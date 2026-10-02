// Idle Country round 3 art: shared rendering + drawing kit.
// Style: dark warm ink outlines, cel shading (base + light + shadow + AO), warm rim light, texture patterns, grain.
const {chromium}=require('playwright');const fs=require('fs');const path=require('path');const {execFileSync}=require('child_process');
const OUT=path.join(__dirname,'..');const RAW=path.join(__dirname,'raw');
const INK='#1d140f';
let _id=0;const uid=(p='u')=>p+(++_id);
const f=n=>Math.round(n*100)/100;

// ---------- seeded random ----------
function rng(seed){let s=seed>>>0||1;return()=>{s^=s<<13;s>>>=0;s^=s>>17;s^=s<<5;s>>>=0;return s/4294967296;};}

// ---------- colour helpers ----------
function hex2rgb(h){h=h.replace('#','');if(h.length==3)h=h.split('').map(c=>c+c).join('');return[0,2,4].map(i=>parseInt(h.substr(i,2),16));}
function rgb2hex(r){return'#'+r.map(v=>Math.max(0,Math.min(255,Math.round(v))).toString(16).padStart(2,'0')).join('');}
function mix(a,b,t){const A=hex2rgb(a),B=hex2rgb(b);return rgb2hex(A.map((v,i)=>v+(B[i]-v)*t));}
const shade=(c,t)=>mix(c,'#1a1530',t);   // toward cool dark
const light=(c,t)=>mix(c,'#fff2d6',t);   // toward warm light

// ---------- texture patterns (local units; overlays only, base colour comes from the face) ----------
function patterns(){
 const r=rng(7);let o='';
 // bricks 32x16 (two courses)
 let b='';for(let row=0;row<2;row++)for(let i=-1;i<3;i++){const x=i*16+(row?8:0),y=row*8;const t=r();
  b+=`<rect x="${x+.8}" y="${y+.8}" width="14.4" height="6.4" fill="${t<.33?'#000':t<.66?'#fff':'#7a2a10'}" opacity="${f(.05+r()*.1)}"/>`+
  `<path d="M${x+1} ${y+1.2}h14" stroke="#fff3d8" stroke-width=".8" opacity=".35"/>`;}
 o+=`<pattern id="brick" width="32" height="16" patternUnits="userSpaceOnUse"><rect width="32" height="16" fill="#2a1a12" opacity=".38"/>${b}</pattern>`;
 // ashlar stone 48x24
 let s='';for(let row=0;row<2;row++)for(let i=-1;i<3;i++){const x=i*24+(row?12:0),y=row*12;const t=r();
  s+=`<rect x="${x+1}" y="${y+1}" width="22" height="10" fill="${t<.5?'#000':'#fff'}" opacity="${f(.04+r()*.08)}"/>`+
  `<path d="M${x+1.5} ${y+1.6}h21" stroke="#fff" stroke-width="1" opacity=".35"/><path d="M${x+22.5} ${y+1.5}v9.5" stroke="#000" stroke-width="1" opacity=".18"/>`;}
 o+=`<pattern id="stone" width="48" height="24" patternUnits="userSpaceOnUse"><rect width="48" height="24" fill="#20160f" opacity=".42"/>${s}</pattern>`;
 // big stone blocks 64x32 (castle / foundations)
 let s2='';for(let row=0;row<2;row++)for(let i=-1;i<3;i++){const x=i*32+(row?16:0),y=row*16;const t=r();
  s2+=`<rect x="${x+1.2}" y="${y+1.2}" width="29.6" height="13.6" rx="2" fill="${t<.5?'#000':'#fff'}" opacity="${f(.05+r()*.1)}"/>`+
  `<path d="M${x+2} ${y+2.2}h27" stroke="#fff" stroke-width="1.2" opacity=".35"/><path d="M${x+5} ${y+9}l4 2" stroke="#000" stroke-width=".8" opacity=".25"/>`;}
 o+=`<pattern id="block" width="64" height="32" patternUnits="userSpaceOnUse"><rect width="64" height="32" fill="#1c140e" opacity=".45"/>${s2}</pattern>`;
 // vertical planks 12 wide
 o+=`<pattern id="plank" width="24" height="60" patternUnits="userSpaceOnUse"><rect width="24" height="60" fill="#000" opacity="0"/><rect x="12" width="12" height="60" fill="#000" opacity=".07"/>
 <path d="M0 0v60M12 0v60" stroke="#1a0e06" stroke-width="1.3" opacity=".55"/><path d="M1.3 0v60M13.3 0v60" stroke="#fff" stroke-width=".8" opacity=".25"/>
 <path d="M4 5c1 8-1 14 0 22M8 30c1 8 -1 14 0 26M17 10c1 8 -1 12 0 20M20 36c-1 6 1 12 0 18" stroke="#2a1608" stroke-width=".7" fill="none" opacity=".35"/>
 <circle cx="6" cy="44" r="1.4" fill="none" stroke="#2a1608" stroke-width=".7" opacity=".4"/><path d="M0 40h12" stroke="#1a0e06" stroke-width="1" opacity=".4"/></pattern>`;
 // horizontal siding / planks 60x10
 o+=`<pattern id="siding" width="60" height="20" patternUnits="userSpaceOnUse"><rect y="10" width="60" height="10" fill="#000" opacity=".06"/>
 <path d="M0 10h60M0 20h60" stroke="#1a0e06" stroke-width="1.3" opacity=".5"/><path d="M0 1h60M0 11h60" stroke="#fff" stroke-width=".9" opacity=".25"/>
 <path d="M6 5c10 1 18-1 30 0M30 15c10 1 18-1 26 0" stroke="#2a1608" stroke-width=".6" fill="none" opacity=".35"/><path d="M40 0v10M15 10v10" stroke="#1a0e06" stroke-width="1" opacity=".4"/></pattern>`;
 // roof shingles 16x10 scalloped rows
 o+=`<pattern id="shingle" width="16" height="10" patternUnits="userSpaceOnUse"><rect width="16" height="10" fill="#000" opacity=".05"/>
 <path d="M0 9.5 q4 -3 8 0 q4 -3 8 0" stroke="#1a0e06" stroke-width="1.2" fill="none" opacity=".55"/><path d="M0 2 q4 -3 8 0 q4 -3 8 0" stroke="#fff" stroke-width=".8" fill="none" opacity=".22"/><path d="M8 0v4M0 5v4" stroke="#1a0e06" stroke-width=".8" opacity=".35"/></pattern>`;
 // terracotta barrel tiles 14x16
 o+=`<pattern id="rtile" width="14" height="16" patternUnits="userSpaceOnUse"><rect width="7" height="16" fill="#fff" opacity=".14"/><rect x="10" width="4" height="16" fill="#000" opacity=".22"/>
 <path d="M0 15.5h14" stroke="#2a0e06" stroke-width="1.6" opacity=".55"/><path d="M1 1.5q6 -2 12 0" stroke="#fff" stroke-width=".8" fill="none" opacity=".3"/><path d="M14 0v16" stroke="#2a0e06" stroke-width="1" opacity=".4"/></pattern>`;
 // slate 20x12
 o+=`<pattern id="slate" width="20" height="24" patternUnits="userSpaceOnUse"><path d="M0 12h20M0 24h20M10 0v12M0 12v12M20 12v12" stroke="#0a0a14" stroke-width="1.2" opacity=".5"/><rect x="1" y="1" width="8" height="2" fill="#fff" opacity=".12"/><rect x="11" y="13" width="8" height="2" fill="#fff" opacity=".12"/><rect x="11" y="1" width="8" height="10" fill="#000" opacity=".08"/></pattern>`;
 // thatch
 let th='';for(let i=0;i<14;i++){const x=r()*24,y=r()*20;th+=`<path d="M${f(x)} ${f(y)}l${f(-1+r()*2)} ${f(6+r()*4)}" stroke="${r()<.5?'#3a2508':'#fff3c0'}" stroke-width=".9" opacity=".45"/>`;}
 o+=`<pattern id="thatch" width="24" height="20" patternUnits="userSpaceOnUse">${th}<path d="M0 19.5h24" stroke="#3a2508" stroke-width="1.4" opacity=".4"/></pattern>`;
 // plaster: soft blotches + hairline cracks
 o+=`<pattern id="plaster" width="90" height="70" patternUnits="userSpaceOnUse"><ellipse cx="20" cy="18" rx="16" ry="9" fill="#000" opacity=".05"/><ellipse cx="65" cy="50" rx="20" ry="11" fill="#fff" opacity=".07"/><ellipse cx="70" cy="12" rx="9" ry="5" fill="#000" opacity=".05"/>
 <path d="M40 30l4 5l-2 6l5 4M10 55l6 -3l3 4" stroke="#2a1a10" stroke-width=".7" fill="none" opacity=".4"/></pattern>`;
 // concrete panels 40x30
 o+=`<pattern id="concrete" width="40" height="30" patternUnits="userSpaceOnUse"><path d="M0 29.5h40M39.5 0v30" stroke="#000" stroke-width="1.2" opacity=".28"/><path d="M0 .7h40M.7 0v30" stroke="#fff" stroke-width=".8" opacity=".2"/><circle cx="4" cy="4" r=".9" fill="#000" opacity=".25"/><circle cx="36" cy="4" r=".9" fill="#000" opacity=".25"/><ellipse cx="22" cy="18" rx="8" ry="4" fill="#000" opacity=".04"/></pattern>`;
 // corrugated metal 6 wide
 o+=`<pattern id="corrug" width="8" height="40" patternUnits="userSpaceOnUse"><rect width="3" height="40" fill="#fff" opacity=".18"/><rect x="5" width="3" height="40" fill="#000" opacity=".22"/><path d="M0 39.5h8" stroke="#000" stroke-width=".7" opacity=".3"/></pattern>`;
 // metal plates with rivets 40x40
 o+=`<pattern id="plate" width="40" height="40" patternUnits="userSpaceOnUse"><path d="M0 39.5h40M39.5 0v40" stroke="#0a0a12" stroke-width="1.3" opacity=".45"/><path d="M0 .8h40M.8 0v40" stroke="#fff" stroke-width=".9" opacity=".22"/>
 ${[[4,4],[36,4],[4,36],[36,36],[20,4],[20,36]].map(([x,y])=>`<circle cx="${x}" cy="${y}" r="1.4" fill="#0a0a12" opacity=".45"/><circle cx="${x-.4}" cy="${y-.4}" r=".7" fill="#fff" opacity=".5"/>`).join('')}</pattern>`;
 // cobbles for ground 28x28
 let cb='';for(let i=0;i<6;i++){const x=(i%3)*9.3+r()*2+4,y=Math.floor(i/3)*14+r()*3+5;cb+=`<ellipse cx="${f(x)}" cy="${f(y)}" rx="${f(3.6+r()*1.2)}" ry="${f(4.6+r()*1.4)}" fill="#fff" opacity="${f(.06+r()*.08)}" stroke="#120c08" stroke-width="1" stroke-opacity=".5"/>`;}
 o+=`<pattern id="cobble" width="28" height="28" patternUnits="userSpaceOnUse"><rect width="28" height="28" fill="#000" opacity=".22"/>${cb}</pattern>`;
 // flagstones 34x34
 o+=`<pattern id="flag" width="34" height="34" patternUnits="userSpaceOnUse"><rect x="1" y="1" width="15" height="15" fill="#fff" opacity=".07"/><rect x="18" y="1" width="15" height="32" fill="#000" opacity=".05"/><rect x="1" y="18" width="15" height="15" fill="#000" opacity=".03"/>
 <path d="M0 .5h34M.5 0v34M17 0v34M0 17h17" stroke="#120c08" stroke-width="1.2" opacity=".45"/><path d="M2 2.5h13M19 2.5h13M2 19.5h13" stroke="#fff" stroke-width=".8" opacity=".3"/><path d="M24 20l3 4l-1 4" stroke="#120c08" stroke-width=".6" fill="none" opacity=".4"/></pattern>`;
 // glass curtain wall 16x24
 o+=`<pattern id="glass" width="16" height="24" patternUnits="userSpaceOnUse"><path d="M0 23.5h16M15.5 0v24" stroke="#0a1420" stroke-width="1.4" opacity=".6"/><path d="M2 20l10 -16" stroke="#fff" stroke-width="2" opacity=".14"/></pattern>`;
 // sci-fi panels 48x32
 o+=`<pattern id="scifi" width="48" height="32" patternUnits="userSpaceOnUse"><path d="M0 31.5h48M47.5 0v32M24 0v14l4 4h20" stroke="#060814" stroke-width="1.1" fill="none" opacity=".45"/><path d="M0 .8h48M.8 0v32" stroke="#fff" stroke-width=".8" opacity=".25"/><rect x="6" y="22" width="8" height="2" rx="1" fill="#7ff4ff" opacity=".55"/></pattern>`;
 // marble veins
 o+=`<pattern id="marble" width="80" height="80" patternUnits="userSpaceOnUse"><path d="M0 20c15 5 25 -5 40 2s30 6 40 0M10 60c10 -6 30 4 45 -2s20 2 25 -4" stroke="#6a5c4a" stroke-width=".7" fill="none" opacity=".25"/><path d="M0 79.5h80" stroke="#3a2c1a" stroke-width="1" opacity=".25"/></pattern>`;
 // packed dirt / gravel for ground
 let gr='';for(let i=0;i<18;i++){gr+=`<ellipse cx="${f(r()*40)}" cy="${f(r()*40)}" rx="${f(.8+r()*1.8)}" ry="${f(.6+r()*1.2)}" fill="${r()<.5?'#fff':'#000'}" opacity="${f(.1+r()*.15)}"/>`;}
 o+=`<pattern id="gravel" width="40" height="40" patternUnits="userSpaceOnUse">${gr}</pattern>`;
 // cloth stripes (awning)
 o+=`<pattern id="stripe" width="16" height="10" patternUnits="userSpaceOnUse"><rect width="8" height="10" fill="#fff6e6" opacity=".9"/></pattern>`;
 // wood grain fine (for crates/furniture) 30x8
 o+=`<pattern id="grain" width="40" height="10" patternUnits="userSpaceOnUse"><path d="M0 3c10 1 20 -1 40 0M0 7c12 -1 25 1 40 0" stroke="#2a1608" stroke-width=".7" fill="none" opacity=".35"/></pattern>`;
 return o;
}
function filters(){
 return `<filter id="blur2" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="2"/></filter>
<filter id="blur4" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="4"/></filter>
<filter id="blur8" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="8"/></filter>
<filter id="blur16" x="-80%" y="-80%" width="260%" height="260%"><feGaussianBlur stdDeviation="16"/></filter>
<filter id="blur30" x="-100%" y="-100%" width="300%" height="300%"><feGaussianBlur stdDeviation="30"/></filter>
<filter id="glow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="5" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
<filter id="dshadow" x="-20%" y="-20%" width="150%" height="150%"><feGaussianBlur in="SourceAlpha" stdDeviation="6"/><feOffset dx="8" dy="10"/><feComponentTransfer><feFuncA type="linear" slope=".45"/></feComponentTransfer><feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge></filter>`;
}
function grads(){
 const lg=(id,stops,x2=0,y2=1)=>`<linearGradient id="${id}" x1="0" y1="0" x2="${x2}" y2="${y2}">${stops.map(([o,c,a=1])=>`<stop offset="${o}" stop-color="${c}" stop-opacity="${a}"/>`).join('')}</linearGradient>`;
 return lg('aoV',[[0,'#000',0],[.6,'#000',0],[1,'#000',.38]])+lg('topLit',[[0,'#fff1cc',.32],[.35,'#fff1cc',0]])+lg('fadeDown',[[0,'#000',0],[1,'#000',.35]])
  +lg('winLit',[[0,'#fff6c8'],[.45,'#ffd36b'],[1,'#e88a2a']])+lg('winDay',[[0,'#bfe3f5'],[.5,'#7fb4d6'],[1,'#3f6d93']])
  +lg('steelH',[[0,'#59626e'],[.18,'#e9eef3'],[.35,'#b7c0ca'],[.7,'#7a8592'],[1,'#3d444e']],1,0)
  +lg('brassH',[[0,'#6b4512'],[.2,'#ffe7a0'],[.4,'#e0b04a'],[.75,'#a7731e'],[1,'#5a3a0e']],1,0)
  +lg('cylL',[[0,'#fff',.0],[.12,'#fff3d8',.35],[.3,'#fff',0],[.62,'#000',0],[1,'#0c0820',.5]],1,0)
  +lg('glassV',[[0,'#cdeaf7'],[.5,'#7fb0cc'],[1,'#2e5571']]);
}
const DEFS=()=>`<defs>${patterns()}${filters()}${grads()}</defs>`;

// ---------- generic ink shape (screen space) ----------
// fill + optional cel shade overlay + ink outline
function ink(d,fill,{w=3,extra='',lw=null}={}){return `<path d="${d}" fill="${fill}" stroke="${INK}" stroke-width="${w}" stroke-linejoin="round" stroke-linecap="round" ${extra}/>`;}
function poly(pts){return 'M'+pts.map(p=>f(p[0])+' '+f(p[1])).join(' L')+'Z';}

// ---------- isometric projector ----------
class Iso{
 constructor(cx,cy,k=1,zk=1.1){this.cx=cx;this.cy=cy;this.k=k;this.zk=zk;
  this.L=norm([-0.4,0.75,1.0]);}
 P([x,y,z]){return[this.cx+(x-y)*this.k,this.cy+(x+y)*this.k/2-z*this.zk*this.k];}
 // planar polygon in world space -> textured, shaded face
 face(pts,o={}){
  const p0=pts[0];let u=norm(sub(pts[1],p0));const n=newell(pts);let v=cross(n,u);if(v[2]>1e-6||(Math.abs(v[2])<1e-6&&(this.P(add(p0,v))[1]<this.P(p0)[1])))v=v.map(a=>-a);
  const loc=pts.map(p=>[dot(sub(p,p0),u),dot(sub(p,p0),v)]);
  const S0=this.P(p0),Su=this.P(add(p0,u)),Sv=this.P(add(p0,v));
  const M=`matrix(${f(Su[0]-S0[0])} ${f(Su[1]-S0[1])} ${f(Sv[0]-S0[0])} ${f(Sv[1]-S0[1])} ${f(S0[0])} ${f(S0[1])})`;
  const xs=loc.map(p=>p[0]),ys=loc.map(p=>p[1]);const bx=Math.min(...xs),by=Math.min(...ys),bw=Math.max(...xs)-bx,bh=Math.max(...ys)-by;
  const id=uid('c');const lp=poly(loc);
  let b=Math.max(0,dot(n[2]<0?n.map(a=>-a):n,this.L));if(o.tone!=null)b=o.tone;
  let base=o.fill||'#999';
  // cel tones: three steps
  const col=b>0.75?light(base,(b-0.75)*0.5):b>0.45?base:b>0.2?shade(base,0.28):shade(base,0.42);
  let inner=`<rect x="${f(bx-2)}" y="${f(by-2)}" width="${f(bw+4)}" height="${f(bh+4)}" fill="${col}"/>`;
  if(o.tex)inner+=`<rect x="${f(bx-2)}" y="${f(by-2)}" width="${f(bw+4)}" height="${f(bh+4)}" fill="url(#${o.tex})" ${o.texOp!=null?`opacity="${o.texOp}"`:''} ${o.texT?`transform="${o.texT}"`:''}/>`;
  if(o.content)inner+=o.content({x:bx,y:by,w:bw,h:bh,loc,lit:b});
  if(o.ao!==false&&o.ao!==0)inner+=`<rect x="${f(bx)}" y="${f(by)}" width="${f(bw)}" height="${f(bh)}" fill="url(#aoV)" opacity="${o.ao||0.9}"/>`;
  if(b>0.45&&o.sheen!==false)inner+=`<rect x="${f(bx)}" y="${f(by)}" width="${f(bw)}" height="${f(bh)}" fill="url(#topLit)"/>`;
  if(o.after)inner+=o.after({x:bx,y:by,w:bw,h:bh});
  const sp=pts.map(p=>this.P(p));
  let out=`<g transform="${M}"><clipPath id="${id}"><path d="${lp}"/></clipPath><g clip-path="url(#${id})">${inner}</g></g>`;
  if(o.stroke!==false)out+=`<path d="${poly(sp)}" fill="none" stroke="${INK}" stroke-width="${o.w||3}" stroke-linejoin="round"/>`;
  if(o.rim)for(const e of o.rim){const a=sp[e],c=sp[(e+1)%sp.length];const cen=centroid(sp);const off=q=>{const d=sub2(cen,q),l=Math.hypot(...d)||1;return[q[0]+d[0]/l*2.6,q[1]+d[1]/l*2.6];};
   const A=off(a),C=off(c);out+=`<path d="M${f(A[0])} ${f(A[1])}L${f(C[0])} ${f(C[1])}" stroke="${o.rimCol||'#ffe2a8'}" stroke-width="${o.rimW||2}" opacity=".85" stroke-linecap="round"/>`;}
  return out;
 }
 // local-coordinate group on a wall face (for decorations without clipping)
 onFace(p0,p1,p2,content){ // p0 origin top-left of face, p1 along u, p2 along v (down)
  const u=norm(sub(p1,p0)),v=norm(sub(p2,p0));const S0=this.P(p0),Su=this.P(add(p0,u)),Sv=this.P(add(p0,v));
  return `<g transform="matrix(${f(Su[0]-S0[0])} ${f(Su[1]-S0[1])} ${f(Sv[0]-S0[0])} ${f(Sv[1]-S0[1])} ${f(S0[0])} ${f(S0[1])})">${content}</g>`;
 }
 // box: x0..x1, y0..y1, z0..z1 ; draws top, left(y=y1), right(x=x1)
 box(x0,y0,z0,x1,y1,z1,o={}){
  const T=o.top||{},Lf=o.left||{},Rf=o.right||{};let s='';
  if(o.noTop!==true)s+=this.face([[x0,y0,z1],[x1,y0,z1],[x1,y1,z1],[x0,y1,z1]],{fill:o.fill,tex:o.topTex,ao:false,rim:[3,0],...T});
  s+=this.face([[x0,y1,z1],[x1,y1,z1],[x1,y1,z0],[x0,y1,z0]],{fill:o.fill,tex:o.tex,...Lf});
  s+=this.face([[x1,y1,z1],[x1,y0,z1],[x1,y0,z0],[x1,y1,z0]],{fill:o.fill,tex:o.tex,...Rf});
  return s;
 }
 shadow(pts,alpha=.32,blur=3){return `<path d="${poly(pts.map(p=>this.P(p)))}" fill="#0b0610" opacity="${alpha}" filter="url(#blur${blur>3?4:2})"/>`;}
 // cast shadow of a box on ground z=0, light from top-left -> shadow toward +x (screen right/down)
 boxShadow(x0,y0,x1,y1,h,alpha=.3,zg=0){const dx=h*0.55,dy=-h*0.12;const pts=[[x0,y0],[x1,y0],[x1,y1],[x0,y1],[x0+dx,y0+dy],[x1+dx,y0+dy],[x1+dx,y1+dy],[x0+dx,y1+dy]].map(([x,y])=>this.P([x,y,zg]));
  return `<path d="${poly(hull(pts))}" fill="#0b0610" opacity="${alpha}" filter="url(#blur2)"/>`;}
 // vertical cylinder centred at (x,y), radius r, z0..z1
 cyl(x,y,r,z0,z1,fill,o={}){const c0=this.P([x,y,z0]),c1=this.P([x,y,z1]);const rx=r*this.k*Math.SQRT2,ry=rx/2;const id=uid('g');
  const body=`M${f(c1[0]-rx)} ${f(c1[1])} L${f(c0[0]-rx)} ${f(c0[1])} A${f(rx)} ${f(ry)} 0 0 0 ${f(c0[0]+rx)} ${f(c0[1])} L${f(c1[0]+rx)} ${f(c1[1])}Z`;
  let s=`<path d="${body}" fill="${fill}"/>`;
  if(o.tex)s+=`<clipPath id="${id}"><path d="${body}"/></clipPath><rect clip-path="url(#${id})" x="${f(c1[0]-rx)}" y="${f(c1[1]-ry)}" width="${f(2*rx)}" height="${f(c0[1]-c1[1]+2*ry)}" fill="url(#${o.tex})"/>`;
  if(o.bands)for(const bz of o.bands){const cb=this.P([x,y,bz]);s+=`<path d="M${f(cb[0]-rx)} ${f(cb[1])} A${f(rx)} ${f(ry)} 0 0 0 ${f(cb[0]+rx)} ${f(cb[1])}" fill="none" stroke="${o.bandCol||INK}" stroke-width="${o.bandW||2.5}"/>`;}
  s+=`<path d="${body}" fill="url(#cylL)"/><path d="${body}" fill="none" stroke="${INK}" stroke-width="${o.w||3}" stroke-linejoin="round"/>`;
  if(o.top!==false)s+=`<ellipse cx="${f(c1[0])}" cy="${f(c1[1])}" rx="${f(rx)}" ry="${f(ry)}" fill="${o.topFill||light(fill,.25)}" stroke="${INK}" stroke-width="${o.w||3}"/>`;
  return s;}
 dome(x,y,r,z,fill,o={}){const c=this.P([x,y,z]);const rx=r*this.k*Math.SQRT2,ry=rx/2,hh=o.h||rx*1.0;const id=uid('d');
  const d=`M${f(c[0]-rx)} ${f(c[1])} C${f(c[0]-rx)} ${f(c[1]-hh*1.3)} ${f(c[0]+rx)} ${f(c[1]-hh*1.3)} ${f(c[0]+rx)} ${f(c[1])} A${f(rx)} ${f(ry)} 0 0 1 ${f(c[0]-rx)} ${f(c[1])}Z`;
  return `<radialGradient id="${id}" cx=".32" cy=".25" r=".85"><stop offset="0" stop-color="${light(fill,.55)}"/><stop offset=".35" stop-color="${fill}"/><stop offset=".75" stop-color="${shade(fill,.3)}"/><stop offset="1" stop-color="${shade(fill,.5)}"/></radialGradient>
  <path d="${d}" fill="url(#${id})"/>${o.ribs?Array.from({length:o.ribs},(_,i)=>{const t=(i+1)/(o.ribs+1);const xx=c[0]-rx+2*rx*t;return `<path d="M${f(xx)} ${f(c[1]+ry*Math.sin(Math.acos(2*t-1))*0.95)} Q${f(c[0]+(xx-c[0])*0.9)} ${f(c[1]-hh*0.9)} ${f(c[0])} ${f(c[1]-hh*0.98)}" fill="none" stroke="${INK}" stroke-width="1.3" opacity=".55"/>`}).join(''):''}
  <path d="${d}" fill="none" stroke="${INK}" stroke-width="3"/>`;}
}
// vector math
const sub=(a,b)=>a.map((v,i)=>v-b[i]),add=(a,b)=>a.map((v,i)=>v+b[i]),dot=(a,b)=>a.reduce((s,v,i)=>s+v*b[i],0);
const cross=(a,b)=>[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]];const norm=a=>{const l=Math.hypot(...a)||1;return a.map(v=>v/l);};
const sub2=(a,b)=>[a[0]-b[0],a[1]-b[1]];const centroid=ps=>[ps.reduce((s,p)=>s+p[0],0)/ps.length,ps.reduce((s,p)=>s+p[1],0)/ps.length];
function newell(ps){let n=[0,0,0];for(let i=0;i<ps.length;i++){const a=ps[i],b=ps[(i+1)%ps.length];n[0]+=(a[1]-b[1])*(a[2]+b[2]);n[1]+=(a[2]-b[2])*(a[0]+b[0]);n[2]+=(a[0]-b[0])*(a[1]+b[1]);}
 n=norm(n);// orient toward viewer: viewer dir is (+1,+1,+something)
 if(dot(n,[1,1,1.2])<0)n=n.map(v=>-v);return n;}
function hull(P){P=P.slice().sort((a,b)=>a[0]-b[0]||a[1]-b[1]);const cr=(o,a,b)=>(a[0]-o[0])*(b[1]-o[1])-(a[1]-o[1])*(b[0]-o[0]);const lo=[],up=[];
 for(const p of P){while(lo.length>=2&&cr(lo[lo.length-2],lo[lo.length-1],p)<=0)lo.pop();lo.push(p);}
 for(const p of P.slice().reverse()){while(up.length>=2&&cr(up[up.length-2],up[up.length-1],p)<=0)up.pop();up.push(p);}
 return lo.slice(0,-1).concat(up.slice(0,-1));}

// ---------- flat-face decorations (local coords, y down) ----------
const W={
 // window with frame, mullions, sill; lit=true warm glow
 win(x,y,w,h,{lit=true,frame='#3a2616',arch=false,shut=null,mull=true,sill=true,glass}={}){
  const g=glass||(lit?'url(#winLit)':'url(#winDay)');
  const d=arch?`M${x} ${y+h}V${y+w/2}A${w/2} ${w/2} 0 0 1 ${x+w} ${y+w/2}V${y+h}Z`:`M${x} ${y}h${w}v${h}h${-w}z`;
  let s=`<path d="${d}" fill="${INK}" stroke="${INK}" stroke-width="3.2"/><path d="${d}" fill="${g}" transform="translate(0 0)"/>`;
  if(lit)s+=`<path d="${d}" fill="#fff4c0" opacity=".25" transform="translate(${x+w/2} ${y+h/2}) scale(.6) translate(${-x-w/2} ${-y-h/2})"/>`;
  if(mull)s+=`<path d="M${x+w/2} ${y+(arch?2:0)}v${h}M${x} ${y+h*0.5}h${w}" stroke="${frame}" stroke-width="2"/>`;
  s+=`<path d="${d}" fill="none" stroke="${frame}" stroke-width="1.6"/>`;
  s+=`<path d="M${x+2} ${y+h-3}L${x+w*0.45} ${y+3}" stroke="#fff" stroke-width="1.6" opacity=".35"/>`;
  if(sill)s+=`<rect x="${x-2.5}" y="${y+h}" width="${w+5}" height="3.5" fill="#d9c7a0" stroke="${INK}" stroke-width="1.6"/>`;
  if(shut)s+=`<rect x="${x-w*0.42-2}" y="${y}" width="${w*0.42}" height="${h}" fill="${shut}" stroke="${INK}" stroke-width="1.8"/><rect x="${x+w+2}" y="${y}" width="${w*0.42}" height="${h}" fill="${shut}" stroke="${INK}" stroke-width="1.8"/>`
   +`<path d="M${x-w*0.42+1} ${y+h*.3}h${w*0.42-5}M${x-w*0.42+1} ${y+h*.6}h${w*0.42-5}M${x+w+4} ${y+h*.3}h${w*0.42-5}M${x+w+4} ${y+h*.6}h${w*0.42-5}" stroke="${INK}" stroke-width="1" opacity=".6"/>`;
  return s;},
 door(x,y,w,h,{col='#6b3f22',arch=false,lit=false,frame='#2a1a10'}={}){
  const d=arch?`M${x} ${y+h}V${y+w/2}A${w/2} ${w/2} 0 0 1 ${x+w} ${y+w/2}V${y+h}Z`:`M${x} ${y}h${w}v${h}h${-w}z`;
  let s=`<path d="${d}" fill="${lit?'url(#winLit)':col}" stroke="${INK}" stroke-width="3"/>`;
  if(!lit)s+=`<path d="M${x+w/2} ${y+(arch?w/4:2)}V${y+h}M${x+4} ${y+h*0.35}h${w-8}" stroke="${INK}" stroke-width="1.2" opacity=".5"/><rect x="${x+3}" y="${y+h*0.4}" width="${w-6}" height="${h*0.55}" fill="none" stroke="#000" stroke-width=".8" opacity=".3"/><circle cx="${x+w*0.72}" cy="${y+h*0.6}" r="1.6" fill="#f1c85a" stroke="${INK}" stroke-width=".8"/>`;
  else s+=`<path d="M${x+w/2} ${y}V${y+h}" stroke="${frame}" stroke-width="2"/>`;
  s+=`<path d="M${x+2} ${y+(arch?w/2:2)}V${y+h-1}" stroke="#fff" stroke-width="1.2" opacity=".2"/>`;
  return s;},
 // striped awning hanging from y, depth dd (drawn flat on wall as a valance)
 valance(x,y,w,h,c1,c2='#f4ead2'){let s=`<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="${c1}"/>`;const n=Math.round(w/12);for(let i=0;i<n;i+=2)s+=`<rect x="${f(x+i*w/n)}" y="${y}" width="${f(w/n)}" height="${h}" fill="${c2}"/>`;
  let sc='';for(let i=0;i<n;i++)sc+=`a${f(w/n/2)} ${f(w/n/2.4)} 0 0 0 ${f(w/n)} 0`;
  return s+`<path d="M${x} ${y+h}${sc}" fill="${c1}" opacity="0"/><path d="M${x} ${y}h${w}v${h}H${x}z" fill="none" stroke="${INK}" stroke-width="2"/><rect x="${x}" y="${y+h-3}" width="${w}" height="3" fill="#000" opacity=".2"/>`;},
 sign(x,y,w,h,{bg='#3b2a1a',border='#d8a640',icon=''}={}){return `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="2" fill="${bg}" stroke="${INK}" stroke-width="2.4"/><rect x="${x+2.5}" y="${y+2.5}" width="${w-5}" height="${h-5}" rx="1.5" fill="none" stroke="${border}" stroke-width="1.4"/>${icon}`;},
 // horizontal band / cornice line
 band(x,y,w,h,c){return `<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="${c}" stroke="${INK}" stroke-width="1.8"/><rect x="${x}" y="${y}" width="${w}" height="${Math.max(1,h*0.3)}" fill="#fff" opacity=".3"/>`;},
 pilaster(x,y,w,h,c){return `<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="${c}" stroke="${INK}" stroke-width="1.8"/><rect x="${x+1}" y="${y}" width="${w*0.35}" height="${h}" fill="#fff" opacity=".25"/><rect x="${x+w*0.7}" y="${y}" width="${w*0.3-1}" height="${h}" fill="#000" opacity=".15"/>`;},
};

// ---------- rendering ----------
async function renderAll(items){ // items: [{name,w,h,svg,opaque,grain}]
 fs.mkdirSync(RAW,{recursive:true});const b=await chromium.launch({executablePath:undefined});const p=await b.newPage({deviceScaleFactor:1});
 for(const it of items){const html=`<html><body style="margin:0;background:transparent;overflow:hidden"><svg id="x" xmlns="http://www.w3.org/2000/svg" width="${it.w}" height="${it.h}" viewBox="0 0 ${it.w} ${it.h}">${DEFS()}${it.svg}</svg></body></html>`;
  await p.setViewportSize({width:it.w,height:it.h});await p.setContent(html);await p.waitForTimeout(30);
  const raw=path.join(RAW,it.name+'.png');await p.locator('#x').screenshot({path:raw,omitBackground:!it.opaque});
  const out=path.join(OUT,it.name+'.png');
  const r=execFileSync('python3',[path.join(__dirname,'post.py'),raw,out,String(it.grain??5),it.opaque?'1':'0',String(it.limit||295000)]).toString().trim();
  console.log(it.name,r);}
 await b.close();}

module.exports={INK,uid,f,rng,mix,shade,light,ink,poly,Iso,W,renderAll,hull,DEFS};
