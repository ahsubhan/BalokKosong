"use client";
import { useEffect, useRef, useState } from "react";

type Direction=0|90|180|270;
type Shape="I"|"L";
type Piece={id:string;x:number;y:number;dir:Direction;shape:Shape;color:string};
type Cell={x:number;y:number};
const COLS=12,ROWS=20;
const colors=["red","blue","yellow","mint","purple","orange","pink"];
const vector=(dir:Direction)=>dir===0?{x:1,y:0}:dir===90?{x:0,y:1}:dir===180?{x:-1,y:0}:{x:0,y:-1};
const rotate=(x:number,y:number,dir:Direction):Cell=>dir===0?{x,y}:dir===90?{x:-y,y:x}:dir===180?{x:-x,y:-y}:{x:y,y:-x};
const base=(shape:Shape):Cell[]=>shape==="I"?[{x:0,y:0},{x:1,y:0},{x:2,y:0},{x:3,y:0}]:[{x:0,y:0},{x:1,y:0},{x:2,y:0},{x:2,y:1}];
const cells=(p:Piece)=>base(p.shape).map(c=>{const r=rotate(c.x,c.y,p.dir);return{x:p.x+r.x,y:p.y+r.y}});
const edges=(own:Cell[],c:Cell)=>{const set=new Set(own.map(v=>`${v.x},${v.y}`));return[[0,-1,"top"],[1,0,"right"],[0,1,"bottom"],[-1,0,"left"]].filter(([dx,dy])=>!set.has(`${c.x+Number(dx)},${c.y+Number(dy)}`)).map(v=>`edge-${v[2]}`).join(" ")};
const clone=(pieces:Piece[])=>pieces.map(p=>({...p}));

function makeLevel(level:number,count:number){
  let seed=5849+level*941;const rnd=()=>((seed=seed*1664525+1013904223>>>0)/4294967296);
  let best:Piece[]=[];
  for(let restart=0;restart<80&&best.length<count;restart++){
    const pieces:Piece[]=[],used=new Set<string>();
    for(let i=0;i<count;i++){
      const shape:Shape=(i+level)%3===0?"L":"I";let placed=false;
      for(let attempt=0;attempt<700&&!placed;attempt++){
        const x=Math.floor(rnd()*COLS),y=Math.floor(rnd()*ROWS),horizontal=rnd()>.5;
        const dir:Direction=horizontal?(x<COLS/2?180:0):(y<ROWS/2?270:90);
        const probe:Piece={id:`${level}-${i}`,x,y,dir,shape,color:colors[(i+level)%colors.length]};
        const own=cells(probe);
        if(own.some(c=>c.x<0||c.x>=COLS||c.y<0||c.y>=ROWS||used.has(`${c.x},${c.y}`)))continue;
        own.forEach(c=>used.add(`${c.x},${c.y}`));pieces.push(probe);placed=true;
      }
      if(!placed)break;
    }
    if(pieces.length>best.length)best=pieces;
  }
  return{name:`${best.length} balok panjang I & L`,pieces:best};
}
const levels=Array.from({length:13},(_,i)=>makeLevel(i+1,8+Math.round(i*32/12)));
const fmt=(ms:number)=>{const s=Math.floor(ms/1000);return`${String(Math.floor(s/60)).padStart(2,"0")}:${String(s%60).padStart(2,"0")}.${Math.floor(ms%1000/100)}`};

export default function Home(){
  const[level,setLevel]=useState(0),[pieces,setPieces]=useState(()=>clone(levels[0].pieces));
  const[selected,setSelected]=useState<string|null>(null),[moves,setMoves]=useState(0),[history,setHistory]=useState<Piece[][]>([]),[won,setWon]=useState(false),[help,setHelp]=useState(true),[time,setTime]=useState(0),[blocked,setBlocked]=useState(false),[dragOffset,setDragOffset]=useState<{id:string;dx:number;dy:number}|null>(null);
  const started=useRef(0);const drag=useRef<{id:string;x:number;y:number}|null>(null);
  useEffect(()=>{if(localStorage.getItem("block-puzzle-seen"))setHelp(false)},[]);
  useEffect(()=>{if(won)return;started.current=performance.now();setTime(0);const t=setInterval(()=>setTime(performance.now()-started.current),100);return()=>clearInterval(t)},[level,won]);
  useEffect(()=>{if(!won&&pieces.length===0)setWon(true)},[pieces.length,won]);
  function load(i:number){const n=(i+levels.length)%levels.length;setLevel(n);setPieces(clone(levels[n].pieces));setSelected(null);setDragOffset(null);setMoves(0);setHistory([]);setWon(false)}
  function dragStart(e:React.PointerEvent,id:string){e.currentTarget.setPointerCapture(e.pointerId);drag.current={id,x:e.clientX,y:e.clientY};setDragOffset({id,dx:0,dy:0});setSelected(id)}
  function dragMove(e:React.PointerEvent){const start=drag.current;if(!start)return;const piece=pieces.find(p=>p.id===start.id);if(!piece)return;const horizontal=piece.dir===0||piece.dir===180;setDragOffset({id:start.id,dx:horizontal?e.clientX-start.x:0,dy:horizontal?0:e.clientY-start.y})}
  function fail(){setBlocked(true);setTimeout(()=>setBlocked(false),300)}
  function dragEnd(e:React.PointerEvent){
    const start=drag.current;if(!start)return;drag.current=null;setDragOffset(null);const dx=e.clientX-start.x,dy=e.clientY-start.y;const piece=pieces.find(p=>p.id===start.id);if(!piece)return;
    const horizontal=piece.dir===0||piece.dir===180,axisDistance=horizontal?dx:dy;if(Math.abs(axisDistance)<16)return;
    const desired:Direction=horizontal?(axisDistance>0?0:180):(axisDistance>0?90:270);
    const d=vector(desired),occupied=new Set<string>();pieces.filter(p=>p.id!==piece.id).forEach(p=>cells(p).forEach(c=>occupied.add(`${c.x},${c.y}`)));
    let clear=true;for(const c of cells(piece)){let x=c.x+d.x,y=c.y+d.y;while(x>=0&&x<COLS&&y>=0&&y<ROWS){if(occupied.has(`${x},${y}`)){clear=false;break}x+=d.x;y+=d.y}if(!clear)break}
    if(!clear){fail();return}setHistory(h=>[...h,clone(pieces)]);setPieces(old=>old.filter(p=>p.id!==piece.id));setMoves(m=>m+1);setSelected(null);
  }
  function undo(){const previous=history.at(-1);if(!previous)return;setPieces(clone(previous));setHistory(h=>h.slice(0,-1));setMoves(m=>Math.max(0,m-1));setWon(false)}
  return <main className="app-shell"><section className="game-card">
    <header className="mobile-top"><button className="mobile-brand" onClick={()=>setHelp(true)}>KELUAR<span>.</span></button><div className="mobile-level"><button onClick={()=>load(level-1)}>‹</button><span><small>LEVEL</small>{String(level+1).padStart(2,"0")}</span><button onClick={()=>load(level+1)}>›</button></div><div className="mobile-stats"><strong>{fmt(time)}</strong><small>{pieces.length} SISA · {moves} LANGKAH</small></div></header>
    <div className={`block-board ${blocked?"board-blocked":""}`}>{Array.from({length:COLS*ROWS},(_,i)=><i key={i} className="block-grid" style={{"--x":i%COLS,"--y":Math.floor(i/COLS)} as React.CSSProperties}/>)}
      {pieces.flatMap(p=>{const own=cells(p),offset=dragOffset?.id===p.id?dragOffset:null;return own.map((c,index)=><button key={`${p.id}-${index}`} className={`block-cell ${edges(own,c)} ${p.shape==="L"?"shape-l":"shape-i"} ${p.color} ${selected===p.id?"selected":""} ${offset?"dragging":""}`} style={{"--x":c.x,"--y":c.y,"--drag-x":`${offset?.dx??0}px`,"--drag-y":`${offset?.dy??0}px`} as React.CSSProperties} onPointerDown={e=>dragStart(e,p.id)} onPointerMove={dragMove} onPointerUp={dragEnd} onPointerCancel={()=>{drag.current=null;setDragOffset(null)}} aria-label={`Balok ${p.shape}, geret lurus`}/>)})}
    </div>
    <nav className="mobile-bottom"><button onClick={undo} disabled={!history.length}><b>↶</b>Urungkan</button><button onClick={()=>load(level)}><b>↻</b>Ulangi</button><button onClick={()=>setHelp(true)}><b>?</b>Petunjuk</button></nav>
  </section>
  {help&&<div className="overlay"><div className="modal"><span className="modal-kicker">CARA BERMAIN</span><h2>Balok I & L</h2><p>Keluarkan semua balok panjang berbentuk I dan L dari papan.</p><p>Balok horizontal hanya bisa ditarik kiri–kanan. Balok vertikal hanya bisa ditarik atas–bawah. Keluarkan penghalangnya lebih dahulu.</p><button className="play-btn" onClick={()=>{localStorage.setItem("block-puzzle-seen","1");setHelp(false)}}>Mulai bermain →</button></div></div>}
  {won&&<div className="overlay"><div className="modal"><div className="burst">✓</div><h2>Papan kosong!</h2><p>Semua balok keluar dalam {fmt(time)}.</p><button className="play-btn" onClick={()=>load(level===levels.length-1?0:level+1)}>Level berikutnya →</button></div></div>}
  </main>
}
