// tiles, smoke puff, crates, seal/ticket icons, medals
const L=require('./lib');const {INK,f,mix,shade,light,rng,Iso,renderAll,uid}=L;
const I={};
const noise=(id,freq,oct,seed,matrix)=>`<filter id="${id}" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="${freq}" numOctaves="${oct}" seed="${seed}"/><feColorMatrix type="matrix" values="${matrix}"/></filter>`;

// ---------- tiles ----------
const poly4=(iso,pts,dx,dy)=>pts.map(p=>{const q=iso.P(p);return f(q[0]+dx)+' '+f(q[1]+dy);}).join('L')+'Z';
function dirtBase(seed){let s=noise('dn'+seed,'0.012',4,seed,'0 0 0 0 0.24  0 0 0 0 0.17  0 0 0 0 0.11  0 0 0 1.4 -0.35')+noise('dg'+seed,'0.35',2,seed+3,'0 0 0 0 0.05  0 0 0 0 0.04  0 0 0 0 0.03  0 0 0 2.2 -1.0');
 s+=`<rect width="512" height="512" fill="#33271d"/><rect width="512" height="512" filter="url(#dn${seed})" opacity=".9"/><rect width="512" height="512" filter="url(#dg${seed})" opacity=".7"/>`;
 const r=rng(seed);
 // gravel pebbles
 for(let i=0;i<260;i++){const x=r()*512,y=r()*512,rr=1+r()*3.2;const c=['#4a3c30','#55473a','#2a2018','#5e5244'][Math.floor(r()*4)];s+=`<ellipse cx="${f(x)}" cy="${f(y)}" rx="${f(rr)}" ry="${f(rr*0.75)}" fill="${c}" transform="rotate(${f(r()*180)} ${f(x)} ${f(y)})"/><ellipse cx="${f(x-rr*0.3)}" cy="${f(y-rr*0.3)}" rx="${f(rr*0.4)}" ry="${f(rr*0.3)}" fill="#7a6a58" opacity=".35"/>`;}
 // a few bigger stones
 for(let i=0;i<14;i++){const x=20+r()*470,y=20+r()*470,rr=5+r()*6;s+=`<ellipse cx="${f(x+2)}" cy="${f(y+2)}" rx="${f(rr)}" ry="${f(rr*0.7)}" fill="#120c08" opacity=".5"/><ellipse cx="${f(x)}" cy="${f(y)}" rx="${f(rr)}" ry="${f(rr*0.7)}" fill="#4e4236"/><ellipse cx="${f(x-rr*0.3)}" cy="${f(y-rr*0.25)}" rx="${f(rr*0.5)}" ry="${f(rr*0.3)}" fill="#6e604e" opacity=".6"/>`;}
 // tyre tracks
 s+=`<path d="M-20 360 C120 330 260 380 540 300" stroke="#1e160f" stroke-width="16" fill="none" opacity=".35"/><path d="M-20 392 C120 362 260 412 540 332" stroke="#1e160f" stroke-width="16" fill="none" opacity=".35"/>`;
 for(let i=0;i<40;i++){const t=i/40;const x=-20+t*560;const y=360+Math.sin(t*3)*-10-t*50;s+=`<path d="M${f(x)} ${f(y-6)}l6 12" stroke="#120c08" stroke-width="2" opacity=".2"/>`;}
 return s;}
function weed(x,y,s=1,seed=1){const r=rng(seed);let o='';for(let i=0;i<9;i++){const a=-Math.PI/2+(r()-.5)*2.2,l=(10+r()*14)*s;const ex=x+Math.cos(a)*l,ey=y+Math.sin(a)*l;o+=`<path d="M${x} ${y}Q${f(x+Math.cos(a)*l*0.5+3)} ${f(y+Math.sin(a)*l*0.5)} ${f(ex)} ${f(ey)}" stroke="#2a3a1a" stroke-width="${f(3.4*s)}" fill="none" stroke-linecap="round"/><path d="M${x} ${y}Q${f(x+Math.cos(a)*l*0.5+3)} ${f(y+Math.sin(a)*l*0.5)} ${f(ex)} ${f(ey)}" stroke="${r()<.5?'#4a5e2a':'#5a6e32'}" stroke-width="${f(2*s)}" fill="none" stroke-linecap="round"/>`;}
 return `<ellipse cx="${x+3}" cy="${y+2}" rx="${14*s}" ry="${7*s}" fill="#000" opacity=".3" filter="url(#blur2)"/>`+o;}
function vig(op=.55){return `<radialGradient id="tv"><stop offset=".5" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="${op}"/></radialGradient><rect width="512" height="512" fill="url(#tv)"/>`;}
I.tile_owned=()=>{let s=noise('an','0.02',4,5,'0 0 0 0 0.16  0 0 0 0 0.16  0 0 0 0 0.18  0 0 0 1.2 -0.25')+noise('ag','0.6',2,8,'0 0 0 0 0.3  0 0 0 0 0.3  0 0 0 0 0.32  0 0 0 2.5 -1.3');
 s+=`<rect width="512" height="512" fill="#262629"/><rect width="512" height="512" filter="url(#an)"/><rect width="512" height="512" filter="url(#ag)" opacity=".35"/>`;
 // cobblestones (jittered grid), low contrast
 const r=rng(3);for(let j=0;j<17;j++)for(let i=0;i<17;i++){const cx=i*31+(j%2?15:0)+(r()-.5)*6,cy=j*31+(r()-.5)*6,w=12+r()*3,h=11+r()*3;const c=mix('#2c2c30','#3a3a3e',r());
  s+=`<rect x="${f(cx-w)}" y="${f(cy-h)}" width="${f(w*2)}" height="${f(h*2)}" rx="${f(w*0.7)}" fill="#18181b" transform="translate(1.5 2)"/><rect x="${f(cx-w)}" y="${f(cy-h)}" width="${f(w*2)}" height="${f(h*2)}" rx="${f(w*0.7)}" fill="${c}"/><rect x="${f(cx-w+3)}" y="${f(cy-h+2)}" width="${f(w*1.2)}" height="${f(h*0.7)}" rx="${f(w*0.4)}" fill="#55555a" opacity=".22"/>`;}
 // asphalt patch over cobbles (worn)
 s+=`<path d="M300 40 C380 30 470 70 500 150 C520 230 470 290 400 300 C330 310 270 260 260 190 C250 120 240 60 300 40Z" fill="#232326"/><path d="M300 40 C380 30 470 70 500 150 C520 230 470 290 400 300 C330 310 270 260 260 190 C250 120 240 60 300 40Z" fill="url(#gravel)" opacity=".5"/><path d="M300 40 C380 30 470 70 500 150 C520 230 470 290 400 300 C330 310 270 260 260 190 C250 120 240 60 300 40Z" fill="none" stroke="#141416" stroke-width="2" opacity=".6"/>`;
 // faint brick patches
 s+=`<g opacity=".45"><rect x="40" y="320" width="150" height="110" fill="#3a2a26"/><rect x="40" y="320" width="150" height="110" fill="url(#brick)"/></g><rect x="40" y="320" width="150" height="110" fill="none" stroke="#141416" stroke-width="2" opacity=".6"/>`;
 s+=`<g opacity=".35"><rect x="330" y="400" width="110" height="70" fill="#3a2a26"/><rect x="330" y="400" width="110" height="70" fill="url(#brick)"/></g>`;
 // cracks
 const crack=(pts,w)=>`<path d="M${pts.map(p=>p.join(' ')).join('L')}" stroke="#0e0e10" stroke-width="${w}" fill="none" stroke-linejoin="round"/><path d="M${pts.map(p=>p.join(' ')).join('L')}" stroke="#4a4a50" stroke-width="${w*0.4}" fill="none" opacity=".35" transform="translate(-1 -1)"/>`;
 s+=crack([[290,120],[330,150],[340,190],[380,210],[420,260]],3)+crack([[340,190],[310,230]],2)+crack([[60,90],[110,110],[130,160],[180,170]],2.5)+crack([[200,470],[230,430],[280,420]],2);
 // manhole cover
 s+=`<circle cx="150" cy="230" r="34" fill="#1a1a1c"/><circle cx="150" cy="230" r="30" fill="#303034" stroke="#141416" stroke-width="2"/>`+Array.from({length:6},(_,i)=>`<path d="M${126} ${214+i*6.5}h48" stroke="#202024" stroke-width="2.4"/>`).join('')+`<circle cx="150" cy="230" r="30" fill="none" stroke="#4a4a50" stroke-width="1.2" opacity=".5"/>`;
 // oil stain
 s+=`<ellipse cx="410" cy="350" rx="40" ry="26" fill="#0c0c10" opacity=".35" filter="url(#blur8)"/>`;
 return s+vig(.6);};
I.tile_forsale=()=>{let s=dirtBase(11);s+=weed(110,140,1.1,1)+weed(390,420,1.3,2)+weed(430,120,.8,3)+weed(80,430,.7,4);return s+vig(.6);};
I.tile_locked=()=>{let s=dirtBase(11);s+=weed(110,140,1.1,1)+weed(390,420,1.3,2);
 s+=`<rect width="512" height="512" fill="#000" opacity=".22"/>`;
 // iron fence ring: rails + posts with spear tips, seen from above-front
 const m=26;const posts=[];for(let i=0;i<=11;i++){const t=m+i*(512-2*m)/11;posts.push([t,m],[t,512-m]);if(i>0&&i<11)posts.push([m,t],[512-m,t]);}
 const rail=(x1,y1,x2,y2)=>`<path d="M${x1} ${y1}L${x2} ${y2}" stroke="#000" stroke-width="9" opacity=".5" transform="translate(4 6)" filter="url(#blur2)"/><path d="M${x1} ${y1}L${x2} ${y2}" stroke="#0c0c0e" stroke-width="8"/><path d="M${x1} ${y1}L${x2} ${y2}" stroke="#3a3a42" stroke-width="3" transform="translate(-1 -1.5)"/>`;
 s+=rail(m,m,512-m,m)+rail(m,512-m,512-m,512-m)+rail(m,m,m,512-m)+rail(512-m,m,512-m,512-m);
 s+=rail(m+12,m+12,512-m-12,m+12).replace(/stroke-width="8"/,'stroke-width="5"')+rail(m+12,512-m-12,512-m-12,512-m-12).replace(/stroke-width="8"/,'stroke-width="5"')+rail(m+12,m+12,m+12,512-m-12).replace(/stroke-width="8"/,'stroke-width="5"')+rail(512-m-12,m+12,512-m-12,512-m-12).replace(/stroke-width="8"/,'stroke-width="5"');
 // pickets between rails (short bars)
 for(let i=0;i<40;i++){const t=m+6+i*(512-2*m-12)/39;s+=`<path d="M${f(t)} ${m}L${f(t)} ${m+12}M${f(t)} ${512-m}L${f(t)} ${512-m-12}M${m} ${f(t)}L${m+12} ${f(t)}M${512-m} ${f(t)}L${512-m-12} ${f(t)}" stroke="#141418" stroke-width="3.4"/>`;}
 for(const [x,y] of posts)s+=`<circle cx="${f(x+3)}" cy="${f(y+4)}" r="9" fill="#000" opacity=".45" filter="url(#blur2)"/><circle cx="${f(x)}" cy="${f(y)}" r="8" fill="#101014" stroke="#000" stroke-width="2"/><path d="M${f(x)} ${f(y-9)}L${f(x+5)} ${f(y)}L${f(x)} ${f(y+9)}L${f(x-5)} ${f(y)}Z" fill="#2e2e36" stroke="#000" stroke-width="1.4"/><circle cx="${f(x-2)}" cy="${f(y-3)}" r="2" fill="#6a6a78" opacity=".7"/>`;
 // gate chain + padlock at bottom centre
 const px=256,py=470;
 for(let i=0;i<9;i++){const x=196+i*15,y=486-Math.sin(i/8*Math.PI)*-10;s+=`<ellipse cx="${f(x)}" cy="${f(y-12)}" rx="6" ry="4" fill="none" stroke="#000" stroke-width="4.6"/><ellipse cx="${f(x)}" cy="${f(y-12)}" rx="6" ry="4" fill="none" stroke="#7a7a84" stroke-width="2"/>`;}
 s+=`<g transform="translate(${px} ${py-10}) scale(1.45)"><ellipse cx="4" cy="34" rx="26" ry="8" fill="#000" opacity=".4" filter="url(#blur2)"/><path d="M-12 -2V-14a12 12 0 0 1 24 0V-2" fill="none" stroke="#000" stroke-width="9"/><path d="M-12 -2V-14a12 12 0 0 1 24 0V-2" fill="none" stroke="#9aa0aa" stroke-width="4.5"/><path d="M-10 -10a10 10 0 0 1 8 -12" stroke="#e8ecf0" stroke-width="1.6" fill="none"/>`
  +`<rect x="-20" y="-4" width="40" height="34" rx="6" fill="#b8862a" stroke="#000" stroke-width="3"/><rect x="-20" y="-4" width="40" height="34" rx="6" fill="url(#brassH)" opacity=".85"/><rect x="-16" y="-1" width="32" height="4" rx="2" fill="#fff4c0" opacity=".55"/><circle cx="0" cy="10" r="4.4" fill="#2a1a08"/><path d="M-2 12h4l1 9h-6z" fill="#2a1a08"/></g>`;
 return s+vig(.6);};

// ---------- smoke puff ----------
I.smoke_puff=()=>{const blobs=[[128,150,62],[78,140,44],[178,138,48],[104,98,46],[154,92,50],[128,70,38],[60,170,30],[196,172,32]];
 let base=blobs.map(([x,y,r])=>`<circle cx="${x}" cy="${y}" r="${r}"/>`).join('');
 return `<clipPath id="sp">${base}</clipPath><g fill="#5a5a66" opacity=".45" transform="translate(0 6)" filter="url(#blur4)">${base}</g><g fill="none" stroke="#7a7a86" stroke-width="7">${base}</g><g fill="#d9dbe0">${base}</g>`+
  `<g clip-path="url(#sp)"><rect x="0" y="150" width="256" height="106" fill="#a9acb6" opacity=".75" filter="url(#blur8)"/>${blobs.map(([x,y,r])=>`<circle cx="${x+r*0.25}" cy="${y+r*0.35}" r="${r*0.75}" fill="#b4b7c0" opacity=".55"/>`).join('')}${blobs.map(([x,y,r])=>`<circle cx="${x-r*0.28}" cy="${y-r*0.32}" r="${r*0.55}" fill="#ffffff" opacity=".85"/>`).join('')}${blobs.map(([x,y,r])=>`<circle cx="${x-r*0.38}" cy="${y-r*0.42}" r="${r*0.22}" fill="#ffffff"/>`).join('')}</g>`;};

// ---------- crates ----------
I.crate_basic=()=>{const iso=new Iso(256,232,1.22,1.1);let s='';const x0=0,y0=0,x1=172,y1=172,h=146;
 s+=`<path d="M${poly4(iso,[[0,0,0],[172,0,0],[172,172,0],[0,172,0]],14,8)}" fill="#000" opacity=".4" filter="url(#blur8)"/>`;
 const wood='#b07a44';
 const planks=(n)=>({w,h:hh})=>{let o='';for(let i=1;i<n;i++)o+=`<path d="M0 ${i*hh/n}H${w}" stroke="#3a2210" stroke-width="2.4"/><path d="M0 ${i*hh/n+1.6}H${w}" stroke="#e8b880" stroke-width="1" opacity=".5"/>`;
  for(let i=0;i<n;i++)for(let k=0;k<3;k++){const yy=i*hh/n+4+k*(hh/n-8)/2;o+=`<path d="M${8+k*30} ${f(yy)}c30 2 60 -2 ${w-40} 0" stroke="#4a2a12" stroke-width=".9" fill="none" opacity=".45"/>`;}
  return o;};
 const frame=({w,h:hh})=>`<rect x="0" y="0" width="${w}" height="${hh}" fill="none" stroke="#7a4a22" stroke-width="22"/><rect x="0" y="0" width="${w}" height="${hh}" fill="none" stroke="#3a2210" stroke-width="2.4" transform="translate(0 0)"/><rect x="11" y="11" width="${w-22}" height="${hh-22}" fill="none" stroke="#3a2210" stroke-width="2.4"/><path d="M14 ${hh-14}L${w-14} 14" stroke="#7a4a22" stroke-width="18"/><path d="M14 ${hh-14}L${w-14} 14" stroke="none"/><path d="M8 ${hh-20}L${w-20} 8M20 ${hh-8}L${w-8} 20" stroke="#3a2210" stroke-width="2.2"/>`
  +[[3,3],[w-3,3],[3,hh-3],[w-3,hh-3]].map(([x,y])=>`<rect x="${x-10}" y="${y-10}" width="20" height="20" fill="#5a5a60" stroke="${INK}" stroke-width="2"/><circle cx="${x}" cy="${y}" r="2.6" fill="#2a2a2e"/><circle cx="${x-1}" cy="${y-1}" r="1" fill="#c8ccd2"/>`).join('');
 const star=(cx,cy,R)=>{let p='';for(let i=0;i<10;i++){const a=-Math.PI/2+i*Math.PI/5,rr=i%2?R*0.42:R;p+=(i?'L':'M')+f(cx+Math.cos(a)*rr)+' '+f(cy+Math.sin(a)*rr);}return `<path d="${p}Z" fill="#efe4c8" opacity=".85"/><path d="${p}Z" fill="url(#gravel)" opacity=".6"/>`;};
 s+=iso.face([[x0,y0,h],[x1,y0,h],[x1,y1,h],[x0,y1,h]],{fill:wood,tex:'grain',ao:false,tone:.9,content:a=>planks(5)(a)+frame(a),rim:[3,0]});
 s+=iso.face([[x0,y1,h],[x1,y1,h],[x1,y1,0],[x0,y1,0]],{fill:wood,tex:'grain',content:a=>planks(5)(a)+frame(a)+star(a.w/2,a.h/2,40),ao:.6});
 s+=iso.face([[x1,y1,h],[x1,y0,h],[x1,y0,0],[x1,y1,0]],{fill:wood,tex:'grain',content:a=>planks(5)(a)+frame(a),ao:.6});
 // rope handles on right face
 const rh=(u)=>{const p0=iso.P([x1,y1-u,h*0.62]),p1=iso.P([x1,y1-u-40,h*0.62]);const mx=(p0[0]+p1[0])/2,my=(p0[1]+p1[1])/2+26;
  return `<path d="M${f(p0[0])} ${f(p0[1])}Q${f(mx)} ${f(my)} ${f(p1[0])} ${f(p1[1])}" stroke="${INK}" stroke-width="12" fill="none" stroke-linecap="round"/><path d="M${f(p0[0])} ${f(p0[1])}Q${f(mx)} ${f(my)} ${f(p1[0])} ${f(p1[1])}" stroke="#c9a46a" stroke-width="7" fill="none" stroke-linecap="round"/><path d="M${f(p0[0])} ${f(p0[1])}Q${f(mx)} ${f(my)} ${f(p1[0])} ${f(p1[1])}" stroke="#7a5a2a" stroke-width="7" fill="none" stroke-dasharray="3 4"/>`+[p0,p1].map(p=>`<circle cx="${f(p[0])}" cy="${f(p[1])}" r="7" fill="#5a5a60" stroke="${INK}" stroke-width="2"/>`).join('');};
 s+=rh(66);
 // rope handle on left face
 { const p0=iso.P([x0+50,y1,h*0.85]),p1=iso.P([x0+120,y1,h*0.85]);const mx=(p0[0]+p1[0])/2,my=(p0[1]+p1[1])/2+20;s+=`<path d="M${f(p0[0])} ${f(p0[1])}Q${f(mx)} ${f(my)} ${f(p1[0])} ${f(p1[1])}" stroke="${INK}" stroke-width="12" fill="none" stroke-linecap="round"/><path d="M${f(p0[0])} ${f(p0[1])}Q${f(mx)} ${f(my)} ${f(p1[0])} ${f(p1[1])}" stroke="#d8b47a" stroke-width="7" fill="none" stroke-linecap="round"/><path d="M${f(p0[0])} ${f(p0[1])}Q${f(mx)} ${f(my)} ${f(p1[0])} ${f(p1[1])}" stroke="#8a6a3a" stroke-width="7" fill="none" stroke-dasharray="3 4"/>`+[p0,p1].map(p=>`<circle cx="${f(p[0])}" cy="${f(p[1])}" r="7" fill="#5a5a60" stroke="${INK}" stroke-width="2"/>`).join('');}
 return s;};

I.crate_limited=()=>{const iso=new Iso(238,246,1.22,1.1);let s='';const x0=0,y0=20,x1=186,y1=150,h=104,R=(y1-y0)/2;const teal='#1f5a5e',gold='#e0b04a';
 s+=`<path d="M${poly4(iso,[[0,20,0],[186,20,0],[186,150,0],[0,150,0]],14,8)}" fill="#000" opacity=".4" filter="url(#blur8)"/>`;
 s+=`<circle cx="256" cy="230" r="150" fill="#ffd36b" opacity=".14" filter="url(#blur30)"/>`;
 const panel=({w,h:hh})=>`<rect x="14" y="14" width="${w-28}" height="${hh-28}" rx="6" fill="none" stroke="${gold}" stroke-width="3"/><rect x="20" y="20" width="${w-40}" height="${hh-40}" rx="4" fill="#000" opacity=".15"/><path d="M${w/2} 22c18 10 18 30 0 40c-18 -10 -18 -30 0 -40z" fill="none" stroke="${gold}" stroke-width="2" opacity=".7"/>`+
  `<path d="M28 ${hh-30}q20 -18 40 0t40 0" stroke="${gold}" stroke-width="1.6" fill="none" opacity=".55"/>`;
 const lac=(o)=>({...o,fill:teal,after:({x,y,w,h:hh})=>`<rect x="${x}" y="${y}" width="${w}" height="${hh}" fill="url(#topLit)"/><path d="M${x+w*0.1} ${y+4}L${x+w*0.45} ${y+hh*0.9}" stroke="#fff" stroke-width="10" opacity=".08"/>`});
 // body
 s+=iso.face([[x0,y1,h],[x1,y1,h],[x1,y1,0],[x0,y1,0]],lac({content:panel,ao:.5}));
 s+=iso.face([[x1,y1,h],[x1,y0,h],[x1,y0,0],[x1,y1,0]],lac({content:panel,ao:.5}));
 // gold corner bands on body
 const vband=(x,y)=>iso.box(x-6,y-6,0,x+6,y+6,h,{fill:gold,ao:false,w:2.4,top:{fill:light(gold,.2)}});
 s+=vband(x0+6,y1-6)+vband(x1-6,y0+6);
 // seam glow (light leaking) under the lid
 const seam=[iso.P([x0,y1,h]),iso.P([x1,y1,h]),iso.P([x1,y0,h])];
 const sd=`M${f(seam[0][0])} ${f(seam[0][1])}L${f(seam[1][0])} ${f(seam[1][1])}L${f(seam[2][0])} ${f(seam[2][1])}`;
 // lid: half cylinder along X
 const N=12,lz=h+4;const pt=(x,a)=>[x,y0+R-Math.cos(a)*R*1.0,lz+Math.sin(a)*R*0.85];
 let lid='';
 for(let i=N-1;i>=0;i--){} // placeholder
 // draw segments from back (a near pi) to front (a near 0) so front overlaps
 const segs=[];for(let i=0;i<N;i++){const a0=Math.PI*i/N,a1=Math.PI*(i+1)/N;segs.push([a0,a1]);}
 for(const [a0,a1] of segs.slice().reverse()){lid+=iso.face([[x0-4,...pt(0,a1).slice(1)],[x1+4,...pt(0,a1).slice(1)],[x1+4,...pt(0,a0).slice(1)],[x0-4,...pt(0,a0).slice(1)]],{fill:teal,ao:false,stroke:false,sheen:false});}
 // lid end cap (half disc) on x=x1+4
 const cap=[];for(let i=0;i<=N;i++){const a=Math.PI*i/N;const p=pt(0,a);cap.push([x1+4,p[1],p[2]]);}
 lid+=iso.face(cap,{fill:teal,ao:false,content:({x,y,w,h:hh})=>`<path d="M${x+w*0.15} ${y+hh}A${w*0.35} ${hh*0.8} 0 0 1 ${x+w*0.85} ${y+hh}" fill="none" stroke="${gold}" stroke-width="3"/>`});
 // outline of lid silhouette
 const front=[];for(let i=0;i<=N;i++){const a=Math.PI*i/N;front.push(iso.P([x0-4,...pt(0,a).slice(1)]));}
 lid+=`<path d="M${front.map(p=>f(p[0])+' '+f(p[1])).join('L')}" fill="none" stroke="${INK}" stroke-width="3"/>`;
 const ridgeA=Math.PI*0.5;const top0=iso.P([x0-4,...pt(0,ridgeA).slice(1)]),top1=iso.P([x1+4,...pt(0,ridgeA).slice(1)]);
 // highlights on lid
 const hl=(a,col,w,op)=>{const p0=iso.P([x0-4,...pt(0,a).slice(1)]),p1=iso.P([x1+4,...pt(0,a).slice(1)]);return `<path d="M${f(p0[0])} ${f(p0[1])}L${f(p1[0])} ${f(p1[1])}" stroke="${col}" stroke-width="${w}" opacity="${op}" stroke-linecap="round"/>`;};
 lid+=hl(Math.PI*0.62,'#7ad0c8',10,.35)+hl(Math.PI*0.58,'#e8fffa',3,.6)+hl(Math.PI*0.2,'#000',14,.18);
 // gold bands across lid
 for(const bx of[x0+30,x1-30]){const band=[];for(let i=0;i<=N;i++){const a=Math.PI*i/N;band.push(iso.P([bx,...pt(0,a).slice(1)]));}
  lid+=`<path d="M${band.map(p=>f(p[0])+' '+f(p[1])).join('L')}" stroke="${INK}" stroke-width="16" fill="none" stroke-linejoin="round"/><path d="M${band.map(p=>f(p[0])+' '+f(p[1])).join('L')}" stroke="${gold}" stroke-width="11" fill="none" stroke-linejoin="round"/><path d="M${band.map(p=>f(p[0]-2)+' '+f(p[1]-2)).join('L')}" stroke="#fff4c0" stroke-width="3" fill="none" opacity=".7"/>`;
  for(let i=1;i<N;i+=2){const p=band[i];lid+=`<circle cx="${f(p[0])}" cy="${f(p[1])}" r="2.6" fill="#7a5a12"/>`;}}
 // lid bottom rim gold
 const rimF=[iso.P([x0-4,y1+2,lz]),iso.P([x1+4,y1+2,lz]),iso.P([x1+4,y0-2,lz])];
 lid+=`<path d="M${rimF.map(p=>f(p[0])+' '+f(p[1])).join('L')}" stroke="${INK}" stroke-width="12" fill="none" stroke-linejoin="round"/><path d="M${rimF.map(p=>f(p[0])+' '+f(p[1])).join('L')}" stroke="${gold}" stroke-width="7" fill="none" stroke-linejoin="round"/>`;
 // glow leaking from the seam: draw under lid rim, above body
 s+=`<path d="${sd}" stroke="#fff6c0" stroke-width="16" fill="none" filter="url(#blur8)" opacity=".95"/><path d="${sd}" stroke="#ffe080" stroke-width="22" fill="none" filter="url(#blur16)" opacity=".45"/>`;
 // light rays up
 s+=`<g opacity=".55" filter="url(#blur4)">`+[[-.9,160],[-.5,200],[-.1,220],[.35,190],[.75,160]].map(([t,l])=>{const bx=256+t*200,by=200+Math.abs(t)*40;return `<path d="M${f(bx-10)} ${f(by)}L${f(bx+t*40-4)} ${f(by-l)}L${f(bx+t*40+14)} ${f(by-l)}L${f(bx+10)} ${f(by)}Z" fill="#fff0a0"/>`;}).join('')+`</g>`;
 s+=lid;
 s+=`<path d="${sd}" stroke="#fffbe0" stroke-width="4" fill="none"/>`;
 // lock plate front centre
 const lp=iso.P([x0+93,y1,h-8]);s+=`<g transform="translate(${f(lp[0])} ${f(lp[1])}) skewY(26.565)"><path d="M-18 -10h36v30l-18 12l-18 -12z" fill="${gold}" stroke="${INK}" stroke-width="3"/><path d="M-18 -10h36v30l-18 12l-18 -12z" fill="url(#brassH)" opacity=".7"/><circle cx="0" cy="6" r="6" fill="#2a1a08"/><path d="M-2 8h4l2 12h-8z" fill="#2a1a08"/><circle cx="0" cy="6" r="14" fill="#fff6c0" opacity=".35" filter="url(#blur4)"/></g>`;
 // sparkles
 for(const [x,y,r] of [[120,120,10],[400,150,8],[360,90,6],[150,330,6],[420,300,7]])s+=`<path d="M${x} ${y-r}L${x+r*0.25} ${y-r*0.25}L${x+r} ${y}L${x+r*0.25} ${y+r*0.25}L${x} ${y+r}L${x-r*0.25} ${y+r*0.25}L${x-r} ${y}L${x-r*0.25} ${y-r*0.25}Z" fill="#fff8d0"/>`;
 return s;};

// ---------- seal + ticket ----------
const eagle=(col,dark)=>{let w='';// right wing feathers, mirrored
 const wing=(sx)=>{let p=`M${2*sx} -6`;const tips=[[34,-30],[40,-18],[42,-6],[38,4],[30,12]];p+=`C${12*sx} -16 ${22*sx} -30 ${tips[0][0]*sx} ${tips[0][1]}`;for(let i=1;i<tips.length;i++){const [x,y]=tips[i];const [px,py]=tips[i-1];p+=`L${(px-6)*sx} ${py+6}L${x*sx} ${y}`;}p+=`L${10*sx} 10Z`;return `<path d="${p}" fill="${col}" stroke="${dark}" stroke-width="2.2" stroke-linejoin="round"/>`+[0,1,2,3].map(i=>`<path d="M${(14+i*5)*sx} ${-12+i*6}l${10*sx} ${-6+i*1}" stroke="${dark}" stroke-width="1.4" opacity=".7"/>`).join('');};
 w+=wing(1)+wing(-1);
 // body + tail
 w+=`<path d="M-8 -6C-10 6 -8 16 -12 24L-6 22L0 30L6 22L12 24C8 16 10 6 8 -6Z" fill="${col}" stroke="${dark}" stroke-width="2.2" stroke-linejoin="round"/><path d="M-4 22v6M4 22v6M0 22v8" stroke="${dark}" stroke-width="1.4"/>`;
 // head turned left with beak
 w+=`<path d="M-6 -8C-8 -16 -4 -22 2 -22C6 -22 8 -18 6 -12L4 -8Z" fill="${col}" stroke="${dark}" stroke-width="2.2"/><path d="M-4 -20L-12 -17L-5 -14Z" fill="${col}" stroke="${dark}" stroke-width="1.8" stroke-linejoin="round"/><circle cx="-1" cy="-17" r="1.4" fill="${dark}"/>`;
 // talons
 w+=`<path d="M-8 14l-6 4M8 14l6 4" stroke="${dark}" stroke-width="2.4" stroke-linecap="round"/>`;
 return w;};
I.icon_seal=()=>{const c=128;let s=`<ellipse cx="${c+6}" cy="${c+10}" rx="98" ry="98" fill="#000" opacity=".35" filter="url(#blur8)"/>`;
 // wax blob edge
 const r=rng(4);let d='';const N=28;for(let i=0;i<=N;i++){const a=i/N*Math.PI*2,rr=100+(i%2?-6:4)+r()*5;d+=(i?'L':'M')+f(c+Math.cos(a)*rr)+' '+f(c+Math.sin(a)*rr);}
 s+=`<radialGradient id="sg" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#fff2b0"/><stop offset=".35" stop-color="#f0c450"/><stop offset=".75" stop-color="#c08a22"/><stop offset="1" stop-color="#7a5210"/></radialGradient>`;
 s+=`<path d="${d}Z" fill="url(#sg)" stroke="${INK}" stroke-width="4" stroke-linejoin="round"/>`;
 s+=`<circle cx="${c}" cy="${c}" r="80" fill="#c99628" stroke="#7a5210" stroke-width="3"/><circle cx="${c}" cy="${c}" r="80" fill="url(#sg)" opacity=".55"/><circle cx="${c}" cy="${c}" r="72" fill="none" stroke="#8a6214" stroke-width="2.4" stroke-dasharray="3 5"/><circle cx="${c}" cy="${c}" r="64" fill="#b8841e"/><circle cx="${c}" cy="${c}" r="64" fill="none" stroke="#fff0a8" stroke-width="2" opacity=".6" transform="translate(-1.5 -1.5)"/><circle cx="${c}" cy="${c}" r="64" fill="none" stroke="#6a4808" stroke-width="2.4"/>`;
 s+=`<g transform="translate(${c+2} ${c+4}) scale(1.75)" opacity=".6">${eagle('#6a4808','#6a4808')}</g><g transform="translate(${c} ${c+2}) scale(1.75)">${eagle('#f4cf62','#6a4808')}</g><g transform="translate(${c-1} ${c+1}) scale(1.75)" opacity=".5"><path d="M-12 -14c4 -4 8 -4 12 0" stroke="#fff8d0" stroke-width="2" fill="none"/></g>`;
 for(let i=0;i<5;i++){const a=-Math.PI/2+(i-2)*0.38;s+=`<path d="M${f(c+Math.cos(a)*58)} ${f(c+Math.sin(a)*58-2)}l2 4l4 1l-3 3l1 4l-4 -2l-4 2l1 -4l-3 -3l4 -1z" fill="#ffe890" stroke="#6a4808" stroke-width="1"/>`;}
 s+=`<path d="M60 90a80 80 0 0 1 60 -48" stroke="#fffbe0" stroke-width="7" fill="none" stroke-linecap="round" opacity=".7"/><circle cx="86" cy="64" r="5" fill="#fff"/>`;
 return s;};
I.icon_ticket=()=>{let s=`<g transform="translate(128 132) rotate(-12)">`;const w=200,h=118;
 const notch=`M${-w/2} ${-h/2}H${w/2}V-14a14 14 0 0 0 0 28V${h/2}H${-w/2}V14a14 14 0 0 0 0 -28Z`;
 s+=`<path d="${notch}" fill="#000" opacity=".35" transform="translate(6 10)" filter="url(#blur4)"/>`;
 s+=`<linearGradient id="tk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e05a48"/><stop offset=".55" stop-color="#c0392b"/><stop offset="1" stop-color="#8a2218"/></linearGradient>`;
 s+=`<path d="${notch}" fill="url(#tk)" stroke="${INK}" stroke-width="4" stroke-linejoin="round"/>`;
 s+=`<path d="M${-w/2+10} ${-h/2+10}H${w/2-10}V-16a16 16 0 0 0 0 32V${h/2-10}H${-w/2+10}V16a16 16 0 0 0 0 -32Z" fill="none" stroke="#f4d8a0" stroke-width="2" opacity=".7"/>`;
 s+=`<path d="M38 ${-h/2+6}V${h/2-6}" stroke="#f4d8a0" stroke-width="3" stroke-dasharray="5 6" opacity=".8"/>`;
 // lines of "text" (abstract bars)
 for(const [y,l] of [[-30,90],[-14,70],[2,84],[18,60],[34,76]])s+=`<rect x="${-w/2+24}" y="${y}" width="${l}" height="6" rx="3" fill="#7a1a10" opacity=".55"/>`;
 // gold star stamp
 let st='';for(let i=0;i<10;i++){const a=-Math.PI/2+i*Math.PI/5,rr=i%2?11:26;st+=(i?'L':'M')+f(Math.cos(a)*rr)+' '+f(Math.sin(a)*rr);}
 s+=`<g transform="translate(66 0) rotate(14)"><circle r="30" fill="#e0b04a" stroke="${INK}" stroke-width="3"/><circle r="30" fill="url(#sg2)"/><circle r="24" fill="none" stroke="#8a6214" stroke-width="1.6" stroke-dasharray="2 3"/><path d="${st}Z" fill="#fff0a0" stroke="#7a5210" stroke-width="2"/></g>`;
 s+=`<radialGradient id="sg2" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#fff2b0" stop-opacity=".8"/><stop offset=".6" stop-color="#e0b04a" stop-opacity="0"/><stop offset="1" stop-color="#7a5210" stop-opacity=".6"/></radialGradient>`;
 s+=`<path d="M${-w/2+8} ${-h/2+6}H${w/2-8}" stroke="#ffb8a8" stroke-width="3" opacity=".6" stroke-linecap="round"/></g>`;
 return s;};

// ---------- medals ----------
function medal(metal,ribbon,stripe){const M={bronze:['#f2c49a','#c07a42','#7a4420','#4a2810'],silver:['#ffffff','#c8d0da','#7a8492','#3a424e'],gold:['#fff4b8','#f0c040','#b07e18','#5a3e08']}[metal];
 let s=`<linearGradient id="rb" x1="0" x2="1"><stop offset="0" stop-color="${shade(ribbon,.2)}"/><stop offset=".5" stop-color="${ribbon}"/><stop offset="1" stop-color="${shade(ribbon,.35)}"/></linearGradient>`;
 s+=`<path d="M40 6H88L76 62H52Z" fill="url(#rb)" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/><path d="M58 6H70L66 62H62Z" fill="${stripe}"/><path d="M44 6H50L56 62H53Z" fill="${stripe}" opacity=".7"/><path d="M78 6H84L75 62H72Z" fill="${stripe}" opacity=".7"/><path d="M40 6H88L76 62H52Z" fill="none" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/>`;
 s+=`<rect x="54" y="56" width="20" height="10" rx="3" fill="${M[1]}" stroke="${INK}" stroke-width="2.4"/>`;
 s+=`<radialGradient id="md" cx=".35" cy=".3" r=".85"><stop offset="0" stop-color="${M[0]}"/><stop offset=".45" stop-color="${M[1]}"/><stop offset=".85" stop-color="${M[2]}"/><stop offset="1" stop-color="${M[3]}"/></radialGradient>`;
 s+=`<circle cx="66" cy="94" r="30" fill="#000" opacity=".3" filter="url(#blur2)"/><circle cx="64" cy="92" r="30" fill="url(#md)" stroke="${INK}" stroke-width="3"/><circle cx="64" cy="92" r="23" fill="none" stroke="${M[3]}" stroke-width="1.6" opacity=".7"/><circle cx="64" cy="92" r="23" fill="none" stroke="${M[0]}" stroke-width="1.2" opacity=".6" transform="translate(-1 -1)"/>`;
 let st='';for(let i=0;i<10;i++){const a=-Math.PI/2+i*Math.PI/5,rr=i%2?7.5:17;st+=(i?'L':'M')+f(64+Math.cos(a)*rr)+' '+f(93+Math.sin(a)*rr);}
 s+=`<path d="${st}Z" fill="${M[3]}" opacity=".5" transform="translate(1.5 1.5)"/><path d="${st}Z" fill="${M[1]}" stroke="${M[3]}" stroke-width="1.4"/><path d="${st}Z" fill="url(#md)" opacity=".6"/>`;
 s+=`<path d="M44 80a24 24 0 0 1 18 -12" stroke="#fff" stroke-width="3.4" fill="none" stroke-linecap="round" opacity=".85"/><circle cx="48" cy="76" r="2.4" fill="#fff"/>`;
 return s;}
I.medal_bronze=()=>medal('bronze','#2e7a3e','#e8d8a0');
I.medal_silver=()=>medal('silver','#2e5aa8','#e8eef8');
I.medal_gold=()=>medal('gold','#b8302a','#f4d070');

module.exports=I;
if(require.main===module){const only=process.argv[2];const sz={tile_owned:[512,512,1],tile_forsale:[512,512,1],tile_locked:[512,512,1],smoke_puff:[256,256,0],crate_basic:[512,512,0],crate_limited:[512,512,0],icon_seal:[256,256,0],icon_ticket:[256,256,0],medal_bronze:[128,128,0],medal_silver:[128,128,0],medal_gold:[128,128,0]};
 renderAll(Object.keys(I).filter(k=>!only||k.startsWith(only)).map(k=>({name:k,w:sz[k][0],h:sz[k][1],svg:I[k](),opaque:!!sz[k][2],grain:sz[k][2]?3:2})));}
