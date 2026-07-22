"use client";
import { useEffect, useRef, useState } from "react";

type Kind="sedan"|"suv"|"truck"|"container";
type Vehicle={id:string;x:number;y:number;dir:0|90|180|270;kind:Kind;color:string};
const SIZE=10;
const colors=["red","blue","yellow","mint","purple","orange","pink"];
const kinds:Kind[]=["sedan","suv","sedan","truck","suv","container"];
const lengthOf=(k:Kind)=>k==="container"?4:k==="truck"?3:2;
const vector=(dir:number)=>dir===0?{x:1,y:0}:dir===90?{x:0,y:1}:dir===180?{x:-1,y:0}:{x:0,y:-1};
const cells=(v:Vehicle)=>{const d=vector(v.dir),n=lengthOf(v.kind);return Array.from({length:n},(_,i)=>({x:v.x+d.x*i,y:v.y+d.y*i}));};
const clone=(v:Vehicle[])=>v.map(x=>({...x}));
function makeLevel(level:number,count:number){
  let seed=9487+level*731;const rnd=()=>((seed=seed*1664525+1013904223>>>0)/4294967296);
  const vehicles:Vehicle[]=[],used=new Set<string>();let attempts=0;
  while(vehicles.length<count&&attempts++<4000){
    const i=vehicles.length,kind=kinds[(i+level)%kinds.length],n=lengthOf(kind),horizontal=rnd()>.46;
    const sx=Math.floor(rnd()*(horizontal?SIZE-n+1:SIZE)),sy=Math.floor(rnd()*(horizontal?SIZE:SIZE-n+1));
    const dir:Vehicle["dir"]=horizontal?(sx+n/2<SIZE/2?180:0):(sy+n/2<SIZE/2?270:90);
    const v:Vehicle={id:`${level}-${i}`,x:dir===180?sx+n-1:sx,y:dir===270?sy+n-1:sy,dir,kind,color:colors[(i+level)%colors.length]};
    const own=cells(v);if(own.some(c=>used.has(`${c.x},${c.y}`)))continue;
    own.forEach(c=>used.add(`${c.x},${c.y}`));vehicles.push(v);
  }
  return {name:`Parking Jam 2D — ${vehicles.length} kendaraan`,vehicles};
}
const levels=Array.from({length:13},(_,i)=>makeLevel(i+1,i+8));
const fmt=(ms:number)=>{const s=Math.floor(ms/1000);return`${String(Math.floor(s/60)).padStart(2,"0")}:${String(s%60).padStart(2,"0")}.${Math.floor(ms%1000/100)}`};

export default function Home(){
  const[level,setLevel]=useState(0),[vehicles,setVehicles]=useState(()=>clone(levels[0].vehicles));
  const[selected,setSelected]=useState<string|null>(null),[moves,setMoves]=useState(0),[history,setHistory]=useState<Vehicle[][]>([]),[won,setWon]=useState(false),[help,setHelp]=useState(true),[time,setTime]=useState(0),[blocked,setBlocked]=useState(false);
  const started=useRef(0);const drag=useRef<{id:string;x:number;y:number}|null>(null);const data=levels[level];
  useEffect(()=>{if(localStorage.getItem("mall-parking-seen"))setHelp(false)},[]);
  useEffect(()=>{if(won)return;started.current=performance.now();setTime(0);const t=setInterval(()=>setTime(performance.now()-started.current),100);return()=>clearInterval(t)},[level,won]);
  useEffect(()=>{if(!won&&vehicles.length===0)setWon(true)},[vehicles.length,won]);
  function load(i:number){const n=(i+levels.length)%levels.length;setLevel(n);setVehicles(clone(levels[n].vehicles));setSelected(null);setMoves(0);setHistory([]);setWon(false)}
  function tryState(next:Vehicle[],moving:string){
    const car=next.find(v=>v.id===moving);if(!car)return false;const own=cells(car);
    const exits=own.some(c=>c.x>=SIZE)&&car.dir===0&&own.every(c=>c.y===4||c.y===5);
    if(exits){setHistory(h=>[...h,clone(vehicles)]);setVehicles(next.filter(v=>v.id!==moving));setMoves(m=>m+1);setSelected(null);return true}
    if(own.some(c=>c.x<0||c.x>=SIZE||c.y<0||c.y>=SIZE))return false;
    const occupied=new Set<string>();next.filter(v=>v.id!==moving).forEach(v=>cells(v).forEach(c=>occupied.add(`${c.x},${c.y}`)));
    if(own.some(c=>occupied.has(`${c.x},${c.y}`)))return false;
    setHistory(h=>[...h,clone(vehicles)]);setVehicles(next);setMoves(m=>m+1);return true;
  }
  function act(action:"forward"|"back"|"left"|"right",target=selected){
    if(!target)return;const next=clone(vehicles),v=next.find(x=>x.id===target);if(!v)return;
    if(action==="left")v.dir=((v.dir+270)%360) as Vehicle["dir"];
    else if(action==="right")v.dir=((v.dir+90)%360) as Vehicle["dir"];
    else{const d=vector(v.dir),sign=action==="forward"?1:-1;v.x+=d.x*sign;v.y+=d.y*sign;}
    if(!tryState(next,v.id)){setBlocked(true);setTimeout(()=>setBlocked(false),280)}
  }
  function dragStart(e:React.PointerEvent,id:string){e.currentTarget.setPointerCapture(e.pointerId);drag.current={id,x:e.clientX,y:e.clientY};setSelected(id)}
  function dragEnd(e:React.PointerEvent){
    const start=drag.current;if(!start)return;drag.current=null;const dx=e.clientX-start.x,dy=e.clientY-start.y;if(Math.hypot(dx,dy)<16)return;
    const desired:Vehicle["dir"]=Math.abs(dx)>Math.abs(dy)?(dx>0?0:180):(dy>0?90:270);const car=vehicles.find(v=>v.id===start.id);if(!car||desired!==car.dir){setBlocked(true);setTimeout(()=>setBlocked(false),280);return}
    const own=cells(car),d=vector(car.dir),front=own[own.length-1],occupied=new Set<string>();vehicles.filter(v=>v.id!==car.id).forEach(v=>cells(v).forEach(c=>occupied.add(`${c.x},${c.y}`)));
    let x=front.x+d.x,y=front.y+d.y,clear=true;while(x>=0&&x<SIZE&&y>=0&&y<SIZE){if(occupied.has(`${x},${y}`)){clear=false;break}x+=d.x;y+=d.y}
    if(!clear){setBlocked(true);setTimeout(()=>setBlocked(false),280);return}
    setHistory(h=>[...h,clone(vehicles)]);setVehicles(old=>old.filter(v=>v.id!==car.id));setMoves(m=>m+1);setSelected(null);
  }
  function undo(){const p=history.at(-1);if(!p)return;setVehicles(clone(p));setHistory(h=>h.slice(0,-1));setMoves(m=>Math.max(0,m-1));setWon(false)}
  const current=vehicles.find(v=>v.id===selected);
  return <main className="app-shell"><section className="game-card">
    <header className="topbar"><div><span className="eyebrow">MALL PARKING PUZZLE</span><h1>KELUAR<span>.</span></h1></div><button className="icon-btn" onClick={()=>setHelp(true)}>?</button></header>
    <div className="level-row"><button className="level-nav" onClick={()=>load(level-1)}>‹</button><div className="level-title"><small>LEVEL {String(level+1).padStart(2,"0")}</small><strong>{data.name}</strong></div><button className="level-nav" onClick={()=>load(level+1)}>›</button></div>
    <div className="stats"><div><span>LANGKAH</span><strong>{String(moves).padStart(2,"0")}</strong></div><div className="goal-pill"><i/><strong>{fmt(time)}</strong><small>WAKTU</small></div><div><span>TERSISA</span><strong>{vehicles.length}</strong></div></div>
    <div className="mall-board jam-board"><div className="exit-gate"><b>EXIT</b> ➜</div><div className="aisle-mark">PARKING JAM</div><div className="pillar p1"/><div className="pillar p2"/>
      {Array.from({length:SIZE*SIZE},(_,i)=><i key={i} className="jam-slot" style={{"--x":i%SIZE,"--y":Math.floor(i/SIZE)} as React.CSSProperties}/>) }
      {vehicles.map(v=>{const n=lengthOf(v.kind),d=vector(v.dir);const minX=Math.min(v.x,v.x+d.x*(n-1)),minY=Math.min(v.y,v.y+d.y*(n-1));const horizontal=v.dir===0||v.dir===180;return <button key={v.id} className={`vehicle ${v.kind} ${v.color} ${selected===v.id?"selected":""}`} style={{"--x":minX,"--y":minY,"--w":horizontal?n:1,"--h":horizontal?1:n,"--rot":`${v.dir}deg`} as React.CSSProperties} onPointerDown={e=>dragStart(e,v.id)} onPointerUp={dragEnd} onPointerCancel={()=>{drag.current=null}} aria-label={`${v.kind}, geret kendaraan`}><span className="vehicle-shell"><i className="glass front"/><i className="roof"/><i className="glass rear"/><i className="cargo"/><i className="lamp l1"/><i className="lamp l2"/></span><i className="wheel w1"/><i className="wheel w2"/><i className="wheel w3"/><i className="wheel w4"/><small>{v.kind==="container"?"CONTAINER":v.kind.toUpperCase()}</small></button>})}
    </div>
    <p className={`tip ${blocked?"blocked-tip":""}`}><span>☝</span>{current?`${current.kind.toUpperCase()} dipilih — tarik sesuai arah depannya`:`Tarik kendaraan ke arah hadapnya jika jalan di depan kosong.`}</p>
    <div className="controls"><button onClick={undo} disabled={!history.length}><span>↶</span>Urungkan</button><button className="reset" onClick={()=>load(level)}><span>↻</span>Ulangi</button><button onClick={()=>setHelp(true)}><span>?</span>Petunjuk</button></div>
  </section>
  {help&&<div className="overlay"><div className="modal"><span className="modal-kicker">CARA BERMAIN</span><h2>Parking Jam 2D</h2><p>Parkiran sangat padat berisi sedan, SUV, truk, dan kontainer. Tarik kendaraan mengikuti arah depannya.</p><p>Jika jalur lurus di depan masih terhalang, keluarkan kendaraan penghalang lebih dahulu. Semua kendaraan yang lolos otomatis menuju satu pintu EXIT.</p><button className="play-btn" onClick={()=>{localStorage.setItem("mall-parking-seen","1");setHelp(false)}}>Mulai bermain →</button></div></div>}
  {won&&<div className="overlay"><div className="modal"><div className="burst">✓</div><h2>Parkiran kosong!</h2><p>Semua kendaraan keluar dalam {fmt(time)}.</p><button className="play-btn" onClick={()=>load(level===levels.length-1?0:level+1)}>Level berikutnya →</button></div></div>}
  </main>
}
