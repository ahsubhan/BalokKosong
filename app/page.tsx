"use client";

import { useEffect, useRef, useState } from "react";

type Axis = "h" | "v";
type Cell = { x: number; y: number };
type Block = {
  id: string;
  x: number;
  y: number;
  axis: Axis;
  color: string;
  shape: Cell[];
};
type Level = { name: string; blocks: Block[] };

const SIZE = 6;

const palette = ["orange", "mint", "sky", "lilac", "coral", "aqua", "lemon"];

type PairCandidate = {
  x: number;
  y: number;
  axis: Axis;
  shape: Cell[];
};

function makeRng(seed: number) {
  return function random() {
    seed = (seed * 1664525 + 1013904223) >>> 0;
    return seed / 4294967296;
  };
}

function colorFor(index: number) {
  return palette[index % palette.length];
}

function collectSingles(occupied: boolean[][]) {
  const cells: Cell[] = [];
  for (let y = 0; y < SIZE; y++) {
    for (let x = 0; x < SIZE; x++) {
      if (!occupied[y][x]) cells.push({ x, y });
    }
  }
  return cells;
}

function collectPairs(occupied: boolean[][]) {
  const pairs: PairCandidate[] = [];
  for (let y = 0; y < SIZE; y++) {
    for (let x = 0; x < SIZE; x++) {
      if (!occupied[y][x] && x + 1 < SIZE && !occupied[y][x + 1]) {
        pairs.push({ x, y, axis: "h", shape: [{ x: 0, y: 0 }, { x: 1, y: 0 }] });
      }
      if (!occupied[y][x] && y + 1 < SIZE && !occupied[y + 1][x]) {
        pairs.push({ x, y, axis: "v", shape: [{ x: 0, y: 0 }, { x: 0, y: 1 }] });
      }
    }
  }
  return pairs;
}

function markOccupancy(occupied: boolean[][], cells: Cell[]) {
  for (const cell of cells) {
    if (cell.x < 0 || cell.x >= SIZE || cell.y < 0 || cell.y >= SIZE) return false;
    if (occupied[cell.y][cell.x]) return false;
  }
  for (const cell of cells) {
    occupied[cell.y][cell.x] = true;
  }
  return true;
}

function makeTruckLevel(levelIndex: number, pieceCount: number): Level {
  const rng = makeRng(12_345 + levelIndex * 97 + pieceCount * 17);
  const occupied = Array.from({ length: SIZE }, () => Array(SIZE).fill(false));
  const blocks: Block[] = [];

  const pairProbability = Math.min(0.75, 0.38 + levelIndex * 0.025);
  let pairCount = 0;
  let singleCount = 0;

  for (let i = 0; i < pieceCount; i++) {
    let placed = false;
    const preferPair = rng() < pairProbability;

    if (preferPair) {
      const candidates = collectPairs(occupied);
      if (candidates.length > 0) {
        const pick = candidates[Math.floor(rng() * candidates.length)];
        const ok = markOccupancy(
          occupied,
          pick.shape.map((cell) => ({ x: pick.x + cell.x, y: pick.y + cell.y }))
        );
        if (ok) {
          blocks.push({
            id: `lvl-${levelIndex}-truck-${i}`,
            x: pick.x,
            y: pick.y,
            axis: pick.axis,
          color: colorFor(i),
          shape: pick.shape
        });
          pairCount += 1;
          placed = true;
        }
      }
    }

    if (placed) continue;

    const singles = collectSingles(occupied);
    if (singles.length === 0) break;
    const pick = singles[Math.floor(rng() * singles.length)];
    occupied[pick.y][pick.x] = true;
    blocks.push({
      id: `lvl-${levelIndex}-truck-${i}`,
      x: pick.x,
      y: pick.y,
      axis: rng() < 0.5 ? "h" : "v",
      color: colorFor(i + 3),
      shape: [{ x: 0, y: 0 }]
    });
    singleCount += 1;
  }

  // Make sure each level tetap terasa seperti campuran truck: ada yang non-gandeng dan ada yang gandeng.
  if (pairCount === 0 && singleCount >= 2) {
    const fallback: PairCandidate[] = collectPairs(occupied);
    if (fallback.length > 0) {
      const pick = fallback[0];
      const merged = markOccupancy(
        occupied,
        pick.shape.map((cell) => ({ x: pick.x + cell.x, y: pick.y + cell.y }))
      );
      if (merged) {
        if (singleCount > 0 && blocks.length > 0) {
          const removed = blocks.shift();
          if (removed) {
            for (const c of getCells(removed)) {
              occupied[c.y][c.x] = false;
            }
            singleCount -= 1;
          }
        }
        blocks.push({
          id: `lvl-${levelIndex}-truck-pair`,
          x: pick.x,
          y: pick.y,
          axis: pick.axis,
          color: colorFor(blocks.length),
          shape: pick.shape
        });
        pairCount += 1;
      }
    }
  }

  if (singleCount === 0 && pairCount >= 1 && blocks.length >= 2) {
    const lone = blocks.pop();
    if (lone) {
      for (const c of getCells(lone)) {
        occupied[c.y][c.x] = false;
      }
      pairCount -= 1;

      const singles = collectSingles(occupied);
      if (!singles.length) return { name: `Truck Campuran #${levelIndex} — ${pieceCount} mobil`, blocks };

      const pick = singles[0];
      blocks.push({
        id: `lvl-${levelIndex}-truck-single-${blocks.length}`,
        x: pick.x,
        y: pick.y,
        axis: "h",
        color: colorFor(blocks.length + 1),
        shape: [{ x: 0, y: 0 }]
      });
      occupied[pick.y][pick.x] = true;
      singleCount += 1;
    }
  }

  return {
    name: `Truck Campuran #${levelIndex} — ${pieceCount} mobil`,
    blocks
  };
}

const levels: Level[] = Array.from({ length: 13 }, (_, idx) => makeTruckLevel(idx + 1, idx + 8));

function cloneBlocks(items: Block[]) {
  return items.map((block) => ({ ...block, shape: block.shape.map((cell) => ({ ...cell })) }));
}

function getCells(block: Block) {
  return block.shape.map((cell) => ({ x: block.x + cell.x, y: block.y + cell.y }));
}

function bounds(block: Block) {
  let maxX = 0;
  let maxY = 0;
  block.shape.forEach((cell) => {
    if (cell.x > maxX) maxX = cell.x;
    if (cell.y > maxY) maxY = cell.y;
  });
  return { w: maxX + 1, h: maxY + 1 };
}

function isInside(cell: Cell) {
  return cell.x >= 0 && cell.x < SIZE && cell.y >= 0 && cell.y < SIZE;
}

function makeCellKey(cell: Cell) {
  return `${cell.x},${cell.y}`;
}

function formatTime(ms: number) {
  const totalSeconds = Math.floor(ms / 1000);
  const minutes = String(Math.floor(totalSeconds / 60)).padStart(2, "0");
  const seconds = String(totalSeconds % 60).padStart(2, "0");
  const millis = String(Math.floor((ms % 1000) / 100));
  return `${minutes}:${seconds}.${millis}`;
}

function bestLabel(ms: number) {
  return Number.isFinite(ms) ? formatTime(ms) : "—";
}

function equalState(before: Block[], after: Block[]) {
  if (before.length !== after.length) return false;
  const map = new Map(before.map((b) => [b.id, b]));
  return after.every((b) => {
    const prev = map.get(b.id);
    return prev?.x === b.x && prev?.y === b.y;
  });
}

export default function Home() {
  const [levelIndex, setLevelIndex] = useState(0);
  const [blocks, setBlocks] = useState(() => cloneBlocks(levels[0].blocks));
  const [moves, setMoves] = useState(0);
  const [history, setHistory] = useState<Block[][]>([]);
  const [won, setWon] = useState(false);
  const [showHelp, setShowHelp] = useState(true);
  const [hintId, setHintId] = useState<string | null>(null);
  const [elapsedMs, setElapsedMs] = useState(0);
  const [bestTimes, setBestTimes] = useState<number[]>(() => levels.map(() => Number.POSITIVE_INFINITY));
  const boardRef = useRef<HTMLDivElement>(null);
  const drag = useRef<{ id: string; start: number; lastStep: number; initial: Block[] } | null>(null);
  const levelStart = useRef<number>(0);

  useEffect(() => {
    const raw = localStorage.getItem("dorong-best-times");
    if (!raw) return;
    try {
      const parsed = JSON.parse(raw);
      if (!Array.isArray(parsed)) return;
      setBestTimes((prev) => prev.map((item, idx) => (Number.isFinite(parsed[idx]) ? parsed[idx] : item)));
    } catch {
      // ignore
    }
  }, []);

  useEffect(() => {
    const seen = localStorage.getItem("dorong-seen");
    if (seen) setShowHelp(false);
  }, []);

  useEffect(() => {
    if (won) return;
    levelStart.current = performance.now();
    setElapsedMs(0);
    const timer = window.setInterval(() => {
      setElapsedMs(Math.floor(performance.now() - levelStart.current));
    }, 100);
    return () => window.clearInterval(timer);
  }, [levelIndex, won]);

  useEffect(() => {
    if (won) return;
    if (blocks.length !== 0) return;
    setWon(true);
    setHistory([]);
    setBestTimes((prev) => {
      const current = prev[levelIndex];
      if (elapsedMs >= current) return prev;
      const next = [...prev];
      next[levelIndex] = elapsedMs;
      try {
        localStorage.setItem("dorong-best-times", JSON.stringify(next));
      } catch {
        // ignore
      }
      return next;
    });
  }, [blocks.length, won, elapsedMs, levelIndex]);

  const level = levels[levelIndex];

  function loadLevel(index: number) {
    const next = (index + levels.length) % levels.length;
    setLevelIndex(next);
    setBlocks(cloneBlocks(levels[next].blocks));
    setMoves(0);
    setHistory([]);
    setWon(false);
    setHintId(null);
    levelStart.current = performance.now();
    setElapsedMs(0);
  }

  function pushStep(item: Block, state: Block[], direction: number) {
    const deltaX = item.axis === "h" ? direction : 0;
    const deltaY = item.axis === "v" ? direction : 0;
    const nextCells = getCells(item).map((cell) => ({ x: cell.x + deltaX, y: cell.y + deltaY }));
    const willExit = nextCells.some((cell) => !isInside(cell));

    if (willExit) {
      return { next: state.filter((block) => block.id !== item.id), moved: true };
    }

    const occupancy = new Set<string>();
    for (const block of state) {
      if (block.id === item.id) continue;
      for (const cell of getCells(block)) {
        occupancy.add(makeCellKey(cell));
      }
    }

    const blocked = nextCells.some((cell) => occupancy.has(makeCellKey(cell)));
    if (blocked) return { next: state, moved: false };

    return {
      next: state.map((block) =>
        block.id === item.id ? { ...block, x: block.x + deltaX, y: block.y + deltaY } : block
      ),
      moved: true
    };
  }

  function moveFromInitial(id: string, requested: number, initial: Block[]) {
    if (requested === 0) return initial;
    const direction = Math.sign(requested);
    if (direction === 0) return initial;

    let changed = false;
    let working = cloneBlocks(initial);

    for (let i = 0; i < Math.abs(requested); i++) {
      const current = working.find((block) => block.id === id);
      if (!current) {
        changed = true;
        break;
      }
      const attempt = pushStep(current, working, direction);
      if (!attempt.moved) break;
      changed = true;
      working = attempt.next;
      if (!working.some((block) => block.id === id)) {
        break;
      }
    }

    return changed ? working : initial;
  }

  function pointerDown(event: React.PointerEvent, item: Block) {
    if (won) return;
    event.currentTarget.setPointerCapture(event.pointerId);
    const start = item.axis === "h" ? event.clientX : event.clientY;
    drag.current = { id: item.id, start, lastStep: 0, initial: cloneBlocks(blocks) };
    setHintId(item.id);
  }

  function pointerMove(event: React.PointerEvent, item: Block) {
    if (!drag.current || drag.current.id !== item.id || !boardRef.current) return;
    const current = item.axis === "h" ? event.clientX : event.clientY;
    const cell = boardRef.current.clientWidth / SIZE;
    const step = Math.round((current - drag.current.start) / cell);
    if (step === drag.current.lastStep) return;
    drag.current.lastStep = step;
    setBlocks(moveFromInitial(item.id, step, drag.current.initial));
  }

  function pointerUp() {
    if (!drag.current) return;
    const before = drag.current.initial;
    const changed = !equalState(before, blocks);
    if (changed) {
      setHistory((old) => [...old, before]);
      setMoves((count) => count + 1);
    }
    drag.current = null;
    setHintId(null);
  }

  function undo() {
    const previous = history.at(-1);
    if (!previous) return;
    setBlocks(cloneBlocks(previous));
    setHistory((old) => old.slice(0, -1));
    setMoves((count) => Math.max(0, count - 1));
  }

  function closeHelp() {
    localStorage.setItem("dorong-seen", "1");
    setShowHelp(false);
  }

  const isCleared = blocks.length === 0;
  const isLastLevel = levelIndex === levels.length - 1;
  const nextLevel = isLastLevel ? 0 : levelIndex + 1;

  return (
    <main className="app-shell">
      <section className="game-card" aria-label="Game puzzle Dorong">
        <header className="topbar">
          <div>
            <span className="eyebrow">PUZZLE TRUCK</span>
            <h1>DORONG<span>.</span></h1>
          </div>
          <div className="header-actions">
            <button className="icon-btn" onClick={() => setShowHelp(true)} aria-label="Buka petunjuk">?</button>
          </div>
        </header>

        <div className="level-row">
          <button className="level-nav" onClick={() => loadLevel(levelIndex - 1)} aria-label="Level sebelumnya">‹</button>
          <div className="level-title">
            <small>LEVEL {String(levelIndex + 1).padStart(2, "0")}</small>
            <strong>{level.name}</strong>
          </div>
          <button className="level-nav" onClick={() => loadLevel(levelIndex + 1)} aria-label="Level berikutnya">›</button>
        </div>

        <div className="stats">
          <div><span>LANGKAH</span><strong>{String(moves).padStart(2, "0")}</strong></div>
          <div className="goal-pill">
            <i />
            <strong>{formatTime(elapsedMs)}</strong>
            <small>WAKTU</small>
          </div>
          <div><span>BEST</span><strong>{bestLabel(bestTimes[levelIndex])}</strong></div>
        </div>

        <div className="board-wrap">
          <div className="board" ref={boardRef}>
            <div className="grid-lines" />
            {blocks.map((item) => {
              const b = bounds(item);
              const isHorizontal = item.axis === "h";
              return (
                <button
                  key={item.id}
                  className={`block ${item.color} truck-${item.axis} ${item.shape.length > 1 ? "truck-gandeng" : "truck-singkat"} ${hintId === item.id ? "active" : ""}`}
                  style={{ "--x": item.x, "--y": item.y, "--w": b.w, "--h": b.h } as React.CSSProperties}
                  onPointerDown={(e) => pointerDown(e, item)}
                  onPointerMove={(e) => pointerMove(e, item)}
                  onPointerUp={pointerUp}
                  onPointerCancel={pointerUp}
                  aria-label={`Truk kontainer ${item.shape.length > 1 ? "gandeng" : "singkat"}, dorong ${isHorizontal ? "kiri atau kanan" : "atas atau bawah"}`}
                >
                  {item.shape.map((cell, idx) => (
                    <span
                      key={idx}
                      className={`block-cell ${item.color}`}
                      style={{ "--cx": cell.x, "--cy": cell.y } as React.CSSProperties}
                    />
                  ))}
                  <span className="truck-visual" aria-hidden="true">
                    <span className="truck-container">
                      <i className="container-rib rib-one" />
                      <i className="container-rib rib-two" />
                      <i className="container-door" />
                    </span>
                    <span className="truck-coupler" />
                    <span className="truck-cab">
                      <i className="windshield" />
                      <i className="cab-line" />
                      <i className="headlight light-one" />
                      <i className="headlight light-two" />
                    </span>
                    <i className="wheel wheel-one" />
                    <i className="wheel wheel-two" />
                    <i className="wheel wheel-three" />
                    <i className="wheel wheel-four" />
                  </span>
                </button>
              );
            })}
          </div>
        </div>

        <p className="tip"><span>☝</span> Truk tidak diputar, hanya didorong searah panjangnya.</p>

        <div className="controls">
          <button onClick={undo} disabled={!history.length}><span>↶</span> Urungkan</button>
          <button className="reset" onClick={() => loadLevel(levelIndex)}><span>↻</span> Ulangi</button>
          <button onClick={() => { setHintId("orange"); window.setTimeout(() => setHintId(null), 900); }}>
            <span>✦</span> Petunjuk
          </button>
        </div>

        <footer><span>dorong.</span><small>Dorong, Kosongkan, Menangkan</small></footer>
      </section>

      {showHelp && (
        <div className="overlay" role="dialog" aria-modal="true" aria-labelledby="help-title">
          <div className="modal">
            <div className="mini-block"><span /></div>
            <span className="modal-kicker">CARA BERMAIN</span>
            <h2 id="help-title">Keluarkan semua balok dari ruangan</h2>
            <p>Gerakkan truck container ke arah panahnya saja. Bentuk yang dipakai hanya kontainer tunggal (1 mobil) dan gandeng (2 mobil), tidak ada rotasi.</p>
            <p>Jika seluruh posisi gerak berikutnya keluar papan, balok langsung hilang. Level selesai saat tidak ada balok tersisa.</p>
            <p>Skor terbaik ditentukan dari waktu tercepat.</p>
            <div className="rule"><b>↔</b><span><strong>Axis horizontal</strong><small>dorong kiri atau kanan</small></span></div>
            <div className="rule"><b>↕</b><span><strong>Axis vertikal</strong><small>dorong atas atau bawah</small></span></div>
            <button className="play-btn" onClick={closeHelp}>Mulai bermain <b>→</b></button>
          </div>
        </div>
      )}

      {won && isCleared && (
        <div className="overlay win" role="dialog" aria-modal="true">
          <div className="modal win-modal">
            <div className="burst">✓</div>
            <span className="modal-kicker">LEVEL SELESAI</span>
            <h2>Tuntas!</h2>
            <p>Semua balok keluar, waktu kamu {formatTime(elapsedMs)}.</p>
            <p>Langkah: <strong>{moves}</strong>.</p>
            <button className="play-btn" onClick={() => loadLevel(nextLevel)}>
              {isLastLevel ? "Kembali ke level 1" : "Level berikutnya"} <b>→</b>
            </button>
            <button className="text-btn" onClick={() => loadLevel(levelIndex)}>Main lagi</button>
          </div>
        </div>
      )}
    </main>
  );
}
