// takedown_bg (1600x520) + enemy_guard / enemy_soldier / enemy_general (400x600, facing left)
const L=require('./lib');const S=require('./scene');const {INK,f,mix,shade,light,rng,renderAll}=L;
const {sky,glow,stars,cloud,ridge,haze,bld,wins,dome,spire,treeRound,cypress,pine,ink,vignette}=S;
const T={};const W=1600,H=520;
const P=(d,fill,w=4)=>`<path d="${d}" fill="${fill}" stroke="${INK}" stroke-width="${w}" stroke-linejoin="round" stroke-linecap="round"/>`;
// shaded part: base path + shadow path (clipped) + highlight path (clipped)
let cid=0;const part=(d,fill,{sh=null,hl=null,w=4,shc=null,hlc=null}={})=>{const id='pc'+(++cid);let s=`<clipPath id="${id}"><path d="${d}"/></clipPath><path d="${d}" fill="${fill}"/><g clip-path="url(#${id})">`;if(sh)s+=`<path d="${sh}" fill="${shc||shade(fill,.4)}" opacity=".85"/>`;if(hl)s+=`<path d="${hl}" fill="${hlc||light(fill,.3)}" opacity=".8"/>`;s+=`</g><path d="${d}" fill="none" stroke="${INK}" stroke-width="${w}" stroke-linejoin="round" stroke-linecap="round"/>`;return s;};

// ================= background =================
T.takedown_bg=()=>{let s='';
 s+=sky(W,H,[[0,'#060a1c'],[.35,'#121a3a'],[.55,'#26304e'],[.6,'#3a3448']]);
 s+=stars(W,H,150,12,220)+glow(1300,80,140,'#c8d4ff',.3)+`<circle cx="1300" cy="80" r="30" fill="#e8ecff"/><circle cx="1290" cy="72" r="6" fill="#cfd6ee"/><circle cx="1312" cy="90" r="4" fill="#d6dcf2"/>`;
 s+=cloud(200,110,320,{col:'#232c4c',sh:'#11162c',lit:'#3a4670',op:.8})+cloud(980,140,360,{col:'#232c4c',sh:'#11162c',lit:'#46527a',op:.7});
 // palace beyond the wall
 const pc=800;
 s+=bld(pc-330,250,200,90,{fill:'#4a4652',tex:'block',d:24,sw:2.4,roof:'hip',roofFill:'#2a2e3a',roofTex:'slate',rh:30,rimCol:'#8a9ac8',rimOp:.4,wins:{cols:6,rows:2,ww:10,wh:18,padT:14,padB:12,lit:.7,seed:3,arch:true}});
 s+=bld(pc+130,250,200,90,{fill:'#4a4652',tex:'block',d:24,sw:2.4,roof:'hip',roofFill:'#2a2e3a',roofTex:'slate',rh:30,rimCol:'#8a9ac8',rimOp:.4,wins:{cols:6,rows:2,ww:10,wh:18,padT:14,padB:12,lit:.7,seed:4,arch:true}});
 s+=bld(pc-140,250,280,140,{fill:'#55505e',tex:'block',d:30,sw:2.4,roof:'flat',topFill:'#3a3644',rimCol:'#8a9ac8',rimOp:.4,wins:{cols:7,rows:3,ww:12,wh:20,padT:14,padB:14,lit:.75,seed:5,arch:true,mull:true}});
 s+=bld(pc-40,110,80,40,{fill:'#55505e',d:16,roof:'none',rimCol:'#8a9ac8',rimOp:.4,wins:{cols:3,rows:1,ww:8,wh:16,padT:10,lit:1,seed:2,arch:true}})+dome(pc+8,70,58,'#3a4a5a',{h:60,ribs:5});
 s+=`<path d="M${pc+8} 0v12" stroke="${INK}" stroke-width="3"/>`;
 // banners on palace
 for(const x of[pc-110,pc+80])s+=P(`M${x} 120h30v70l-15 -10l-15 10z`,'#8a1f24',2.4)+`<circle cx="${x+15}" cy="${148}" r="7" fill="none" stroke="#d8a640" stroke-width="2"/>`;
 // trees behind wall
 for(const [x,y,sc] of [[80,300,40],[200,290,46],[330,300,36],[1270,300,40],[1400,292,48],[1530,300,38]])s+=treeRound(x,y,sc*0.6,'#1e3028',{lit:'#2e4a3e',trunk:'#1a120c'});
 s+=haze(W,180,300,'#3a3448',.35);
 // fortified wall
 const wy=330;
 s+=`<rect x="0" y="${wy-80}" width="${W}" height="80" fill="#5a5560"/><rect x="0" y="${wy-80}" width="${W}" height="80" fill="url(#block)" opacity=".8"/><rect x="0" y="${wy-80}" width="${W}" height="80" fill="url(#aoV)"/><path d="M0 ${wy-80}H${W}" stroke="${INK}" stroke-width="3"/>`;
 for(let x=0;x<W;x+=40)s+=`<rect x="${x}" y="${wy-100}" width="22" height="22" fill="#5a5560" stroke="${INK}" stroke-width="2.4"/><rect x="${x}" y="${wy-100}" width="22" height="5" fill="#8a8494"/>`;
 // gate towers
 const tower=(x,w,h)=>bld(x,wy,w,h,{fill:'#625c6a',tex:'block',d:22,sw:3,cren:14,rimCol:'#9aa6d8',rimOp:.45,wins:{cols:1,rows:2,ww:10,wh:22,padT:30,padB:60,lit:.9,seed:Math.round(x),arch:true}});
 s+=tower(560,110,210)+tower(930,110,210);
 // gate arch block
 s+=bld(670,wy,260,170,{fill:'#5e5866',tex:'block',d:0,sw:3,cren:16,rimCol:'#9aa6d8',rimOp:.45,content:(X,t,w,h)=>{let q=`<path d="M${X+40} ${t+h}V${t+80}A90 90 0 0 1 ${X+w-40} ${t+80}V${t+h}Z" fill="#0c0c14" stroke="${INK}" stroke-width="3"/>`;
  q+=`<path d="M${X+28} ${t+80}A102 102 0 0 1 ${X+w-28} ${t+80}" fill="none" stroke="#8a8494" stroke-width="10"/><path d="M${X+28} ${t+80}A102 102 0 0 1 ${X+w-28} ${t+80}" fill="none" stroke="${INK}" stroke-width="2"/>`;
  q+=glow(X+w/2,t+110,120,'#ffb050',.35);
  // iron gate bars
  for(let i=0;i<12;i++){const x=X+48+i*(w-96)/11;q+=`<path d="M${f(x)} ${t+h}V${t+40}" stroke="#08080c" stroke-width="7"/><path d="M${f(x)} ${t+h}V${t+40}" stroke="#3a3a46" stroke-width="3"/><path d="M${f(x-5)} ${t+44}L${f(x)} ${t+30}L${f(x+5)} ${t+44}Z" fill="#3a3a46" stroke="#08080c" stroke-width="2"/>`;}
  for(const y of[t+70,t+110,t+150])q+=`<path d="M${X+44} ${y}H${X+w-44}" stroke="#08080c" stroke-width="8"/><path d="M${X+44} ${y}H${X+w-44}" stroke="#4a4a58" stroke-width="3"/>`;
  q+=`<circle cx="${X+w/2}" cy="${t+110}" r="22" fill="none" stroke="#08080c" stroke-width="9"/><circle cx="${X+w/2}" cy="${t+110}" r="22" fill="none" stroke="#c9a640" stroke-width="4"/><path d="M${X+w/2} ${t+92}l6 12h-12z" fill="#c9a640"/>`;
  return q;}});
 // crest above gate
 s+=P(`M780 176h40l-4 34l-16 10l-16 -10z`,'#8a1f24',2.6)+`<path d="M792 188l8 -6l8 6l-8 14z" fill="#d8a640"/>`;
 // stone pillars with lanterns flanking (front)
 const pillar=(x)=>{let q=bld(x,wy+30,54,140,{fill:'#7a7482',tex:'block',d:16,sw:3,rimCol:'#ffd890',rimOp:.6,roof:'flat',topFill:'#8a8494'});q+=bld(x-6,wy-110,66,12,{fill:'#8a8494',d:18,sw:2.6,shadow:false});
  q+=glow(x+30,wy-150,90,'#ffb050',.55)+`<path d="M${x+30} ${wy-122}v-8" stroke="${INK}" stroke-width="4"/>`+P(`M${x+14} ${wy-130}h32l-4 -40h-24z`,'#2a2a30',3)+`<rect x="${x+20}" y="${wy-164}" width="20" height="30" fill="#ffd36b"/><rect x="${x+24}" y="${wy-160}" width="12" height="22" fill="#fff6c0"/>`+P(`M${x+10} ${wy-170}h40l-20 -14z`,'#2a2a30',3)+`<circle cx="${x+30}" cy="${wy-188}" r="4" fill="#2a2a30" stroke="${INK}" stroke-width="2"/>`;return q;};
 s+=pillar(470)+pillar(1080);
 // trees in front corners
 s+=pine(60,390,180,'#1a2e26')+pine(150,370,140,'#1e3428')+pine(1460,384,170,'#1a2e26')+pine(1550,396,190,'#1e3428');
 // courtyard ground (perspective cobbles)
 s+=`<rect x="0" y="${wy}" width="${W}" height="${H-wy}" fill="#2e2c34"/>`;
 { const r=rng(7);let o='';let y=wy+3;let rowH=6;let row=0;while(y<H){const cw=rowH*2.2;for(let x=-(row%2)*cw/2;x<W;x+=cw){const c=mix('#34323a','#46434e',r());o+=`<rect x="${f(x+1)}" y="${f(y+0.5)}" width="${f(cw-2)}" height="${f(rowH-1)}" rx="${f(rowH*0.35)}" fill="${c}"/><rect x="${f(x+2)}" y="${f(y+1)}" width="${f(cw*0.6)}" height="${f(rowH*0.25)}" rx="2" fill="#7a7688" opacity=".2"/>`;}y+=rowH;rowH*=1.12;row++;}s+=o;}
 s+=`<rect x="0" y="${wy}" width="${W}" height="40" fill="url(#fadeDown)" opacity=".0"/>`;
 // light pools
 s+=`<ellipse cx="500" cy="${wy+40}" rx="160" ry="40" fill="#ffb050" opacity=".22" filter="url(#blur16)"/><ellipse cx="1110" cy="${wy+40}" rx="160" ry="40" fill="#ffb050" opacity=".22" filter="url(#blur16)"/><ellipse cx="800" cy="${wy+20}" rx="200" ry="30" fill="#ffb050" opacity=".18" filter="url(#blur16)"/>`;
 // wall base shadow line
 s+=`<rect x="0" y="${wy}" width="${W}" height="10" fill="#000" opacity=".35" filter="url(#blur4)"/>`;
 // moonlight cool wash and vignette
 s+=`<rect width="${W}" height="${H}" fill="#1a2a5a" opacity=".12"/>`+vignette(W,H,.55);
 return s;};

// ================= characters (400x600, face left) =================
const skin='#e0b08a',skinD='#b07a58';
const shadowG=(cx=200,cy=576,rx=120)=>`<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="18" fill="#000" opacity=".45" filter="url(#blur4)"/>`;
const head=(cx,cy,{mus=false,scar=false,brow='#2a1a10',jaw=1}={})=>{let s='';
 // ear (right side, visible)
 s+=part(`M${cx+30} ${cy-4}c12 -6 18 4 14 18c-2 10 -10 14 -16 10z`,skin,{sh:`M${cx+34} ${cy+2}h20v30h-20z`,w:3.4});
 // face facing left with nose bump
 const d=`M${cx+34} ${cy-30}C${cx+38} ${cy+10} ${cx+30} ${cy+44*jaw} ${cx+4} ${cy+50*jaw}C${cx-14} ${cy+52*jaw} ${cx-26} ${cy+42} ${cx-30} ${cy+30}L${cx-34} ${cy+22}L${cx-32} ${cy+16}L${cx-38} ${cy+12}L${cx-40} ${cy+4}L${cx-32} ${cy-2}C${cx-36} ${cy-20} ${cx-30} ${cy-34} ${cx-20} ${cy-40}Z`;
 s+=part(d,skin,{sh:`M${cx+6} ${cy-40}C${cx+40} ${cy-30} ${cx+40} ${cy+30} ${cx+10} ${cy+56}H${cx+60}V${cy-50}Z`,hl:`M${cx-30} ${cy-30}C${cx-36} ${cy-10} ${cx-34} ${cy} ${cx-28} ${cy+4}L${cx-22} ${cy-30}Z`,w:3.6});
 // eye + angry brow
 s+=`<path d="M${cx-24} ${cy-8}l20 6" stroke="${brow}" stroke-width="5" stroke-linecap="round"/><ellipse cx="${cx-14}" cy="${cy+3}" rx="4" ry="4.6" fill="#1a1a1a"/><circle cx="${cx-15}" cy="${cy+1.5}" r="1.3" fill="#fff"/>`;
 s+=`<path d="M${cx-26} ${cy+30}q8 -3 14 0" stroke="${INK}" stroke-width="2.6" fill="none"/>`;
 if(mus)s+=P(`M${cx-34} ${cy+22}q10 -8 22 -2q8 -6 16 4q-8 8 -16 2q-10 8 -22 -4z`,'#3a2414',2.4);
 if(scar)s+=`<path d="M${cx-6} ${cy-14}l8 22" stroke="#9a4a3a" stroke-width="2.4"/>`;
 return s;};

T.enemy_guard=()=>{let s=shadowG(200,578,120);const coat='#2c3140',coatD='#1a1e28';
 // legs / boots
 s+=part('M150 470L146 560H104Q96 570 104 578H176L180 470Z','#18181c',{hl:'M150 470L148 560H158L160 470Z',hlc:'#4a4a56'});
 s+=part('M220 470L224 562H212Q204 572 212 578H284L278 560L262 470Z','#18181c',{hl:'M226 470L228 560H238L236 470Z',hlc:'#4a4a56'});
 // long coat
 const cd='M130 180C116 240 112 330 106 400L96 490C150 504 250 504 304 490L290 400C286 330 282 240 270 180C240 166 160 166 130 180Z';
 s+=part(cd,coat,{sh:'M226 176C262 190 280 260 286 400L300 490H230C236 400 236 260 226 176Z',hl:'M134 186C122 250 118 330 112 410L124 410C128 330 134 250 146 186Z',shc:coatD});
 s+=`<path d="M190 300L180 492" stroke="${INK}" stroke-width="3"/><path d="M150 420L140 488M250 420L262 488" stroke="${coatD}" stroke-width="3" opacity=".8"/>`;
 // belt
 s+=part('M112 330C170 344 240 344 286 330L288 352C240 366 170 366 110 352Z','#3a2414',{w:3.6})+P('M170 336h22v22h-22z','#c9a640',3);
 for(const y of[230,264,380,410])s+=`<circle cx="${y>350?186:192}" cy="${y}" r="5" fill="#c9a640" stroke="${INK}" stroke-width="2"/>`;
 // upper arms
 s+=part('M128 186C104 210 100 250 108 300L150 300C150 260 152 220 156 190Z',coat,{sh:'M136 186h30v120h-30z',shc:coatD});
 s+=part('M270 186C296 210 302 250 294 300L250 300C250 260 250 220 246 190Z',coat,{sh:'M262 186h50v120h-50z',shc:coatD});
 // crossed forearms
 s+=part('M110 286C150 300 230 300 290 282L292 312C230 330 150 330 108 316Z',coat,{sh:'M100 306H300V340H100Z',shc:coatD});
 s+=part('M296 264C250 270 180 286 120 290L118 318C180 316 250 300 300 294Z',shade(coat,.05),{sh:'M100 306H310V330H100Z',shc:coatD,hl:'M120 290C180 286 250 270 296 264L296 270C250 276 180 292 122 296Z',hlc:'#4a5266'});
 s+=part('M96 290c-12 2 -16 18 -6 26c8 6 22 2 26 -8z','#2a2a30',{w:3.4})+part('M296 262c14 -2 22 14 12 24c-8 8 -22 4 -24 -6z','#2a2a30',{w:3.4});
 // epaulettes / shoulder boards
 s+=P('M124 182l40 -6l2 14l-40 8z','#5a1a1e',3)+P('M276 182l-40 -6l-2 14l40 8z','#3a1012',3);
 // collar (turned up)
 s+=part('M154 166L200 180L246 166L254 194L200 212L146 194Z',coat,{sh:'M200 170L254 160V200L200 214Z',shc:coatD});
 // head + cap
 s+=head(198,124,{mus:true});
 s+=part('M150 92C148 60 186 44 214 46C246 48 266 62 262 92Z','#22262f',{sh:'M222 46C252 54 266 70 262 92H226Z',hl:'M156 90C156 70 172 58 192 54L186 90Z',hlc:'#3a4050'});
 s+=part('M152 86H262L260 104H154Z','#8a1f24',{hl:'M152 86H262V92H152Z',hlc:'#c03a3a'});
 s+=part('M160 102C140 102 118 110 112 118C140 122 168 118 190 108Z','#0e0e12',{w:3.4,hl:'M120 114C140 108 160 104 178 104',hlc:'#5a5a6a'});
 s+=`<circle cx="186" cy="94" r="7" fill="#d8a640" stroke="${INK}" stroke-width="2"/>`;
 return s;};

T.enemy_soldier=()=>{let s=shadowG(206,580,140);const uni='#56603e',uniD='#363e26';
 // back leg (extended right)
 s+=part('M232 360L300 470L316 556H296Q288 570 298 578H360L346 556L330 466L270 350Z',uni,{sh:'M290 360L360 470V560H330L316 470L260 370Z',shc:uniD});
 s+=part('M296 540h50l16 22q4 14 -8 16h-62z','#1e1a16',{hl:'M298 544h20v6h-20z',hlc:'#5a5048'});
 // front leg bent
 s+=part('M200 360L150 440L120 470L118 556H98Q86 568 96 578H170L166 556L172 484L230 400Z',uni,{sh:'M196 380L160 460L150 556H170L176 484L230 404Z',shc:uniD});
 s+=part('M94 544h70l2 34h-80q-6 -14 8 -34z','#1e1a16',{hl:'M98 548h22v6h-22z',hlc:'#5a5048'});
 // torso leaning forward-left
 const td='M168 196C150 230 150 300 170 368L282 372C292 320 290 250 266 196C240 182 194 182 168 196Z';
 s+=part(td,uni,{sh:'M236 186C268 200 290 260 284 372H240C250 300 250 240 236 186Z',hl:'M172 204C160 240 160 300 174 340L184 340C176 300 176 240 186 204Z',shc:uniD});
 // bandolier + belt + pouches
 s+=`<path d="M176 206L276 340" stroke="${INK}" stroke-width="16"/><path d="M176 206L276 340" stroke="#6a4a2a" stroke-width="10"/>`;for(let i=0;i<6;i++)s+=`<rect x="${f(186+i*15)}" y="${f(214+i*20)}" width="8" height="10" fill="#c9a640" stroke="${INK}" stroke-width="1.6" transform="rotate(36 ${f(190+i*15)} ${f(219+i*20)})"/>`;
 s+=part('M166 346H286V370H166Z','#4a3420',{w:3.6})+P('M214 346h20v24h-20z','#9a9aa0',3);
 s+=part('M176 350h30v34h-30z','#3e4630',{w:3})+part('M244 350h30v34h-30z','#3e4630',{w:3});
 // rifle held across, pointing left
 s+=`<g transform="rotate(-8 200 280)">`+part('M18 262H230V274H18Z','#4a4e56',{hl:'M18 262H230V266H18Z',hlc:'#a8b0bc'})+part('M120 258H330L352 300L340 314L300 286H120Z','#6a4024',{hl:'M124 260H320V266H124Z',hlc:'#b8784a',w:3.6})+P('M10 258h12v20h-12z','#2a2a30',3)+P('M150 286h18l-2 24h-14z','#2a2a30',3)+`</g>`;
 // arms: front arm forward holding fore-end, back arm on stock
 s+=part('M180 212C150 230 130 250 110 262L122 286C150 272 176 254 198 236Z',uni,{sh:'M110 272L200 236V250L122 290Z',shc:uniD});
 s+=part('M96 254c-10 4 -10 20 2 24c10 3 20 -4 20 -14z',skin,{w:3.2});
 s+=part('M258 210C276 236 278 262 268 286L236 280C246 262 246 240 236 220Z',uni,{sh:'M256 210h40v80h-40z',shc:uniD});
 s+=part('M226 270c-10 2 -12 18 0 22c10 2 18 -4 16 -14z',skin,{w:3.2});
 // collar
 s+=part('M180 190L216 202L248 188L252 206L216 220L178 206Z',uni,{shc:uniD,sh:'M216 196L256 186V210L216 222Z'});
 // head + helmet
 s+=head(206,148,{scar:true});
 s+=part('M152 128C148 84 180 64 214 64C250 64 272 86 270 128C276 132 276 142 268 144H150C142 142 144 132 152 128Z','#4a5236',{sh:'M228 64C262 72 274 100 270 144H236C240 110 238 84 228 64Z',hl:'M158 124C158 96 172 80 192 74L184 124Z',hlc:'#7a8456',shc:'#2e3420'});
 s+=`<path d="M150 136H270" stroke="#2e3420" stroke-width="3"/>`;
 // chin strap
 s+=`<path d="M246 140C246 170 236 190 214 196" stroke="${INK}" stroke-width="4" fill="none"/>`;
 return s;};

T.enemy_general=()=>{let s=shadowG(212,580,150);const uni='#23304e',uniD='#151d34',cape='#7a1a20';
 // cape behind (flowing right)
 s+=part('M150 190C120 300 120 420 140 560L360 572C380 520 392 440 380 350C370 270 330 210 270 186Z',cape,{sh:'M280 190C340 230 380 330 384 440L372 570H300C320 450 310 300 280 190Z',hl:'M156 200C140 300 138 420 150 550L164 550C156 420 158 300 170 200Z',shc:'#4a0c12',hlc:'#a83038'});
 s+=`<path d="M220 250C230 360 240 460 250 568M300 240C320 340 340 450 340 566" stroke="#4a0c12" stroke-width="3" fill="none"/>`;
 // legs + riding boots
 s+=part('M160 400L152 470L146 556H124Q112 568 122 578H196L194 556L204 470L208 400Z','#2a2e3a',{hl:'M160 400L154 470H164L168 400Z',hlc:'#5a6070'});
 s+=part('M222 400L230 470L236 556H230Q222 568 232 578H306L298 556L282 470L270 400Z','#2a2e3a',{sh:'M250 400L278 470L298 556H262L250 400Z',shc:'#14161c'});
 s+=part('M144 470h56l-4 86h-50z','#121216',{hl:'M150 474h10v80h-10z',hlc:'#4a4a56'})+part('M228 470h54l12 86h-60z','#121216',{hl:'M234 474h10v80h-10z',hlc:'#4a4a56'});
 s+=`<path d="M164 400V476M248 400V476" stroke="#b8302a" stroke-width="5"/>`;
 // tunic (bulky)
 const td='M150 196C130 240 128 330 140 410C190 422 250 422 288 410C298 330 296 240 276 196C246 180 180 180 150 196Z';
 s+=part(td,uni,{sh:'M244 186C280 200 298 280 290 410H244C254 330 254 250 244 186Z',hl:'M154 204C142 250 140 330 148 400L160 400C154 330 156 250 168 204Z',shc:uniD});
 // sash
 s+=`<path d="M160 206L280 380" stroke="${INK}" stroke-width="26"/><path d="M160 206L280 380" stroke="#c9a640" stroke-width="20"/><path d="M160 206L280 380" stroke="#fff0b0" stroke-width="3" transform="translate(-6 2)"/>`;
 // belt with gold buckle
 s+=part('M140 360C190 372 250 372 290 360L292 386C250 398 190 398 140 386Z','#1a1a20',{w:3.6})+P('M196 362h28v28h-28z','#e0b04a',3);
 // buttons + medals
 for(const y of[226,256,286,316])s+=`<circle cx="194" cy="${y}" r="5.5" fill="#e0b04a" stroke="${INK}" stroke-width="2"/>`;
 const med=(x,y,c)=>`<path d="M${x-6} ${y-20}h12l-2 12h-8z" fill="${c}" stroke="${INK}" stroke-width="1.8"/><circle cx="${x}" cy="${y}" r="8" fill="#e0b04a" stroke="${INK}" stroke-width="2"/><path d="M${x} ${y-5}l1.6 3.4l3.6 .4l-2.8 2.4l.8 3.6l-3.2 -1.8l-3.2 1.8l.8 -3.6l-2.8 -2.4l3.6 -.4z" fill="#fff0a0"/>`;
 s+=med(160,250,'#b8302a')+med(178,256,'#2e5aa8')+med(160,282,'#2e7a3e');
 s+=`<path d="M236 236l6 12l13 1l-10 9l3 13l-12 -7l-12 7l3 -13l-10 -9l13 -1z" fill="#e8e8f0" stroke="${INK}" stroke-width="2"/>`;
 // arm resting on sword hilt (left side, front)
 s+=part('M152 200C128 230 120 280 126 330L156 334C156 290 162 250 176 216Z',uni,{sh:'M140 300H170V340H140Z',shc:uniD});
 s+=P('M118 326h44v14h-44z','#e0b04a',3);
 s+=part('M128 336c-10 4 -10 24 4 28c12 3 22 -6 20 -18z','#e8e8e8',{w:3.2});
 // sword scabbard
 s+=part('M124 352L108 520L120 524L142 356Z','#1a1a20',{hl:'M126 356L112 516H116L132 356Z',hlc:'#5a5a6a'})+P('M114 340h36l-4 10h-28z','#e0b04a',3)+P('M128 318h10v24h-10z','#3a2414',2.6)+`<circle cx="133" cy="314" r="7" fill="#e0b04a" stroke="${INK}" stroke-width="2.4"/>`;
 // back arm behind cape side (hand on hip)
 s+=part('M272 200C296 230 304 270 296 316L268 310C272 280 268 250 258 222Z',uni,{sh:'M262 200h50v120h-50z',shc:uniD});
 // big gold epaulettes
 for(const [cx,dk] of [[160,0],[270,1]]){s+=part(`M${cx-34} 196Q${cx} 172 ${cx+34} 196L${cx+30} 212Q${cx} 202 ${cx-30} 212Z`,'#e0b04a',{w:3.4,sh:dk?`M${cx} 170h40v50h-40z`:null,shc:'#a07818'});for(let i=0;i<8;i++){const x=cx-28+i*8;s+=`<path d="M${x} 210v22" stroke="${INK}" stroke-width="6" stroke-linecap="round"/><path d="M${x} 210v20" stroke="${dk?'#b08a28':'#f0c860'}" stroke-width="3" stroke-linecap="round"/>`;}}
 // high collar gold trimmed
 s+=part('M172 180L214 192L254 178L260 200L214 214L166 200Z',uni,{shc:uniD,sh:'M214 186L262 174V204L214 216Z'})+`<path d="M168 196L214 210L258 196" stroke="#e0b04a" stroke-width="3" fill="none"/>`;
 // head + peaked cap with gold
 s+=head(214,132,{mus:true,jaw:1.05});
 s+=`<path d="M190 168q14 10 30 0" stroke="#e8e8e8" stroke-width="5" fill="none"/>`;
 s+=part('M162 98C156 60 196 40 226 42C262 44 286 60 280 98Z',uni,{sh:'M240 42C272 50 286 70 280 98H246Z',hl:'M168 94C168 74 184 60 204 54L198 94Z',hlc:'#3a4a70',shc:uniD});
 s+=part('M164 92H280L278 112H166Z','#b8302a',{hl:'M164 92H280V98H164Z',hlc:'#e05040'});
 s+=part('M172 110C150 110 126 118 120 128C150 132 182 126 204 116Z','#0e0e14',{w:3.4,hl:'M128 124C150 116 174 112 194 112',hlc:'#5a5a6a'});
 s+=`<path d="M174 108C150 112 132 118 124 126" stroke="#e0b04a" stroke-width="2.4" fill="none"/>`;
 s+=`<path d="M196 72l8 -12l8 12l-8 14z" fill="#e0b04a" stroke="${INK}" stroke-width="2"/><path d="M180 86q24 -10 50 0" stroke="#e0b04a" stroke-width="3" fill="none"/>`;
 return s;};

module.exports=T;
if(require.main===module){const only=process.argv[2];const items=[];
 if(!only||only==='bg')items.push({name:'takedown_bg',w:W,h:H,svg:T.takedown_bg(),opaque:true,grain:0});
 for(const k of['enemy_guard','enemy_soldier','enemy_general'])if(!only||k.includes(only))items.push({name:k,w:400,h:600,svg:T[k](),grain:2});
 renderAll(items);}
