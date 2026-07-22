"use client";

import { useEffect, useMemo, useRef, useState } from "react";

type Cell = { x: number; y: number };
type Car = { id: string; pathIndex: number; color: string };
type Level = { name: string; route: Cell[]; cars: Car[]; exit: "top" | "right" | "bottom" | "left" };

const GRID = 7;
const COLORS = ["red", "blue", "yellow", "mint", "purple", "orange", "pink"];

function horizontalMaze(): Cell[] {
  const route: Cell[] = [];
  const rows = [6, 4, 2, 0];
  rows.forEach((y, row) => {
    const forward = row % 2 === 0;
    for (let step = 0; step < GRID; step++) route.push({ x: forward ? step : GRID - 1 - step, y });
    if (row < rows.length - 1) {
      const edge = forward ? GRID - 1 : 0;
      route.push({ x: edge, y: y - 1 });
    }
  });
  return route;
}

function verticalMaze(): Cell[] {
  const route: Cell[] = [];
  const columns = [0, 2, 4, 6];
  columns.forEach((x, column) => {
    const upward = column % 2 === 0;
    for (let step = 0; step < GRID; step++) route.push({ x, y: upward ? GRID - 1 - step : step });
    if (column < columns.length - 1) route.push({ x: x + 1, y: upward ? 0 : GRID - 1 });
  });
  return route;
}

function spiralMaze(): Cell[] {
  const route: Cell[] = [];
  let left = 0, right = GRID - 1, top = 0, bottom = GRID - 1;
  while (left <= right && top <= bottom) {
    for (let x = left; x <= right; x++) route.push({ x, y: top });
    top++;
    for (let y = top; y <= bottom; y++) route.push({ x: right, y });
    right--;
    if (top <= bottom) {
      for (let x = right; x >= left; x--) route.push({ x, y: bottom });
      bottom--;
    }
    if (left <= right) {
      for (let y = bottom; y >= top; y--) route.push({ x: left, y });
      left++;
    }
  }
  return route.reverse();
}

function createLevel(index: number, count: number): Level {
  const variant = index % 3;
  const route = variant === 1 ? horizontalMaze() : variant === 2 ? verticalMaze() : spiralMaze();
  const usable = Math.max(count, route.length - 3);
  const chosen = new Set<number>();
  for (let i = 0; i < count; i++) chosen.add(Math.floor((i * usable) / count));
  let cursor = 0;
  while (chosen.size < count) chosen.add(cursor++);
  const positions = [...chosen].sort((a, b) => a - b).slice(0, count);
  const cars = positions.map((pathIndex, car) => ({ id: `level-${index}-car-${car}`, pathIndex, color: COLORS[(car + index) % COLORS.length] }));
  return {
    name: variant === 1 ? `Lorong Zigzag — ${count} mobil` : variant === 2 ? `Lorong Berliku — ${count} mobil` : `Parkiran Spiral — ${count} mobil`,
    route,
    cars,
    exit: variant === 1 ? "left" : variant === 2 ? "bottom" : "top"
  };
}

const LEVELS = Array.from({ length: 13 }, (_, index) => createLevel(index + 1, index + 8));

function cloneCars(cars: Car[]) { return cars.map((car) => ({ ...car })); }
function key(cell: Cell) { return `${cell.x},${cell.y}`; }
function direction(from: Cell, to: Cell) {
  const dx = to.x - from.x;
  const dy = to.y - from.y;
  if (Math.abs(dx) > Math.abs(dy)) return dx > 0 ? 0 : 180;
  return dy > 0 ? 90 : 270;
}
function exitAngle(exit: Level["exit"]) { return exit === "right" ? 0 : exit === "bottom" ? 90 : exit === "left" ? 180 : 270; }
function formatTime(ms: number) {
  const seconds = Math.floor(ms / 1000);
  return `${String(Math.floor(seconds / 60)).padStart(2, "0")}:${String(seconds % 60).padStart(2, "0")}.${Math.floor((ms % 1000) / 100)}`;
}
function bestLabel(value: number) { return Number.isFinite(value) ? formatTime(value) : "—"; }

export default function Home() {
  const [levelIndex, setLevelIndex] = useState(0);
  const [cars, setCars] = useState(() => cloneCars(LEVELS[0].cars));
  const [moves, setMoves] = useState(0);
  const [history, setHistory] = useState<Car[][]>([]);
  const [won, setWon] = useState(false);
  const [showHelp, setShowHelp] = useState(true);
  const [blockedId, setBlockedId] = useState<string | null>(null);
  const [elapsedMs, setElapsedMs] = useState(0);
  const [bestTimes, setBestTimes] = useState<number[]>(() => LEVELS.map(() => Number.POSITIVE_INFINITY));
  const levelStart = useRef(0);

  const level = LEVELS[levelIndex];
  const routeSet = useMemo(() => new Set(level.route.map(key)), [level]);

  useEffect(() => {
    const raw = localStorage.getItem("sedan-parking-best");
    if (raw) try {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed)) setBestTimes((old) => old.map((value, i) => Number.isFinite(parsed[i]) ? parsed[i] : value));
    } catch { /* ignore */ }
    if (localStorage.getItem("sedan-parking-seen")) setShowHelp(false);
  }, []);

  useEffect(() => {
    if (won) return;
    levelStart.current = performance.now();
    setElapsedMs(0);
    const timer = window.setInterval(() => setElapsedMs(Math.floor(performance.now() - levelStart.current)), 100);
    return () => window.clearInterval(timer);
  }, [levelIndex, won]);

  useEffect(() => {
    if (won || cars.length) return;
    setWon(true);
    setBestTimes((old) => {
      if (elapsedMs >= old[levelIndex]) return old;
      const next = [...old];
      next[levelIndex] = elapsedMs;
      localStorage.setItem("sedan-parking-best", JSON.stringify(next));
      return next;
    });
  }, [cars.length, elapsedMs, levelIndex, won]);

  function loadLevel(index: number) {
    const next = (index + LEVELS.length) % LEVELS.length;
    setLevelIndex(next);
    setCars(cloneCars(LEVELS[next].cars));
    setMoves(0);
    setHistory([]);
    setWon(false);
    setBlockedId(null);
  }

  function advanceCar(id: string) {
    if (won) return;
    const car = cars.find((item) => item.id === id);
    if (!car) return;
    const nextIndex = car.pathIndex + 1;
    const occupied = new Set(cars.filter((item) => item.id !== id).map((item) => item.pathIndex));
    if (nextIndex < level.route.length && occupied.has(nextIndex)) {
      setBlockedId(id);
      window.setTimeout(() => setBlockedId(null), 320);
      return;
    }
    setHistory((old) => [...old, cloneCars(cars)]);
    setMoves((value) => value + 1);
    if (nextIndex >= level.route.length) setCars((old) => old.filter((item) => item.id !== id));
    else setCars((old) => old.map((item) => item.id === id ? { ...item, pathIndex: nextIndex } : item));
  }

  function undo() {
    const previous = history.at(-1);
    if (!previous) return;
    setCars(cloneCars(previous));
    setHistory((old) => old.slice(0, -1));
    setMoves((value) => Math.max(0, value - 1));
  }

  function closeHelp() {
    localStorage.setItem("sedan-parking-seen", "1");
    setShowHelp(false);
  }

  const finalCell = level.route[level.route.length - 1];
  const isLast = levelIndex === LEVELS.length - 1;

  return (
    <main className="app-shell">
      <section className="game-card" aria-label="Game parkiran mobil sedan">
        <header className="topbar">
          <div><span className="eyebrow">ONE WAY PARKING</span><h1>KELUAR<span>.</span></h1></div>
          <button className="icon-btn" onClick={() => setShowHelp(true)} aria-label="Buka petunjuk">?</button>
        </header>

        <div className="level-row">
          <button className="level-nav" onClick={() => loadLevel(levelIndex - 1)} aria-label="Level sebelumnya">‹</button>
          <div className="level-title"><small>LEVEL {String(levelIndex + 1).padStart(2, "0")}</small><strong>{level.name}</strong></div>
          <button className="level-nav" onClick={() => loadLevel(levelIndex + 1)} aria-label="Level berikutnya">›</button>
        </div>

        <div className="stats">
          <div><span>LANGKAH</span><strong>{String(moves).padStart(2, "0")}</strong></div>
          <div className="goal-pill"><i /><strong>{formatTime(elapsedMs)}</strong><small>WAKTU</small></div>
          <div><span>TERBAIK</span><strong>{bestLabel(bestTimes[levelIndex])}</strong></div>
        </div>

        <div className={`parking-wrap exit-${level.exit}`}>
          <div className="exit-sign" style={{ "--exit-x": finalCell.x, "--exit-y": finalCell.y } as React.CSSProperties}><b>EXIT</b><span>➜</span></div>
          <div className="parking-board">
            {Array.from({ length: GRID * GRID }, (_, index) => {
              const cell = { x: index % GRID, y: Math.floor(index / GRID) };
              return <span key={index} className={routeSet.has(key(cell)) ? "road-cell" : "island-cell"} style={{ "--x": cell.x, "--y": cell.y } as React.CSSProperties} />;
            })}
            {level.route.map((cell, index) => {
              if (index % 3 !== 1) return null;
              const next = level.route[index + 1];
              const angle = next ? direction(cell, next) : exitAngle(level.exit);
              return <i key={`arrow-${index}`} className="lane-arrow" style={{ "--x": cell.x, "--y": cell.y, "--rot": `${angle}deg` } as React.CSSProperties}>➜</i>;
            })}
            {cars.map((car) => {
              const cell = level.route[car.pathIndex];
              const next = level.route[car.pathIndex + 1];
              const angle = next ? direction(cell, next) : exitAngle(level.exit);
              return (
                <button key={car.id} className={`sedan ${car.color} ${blockedId === car.id ? "blocked" : ""}`} style={{ "--x": cell.x, "--y": cell.y, "--rot": `${angle}deg` } as React.CSSProperties} onClick={() => advanceCar(car.id)} aria-label={`Mobil sedan ${car.color}, maju mengikuti jalan`}>
                  <span className="car-body"><i className="rear-glass" /><i className="roof" /><i className="front-glass" /><i className="lamp left" /><i className="lamp right" /></span>
                  <i className="tire t1" /><i className="tire t2" /><i className="tire t3" /><i className="tire t4" />
                </button>
              );
            })}
          </div>
        </div>

        <p className="tip"><span>☝</span> Ketuk mobil untuk maju. Mobil otomatis berbelok mengikuti jalan satu arah.</p>
        <div className="controls">
          <button onClick={undo} disabled={!history.length}><span>↶</span> Urungkan</button>
          <button className="reset" onClick={() => loadLevel(levelIndex)}><span>↻</span> Ulangi</button>
          <button onClick={() => setShowHelp(true)}><span>↱</span> Aturan</button>
        </div>
        <footer><span>keluar.</span><small>Satu jalan, satu pintu keluar</small></footer>
      </section>

      {showHelp && <div className="overlay" role="dialog" aria-modal="true" aria-labelledby="help-title"><div className="modal">
        <div className="mini-car"><i /></div><span className="modal-kicker">CARA BERMAIN</span>
        <h2 id="help-title">Keluarkan semua sedan</h2>
        <p>Setiap parkiran hanya memiliki satu pintu keluar. Ketuk mobil untuk maju satu petak pada jalur berliku.</p>
        <p>Mobil bisa belok kiri atau kanan secara otomatis mengikuti panah satu arah, tetapi tidak dapat menabrak mobil di depannya.</p>
        <div className="rule"><b>➜</b><span><strong>Ikuti panah</strong><small>jalan di dalam parkiran hanya satu arah</small></span></div>
        <div className="rule"><b>🚗</b><span><strong>Dahulukan mobil depan</strong><small>buka jalan untuk mobil di belakang</small></span></div>
        <button className="play-btn" onClick={closeHelp}>Mulai bermain <b>→</b></button>
      </div></div>}

      {won && <div className="overlay win" role="dialog" aria-modal="true"><div className="modal win-modal">
        <div className="burst">✓</div><span className="modal-kicker">PARKIRAN KOSONG</span><h2>Semua mobil keluar!</h2>
        <p>Waktu {formatTime(elapsedMs)} dengan {moves} langkah.</p>
        <button className="play-btn" onClick={() => loadLevel(isLast ? 0 : levelIndex + 1)}>{isLast ? "Kembali ke level 1" : "Level berikutnya"} <b>→</b></button>
        <button className="text-btn" onClick={() => loadLevel(levelIndex)}>Main lagi</button>
      </div></div>}
    </main>
  );
}
