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

const levels: Level[] = [
  {
    name: "Pemanasan",
    blocks: [
      { id: "orange", x: 0, y: 2, axis: "h", color: "orange", shape: [{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 2, y: 0 }] },
      { id: "a", x: 4, y: 0, axis: "v", color: "mint", shape: [{ x: 0, y: 0 }, { x: 0, y: 1 }, { x: 0, y: 2 }] },
      { id: "b", x: 2, y: 4, axis: "h", color: "sky", shape: [{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 1, y: 1 }] },
      { id: "c", x: 4, y: 4, axis: "h", color: "lilac", shape: [{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 1, y: 1 }] },
      { id: "d", x: 5, y: 1, axis: "v", color: "coral", shape: [{ x: 0, y: 0 }, { x: 0, y: 1 }] },
      { id: "e", x: 1, y: 0, axis: "h", color: "lemon", shape: [{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 2, y: 0 }, { x: 1, y: 1 }] },
      { id: "f", x: 1, y: 5, axis: "v", color: "aqua", shape: [{ x: 0, y: 0 }] }
    ]
  },
  {
    name: "Lorong Tipis",
    blocks: [
      { id: "orange", x: 1, y: 0, axis: "v", color: "orange", shape: [{ x: 0, y: 0 }, { x: 0, y: 1 }, { x: 0, y: 2 }, { x: 0, y: 3 }] },
      { id: "a", x: 0, y: 2, axis: "v", color: "mint", shape: [{ x: 0, y: 0 }, { x: 0, y: 1 }, { x: 0, y: 2 }] },
      { id: "b", x: 4, y: 1, axis: "v", color: "lilac", shape: [{ x: 0, y: 0 }, { x: 0, y: 1 }, { x: 0, y: 2 }] },
      { id: "c", x: 2, y: 4, axis: "h", color: "coral", shape: [{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 1, y: 1 }] },
      { id: "d", x: 3, y: 0, axis: "v", color: "aqua", shape: [{ x: 0, y: 0 }, { x: 0, y: 1 }, { x: 0, y: 2 }] },
      { id: "e", x: 5, y: 0, axis: "v", color: "sky", shape: [{ x: 0, y: 0 }, { x: 0, y: 1 }, { x: 0, y: 2 }] },
      { id: "f", x: 0, y: 5, axis: "h", color: "lemon", shape: [{ x: 0, y: 0 }, { x: 1, y: 0 }] }
    ]
  },
  {
    name: "Bertemu Bentuk",
    blocks: [
      { id: "orange", x: 0, y: 1, axis: "h", color: "orange", shape: [{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 2, y: 0 }, { x: 2, y: 1 }] },
      { id: "a", x: 4, y: 3, axis: "v", color: "mint", shape: [{ x: 0, y: 0 }, { x: 0, y: 1 }, { x: 0, y: 2 }] },
      { id: "b", x: 2, y: 3, axis: "h", color: "sky", shape: [{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 0, y: 1 }, { x: 0, y: 2 }] },
      { id: "c", x: 0, y: 4, axis: "h", color: "lilac", shape: [{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 1, y: 1 }] },
      { id: "d", x: 5, y: 0, axis: "v", color: "coral", shape: [{ x: 0, y: 0 }, { x: 0, y: 1 }, { x: 0, y: 2 }] },
      { id: "e", x: 0, y: 2, axis: "h", color: "lemon", shape: [{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 1, y: 1 }] },
      { id: "f", x: 3, y: 0, axis: "v", color: "aqua", shape: [{ x: 0, y: 0 }, { x: 0, y: 1 }] }
    ]
  },
  {
    name: "Peta Ruwet",
    blocks: [
      { id: "orange", x: 0, y: 0, axis: "h", color: "orange", shape: [{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 2, y: 0 }] },
      { id: "a", x: 5, y: 0, axis: "v", color: "mint", shape: [{ x: 0, y: 0 }, { x: 0, y: 1 }] },
      { id: "b", x: 2, y: 2, axis: "h", color: "sky", shape: [{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 1, y: 1 }, { x: 2, y: 1 }] },
      { id: "c", x: 0, y: 4, axis: "h", color: "lilac", shape: [{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 1, y: 1 }, { x: 2, y: 1 }] },
      { id: "d", x: 5, y: 3, axis: "v", color: "coral", shape: [{ x: 0, y: 0 }, { x: 0, y: 1 }, { x: 0, y: 2 }] },
      { id: "e", x: 3, y: 5, axis: "h", color: "lemon", shape: [{ x: 0, y: 0 }, { x: 1, y: 0 }] },
      { id: "f", x: 0, y: 3, axis: "h", color: "aqua", shape: [{ x: 0, y: 0 }, { x: 1, y: 0 }] }
    ]
  }
];

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
            <span className="eyebrow">PUZZLE BALOK</span>
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
                  className={`block ${item.color} ${hintId === item.id ? "active" : ""}`}
                  style={{ "--x": item.x, "--y": item.y, "--w": b.w, "--h": b.h } as React.CSSProperties}
                  onPointerDown={(e) => pointerDown(e, item)}
                  onPointerMove={(e) => pointerMove(e, item)}
                  onPointerUp={pointerUp}
                  onPointerCancel={pointerUp}
                  aria-label={`Balok, dorong ${isHorizontal ? "kiri atau kanan" : "atas atau bawah"}`}
                >
                  {item.shape.map((cell, idx) => (
                    <span
                      key={idx}
                      className={`block-cell ${item.color}`}
                      style={{ "--cx": cell.x, "--cy": cell.y } as React.CSSProperties}
                    />
                  ))}
                  <span className={isHorizontal ? "grip horizontal" : "grip vertical"} />
                </button>
              );
            })}
          </div>
        </div>

        <p className="tip"><span>☝</span> Balok tidak diputar, hanya didorong searah panjangnya.</p>

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
            <p>Tarik balok ke arah panahnya. Seluruh balok bisa lurus, ada juga bentuk L/T, tapi tetap tidak boleh diputar.</p>
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
