// gear icons 512x512: weapons diagonal, armor 3/4 view. Neutral materials (rarity shown by UI border).
const L=require('./lib');const {INK,f,mix,shade,light,rng,renderAll,uid}=L;
const G={};const IW=4.5;
const P=(d,fill,w=IW,extra='')=>`<path d="${d}" fill="${fill}" stroke="${INK}" stroke-width="${w}" stroke-linejoin="round" stroke-linecap="round" ${extra}/>`;
const defs=`<linearGradient id="bladeL" x1="0" x2="1"><stop offset="0" stop-color="#8a96a4"/><stop offset=".55" stop-color="#eef3f8"/><stop offset="1" stop-color="#ffffff"/></linearGradient>
<linearGradient id="bladeR" x1="0" x2="1"><stop offset="0" stop-color="#a8b4c2"/><stop offset=".5" stop-color="#7a8696"/><stop offset="1" stop-color="#4a5462"/></linearGradient>
<linearGradient id="brass" x1="0" x2="1"><stop offset="0" stop-color="#7a5418"/><stop offset=".25" stop-color="#ffe8a0"/><stop offset=".5" stop-color="#d8a640"/><stop offset="1" stop-color="#6a4410"/></linearGradient>
<linearGradient id="brassV" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff0b0"/><stop offset=".4" stop-color="#d8a640"/><stop offset="1" stop-color="#6a4410"/></linearGradient>
<linearGradient id="steelX" x1="0" x2="1"><stop offset="0" stop-color="#4a5462"/><stop offset=".22" stop-color="#e8eef4"/><stop offset=".4" stop-color="#aab4c0"/><stop offset=".75" stop-color="#6a7482"/><stop offset="1" stop-color="#363e4a"/></linearGradient>
<linearGradient id="steelY" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e8eef4"/><stop offset=".45" stop-color="#9aa4b2"/><stop offset="1" stop-color="#3e4652"/></linearGradient>
<linearGradient id="walnut" x1="0" x2="1"><stop offset="0" stop-color="#4a2a14"/><stop offset=".3" stop-color="#a8683a"/><stop offset=".55" stop-color="#8a5228"/><stop offset="1" stop-color="#3a200e"/></linearGradient>
<linearGradient id="ash" x1="0" x2="1"><stop offset="0" stop-color="#5a3a1e"/><stop offset=".3" stop-color="#c08a52"/><stop offset=".6" stop-color="#9a6a3a"/><stop offset="1" stop-color="#4a2e16"/></linearGradient>
<linearGradient id="leath" x1="0" x2="1"><stop offset="0" stop-color="#3a2010"/><stop offset=".35" stop-color="#7a4a26"/><stop offset="1" stop-color="#2e1a0c"/></linearGradient>
<radialGradient id="steelR" cx=".32" cy=".28" r=".85"><stop offset="0" stop-color="#ffffff"/><stop offset=".18" stop-color="#dfe6ee"/><stop offset=".55" stop-color="#8e99a8"/><stop offset=".85" stop-color="#4e5866"/><stop offset="1" stop-color="#2e3540"/></radialGradient>
<radialGradient id="brassR" cx=".32" cy=".28" r=".85"><stop offset="0" stop-color="#fff8d0"/><stop offset=".3" stop-color="#f0c860"/><stop offset=".75" stop-color="#a87420"/><stop offset="1" stop-color="#5a3a0c"/></radialGradient>
<radialGradient id="woolR" cx=".35" cy=".25" r=".9"><stop offset="0" stop-color="#8a8a7a"/><stop offset=".6" stop-color="#5e5e52"/><stop offset="1" stop-color="#34342c"/></radialGradient>`;
const shadowUnder=(cx,cy,rx,ry)=>`<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="#000" opacity=".28" filter="url(#blur8)"/>`;
const spark=(x,y,r)=>`<path d="M${x} ${y-r}L${x+r*0.22} ${y-r*0.22}L${x+r} ${y}L${x+r*0.22} ${y+r*0.22}L${x} ${y+r}L${x-r*0.22} ${y+r*0.22}L${x-r} ${y}L${x-r*0.22} ${y-r*0.22}Z" fill="#fff"/>`;
// diagonal wrapper: draw item pointing UP in local coords centred at (0,0), rotate 45deg so tip goes top-right
const diag=(body,ang=45,sc=1)=>`<g filter="url(#dshadow)"><g transform="translate(256 256) rotate(${ang}) scale(${sc})">${body}</g></g>`;
const wrapGrip=(x,y,w,h,col='#5a3418')=>{let s=P(`M${x} ${y}h${w}v${h}h${-w}z`,'url(#leath)',IW);for(let yy=y+4;yy<y+h;yy+=9)s+=`<path d="M${x+1} ${yy+5}L${x+w-1} ${yy}" stroke="#1a0c04" stroke-width="2.4"/><path d="M${x+1} ${yy+2}L${x+w-1} ${yy-3}" stroke="#b07a4a" stroke-width="1.2" opacity=".6"/>`;return s;};
const woodShaft=(x,y,w,h,g='ash')=>{let s=P(`M${x} ${y}h${w}v${h}h${-w}z`,`url(#${g})`,IW);const r=rng(Math.round(h));for(let i=0;i<5;i++){const xx=x+w*(.2+r()*.6);s+=`<path d="M${f(xx)} ${y+r()*30}c${f(r()*2-1)} ${h*0.2} ${f(r()*2-1)} ${h*0.3} ${f(r()*2-1)} ${h*0.5}" stroke="#2a1608" stroke-width="1" fill="none" opacity=".45"/>`;}return s;};
const rivet=(x,y,r=4)=>`<circle cx="${x}" cy="${y}" r="${r}" fill="url(#steelR)" stroke="${INK}" stroke-width="1.8"/>`;
const brassRivet=(x,y,r=4)=>`<circle cx="${x}" cy="${y}" r="${r}" fill="url(#brassR)" stroke="${INK}" stroke-width="1.8"/>`;

// ===== weapons =====
G.gear_sword=()=>diag((()=>{let s='';
 // blade from y=-230 tip to y=40
 s+=P('M0 -236L22 -196V44H-22V-196Z','#c8d0da');
 s+=`<path d="M0 -236L-22 -196V44H0Z" fill="url(#bladeL)"/><path d="M0 -236L22 -196V44H0Z" fill="url(#bladeR)"/>`;
 s+=`<path d="M-4 -186V30h8V-186Z" fill="#5a6474" opacity=".5"/><path d="M-2 -186V30" stroke="#fff" stroke-width="1.6" opacity=".6"/>`;
 s+=`<path d="M-19 -194V40" stroke="#fff" stroke-width="2.4" opacity=".85"/><path d="M0 -232L-19 -196" stroke="#fff" stroke-width="2.4" opacity=".9"/>`;
 s+=P('M0 -236L22 -196V44H-22V-196Z','none');
 // crossguard
 s+=P('M-78 38Q-84 52 -74 60L-20 56H20L74 60Q84 52 78 38Q40 44 0 42Q-40 44 -78 38Z','url(#brassV)');
 s+=`<path d="M-72 44Q-36 48 0 47Q36 48 72 44" stroke="#fff4c0" stroke-width="2" fill="none" opacity=".8"/>`+brassRivet(0,50,7);
 s+=wrapGrip(-13,60,26,92);
 s+=P('M-17 150h34v10h-34z','url(#brassV)',3.4);
 s+=`<circle cx="0" cy="182" r="22" fill="url(#brassR)" stroke="${INK}" stroke-width="${IW}"/><circle cx="-6" cy="175" r="5" fill="#fff8d8" opacity=".9"/><circle cx="0" cy="182" r="9" fill="none" stroke="#6a4410" stroke-width="2"/>`;
 s+=spark(-12,-150,10);return s;})(),45,1.2);

G.gear_saber=()=>diag((()=>{let s='';
 const outer='M-18 40C-22 -60 -8 -160 34 -238C26 -150 18 -60 18 40Z';
 s+=P(outer,'#c8d0da');s+=`<path d="M-18 40C-22 -60 -8 -160 34 -238C14 -150 0 -60 2 40Z" fill="url(#bladeL)"/><path d="M2 40C0 -60 14 -150 34 -238C26 -150 18 -60 18 40Z" fill="url(#bladeR)"/>`;
 s+=`<path d="M-13 30C-16 -60 -4 -150 28 -224" stroke="#fff" stroke-width="2.6" fill="none" opacity=".85"/><path d="M8 20C6 -60 16 -140 30 -200" stroke="#4a5462" stroke-width="2" fill="none" opacity=".6"/>`+P(outer,'none');
 // D-guard
 s+=P('M-34 40H30Q38 40 36 50L32 60H-30Q-38 56 -34 40Z','url(#brassV)');
 s+=`<path d="M30 58C56 90 52 150 18 178" fill="none" stroke="${INK}" stroke-width="15" stroke-linecap="round"/><path d="M30 58C56 90 52 150 18 178" fill="none" stroke="url(#brass)" stroke-width="8" stroke-linecap="round"/><path d="M34 66C50 96 48 140 22 168" fill="none" stroke="#fff4c0" stroke-width="2" opacity=".7"/>`;
 // grip with wire wrap
 s+=P('M-14 60H14L12 160H-12Z','#2a1a10');for(let y=64;y<160;y+=7)s+=`<path d="M-13 ${y+4}L13 ${y}" stroke="#c8a050" stroke-width="2.4"/>`;s+=P('M-14 60H14L12 160H-12Z','none');
 s+=P('M-16 158h32l-4 22h-24z','url(#brassV)');s+=`<circle cx="-4" cy="166" r="3" fill="#fff8d8"/>`;
 s+=spark(4,-140,9);return s;})(),45,1.18);

G.gear_spear=()=>diag((()=>{let s='';
 s+=woodShaft(-10,-120,20,350);
 s+=P('M-14 226h28v14h-28z','url(#steelX)');
 // socket + bindings
 s+=P('M-13 -150h26l-3 34h-20z','url(#steelX)');for(const y of[-110,-96,-82])s+=P(`M-12 ${y}h24v6h-24z`,'#6a4a2a',2.6);
 // leaf blade
 const leaf='M0 -244C24 -214 30 -180 14 -150H-14C-30 -180 -24 -214 0 -244Z';
 s+=P(leaf,'#c8d0da')+`<path d="M0 -244C-24 -214 -30 -180 -14 -150H0Z" fill="url(#bladeL)"/><path d="M0 -244C24 -214 30 -180 14 -150H0Z" fill="url(#bladeR)"/><path d="M0 -240V-152" stroke="#4a5462" stroke-width="2"/><path d="M-3 -236C-20 -210 -24 -180 -12 -156" stroke="#fff" stroke-width="2.4" fill="none" opacity=".8"/>`+P(leaf,'none');
 // tassel
 s+=`<path d="M10 -112q16 10 14 34M6 -112q10 14 4 40M12 -110q22 6 26 26" stroke="${INK}" stroke-width="5" fill="none" stroke-linecap="round"/><path d="M10 -112q16 10 14 34M6 -112q10 14 4 40M12 -110q22 6 26 26" stroke="#a8322a" stroke-width="2.6" fill="none" stroke-linecap="round"/>`;
 s+=spark(-6,-210,9);return s;})(),45,1.2);

G.gear_halberd=()=>diag((()=>{let s='';
 s+=woodShaft(-10,-150,20,390);s+=P('M-13 232h26v12h-26z','url(#steelX)');
 // langets
 s+=P('M-12 -150h24v70h-24z','url(#steelX)',3.6);for(const y of[-140,-120,-100])s+=rivet(0,y,3.4);
 // top spike
 const sp='M0 -250L12 -200L8 -150H-8L-12 -200Z';s+=P(sp,'#c8d0da')+`<path d="M0 -250L-12 -200L-8 -150H0Z" fill="url(#bladeL)"/><path d="M0 -250L12 -200L8 -150H0Z" fill="url(#bladeR)"/>`+P(sp,'none');
 // axe blade (to the right)
 const ax='M10 -186C60 -196 96 -176 104 -130C108 -96 92 -70 60 -64C76 -84 76 -112 58 -126C42 -136 26 -132 10 -128Z';
 s+=P(ax,'url(#steelY)')+`<path d="M58 -126C76 -112 76 -84 60 -64C92 -70 108 -96 104 -130C102 -150 92 -166 76 -178C90 -150 86 -110 58 -126Z" fill="#fff" opacity=".35"/><path d="M98 -150C104 -120 96 -88 68 -70" stroke="#fff" stroke-width="3" fill="none" opacity=".8"/>`+P(ax,'none')+rivet(20,-156,4)+rivet(20,-138,4);
 // back hook
 const hk='M-10 -176L-58 -196L-40 -170L-10 -150Z';s+=P(hk,'url(#steelY)')+`<path d="M-14 -172L-48 -188" stroke="#fff" stroke-width="2" opacity=".7"/>`;
 s+=spark(84,-150,9);return s;})(),45,1.12);

G.gear_musket=()=>diag((()=>{let s='';
 // ramrod
 s+=`<path d="M10 -240V60" stroke="${INK}" stroke-width="8"/><path d="M10 -240V60" stroke="#c8a070" stroke-width="3.5"/>`;
 // barrel
 s+=P('M-9 -250h18v240h-18z','url(#steelX)');s+=P('M-12 -254h24v10h-24z','url(#steelX)',3.4);
 // stock (fore-end + butt)
 const st='M-12 -110H14V60C14 92 22 120 40 160L42 236C20 244 -14 244 -36 236L-24 150C-18 110 -14 84 -14 50Z';
 s+=P(st,'url(#walnut)');s+=`<path d="M-8 -100V50C-8 84 -14 112 -20 150L-28 228" stroke="#d89a5a" stroke-width="3" fill="none" opacity=".55"/>`;
 for(let i=0;i<6;i++)s+=`<path d="M${-6+i*3} ${-80+i*40}c6 20 -4 30 2 50" stroke="#2a1608" stroke-width="1.1" fill="none" opacity=".45"/>`;
 // butt plate
 s+=P('M-36 236C-14 244 20 244 42 236L44 248C20 256 -16 256 -38 248Z','url(#brass)',3.6);
 // barrel bands
 for(const y of[-170,-90])s+=P(`M-15 ${y}h30v10h-30z`,'url(#brass)',3.4);
 // lock plate + flint hammer
 s+=P('M10 10h22v56h-22z','url(#steelX)',3.4);
 s+=P('M30 18C46 6 52 -6 48 -18L40 -14C40 -4 34 4 26 10Z','url(#steelY)',3.4)+P('M40 -24h14v8h-14z','#5a5a60',2.4);
 s+=P('M24 72C40 80 44 96 34 104',"none",4)+`<path d="M24 72C40 80 44 96 34 104" stroke="url(#brass)" stroke-width="2" fill="none"/>`;
 // trigger guard
 s+=`<path d="M14 70C30 76 34 98 14 108" fill="none" stroke="${INK}" stroke-width="9"/><path d="M14 70C30 76 34 98 14 108" fill="none" stroke="#d8a640" stroke-width="4"/>`;
 // sling
 s+=`<path d="M-12 -60C-50 0 -60 120 -30 200" fill="none" stroke="${INK}" stroke-width="11"/><path d="M-12 -60C-50 0 -60 120 -30 200" fill="none" stroke="#8a5a30" stroke-width="6"/>`;
 s+=`<path d="M-4 -246V-20" stroke="#fff" stroke-width="2.4" opacity=".8"/>`+spark(0,-200,9);return s;})(),45,1.0);

G.gear_rifle=()=>diag((()=>{let s='';
 // barrel
 s+=P('M-8 -252h16v200h-16z','url(#steelX)');s+=P('M-12 -256h24v12h-24z','#3a404a',3.4);s+=P('M-4 -268h8v14h-8z','#3a404a',3);
 // handguard + stock
 const st='M-14 -150H14V20H22V60C22 90 30 120 44 150L46 232C22 242 -16 242 -40 232L-24 140C-18 100 -16 80 -16 50V20H-14Z';
 s+=P(st,'url(#walnut)')+`<path d="M-9 -140V40C-10 80 -18 120 -26 160L-32 224" stroke="#d89a5a" stroke-width="3" fill="none" opacity=".5"/>`;
 s+=P('M-16 -60h32v8h-32z','#3a404a',3);s+=P('M-16 -120h32v8h-32z','#3a404a',3);
 // receiver + bolt
 s+=P('M-16 0h34v62h-34z','url(#steelX)');s+=`<path d="M18 22H44" stroke="${INK}" stroke-width="9" stroke-linecap="round"/><path d="M18 22H44" stroke="#c8d0da" stroke-width="4" stroke-linecap="round"/><circle cx="48" cy="22" r="8" fill="url(#steelR)" stroke="${INK}" stroke-width="3"/>`;
 // magazine
 s+=P('M18 66h22l-4 30h-18z','#3a404a',3.6);
 // trigger guard
 s+=`<path d="M18 100C34 104 36 124 16 130" fill="none" stroke="${INK}" stroke-width="8"/><path d="M18 100C34 104 36 124 16 130" fill="none" stroke="#5a606a" stroke-width="3.5"/>`;
 s+=P('M-40 232C-16 242 22 242 46 232L48 244C22 252 -18 252 -42 244Z','#2a2a30',3.4);
 // sling
 s+=`<path d="M-14 -110C-56 -40 -62 100 -34 190" fill="none" stroke="${INK}" stroke-width="12"/><path d="M-14 -110C-56 -40 -62 100 -34 190" fill="none" stroke="#5a5a3a" stroke-width="7"/><path d="M-14 -110C-56 -40 -62 100 -34 190" fill="none" stroke="#7a7a50" stroke-width="2" stroke-dasharray="4 6"/>`;
 // front sight
 s+=P('M-4 -246v-12h8v12z','#3a404a',2.6);
 s+=`<path d="M-3 -248V-70" stroke="#fff" stroke-width="2.4" opacity=".8"/>`+spark(2,-210,9);return s;})(),45,1.0);

// ===== armour =====
G.gear_helm=()=>{let s=shadowUnder(262,446,160,30);
 // dome
 const dome='M110 300C100 170 170 92 256 92C342 92 412 170 402 300Z';
 s+=P(dome,'url(#steelR)');
 s+=`<path d="M256 96C222 120 214 200 220 300" stroke="#2e3540" stroke-width="3" fill="none" opacity=".5"/><path d="M256 92C290 120 300 200 296 300" stroke="#fff" stroke-width="2" fill="none" opacity=".3"/>`;
 // central crest ridge
 s+=P('M246 92C246 70 266 70 266 92L270 300H242Z','url(#steelX)',3.6);
 // brim band with rivets (brass trim)
 s+=P('M96 296C150 318 362 318 416 296L420 326C362 350 150 350 92 326Z','url(#brass)');
 for(let i=0;i<9;i++){const t=i/8;const x=112+t*288;const y=318+Math.sin(t*Math.PI)*12;s+=brassRivet(f(x),f(y),4);}
 // cheek guards
 s+=P('M120 330C118 380 140 420 178 436C188 406 190 372 186 340Z','url(#steelY)')+P('M392 330C394 380 372 420 334 436C324 406 322 372 326 340Z','url(#steelY)');
 s+=`<path d="M132 344C134 380 150 408 172 422" stroke="#fff" stroke-width="2.4" fill="none" opacity=".6"/>`+rivet(156,362)+rivet(356,362);
 // nasal guard
 s+=P('M244 316H268L264 412L256 424L248 412Z','url(#steelX)');
 // dark face opening hint
 s+=`<path d="M186 340C200 344 236 346 244 344L248 412C220 420 200 420 182 416Z" fill="#1a1d24" opacity=".85"/><path d="M268 344C276 346 312 344 326 340L330 416C312 420 292 420 264 412Z" fill="#1a1d24" opacity=".85"/>`;
 // leather chin strap
 s+=`<path d="M180 430C220 470 292 470 332 430" fill="none" stroke="${INK}" stroke-width="13"/><path d="M180 430C220 470 292 470 332 430" fill="none" stroke="#7a4a26" stroke-width="7"/>`+P('M248 452h16v14h-16z','url(#brass)',2.6);
 // plume holder + short plume (neutral grey)
 s+=P('M248 70h16v-18h-16z','url(#brass)',3);
 s+=`<path d="M256 54C230 20 200 14 176 22C210 26 230 40 246 62Z" fill="#d8d4c8" stroke="${INK}" stroke-width="3.6"/><path d="M252 50C232 30 210 24 190 26" stroke="#fff" stroke-width="2" fill="none" opacity=".8"/>`;
 // speculars
 s+=`<path d="M150 230C156 170 196 124 240 112" stroke="#fff" stroke-width="10" fill="none" stroke-linecap="round" opacity=".55"/><circle cx="184" cy="150" r="9" fill="#fff"/>`+spark(370,170,12);
 return s;};

G.gear_cuirass=()=>{let s=shadowUnder(260,462,170,28);
 // backplate edges visible behind
 s+=P('M118 140C130 120 170 108 200 104L312 104C342 108 382 120 394 140L404 330C380 380 330 412 256 420C182 412 132 380 108 330Z','#5a6270');
 // front plate
 const fr='M128 132C150 118 182 112 206 116C222 136 290 136 306 116C330 112 362 118 384 132L392 300C384 360 334 404 256 416C178 404 128 360 120 300Z';
 s+=P(fr,'url(#steelR)');
 // medial ridge & shading
 s+=`<path d="M256 134C256 220 254 330 256 414" stroke="#2e3540" stroke-width="3" fill="none" opacity=".6"/><path d="M262 134C262 220 262 330 262 410" stroke="#fff" stroke-width="2" fill="none" opacity=".5"/>`;
 s+=`<path d="M300 140C340 180 360 260 340 360C330 380 310 396 290 404C330 330 330 220 300 140Z" fill="#000" opacity=".18"/>`;
 // neck & arm openings (rolled edges brass)
 s+=`<path d="M206 116C222 136 290 136 306 116" fill="none" stroke="${INK}" stroke-width="12"/><path d="M206 116C222 136 290 136 306 116" fill="none" stroke="url(#brass)" stroke-width="6"/>`;
 s+=`<path d="M128 132C140 170 150 200 132 226" fill="none" stroke="${INK}" stroke-width="12"/><path d="M128 132C140 170 150 200 132 226" fill="none" stroke="url(#brass)" stroke-width="6"/><path d="M384 132C372 170 362 200 380 226" fill="none" stroke="${INK}" stroke-width="12"/><path d="M384 132C372 170 362 200 380 226" fill="none" stroke="url(#brass)" stroke-width="6"/>`;
 // waist lame
 s+=P('M124 330C170 370 342 370 388 330L384 356C340 400 172 400 128 356Z','url(#steelY)',3.6);
 // rivets
 for(let i=0;i<7;i++){const t=i/6;s+=rivet(f(140+t*232),f(348+Math.sin(t*Math.PI)*18),4);}
 for(const [x,y] of[[150,150],[362,150],[146,280],[366,280]])s+=rivet(x,y,4.5);
 // shoulder straps leather with buckles
 for(const sx of[-1,1]){const x=256+sx*80;s+=P(`M${x-14} 86h28v44h-28z`,'url(#leath)',3.6)+P(`M${x-12} 110h24v14h-24z`,'none',3)+`<rect x="${x-10}" y="112" width="20" height="10" fill="none" stroke="#d8a640" stroke-width="3"/>`;}
 // speculars
 s+=`<path d="M170 170C176 230 182 290 200 350" stroke="#fff" stroke-width="12" fill="none" stroke-linecap="round" opacity=".45"/><circle cx="182" cy="176" r="8" fill="#fff"/>`+spark(330,210,12);
 return s;};

G.gear_plate=()=>{let s=shadowUnder(260,470,190,28);
 // tassets (thigh plates)
 for(const sx of[-1,1]){const x=256+sx*64;s+=P(`M${x-46} 360H${x+46}L${x+40} 452Q${x} 466 ${x-40} 452Z`,'url(#steelY)');for(const y of[384,410,434])s+=`<path d="M${x-44} ${y}Q${x} ${y+8} ${x+44} ${y}" stroke="${INK}" stroke-width="3" fill="none"/>`;s+=rivet(x-30,372,4)+rivet(x+30,372,4);}
 // breastplate
 const fr='M150 150C170 130 210 122 236 126C246 140 266 140 276 126C302 122 342 130 362 150L370 320C358 368 316 392 256 398C196 392 154 368 142 320Z';
 s+=P(fr,'url(#steelR)');
 s+=`<path d="M256 140C256 220 256 300 256 396" stroke="#2e3540" stroke-width="3.4" fill="none" opacity=".6"/><path d="M262 140V392" stroke="#fff" stroke-width="2" opacity=".5"/><path d="M300 150C340 190 352 270 336 350C326 370 306 384 290 390C320 320 322 220 300 150Z" fill="#000" opacity=".2"/>`;
 // fauld lames
 s+=P('M146 318C190 352 322 352 366 318L368 344C322 382 190 382 144 344Z','url(#steelY)',3.6)+P('M148 344C190 380 322 380 364 344L364 368C322 404 190 404 148 368Z','url(#steelY)',3.6);
 // gorget
 s+=P('M200 98C220 88 292 88 312 98L318 130C296 146 216 146 194 130Z','url(#steelY)');s+=`<path d="M204 112C230 124 282 124 308 112" stroke="${INK}" stroke-width="3" fill="none"/>`;
 // pauldrons (layered)
 for(const sx of[-1,1]){const cx=256+sx*124;
  const p1=`M${cx-sx*70} 112C${cx-sx*30} 82 ${cx+sx*40} 90 ${cx+sx*62} 140C${cx+sx*72} 170 ${cx+sx*64} 196 ${cx+sx*48} 210C${cx+sx*10} 196 ${cx-sx*40} 170 ${cx-sx*70} 150Z`;
  s+=P(p1,'url(#steelR)');
  for(let k=0;k<3;k++){const y=196+k*22;s+=P(`M${cx-sx*30} ${y}C${cx} ${y-6} ${cx+sx*40} ${y+4} ${cx+sx*56} ${y+18}L${cx+sx*50} ${y+34}C${cx+sx*30} ${y+22} ${cx} ${y+16} ${cx-sx*26} ${y+20}Z`,'url(#steelY)',3.4);}
  s+=`<path d="M${cx-sx*50} 118C${cx-sx*10} 98 ${cx+sx*30} 104 ${cx+sx*50} 140" stroke="url(#brass)" stroke-width="6" fill="none"/><path d="M${cx-sx*50} 118C${cx-sx*10} 98 ${cx+sx*30} 104 ${cx+sx*50} 140" stroke="${INK}" stroke-width="1.6" fill="none" transform="translate(0 4)"/>`+rivet(cx-sx*4,130,5);
 }
 s+=`<path d="M190 170C194 230 200 290 214 340" stroke="#fff" stroke-width="12" fill="none" stroke-linecap="round" opacity=".45"/><circle cx="198" cy="176" r="8" fill="#fff"/><path d="M110 130C130 110 160 102 180 104" stroke="#fff" stroke-width="5" fill="none" stroke-linecap="round" opacity=".6"/>`+spark(326,226,12);
 return s;};

G.gear_coat=()=>{let s=shadowUnder(262,476,170,26);
 const wool='#5a5c50',woolD='#3a3c34';
 // sleeves
 s+=P('M150 120C110 140 92 220 88 330C86 380 90 420 96 440H146C148 400 150 330 160 250Z','url(#woolR)');s+=P('M374 120C414 140 432 220 436 330C438 380 434 420 428 440H378C376 400 374 330 364 250Z','url(#woolR)');
 s+=P('M92 418h56v26h-56z','#3a3c34')+P('M376 418h56v26h-56z','#3a3c34');for(const x of[106,134,390,418])s+=brassRivet(x,431,4.4);
 // body
 const body='M150 112C190 92 230 88 256 98C282 88 322 92 374 112L384 300C390 360 396 420 402 466H122C128 420 134 360 140 300Z';
 s+=P(body,'url(#woolR)');
 // folds
 s+=`<path d="M190 300C186 360 180 420 176 464M330 300C334 360 340 420 344 464M220 360C224 400 222 440 214 466" stroke="${woolD}" stroke-width="4" fill="none" opacity=".7"/><path d="M196 300C192 360 186 420 182 464" stroke="#9a9a88" stroke-width="2" fill="none" opacity=".4"/>`;
 // lapels / double-breasted front
 s+=P('M206 104L256 210L232 466H196L212 230L176 140Z',shade(wool,.1));s+=P('M306 104L256 210L280 466H316L300 230L336 140Z',shade(wool,.25));
 s+=`<path d="M256 210V466" stroke="${INK}" stroke-width="3.6"/>`;
 // collar
 s+=P('M196 96C220 76 292 76 316 96L306 126C290 112 222 112 206 126Z','#4a4c42');s+=`<path d="M204 92C230 80 282 80 308 92" stroke="#8a8a78" stroke-width="2" fill="none"/>`;
 // epaulettes
 for(const sx of[-1,1]){const cx=256+sx*110;s+=P(`M${cx-34} 108Q${cx} 92 ${cx+34} 108L${cx+30} 128Q${cx} 120 ${cx-30} 128Z`,'url(#brassV)');for(let i=0;i<7;i++)s+=`<path d="M${cx-28+i*9.3} 126v16" stroke="${INK}" stroke-width="5" stroke-linecap="round"/><path d="M${cx-28+i*9.3} 126v14" stroke="#e0b04a" stroke-width="2.6" stroke-linecap="round"/>`;}
 // buttons two rows
 for(let i=0;i<5;i++){const y=236+i*44;s+=brassRivet(232,y,7)+brassRivet(280,y,7);}
 // belt
 s+=P('M138 320C190 330 322 330 386 320L388 346C322 358 190 358 136 346Z','#3a2a1a',3.6)+P('M240 318h32v34h-32z','none',3.6)+`<rect x="242" y="320" width="28" height="30" fill="none" stroke="#d8a640" stroke-width="4"/>`;
 // pocket flaps
 s+=P('M150 380h56l-4 14h-48z','#4a4c42',3)+P('M306 380h56l-4 14h-48z','#4a4c42',3);
 s+=`<path d="M164 130C150 200 146 280 150 330" stroke="#a8a894" stroke-width="5" fill="none" stroke-linecap="round" opacity=".5"/>`;
 return s;};

G.gear_shield=()=>{let s=shadowUnder(270,470,150,26);
 s+=`<g transform="translate(256 262) skewY(-6) scale(.98 1)">`;
 const sh='M-150 -190H150C154 -60 140 60 0 200C-140 60 -154 -60 -150 -190Z';
 // wood planks
 s+=`<clipPath id="shc"><path d="${sh}"/></clipPath><g clip-path="url(#shc)">`;
 const cols=['#9a6a3c','#a87444','#8e6036','#a06e40','#94663a'];for(let i=0;i<5;i++){const x=-150+i*60;s+=`<rect x="${x}" y="-200" width="60" height="420" fill="${cols[i]}"/><rect x="${x}" y="-200" width="60" height="420" fill="url(#grain)" opacity=".8" transform="rotate(90 ${x+30} 0)"/><path d="M${x} -200V220" stroke="#3a2010" stroke-width="3"/><path d="M${x+2} -200V220" stroke="#d8a670" stroke-width="1.4" opacity=".5"/>`;}
 s+=`<rect x="-160" y="-200" width="320" height="420" fill="url(#woolR)" opacity=".0"/><radialGradient id="shg" cx=".3" cy=".2" r=".9"><stop offset="0" stop-color="#fff2d0" stop-opacity=".35"/><stop offset=".6" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".45"/></radialGradient><rect x="-160" y="-200" width="320" height="420" fill="url(#shg)"/></g>`;
 // steel rim
 s+=`<path d="${sh}" fill="none" stroke="${INK}" stroke-width="26" stroke-linejoin="round"/><path d="${sh}" fill="none" stroke="url(#steelX)" stroke-width="18" stroke-linejoin="round"/><path d="${sh}" fill="none" stroke="#fff" stroke-width="2" opacity=".5" transform="translate(-2 -2)"/>`;
 for(let i=0;i<12;i++){const t=i/11;const x=-150+t*300;s+=rivet(f(x),-190,4.5);}
 
 // steel cross band + boss
 s+=P('M-140 -40H140V-8H-140Z','url(#steelY)',3.6)+P('M-16 -186H16V180L0 196L-16 180Z','url(#steelX)',3.6);
 s+=`<circle cx="0" cy="-24" r="46" fill="url(#steelR)" stroke="${INK}" stroke-width="${IW}"/><circle cx="0" cy="-24" r="30" fill="url(#steelR)" stroke="${INK}" stroke-width="2.4"/><circle cx="-12" cy="-38" r="7" fill="#fff"/>`;
 for(let i=0;i<8;i++){const a=i*Math.PI/4;s+=rivet(f(Math.cos(a)*38),f(-24+Math.sin(a)*38),3.4);}
 s+=`</g>`;
 return s;};

module.exports=G;
if(require.main===module){const only=process.argv[2];renderAll(Object.keys(G).filter(k=>!only||k.startsWith(only)).map(k=>({name:k,w:512,h:512,svg:`<defs>${defs}</defs>`+G[k](),grain:2})));}
