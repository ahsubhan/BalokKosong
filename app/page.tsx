"use client";
import { useEffect, useRef, useState } from "react";

type Direction=0|90|180|270;
type Shape="I"|"L";
type Piece={id:string;x:number;y:number;dir:Direction;shape:Shape;color:string};
type Cell={x:number;y:number};
const SIZE=12;
const colors=["red","blue","yellow","mint","purple","orange","pink"];
const vector=(dir:Direction)=>dir===0?{x:1,y:0}:dir===90?{x:0,y:1}:dir===180?{x:-1,y:0}:{x:0,y:-1};
const rotate=(x:number,y:number,dir:Direction):Cell=>dir===0?{x,y}:dir===90?{x:-y,y:x}:dir===180?{x:-x,y:-y}:{x:y,y:-x};
const base=(shape:Shape):Cell[]=>shape==="I"?[{x:0,y:0},{x:1,y:0},{x:2,y:0},{x:3,y:0}]:[{x:0,y:0},{x:1,y:0},{x:2,y:0},{x:2,y:1}];
const cells=(p:Piece)=>base(p.shape).map(c=>{const r=rotate(c.x,c.y,p.dir);return{x:p.x+r.x,y:p.y+r.y}});
const clone=(pieces:Piece[])=>pieces.map(p=>({...p}));

function makeLevel(level:number,count:number){
  let seed=5849+level*941;const rnd=()=>((seed=seed*1664525+1013904223>>>0)/4294967296);
  let best:Piece[]=[];
  for(let restart=0;restart<80&&best.length<count;restart++){
    const pieces:Piece[]=[],used=new Set<string>();
    for(let i=0;i<count;i++){
      const shape:Shape=(i+level)%3===0?"L":"I";let placed=false;
      for(let attempt=0;attempt<700&&!placed;attempt++){
        const x=Math.floor(rnd()*SIZE),y=Math.floor(rnd()*SIZE),horizontal=rnd()>.5;
        const dir:Direction=horizontal?(x<SIZE/2?180:0):(y<SIZE/2?270:90);
        const probe:Piece={id:`${level}-${i}`,x,y,dir,shape,color:colors[(i+level)%colors.length]};
        const own=cells(probe);
        if(own.some(c=>c.x<0||c.x>=SIZE||c.y<0||c.y>=SIZE||used.has(`${c.x},${c.y}`)))continue;
        own.forEach(c=>used.add(`${c.x},${c.y}`));pieces.push(probe);placed=true;
      }
      if(!placed)break;
    }
    if(pieces.length>best.length)best=pieces;
  }
  return{name:`${best.length} balok panjang I & L`,pieces:best};
}
const levels=Array.from({length:13},(_,i)=>makeLevel(i+1,i+8));
const fmt=(ms:number)=>{const s=Math.floor(ms/1000);return`${String(Math.floor(s/60)).padStart(2,"0")}:${String(s%60).padStart(2,"0")}.${Math.floor(ms%1000/100)}`};

export default function Home(){
  const[level,setLevel]=useState(0),[pieces,setPieces]=useState(()=>clone(levels[0].pieces));
  const[selected,setSelected]=useState<string|null>(null),[moves,setMoves]=useState(0),[history,setHistory]=useState<Piece[][]>([]),[won,setWon]=useState(false),[help,setHelp]=useState(true),[time,setTime]=useState(0),[blocked,setBlocked]=useState(false);
  const started=useRef(0);const drag=useRef<{id:string;x:number;y:number}|null>(null);const data=levels[level];
  useEffect(()=>{if(localStorage.getItem("block-puzzle-seen"))setHelp(false)},[]);
  useEffect(()=>{if(won)return;started.current=performance.now();setTime(0);const t=setInterval(()=>setTime(performance.now()-started.current),100);return()=>clearInterval(t)},[level,won]);
  useEffect(()=>{if(!won&&pieces.length===0)setWon(true)},[pieces.length,won]);
  function load(i:number){const n=(i+levels.length)%levels.length;setLevel(n);setPieces(clone(levels[n].pieces));setSelected(null);setMoves(0);setHistory([]);setWon(false)}
  function dragStart(e:React.PointerEvent,id:string){e.currentTarget.setPointerCapture(e.pointerId);drag.current={id,x:e.clientX,y:e.clientY};setSelected(id)}
  function fail(){setBlocked(true);setTimeout(()=>setBlocked(false),300)}
  function dragEnd(e:React.PointerEvent){
    const start=drag.current;if(!start)return;drag.current=null;const dx=e.clientX-start.x,dy=e.clientY-start.y;if(Math.hypot(dx,dy)<16)return;
    const desired:Direction=Math.abs(dx)>Math.abs(dy)?(dx>0?0:180):(dy>0?90:270);const piece=pieces.find(p=>p.id===start.id);if(!piece)return;
    const horizontal=piece.dir===0||piece.dir===180;if((horizontal&&desired!==0&&desired!==180)||(!horizontal&&desired!==90&&desired!==270)){fail();return}
    const d=vector(desired),occupied=new Set<string>();pieces.filter(p=>p.id!==piece.id).forEach(p=>cells(p).forEach(c=>occupied.add(`${c.x},${c.y}`)));
    let clear=true;for(const c of cells(piece)){let x=c.x+d.x,y=c.y+d.y;while(x>=0&&x<SIZE&&y>=0&&y<SIZE){if(occupied.has(`${x},${y}`)){clear=false;break}x+=d.x;y+=d.y}if(!clear)break}
    if(!clear){fail();return}setHistory(h=>[...h,clone(pieces)]);setPieces(old=>old.filter(p=>p.id!==piece.id));setMoves(m=>m+1);setSelected(null);
  }
  function undo(){const previous=history.at(-1);if(!previous)return;setPieces(clone(previous));setHistory(h=>h.slice(0,-1));setMoves(m=>Math.max(0,m-1));setWon(false)}
  const current=pieces.find(p=>p.id===selected);
  return <main className="app-shell"><section className="game-card">
    <header className="topbar"><div><span className="eyebrow">PUZZLE BALOK 2D</span><h1>KELUAR<span>.</span></h1></div><button className="icon-btn" onClick={()=>setHelp(true)}>?</button></header>
    <div className="level-row"><button className="level-nav" onClick={()=>load(level-1)}>‹</button><div className="level-title"><small>LEVEL {String(level+1).padStart(2,"0")}</small><strong>{data.name}</strong></div><button className="level-nav" onClick={()=>load(level+1)}>›</button></div>
    <div className="stats"><div><span>LANGKAH</span><strong>{String(moves).padStart(2,"0")}</strong></div><div className="goal-pill"><i/><strong>{fmt(time)}</strong><small>WAKTU</small></div><div><span>TERSISA</span><strong>{pieces.length}</strong></div></div>
    <div className="block-board"><div className="block-exit">EXIT</div>{Array.from({length:SIZE*SIZE},(_,i)=><i key={i} className="block-grid" style={{"--x":i%SIZE,"--y":Math.floor(i/SIZE)} as React.CSSProperties}/>)}
      {pieces.flatMap(p=>cells(p).map((c,index)=><button key={`${p.id}-${index}`} className={`block-cell ${p.shape==="L"?"shape-l":"shape-i"} ${p.color} ${selected===p.id?"selected":""}`} style={{"--x":c.x,"--y":c.y} as React.CSSProperties} onPointerDown={e=>dragStart(e,p.id)} onPointerUp={dragEnd} onPointerCancel={()=>{drag.current=null}} aria-label={`Balok ${p.shape}, geret lurus`}/>))}
    </div>
    <p className={`tip ${blocked?"blocked-tip":""}`}><span>☝</span>{current?`Balok ${current.shape} dipilih — tarik lurus pada sumbunya`:`Horizontal: kiri–kanan. Vertikal: atas–bawah.`}</p>
    <div className="controls"><button onClick={undo} disabled={!history.length}><span>↶</span>Urungkan</button><button className="reset" onClick={()=>load(level)}><span>↻</span>Ulangi</button><button onClick={()=>setHelp(true)}><span>?</span>Petunjuk</button></div>
  </section>
  {help&&<div className="overlay"><div className="modal"><span className="modal-kicker">CARA BERMAIN</span><h2>Balok I & L</h2><p>Keluarkan semua balok panjang berbentuk I dan L dari papan.</p><p>Balok horizontal hanya bisa ditarik kiri–kanan. Balok vertikal hanya bisa ditarik atas–bawah. Keluarkan penghalangnya lebih dahulu.</p><button className="play-btn" onClick={()=>{localStorage.setItem("block-puzzle-seen","1");setHelp(false)}}>Mulai bermain →</button></div></div>}
  {won&&<div className="overlay"><div className="modal"><div className="burst">✓</div><h2>Papan kosong!</h2><p>Semua balok keluar dalam {fmt(time)}.</p><button className="play-btn" onClick={()=>load(level===levels.length-1?0:level+1)}>Level berikutnya →</button></div></div>}
  </main>
}
