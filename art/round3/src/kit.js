// Isometric building kit on top of lib.Iso: plots, roofs, small props.
const L=require('./lib');const {INK,f,mix,shade,light,poly,Iso,W,uid,rng}=L;
// evenly spaced windows along a face of width w: n windows of ww x wh at top y
const rowWins=(w,y,ww,wh,n,o={})=>{let s='';const gap=(w-n*ww)/(n+1);for(let i=0;i<n;i++)s+=W.win(gap+i*(ww+gap),y,ww,wh,o);return s;};

const PL=204; // plot side in world units
function mkIso(){return new Iso(256,236,1,1.1);} // top corner of plot at (256,236); plot centre ~ y 338

const GROUND={
 stone:{fill:'#8d8478',tex:'flag',side:'#7a6e60',sideTex:'block',rim:'#a39886'},
 cobble:{fill:'#7f7466',tex:'cobble',side:'#6f6252',sideTex:'block',rim:'#968a78'},
 dirt:{fill:'#8a7458',tex:'gravel',side:'#6f5a40',sideTex:'block',rim:'#9a8466',inner:'cobble'},
 brick:{fill:'#8a5a44',tex:'brick',side:'#6a5446',sideTex:'block',rim:'#9a8a78'},
 concrete:{fill:'#7d8088',tex:'concrete',side:'#5f636b',sideTex:'concrete',rim:'#9a9ea6'},
 metal:{fill:'#5e6680',tex:'scifi',side:'#454c62',sideTex:'plate',rim:'#8a94b0'},
 marble:{fill:'#b8ad98',tex:'flag',side:'#8f8470',sideTex:'block',rim:'#d6ccb6'},
};
function plot(iso,g='stone'){const G=GROUND[g];const T=16,b=9;let s='';
 // soft drop shadow under slab
 s+=`<path d="${poly([iso.P([0,0,-T]),iso.P([PL,0,-T]),iso.P([PL,PL,-T]),iso.P([0,PL,-T])].map(p=>[p[0]+6,p[1]+8]))}" fill="#000" opacity=".35" filter="url(#blur8)"/>`;
 s+=iso.face([[0,PL,0],[PL,PL,0],[PL,PL,-T],[0,PL,-T]],{fill:G.side,tex:G.sideTex,texOp:.9,ao:.5});
 s+=iso.face([[PL,PL,0],[PL,0,0],[PL,0,-T],[PL,PL,-T]],{fill:G.side,tex:G.sideTex,texOp:.9,ao:.5});
 // curb ring
 s+=iso.face([[0,0,0],[PL,0,0],[PL,PL,0],[0,PL,0]],{fill:G.rim,tex:'stone',texOp:.6,ao:false,sheen:false,tone:.8,rim:[3,2]});
 // inner paving
 s+=iso.face([[b,b,0],[PL-b,b,0],[PL-b,PL-b,0],[b,PL-b,0]],{fill:G.fill,tex:G.tex,ao:false,tone:.78,w:2,content:({x,y,w,h})=>
   `<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="url(#gravel)" opacity=".7"/><radialGradient id="pv" cx=".3" cy=".25" r=".9"><stop offset="0" stop-color="#fff3d0" stop-opacity=".18"/><stop offset="1" stop-color="#000" stop-opacity=".25"/></radialGradient><rect x="${x}" y="${y}" width="${w}" height="${h}" fill="url(#pv)"/>`});
 return s;}
// clip everything on the plot top (for shadows)
function onPlot(iso,content){const id=uid('pc');const d=poly([[0,0,0],[PL,0,0],[PL,PL,0],[0,PL,0]].map(p=>iso.P(p)));return `<clipPath id="${id}"><path d="${d}"/></clipPath><g clip-path="url(#${id})">${content}</g>`;}

// ---------- roofs ----------
// gable roof, ridge along X (axis 'x') or along Y (axis 'y'); z = eave height, rh = ridge rise
function gable(iso,x0,y0,x1,y1,z,rh,o={}){const ov=o.ov??6,fill=o.fill||'#6a6f7d',tex=o.tex||'slate',gf=o.gable||null;let s='';
 if((o.axis||'x')==='x'){const ym=(y0+y1)/2;
  s+=iso.face([[x1+ov,ym,z+rh],[x0-ov,ym,z+rh],[x0-ov,y0-ov,z-ov*0.6],[x1+ov,y0-ov,z-ov*0.6]],{fill,tex,ao:false});
  if(gf)s+=iso.face([[x1,y1,z],[x1,y0,z],[x1,ym,z+rh]],{fill:gf.fill,tex:gf.tex,ao:false,content:gf.content});
  // eave fascia
  s+=iso.face([[x0-ov,y1+ov,z-ov*0.6],[x1+ov,y1+ov,z-ov*0.6],[x1+ov,y1+ov,z-ov*0.6-4],[x0-ov,y1+ov,z-ov*0.6-4]],{fill:o.fascia||'#4a3020',ao:false,w:2});
  s+=iso.face([[x0-ov,ym,z+rh],[x1+ov,ym,z+rh],[x1+ov,y1+ov,z-ov*0.6],[x0-ov,y1+ov,z-ov*0.6]],{fill,tex,ao:.5,rim:[0]});
  // barge board on right end
  s+=iso.face([[x1+ov,y1+ov,z-ov*0.6],[x1+ov,ym,z+rh],[x1+ov,ym,z+rh-4],[x1+ov,y1+ov,z-ov*0.6-4]],{fill:o.fascia||'#4a3020',ao:false,w:2});
  s+=iso.face([[x1+ov,ym,z+rh],[x1+ov,y0-ov,z-ov*0.6],[x1+ov,y0-ov,z-ov*0.6-4],[x1+ov,ym,z+rh-4]],{fill:o.fascia||'#4a3020',ao:false,w:2});
  // ridge cap
  const a=iso.P([x0-ov,ym,z+rh]),b=iso.P([x1+ov,ym,z+rh]);s+=`<path d="M${f(a[0])} ${f(a[1])}L${f(b[0])} ${f(b[1])}" stroke="${INK}" stroke-width="6" stroke-linecap="round"/><path d="M${f(a[0])} ${f(a[1]-1)}L${f(b[0])} ${f(b[1]-1)}" stroke="${o.ridge||light(fill,.2)}" stroke-width="2.5" stroke-linecap="round"/>`;
 }else{const xm=(x0+x1)/2;
  s+=iso.face([[xm,y1+ov,z+rh],[xm,y0-ov,z+rh],[x0-ov,y0-ov,z-ov*0.6],[x0-ov,y1+ov,z-ov*0.6]],{fill,tex,ao:false});
  if(gf)s+=iso.face([[x0,y1,z],[x1,y1,z],[xm,y1,z+rh]],{fill:gf.fill,tex:gf.tex,ao:false,content:gf.content});
  s+=iso.face([[x1+ov,y1+ov,z-ov*0.6],[x1+ov,y0-ov,z-ov*0.6],[x1+ov,y0-ov,z-ov*0.6-4],[x1+ov,y1+ov,z-ov*0.6-4]],{fill:o.fascia||'#4a3020',ao:false,w:2});
  s+=iso.face([[xm,y1+ov,z+rh],[x1+ov,y1+ov,z-ov*0.6],[x1+ov,y0-ov,z-ov*0.6],[xm,y0-ov,z+rh]],{fill,tex,ao:.5});
  s+=iso.face([[x0-ov,y1+ov,z-ov*0.6],[xm,y1+ov,z+rh],[xm,y1+ov,z+rh-4],[x0-ov,y1+ov,z-ov*0.6-4]],{fill:o.fascia||'#4a3020',ao:false,w:2,tone:.9});
  s+=iso.face([[xm,y1+ov,z+rh],[x1+ov,y1+ov,z-ov*0.6],[x1+ov,y1+ov,z-ov*0.6-4],[xm,y1+ov,z+rh-4]],{fill:o.fascia||'#4a3020',ao:false,w:2,tone:.9});
  const a=iso.P([xm,y0-ov,z+rh]),b=iso.P([xm,y1+ov,z+rh]);s+=`<path d="M${f(a[0])} ${f(a[1])}L${f(b[0])} ${f(b[1])}" stroke="${INK}" stroke-width="6" stroke-linecap="round"/><path d="M${f(a[0])} ${f(a[1]-1)}L${f(b[0])} ${f(b[1]-1)}" stroke="${o.ridge||light(fill,.2)}" stroke-width="2.5" stroke-linecap="round"/>`;
 }
 return s;}
// hip / pyramid roof
function hip(iso,x0,y0,x1,y1,z,rh,o={}){const ov=o.ov??6,fill=o.fill||'#6a6f7d',tex=o.tex||'slate';const X0=x0-ov,Y0=y0-ov,X1=x1+ov,Y1=y1+ov,zz=z-ov*0.6;
 const inset=o.inset??Math.min(x1-x0,y1-y0)/2;const r0=[X0+inset,Y0+inset],r1=[X1-inset,Y1-inset];
 const A=[X0,Y0,zz],B=[X1,Y0,zz],C=[X1,Y1,zz],D=[X0,Y1,zz],ra=[r0[0],r0[1],z+rh],rb=[r1[0],r0[1],z+rh],rc=[r1[0],r1[1],z+rh],rd=[r0[0],r1[1],z+rh];
 let s='';const fc=(pts,extra={})=>{const u=[];pts.forEach(p=>{if(!u.some(q=>q.every((v,i)=>Math.abs(v-p[i])<1e-6)))u.push(p);});return u.length>=3?iso.face(u,{fill,tex,...extra}):'';};
 s+=fc([A,B,rb,ra],{ao:false});s+=fc([D,A,ra,rd],{ao:false});
 s+=iso.face([[X0,Y1,zz],[X1,Y1,zz],[X1,Y1,zz-4],[X0,Y1,zz-4]],{fill:o.fascia||'#4a3020',ao:false,w:2});
 s+=iso.face([[X1,Y1,zz],[X1,Y0,zz],[X1,Y0,zz-4],[X1,Y1,zz-4]],{fill:o.fascia||'#4a3020',ao:false,w:2});
 s+=fc([B,C,rc,rb],{ao:.4});s+=fc([C,D,rd,rc],{ao:.4,rim:[3]});
 return s;}
// flat roof with parapet
function flatRoof(iso,x0,y0,x1,y1,z,o={}){const ph=o.ph??6,t=o.t??4,fill=o.fill||'#8a8c90',pf=o.pfill||fill;let s='';
 s+=iso.face([[x0,y0,z],[x1,y0,z],[x1,y1,z],[x0,y1,z]],{fill:o.top||shade(fill,.15),tex:o.tex||'concrete',ao:false,tone:.6});
 // parapet inner walls (back ones visible)
 s+=iso.face([[x0+t,y0+t,z],[x1-t,y0+t,z],[x1-t,y0+t,z+ph],[x0+t,y0+t,z+ph]],{fill:pf,ao:false,tone:.6,w:2});
 s+=iso.face([[x0+t,y0+t,z],[x0+t,y1-t,z],[x0+t,y1-t,z+ph],[x0+t,y0+t,z+ph]],{fill:pf,ao:false,tone:.5,w:2});
 // parapet top ring + outer faces
 s+=iso.face([[x0,y0,z+ph],[x1,y0,z+ph],[x1,y0+t,z+ph],[x0,y0+t,z+ph]],{fill:pf,ao:false,tone:.85,w:2});
 s+=iso.face([[x0,y0,z+ph],[x0+t,y0,z+ph],[x0+t,y1,z+ph],[x0,y1,z+ph]],{fill:pf,ao:false,tone:.85,w:2});
 s+=iso.face([[x1-t,y0,z+ph],[x1,y0,z+ph],[x1,y1,z+ph],[x1-t,y1,z+ph]],{fill:pf,ao:false,tone:.85,w:2});
 s+=iso.face([[x0,y1-t,z+ph],[x1,y1-t,z+ph],[x1,y1,z+ph],[x0,y1,z+ph]],{fill:pf,ao:false,tone:.85,w:2,rim:[2]});
 s+=iso.face([[x0,y1,z+ph],[x1,y1,z+ph],[x1,y1,z-2],[x0,y1,z-2]],{fill:pf,ao:false,w:2});
 s+=iso.face([[x1,y1,z+ph],[x1,y0,z+ph],[x1,y0,z-2],[x1,y1,z-2]],{fill:pf,ao:false,w:2});
 return s;}

// ---------- small props ----------
const P={
 crate(iso,x,y,s=12,col='#a87444',z=0){let o=iso.box(x,y,z,x+s,y+s,z+s*0.95,{fill:col,tex:'grain',topTex:'grain',left:{content:({w,h})=>`<path d="M1 1L${w-1} ${h-1}M${w-1} 1L1 ${h-1}" stroke="#4a2e16" stroke-width="2"/><rect x="0" y="0" width="${w}" height="${h}" fill="none" stroke="#4a2e16" stroke-width="3"/>`},right:{content:({w,h})=>`<rect x="0" y="0" width="${w}" height="${h}" fill="none" stroke="#4a2e16" stroke-width="3"/><path d="M1 ${h/2}H${w}" stroke="#4a2e16" stroke-width="2"/>`},top:{rim:[3,0]}});return o;},
 barrel(iso,x,y,r=6,h=14,col='#8a5a32',z=0){return iso.cyl(x,y,r,z,z+h,col,{tex:'plank',bands:[z+h*0.2,z+h*0.75],bandCol:'#3a3a40',topFill:light(col,.15)});},
 sack(iso,x,y,s=7,col='#c9b083'){const c=iso.P([x,y,0]);const w=s*1.5,h=s*1.6;return `<path d="M${f(c[0]-w)} ${f(c[1])} C${f(c[0]-w*1.15)} ${f(c[1]-h*0.9)} ${f(c[0]-w*0.4)} ${f(c[1]-h*1.15)} ${f(c[0])} ${f(c[1]-h*1.2)} C${f(c[0]+w*0.4)} ${f(c[1]-h*1.15)} ${f(c[0]+w*1.15)} ${f(c[1]-h*0.9)} ${f(c[0]+w)} ${f(c[1])} Q${f(c[0])} ${f(c[1]+h*0.35)} ${f(c[0]-w)} ${f(c[1])}Z" fill="${col}" stroke="${INK}" stroke-width="2.4"/><path d="M${f(c[0]+w*0.2)} ${f(c[1]-h*1.05)} C${f(c[0]+w*0.9)} ${f(c[1]-h*0.7)} ${f(c[0]+w*0.8)} ${f(c[1]-h*0.1)} ${f(c[0]+w*0.5)} ${f(c[1]+h*0.12)}" stroke="none" fill="#000" opacity=".18"/><path d="M${f(c[0]-w*0.6)} ${f(c[1]-h*0.7)} q${f(w*0.3)} ${f(-h*0.3)} ${f(w*0.6)} ${f(-h*0.35)}" stroke="#fff" stroke-width="1.5" fill="none" opacity=".45"/><path d="M${f(c[0]-w*0.3)} ${f(c[1]-h*1.05)} q${f(w*0.3)} ${f(h*0.15)} ${f(w*0.6)} 0" stroke="${INK}" stroke-width="1.6" fill="none"/>`;},
 lamp(iso,x,y,h=34,{col='#2b2b30',glow='#ffcf6a',z=0}={}){const b=iso.P([x,y,z]),t=iso.P([x,y,z+h]);return `<ellipse cx="${f(t[0])}" cy="${f(t[1]-4)}" rx="16" ry="14" fill="${glow}" opacity=".35" filter="url(#blur8)"/>`
  +`<rect x="${f(b[0]-2)}" y="${f(t[1])}" width="4" height="${f(b[1]-t[1])}" fill="${col}" stroke="${INK}" stroke-width="1.8"/><rect x="${f(b[0]-4)}" y="${f(b[1]-5)}" width="8" height="5" fill="${col}" stroke="${INK}" stroke-width="1.8"/>`
  +`<path d="M${f(t[0]-5)} ${f(t[1]-2)}h10l-2 -10h-6z" fill="${glow}" stroke="${INK}" stroke-width="2"/><path d="M${f(t[0]-6)} ${f(t[1]-12)}h12l-6 -5z" fill="${col}" stroke="${INK}" stroke-width="2"/><rect x="${f(t[0]-1.5)}" y="${f(t[1]-10)}" width="3" height="6" fill="#fff8d8"/>`;},
 bush(iso,x,y,s=10,col='#4f7a3a',z=0){const c=iso.P([x,y,z]);const r=rng(Math.round(x*7+y*13));let o='',hl='';const blobs=[[0,-s*0.9,s*0.95],[-s*0.8,-s*0.45,s*0.75],[s*0.8,-s*0.4,s*0.75],[-s*0.2,-s*1.5,s*0.7],[s*0.4,-s*1.3,s*0.6]];
  o+=`<ellipse cx="${f(c[0]+3)}" cy="${f(c[1]+1)}" rx="${f(s*1.6)}" ry="${f(s*0.6)}" fill="#000" opacity=".28" filter="url(#blur2)"/>`;
  for(const [dx,dy,rr] of blobs)o+=`<circle cx="${f(c[0]+dx)}" cy="${f(c[1]+dy)}" r="${f(rr)}" fill="${INK}" stroke="${INK}" stroke-width="5"/>`;
  for(const [dx,dy,rr] of blobs)o+=`<circle cx="${f(c[0]+dx)}" cy="${f(c[1]+dy)}" r="${f(rr)}" fill="${col}"/>`;
  for(const [dx,dy,rr] of blobs)o+=`<circle cx="${f(c[0]+dx+rr*0.3)}" cy="${f(c[1]+dy+rr*0.3)}" r="${f(rr*0.75)}" fill="${shade(col,.35)}" opacity=".7"/>`;
  for(const [dx,dy,rr] of blobs)hl+=`<circle cx="${f(c[0]+dx-rr*0.3)}" cy="${f(c[1]+dy-rr*0.35)}" r="${f(rr*0.45)}" fill="${light(col,.35)}" opacity=".9"/>`;
  for(let i=0;i<6;i++)hl+=`<path d="M${f(c[0]-s+r()*s*2)} ${f(c[1]-s*1.6+r()*s*1.2)}q2 -2 4 0" stroke="${light(col,.6)}" stroke-width="1.2" fill="none" opacity=".8"/>`;
  return o+hl;},
 tree(iso,x,y,s=16,col='#4f7a3a',trunk='#6b4a2e'){const c=iso.P([x,y,0]);return `<ellipse cx="${f(c[0]+8)}" cy="${f(c[1]+2)}" rx="${f(s*1.3)}" ry="${f(s*0.5)}" fill="#000" opacity=".3" filter="url(#blur2)"/><path d="M${f(c[0]-3)} ${f(c[1])}l1 ${f(-s*1.6)}h4l1 ${f(s*1.6)}z" fill="${trunk}" stroke="${INK}" stroke-width="2.2"/>`+P.bush(iso,x,y,s,col,s*1.5).replace(/<ellipse[^>]*blur2[^>]*\/>/,'');},
 anvil(iso,x,y){const c=iso.P([x,y,0]);return `<path d="M${f(c[0]-6)} ${f(c[1])}h12l-2 -8h-8z" fill="#5a4636" stroke="${INK}" stroke-width="2"/><path d="M${f(c[0]-12)} ${f(c[1]-8)}h20l6 -3h-4l-2 -4h-18q-4 2 -2 7z" fill="#4a4f58" stroke="${INK}" stroke-width="2.2"/><path d="M${f(c[0]-10)} ${f(c[1]-14)}h15" stroke="#c9d0da" stroke-width="1.6"/>`;},
 // flat sign board standing on ground (pictogram only)
 board(iso,x,y,{w=16,h=12,col='#5a3a22',icon=''}={}){return iso.onFace([x,y,h+10],[x+1,y,h+10],[x,y,h+9],`<rect x="-1.5" y="${h}" width="3" height="10" fill="#4a3020" stroke="${INK}" stroke-width="1.5"/><rect x="${w-1.5}" y="${h}" width="3" height="10" fill="#4a3020" stroke="${INK}" stroke-width="1.5"/>${W.sign(-2,0,w+4,h,{bg:col,icon})}`);},
 // little figure-free cart
 cart(iso,x,y,col='#9a6a3c'){let o=iso.box(x,y,6,x+22,y+12,14,{fill:col,tex:'siding',topTex:'grain'});const w1=iso.P([x+5,y+12,4]),w2=iso.P([x+17,y+12,4]);
  for(const w of [w1,w2])o+=`<ellipse cx="${f(w[0])}" cy="${f(w[1])}" rx="5" ry="6" fill="#5a3a20" stroke="${INK}" stroke-width="2.2"/><ellipse cx="${f(w[0])}" cy="${f(w[1])}" rx="1.6" ry="2" fill="${INK}"/>`;return o;},
 smoke(x,y,s=1){return `<g opacity=".85">${[[0,0,9],[6,-12,11],[-2,-26,13],[8,-40,15]].map(([dx,dy,r],i)=>`<circle cx="${f(x+dx*s)}" cy="${f(y+dy*s)}" r="${f(r*s)}" fill="#d9d6d0" opacity="${f(.75-i*.15)}" stroke="${INK}" stroke-width="1.5" stroke-opacity="${f(.35-i*.08)}"/><circle cx="${f(x+dx*s-r*s*0.3)}" cy="${f(y+dy*s-r*s*0.3)}" r="${f(r*s*0.5)}" fill="#fff" opacity="${f(.5-i*.1)}"/>`).join('')}</g>`;},
 flag(iso,x,y,z,h,col='#b8352b'){const b=iso.P([x,y,z]),t=iso.P([x,y,z+h]);return `<path d="M${f(b[0])} ${f(b[1])}V${f(t[1])}" stroke="${INK}" stroke-width="3.5"/><path d="M${f(b[0])} ${f(b[1])}V${f(t[1])}" stroke="#d8c08a" stroke-width="1.5"/><path d="M${f(t[0]+1)} ${f(t[1]+1)}c8 -3 14 3 22 0v12c-8 3 -14 -3 -22 0z" fill="${col}" stroke="${INK}" stroke-width="2"/><path d="M${f(t[0]+1)} ${f(t[1]+8)}c8 -3 14 3 22 0v5c-8 3 -14 -3 -22 0z" fill="#000" opacity=".2"/><circle cx="${f(t[0])}" cy="${f(t[1]-1)}" r="2.2" fill="#f1c85a" stroke="${INK}" stroke-width="1.2"/>`;},
 chimney(iso,x,y,z0,z1,s=10,col='#8a4a36',smoke=true){let o=iso.box(x,y,z0,x+s,y+s,z1,{fill:col,tex:'brick',topTex:null,top:{fill:'#2a1a14',tone:.5}});o+=iso.box(x-1.5,y-1.5,z1,x+s+1.5,y+s+1.5,z1+3,{fill:light(col,.2),top:{fill:'#1a100c',tone:.4}});
  if(smoke){const t=iso.P([x+s/2,y+s/2,z1+3]);o+=P.smoke(t[0]+2,t[1]-8,.9);}return o;},
};
Object.assign(P,{
 column(iso,x,y,z0,z1,r=5,col='#ece3cf',cap='doric'){let o=iso.box(x-r-1.5,y-r-1.5,z0,x+r+1.5,y+r+1.5,z0+4,{fill:col,ao:false});
  o+=iso.cyl(x,y,r,z0+4,z1-5,col,{top:false});const a=iso.P([x,y,z0+4]),b=iso.P([x,y,z1-5]);const rx=r*Math.SQRT2;
  for(const t of[-.45,0,.45])o+=`<path d="M${f(a[0]+t*rx)} ${f(a[1]+2)}V${f(b[1])}" stroke="#000" stroke-width=".9" opacity=".22"/>`;
  o+=iso.box(x-r-2.5,y-r-2.5,z1-5,x+r+2.5,y+r+2.5,z1,{fill:col,ao:false});
  if(cap==='ionic'){const c=iso.P([x,y,z1-3]);o+=`<circle cx="${f(c[0]-rx-1)}" cy="${f(c[1]+1)}" r="2.6" fill="${col}" stroke="${INK}" stroke-width="1.5"/><circle cx="${f(c[0]+rx+1)}" cy="${f(c[1]+1)}" r="2.6" fill="${shade(col,.25)}" stroke="${INK}" stroke-width="1.5"/>`;}
  return o;},
 palm(iso,x,y,h=70,lean=10){const b=iso.P([x,y,0]);const t=[b[0]+lean,b[1]-h*1.1];let o=`<ellipse cx="${f(b[0]+14)}" cy="${f(b[1]+2)}" rx="22" ry="7" fill="#000" opacity=".25" filter="url(#blur2)"/>`;
  o+=`<path d="M${f(b[0]-4)} ${f(b[1])} Q${f(b[0]-2+lean*0.2)} ${f(b[1]-h*0.6)} ${f(t[0]-2.5)} ${f(t[1])} L${f(t[0]+2.5)} ${f(t[1])} Q${f(b[0]+4+lean*0.2)} ${f(b[1]-h*0.6)} ${f(b[0]+4)} ${f(b[1])}Z" fill="#8a6440" stroke="${INK}" stroke-width="2.4"/>`;
  for(let i=1;i<9;i++){const q=i/9;const px=b[0]+(t[0]-b[0])*q*q*0.9+lean*0.1*q,py=b[1]+(t[1]-b[1])*q;o+=`<path d="M${f(px-3.5)} ${f(py)}q3.5 2 7 0" stroke="${INK}" stroke-width="1.2" fill="none" opacity=".7"/>`;}
  const fr=[[-34,6],[-26,-10],[-8,-18],[14,-16],[30,-6],[36,10],[-18,14],[20,16]];
  for(const [dx,dy] of fr){const ex=t[0]+dx,ey=t[1]+dy+8;const mx=t[0]+dx*0.5,my=t[1]+dy*0.5-10;
   o+=`<path d="M${f(t[0])} ${f(t[1])} Q${f(mx)} ${f(my-4)} ${f(ex)} ${f(ey)} Q${f(mx+2)} ${f(my+6)} ${f(t[0])} ${f(t[1]+3)}Z" fill="#5d8a3a" stroke="${INK}" stroke-width="2"/><path d="M${f(t[0])} ${f(t[1]+1)} Q${f(mx)} ${f(my)} ${f(ex)} ${f(ey)}" stroke="#2f4f22" stroke-width="1" fill="none"/><path d="M${f(t[0])} ${f(t[1])} Q${f(mx)} ${f(my-3)} ${f(ex-dx*0.2)} ${f(ey-dy*0.2-2)}" stroke="#a9cf6a" stroke-width="1.2" fill="none" opacity=".8"/>`;}
  o+=`<circle cx="${f(t[0]-2)}" cy="${f(t[1]+4)}" r="3" fill="#8a3a1a" stroke="${INK}" stroke-width="1.2"/><circle cx="${f(t[0]+3)}" cy="${f(t[1]+5)}" r="3" fill="#a04a20" stroke="${INK}" stroke-width="1.2"/>`;
  return o;},
 cypress(iso,x,y,h=60){const b=iso.P([x,y,0]);const t=b[1]-h*1.1;return `<ellipse cx="${f(b[0]+10)}" cy="${f(b[1]+2)}" rx="14" ry="5" fill="#000" opacity=".28" filter="url(#blur2)"/><rect x="${f(b[0]-2)}" y="${f(b[1]-8)}" width="4" height="8" fill="#5a3a22" stroke="${INK}" stroke-width="1.5"/>`
  +`<path d="M${f(b[0])} ${f(t)} C${f(b[0]+12)} ${f(t+h*0.35)} ${f(b[0]+13)} ${f(b[1]-14)} ${f(b[0]+3)} ${f(b[1]-6)} L${f(b[0]-3)} ${f(b[1]-6)} C${f(b[0]-13)} ${f(b[1]-14)} ${f(b[0]-12)} ${f(t+h*0.35)} ${f(b[0])} ${f(t)}Z" fill="#3c5e34" stroke="${INK}" stroke-width="2.4"/>`
  +`<path d="M${f(b[0]+1)} ${f(t+4)} C${f(b[0]+11)} ${f(t+h*0.38)} ${f(b[0]+11)} ${f(b[1]-16)} ${f(b[0]+3)} ${f(b[1]-7)} L${f(b[0]+1)} ${f(b[1]-7)}Z" fill="#22382a" opacity=".55"/><path d="M${f(b[0]-3)} ${f(t+12)} q-6 ${f(h*0.3)} -3 ${f(h*0.6)}" stroke="#7aa65a" stroke-width="2" fill="none" opacity=".8"/>`;},
 amphora(iso,x,y,s=1,col='#b8643a'){const c=iso.P([x,y,0]);const X=c[0],Y=c[1];return `<path d="M${f(X-2*s)} ${f(Y)} q${f(-7*s)} ${f(-6*s)} ${f(-6*s)} ${f(-14*s)} q${f(1*s)} ${f(-6*s)} ${f(5*s)} ${f(-8*s)} v${f(-4*s)} h${f(6*s)} v${f(4*s)} q${f(4*s)} ${f(2*s)} ${f(5*s)} ${f(8*s)} q${f(1*s)} ${f(8*s)} ${f(-6*s)} ${f(14*s)}z" fill="${col}" stroke="${INK}" stroke-width="2"/><path d="M${f(X+1*s)} ${f(Y-26*s)} q${f(7*s)} ${f(1*s)} ${f(4*s)} ${f(8*s)}M${f(X-1*s)} ${f(Y-26*s)} q${f(-7*s)} ${f(1*s)} ${f(-4*s)} ${f(8*s)}" stroke="${INK}" stroke-width="1.6" fill="none"/><path d="M${f(X+2*s)} ${f(Y-18*s)} q${f(4*s)} ${f(6*s)} ${f(0)} ${f(16*s)}" stroke="#000" stroke-width="${f(3*s)}" opacity=".18" fill="none"/><path d="M${f(X-4*s)} ${f(Y-16*s)} q${f(-1*s)} ${f(5*s)} ${f(1*s)} ${f(9*s)}" stroke="#fff" stroke-width="1.4" opacity=".5" fill="none"/><path d="M${f(X-5.5*s)} ${f(Y-12*s)}h${f(11*s)}" stroke="#2a1208" stroke-width="1.4" opacity=".6"/>`;},
 basket(iso,x,y,s=8,fruit='#d2452e'){const c=iso.P([x,y,0]);const X=c[0],Y=c[1];let o=`<path d="M${f(X-s)} ${f(Y-s*0.9)} L${f(X-s*0.75)} ${f(Y)} Q${f(X)} ${f(Y+s*0.35)} ${f(X+s*0.75)} ${f(Y)} L${f(X+s)} ${f(Y-s*0.9)}Z" fill="#b48a4a" stroke="${INK}" stroke-width="2"/>`;
  o+=`<path d="M${f(X-s*0.9)} ${f(Y-s*0.5)}Q${f(X)} ${f(Y-s*0.2)} ${f(X+s*0.9)} ${f(Y-s*0.5)}" stroke="#6a4a22" stroke-width="1" fill="none"/>`;
  for(const [dx,dy] of [[-.5,-1.05],[0,-1.2],[.5,-1.05],[-.25,-1.4],[.25,-1.38]])o+=`<circle cx="${f(X+dx*s)}" cy="${f(Y+dy*s)}" r="${f(s*0.32)}" fill="${fruit}" stroke="${INK}" stroke-width="1.3"/><circle cx="${f(X+dx*s-s*0.1)}" cy="${f(Y+dy*s-s*0.1)}" r="${f(s*0.1)}" fill="#fff" opacity=".6"/>`;
  o+=`<ellipse cx="${f(X)}" cy="${f(Y-s*0.9)}" rx="${f(s)}" ry="${f(s*0.3)}" fill="none" stroke="${INK}" stroke-width="1.8"/>`;return o;},
 water(iso,x0,y0,x1,y1,z=0,col='#2f6f86'){return iso.face([[x0,y0,z],[x1,y0,z],[x1,y1,z],[x0,y1,z]],{fill:col,ao:false,sheen:false,tone:.6,content:({x,y,w,h})=>{let o=`<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="url(#fadeDown)" opacity=".6"/>`;const r=rng(x0*3+y0);for(let i=0;i<Math.round(w*h/260);i++){const px=x+r()*w,py=y+r()*h;o+=`<path d="M${f(px)} ${f(py)}q4 -2 8 0" stroke="#bfe8f0" stroke-width="1.2" fill="none" opacity="${f(.3+r()*.4)}"/>`;}return o;}});},
 banner(iso,p0,p1,p2,x,w,h,col='#b8352b',emb='#f1c85a'){return iso.onFace(p0,p1,p2,`<rect x="${x-2}" y="-2" width="${w+4}" height="3" fill="#4a3020" stroke="${INK}" stroke-width="1.5"/><path d="M${x} 0h${w}v${h}l${-w/2} ${-w*0.35}l${-w/2} ${w*0.35}z" fill="${col}" stroke="${INK}" stroke-width="2"/><path d="M${x+w*0.65} 0h${w*0.35}v${h}l${-w*0.35} ${-w*0.12}z" fill="#000" opacity=".2"/><circle cx="${x+w/2}" cy="${h*0.4}" r="${w*0.22}" fill="none" stroke="${emb}" stroke-width="2"/><path d="M${x+2} ${h*0.08}h${w-4}" stroke="${emb}" stroke-width="1.5"/>`);},
 torch(iso,x,y,z){const c=iso.P([x,y,z]);return `<circle cx="${f(c[0])}" cy="${f(c[1]-8)}" r="12" fill="#ffb347" opacity=".45" filter="url(#blur4)"/><path d="M${f(c[0]-2)} ${f(c[1])}h4l1 -6h-6z" fill="#4a3020" stroke="${INK}" stroke-width="1.5"/><path d="M${f(c[0])} ${f(c[1]-16)}q5 5 3 9q-3 2 -6 0q-2 -4 3 -9z" fill="#ffcf4a" stroke="#a8401a" stroke-width="1.2"/><path d="M${f(c[0])} ${f(c[1]-11)}q2 2 1 4h-2q-1 -2 1 -4z" fill="#fff6c0"/>`;},
 steps(iso,x0,y0,x1,y1,n,hz,dir='y',col='#d8cdb5'){let o='';for(let i=0;i<n;i++){const t=i/n;if(dir==='y')o+=iso.box(x0,y0,i*hz,x1,y1-(y1-y0)*t,(i+1)*hz,{fill:col,ao:false,w:2});else o+=iso.box(x0,y0,i*hz,x1-(x1-x0)*t,y1,(i+1)*hz,{fill:col,ao:false,w:2});}return o;},
 car(iso,x,y,col='#c0392b',dir='x',style='old'){ // small parked car, length along dir
  const Lx=dir==='x'?30:16,Ly=dir==='x'?16:30;let o=iso.boxShadow(x,y,x+Lx,y+Ly,8,.35);
  o+=iso.box(x,y,3,x+Lx,y+Ly,11,{fill:col,ao:false,w:2.4});
  const cx0=dir==='x'?x+7:x+2,cy0=dir==='x'?y+2:y+7,cx1=dir==='x'?x+22:x+14,cy1=dir==='x'?y+14:y+22;
  o+=iso.box(cx0,cy0,11,cx1,cy1,18,{fill:style==='future'?'#2a3a5a':'#9fc6dc',top:{fill:col},left:{fill:'#6f9fbf',content:({w,h})=>`<path d="M${w*0.5} 0V${h}" stroke="${col}" stroke-width="2"/><path d="M2 ${h-2}L${w*0.3} 2" stroke="#fff" stroke-width="1.4" opacity=".5"/>`},right:{fill:'#5a87a8'},ao:false,w:2.2});
  if(style!=='future'){const wh=dir==='x'?[[x+6,y+Ly],[x+24,y+Ly]]:[[x+Lx,y+6],[x+Lx,y+24]];for(const [wx,wy] of wh){const c=iso.P([wx,wy,3]);o+=`<ellipse cx="${f(c[0])}" cy="${f(c[1])}" rx="3.6" ry="4" fill="#1a1a1e" stroke="${INK}" stroke-width="1.5"/><ellipse cx="${f(c[0])}" cy="${f(c[1])}" rx="1.4" ry="1.6" fill="#b8bec8"/>`;}}
  const hl=dir==='x'?iso.P([x+Lx,y+Ly-3,8]):iso.P([x+3,y+Ly,8]);o+=`<circle cx="${f(hl[0])}" cy="${f(hl[1])}" r="1.8" fill="#fff6c0" stroke="${INK}" stroke-width="1"/>`;
  return o;},
 ac(iso,x,y,z,s=12){let o=iso.box(x,y,z,x+s,y+s,z+s*0.6,{fill:'#a9adb3',tex:'corrug',ao:false,w:2.2});const c=iso.P([x+s/2,y+s/2,z+s*0.6]);o+=`<ellipse cx="${f(c[0])}" cy="${f(c[1])}" rx="${f(s*0.55)}" ry="${f(s*0.28)}" fill="#3a3e46" stroke="${INK}" stroke-width="1.5"/><path d="M${f(c[0]-s*0.4)} ${f(c[1])}h${f(s*0.8)}M${f(c[0])} ${f(c[1]-s*0.2)}v${f(s*0.4)}" stroke="#7a8088" stroke-width="1.2"/>`;return o;},
 dish(iso,x,y,z,r=10){const c=iso.P([x,y,z]);return `<path d="M${f(c[0])} ${f(c[1])}v-10" stroke="${INK}" stroke-width="3"/><g transform="translate(${f(c[0])} ${f(c[1]-14)}) rotate(-25)"><ellipse rx="${r}" ry="${r*0.55}" fill="#e6e9ee" stroke="${INK}" stroke-width="2.2"/><ellipse cx="2" cy="1.5" rx="${r*0.7}" ry="${r*0.35}" fill="#b8bec8"/><path d="M0 0l${r*0.6} ${-r*0.9}" stroke="${INK}" stroke-width="1.6"/><circle cx="${r*0.6}" cy="${-r*0.9}" r="1.8" fill="#e04a3a" stroke="${INK}" stroke-width="1"/></g>`;},
 pipe(iso,pts,r=3,col='#8a8f98'){const sp=pts.map(p=>iso.P(p));const d='M'+sp.map(p=>f(p[0])+' '+f(p[1])).join('L');return `<path d="${d}" fill="none" stroke="${INK}" stroke-width="${r*2+3}" stroke-linejoin="round" stroke-linecap="round"/><path d="${d}" fill="none" stroke="${col}" stroke-width="${r*2}" stroke-linejoin="round" stroke-linecap="round"/><path d="${d}" fill="none" stroke="#fff" stroke-width="${Math.max(1,r*0.6)}" opacity=".45" transform="translate(-${r*0.4} -${r*0.5})" stroke-linejoin="round"/>`;},
 glowPad(iso,x,y,r,col='#7ff4ff',z=0){const c=iso.P([x,y,z]);const rx=r*Math.SQRT2;return `<ellipse cx="${f(c[0])}" cy="${f(c[1])}" rx="${f(rx*1.3)}" ry="${f(rx*0.65)}" fill="${col}" opacity=".35" filter="url(#blur8)"/><ellipse cx="${f(c[0])}" cy="${f(c[1])}" rx="${f(rx)}" ry="${f(rx/2)}" fill="none" stroke="${col}" stroke-width="2.5"/>`;},
});
module.exports={PL,mkIso,plot,onPlot,gable,hip,flatRoof,P,GROUND,rowWins};
