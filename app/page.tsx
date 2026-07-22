"use client";
import { useEffect, useRef, useState } from "react";

type Direction=0|90|180|270;
type Shape="I"|"L"|"J"|"T"|"F"|"Z";
type Theme="dark"|"midnight"|"forest"|"plum"|"sand";
type Piece={id:string;x:number;y:number;dir:Direction;shape:Shape;length:number;color:string};
type Cell={x:number;y:number};
type Result={score:number;stars:number;time:number};
const COLS=28,ROWS=42;
const TEST_ALL_LEVELS=true;
const colors=["red","blue","yellow","mint","purple","orange","pink"];
const shapes:Shape[]=["I","L","J","T","F","Z","L","T"];
const themes:{id:Theme;name:string}[]=[{id:"dark",name:"Gelap"},{id:"midnight",name:"Midnight"},{id:"forest",name:"Forest"},{id:"plum",name:"Plum"},{id:"sand",name:"Sand"}];
const guideSteps=[
  {icon:"◎",title:"Kosongkan papan",text:"Tujuannya sederhana: keluarkan semua balok sampai tidak ada satu pun yang tersisa."},
  {icon:"↔",title:"Geret lurus",text:"Balok horizontal hanya dapat digeret ke kiri atau kanan. Ikuti arah panjang balok."},
  {icon:"↕",title:"Buka jalannya",text:"Balok vertikal hanya dapat digeret ke atas atau bawah. Keluarkan balok yang tidak terhalang lebih dahulu."},
  {icon:"★",title:"Siap bermain!",text:"Pilih mode Santai atau Tantangan. Selesaikan lebih cepat dan gunakan sedikit petunjuk untuk mendapat 3 bintang."}
];
const vector=(dir:Direction)=>dir===0?{x:1,y:0}:dir===90?{x:0,y:1}:dir===180?{x:-1,y:0}:{x:0,y:-1};
const rotate=(x:number,y:number,dir:Direction):Cell=>dir===0?{x,y}:dir===90?{x:-y,y:x}:dir===180?{x:-x,y:-y}:{x:y,y:-x};
const base=(shape:Shape,length:number):Cell[]=>{const line=Array.from({length},(_,x)=>({x,y:0})),mid=Math.max(1,Math.floor((length-1)/2));return shape==="I"?line
  :shape==="L"?[...line,{x:length-1,y:1}]
  :shape==="J"?[{x:0,y:1},...line]
  :shape==="T"?[...line,{x:mid,y:1}]
  :shape==="F"?[...line,{x:mid,y:1},{x:Math.min(length-1,mid+1),y:1}]
  :[...line,{x:mid,y:-1},{x:Math.max(0,mid-1),y:1}]};
const cells=(p:Piece)=>base(p.shape,p.length).map(c=>{const r=rotate(c.x,c.y,p.dir);return{x:p.x+r.x,y:p.y+r.y}});
const edges=(own:Cell[],c:Cell)=>{const set=new Set(own.map(v=>`${v.x},${v.y}`));return[[0,-1,"top"],[1,0,"right"],[0,1,"bottom"],[-1,0,"left"]].filter(([dx,dy])=>!set.has(`${c.x+Number(dx)},${c.y+Number(dy)}`)).map(v=>`edge-${v[2]}`).join(" ")};
const clone=(pieces:Piece[])=>pieces.map(p=>({...p}));

function makeLevel(level:number,count:number){
  let seed=5849+level*941;const rnd=()=>((seed=seed*1664525+1013904223>>>0)/4294967296);
  let best:Piece[]=[];
  for(let restart=0;restart<80&&best.length<count;restart++){
    const pieces:Piece[]=[],used=new Set<string>();
    for(let i=0;i<count;i++){
      const shape=shapes[(i+level)%shapes.length],length=shape==="I"?2+(i+level)%6:3+(i*3+level)%5;let placed=false;
      for(let attempt=0;attempt<700&&!placed;attempt++){
        const x=Math.floor(rnd()*COLS),y=Math.floor(rnd()*ROWS),horizontal=rnd()>.5;
        const dir:Direction=horizontal?(x<COLS/2?180:0):(y<ROWS/2?270:90);
        const probe:Piece={id:`${level}-${i}`,x,y,dir,shape,length,color:colors[(i+level)%colors.length]};
        const own=cells(probe);
        if(own.some(c=>c.x<0||c.x>=COLS||c.y<0||c.y>=ROWS||used.has(`${c.x},${c.y}`)))continue;
        own.forEach(c=>used.add(`${c.x},${c.y}`));pieces.push(probe);placed=true;
      }
      if(!placed)break;
    }
    if(pieces.length>best.length)best=pieces;
  }
  return{pieces:best};
}
const levels=Array.from({length:17},(_,i)=>makeLevel(i+4,8+Math.round((i+3)*92/19)));
const fmt=(ms:number)=>{const s=Math.floor(ms/1000);return`${String(Math.floor(s/60)).padStart(2,"0")}:${String(s%60).padStart(2,"0")}`};
const parFor=(i:number)=>(20+levels[i].pieces.length*2.2)*1000;
const challengeFor=(i:number)=>(45+levels[i].pieces.length*2.8)*1000;

export default function Home(){
  const[level,setLevel]=useState(0),[pieces,setPieces]=useState(()=>clone(levels[0].pieces));
  const[round,setRound]=useState(0);
  const[selected,setSelected]=useState<string|null>(null),[moves,setMoves]=useState(0),[history,setHistory]=useState<Piece[][]>([]),[won,setWon]=useState(false),[help,setHelp]=useState(false),[entryOpen,setEntryOpen]=useState(true),[entryNote,setEntryNote]=useState<string|null>(null),[onboarding,setOnboarding]=useState(true),[guidePage,setGuidePage]=useState(0),[time,setTime]=useState(0),[paused,setPaused]=useState(false),[blocked,setBlocked]=useState(false),[showGrid,setShowGrid]=useState(true),[theme,setTheme]=useState<Theme>("dark"),[shopOpen,setShopOpen]=useState(false),[modeOpen,setModeOpen]=useState(false),[challengeMode,setChallengeMode]=useState(false),[timedOut,setTimedOut]=useState(false),[mistakes,setMistakes]=useState(0),[hintsUsed,setHintsUsed]=useState(0),[tokens,setTokens]=useState(3),[unlocked,setUnlocked]=useState(1),[bestStars,setBestStars]=useState<Record<number,number>>({}),[hintId,setHintId]=useState<string|null>(null),[result,setResult]=useState<Result|null>(null),[adLoading,setAdLoading]=useState(false),[noAds,setNoAds]=useState(false),[dragOffset,setDragOffset]=useState<{id:string;dx:number;dy:number}|null>(null),[exiting,setExiting]=useState<{piece:Piece;direction:Direction}|null>(null);
  const started=useRef(0),elapsedBeforePause=useRef(0),exitTimer=useRef<ReturnType<typeof setTimeout>|null>(null);const drag=useRef<{id:string;x:number;y:number}|null>(null);
  useEffect(()=>{setEntryOpen(localStorage.getItem("block-entry-v1")!=="1");setOnboarding(localStorage.getItem("block-onboarding-v2")!=="1");if(localStorage.getItem("block-grid-visible")==="0")setShowGrid(false);const saved=localStorage.getItem("block-theme") as Theme|null;if(saved&&themes.some(t=>t.id===saved))setTheme(saved);setChallengeMode(localStorage.getItem("block-challenge-mode")==="1");setTokens(Number(localStorage.getItem("block-tokens")??3));let savedUnlocked=Number(localStorage.getItem("block-unlocked")??1),savedStars:Record<number,number>={};try{savedStars=JSON.parse(localStorage.getItem("block-stars")??"{}")}catch{}if(!localStorage.getItem("block-levels-trimmed-v1")){savedUnlocked=Math.max(1,savedUnlocked-3);savedStars=Object.fromEntries(Object.entries(savedStars).filter(([key])=>Number(key)>=3).map(([key,value])=>[Number(key)-3,value]));localStorage.setItem("block-unlocked",String(savedUnlocked));localStorage.setItem("block-stars",JSON.stringify(savedStars));localStorage.setItem("block-levels-trimmed-v1","1")}setUnlocked(Math.min(levels.length,Math.max(1,savedUnlocked)));setBestStars(savedStars);setNoAds(localStorage.getItem("block-no-ads")==="1")},[]);
  useEffect(()=>{if(won||timedOut||entryOpen||onboarding||paused)return;const base=elapsedBeforePause.current;started.current=performance.now();const limit=challengeFor(level);const t=setInterval(()=>{const elapsed=base+performance.now()-started.current;if(challengeMode&&elapsed>=limit){setTime(limit);setTimedOut(true);clearInterval(t);return}setTime(elapsed)},100);return()=>clearInterval(t)},[level,round,won,timedOut,challengeMode,entryOpen,onboarding,paused]);
  useEffect(()=>{if(!won&&pieces.length===0&&!exiting){const par=parFor(level),stars=time<=par&&hintsUsed===0&&mistakes<=2?3:time<=par*1.6?2:1,score=Math.max(100,Math.round(1000+Math.max(0,(par-time)/1000)*10-mistakes*25-hintsUsed*100));setResult({score,stars,time});setWon(true);const nextUnlocked=Math.min(levels.length,Math.max(unlocked,level+2));setUnlocked(nextUnlocked);localStorage.setItem("block-unlocked",String(nextUnlocked));setBestStars(old=>{const next={...old,[level]:Math.max(old[level]??0,stars)};localStorage.setItem("block-stars",JSON.stringify(next));return next})}},[pieces.length,exiting,won,time,hintsUsed,mistakes,level,unlocked]);
  function load(i:number){const n=Math.max(0,Math.min(i,levels.length-1)),saved=Number(localStorage.getItem("block-unlocked")??1),available=TEST_ALL_LEVELS?levels.length:Math.max(unlocked,Number.isFinite(saved)?saved:1);if(n+1>available)return;if(exitTimer.current)clearTimeout(exitTimer.current);exitTimer.current=null;setExiting(null);elapsedBeforePause.current=0;setLevel(n);setPieces(clone(levels[n].pieces));setSelected(null);setDragOffset(null);setMoves(0);setMistakes(0);setHintsUsed(0);setTime(0);setPaused(false);setResult(null);setHistory([]);setTimedOut(false);setWon(false);setRound(r=>r+1)}
  function goPrevious(){if(TEST_ALL_LEVELS)load(level>0?level-1:levels.length-1);else if(level>0)load(level-1)}
  function goNext(){if(level<levels.length-1&&(TEST_ALL_LEVELS||level+1<unlocked))load(level+1)}
  function dragStart(e:React.PointerEvent,id:string){if(exiting||paused)return;e.currentTarget.setPointerCapture(e.pointerId);drag.current={id,x:e.clientX,y:e.clientY};setDragOffset({id,dx:0,dy:0});setSelected(id)}
  function dragMove(e:React.PointerEvent){const start=drag.current;if(!start)return;const piece=pieces.find(p=>p.id===start.id);if(!piece)return;const horizontal=piece.dir===0||piece.dir===180;setDragOffset({id:start.id,dx:horizontal?e.clientX-start.x:0,dy:horizontal?0:e.clientY-start.y})}
  function fail(){setMistakes(m=>m+1);setBlocked(true);setTimeout(()=>setBlocked(false),300)}
  function canExit(piece:Piece,desired:Direction){const d=vector(desired),occupied=new Set<string>();pieces.filter(p=>p.id!==piece.id).forEach(p=>cells(p).forEach(c=>occupied.add(`${c.x},${c.y}`)));for(const c of cells(piece)){let x=c.x+d.x,y=c.y+d.y;while(x>=0&&x<COLS&&y>=0&&y<ROWS){if(occupied.has(`${x},${y}`))return false;x+=d.x;y+=d.y}}return true}
  function dragEnd(e:React.PointerEvent){
    const start=drag.current;if(!start)return;drag.current=null;setDragOffset(null);const dx=e.clientX-start.x,dy=e.clientY-start.y;const piece=pieces.find(p=>p.id===start.id);if(!piece)return;
    const horizontal=piece.dir===0||piece.dir===180,axisDistance=horizontal?dx:dy;if(Math.abs(axisDistance)<16)return;
    const desired:Direction=horizontal?(axisDistance>0?0:180):(axisDistance>0?90:270);
    if(!canExit(piece,desired)){fail();return}setHistory(h=>[...h,clone(pieces)]);setExiting({piece:{...piece},direction:desired});setPieces(old=>old.filter(p=>p.id!==piece.id));setMoves(m=>m+1);setSelected(null);exitTimer.current=setTimeout(()=>{setExiting(null);exitTimer.current=null},480);
  }
  function undo(){const previous=history.at(-1);if(!previous)return;if(exitTimer.current)clearTimeout(exitTimer.current);exitTimer.current=null;setExiting(null);setPieces(clone(previous));setHistory(h=>h.slice(0,-1));setMoves(m=>Math.max(0,m-1));setWon(false)}
  function toggleGrid(){setShowGrid(v=>{const next=!v;localStorage.setItem("block-grid-visible",next?"1":"0");return next})}
  function chooseTheme(next:Theme){setTheme(next);localStorage.setItem("block-theme",next)}
  function chooseMode(challenge:boolean){setChallengeMode(challenge);localStorage.setItem("block-challenge-mode",challenge?"1":"0");setModeOpen(false);load(level)}
  function finishGuide(){localStorage.setItem("block-onboarding-v2","1");setOnboarding(false);setGuidePage(0)}
  function openGuide(){setHelp(false);setGuidePage(0);setOnboarding(true)}
  function togglePause(){if(won||timedOut)return;if(paused){setPaused(false);return}elapsedBeforePause.current=time;drag.current=null;setDragOffset(null);setSelected(null);setPaused(true)}
  function enterAsGuest(){localStorage.setItem("block-entry-v1","1");setEntryOpen(false);setEntryNote(null)}
  function showSignInNote(provider:string){setEntryNote(`Masuk dengan ${provider} akan tersedia setelah layanan akun dihubungkan.`)}
  function openEntry(){elapsedBeforePause.current=time;setEntryNote(null);setHelp(false);setEntryOpen(true)}
  function useHint(){if(tokens<1){setShopOpen(true);return}const piece=pieces.find(p=>{const horizontal=p.dir===0||p.dir===180;return (horizontal?[0,180]:[90,270] as Direction[]).some(d=>canExit(p,d as Direction))});if(!piece)return;const next=tokens-1;setTokens(next);localStorage.setItem("block-tokens",String(next));setHintsUsed(h=>h+1);setHintId(piece.id);setTimeout(()=>setHintId(null),2500)}
  function rewardDemo(){if(adLoading)return;setAdLoading(true);setTimeout(()=>{setAdLoading(false);const next=tokens+1;setTokens(next);localStorage.setItem("block-tokens",String(next))},1500)}
  function tokenPackDemo(){const next=tokens+10;setTokens(next);localStorage.setItem("block-tokens",String(next))}
  function noAdsDemo(){setNoAds(true);localStorage.setItem("block-no-ads","1")}
  const canGoPrevious=TEST_ALL_LEVELS||level>0,canGoNext=level<levels.length-1&&(TEST_ALL_LEVELS||level+1<unlocked),remaining=Math.max(0,challengeFor(level)-time),score=Math.max(0,1000-moves*5-mistakes*25-hintsUsed*100);
  return <main className={`app-shell theme-${theme}`}><section className="game-card">
    <header className="game-hud"><button className={`hud-pause ${paused?"paused":""}`} onClick={togglePause} aria-label={paused?"Lanjutkan permainan":"Jeda permainan"}>{paused?"▶":<span className="pause-mark"/>}</button><div className="hud-score"><small>SCORE</small><strong>{score.toLocaleString("id-ID")}</strong></div><div className={`hud-time ${challengeMode&&remaining<=10000?"time-danger":""}`}><small>{challengeMode?"TANTANGAN":"WAKTU"}</small><strong>{fmt(challengeMode?remaining:time)}</strong></div></header>
    <div className={`block-board ${blocked?"board-blocked":""} ${showGrid?"":"grid-off"}`}>
      {[...pieces,...(exiting?[exiting.piece]:[])].flatMap(p=>{const own=cells(p),offset=dragOffset?.id===p.id?dragOffset:null,isExiting=exiting?.piece.id===p.id,exitClass=isExiting?` exiting exit-${exiting.direction===0?"right":exiting.direction===180?"left":exiting.direction===90?"down":"up"}`:"";return own.map((c,index)=><button key={`${p.id}-${index}`} className={`block-cell shape-${p.shape.toLowerCase()} ${edges(own,c)} ${p.color} ${selected===p.id?"selected":""} ${hintId===p.id?"hinted":""} ${offset?"dragging":""}${exitClass}`} style={{"--x":c.x,"--y":c.y,"--drag-x":`${offset?.dx??0}px`,"--drag-y":`${offset?.dy??0}px`} as React.CSSProperties} onPointerDown={isExiting?undefined:e=>dragStart(e,p.id)} onPointerMove={isExiting?undefined:dragMove} onPointerUp={isExiting?undefined:dragEnd} onPointerCancel={isExiting?undefined:()=>{drag.current=null;setDragOffset(null)}} aria-label="Balok variasi, geret lurus"/>)})}
      {paused&&<div className="pause-cover"><div className="pause-panel"><div className="pause-logo"><span>Balok</span><b>Kosong</b></div><small className="pause-level-label">LEVEL {String(level+1).padStart(2,"0")}</small><div className="pause-level-nav"><button onClick={goPrevious} disabled={!canGoPrevious} aria-label="Level sebelumnya">‹</button><span>{String(level+1).padStart(2,"0")}</span><button onClick={goNext} disabled={!canGoNext} aria-label="Level berikutnya">›</button></div><div className="pause-menu"><button onClick={undo} disabled={!history.length}><b>↶</b>Urungkan</button><button onClick={()=>load(level)}><b>↻</b>Ulangi</button><button onClick={useHint}><b>◆</b>Petunjuk</button><button onClick={()=>setModeOpen(true)} className={challengeMode?"active-mode":""}><b>⏱</b>Mode</button><button onClick={()=>setHelp(true)}><b>?</b>Aturan</button></div><button className="pause-resume" onClick={togglePause}><b>▶</b>LANJUTKAN</button></div></div>}
    </div>
  </section>
  {entryOpen&&<div className="entry-screen"><div className="entry-content"><div className="entry-title"><span>Balok</span><b>Kosong</b></div><p className="entry-tagline">BEBASKAN SEMUA BALOK</p><div className="entry-actions"><button className="entry-btn apple" onClick={()=>showSignInNote("Apple")}><b>●</b><span>MASUK DENGAN APPLE</span></button><button className="entry-btn facebook" onClick={()=>showSignInNote("Facebook")}><b>f</b><span>MASUK DENGAN FACEBOOK</span></button><button className="entry-btn guest" onClick={enterAsGuest}><span>MAIN SEBAGAI TAMU</span></button>{entryNote&&<small className="entry-note">{entryNote}</small>}</div><p className="entry-terms">Dengan mengetuk Apple, Facebook, atau Tamu,<br/>Anda menyetujui <u>Ketentuan Penggunaan</u> dan <u>Kebijakan Privasi</u>.</p></div></div>}
  {onboarding&&<div className="overlay guide-overlay"><div className="modal guide-modal"><span className="modal-kicker">CARA BERMAIN · {guidePage+1}/{guideSteps.length}</span><div className={`guide-visual guide-visual-${guidePage}`}><b>{guideSteps[guidePage].icon}</b><i/><i/><i/></div><h2>{guideSteps[guidePage].title}</h2><p>{guideSteps[guidePage].text}</p><div className="guide-dots">{guideSteps.map((_,i)=><i key={i} className={i===guidePage?"active":""}/>)}</div><div className="guide-actions">{guidePage>0&&<button className="guide-back" onClick={()=>setGuidePage(p=>p-1)}>Kembali</button>}<button className="play-btn" onClick={()=>guidePage<guideSteps.length-1?setGuidePage(p=>p+1):finishGuide()}>{guidePage<guideSteps.length-1?"Berikutnya →":"Mulai bermain →"}</button></div></div></div>}
  {modeOpen&&<div className="overlay"><div className="modal"><span className="modal-kicker">PILIH MODE</span><h2>Cara bermain</h2><div className="mode-list"><button className={!challengeMode?"active":""} onClick={()=>chooseMode(false)}><b>∞</b><span><strong>Santai</strong><small>Timer menghitung waktu, tidak ada batas.</small></span></button><button className={challengeMode?"active":""} onClick={()=>chooseMode(true)}><b>⏱</b><span><strong>Tantangan</strong><small>Countdown habis = ulang level ini.</small></span></button></div><button className="text-btn" onClick={()=>setModeOpen(false)}>Batal</button></div></div>}
  {shopOpen&&<div className="overlay"><div className="modal shop-modal"><span className="modal-kicker">TOKO & BANTUAN</span><h2>◆ {tokens} token</h2><p>Token hanya untuk petunjuk. Progres level tidak pernah dihapus.</p><div className="shop-list"><button onClick={rewardDemo}><b>▶</b><span><strong>+1 Token</strong><small>{adLoading?"Memutar iklan demo…":"Iklan berhadiah (demo web)"}</small></span></button><button onClick={tokenPackDemo}><b>◆</b><span><strong>+10 Token</strong><small>Pembelian demo — belum ditagih</small></span></button><button onClick={noAdsDemo} disabled={noAds}><b>⊘</b><span><strong>{noAds?"Bebas iklan aktif":"Bebas Iklan"}</strong><small>Pembelian sekali (demo web)</small></span></button></div><p className="store-note">Pembayaran dan iklan produksi aktif setelah ID App Store, Google Play, dan AdMob dihubungkan.</p><button className="text-btn" onClick={()=>setShopOpen(false)}>Tutup</button></div></div>}
  {help&&<div className="overlay"><div className="modal settings-modal"><span className="modal-kicker">ATURAN & PENGATURAN</span><h2>BalokKosong</h2><p>Keluarkan semua balok. Balok horizontal hanya bergerak kiri–kanan dan balok vertikal hanya bergerak atas–bawah.</p><button className="replay-guide" onClick={openGuide}><b>▶</b><span><strong>Lihat cara bermain</strong><small>Panduan singkat 4 halaman</small></span></button><button className="replay-guide" onClick={openEntry}><b>⌂</b><span><strong>Kembali ke halaman utama</strong><small>Pilih akun atau Main sebagai Tamu</small></span></button><div className="setting-row"><span><strong>Tampilkan grid</strong><small>Garis bantu pada papan permainan</small></span><button className={showGrid?"toggle-on":""} onClick={toggleGrid} aria-label="Tampilkan atau sembunyikan grid"><i/></button></div><span className="settings-label">TEMA LATAR</span><div className="theme-grid compact-themes">{themes.map(t=><button key={t.id} className={`theme-choice swatch-${t.id} ${theme===t.id?"active":""}`} onClick={()=>chooseTheme(t.id)}><i/><span>{t.name}</span>{theme===t.id&&<b>✓</b>}</button>)}</div><button className="play-btn" onClick={()=>setHelp(false)}>Tutup</button></div></div>}
  {timedOut&&<div className="overlay"><div className="modal timeout-modal"><div className="timeout-icon">⏱</div><span className="modal-kicker">MODE TANTANGAN</span><h2>Waktu habis!</h2><p>Tenang, progres Anda tetap aman. Ulangi Level {level+1} dan coba jalur yang lebih cepat.</p><button className="play-btn" onClick={()=>load(level)}>Ulangi level ↻</button><button className="text-btn" onClick={()=>chooseMode(false)}>Pindah ke mode Santai</button></div></div>}
  {won&&result&&<div className="overlay"><div className="modal"><div className="result-stars">{"★".repeat(result.stars)}{"☆".repeat(3-result.stars)}</div><h2>{level===levels.length-1?"Selamat!":"Papan kosong!"}</h2><p>{level===levels.length-1?`Semua ${levels.length} level sudah selesai.`:`Waktu ${fmt(result.time)} · ${mistakes} salah · ${hintsUsed} petunjuk`}</p><div className="score-box"><small>NILAI</small><strong>{result.score.toLocaleString("id-ID")}</strong></div><button className="play-btn" onClick={()=>load(level===levels.length-1?0:level+1)}>{level===levels.length-1?"Main lagi ↻":"Level berikutnya →"}</button></div></div>}
  </main>
}
