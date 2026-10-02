// country_era1..8: 1600x400 panoramic capital scenes.
const L=require('./lib');const S=require('./scene');const {INK,f,mix,shade,light,rng,renderAll}=L;
const {sky,glow,sunDisc,stars,cloud,ridge,haze,bld,wins,dome,spire,treeRound,cypress,pine,palm,ink,smokePlume,vignette,reflect}=S;
const W=1600,H=400;const E={};

// small helpers
const stall=(x,base,w,c1,c2='#f1e2c0')=>{let s=`<path d="M${x+4} ${base}V${base-30}M${x+w-4} ${base}V${base-30}" stroke="${INK}" stroke-width="4"/><path d="M${x+4} ${base}V${base-30}M${x+w-4} ${base}V${base-30}" stroke="#8a6440" stroke-width="2"/>`;
 s+=ink(`M${x} ${base-12}h${w}v12h${-w}z`,'#a8784a',2.2);
 const n=Math.round(w/10);let st='';for(let i=0;i<n;i++)st+=`<path d="M${f(x-4+i*(w+8)/n)} ${base-30}L${f(x-4+(i+1)*(w+8)/n)} ${base-30}L${f(x-6+(i+1)*(w+12)/n)} ${base-42}L${f(x-6+i*(w+12)/n)} ${base-42}Z" fill="${i%2?c2:c1}"/>`;
 s+=st+`<path d="M${x-4} ${base-30}H${x+w+4}L${x+w+6} ${base-42}H${x-6}Z" fill="none" stroke="${INK}" stroke-width="2.2"/>`;
 for(let i=0;i<n;i++)s+=`<path d="M${f(x-4+i*(w+8)/n)} ${base-30}a${f((w+8)/n/2)} 4 0 0 0 ${f((w+8)/n)} 0" fill="${i%2?c2:c1}" stroke="${INK}" stroke-width="1.4"/>`;
 for(let i=0;i<Math.floor(w/9);i++)s+=`<circle cx="${x+6+i*9}" cy="${base-15}" r="3.4" fill="${['#d2452e','#e3a43a','#6a9a3a','#8a3a7a'][i%4]}" stroke="${INK}" stroke-width="1.2"/>`;
 return s;};
const pot=(x,base,s=1,col='#b8643a')=>ink(`M${x-2*s} ${base}q${-7*s} ${-5*s} ${-6*s} ${-13*s}q${1*s} ${-6*s} ${5*s} ${-7*s}v${-3*s}h${6*s}v${3*s}q${4*s} ${1*s} ${5*s} ${7*s}q${1*s} ${8*s} ${-6*s} ${13*s}z`,col,1.8)+`<path d="M${x-4*s} ${base-12*s}q${-1*s} ${4*s} ${1*s} ${8*s}" stroke="#fff" stroke-width="1.3" opacity=".45" fill="none"/>`;
const reeds=(x0,x1,base,seed,col='#5a6a2a')=>{const r=rng(seed);let o='';for(let x=x0;x<x1;x+=5+r()*6){const h=14+r()*26,l=(r()-.5)*10;o+=`<path d="M${f(x)} ${base}q${f(l*0.3)} ${f(-h*0.5)} ${f(l)} ${f(-h)}" stroke="${col}" stroke-width="${f(1.4+r()*1.4)}" fill="none" stroke-linecap="round"/>`;if(r()<.2)o+=`<ellipse cx="${f(x+l)}" cy="${f(base-h)}" rx="1.8" ry="5" fill="#6a4a2a"/>`;}return o;};
const water=(y0,y1,c0,c1,seed,lineCol='#fff')=>{const r=rng(seed);const id='w'+seed;let o=`<linearGradient id="${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${c0}"/><stop offset="1" stop-color="${c1}"/></linearGradient><rect x="0" y="${y0}" width="${W}" height="${y1-y0}" fill="url(#${id})"/>`;
 for(let i=0;i<120;i++){const x=r()*W,y=y0+4+r()*(y1-y0-6),l=10+r()*40;o+=`<path d="M${f(x)} ${f(y)}h${f(l)}" stroke="${lineCol}" stroke-width="${f(.8+r()*1.2)}" opacity="${f(.12+r()*.25)}" stroke-linecap="round"/>`;}return o;};
const boat=(x,y,s=1,sail=null)=>{let o=ink(`M${x-40*s} ${y-8*s}Q${x} ${y+10*s} ${x+40*s} ${y-8*s}L${x+34*s} ${y-2*s}Q${x} ${y+6*s} ${x-34*s} ${y-2*s}Z`,'#7a4a2a',2.2)+`<path d="M${x-36*s} ${y-6*s}Q${x} ${y+4*s} ${x+36*s} ${y-6*s}" stroke="#c9945a" stroke-width="1.5" fill="none"/>`;
 if(sail)o+=`<path d="M${x} ${y-2*s}V${y-62*s}" stroke="${INK}" stroke-width="3"/>`+ink(`M${x+2*s} ${y-58*s}Q${x+30*s} ${y-36*s} ${x+2*s} ${y-12*s}Z`,sail,2)+`<path d="M${x+4*s} ${y-50*s}Q${x+20*s} ${y-36*s} ${x+4*s} ${y-20*s}" stroke="#fff" stroke-width="1.5" opacity=".4" fill="none"/>`;
 return o;};

// ================= ERA 1: Ancient =================
E[1]=()=>{let s='';
 s+=sky(W,H,[[0,'#4f6290'],[.35,'#c98a6a'],[.62,'#f2b36a'],[.8,'#f8dca0']]);
 s+=sunDisc(330,232,26,'#fff0c0','#ffc070');
 s+=cloud(80,120,260,{col:'#f0b890',sh:'#a86a70',lit:'#ffe6c0',op:.85})+cloud(1050,90,330,{col:'#e8a88a',sh:'#8a5a70',lit:'#ffd8b0',op:.8})+cloud(560,150,180,{col:'#f4c09a',sh:'#b07a7a',lit:'#ffe8c8',op:.7})+cloud(1380,170,200,{col:'#f4c09a',sh:'#b07a7a',lit:'#ffe8c8',op:.7});
 s+=ridge(W,268,26,3,'#b98a76',{step:30});s+=ridge(W,282,14,7,'#a87660',{step:25});
 s+=haze(W,200,300,'#f6d0a0',.55);
 // far city silhouettes
 const r=rng(11);let far='';for(let x=0;x<W;x+=34+r()*30){const w=30+r()*40,h=16+r()*26;if(x>540&&x<1080)continue;far+=bld(x,300,w,h,{fill:'#c49674',d:8,sw:1.2,ink:'#7a5446',shadow:false,rim:false,ao:.3,wins:{cols:2,rows:1,ww:4,wh:5,padT:6,lit:.6,seed:Math.round(x),glowOn:false,frame:'#7a5446',fw:.8}});if(r()<.25)far+=palm(x+w*0.5,300-h+4,34,{ink:'#6a4a3a',col:'#7a8a4a'});}
 s+=far+haze(W,240,305,'#f2c896',.35);
 // ziggurat
 const zc=800,zb=318;
 const tier=(w,h,base,seed)=>bld(zc-w/2,base,w,h,{fill:'#c99a64',tex:'brick',texOp:.55,d:46,content:(x,t,ww,hh)=>{let o='';for(let i=0;i<ww;i+=26)o+=`<rect x="${x+i}" y="${t}" width="8" height="${hh}" fill="#000" opacity=".12"/><rect x="${x+i+8}" y="${t}" width="2" height="${hh}" fill="#fff" opacity=".18"/>`;return o+`<rect x="${x}" y="${t}" width="${ww}" height="5" fill="#e8c48a"/>`;}});
 s+=tier(520,64,zb,1)+tier(380,52,zb-64,2)+tier(250,46,zb-116,3);
 // temple on top
 s+=bld(zc-70,zb-162,140,46,{fill:'#d8b07a',tex:'brick',texOp:.5,d:30,content:(x,t,w,h)=>`<rect x="${x}" y="${t+6}" width="${w}" height="10" fill="#2e5e9a"/><path d="M${x} ${t+11}h${w}" stroke="#e8c050" stroke-width="2" stroke-dasharray="6 6"/><path d="M${x+w/2-12} ${t+h}V${t+24}a12 12 0 0 1 24 0V${t+h}Z" fill="#2a1408" stroke="${INK}" stroke-width="2.2"/><path d="M${x+w/2-9} ${t+h}V${t+26}a9 9 0 0 1 18 0V${t+h}Z" fill="url(#winLit)" opacity=".8"/>`});
 s+=`<path d="M${zc} ${zb-208}v-26" stroke="${INK}" stroke-width="4"/>`+ink(`M${zc} ${zb-234}l26 6l-26 6z`,'#c0392b',2)+glow(zc,zb-190,60,'#ffd890',.35);
 // grand central stair
 const st=`M${zc-46} ${zb}L${zc-26} ${zb-116}H${zc+26}L${zc+46} ${zb}Z`;s+=ink(st,'#d8b07a',2.6);for(let i=1;i<24;i++){const y=zb-i*116/24,hw=46-i*20/24;s+=`<path d="M${f(zc-hw)} ${f(y)}H${f(zc+hw)}" stroke="#7a5030" stroke-width="1.2" opacity=".7"/>`;}
 s+=`<path d="${st}" fill="url(#topLit)"/>`;
 // braziers on tiers
 for(const [x,y] of [[zc-190,zb-64],[zc+190,zb-64],[zc-125,zb-116],[zc+125,zb-116]])s+=glow(x,y-10,22,'#ffb050',.7)+ink(`M${x-5} ${y}h10l2 -7h-14z`,'#5a3a20',1.6)+`<path d="M${x} ${y-18}q5 5 2 10h-4q-3 -5 2 -10z" fill="#ffd060"/>`;
 // mid city: mudbrick houses both sides
 const house=(x,w,h,seed,base=328)=>bld(x,base,w,h,{fill:['#d4a874','#c99a66','#ddb684'][seed%3],tex:'plaster',d:16,sw:2.2,content:(X,t,ww,hh)=>`<rect x="${X}" y="${t}" width="${ww}" height="4" fill="#e8c898"/>`+(ww>40?`<path d="M${X+ww*0.2} ${t+hh}v-18h12v18z" fill="#3a2010" stroke="${INK}" stroke-width="1.6"/>`:''),wins:{cols:Math.max(1,Math.round(w/30)),rows:h>50?2:1,ww:8,wh:9,padT:10,padB:24,lit:.7,seed}});
 // back row of houses (higher, hazed)
 let back='';[[20,60,40],[90,70,52],[170,54,36],[240,76,58],[330,60,44],[400,70,50],[470,60,40],[1080,64,44],[1150,70,56],[1230,60,40],[1300,80,60],[1390,60,46],[1460,70,52],[1540,60,40]].forEach(([x,w,h],i)=>back+=bld(x,312,w,h,{fill:'#c89c70',tex:'plaster',d:12,sw:1.6,ink:'#6a4a3a',ao:.4,haze:.18,hazeCol:'#f6d0a0',wins:{cols:2,rows:1,ww:6,wh:7,padT:9,lit:.6,seed:i+40}}));
 s+=back;
 let mid='';const hx=[[40,70,54],[118,56,40],[180,80,62],[268,60,44],[336,70,52],[410,64,38],[478,58,48],[1100,70,46],[1176,80,60],[1264,58,40],[1330,74,56],[1412,62,44],[1482,80,58]];
 hx.forEach(([x,w,h],i)=>mid+=house(x,w,h,i));
 s+=mid;
 for(const x of[160,330,520,1150,1320,1500])s+=palm(x,330,64+(x%50),{lean:(x%3)*6-6});
 // riverbank + stalls
 s+=`<path d="M0 326H${W}V346H0Z" fill="#b48a5a"/><path d="M0 326H${W}" stroke="${INK}" stroke-width="2.4"/><rect x="0" y="326" width="${W}" height="20" fill="url(#gravel)"/>`;
 s+=stall(60,338,70,'#b8402e')+stall(200,338,60,'#2e6a9a')+stall(420,338,74,'#b8402e')+stall(1040,338,66,'#8a3a7a')+stall(1210,338,72,'#2e6a9a')+stall(1420,338,64,'#b8402e');
 for(const [x,c] of [[150,'#b8643a'],[160,'#a0522d'],[350,'#b8643a'],[510,'#a0522d'],[1130,'#b8643a'],[1300,'#a0522d'],[1520,'#b8643a']])s+=pot(x,340,1.1,c);
 // river
 s+=water(346,H,'#4a7a8a','#244a5a',5,'#ffe0b0');
 s+=`<rect x="0" y="346" width="${W}" height="54" fill="#ffb060" opacity=".08"/>`+glow(330,352,140,'#ffd090',.35);
 s+=reflect(back+mid,346,.18);
 s+=boat(560,366,.8,'#efe2c0')+boat(1010,364,.7,null)+boat(1240,392,1.5,'#e8d4a8');
 // foreground bank corners + big framing palms
 s+=`<path d="M0 360Q90 352 190 372Q240 384 260 400H0Z" fill="#5a4a2a" stroke="${INK}" stroke-width="2.4"/><path d="M${W} 356Q${W-110} 350 ${W-200} 370Q${W-250} 386 ${W-270} 400H${W}Z" fill="#5a4a2a" stroke="${INK}" stroke-width="2.4"/>`;
 s+=reeds(0,220,400,3,'#3a4a1a')+reeds(1380,W,400,9,'#3a4a1a');
 s+=palm(40,400,170,{lean:22,col:'#4a7a34'})+palm(W-60,400,150,{lean:-24,col:'#4a7a34'})+pot(120,396,1.6,'#a0522d')+pot(W-160,398,1.5,'#b8643a');
 s+=vignette(W,H,.35);return s;};

// ================= ERA 2: Classical =================
const temple=(x,base,w,h,n,{col='#efe8d8',roof='#b9583a',d=40,gold=false}={})=>{let s='';const top=base-h;const ent=h*0.17,ped=w*0.15;
 // steps
 for(let i=0;i<3;i++)s+=bld(x-12+i*4,base-i*5,w+24-i*8,5,{fill:col,d:d+8-i*2,sw:2,shadow:i==0,rim:false,ao:0,tex:'stone',texOp:.3});
 const cb=base-15;
 // cella wall behind columns (darker)
 s+=bld(x+8,cb,w-16,h-15-ent,{fill:shade(col,.25),d:d,sw:2,rim:false,shadow:false,content:(X,t,ww,hh)=>`<rect x="${X+ww/2-12}" y="${t+hh-40}" width="24" height="40" fill="#3a2a1a"/><rect x="${X+ww/2-9}" y="${t+hh-37}" width="18" height="37" fill="url(#winLit)" opacity=".6"/>`});
 // columns
 const cw=w/(n*1.75),gap=(w-cw*n)/(n-1);
 for(let i=0;i<n;i++){const cx=x+i*(cw+gap);const ch=h-15-ent;
  s+=`<rect x="${f(cx)}" y="${f(cb-ch)}" width="${f(cw)}" height="${f(ch)}" fill="${col}"/><rect x="${f(cx+cw*0.62)}" y="${f(cb-ch)}" width="${f(cw*0.38)}" height="${f(ch)}" fill="#6a5a7a" opacity=".35"/><rect x="${f(cx+cw*0.12)}" y="${f(cb-ch)}" width="${f(cw*0.18)}" height="${f(ch)}" fill="#fff" opacity=".5"/>`;
  for(const t of[.33,.5,.66])s+=`<path d="M${f(cx+cw*t)} ${f(cb-ch+4)}V${f(cb-2)}" stroke="#7a6a5a" stroke-width=".8" opacity=".5"/>`;
  s+=`<rect x="${f(cx)}" y="${f(cb-ch)}" width="${f(cw)}" height="${f(ch)}" fill="none" stroke="${INK}" stroke-width="2"/>`+ink(`M${f(cx-3)} ${f(cb-ch)}h${f(cw+6)}v-5h${f(-cw-6)}z`,col,1.8)+ink(`M${f(cx-2)} ${f(cb)}h${f(cw+4)}v-4h${f(-cw-4)}z`,col,1.6);}
 // entablature
 s+=bld(x-6,top+ent+ped*0,w+12,ent,{fill:col,d:d,sw:2.4,rim:true,shadow:false,roof:'none',content:(X,t,ww,hh)=>`<rect x="${X}" y="${t+hh*0.45}" width="${ww}" height="${hh*0.55}" fill="#000" opacity=".06"/>`+Array.from({length:Math.floor(ww/12)},(_,i)=>`<rect x="${X+4+i*12}" y="${t+hh*0.5}" width="4" height="${hh*0.4}" fill="#000" opacity=".22"/>`).join('')+(gold?`<rect x="${X}" y="${t+2}" width="${ww}" height="2.5" fill="#d8a640"/>`:'')});
 // pediment + roof slope
 const pt=top;const slope=`M${x+w/2} ${pt-ped}L${x+w/2+d} ${pt-ped-d/2}L${x+w+6+d} ${pt-d/2}L${x+w+6} ${pt}Z`;
 s+=ink(slope,shade(roof,.12),2.4)+`<path d="${slope}" fill="url(#rtile)" opacity=".8"/>`;
 const tri=`M${x-6} ${pt}L${x+w/2} ${pt-ped}L${x+w+6} ${pt}Z`;s+=ink(tri,col,2.6)+`<path d="M${x+w*0.18} ${pt-3}L${x+w/2} ${pt-ped*0.78}L${x+w*0.82} ${pt-3}Z" fill="#000" opacity=".1"/>`;
 // relief figures (abstract)
 for(let i=0;i<5;i++){const fx=x+w*0.3+i*w*0.1,fh=ped*(0.35+0.25*(1-Math.abs(i-2)/2));s+=`<path d="M${f(fx)} ${pt-3}v${f(-fh)}" stroke="#b8a888" stroke-width="4" stroke-linecap="round"/>`;}
 if(gold)s+=`<circle cx="${x+w/2}" cy="${f(pt-ped*0.45)}" r="${f(ped*0.18)}" fill="#e0b04a" stroke="${INK}" stroke-width="1.6"/>`;
 s+=`<path d="M${x-8} ${pt}L${x+w/2} ${pt-ped-3}L${x+w+8} ${pt}" fill="none" stroke="${roof}" stroke-width="4"/><path d="M${x-8} ${pt}L${x+w/2} ${pt-ped-3}L${x+w+8} ${pt}" fill="none" stroke="${INK}" stroke-width="1.4" transform="translate(0 -2.5)"/>`;
 return s;};
const arches=(x0,x1,base,h,n,{col='#cdbb98',ink2=INK,sw=2.4,haze=0}={})=>{const w=x1-x0,aw=w/n;let d=`M${x0} ${base-h}H${x1}V${base}`;for(let i=n-1;i>=0;i--){const ax=x0+i*aw,p=aw*0.16;d+=`H${f(ax+aw-p)}V${f(base-h*0.42)}A${f(aw/2-p)} ${f(aw/2-p)} 0 0 0 ${f(ax+p)} ${f(base-h*0.42)}V${base}`;}d+=`H${x0}Z`;
 let s=`<path d="${d}" fill="${col}"/><path d="${d}" fill="url(#stone)" opacity=".55"/><path d="${d}" fill="url(#topLit)"/>`;
 for(let i=0;i<n;i++){const ax=x0+i*aw,p=aw*0.16;s+=`<path d="M${f(ax+aw-p)} ${base}V${f(base-h*0.42)}A${f(aw/2-p)} ${f(aw/2-p)} 0 0 0 ${f(ax+p)} ${f(base-h*0.42)}" fill="none" stroke="#000" stroke-width="5" opacity=".18" transform="translate(3 0)"/><path d="M${f(ax+aw/2-3)} ${f(base-h*0.42-(aw/2-p))}l3 -5l3 5" fill="${light(col,.2)}" stroke="${ink2}" stroke-width="1.2"/>`;}
 s+=`<path d="${d}" fill="none" stroke="${ink2}" stroke-width="${sw}" stroke-linejoin="round"/><rect x="${x0-3}" y="${base-h-5}" width="${w+6}" height="6" fill="${light(col,.15)}" stroke="${ink2}" stroke-width="${sw*0.8}"/>`;
 if(haze)s+=`<path d="${d}" fill="#dceaf4" opacity="${haze}"/>`;return s;};
const trireme=(x,y,s=1,sail='#e8dcc0',stripe='#b8352b')=>{let o=ink(`M${x-70*s} ${y-14*s}Q${x-20*s} ${y+8*s} ${x+60*s} ${y-6*s}L${x+78*s} ${y-20*s}L${x+70*s} ${y-6*s}Q${x+10*s} ${y+14*s} ${x-62*s} ${y-4*s}Q${x-76*s} ${y-12*s} ${x-84*s} ${y-26*s}Z`,'#5a3420',2.4);
 o+=`<path d="M${x-66*s} ${y-12*s}Q${x} ${y+2*s} ${x+64*s} ${y-8*s}" stroke="#c9945a" stroke-width="${2*s}" fill="none"/><path d="M${x-60*s} ${y-6*s}Q${x} ${y+8*s} ${x+60*s} ${y-2*s}" stroke="#b8352b" stroke-width="${2.4*s}" fill="none"/>`;
 for(let i=0;i<14;i++){const ox=x-50*s+i*8*s;o+=`<path d="M${f(ox)} ${f(y-2*s+Math.abs(i-7)*0.2)}l${f(-6*s)} ${f(16*s)}" stroke="#3a2010" stroke-width="${1.4*s}"/>`;}
 o+=`<circle cx="${x+62*s}" cy="${y-10*s}" r="${2.2*s}" fill="#fff" stroke="${INK}" stroke-width="1"/>`;
 o+=`<path d="M${x} ${y-8*s}V${y-84*s}" stroke="${INK}" stroke-width="${4*s}"/><path d="M${x-34*s} ${y-80*s}H${x+34*s}" stroke="${INK}" stroke-width="${3*s}"/>`;
 const sl=`M${x-32*s} ${y-78*s}H${x+32*s}Q${x+38*s} ${y-50*s} ${x+30*s} ${y-26*s}H${x-30*s}Q${x-38*s} ${y-50*s} ${x-32*s} ${y-78*s}Z`;
 o+=ink(sl,sail,2.2)+`<path d="M${x-12*s} ${y-78*s}V${y-26*s}M${x+12*s} ${y-78*s}V${y-26*s}" stroke="${stripe}" stroke-width="${8*s}" opacity=".9"/><path d="${sl}" fill="url(#fadeDown)" opacity=".6"/><path d="${sl}" fill="none" stroke="${INK}" stroke-width="2.2"/>`;
 return o;};
const villa=(x,base,w,h,seed,o={})=>bld(x,base,w,h,{fill:['#f1e8d6','#ece0c8','#f4ecdc'][seed%3],tex:'plaster',d:o.d??14,sw:o.sw??2.2,roof:'gableFront',roofFill:'#b9583a',roofTex:'rtile',rh:h*0.32,ov:3,wins:{cols:Math.max(1,Math.round(w/26)),rows:h>40?2:1,ww:7,wh:10,padT:8,padB:14,lit:.35,seed,dark:'#4a3a2a',arch:true},haze:o.haze,hazeCol:'#dceaf4',ink:o.ink});

E[2]=()=>{let s='';
 s+=sky(W,H,[[0,'#3f7cc0'],[.45,'#88bce6'],[.75,'#d6e8f2'],[1,'#f1efe6']]);
 s+=sunDisc(240,70,20,'#fffbe8','#fff4c0');
 s+=cloud(380,90,240,{col:'#ffffff',sh:'#b8cce0',lit:'#ffffff',op:.95})+cloud(980,60,300,{col:'#ffffff',sh:'#aec4dc',lit:'#ffffff',op:.9})+cloud(1330,120,200,{col:'#ffffff',sh:'#b8cce0',lit:'#fff',op:.85})+cloud(40,150,150,{col:'#fff',sh:'#c0d2e4',lit:'#fff',op:.8});
 s+=ridge(W,230,50,4,'#9ab4c8',{step:40});s+=ridge(W,262,30,9,'#86a2b4',{step:30});
 s+=haze(W,180,300,'#e6f0f4',.6);
 // aqueduct far-right, two tiers
 s+=arches(900,W+20,300,52,12,{col:'#c9b896',ink2:'#5a5a6a',sw:1.8,haze:.25})+arches(900,W+20,248,34,18,{col:'#cdbd9c',ink2:'#5a5a6a',sw:1.6,haze:.28});
 s+=`<rect x="900" y="208" width="${W-880}" height="8" fill="#c9b896" stroke="#5a5a6a" stroke-width="1.6"/>`;
 // acropolis hill
 const hill=`M240 330 C300 300 330 250 400 236 C460 224 520 228 560 214 L860 214 C910 226 940 250 990 280 C1030 302 1060 316 1110 330Z`;
 s+=`<linearGradient id="hillg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#b8a070"/><stop offset=".5" stop-color="#9a8a5a"/><stop offset="1" stop-color="#7a7448"/></linearGradient>`+ink(hill,'url(#hillg)',2.6)+`<path d="${hill}" fill="url(#block)" opacity=".35"/>`+(()=>{const r=rng(21);let o='';for(let i=0;i<60;i++){const x=300+r()*760,y=232+r()*90;if(y<214+Math.abs(x-710)*0.18)continue;o+=`<ellipse cx="${f(x)}" cy="${f(y)}" rx="${f(6+r()*14)}" ry="${f(2+r()*3)}" fill="${r()<.5?'#6a8a3a':'#d8c090'}" opacity="${f(.35+r()*.3)}"/>`;}return o;})()+`<path d="M640 330 L700 296 L620 270 L700 240 L660 220" fill="none" stroke="#e8d8b0" stroke-width="5" stroke-linejoin="round"/><path d="M640 330 L700 296 L620 270 L700 240 L660 220" fill="none" stroke="${INK}" stroke-width="1.2" stroke-linejoin="round" transform="translate(0 3)"/><path d="M560 214 L860 214 C910 226 940 250 990 280 L980 300 C920 270 880 250 840 240 Z" fill="#000" opacity=".15"/><path d="M400 236 C460 224 520 228 560 214 L600 216 C540 236 470 236 420 250Z" fill="#fff4d8" opacity=".25"/>`;
 for(const [x,y] of [[380,250],[470,242],[930,262],[1000,292],[320,290]])s+=treeRound(x,y,8,'#5a7a3a');
 // temple on top
 s+=temple(570,216,280,134,8,{gold:true});
 s+=cypress(560,216,60)+cypress(860,218,52)+cypress(880,222,44);
 // houses on slopes and below
 let hs='';[[160,330,70,44],[250,322,56,36],[318,300,50,30],[930,300,56,34],[1000,316,64,40],[1080,328,70,46],[1170,332,60,40],[1250,330,70,48],[60,336,80,50]].forEach(([x,b,w,h],i)=>hs+=villa(x,b,w,h,i));
 s+=hs;
 for(const x of[230,300,1150,1240])s+=cypress(x,336,54+(x%20));
 // stoa / colonnade along the quay
 s+=bld(300,348,560,10,{fill:'#e8dfc8',d:18,sw:2.2,shadow:false,tex:'stone',texOp:.3});
 for(let i=0;i<22;i++){const cx=310+i*25;s+=`<rect x="${cx}" y="300" width="8" height="38" fill="#f1ead8" stroke="${INK}" stroke-width="1.6"/><rect x="${cx+5}" y="300" width="3" height="38" fill="#7a6a8a" opacity=".3"/>`;}
 s+=bld(296,300,568,10,{fill:'#efe8d6',d:18,sw:2.2,shadow:false,roof:'gableFront',roofFill:'#b9583a',roofTex:'rtile',rh:12,ov:4});
 // harbor water
 s+=water(348,H,'#3f86b0','#1f4e72',8,'#eaf6ff');
 s+=reflect(`<g>${s.slice(-1)}</g>`,348,0);
 s+=glow(240,360,160,'#fff6d0',.25);
 s+=trireme(1060,380,1.05)+trireme(1380,366,.75,'#e8dcc0','#2e5e9a')+trireme(560,390,.6,'#efe4cc','#2e5e9a');
 // lighthouse on mole right
 s+=ink(`M1490 352h110v10h-110z`,'#a89878',2.2)+bld(1530,352,30,92,{fill:'#e8dcc0',tex:'stone',texOp:.4,d:10,sw:2.2,wins:{cols:1,rows:3,ww:6,wh:9,padT:10,padB:14,lit:1,seed:3}})+glow(1550,250,70,'#ffd060',.9)+ink(`M1528 260h34l-4 -12h-26z`,'#d8a640',2)+`<circle cx="1545" cy="254" r="4" fill="#fff6c0"/>`;
 // foreground quay corner left with olive tree
 s+=ink(`M0 352H300L286 400H0Z`,'#c9b48e',2.4)+`<path d="M0 352H300L286 400H0Z" fill="url(#flag)" opacity=".7"/><rect x="0" y="352" width="300" height="6" fill="#efe2c4" stroke="${INK}" stroke-width="1.6"/>`;
 s+=treeRound(90,370,22,'#6a8a4a',{lit:'#b8d08a'})+pot(200,384,1.8,'#b8643a')+pot(226,388,1.5,'#a0522d');
 s+=vignette(W,H,.3);return s;};

// ================= ERA 3: Medieval =================
const tower2d=(x,base,w,h,{col='#a29a8c',roof='#3f5a8a',rh=null,cren=false,ink2=INK,sw=2.4,flag='#b8352b',seed=1,haze=0}={})=>{const id='tg'+Math.round(x*7+base);const top=base-h;let s=`<linearGradient id="${id}" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="${light(col,.25)}"/><stop offset=".35" stop-color="${col}"/><stop offset="1" stop-color="${shade(col,.45)}"/></linearGradient>`;
 s+=`<rect x="${x}" y="${top}" width="${w}" height="${h}" fill="url(#${id})"/><rect x="${x}" y="${top}" width="${w}" height="${h}" fill="url(#block)" opacity=".45"/>`;
 for(let i=0;i<Math.floor(h/40);i++)s+=`<rect x="${x+w*0.42}" y="${top+16+i*40}" width="${Math.max(3,w*0.12)}" height="${Math.min(14,w*0.4)}" rx="2" fill="${(i+seed)%2?'url(#winLit)':'#2a2018'}" stroke="${ink2}" stroke-width="1.2"/>`;
 if(haze)s+=`<rect x="${x}" y="${top}" width="${w}" height="${h}" fill="#dfe6ea" opacity="${haze}"/>`;
 s+=`<rect x="${x}" y="${top}" width="${w}" height="${h}" fill="none" stroke="${ink2}" stroke-width="${sw}"/>`;
 if(cren){const n=5,mw=(w+8)/n;s+=`<rect x="${x-4}" y="${top-8}" width="${w+8}" height="8" fill="${col}" stroke="${ink2}" stroke-width="${sw*0.8}"/>`;for(let i=0;i<n;i+=2)s+=`<rect x="${f(x-4+i*mw)}" y="${top-16}" width="${f(mw)}" height="9" fill="${col}" stroke="${ink2}" stroke-width="${sw*0.8}"/>`;}
 else{const r=rh??w*1.3;s+=`<path d="M${x-5} ${top}L${x+w/2} ${top-r}L${x+w+5} ${top}Z" fill="${roof}" stroke="${ink2}" stroke-width="${sw}" stroke-linejoin="round"/><path d="M${x+w/2} ${top-r}L${x+w+5} ${top}L${x+w*0.55} ${top}Z" fill="#000" opacity=".3"/><path d="M${x+w/2-1} ${top-r+6}L${x+w*0.12} ${top-2}" stroke="#fff" stroke-width="1.5" opacity=".35"/>`;
  if(haze)s+=`<path d="M${x-5} ${top}L${x+w/2} ${top-r}L${x+w+5} ${top}Z" fill="#dfe6ea" opacity="${haze}"/>`;
  if(flag)s+=`<path d="M${x+w/2} ${top-r}v-18" stroke="${ink2}" stroke-width="2"/>`+`<path d="M${x+w/2+1} ${top-r-18}c6 -2 10 2 16 0v8c-6 2 -10 -2 -16 0z" fill="${flag}" stroke="${ink2}" stroke-width="1.4"/>`;}
 return s;};
const timber=(x,base,w,h,seed,o={})=>bld(x,base,w,h,{fill:['#e8dab4','#e2cfa0','#efe2c0','#d8c49a'][seed%4],tex:'plaster',d:o.d??12,sw:o.sw??2.2,ink:o.ink,roof:'gable',roofFill:['#8a4a36','#5f6b7a','#7a3a2a'][seed%3],roofTex:seed%3==1?'slate':'rtile',rh:w*0.75,ov:3,haze:o.haze,hazeCol:o.hazeCol||'#e0dcc8',
 content:(X,t,ww,hh)=>{let q=`<rect x="${X}" y="${t}" width="${ww}" height="${hh}" fill="none" stroke="#4a2a18" stroke-width="3"/><path d="M${X} ${t+hh*0.5}H${X+ww}" stroke="#4a2a18" stroke-width="2.4"/>`;for(let i=1;i<3;i++)q+=`<path d="M${X+ww*i/3} ${t}V${t+hh}" stroke="#4a2a18" stroke-width="2"/>`;q+=`<path d="M${X} ${t+hh*0.5}L${X+ww/3} ${t}M${X+ww} ${t+hh*0.5}L${X+ww*2/3} ${t}" stroke="#4a2a18" stroke-width="1.6"/>`;return q;},
 wins:{cols:Math.max(1,Math.round(w/22)),rows:2,ww:6,wh:8,padT:hh(h),padB:6,lit:.75,seed,frame:'#2a1a10'},gableContent:(X,t,ww,rh)=>`<rect x="${X+ww/2-3}" y="${t-rh*0.45}" width="6" height="8" fill="url(#winLit)" stroke="${INK}" stroke-width="1.2"/>`});
function hh(h){return Math.max(6,h*0.12);}

E[3]=()=>{let s='';
 s+=sky(W,H,[[0,'#4a6a98'],[.4,'#93a6b8'],[.7,'#e2c8a0'],[.85,'#f2d8a8']]);
 s+=sunDisc(220,220,22,'#fff0c8','#ffd8a0');
 s+=cloud(300,110,280,{col:'#efe0d0',sh:'#8a8aa0',lit:'#fff4e0',op:.9})+cloud(820,70,220,{col:'#e8dcd0',sh:'#8a8aa8',lit:'#fff',op:.85})+cloud(1250,100,320,{col:'#efe0d0',sh:'#8a8aa0',lit:'#fff4e0',op:.9});
 s+=ridge(W,228,40,5,'#7a90a0',{step:36});s+=ridge(W,252,28,8,'#6a8478',{step:28});
 // far forest dots
 { const r=rng(31);let o='';for(let x=0;x<W;x+=9+r()*8){const y=262+Math.sin(x/90)*6+r()*6;o+=`<circle cx="${f(x)}" cy="${f(y)}" r="${f(7+r()*6)}" fill="#55705a"/>`;}s+=o+`<rect x="0" y="262" width="${W}" height="40" fill="#55705a"/>`;}
 s+=haze(W,170,300,'#e8e0cc',.5);
 // castle hill right
 const hill=`M820 340 C900 300 960 230 1060 200 L1360 196 C1440 214 1500 260 1600 300 L1600 340Z`;
 s+=`<linearGradient id="h3" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8a9a6a"/><stop offset="1" stop-color="#5a6a44"/></linearGradient>`+ink(hill,'url(#h3)',2.6)+`<path d="M1060 200 C1000 220 960 260 940 300 L980 310 C1000 270 1040 230 1100 210Z" fill="#a89a7a" opacity=".6"/><path d="M1360 196 C1440 214 1500 260 1600 300 L1600 330 C1500 300 1440 250 1340 220Z" fill="#000" opacity=".15"/>`;
 // castle
 const cb=206;let cs='';
 cs+=tower2d(1080,cb,34,96,{seed:1})+tower2d(1330,cb,34,90,{seed:2});
 cs+=bld(1110,cb,220,58,{fill:'#a29a8c',tex:'block',d:20,cren:22,content:(X,t,w,h)=>`<path d="M${X+w/2-18} ${t+h}V${t+h-26}a18 18 0 0 1 36 0V${t+h}Z" fill="#1a120c" stroke="${INK}" stroke-width="2.4"/>`+Array.from({length:5},(_,i)=>`<path d="M${X+w/2-14+i*7} ${t+h-36}V${t+h}" stroke="#3a3530" stroke-width="2"/>`).join(''),wins:{cols:6,rows:1,ww:5,wh:10,padT:12,lit:.6,seed:4}});
 cs+=bld(1170,cb-58,90,88,{fill:'#aaa294',tex:'block',d:26,cren:15,wins:{cols:3,rows:2,ww:7,wh:14,padT:14,padB:12,lit:.8,seed:7,arch:true}});
 cs+=tower2d(1200,cb-146,30,30,{seed:3,rh:40})+`<path d="M1260 ${cb-146}v-34" stroke="${INK}" stroke-width="3"/><path d="M1261 ${cb-180}c10 -3 16 3 26 0v14c-10 3 -16 -3 -26 0z" fill="#b8352b" stroke="${INK}" stroke-width="1.8"/>`;
 cs+=tower2d(1150,cb+4,30,72,{seed:5})+tower2d(1290,cb+4,30,70,{seed:6});
 s+=`<g transform="translate(0 16)">${cs}</g>`;
 // town houses climbing the hill + lower town
 let town='';const tr=rng(5);[[900,318],[950,300],[1000,282],[1040,262],[1380,250],[1430,272],[1480,290],[1530,300]].forEach(([x,b],i)=>town+=timber(x,b,38+tr()*12,34+tr()*12,i+3));
 s+=town;
 // cathedral left-centre
 const cx=420,cbs=322;
 s+=bld(cx+130,cbs,250,96,{fill:'#c8bca4',tex:'block',d:30,roof:'gableFront',roofFill:'#4f5866',roofTex:'slate',rh:46,ov:4,content:(X,t,w,h)=>{let q='';for(let i=0;i<6;i++){const bx=X+14+i*40;q+=`<path d="M${bx} ${t+h}V${t+30}a9 9 0 0 1 18 0V${t+h-10}" fill="url(#winLit)" stroke="${INK}" stroke-width="1.8"/><path d="M${bx+9} ${t+22}v${h-30}" stroke="${INK}" stroke-width="1" opacity=".6"/><rect x="${bx+26}" y="${t+6}" width="8" height="${h-6}" fill="#000" opacity=".15"/>`;}return q;}});
 s+=bld(cx,cbs,130,150,{fill:'#d0c4ac',tex:'block',d:24,content:(X,t,w,h)=>`<circle cx="${X+w/2}" cy="${t+46}" r="22" fill="#2a1a14" stroke="${INK}" stroke-width="2.4"/><circle cx="${X+w/2}" cy="${t+46}" r="18" fill="url(#winLit)"/>`+Array.from({length:8},(_,i)=>`<path d="M${X+w/2} ${t+46}l${f(18*Math.cos(i*Math.PI/4))} ${f(18*Math.sin(i*Math.PI/4))}" stroke="${INK}" stroke-width="1.6"/>`).join('')+`<circle cx="${X+w/2}" cy="${t+46}" r="5" fill="#d84a3a" stroke="${INK}" stroke-width="1.2"/><path d="M${X+w/2-20} ${t+h}V${t+h-38}a20 20 0 0 1 40 0V${t+h}Z" fill="#3a2414" stroke="${INK}" stroke-width="2.4"/><path d="M${X+w/2-24} ${t+h-38}a24 24 0 0 1 48 0" fill="none" stroke="#e8dcc0" stroke-width="3"/>`});
 s+=bld(cx-14,cbs,34,190,{fill:'#d0c4ac',tex:'block',d:12,roof:'none',wins:{cols:1,rows:4,ww:7,wh:18,padT:24,padB:20,lit:.7,seed:9,arch:true}})+spire(cx+3+6,cbs-190,46,110,'#4f5866');
 s+=bld(cx+110,cbs,34,190,{fill:'#d0c4ac',tex:'block',d:12,roof:'none',wins:{cols:1,rows:4,ww:7,wh:18,padT:24,padB:20,lit:.7,seed:10,arch:true}})+spire(cx+127+6,cbs-190,46,110,'#4f5866');
 s+=`<path d="M${cx+3+6} ${cbs-300}v-16M${cx+3} ${cbs-310}h12M${cx+133} ${cbs-300}v-16M${cx+127} ${cbs-310}h12" stroke="#d8a640" stroke-width="2.6"/>`;
 // lower town in front (left & centre)
 let low='';const lr=rng(9);[[30,330],[80,334],[140,328],[200,336],[262,330],[690,334],[740,330],[800,336],[860,338]].forEach(([x,b],i)=>low+=timber(x,b,42+lr()*16,40+lr()*16,i));
 s+=low;
 // town wall across front
 s+=bld(0,352,W,22,{fill:'#9a9284',tex:'block',d:0,cren:14,shadow:false,rim:false});
 s+=tower2d(560,356,40,60,{cren:true})+tower2d(1000,356,40,60,{cren:true})+tower2d(260,356,36,54,{cren:true})+tower2d(1360,356,40,58,{cren:true});
 // gate in wall
 s+=ink(`M760 352V320a24 24 0 0 1 48 0V352Z`,'#2a1a10',2.4)+`<path d="M766 352V322a18 18 0 0 1 36 0V352Z" fill="url(#winLit)" opacity=".5"/>`;
 // foreground meadow + road
 s+=`<rect x="0" y="352" width="${W}" height="48" fill="#5a7040"/><path d="M0 352H${W}" stroke="${INK}" stroke-width="2.4"/>`+ink(`M760 352L808 352L900 400L660 400Z`,'#b8a078',2)+`<path d="M760 352L808 352L900 400L660 400Z" fill="url(#cobble)" opacity=".6"/>`;
 { const r=rng(41);let o='';for(let i=0;i<140;i++){const x=r()*W,y=358+r()*40;o+=`<path d="M${f(x)} ${f(y)}l${f(-1+r()*2)} ${f(-4-r()*5)}" stroke="${r()<.5?'#7a9a54':'#3a5030'}" stroke-width="1.4"/>`;}s+=o;}
 s+=treeRound(80,400,26,'#3f6a3a')+treeRound(1510,400,30,'#3f6a3a')+treeRound(1440,398,18,'#4f7a3a')+pine(170,398,70,'#2a4a3a');
 // wooden fence
 for(let x=980;x<1380;x+=26)s+=`<path d="M${x} 392v-20" stroke="${INK}" stroke-width="4"/><path d="M${x} 392v-20" stroke="#8a6440" stroke-width="2"/>`;s+=`<path d="M980 376H1380M980 386H1380" stroke="${INK}" stroke-width="4"/><path d="M980 376H1380M980 386H1380" stroke="#a87c4c" stroke-width="2"/>`;
 s+=vignette(W,H,.35);return s;};

// ================= ERA 4: Early Modern =================
const tallShip=(x,y,s=1,{hull='#4a2a1a',band='#c9a640',sail='#efe6d0',flag='#2e4f8a'}={})=>{let o='';
 const h=`M${x-90*s} ${y-30*s}L${x+70*s} ${y-30*s}L${x+96*s} ${y-44*s}L${x+84*s} ${y-12*s}Q${x} ${y+6*s} ${x-80*s} ${y-6*s}L${x-96*s} ${y-40*s}Z`;
 o+=ink(h,hull,2.6)+`<path d="M${x-88*s} ${y-24*s}L${x+80*s} ${y-24*s}" stroke="${band}" stroke-width="${3*s}"/>`;for(let i=0;i<9;i++)o+=`<rect x="${x-70*s+i*16*s}" y="${y-20*s}" width="${5*s}" height="${5*s}" fill="#ffd36b" stroke="${INK}" stroke-width="1"/>`;
 o+=ink(`M${x-96*s} ${y-40*s}L${x-110*s} ${y-58*s}L${x-74*s} ${y-58*s}L${x-70*s} ${y-30*s}Z`,shade(hull,.1),2);
 for(const [mx,mh] of [[-50,170],[0,190],[46,150]]){const X=x+mx*s;o+=`<path d="M${X} ${y-30*s}V${y-(30+mh)*s}" stroke="${INK}" stroke-width="${4*s}"/>`;
  for(let k=0;k<3;k++){const sy=y-(40+k*mh*0.3)*s,sw=(34-k*7)*s,sh=mh*0.24*s;const d=`M${X-sw} ${sy-sh}Q${X} ${sy-sh-6*s} ${X+sw} ${sy-sh}Q${X+sw+6*s} ${sy-sh*0.5} ${X+sw} ${sy}Q${X} ${sy+8*s} ${X-sw} ${sy}Q${X-sw+4*s} ${sy-sh*0.5} ${X-sw} ${sy-sh}Z`;o+=ink(d,sail,1.8)+`<path d="${d}" fill="url(#fadeDown)" opacity=".5"/><path d="M${X-sw+4*s} ${sy-sh+3*s}Q${X-sw*0.4} ${sy-sh*0.5} ${X-sw+3*s} ${sy-4*s}" stroke="#fff" stroke-width="1.5" opacity=".6" fill="none"/>`;}
  o+=`<path d="M${X} ${y-(30+mh)*s}v${-10*s}" stroke="${INK}" stroke-width="2"/><path d="M${X+1} ${y-(40+mh)*s}l${16*s} ${3*s}l${-16*s} ${3*s}z" fill="${flag}" stroke="${INK}" stroke-width="1.2"/>`;}
 o+=`<path d="M${x-110*s} ${y-58*s}L${x-50*s} ${y-200*s}L${x} ${y-220*s}L${x+46*s} ${y-180*s}L${x+92*s} ${y-44*s}" fill="none" stroke="${INK}" stroke-width="1" opacity=".7"/>`;
 return o;};
const canalHouse=(x,base,w,h,seed,o={})=>{const cols=['#8e4a38','#6a4a3a','#a85a3a','#5a5048','#8a6a4a'];const fill=cols[seed%5];let s=bld(x,base,w,h,{fill,tex:'brick',d:o.d??10,sw:2.2,roof:'none',haze:o.haze,hazeCol:o.hazeCol,wins:{cols:2,rows:Math.max(2,Math.round(h/30)),ww:8,wh:12,padT:10,padB:22,lit:.75,seed,frame:'#efe6d0',fw:1.8,mull:true},content:(X,t,ww,hh)=>`<rect x="${X+ww/2-5}" y="${t+hh-18}" width="10" height="18" fill="#2a2a3a" stroke="${INK}" stroke-width="1.4"/>`});
 // curved/stepped gable
 const t=base-h;const g=seed%2?`M${x} ${t}L${x} ${t-8}L${x+w*0.2} ${t-8}L${x+w*0.2} ${t-18}L${x+w*0.35} ${t-18}L${x+w*0.35} ${t-28}L${x+w*0.65} ${t-28}L${x+w*0.65} ${t-18}L${x+w*0.8} ${t-18}L${x+w*0.8} ${t-8}L${x+w} ${t-8}L${x+w} ${t}Z`:`M${x} ${t}Q${x+w*0.1} ${t-4} ${x+w*0.22} ${t-12}Q${x+w*0.3} ${t-26} ${x+w*0.4} ${t-30}H${x+w*0.6}Q${x+w*0.7} ${t-26} ${x+w*0.78} ${t-12}Q${x+w*0.9} ${t-4} ${x+w} ${t}Z`;
 s+=`<path d="${g}" fill="${fill}"/><path d="${g}" fill="url(#brick)" opacity=".7"/><path d="${g}" fill="url(#topLit)"/>`+(o.haze?`<path d="${g}" fill="${o.hazeCol}" opacity="${o.haze}"/>`:'')+`<path d="${g}" fill="none" stroke="${INK}" stroke-width="2.2" stroke-linejoin="round"/><rect x="${x+w/2-3}" y="${t-22}" width="6" height="8" fill="url(#winLit)" stroke="${INK}" stroke-width="1.2"/><path d="M${x} ${t-1}H${x+w}" stroke="#efe6d0" stroke-width="2"/>`;
 return s;};
E[4]=()=>{let s='';
 s+=sky(W,H,[[0,'#3a4f8a'],[.35,'#a07aa0'],[.6,'#f0a07a'],[.82,'#fcd49a']]);
 s+=sunDisc(300,250,30,'#fff0c0','#ffb070');
 s+=cloud(120,110,300,{col:'#f4b8a0',sh:'#8a5a80',lit:'#ffe0c0',op:.9})+cloud(700,70,260,{col:'#f0a890',sh:'#7a4a7a',lit:'#ffd8b8',op:.85})+cloud(1150,120,340,{col:'#f4b8a0',sh:'#8a5a80',lit:'#ffe0c0',op:.9});
 s+=ridge(W,262,24,6,'#9a7a90',{step:34});
 s+=haze(W,200,300,'#f8c8a0',.5);
 // far town skyline with domes/spires
 { const r=rng(17);let o='';for(let x=0;x<W;x+=30+r()*30){const h=20+r()*30;o+=`<rect x="${f(x)}" y="${f(296-h)}" width="${f(26+r()*20)}" height="${f(h)}" fill="#8a6a80"/>`;if(r()<.15)o+=`<path d="M${f(x+12)} ${f(296-h)}l6 -30l6 30z" fill="#8a6a80"/>`;if(r()<.12)o+=`<circle cx="${f(x+18)}" cy="${f(296-h)}" r="14" fill="#8a6a80"/>`;}s+=o;}
 s+=haze(W,240,300,'#f8c8a0',.3);
 // left: canal houses
 let ch='';const cr=rng(23);for(let i=0;i<9;i++){const x=10+i*52;ch+=canalHouse(x,330,46,70+cr()*40,i);}s+=ch;
 // palace centre
 const pc=820,pb=330;
 s+=bld(pc-310,pb,140,74,{fill:'#ead9b8',tex:'stone',texOp:.35,d:24,roof:'hip',roofFill:'#4f6a7a',roofTex:'slate',rh:20,wins:{cols:5,rows:2,ww:10,wh:18,padT:10,padB:12,lit:.85,seed:5,arch:true,mull:true,frame:'#f8f0e0'}});
 s+=bld(pc+170,pb,140,74,{fill:'#ead9b8',tex:'stone',texOp:.35,d:24,roof:'hip',roofFill:'#4f6a7a',roofTex:'slate',rh:20,wins:{cols:5,rows:2,ww:10,wh:18,padT:10,padB:12,lit:.85,seed:6,arch:true,mull:true,frame:'#f8f0e0'}});
 s+=bld(pc-180,pb,360,96,{fill:'#efe0c2',tex:'stone',texOp:.35,d:36,roof:'hip',roofFill:'#4f6a7a',roofTex:'slate',rh:22,wins:{cols:11,rows:2,ww:11,wh:22,padT:12,padB:14,lit:.9,seed:7,arch:true,mull:true,frame:'#f8f0e0'},content:(X,t,w,h)=>`<rect x="${X}" y="${t+h*0.5-2}" width="${w}" height="4" fill="#d8c8a0"/>`});
 // central pavilion + dome
 s+=bld(pc-60,pb,120,130,{fill:'#f4e8cc',tex:'stone',texOp:.3,d:20,content:(X,t,w,h)=>{let q='';for(let i=0;i<4;i++)q+=`<rect x="${X+10+i*30}" y="${t+24}" width="9" height="${h-30}" fill="#fffaf0" stroke="${INK}" stroke-width="1.6"/><rect x="${X+15+i*30}" y="${t+24}" width="4" height="${h-30}" fill="#000" opacity=".12"/>`;q+=`<path d="M${X+w/2-14} ${t+h}V${t+h-34}a14 14 0 0 1 28 0V${t+h}Z" fill="url(#winLit)" stroke="${INK}" stroke-width="2"/><path d="M${X} ${t+22}L${X+w/2} ${t-2}L${X+w} ${t+22}Z" fill="#f8f0dc" stroke="${INK}" stroke-width="2"/><circle cx="${X+w/2}" cy="${t+14}" r="5" fill="#d8a640" stroke="${INK}" stroke-width="1.2"/>`;return q;}});
 s+=bld(pc-34,pb-130,68,30,{fill:'#f4e8cc',d:14,roof:'none',wins:{cols:4,rows:1,ww:6,wh:14,padT:8,lit:1,seed:2,arch:true}})+dome(pc+7,pb-160,48,'#5f8f9a',{h:56,ribs:5});
 // balustrade
 s+=`<rect x="${pc-180}" y="${pb-100}" width="360" height="6" fill="#f8f0dc" stroke="${INK}" stroke-width="1.6"/>`;for(let i=0;i<9;i++)s+=`<path d="M${pc-170+i*42} ${pb-100}v-14" stroke="${INK}" stroke-width="3"/><path d="M${pc-170+i*42} ${pb-104}v-10" stroke="#e8c870" stroke-width="2"/><circle cx="${pc-170+i*42}" cy="${pb-116}" r="3" fill="#e8c870" stroke="${INK}" stroke-width="1"/>`;
 // gardens & fountain
 s+=`<path d="M440 330H1180L1220 360H400Z" fill="#6a8a4a" stroke="${INK}" stroke-width="2"/><path d="M780 330H860L900 360H740Z" fill="#d8c8a0" stroke="${INK}" stroke-width="1.6"/>`;
 for(const x of[470,540,610,680,950,1020,1090,1160])s+=ink(`M${x-8} 346L${x} 320L${x+8} 346Z`,'#3f6a3a',2)+`<path d="M${x} 320L${x+8} 346H${x+2}Z" fill="#000" opacity=".25"/>`;
 s+=ink(`M786 352a34 9 0 0 0 68 0a34 9 0 0 0 -68 0Z`,'#5aa0c0',2)+`<path d="M820 350v-26" stroke="#bfe8ff" stroke-width="4"/><path d="M820 326q-14 4 -18 22M820 326q14 4 18 22" stroke="#d8f4ff" stroke-width="2" fill="none"/>`;
 // harbor right
 s+=water(352,H,'#6a7aa8','#2a3a68',4,'#ffd8b0');
 s+=glow(300,360,200,'#ffc890',.3);
 // quay houses right
 let qh='';for(let i=0;i<7;i++)qh+=canalHouse(1230+i*52,342,46,60+((i*37)%30),i+3,{haze:.12,hazeCol:'#f8c8a0'});s+=qh;
 s+=`<rect x="0" y="342" width="${W}" height="12" fill="#a89478" stroke="${INK}" stroke-width="2"/><rect x="0" y="342" width="${W}" height="12" fill="url(#block)" opacity=".5"/>`;
 s+=tallShip(1250,392,.95)+tallShip(1490,382,.72,{hull:'#5a3020',flag:'#b8352b'})+tallShip(150,396,.6,{flag:'#b8352b'});
 s+=reflect(tallShip(1250,392,.95),392,.12);
 s+=vignette(W,H,.35);return s;};

// ================= ERA 5: Industrial =================
const chimney=(x,base,w,h,{col='#7a3a2a',smoke=true,seed=1,dark=false,ink2=INK,sw=2.2}={})=>{let s=`<path d="M${x} ${base}L${x+w*0.12} ${base-h}H${x+w*0.88}L${x+w} ${base}Z" fill="${col}"/><path d="M${x} ${base}L${x+w*0.12} ${base-h}H${x+w*0.88}L${x+w} ${base}Z" fill="url(#brick)" opacity=".7"/><path d="M${x+w*0.55} ${base}L${x+w*0.6} ${base-h}H${x+w*0.88}L${x+w} ${base}Z" fill="#000" opacity=".25"/><path d="M${x} ${base}L${x+w*0.12} ${base-h}H${x+w*0.88}L${x+w} ${base}Z" fill="none" stroke="${ink2}" stroke-width="${sw}"/><rect x="${x+w*0.04}" y="${base-h-6}" width="${w*0.92}" height="7" fill="${light(col,.1)}" stroke="${ink2}" stroke-width="${sw*0.8}"/><rect x="${x+w*0.08}" y="${base-h*0.3}" width="${w*0.84}" height="4" fill="#d8b890" opacity=".5"/>`;
 if(smoke)s=smokePlume(x+w/2,base-h-14,w/18,{col:dark?'#5a4a48':'#8a7a74',lit:'#f0b070',n:7,drift:2.2,seed})+s;return s;};
const sawFactory=(x,base,w,h,n,seed,o={})=>{let s=bld(x,base,w,h,{fill:o.fill||'#9a4e38',tex:'brick',d:o.d??22,sw:o.sw??2.4,roof:'none',ink:o.ink,haze:o.haze,hazeCol:o.hazeCol,wins:{cols:Math.round(w/22),rows:Math.max(1,Math.round(h/34)),ww:10,wh:16,padT:12,padB:12,lit:.85,seed,arch:true,frame:'#2a1a14',mull:true}});
 const tw=w/n;for(let i=0;i<n;i++){const tx=x+i*tw;const d=`M${tx} ${base-h}L${tx} ${base-h-22}L${tx+tw} ${base-h}Z`;s+=`<path d="${d}" fill="url(#winLit)" opacity=".9"/><path d="M${tx} ${base-h-22}L${tx+tw} ${base-h}L${tx+tw} ${base-h-2}Z" fill="#5a5a62"/><path d="${d}" fill="none" stroke="${o.ink||INK}" stroke-width="2"/>`;}
 if(o.haze)s+=`<path d="M${x} ${base-h}h${w}v-22h${-w}z" fill="${o.hazeCol}" opacity="${o.haze*0.8}"/>`;return s;};
E[5]=()=>{let s='';
 s+=sky(W,H,[[0,'#3a2a3a'],[.3,'#8a4a3a'],[.55,'#d8703a'],[.78,'#f4a850'],[.9,'#f8c878']]);
 s+=sunDisc(420,236,34,'#ffe0a0','#ff9050');
 // smoky cloud bands
 s+=`<g opacity=".7">`+cloud(-40,110,420,{col:'#7a4a44',sh:'#4a2a30',lit:'#e08a5a'})+cloud(520,80,380,{col:'#6a3a3a',sh:'#3a2028',lit:'#d07a50'})+cloud(1000,130,460,{col:'#7a4a44',sh:'#4a2a30',lit:'#e08a5a'})+`</g>`;
 // far factory silhouettes
 { const r=rng(51);let o='';for(let x=0;x<W;x+=40+r()*40){const h=20+r()*30,w=40+r()*50;o+=`<rect x="${f(x)}" y="${f(286-h)}" width="${f(w)}" height="${f(h)}" fill="#8a4a3c"/>`;if(r()<.5){const cx=x+r()*w,ch=50+r()*50;o+=`<rect x="${f(cx)}" y="${f(286-h-ch)}" width="7" height="${f(ch)}" fill="#8a4a3c"/>`+smokePlume(cx+3,286-h-ch-6,.5,{col:'#9a6a5a',lit:'#e8a070',n:5,op:.6,seed:Math.round(x)});}}s+=o;}
 s+=haze(W,180,292,'#f0a060',.45);
 // mid factories
 s+=chimney(250,300,22,170,{seed:2})+chimney(640,300,26,200,{seed:3})+chimney(1180,300,24,180,{seed:4})+chimney(1420,300,20,150,{seed:5});
 s+=sawFactory(40,300,260,70,6,1,{haze:.12,hazeCol:'#f0a060'})+sawFactory(520,300,220,90,5,2,{fill:'#8a4434',haze:.1,hazeCol:'#f0a060'})+sawFactory(1060,300,260,76,6,3,{haze:.12,hazeCol:'#f0a060'});
 // gasometer
 { const gx=870,gb=300,gw=130,gh=90;s+=`<linearGradient id="gas" x1="0" x2="1"><stop offset="0" stop-color="#8a8a80"/><stop offset=".3" stop-color="#6a6a64"/><stop offset="1" stop-color="#3a3a3a"/></linearGradient><rect x="${gx}" y="${gb-gh}" width="${gw}" height="${gh}" fill="url(#gas)" stroke="${INK}" stroke-width="2.2"/><ellipse cx="${gx+gw/2}" cy="${gb-gh}" rx="${gw/2}" ry="8" fill="#7a7a72" stroke="${INK}" stroke-width="2"/>`;
  for(let i=0;i<=6;i++)s+=`<path d="M${gx-6+i*(gw+12)/6} ${gb}V${gb-gh-20}" stroke="${INK}" stroke-width="4"/><path d="M${gx-6+i*(gw+12)/6} ${gb}V${gb-gh-20}" stroke="#6a4a3a" stroke-width="2"/>`;
  for(const y of[gb-30,gb-60,gb-gh-18])s+=`<path d="M${gx-6} ${y}H${gx+gw+6}" stroke="${INK}" stroke-width="3"/>`;
  for(let i=0;i<6;i++)s+=`<path d="M${gx-6+i*(gw+12)/6} ${gb-30}L${gx-6+(i+1)*(gw+12)/6} ${gb-60}" stroke="${INK}" stroke-width="1.6"/>`;}
 // warehouse row nearer
 let wh='';[[0,140,60],[150,120,70],[290,160,56],[760,110,64],[1340,150,68],[1500,110,58]].forEach(([x,w,h],i)=>wh+=bld(x,322,w,h,{fill:['#9a5038','#8a4a36','#a85a40'][i%3],tex:'brick',d:16,roof:'gableFront',roofFill:'#4a4a52',roofTex:'slate',rh:16,wins:{cols:Math.round(w/24),rows:1,ww:10,wh:14,padT:14,lit:.85,seed:i+60,arch:true,frame:'#2a1a14'}}));s+=wh;
 // river
 s+=water(330,H,'#a8603a','#3a2a30',6,'#ffd090');
 s+=glow(420,340,220,'#ffb060',.35);
 // iron truss bridge
 const by=300;
 for(const px of[180,620,1060,1500])s+=bld(px-18,400,36,92,{fill:'#8a7a6a',tex:'block',d:10,sw:2.4,roof:'none'});
 s+=`<rect x="0" y="${by}" width="${W}" height="12" fill="#3a3a40" stroke="${INK}" stroke-width="2.4"/>`;
 const truss=(x0,x1)=>{let o=`<path d="M${x0} ${by}Q${(x0+x1)/2} ${by-120} ${x1} ${by}" fill="none" stroke="${INK}" stroke-width="8"/><path d="M${x0} ${by}Q${(x0+x1)/2} ${by-120} ${x1} ${by}" fill="none" stroke="#5a5a64" stroke-width="4"/>`;const n=12;for(let i=1;i<n;i++){const t=i/n,x=x0+(x1-x0)*t,yy=by-60*4*t*(1-t);o+=`<path d="M${f(x)} ${by}V${f(yy)}" stroke="${INK}" stroke-width="3"/><path d="M${f(x)} ${by}V${f(yy)}" stroke="#6a6a74" stroke-width="1.4"/>`;if(i<n-1){const x2=x0+(x1-x0)*(i+1)/n,y2=by-60*4*((i+1)/n)*(1-(i+1)/n);o+=`<path d="M${f(x)} ${f(yy)}L${f(x2)} ${by}" stroke="${INK}" stroke-width="1.8"/>`;}}return o;};
 // train (behind trusses partly)
 const tx=760,ty=by;let tr='';
 tr+=smokePlume(tx+150,ty-64,1.2,{col:'#e8e0d8',lit:'#ffe0b0',n:7,drift:-2.6,op:.9,seed:9});
 for(let i=0;i<4;i++){const cx=tx-120-i*96;tr+=ink(`M${cx} ${ty-4}h86v-34h-86z`,i%2?'#6a2a24':'#7a3a2a',2.4)+`<rect x="${cx}" y="${ty-38}" width="86" height="6" fill="#3a2a24"/>`+[0,1,2,3].map(k=>`<rect x="${cx+8+k*20}" y="${ty-30}" width="12" height="12" fill="url(#winLit)" stroke="${INK}" stroke-width="1.4"/>`).join('')+ink(`M${cx-2} ${ty-38}q45 -10 90 0z`,'#3a3a40',1.8);}
 tr+=ink(`M${tx} ${ty-4}h120v-30h-120z`,'#2a2a30',2.4)+`<rect x="${tx}" y="${ty-34}" width="120" height="30" fill="url(#steelH)" opacity=".25"/>`;
 tr+=ink(`M${tx+10} ${ty-30}h94a14 14 0 0 1 0 -26h-94z`,'#3a3a44',2.4)+`<path d="M${tx+14} ${ty-50}h86" stroke="#c9a640" stroke-width="2"/>`;
 tr+=ink(`M${tx-2} ${ty-34}h40v-34h-40z`,'#3a2a24',2.4)+`<rect x="${tx+6}" y="${ty-62}" width="14" height="14" fill="url(#winLit)" stroke="${INK}" stroke-width="1.4"/>`+ink(`M${tx-6} ${ty-68}h48v-6h-48z`,'#2a2a30',1.8);
 tr+=ink(`M${tx+86} ${ty-56}l-3 -20h18l-3 20z`,'#2a2a30',2.2)+ink(`M${tx+80} ${ty-76}h24v-5h-24z`,'#c9a640',1.6)+ink(`M${tx+120} ${ty-4}l18 0l-8 -14h-10z`,'#c0392b',2)+`<circle cx="${tx+116}" cy="${ty-44}" r="6" fill="#fff6c0" stroke="${INK}" stroke-width="2"/>`+glow(tx+140,ty-44,40,'#fff0b0',.6);
 for(const k of[16,44,72,100])tr+=`<circle cx="${tx+k}" cy="${ty-2}" r="9" fill="#2a2a30" stroke="${INK}" stroke-width="2"/><circle cx="${tx+k}" cy="${ty-2}" r="3" fill="#c0392b"/>`;
 s+=tr+truss(180,620)+truss(620,1060)+truss(1060,1500)+truss(-260,180)+truss(1500,1940);
 s+=reflect(`<rect x="0" y="${by}" width="${W}" height="12" fill="#3a3a40"/>`,330,.3);
 // foreground embankment with lamps
 s+=ink(`M0 372L520 366L560 400H0Z`,'#5a3a30',2.4)+`<path d="M0 372L520 366L560 400H0Z" fill="url(#brick)" opacity=".6"/>`+ink(`M${W} 368L1180 364L1150 400H${W}Z`,'#5a3a30',2.4)+`<path d="M${W} 368L1180 364L1150 400H${W}Z" fill="url(#brick)" opacity=".6"/>`;
 for(const x of[120,320,1280,1480])s+=glow(x,330,40,'#ffd070',.7)+`<path d="M${x} 372V336" stroke="${INK}" stroke-width="5"/><path d="M${x} 372V336" stroke="#3a3a40" stroke-width="2.4"/>`+ink(`M${x-6} 336h12l-2 -12h-8z`,'#ffe08a',2)+ink(`M${x-8} 324h16l-8 -6z`,'#2a2a30',1.8);
 s+=vignette(W,H,.4);return s;};

// ================= ERA 6: Modern (night) =================
const car=(x,y,dir,col,s=1)=>{let o=ink(`M${x-22*s} ${y}v-10q0 -4 6 -5l8 -8h${18*s}l10 8q8 1 8 5v10z`,col,2)+`<path d="M${x-10*s} ${y-15}l5 -6h${12*s}l6 6z" fill="#9fc6dc" stroke="${INK}" stroke-width="1.2"/>`+`<circle cx="${x-12*s}" cy="${y}" r="${4*s}" fill="#1a1a1e" stroke="${INK}" stroke-width="1.4"/><circle cx="${x+14*s}" cy="${y}" r="${4*s}" fill="#1a1a1e" stroke="${INK}" stroke-width="1.4"/>`;
 if(dir>0)o+=`<circle cx="${x+23*s}" cy="${y-7}" r="2.4" fill="#fffbe0"/><circle cx="${x-23*s}" cy="${y-7}" r="2" fill="#ff3a2a"/>`;
 else o+=`<circle cx="${x-23*s}" cy="${y-7}" r="2.4" fill="#fffbe0"/><circle cx="${x+23*s}" cy="${y-7}" r="2" fill="#ff3a2a"/>`;
 return o;};
const streetLamp=(x,base,h=70,col='#ffd890')=>glow(x+10,base-h+2,46,col,.55)+`<path d="M${x} ${base}V${base-h}q0 -6 10 -6h4" stroke="${INK}" stroke-width="5" fill="none"/><path d="M${x} ${base}V${base-h}q0 -6 10 -6h4" stroke="#3a3e48" stroke-width="2.4" fill="none"/>`+ink(`M${x+8} ${base-h-4}h14l-3 6h-8z`,col,1.6);
E[6]=()=>{let s='';
 s+=sky(W,H,[[0,'#070d24'],[.45,'#16224a'],[.75,'#2c3a6a'],[.9,'#4a4a78']]);
 s+=stars(W,H,160,6,220)+glow(1380,70,120,'#bcd0ff',.35)+`<circle cx="1380" cy="70" r="26" fill="#eef2ff"/><circle cx="1372" cy="64" r="5" fill="#cfd6ee"/><circle cx="1390" cy="78" r="4" fill="#d6dcf2"/>`;
 s+=cloud(200,120,300,{col:'#2a3660',sh:'#141c3a',lit:'#4a5a8a',op:.7})+cloud(1000,90,260,{col:'#2a3660',sh:'#141c3a',lit:'#5a6a9a',op:.6});
 // far skyline
 { const r=rng(61);let o='';for(let x=0;x<W;x+=26+r()*30){const h=40+r()*90,w=26+r()*34;o+=`<rect x="${f(x)}" y="${f(300-h)}" width="${f(w)}" height="${f(h)}" fill="#1e2a4e"/>`;for(let k=0;k<h/9;k++)for(let j=0;j<w/8;j++)if(r()<.22)o+=`<rect x="${f(x+3+j*8)}" y="${f(300-h+4+k*9)}" width="3" height="4" fill="#ffd890" opacity="${f(.4+r()*.5)}"/>`;}s+=o;}
 s+=haze(W,220,310,'#2c3a6a',.5);
 // apartment blocks mid
 const block=(x,base,w,h,seed,col='#5a6278')=>bld(x,base,w,h,{fill:col,tex:'concrete',texOp:.5,d:20,sw:2.2,ink:'#0a0a18',rimCol:'#ffd890',rimOp:.35,wins:{cols:Math.round(w/16),rows:Math.round(h/18),ww:8,wh:9,padT:10,padB:10,lit:.5,seed,frame:'#0a0a18',dark:'#1a2038'}});
 s+=block(30,320,110,150,1)+block(150,320,90,110,2,'#4e566c')+block(250,320,120,170,3,'#5e6680')+block(1170,320,110,160,4,'#5e6680')+block(1290,320,100,120,5,'#4e566c')+block(1400,320,120,180,6)+block(1530,320,80,110,7,'#4e566c');
 // neon billboard on a roof
 s+=`<rect x="262" y="104" width="96" height="44" rx="4" fill="#141830" stroke="${INK}" stroke-width="2.4"/><rect x="268" y="110" width="84" height="32" rx="3" fill="none" stroke="#ff4a8a" stroke-width="2.4" filter="url(#glow)"/><circle cx="296" cy="126" r="9" fill="none" stroke="#4ae0ff" stroke-width="2.4" filter="url(#glow)"/><path d="M312 118h28M312 126h22M312 134h26" stroke="#ffd36b" stroke-width="2.4" filter="url(#glow)"/><path d="M280 148v-0M300 148v8M320 148v8" stroke="${INK}" stroke-width="3"/>`;
 // parliament
 const pc=790,pb=320;
 s+=glow(pc,200,320,'#ffb860',.22);
 s+=bld(pc-330,pb,200,80,{fill:'#d8ccb0',tex:'stone',texOp:.3,d:30,roof:'flat',topFill:'#a89a80',wins:{cols:9,rows:2,ww:9,wh:18,padT:10,padB:10,lit:.9,seed:8,arch:true,mull:true,frame:'#f0e6d0'}});
 s+=bld(pc+130,pb,200,80,{fill:'#d8ccb0',tex:'stone',texOp:.3,d:30,roof:'flat',topFill:'#a89a80',wins:{cols:9,rows:2,ww:9,wh:18,padT:10,padB:10,lit:.9,seed:9,arch:true,mull:true,frame:'#f0e6d0'}});
 s+=bld(pc-130,pb,260,110,{fill:'#e4d8bc',tex:'stone',texOp:.3,d:34,roof:'flat',topFill:'#b0a288',content:(X,t,w,h)=>{let q='';for(let i=0;i<8;i++)q+=`<rect x="${X+12+i*31}" y="${t+30}" width="10" height="${h-36}" fill="#fff8e8" stroke="${INK}" stroke-width="1.6"/><rect x="${X+18+i*31}" y="${t+30}" width="4" height="${h-36}" fill="#000" opacity=".15"/>`;q+=`<rect x="${X}" y="${t+16}" width="${w}" height="14" fill="#f4ead2" stroke="${INK}" stroke-width="1.6"/><rect x="${X+20}" y="${t+40}" width="${w-40}" height="${h-46}" fill="url(#winLit)" opacity=".55"/>`;return q;}});
 s+=`<path d="M${pc-140} ${pb-110}L${pc} ${pb-150}L${pc+140} ${pb-110}Z" fill="#f0e6cc" stroke="${INK}" stroke-width="2.4"/><path d="M${pc-100} ${pb-114}L${pc} ${pb-142}L${pc+100} ${pb-114}Z" fill="#000" opacity=".08"/>`;
 // drum + dome
 s+=bld(pc-70,pb-150,140,44,{fill:'#ece0c4',d:18,roof:'none',sw:2.4,content:(X,t,w,h)=>{let q='';for(let i=0;i<7;i++)q+=`<rect x="${X+6+i*19.5}" y="${t+6}" width="7" height="${h-10}" fill="#fff8e8" stroke="${INK}" stroke-width="1.2"/>`;for(let i=0;i<6;i++)q+=`<rect x="${X+15+i*19.5}" y="${t+10}" width="8" height="${h-18}" rx="4" fill="url(#winLit)"/>`;return q;}});
 s+=dome(pc+9,pb-194,74,'#d8d0c0',{h:72,ribs:7});
 s+=glow(pc+9,pb-250,90,'#fff0c0',.25);
 s+=`<path d="M${pc+9} ${pb-296}v-20" stroke="${INK}" stroke-width="3"/><path d="M${pc+10} ${pb-316}c10 -3 16 3 26 0v14c-10 3 -16 -3 -26 0z" fill="#c0392b" stroke="${INK}" stroke-width="1.6"/>`;
 // floodlight beams
 // steps
 for(let i=0;i<3;i++)s+=`<rect x="${pc-160+i*10}" y="${pb+i*-4+8}" width="${320-i*20}" height="4" fill="#cfc2a6" stroke="${INK}" stroke-width="1.2"/>`;
 // boulevard
 s+=`<rect x="0" y="328" width="${W}" height="72" fill="#22252e"/><rect x="0" y="322" width="${W}" height="8" fill="#6a6a70" stroke="${INK}" stroke-width="1.6"/><path d="M0 364H${W}" stroke="#e8d890" stroke-width="2" stroke-dasharray="26 22" opacity=".7"/>`;
 // light trails
 s+=`<path d="M0 352H${W}" stroke="#ff3a2a" stroke-width="3" opacity=".45" filter="url(#blur2)"/><path d="M0 378H${W}" stroke="#fff4c0" stroke-width="3" opacity=".4" filter="url(#blur2)"/>`;
 // trees + lamps along the boulevard
 for(let x=60;x<W;x+=130){s+=treeRound(x,326,14,'#2a4a3a',{lit:'#4a7a5a',trunk:'#2a1a10'});}
 for(let x=0;x<W;x+=130)s+=streetLamp(x+124,330,74);
 s+=car(200,360,1,'#c0392b')+car(520,360,1,'#e8e4d8')+car(1060,360,1,'#2e6ab0')+car(1400,360,1,'#e0a030')+car(360,388,-1,'#2e8a5a',1.1)+car(820,388,-1,'#c0392b',1.1)+car(1240,388,-1,'#e8e4d8',1.1);
 s+=`<rect x="0" y="394" width="${W}" height="6" fill="#4a4a50"/>`;
 s+=vignette(W,H,.45);return s;};

// ================= ERA 7: Information Age =================
const gTower=(x,base,w,h,seed,{col='#3f6a9a',crown='flat',lit=.45,warm=.7,d=null,ink2='#0a1020',haze=0}={})=>{const r=rng(seed);let s=bld(x,base,w,h,{fill:col,d:d??Math.round(w*0.25),sw:2.2,ink:ink2,roof:'flat',topFill:shade(col,.2),sideFill:shade(col,.35),rimCol:'#bfe8ff',rimOp:.5,haze,hazeCol:'#8ab4d8',
 sideWins:(X,b,dd,hh)=>{let o='';for(let yy=b-hh+6;yy<b-6;yy+=9)if(r()<.5)o+=`<path d="M${X+2} ${f(yy)}L${X+dd-2} ${f(yy-dd*0.5)}" stroke="${r()<warm?'#ffd890':'#bfe8ff'}" stroke-width="2.4" opacity="${f(.4+r()*.4)}"/>`;return o;},
 content:(X,t,ww,hh)=>{let o=`<rect x="${X}" y="${t}" width="${ww}" height="${hh}" fill="url(#glassV)" opacity=".35"/>`;const cw=Math.max(6,ww/Math.round(ww/9)),ch=9;
  for(let yy=t+4;yy<t+hh-4;yy+=ch)for(let xx=X;xx<X+ww-2;xx+=cw)if(r()<lit)o+=`<rect x="${f(xx+1.2)}" y="${f(yy+1.2)}" width="${f(cw-2.4)}" height="${ch-2.4}" fill="${r()<warm?'#ffd890':'#cfeeff'}" opacity="${f(.55+r()*.4)}"/>`;
  for(let xx=X;xx<X+ww;xx+=cw)o+=`<path d="M${f(xx)} ${t}V${t+hh}" stroke="#0a1426" stroke-width="1" opacity=".7"/>`;
  o+=`<path d="M${X} ${t+hh*0.55}L${X+ww*0.7} ${t}" stroke="#fff" stroke-width="${ww*0.18}" opacity=".08"/>`;return o;}});
 const top=base-h,dd=d??Math.round(w*0.25);
 if(crown==='spire')s+=`<path d="M${x+w/2+dd/2} ${top-dd/2}v-60" stroke="${ink2}" stroke-width="4"/><path d="M${x+w/2+dd/2} ${top-dd/2}v-60" stroke="#cfd8e8" stroke-width="2"/><circle cx="${x+w/2+dd/2}" cy="${top-dd/2-62}" r="3.5" fill="#ff4a4a" filter="url(#glow)"/>`;
 if(crown==='slant')s+=`<path d="M${x} ${top}L${x+w} ${top-w*0.5}L${x+w+dd} ${top-w*0.5-dd/2}L${x+w+dd} ${top-dd/2}L${x+w} ${top}Z" fill="${shade(col,.1)}" stroke="${ink2}" stroke-width="2.2"/><path d="M${x} ${top}L${x+w} ${top-w*0.5}V${top}Z" fill="${light(col,.2)}" stroke="${ink2}" stroke-width="2.2"/><path d="M${x+4} ${top-2}L${x+w-4} ${top-w*0.5+4}" stroke="#bfe8ff" stroke-width="2" opacity=".6"/>`;
 if(crown==='step'){s+=bld(x+w*0.15,top,w*0.7,30,{fill:col,d:dd*0.7,sw:2.2,ink:ink2,rim:false,shadow:false,sideFill:shade(col,.35)})+bld(x+w*0.3,top-30,w*0.4,24,{fill:col,d:dd*0.5,sw:2.2,ink:ink2,rim:false,shadow:false,sideFill:shade(col,.35)})+`<rect x="${x+w*0.3}" y="${top-34}" width="${w*0.4}" height="3" fill="#4ae0ff" filter="url(#glow)"/>`;}
 return s;};
E[7]=()=>{let s='';
 s+=sky(W,H,[[0,'#0a1430'],[.35,'#1e3a72'],[.65,'#3f6fae'],[.85,'#86b0d8'],[1,'#b8d2e8']]);
 s+=stars(W,H,60,7,120);
 s+=glow(1250,320,520,'#ffb890',.35)+glow(300,330,400,'#9ad0ff',.25);
 s+=cloud(100,120,280,{col:'#3a5a90',sh:'#1e3060',lit:'#7aa0d0',op:.6})+cloud(900,80,320,{col:'#3a5a90',sh:'#1e3060',lit:'#8ab0d8',op:.55});
 // far towers
 { const r=rng(71);let o='';for(let x=-20;x<W;x+=24+r()*30){const h=80+r()*130,w=22+r()*30;o+=`<rect x="${f(x)}" y="${f(300-h)}" width="${f(w)}" height="${f(h)}" fill="#3a5a8a"/>`;for(let k=0;k<h/8;k++)if(r()<.5)o+=`<rect x="${f(x+2)}" y="${f(300-h+3+k*8)}" width="${f(w-4)}" height="2" fill="#bfe0ff" opacity="${f(.15+r()*.25)}"/>`;if(r()<.2)o+=`<path d="M${f(x+w/2)} ${f(300-h)}v-24" stroke="#3a5a8a" stroke-width="2"/>`;}s+=o;}
 s+=haze(W,160,310,'#86b0d8',.4);
 // mid layer (hazed, smaller)
 s+=gTower(100,330,60,170,31,{col:'#2e4a74',lit:.25,haze:.25})+gTower(400,330,70,190,32,{col:'#2e4a74',lit:.25,haze:.25,crown:'slant'})+gTower(600,330,56,150,33,{col:'#2e4a74',lit:.25,haze:.25})+gTower(1010,330,64,180,34,{col:'#2e4a74',lit:.25,haze:.25,crown:'spire'})+gTower(1240,330,60,160,35,{col:'#2e4a74',lit:.25,haze:.25})+gTower(1480,330,64,200,36,{col:'#2e4a74',lit:.25,haze:.25});
 // front towers with gaps
 s+=gTower(20,330,84,190,1,{col:'#35628f',crown:'slant',lit:.35})+gTower(200,330,96,236,3,{col:'#3a6c9c',crown:'spire',lit:.35})+gTower(330,330,64,120,4,{col:'#2c4f78',lit:.35});
 s+=gTower(500,330,100,200,5,{col:'#3f74a6',crown:'step',lit:.35});
 s+=gTower(680,330,120,262,7,{col:'#4a82b8',crown:'spire',lit:.4});
 s+=`<rect x="694" y="140" width="92" height="56" rx="3" fill="#0a1020" stroke="${INK}" stroke-width="2.4"/><linearGradient id="led" x1="0" x2="1"><stop offset="0" stop-color="#ff4aa8"/><stop offset=".5" stop-color="#7a5aff"/><stop offset="1" stop-color="#4ae0ff"/></linearGradient><rect x="698" y="144" width="84" height="48" fill="url(#led)" opacity=".9"/><path d="M712 178l14 -14l10 8l18 -20l14 12" stroke="#fff" stroke-width="3" fill="none" stroke-linejoin="round"/><rect x="694" y="140" width="92" height="56" fill="#fff" opacity=".1" filter="url(#glow)"/>`;
 s+=gTower(870,330,84,180,8,{col:'#33618e',crown:'slant',lit:.35})+gTower(1100,330,100,222,9,{col:'#3d70a2',crown:'step',lit:.35})+gTower(1330,330,80,150,12,{col:'#2e557e',lit:.35})+gTower(1450,330,104,240,13,{col:'#3f74a6',crown:'spire',lit:.35});
 // water
 s+=water(330,H,'#2a4a7a','#0a1834',7,'#bfe0ff');
 s+=reflect(`<rect x="0" y="200" width="${W}" height="130" fill="#ffd890" opacity=".0"/>`,330,0);
 // reflections of lit towers (blurred strips)
 { const r=rng(77);let o='';for(let x=0;x<W;x+=6+r()*10)o+=`<rect x="${f(x)}" y="${f(334+r()*10)}" width="${f(2+r()*4)}" height="${f(10+r()*40)}" fill="${r()<.7?'#ffd890':'#bfe8ff'}" opacity="${f(.1+r()*.25)}"/>`;s+=`<g filter="url(#blur2)">${o}</g>`;}
 // elevated highway with light trails
 const hy=356;
 for(let x=80;x<W;x+=220)s+=`<rect x="${x}" y="${hy+8}" width="22" height="${H-hy}" fill="#3a4254" stroke="${INK}" stroke-width="2.2"/><rect x="${x}" y="${hy+8}" width="7" height="${H-hy}" fill="#fff" opacity=".12"/>`;
 s+=`<path d="M0 ${hy}H${W}V${hy+14}H0Z" fill="#4a5266" stroke="${INK}" stroke-width="2.4"/><rect x="0" y="${hy-6}" width="${W}" height="6" fill="#6a748a" stroke="${INK}" stroke-width="1.6"/>`;
 s+=`<g filter="url(#glow)"><path d="M0 ${hy-9}H${W}" stroke="#ff3a3a" stroke-width="4" opacity=".9"/><path d="M0 ${hy-15}H${W}" stroke="#fff4d0" stroke-width="4" opacity=".95"/><path d="M0 ${hy-20}H${W}" stroke="#ffcf6a" stroke-width="2.5" opacity=".7"/></g>`;
 { const r=rng(79);let o='';for(let x=0;x<W;x+=30+r()*60)o+=`<rect x="${f(x)}" y="${hy-12}" width="${f(14+r()*30)}" height="5" rx="2.5" fill="${r()<.5?'#ff5a4a':'#fffbe0'}"/>`;s+=`<g filter="url(#glow)">${o}</g>`;}
 // curving on-ramp
 s+=`<path d="M1050 ${hy}C1150 ${hy+30} 1250 ${hy+40} 1400 ${hy+44}H${W}V${hy+58}H1400C1250 ${hy+54} 1140 ${hy+46} 1040 ${hy+14}Z" fill="#4a5266" stroke="${INK}" stroke-width="2.2"/><path d="M1050 ${hy+4}C1150 ${hy+34} 1250 ${hy+44} 1400 ${hy+48}H${W}" stroke="#ff5a4a" stroke-width="4" fill="none" opacity=".8" filter="url(#glow)"/>`;
 for(let x=40;x<W;x+=160)s+=glow(x+10,hy-44,30,'#ffe0a0',.55)+`<path d="M${x} ${hy-6}V${hy-44}h10" stroke="${INK}" stroke-width="4" fill="none"/><path d="M${x} ${hy-6}V${hy-44}h10" stroke="#8a94a8" stroke-width="2" fill="none"/><rect x="${x+8}" y="${hy-46}" width="10" height="4" fill="#fff4d0"/>`;
 s+=vignette(W,H,.4);return s;};

// ================= ERA 8: Space Age =================
const fTower=(x,base,w,h,{col='#c8c0e8',glowc='#5ef0ff',seed=1,rings=1,ink2='#0a0820',haze=0}={})=>{const r=rng(seed);const cx=x+w/2,top=base-h;const id='ft'+seed;
 const d=`M${x} ${base}C${x+w*0.08} ${base-h*0.5} ${cx-w*0.18} ${top+h*0.2} ${cx-3} ${top}H${cx+3}C${cx+w*0.18} ${top+h*0.2} ${x+w*0.92} ${base-h*0.5} ${x+w} ${base}Z`;
 let s=`<linearGradient id="${id}" x1="0" x2="1"><stop offset="0" stop-color="${light(col,.3)}"/><stop offset=".4" stop-color="${col}"/><stop offset="1" stop-color="${shade(col,.5)}"/></linearGradient><path d="${d}" fill="url(#${id})"/>`;
 s+=`<clipPath id="c${id}"><path d="${d}"/></clipPath><g clip-path="url(#c${id})">`;for(let yy=base-10;yy>top+20;yy-=12)if(r()<.75)s+=`<rect x="${x}" y="${f(yy)}" width="${w}" height="3" fill="${r()<.6?glowc:'#ffd8f0'}" opacity="${f(.45+r()*.4)}"/>`;s+=`<rect x="${cx+w*0.08}" y="${top}" width="${w}" height="${h}" fill="#000" opacity=".18"/>`+(haze?`<rect x="${x}" y="${top}" width="${w}" height="${h}" fill="#c890d8" opacity="${haze}"/>`:'')+`</g>`;
 s+=`<path d="${d}" fill="none" stroke="${ink2}" stroke-width="2.4"/>`;
 for(let i=0;i<rings;i++){const ry=base-h*(0.45+i*0.2),rw=w*(0.9-i*0.18);s+=`<ellipse cx="${cx}" cy="${f(ry)}" rx="${f(rw*0.75)}" ry="${f(rw*0.14)}" fill="${shade(col,.2)}" stroke="${ink2}" stroke-width="2.2"/><ellipse cx="${cx}" cy="${f(ry-2)}" rx="${f(rw*0.75)}" ry="${f(rw*0.12)}" fill="${light(col,.15)}" stroke="${ink2}" stroke-width="1.4"/><path d="M${f(cx-rw*0.6)} ${f(ry+rw*0.06)}Q${cx} ${f(ry+rw*0.16)} ${f(cx+rw*0.6)} ${f(ry+rw*0.06)}" stroke="${glowc}" stroke-width="2" fill="none" filter="url(#glow)"/>`;}
 s+=`<path d="M${cx} ${top}v-20" stroke="${ink2}" stroke-width="2.4"/><circle cx="${cx}" cy="${top-21}" r="3" fill="#ff6ad0" filter="url(#glow)"/>`;
 return s;};
const capTower=(x,base,w,h,{col='#6a5aa8',glowc='#7ff4ff',seed=1,ink2='#0a0820'}={})=>{const r=rng(seed);const top=base-h;const id='cp'+seed;let s=`<linearGradient id="${id}" x1="0" x2="1"><stop offset="0" stop-color="${light(col,.35)}"/><stop offset=".4" stop-color="${col}"/><stop offset="1" stop-color="${shade(col,.5)}"/></linearGradient>`;
 const d=`M${x} ${base}V${top+w/2}A${w/2} ${w/2} 0 0 1 ${x+w} ${top+w/2}V${base}Z`;s+=`<path d="${d}" fill="url(#${id})"/><clipPath id="c${id}"><path d="${d}"/></clipPath><g clip-path="url(#c${id})">`;for(let yy=base-8;yy>top+w/2;yy-=10)if(r()<.7)s+=`<rect x="${x+w*0.15}" y="${yy}" width="${w*0.7}" height="4" rx="2" fill="${r()<.5?glowc:'#ffe0f4'}" opacity="${f(.5+r()*.4)}"/>`;s+=`</g><path d="${d}" fill="none" stroke="${ink2}" stroke-width="2.4"/>`;
 s+=`<ellipse cx="${x+w/2}" cy="${top+w*0.55}" rx="${w*0.32}" ry="${w*0.3}" fill="${glowc}" opacity=".5" filter="url(#glow)"/><path d="M${x+w*0.2} ${top+w*0.6}A${w*0.3} ${w*0.3} 0 0 1 ${x+w*0.5} ${top+w*0.25}" stroke="#fff" stroke-width="2" opacity=".6" fill="none"/>`;return s;};
E[8]=()=>{let s='';
 s+=sky(W,H,[[0,'#0c0626'],[.35,'#2e1462'],[.62,'#6a2a8a'],[.82,'#c0509a'],[1,'#f08aa0']]);
 s+=stars(W,H,200,8,260);
 // two moons
 s+=glow(260,110,170,'#e8d0ff',.35)+`<circle cx="260" cy="110" r="62" fill="#e6dcf6"/><circle cx="260" cy="110" r="62" fill="url(#cylL)" opacity=".5"/><circle cx="236" cy="92" r="12" fill="#cfc2e6"/><circle cx="286" cy="126" r="16" fill="#d2c6ea"/><circle cx="262" cy="140" r="7" fill="#cfc2e6"/><path d="M200 110a62 62 0 0 0 112 34" fill="none" stroke="#fff" stroke-width="2" opacity=".5"/><circle cx="260" cy="110" r="62" fill="none" stroke="#8a6ab0" stroke-width="2"/>`;
 s+=glow(1300,70,70,'#7ff4ff',.4)+`<circle cx="1300" cy="70" r="22" fill="#9ae8f0"/><circle cx="1294" cy="64" r="5" fill="#7ad0e0"/><path d="M1268 76a34 9 -14 0 0 64 -14" stroke="#e8fbff" stroke-width="2" fill="none" opacity=".7"/>`;
 // nebula clouds
 s+=`<g opacity=".55">`+cloud(500,150,380,{col:'#7a3a9a',sh:'#3a1a5a',lit:'#e08ad0'})+cloud(1050,180,340,{col:'#8a3a8a',sh:'#3a1a5a',lit:'#f09ad0'})+`</g>`;
 // far needle towers
 { const r=rng(81);let o='';for(let x=-10;x<W;x+=30+r()*36){const h=90+r()*140,w=14+r()*20;o+=`<path d="M${f(x)} 300C${f(x+2)} ${f(300-h*0.6)} ${f(x+w/2-2)} ${f(300-h)} ${f(x+w/2)} ${f(300-h-10)}C${f(x+w/2+2)} ${f(300-h)} ${f(x+w-2)} ${f(300-h*0.6)} ${f(x+w)} 300Z" fill="#4a2a7a"/>`;if(r()<.6)o+=`<circle cx="${f(x+w/2)}" cy="${f(300-h-10)}" r="1.6" fill="#ff8ad8"/>`;for(let k=0;k<4;k++)if(r()<.6)o+=`<rect x="${f(x+2)}" y="${f(300-h*r())}" width="${f(w-4)}" height="1.6" fill="#7ff4ff" opacity=".5"/>`;}s+=o;}
 s+=haze(W,170,310,'#c060a0',.35);
 // sky traffic lanes
 { const r=rng(83);let o='';for(const [y,c] of [[150,'#7ff4ff'],[176,'#ffb0e0'],[210,'#7ff4ff']])for(let x=r()*60;x<W;x+=40+r()*80)o+=`<rect x="${f(x)}" y="${f(y+Math.sin(x/200)*6)}" width="${f(6+r()*10)}" height="2.4" rx="1.2" fill="${c}" opacity=".85"/>`;s+=`<g filter="url(#glow)">${o}</g>`;}
 // mid towers
 s+=fTower(30,330,90,220,{seed:1,col:'#b8b0e0',rings:1})+fTower(140,330,70,170,{seed:2,col:'#a89ed8'})+fTower(230,330,110,280,{seed:3,col:'#c8c0ec',rings:2})+capTower(370,330,60,200,{seed:4,col:'#3a6a9a',glowc:'#ffb0e0'});
 s+=fTower(460,330,120,250,{seed:5,col:'#c0b8e8',rings:2,glowc:'#ffb0e0'})+capTower(610,330,64,180,{seed:6,col:'#5a4a9a'});
 // dome habitat centre
 s+=bld(700,330,240,60,{fill:'#8a84b8',tex:'scifi',d:30,sw:2.4,ink:'#0a0820',rimCol:'#e0d0ff',wins:{cols:10,rows:1,ww:12,wh:10,padT:20,lit:1,seed:3,litCol:'#7ff4ff',frame:'#0a0820',glowOn:false}});
 s+=dome(835,270,96,'#7ab0d8',{h:90,ribs:9,ink:'#0a0820'})+`<path d="M760 268a75 60 0 0 1 60 -70" stroke="#fff" stroke-width="4" opacity=".35" fill="none"/>`;
 // sky bridge between towers
 s+=`<path d="M285 160H515" stroke="#0a0820" stroke-width="9"/><path d="M285 160H515" stroke="#d8d0f4" stroke-width="5"/><path d="M285 162H515" stroke="#7ff4ff" stroke-width="1.5" filter="url(#glow)"/>`;
 // launch pad right
 const lx=1300,lb=330;
 s+=capTower(990,330,60,190,{seed:7,col:'#3a6a9a'})+fTower(1080,330,100,240,{seed:8,col:'#c0b8e8',rings:1,glowc:'#ffb0e0'});
 // gantry lattice
 s+=`<rect x="${lx+46}" y="${lb-220}" width="34" height="220" fill="none" stroke="#0a0820" stroke-width="5"/><rect x="${lx+46}" y="${lb-220}" width="34" height="220" fill="none" stroke="#c0392b" stroke-width="2.4"/>`;for(let i=0;i<11;i++){const y=lb-220+i*20;s+=`<path d="M${lx+46} ${y}L${lx+80} ${y+20}M${lx+80} ${y}L${lx+46} ${y+20}" stroke="#a83a3a" stroke-width="1.6"/><path d="M${lx+46} ${y}H${lx+80}" stroke="#0a0820" stroke-width="2"/>`;}
 s+=`<path d="M${lx+46} ${lb-180}H${lx+22}M${lx+46} ${lb-120}H${lx+22}" stroke="#0a0820" stroke-width="5"/><path d="M${lx+46} ${lb-180}H${lx+22}M${lx+46} ${lb-120}H${lx+22}" stroke="#c0392b" stroke-width="2.4"/>`;
 // exhaust plume + smoke clouds
 const ry=lb-200;
 s+=glow(lx,lb-20,170,'#ffb060',.5);
 s+=`<g filter="url(#blur2)">`+[[-120,0,40],[-80,-14,46],[-30,-6,52],[30,-8,50],[84,-12,44],[130,2,38],[-60,10,40],[60,12,42]].map(([dx,dy,r])=>`<circle cx="${lx+dx}" cy="${lb+dy}" r="${r}" fill="#e8d8e8"/><circle cx="${lx+dx-r*0.3}" cy="${lb+dy-r*0.3}" r="${r*0.6}" fill="#fff4f0"/><circle cx="${lx+dx+r*0.3}" cy="${lb+dy+r*0.3}" r="${r*0.6}" fill="#b89ac0" opacity=".6"/>`).join('')+`</g>`;
 s+=`<path d="M${lx-22} ${ry+96}Q${lx} ${lb+30} ${lx+22} ${ry+96}Z" fill="#ffb040" opacity=".8" filter="url(#blur4)"/><path d="M${lx-13} ${ry+96}Q${lx} ${lb-10} ${lx+13} ${ry+96}Z" fill="#fff6c0"/><path d="M${lx-6} ${ry+96}Q${lx} ${lb-40} ${lx+6} ${ry+96}Z" fill="#ffffff"/>`+glow(lx,ry+120,60,'#fff0a0',.7);
 // rocket
 s+=ink(`M${lx-14} ${ry+96}V${ry}Q${lx-14} ${ry-40} ${lx} ${ry-64}Q${lx+14} ${ry-40} ${lx+14} ${ry}V${ry+96}Z`,'#f0eef8',2.6)+`<path d="M${lx+4} ${ry-56}Q${lx+14} ${ry-40} ${lx+14} ${ry}V${ry+96}H${lx+5}Z" fill="#8a84b0" opacity=".5"/><path d="M${lx-14} ${ry-6}h28v10h-28z" fill="#c0392b"/><path d="M${lx-14} ${ry+60}h28v6h-28z" fill="#2a2a3a"/>`+ink(`M${lx-14} ${ry+70}l-14 30h14z`,'#c0392b',2.2)+ink(`M${lx+14} ${ry+70}l14 30h-14z`,'#c0392b',2.2)+`<circle cx="${lx}" cy="${ry-20}" r="5" fill="#7ff4ff" stroke="#0a0820" stroke-width="1.8"/><path d="M${lx-10} ${ry-30}Q${lx-12} ${ry+20} ${lx-10} ${ry+90}" stroke="#fff" stroke-width="2" opacity=".6" fill="none"/>`;
 s+=capTower(1450,330,58,170,{seed:9,col:'#5a4a9a',glowc:'#ffb0e0'})+fTower(1530,330,80,230,{seed:10,col:'#b8b0e0',rings:1});
 // ground platform
 s+=`<rect x="0" y="330" width="${W}" height="70" fill="#2a1a4a"/><rect x="0" y="330" width="${W}" height="70" fill="url(#scifi)" opacity=".5"/><path d="M0 330H${W}" stroke="#0a0820" stroke-width="2.4"/><path d="M0 334H${W}" stroke="#7ff4ff" stroke-width="2" opacity=".8" filter="url(#glow)"/>`;
 { const r=rng(87);let o='';for(let i=0;i<40;i++){const x=r()*W,y=344+r()*50;o+=`<rect x="${f(x)}" y="${f(y)}" width="${f(16+r()*30)}" height="2" fill="${r()<.6?'#7ff4ff':'#ff8ad8'}" opacity="${f(.3+r()*.4)}"/>`;}s+=`<g filter="url(#glow)">${o}</g>`;}
 // hover car foreground
 s+=`<g transform="translate(420 372)">`+glow(0,14,40,'#7ff4ff',.6)+ink(`M-34 4Q-30 -8 -10 -10L16 -12Q34 -10 36 0Q34 10 12 12L-20 12Q-34 12 -34 4Z`,'#e8e4f4',2.4)+ink(`M-12 -9Q-4 -22 14 -20Q24 -18 26 -8Z`,'#2a1a4a',2)+`<path d="M-26 12h44" stroke="#7ff4ff" stroke-width="3" filter="url(#glow)"/><circle cx="34" cy="0" r="2.4" fill="#fff"/></g>`;
 s+=vignette(W,H,.4);return s;};

const only=process.argv[2];
const items=Object.keys(E).filter(k=>!only||only.split(',').includes(k)).map(k=>({name:'country_era'+k,w:W,h:H,svg:E[k](),opaque:true,grain:2,limit:295000}));
renderAll(items);
