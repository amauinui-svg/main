// loading_bg 1920x1080: dark war room, map table, compass, candles, flags; empty dark centre for the title.
const L=require('./lib');const S=require('./scene');const {INK,f,mix,shade,light,rng,renderAll}=L;const {glow,vignette}=S;
const W=1920,H=1080;
const P=(d,fill,w=4,extra='')=>`<path d="${d}" fill="${fill}" stroke="${INK}" stroke-width="${w}" stroke-linejoin="round" stroke-linecap="round" ${extra}/>`;
function blob(cx,cy,r,seed,n=14,j=.35){const R=rng(seed);let pts=[];for(let i=0;i<n;i++){const a=i/n*Math.PI*2,rr=r*(1-j/2+R()*j);pts.push([cx+Math.cos(a)*rr*1.3,cy+Math.sin(a)*rr]);}
 let d=`M${f((pts[0][0]+pts[n-1][0])/2)} ${f((pts[0][1]+pts[n-1][1])/2)}`;for(let i=0;i<n;i++){const p=pts[i],q=pts[(i+1)%n];d+=`Q${f(p[0])} ${f(p[1])} ${f((p[0]+q[0])/2)} ${f((p[1]+q[1])/2)}`;}return d+'Z';}
function build(){let s='';
 // wall
 s+=`<linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2a080c"/><stop offset=".5" stop-color="#3e0e14"/><stop offset="1" stop-color="#1a0508"/></linearGradient><rect width="${W}" height="${H}" fill="url(#wall)"/>`;
 // damask pattern
 s+=`<pattern id="dam" width="120" height="160" patternUnits="userSpaceOnUse"><path d="M60 20C80 40 84 70 60 90C36 70 40 40 60 20Z M60 90C70 110 90 120 100 140C80 136 66 126 60 110C54 126 40 136 20 140C30 120 50 110 60 90Z" fill="#5a1a20" opacity=".55"/><circle cx="0" cy="80" r="6" fill="#5a1a20" opacity=".5"/><circle cx="120" cy="80" r="6" fill="#5a1a20" opacity=".5"/></pattern><rect width="${W}" height="680" fill="url(#dam)"/>`;
 // gold wall panels / molding
 for(const [x,w] of [[120,380],[1420,380]])s+=`<rect x="${x}" y="120" width="${w}" height="420" rx="8" fill="none" stroke="#7a5a1a" stroke-width="10"/><rect x="${x}" y="120" width="${w}" height="420" rx="8" fill="none" stroke="#d8a640" stroke-width="3" opacity=".7"/><rect x="${x+20}" y="140" width="${w-40}" height="380" rx="6" fill="#000" opacity=".15"/>`;
 s+=`<rect x="0" y="40" width="${W}" height="16" fill="#5a3a10"/><rect x="0" y="40" width="${W}" height="4" fill="#e8b850" opacity=".6"/><rect x="0" y="600" width="${W}" height="24" fill="#4a2a0c"/><rect x="0" y="600" width="${W}" height="5" fill="#d8a640" opacity=".6"/>`;
 // framed world map on the back wall left & right? keep centre empty: framed portraits silhouettes in side panels
 for(const cx of[310,1610]){s+=`<rect x="${cx-120}" y="190" width="240" height="280" rx="6" fill="#140608" stroke="#c9a640" stroke-width="10"/><rect x="${cx-120}" y="190" width="240" height="280" rx="6" fill="none" stroke="${INK}" stroke-width="3"/>`;
  // map of a continent in frame
  s+=`<rect x="${cx-104}" y="206" width="208" height="248" fill="#6a5434"/><path d="${blob(cx-10,320,60,cx)}" fill="#8a7448" stroke="#3a2a14" stroke-width="2"/><path d="${blob(cx+50,400,26,cx+3)}" fill="#8a7448" stroke="#3a2a14" stroke-width="2"/><path d="M${cx-90} 260h180M${cx-90} 320h180M${cx-90} 380h180M${cx-40} 210v240M${cx+30} 210v240" stroke="#3a2a14" stroke-width="1" opacity=".4"/><rect x="${cx-104}" y="206" width="208" height="248" fill="#000" opacity=".35"/>`;}
 // hanging banners
 const banner=(x,col)=>{let o=`<rect x="${x-80}" y="36" width="160" height="12" rx="6" fill="#c9a640" stroke="${INK}" stroke-width="3"/>`;
  const d=`M${x-70} 48H${x+70}V520L${x} 470L${x-70} 520Z`;o+=P(d,col,4)+`<path d="M${x+20} 48H${x+70}V520L${x+40} 495Z" fill="#000" opacity=".25"/><path d="M${x-60} 48V500" stroke="#fff" stroke-width="3" opacity=".12"/>`;
  o+=`<path d="M${x-58} 60H${x+58}V500L${x} 456L${x-58} 500Z" fill="none" stroke="#d8a640" stroke-width="4"/>`;
  // emblem: laurel + star
  o+=`<circle cx="${x}" cy="230" r="44" fill="none" stroke="#d8a640" stroke-width="5"/>`;let st='';for(let i=0;i<10;i++){const a=-Math.PI/2+i*Math.PI/5,r=i%2?14:34;st+=(i?'L':'M')+f(x+Math.cos(a)*r)+' '+f(230+Math.sin(a)*r);}o+=`<path d="${st}Z" fill="#e8b850" stroke="${INK}" stroke-width="2.4"/>`;
  for(let i=0;i<6;i++){o+=`<ellipse cx="${x-50+i*2}" cy="${300+i*-12}" rx="5" ry="10" fill="#d8a640" transform="rotate(${-30+i*8} ${x-50+i*2} ${300+i*-12})"/><ellipse cx="${x+50-i*2}" cy="${300+i*-12}" rx="5" ry="10" fill="#d8a640" transform="rotate(${30-i*8} ${x+50-i*2} ${300+i*-12})"/>`;}
  o+=`<path d="M${x-50} 160h100M${x-50} 370h100" stroke="#d8a640" stroke-width="3" opacity=".7"/>`;
  // tassels
  for(const tx of[x-70,x+70])o+=`<path d="M${tx} 520v40" stroke="#c9a640" stroke-width="3"/><path d="M${tx-6} 560h12l4 26h-20z" fill="#c9a640" stroke="${INK}" stroke-width="2"/>`;
  return o;};
 s+=banner(680,'#8a1820')+banner(1240,'#8a1820');
 // table: perspective-ish top + front edge
 const ty=690;
 s+=`<path d="M60 ${ty}H${W-60}L${W+80} ${H}H-80Z" fill="#3a2010"/>`;
 s+=`<path d="M60 ${ty}H${W-60}L${W+80} ${H}H-80Z" fill="url(#grain)" opacity=".5"/>`;
 // green baize inlay + map
 s+=`<path d="M140 ${ty+24}H${W-140}L${W-20} ${H-20}H20Z" fill="#1e3a2a" stroke="#c9a640" stroke-width="4"/>`;
 // map parchment (tilted rectangle)
 const mx0=330,mx1=1590,my0=ty+50,my1=H-40;
 const md=`M${mx0} ${my0}H${mx1}L${mx1+70} ${my1}H${mx0-70}Z`;
 s+=`<linearGradient id="parch" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#d8c08a"/><stop offset=".5" stop-color="#c8aa72"/><stop offset="1" stop-color="#a88a52"/></linearGradient>`;
 s+=`<clipPath id="mp"><path d="${md}"/></clipPath><path d="${md}" fill="url(#parch)"/><g clip-path="url(#mp)">`;
 // stains
 const r=rng(5);for(let i=0;i<14;i++)s+=`<ellipse cx="${f(mx0+r()*(mx1-mx0))}" cy="${f(my0+r()*(my1-my0))}" rx="${f(30+r()*80)}" ry="${f(14+r()*30)}" fill="#7a5a2a" opacity="${f(.08+r()*.1)}"/>`;
 // sea tint + continents (squashed for table perspective)
 s+=`<g transform="translate(0 ${my0}) scale(1 .5) translate(0 ${-my0})">`;
 const conts=[[560,my0+150,110,1],[820,my0+300,80,2],[1080,my0+170,140,3],[1360,my0+330,90,4],[1240,my0+520,60,5],[700,my0+520,70,6]];
 for(const [cx,cy,rr,sd] of conts){s+=`<path d="${blob(cx,cy,rr,sd,16,.45)}" fill="#e2cc96" stroke="#5a3a1a" stroke-width="4"/><path d="${blob(cx,cy,rr*0.8,sd+20,14,.3)}" fill="#bfa86a" opacity=".45"/>`;}
 // territories borders dashed + coloured
 s+=`<path d="${blob(1080,my0+170,90,33,12,.3)}" fill="#b8302a" opacity=".28" stroke="#8a1a14" stroke-width="3" stroke-dasharray="10 8"/><path d="${blob(560,my0+150,70,34,12,.3)}" fill="#2e5aa8" opacity=".25" stroke="#1a3a7a" stroke-width="3" stroke-dasharray="10 8"/>`;
 // grid
 for(let x=mx0-60;x<mx1+80;x+=90)s+=`<path d="M${x} ${my0}V${my0+2*(my1-my0)}" stroke="#5a3a1a" stroke-width="1.6" opacity=".3"/>`;for(let y=my0;y<my0+2*(my1-my0);y+=90)s+=`<path d="M${mx0-80} ${y}H${mx1+80}" stroke="#5a3a1a" stroke-width="1.6" opacity=".3"/>`;
 // campaign arrows
 s+=`<path d="M640 ${my0+170}C760 ${my0+90} 900 ${my0+100} 1000 ${my0+160}" stroke="#2e5aa8" stroke-width="9" fill="none" stroke-linecap="round"/><path d="M1000 ${my0+160}l-34 -6l18 -24z" fill="#2e5aa8"/>`;
 s+=`<path d="M1180 ${my0+260}C1240 ${my0+360} 1300 ${my0+380} 1340 ${my0+300}" stroke="#b8302a" stroke-width="9" fill="none" stroke-linecap="round"/><path d="M1340 ${my0+300}l-6 34l-26 -16z" fill="#b8302a"/>`;
 // printed compass rose
 { const cx=1470,cy=my0+120;s+=`<circle cx="${cx}" cy="${cy}" r="60" fill="none" stroke="#5a3a1a" stroke-width="3"/><path d="M${cx} ${cy-80}L${cx+12} ${cy}L${cx} ${cy+80}L${cx-12} ${cy}Z M${cx-80} ${cy}L${cx} ${cy-12}L${cx+80} ${cy}L${cx} ${cy+12}Z" fill="#5a3a1a" opacity=".7"/>`;}
 s+=`</g>`;
 s+=`</g><path d="${md}" fill="none" stroke="#5a3a1a" stroke-width="4"/><path d="${md}" fill="url(#aoV)" opacity=".4"/>`;
 // map pieces (army figurines)
 const pawn=(x,y,col,sc=1)=>`<ellipse cx="${x+4}" cy="${y+3}" rx="${16*sc}" ry="${6*sc}" fill="#000" opacity=".45" filter="url(#blur2)"/>`+P(`M${x-14*sc} ${y}h${28*sc}l-4 ${-8*sc}h${-20*sc}z`,shade(col,.1),2.6)+P(`M${x-8*sc} ${y-8*sc}l3 ${-22*sc}h${10*sc}l3 ${22*sc}z`,col,2.6)+`<circle cx="${x}" cy="${y-36*sc}" r="${9*sc}" fill="${col}" stroke="${INK}" stroke-width="2.6"/><circle cx="${x-3*sc}" cy="${y-39*sc}" r="${3*sc}" fill="#fff" opacity=".6"/>`;
 s+=pawn(1080,ty+150,'#b8302a',1.2)+pawn(1120,ty+170,'#b8302a',1.2)+pawn(1300,ty+260,'#b8302a',1.3)+pawn(640,ty+150,'#2e5aa8',1.2)+pawn(600,ty+175,'#2e5aa8',1.2)+pawn(860,ty+250,'#2e5aa8',1.3);
 // little flags pinned in the map
 const pin=(x,y,col)=>`<path d="M${x} ${y}V${y-60}" stroke="${INK}" stroke-width="4"/><path d="M${x} ${y}V${y-60}" stroke="#c9a640" stroke-width="2"/>`+P(`M${x+1} ${y-60}l34 9l-34 9z`,col,2.4);
 s+=pin(1010,ty+130,'#b8302a')+pin(700,ty+120,'#2e5aa8')+pin(1380,ty+300,'#b8302a');
 // brass compass (open) bottom-left
 { const cx=330,cy=H-110;s+=`<ellipse cx="${cx+10}" cy="${cy+20}" rx="130" ry="52" fill="#000" opacity=".5" filter="url(#blur8)"/>`;
  s+=`<ellipse cx="${cx}" cy="${cy}" rx="120" ry="58" fill="url(#brassH)" stroke="${INK}" stroke-width="5"/><ellipse cx="${cx}" cy="${cy-6}" rx="104" ry="48" fill="#f0e6c8" stroke="#6a4410" stroke-width="4"/>`;
  for(let i=0;i<16;i++){const a=i/16*Math.PI*2;s+=`<path d="M${f(cx+Math.cos(a)*92)} ${f(cy-6+Math.sin(a)*42)}L${f(cx+Math.cos(a)*(i%4?98:84))} ${f(cy-6+Math.sin(a)*(i%4?45:38))}" stroke="#3a2a14" stroke-width="${i%4?2:4}"/>`;}
  s+=`<path d="M${cx-70} ${cy+12}L${cx+6} ${cy-10}L${cx+70} ${cy-24}L${cx-4} ${cy-2}Z" fill="#b8302a" stroke="${INK}" stroke-width="2.4"/><path d="M${cx-4} ${cy-2}L${cx+70} ${cy-24}L${cx+6} ${cy-10}Z" fill="#2a2a30"/><circle cx="${cx}" cy="${cy-6}" r="8" fill="url(#brassH)" stroke="${INK}" stroke-width="2.4"/>`;
  s+=`<path d="M${cx-90} ${cy-30}A100 44 0 0 1 ${cx+30} ${cy-52}" stroke="#fff" stroke-width="6" opacity=".5" fill="none" stroke-linecap="round"/>`;
  // lid hinge + open lid behind
  s+=`<ellipse cx="${cx+40}" cy="${cy-118}" rx="96" ry="60" fill="url(#brassH)" stroke="${INK}" stroke-width="5" transform="rotate(-18 ${cx+40} ${cy-118})"/><ellipse cx="${cx+40}" cy="${cy-118}" rx="78" ry="46" fill="#5a3a10" stroke="#3a240a" stroke-width="3" transform="rotate(-18 ${cx+40} ${cy-118})"/><path d="M${cx+30} ${cy-140}l12 -8l12 8l-12 30z" fill="#d8a640" opacity=".7"/>`;}
 // quill + inkwell bottom-right
 { const cx=1600,cy=H-120;s+=`<ellipse cx="${cx+8}" cy="${cy+40}" rx="70" ry="22" fill="#000" opacity=".5" filter="url(#blur4)"/>`+P(`M${cx-48} ${cy+40}V${cy-10}Q${cx} ${cy-34} ${cx+48} ${cy-10}V${cy+40}Q${cx} ${cy+58} ${cx-48} ${cy+40}Z`,'#1e2430',5)+`<path d="M${cx-36} ${cy-6}V${cy+36}" stroke="#fff" stroke-width="5" opacity=".25"/>`+P(`M${cx-20} ${cy-22}h40v-20h-40z`,'url(#brassH)',4)+`<ellipse cx="${cx}" cy="${cy-42}" rx="20" ry="6" fill="#0a0a10" stroke="${INK}" stroke-width="3"/>`;
  s+=`<path d="M${cx+4} ${cy-44}L${cx+150} ${cy-330}" stroke="${INK}" stroke-width="6"/>`+P(`M${cx+40} ${cy-110}C${cx+90} ${cy-260} ${cx+150} ${cy-340} ${cx+190} ${cy-360}C${cx+180} ${cy-300} ${cx+130} ${cy-200} ${cx+60} ${cy-100}Z`,'#ece6da',3.4)+`<path d="M${cx+50} ${cy-106}L${cx+186} ${cy-356}" stroke="#a89a88" stroke-width="2.4"/>`;
  for(let i=0;i<10;i++){const t=i/10;s+=`<path d="M${f(cx+56+t*120)} ${f(cy-120-t*220)}l${f(22-t*10)} ${f(10-t*4)}" stroke="#b8b0a0" stroke-width="1.6"/>`;}}
 // scroll rolled on the right
 s+=`<g transform="rotate(-8 1700 760)">`+P(`M1620 740h200v44h-200z`,'#d8c08a',4)+`<ellipse cx="1620" cy="762" rx="12" ry="22" fill="#c8aa72" stroke="${INK}" stroke-width="4"/><ellipse cx="1820" cy="762" rx="12" ry="22" fill="#e8d8a8" stroke="${INK}" stroke-width="4"/><ellipse cx="1820" cy="762" rx="5" ry="10" fill="#8a6a3a"/><path d="M1700 740v44" stroke="#8a1820" stroke-width="10"/><circle cx="1700" cy="786" r="10" fill="#b8302a" stroke="${INK}" stroke-width="2.4"/></g>`;
 // dagger pinning the map
 s+=`<g transform="rotate(28 1240 ${ty+90})">`+P(`M1232 ${ty+90}V${ty-10}h16V${ty+90}l-8 22z`,'url(#steelH)',3.4)+P(`M1210 ${ty-14}h60v12h-60z`,'url(#brassH)',3.4)+P(`M1232 ${ty-14}v-60h16v60z`,'#3a2414',3.4)+`<circle cx="1240" cy="${ty-80}" r="11" fill="url(#brassH)" stroke="${INK}" stroke-width="3"/></g>`;
 // candles
 const candle=(x,base,h)=>{let o=glow(x,base-h-30,360,'#ffb050',.38)+glow(x,base-h-30,90,'#ffe0a0',.7);
  o+=`<ellipse cx="${x+6}" cy="${base+6}" rx="70" ry="18" fill="#000" opacity=".5" filter="url(#blur4)"/>`+P(`M${x-60} ${base}Q${x} ${base+22} ${x+60} ${base}L${x+44} ${base-14}H${x-44}Z`,'url(#brassH)',4)+P(`M${x-10} ${base-14}V${base-40}h20V${base-14}Z`,'url(#brassH)',3.4)+P(`M${x-34} ${base-40}h68l-8 -12h-52z`,'url(#brassH)',3.4);
  o+=P(`M${x-22} ${base-52}V${base-h}Q${x} ${base-h-8} ${x+22} ${base-h}V${base-52}Z`,'#efe4cc',4)+`<path d="M${x+8} ${base-h+2}V${base-52}" stroke="#000" stroke-width="10" opacity=".12"/><path d="M${x-12} ${base-h+4}v30q-4 10 0 22" stroke="#fffaf0" stroke-width="5" fill="none" opacity=".6"/>`+P(`M${x+10} ${base-h+2}q4 20 -2 30q-6 -8 -4 -30z`,'#f4ead4',2.4);
  o+=`<path d="M${x} ${base-h-4}v-8" stroke="#2a1a10" stroke-width="3"/><path d="M${x} ${base-h-58}C${x+16} ${base-h-34} ${x+12} ${base-h-12} ${x} ${base-h-10}C${x-12} ${base-h-12} ${x-16} ${base-h-34} ${x} ${base-h-58}Z" fill="#ffb040"/><path d="M${x} ${base-h-44}C${x+8} ${base-h-30} ${x+6} ${base-h-16} ${x} ${base-h-14}C${x-6} ${base-h-16} ${x-8} ${base-h-30} ${x} ${base-h-44}Z" fill="#fff6c8"/>`;return o;};
 s+=candle(200,ty+70,170)+candle(1720,ty+60,200);
 // standing flags at the edges (draped)
 const sflag=(x,col,dir)=>{let o=`<path d="M${x} ${H}V120" stroke="${INK}" stroke-width="12"/><path d="M${x} ${H}V120" stroke="#6a4420" stroke-width="7"/><circle cx="${x}" cy="110" r="14" fill="url(#brassH)" stroke="${INK}" stroke-width="3"/>`;
  const d=`M${x} 140C${x+dir*80} 150 ${x+dir*150} 140 ${x+dir*200} 170C${x+dir*190} 260 ${x+dir*160} 360 ${x+dir*120} 470C${x+dir*80} 440 ${x+dir*40} 430 ${x} 440Z`;
  o+=P(d,col,4)+`<path d="M${x+dir*60} 150C${x+dir*70} 260 ${x+dir*60} 360 ${x+dir*50} 436" stroke="#000" stroke-width="16" opacity=".22" fill="none"/><path d="M${x+dir*130} 160C${x+dir*140} 260 ${x+dir*120} 380 ${x+dir*100} 460" stroke="#000" stroke-width="12" opacity=".18" fill="none"/><path d="M${x+dir*20} 150C${x+dir*28} 250 ${x+dir*24} 340 ${x+dir*16} 430" stroke="#fff" stroke-width="5" opacity=".15" fill="none"/>`;
  o+=`<path d="M${x} 180C${x+dir*80} 190 ${x+dir*140} 184 ${x+dir*186} 206" stroke="#d8a640" stroke-width="5" fill="none"/>`;return o;};
 s+=sflag(60,'#8a1820',1)+sflag(W-60,'#7a1420',-1);
 // dust motes
 { const r=rng(9);let o='';for(let i=0;i<70;i++)o+=`<circle cx="${f(r()*W)}" cy="${f(r()*700)}" r="${f(1+r()*2.4)}" fill="#ffd890" opacity="${f(.15+r()*.4)}"/>`;s+=`<g filter="url(#blur2)">${o}</g>`;}
 // darken centre zone for the title + vignette
 s+=`<radialGradient id="cz" cx=".5" cy=".38" r=".38"><stop offset="0" stop-color="#000" stop-opacity=".55"/><stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient><rect width="${W}" height="${H}" fill="url(#cz)"/>`+vignette(W,H,.7);
 return s;}
if(require.main===module)renderAll([{name:'loading_bg',w:W,h:H,svg:build(),opaque:true,grain:0}]);
