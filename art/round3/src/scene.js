// 2D side-view scene kit (oblique buildings: front + right side + top), used by country panoramas and backgrounds.
const L=require('./lib');const {INK,f,mix,shade,light,rng,uid}=L;

function linGrad(id,stops,x2=0,y2=1){return `<linearGradient id="${id}" x1="0" y1="0" x2="${x2}" y2="${y2}">${stops.map(([o,c,a=1])=>`<stop offset="${o}" stop-color="${c}" stop-opacity="${a}"/>`).join('')}</linearGradient>`;}
function sky(W,H,stops){const id=uid('sky');return linGrad(id,stops)+`<rect width="${W}" height="${H}" fill="url(#${id})"/>`;}
function glow(x,y,r,col,op=.8){const id=uid('gl');return `<radialGradient id="${id}"><stop offset="0" stop-color="${col}" stop-opacity="${op}"/><stop offset=".35" stop-color="${col}" stop-opacity="${op*0.45}"/><stop offset="1" stop-color="${col}" stop-opacity="0"/></radialGradient><ellipse cx="${x}" cy="${y}" rx="${r}" ry="${r}" fill="url(#${id})"/>`;}
function sunDisc(x,y,r,col,halo){return glow(x,y,r*7,halo||col,.55)+glow(x,y,r*2.5,col,.8)+`<circle cx="${x}" cy="${y}" r="${r}" fill="${light(col,.5)}"/>`;}
function stars(W,H,n,seed,maxY){const r=rng(seed);let o='';for(let i=0;i<n;i++){const x=r()*W,y=r()*maxY,s=r();o+=`<circle cx="${f(x)}" cy="${f(y)}" r="${f(.5+s*1.3)}" fill="#fff" opacity="${f(.3+s*.6)}"/>`;if(s>.93)o+=`<path d="M${f(x-4)} ${f(y)}h8M${f(x)} ${f(y-4)}v8" stroke="#fff" stroke-width=".8" opacity=".7"/>`;}return o;}
// fluffy cloud: lit top, shaded bottom, optional ink
function cloud(x,y,w,{col='#f4e6d0',sh='#b89aa0',lit='#fff6e0',op=1,inkW=0}={}){const r=rng(Math.round(x*3+y*7));const n=5+Math.floor(w/60);let blobs=[];
 for(let i=0;i<n;i++){const t=i/(n-1);const bx=x+t*w,rr=(w/n)*(0.8+r()*0.7)*(1-Math.abs(t-.5)*0.9);blobs.push([bx,y-rr*0.4-r()*rr*0.3,rr]);}
 const id=uid('cl');let base='';for(const [bx,by,rr] of blobs)base+=`<circle cx="${f(bx)}" cy="${f(by)}" r="${f(rr)}"/>`;base+=`<rect x="${f(x)}" y="${f(y-w*0.05)}" width="${f(w)}" height="${f(w*0.06)}" rx="${f(w*0.03)}"/>`;
 let o=`<g opacity="${op}"><clipPath id="${id}">${base}</clipPath>`;
 if(inkW)o+=`<g fill="none" stroke="${INK}" stroke-width="${inkW*2}">${base}</g>`;
 o+=`<g fill="${col}">${base}</g><g clip-path="url(#${id})"><rect x="${f(x-w)}" y="${f(y-w*0.02)}" width="${f(w*3)}" height="${f(w)}" fill="${sh}" opacity=".85"/>`;
 for(const [bx,by,rr] of blobs)o+=`<circle cx="${f(bx-rr*0.25)}" cy="${f(by-rr*0.3)}" r="${f(rr*0.7)}" fill="${lit}" opacity=".7"/>`;
 o+=`</g></g>`;return o;}
// silhouette ridge (hills / mountains) from baseline
function ridge(W,base,amp,seed,col,{rough=6,step=40,peaks=false,op=1,H=400}={}){const r=rng(seed);let d=`M0 ${H}L0 ${base}`;let y=base;for(let x=0;x<=W+step;x+=step){const t=peaks?(r()<.5?-1:1)*amp*r():(Math.sin(x/170+seed)*amp*0.6+Math.sin(x/61+seed*2)*amp*0.3+ (r()-.5)*rough);d+=`L${x} ${f(base-Math.abs(t))}`;}d+=`L${W} ${H}Z`;return `<path d="${d}" fill="${col}" opacity="${op}"/>`;}
function haze(W,y0,y1,col,op){const id=uid('hz');return linGrad(id,[[0,col,0],[1,col,op]])+`<rect x="0" y="${y0}" width="${W}" height="${y1-y0}" fill="url(#${id})"/>`;}

// ---- oblique building ----
// x: left of front face, base: ground y, w,h front size, d: depth (side face width)
function bld(x,base,w,h,o={}){const d=o.d??Math.round(w*0.2),dy=d*0.5,sw=o.sw??2.6,stroke=o.ink??INK;const fill=o.fill||'#b8a888';
 const top=base-h;let s='';const fid=uid('bf');
 // shadow on ground to the right
 if(o.shadow!==false)s+=`<path d="M${x+w} ${base}L${x+w+d+h*0.35} ${base}L${x+w+d} ${base-dy}Z" fill="#000" opacity=".25" filter="url(#blur4)"/>`;
 // side face
 const side=`M${x+w} ${base}L${x+w+d} ${base-dy}L${x+w+d} ${top-dy}L${x+w} ${top}Z`;const sf=o.sideFill||shade(fill,.38);
 if(d>0){s+=`<path d="${side}" fill="${sf}"/>`;if(o.tex)s+=`<path d="${side}" fill="url(#${o.tex})" opacity="${o.texOp??.8}"/>`;
  if(o.sideWins)s+=o.sideWins(x+w,base,d,h);
  s+=`<path d="${side}" fill="#0a0818" opacity="${o.sideDark??.12}"/><path d="${side}" fill="none" stroke="${stroke}" stroke-width="${sw}" stroke-linejoin="round"/>`;}
 // top face (flat roofs)
 if(o.roof==null||o.roof==='flat'){const tp=`M${x} ${top}L${x+w} ${top}L${x+w+d} ${top-dy}L${x+d} ${top-dy}Z`;s+=`<path d="${tp}" fill="${o.topFill||light(fill,.12)}" stroke="${stroke}" stroke-width="${sw}" stroke-linejoin="round"/>`;}
 // front face
 const fr=`M${x} ${base}V${top}H${x+w}V${base}Z`;
 s+=`<clipPath id="${fid}"><path d="${fr}"/></clipPath><g clip-path="url(#${fid})"><rect x="${x}" y="${top}" width="${w}" height="${h}" fill="${fill}"/>`;
 if(o.tex)s+=`<rect x="${x}" y="${top}" width="${w}" height="${h}" fill="url(#${o.tex})" opacity="${o.texOp??.8}"/>`;
 if(o.wins)s+=wins(x,top,w,h,o.wins);
 if(o.content)s+=o.content(x,top,w,h);
 s+=`<rect x="${x}" y="${top}" width="${w}" height="${h}" fill="url(#aoV)" opacity="${o.ao??.7}"/><rect x="${x}" y="${top}" width="${w}" height="${h}" fill="url(#topLit)"/>`;
 if(o.haze)s+=`<rect x="${x}" y="${top}" width="${w}" height="${h}" fill="${o.hazeCol||'#fff'}" opacity="${o.haze}"/>`;
 s+=`</g><path d="${fr}" fill="none" stroke="${stroke}" stroke-width="${sw}" stroke-linejoin="round"/>`;
 // rim light on left edge
 if(o.rim!==false)s+=`<path d="M${x+1.8} ${base-3}V${top+2}H${x+w-2}" stroke="${o.rimCol||'#ffe2a8'}" stroke-width="1.6" fill="none" opacity="${o.rimOp??.6}"/>`;
 // roofs
 const R=o.roof;if(R&&R!=='flat'&&R!=='none'){const rf=o.roofFill||'#8a4a36',rt=o.roofTex,rh=o.rh??w*0.4,ov=o.ov??4;
  if(R==='gable'){ // ridge goes into depth: front triangle + right slope
   const tri=`M${x-ov} ${top}L${x+w/2} ${top-rh}L${x+w+ov} ${top}Z`;const slope=`M${x+w/2} ${top-rh}L${x+w/2+d} ${top-rh-dy}L${x+w+ov+d} ${top-dy}L${x+w+ov} ${top}Z`;
   s+=`<path d="${slope}" fill="${shade(rf,.15)}"/>`+(rt?`<path d="${slope}" fill="url(#${rt})" opacity=".8"/>`:'')+`<path d="${slope}" fill="none" stroke="${stroke}" stroke-width="${sw}" stroke-linejoin="round"/>`;
   s+=`<path d="${tri}" fill="${o.gableFill||fill}"/>`+(o.tex?`<path d="${tri}" fill="url(#${o.tex})" opacity=".7"/>`:'')+`<path d="${tri}" fill="url(#topLit)"/>`+(o.gableContent?o.gableContent(x,top,w,rh):'')+`<path d="${tri}" fill="none" stroke="${stroke}" stroke-width="${sw}" stroke-linejoin="round"/>`;
   s+=`<path d="M${x-ov} ${top}L${x+w/2} ${top-rh}L${x+w+ov} ${top}" fill="none" stroke="${rf}" stroke-width="${Math.max(3,sw*1.6)}" stroke-linejoin="round"/><path d="M${x-ov} ${top}L${x+w/2} ${top-rh}L${x+w+ov} ${top}" fill="none" stroke="${stroke}" stroke-width="1.2" stroke-linejoin="round" transform="translate(0 -2)"/>`;}
  if(R==='gableFront'){ // ridge parallel to front: front slope visible + right gable triangle
   const ry=top-rh,rx0=x+d*0.5,rx1=x+w+d*0.5;
   const fs=`M${x-ov} ${top+2}L${x+w+ov} ${top+2}L${rx1+ov*0.5} ${ry-dy*0.5}L${rx0-ov*0.5} ${ry-dy*0.5}Z`;
   const gt=`M${x+w} ${top}L${x+w+d} ${top-dy}L${rx1} ${ry-dy*0.5}Z`;
   s+=`<path d="${gt}" fill="${o.sideFill||shade(fill,.38)}" stroke="${stroke}" stroke-width="${sw}" stroke-linejoin="round"/>`;
   s+=`<path d="${fs}" fill="${rf}"/>`+(rt?`<path d="${fs}" fill="url(#${rt})" opacity=".85"/>`:'')+`<path d="${fs}" fill="url(#topLit)"/><path d="${fs}" fill="none" stroke="${stroke}" stroke-width="${sw}" stroke-linejoin="round"/>`;
   s+=`<path d="M${rx0-ov*0.5} ${ry-dy*0.5}L${rx1+ov*0.5} ${ry-dy*0.5}" stroke="${light(rf,.3)}" stroke-width="2"/>`;}
  if(R==='hip'||R==='pyramid'){const cx=x+w/2+d/2,ry=top-rh-dy/2;const ins=R==='pyramid'?0:w*0.25;
   const fs=`M${x-ov} ${top+2}L${x+w+ov} ${top+2}L${cx+ins} ${ry}L${cx-ins} ${ry}Z`;const ss=`M${x+w+ov} ${top+2}L${x+w+d+ov} ${top-dy}L${cx+ins} ${ry}Z`;
   s+=`<path d="${ss}" fill="${shade(rf,.3)}"/>`+(rt?`<path d="${ss}" fill="url(#${rt})" opacity=".8"/>`:'')+`<path d="${ss}" fill="none" stroke="${stroke}" stroke-width="${sw}" stroke-linejoin="round"/>`;
   s+=`<path d="${fs}" fill="${rf}"/>`+(rt?`<path d="${fs}" fill="url(#${rt})" opacity=".85"/>`:'')+`<path d="${fs}" fill="url(#topLit)"/><path d="${fs}" fill="none" stroke="${stroke}" stroke-width="${sw}" stroke-linejoin="round"/>`;}
 }
 if(o.cren){const n=Math.max(3,Math.round(w/o.cren)),mw=w/n;for(let i=0;i<n;i+=2){s+=`<rect x="${f(x+i*mw)}" y="${f(top-mw*0.8)}" width="${f(mw)}" height="${f(mw*0.8+1)}" fill="${fill}" stroke="${stroke}" stroke-width="${sw*0.8}"/><rect x="${f(x+i*mw)}" y="${f(top-mw*0.8)}" width="${f(mw)}" height="${f(mw*0.25)}" fill="#fff" opacity=".25"/>`;}}
 return s;}
// window grid inside front face
function wins(x,top,w,h,o){const {cols=3,rows=2,ww=10,wh=14,padT=12,padB=14,padX=null,lit=0.7,seed=1,arch=false,frame=INK,litCol='url(#winLit)',dark='#2a3040',glowOn=true,sill=false}=o;const r=rng(seed);
 const px=padX??(w-cols*ww)/(cols+1);const gx=cols>1?(w-2*px-ww)/(cols-1):0;const gy=rows>1?(h-padT-padB-wh)/(rows-1):0;let s='';
 for(let j=0;j<rows;j++)for(let i=0;i<cols;i++){const X=x+px+i*gx,Y=top+padT+j*gy;const on=r()<lit;
  const d=arch?`M${f(X)} ${f(Y+wh)}V${f(Y+ww/2)}A${ww/2} ${ww/2} 0 0 1 ${f(X+ww)} ${f(Y+ww/2)}V${f(Y+wh)}Z`:`M${f(X)} ${f(Y)}h${ww}v${wh}h${-ww}z`;
  if(on&&glowOn)s+=`<rect x="${f(X-ww*0.6)}" y="${f(Y-wh*0.3)}" width="${f(ww*2.2)}" height="${f(wh*1.6)}" fill="#ffc860" opacity=".22" filter="url(#blur4)"/>`;
  s+=`<path d="${d}" fill="${on?litCol:dark}" stroke="${frame}" stroke-width="${o.fw??1.6}"/>`;
  if(o.mull&&ww>7)s+=`<path d="M${f(X+ww/2)} ${f(Y+(arch?ww/2:0))}V${f(Y+wh)}M${f(X)} ${f(Y+wh*0.5)}h${ww}" stroke="${frame}" stroke-width="1" opacity=".8"/>`;
  if(sill)s+=`<rect x="${f(X-1.5)}" y="${f(Y+wh)}" width="${ww+3}" height="2.2" fill="#e8dcc0" opacity=".8"/>`;}
 return s;}
// dome on top of a building (centre cx, base y, radius r)
function dome(cx,y,r,col,{h=r*1.05,ribs=0,sw=2.6,lantern=true,ink=INK}={}){const id=uid('dm');
 let s=`<radialGradient id="${id}" cx=".3" cy=".25" r=".9"><stop offset="0" stop-color="${light(col,.55)}"/><stop offset=".4" stop-color="${col}"/><stop offset=".85" stop-color="${shade(col,.35)}"/><stop offset="1" stop-color="${shade(col,.5)}"/></radialGradient>`;
 const d=`M${cx-r} ${y}C${cx-r} ${y-h*1.3} ${cx+r} ${y-h*1.3} ${cx+r} ${y}Z`;s+=`<path d="${d}" fill="url(#${id})"/>`;
 for(let i=1;i<=ribs;i++){const t=i/(ribs+1);const xx=cx-r+2*r*t;s+=`<path d="M${f(xx)} ${y}Q${f(cx+(xx-cx)*0.92)} ${f(y-h*0.92)} ${cx} ${f(y-h*0.97)}" fill="none" stroke="${ink}" stroke-width="1" opacity=".45"/>`;}
 s+=`<path d="${d}" fill="none" stroke="${ink}" stroke-width="${sw}"/>`;
 if(lantern)s+=`<rect x="${cx-r*0.12}" y="${f(y-h*0.98-r*0.3)}" width="${f(r*0.24)}" height="${f(r*0.32)}" fill="${light(col,.2)}" stroke="${ink}" stroke-width="${sw*0.7}"/><path d="M${cx} ${f(y-h*0.98-r*0.3)}v${f(-r*0.3)}" stroke="${ink}" stroke-width="${sw*0.8}"/><circle cx="${cx}" cy="${f(y-h*0.98-r*0.62)}" r="${f(Math.max(2,r*0.07))}" fill="#ffe08a" stroke="${ink}" stroke-width="1"/>`;
 return s;}
function spire(cx,y,w,h,col,{sw=2.6,ink=INK}={}){return `<path d="M${cx-w/2} ${y}L${cx} ${y-h}L${cx+w/2} ${y}Z" fill="${col}" stroke="${ink}" stroke-width="${sw}" stroke-linejoin="round"/><path d="M${cx} ${y-h}L${cx+w/2} ${y}L${cx+w*0.12} ${y}Z" fill="#000" opacity=".28"/><path d="M${cx-1} ${y-h+6}L${cx-w*0.3} ${y-2}" stroke="#fff" stroke-width="1.4" opacity=".4"/>`;}
// trees
function treeRound(x,base,s,col='#3f6a3a',{trunk='#5a3a22',ink=INK,sw=2.2,lit}={}){const r=rng(Math.round(x*5+base));const blobs=[[0,-s*1.5,s],[-s*0.7,-s*1.1,s*0.75],[s*0.7,-s*1.05,s*0.75],[-s*0.3,-s*2.1,s*0.7],[s*0.35,-s*1.95,s*0.65]];
 let o=`<path d="M${x-s*0.12} ${base}L${x-s*0.08} ${base-s*0.9}h${s*0.16}L${x+s*0.12} ${base}Z" fill="${trunk}" stroke="${ink}" stroke-width="${sw*0.8}"/>`;
 o+=blobs.map(([dx,dy,rr])=>`<circle cx="${f(x+dx)}" cy="${f(base+dy)}" r="${f(rr)}" fill="${ink}" stroke="${ink}" stroke-width="${sw*2}"/>`).join('');
 o+=blobs.map(([dx,dy,rr])=>`<circle cx="${f(x+dx)}" cy="${f(base+dy)}" r="${f(rr)}" fill="${col}"/>`).join('');
 o+=blobs.map(([dx,dy,rr])=>`<circle cx="${f(x+dx+rr*0.3)}" cy="${f(base+dy+rr*0.3)}" r="${f(rr*0.7)}" fill="${shade(col,.35)}" opacity=".6"/>`).join('');
 o+=blobs.map(([dx,dy,rr])=>`<circle cx="${f(x+dx-rr*0.32)}" cy="${f(base+dy-rr*0.35)}" r="${f(rr*0.42)}" fill="${lit||light(col,.3)}" opacity=".85"/>`).join('');
 return o;}
function cypress(x,base,h,col='#2f4f2f',{ink=INK,sw=2.2}={}){return `<path d="M${x} ${base-h}C${x+h*0.17} ${base-h*0.6} ${x+h*0.16} ${base-h*0.15} ${x+3} ${base}L${x-3} ${base}C${x-h*0.16} ${base-h*0.15} ${x-h*0.17} ${base-h*0.6} ${x} ${base-h}Z" fill="${col}" stroke="${ink}" stroke-width="${sw}"/><path d="M${x+1} ${base-h+6}C${x+h*0.14} ${base-h*0.55} ${x+h*0.13} ${base-h*0.15} ${x+3} ${base-2}Z" fill="#000" opacity=".3"/><path d="M${x-3} ${base-h*0.8}q${-h*0.08} ${h*0.3} ${-h*0.04} ${h*0.6}" stroke="${light(col,.4)}" stroke-width="1.6" fill="none" opacity=".8"/>`;}
function pine(x,base,h,col='#2a4a3a',{ink=INK,sw=2}={}){let o=`<rect x="${x-2}" y="${base-h*0.15}" width="4" height="${h*0.15}" fill="#4a3020" stroke="${ink}" stroke-width="1.4"/>`;for(let i=0;i<3;i++){const y0=base-h*0.12-i*h*0.26,w=h*(0.38-i*0.09);o+=`<path d="M${f(x-w)} ${f(y0)}L${x} ${f(y0-h*0.42)}L${f(x+w)} ${f(y0)}Z" fill="${col}" stroke="${ink}" stroke-width="${sw}" stroke-linejoin="round"/><path d="M${x} ${f(y0-h*0.42)}L${f(x+w)} ${f(y0)}L${x+2} ${f(y0)}Z" fill="#000" opacity=".25"/>`;}return o;}
function palm(x,base,h,{lean=8,ink=INK,col='#5d8a3a'}={}){const t=[x+lean,base-h];let o=`<path d="M${x-3} ${base}Q${x-1+lean*0.2} ${base-h*0.6} ${t[0]-2} ${t[1]}L${t[0]+2} ${t[1]}Q${x+3+lean*0.2} ${base-h*0.6} ${x+3} ${base}Z" fill="#7a5a3a" stroke="${ink}" stroke-width="2"/>`;
 const s=h/70;for(const [dx,dy] of [[-30,6],[-22,-9],[-6,-15],[12,-14],[26,-5],[32,9],[-16,13],[18,14]]){const ex=t[0]+dx*s,ey=t[1]+(dy+8)*s,mx=t[0]+dx*s*0.5,my=t[1]+(dy*0.5-9)*s;o+=`<path d="M${t[0]} ${t[1]}Q${f(mx)} ${f(my-3*s)} ${f(ex)} ${f(ey)}Q${f(mx+2*s)} ${f(my+5*s)} ${t[0]} ${t[1]+3*s}Z" fill="${col}" stroke="${ink}" stroke-width="1.8"/>`;}return o;}
// generic ink shape
const ink=(d,fill,sw=2.6,extra='')=>`<path d="${d}" fill="${fill}" stroke="${INK}" stroke-width="${sw}" stroke-linejoin="round" stroke-linecap="round" ${extra}/>`;
function smokePlume(x,y,s,{col='#8a8580',lit='#e8c8a0',n=6,drift=1.4,op=.85,seed=1}={}){const r=rng(seed);let o='';for(let i=0;i<n;i++){const t=i/(n-1);const cx=x+t*60*s*drift+(r()-.5)*8*s,cy=y-t*110*s,rr=(10+t*26)*s;
 o+=`<circle cx="${f(cx)}" cy="${f(cy)}" r="${f(rr)}" fill="${col}" opacity="${f(op*(1-t*0.6))}"/><circle cx="${f(cx-rr*0.3)}" cy="${f(cy-rr*0.35)}" r="${f(rr*0.55)}" fill="${lit}" opacity="${f(op*0.55*(1-t*0.6))}"/>`;}return `<g filter="url(#blur2)">${o}</g>`;}
function vignette(W,H,op=.45){const id=uid('vg');return `<radialGradient id="${id}" cx=".5" cy=".5" r=".75"><stop offset=".55" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="${op}"/></radialGradient><rect width="${W}" height="${H}" fill="url(#${id})"/>`;}
function reflect(content,axisY,op=.35){return `<g transform="translate(0 ${2*axisY}) scale(1 -1)" opacity="${op}">${content}</g>`;}
module.exports={linGrad,sky,glow,sunDisc,stars,cloud,ridge,haze,bld,wins,dome,spire,treeRound,cypress,pine,palm,ink,smokePlume,vignette,reflect};
