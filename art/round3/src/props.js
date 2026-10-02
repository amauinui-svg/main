// 24 isometric property buildings (512x512, transparent) + construction site.
const L=require('./lib');const K=require('./kit');const {INK,f,mix,shade,light,poly,W,renderAll}=L;const {PL,mkIso,plot,onPlot,gable,hip,flatRoof,P,rowWins}=K;
const B={};
const wrap=(g,body)=>{const iso=mkIso();return plot(iso,g)+body(iso);};
const tf=(col='#3a2414')=>({w,h})=>{let o=`<rect x="0" y="0" width="${w}" height="${h}" fill="none" stroke="${col}" stroke-width="5"/>`;const n=Math.max(3,Math.round(w/20));for(let i=1;i<n;i++)o+=`<path d="M${f(i*w/n)} 0V${h}" stroke="${col}" stroke-width="4"/>`;o+=`<path d="M0 ${h*0.55}H${w}" stroke="${col}" stroke-width="3"/><path d="M0 ${h}L${f(w/n)} 0M${f(w/n*2)} ${h}L${f(w/n)} 0M${f(w-w/n)} 0L${w} ${h}M${f(w-2*w/n)} ${h}L${f(w-w/n)} 0" stroke="${col}" stroke-width="3"/>`;return o;};
const mudFlat=(iso,x0,y0,x1,y1,z,col)=>iso.box(x0-2,y0-2,z,x1+2,y1+2,z+4,{fill:light(col,.1),topTex:'plaster',top:{tone:.8}});

// ===== Era 1 Ancient =====
B.e1_t1=()=>wrap('dirt',iso=>{let s='';const mud='#c9a271';
 s+=onPlot(iso,iso.boxShadow(40,40,120,96,52,.33)+iso.boxShadow(40,96,150,150,50,.22));
 s+=iso.box(40,40,0,120,96,46,{fill:mud,tex:'plaster',noTop:true,left:{content:({w})=>W.door(w*0.18,14,18,32,{col:'#5a3a22'})+`<rect x="${w*0.55}" y="12" width="14" height="10" fill="#2a1408" stroke="${INK}" stroke-width="2.5"/><rect x="${w*0.55+2}" y="14" width="10" height="8" fill="url(#winLit)"/>`+`<path d="M0 6H${w}" stroke="#a37a4a" stroke-width="2" opacity=".6"/>`},right:{content:({w})=>`<rect x="${w*0.4}" y="12" width="12" height="10" fill="url(#winLit)" stroke="${INK}" stroke-width="2.5"/>`}});
 s+=flatRoof(iso,40,40,120,96,46,{fill:mud,tex:'plaster',ph:5,t:4});
 s+=P.amphora(iso,62,60,0.55,'#b8643a').replace(/NaN/g,'0');
 // roof goods
 { const c=iso.P([70,58,46]);s+=P.basket(iso,95,70,7,'#e3a43a').replace(/translate/g,'translate');}
 // canopy posts + striped cloth roof
 const cx0=34,cx1=150,cy0=96,cy1=150;
 const post=(x,y,h)=>iso.box(x-2,y-2,0,x+2,y+2,h,{fill:'#8a6440',ao:false,w:2});
 s+=post(cx1-4,cy0+4,40);
 // counter
 s+=iso.box(cx0+16,cy1-22,0,cx1-12,cy1-8,20,{fill:'#b8875a',tex:'siding',top:{fill:'#8a6440',tex:'grain'}});
 s+=P.basket(iso,cx0+30,cy1-15,8,'#d2452e')+P.basket(iso,cx0+52,cy1-15,8,'#e3a43a')+P.basket(iso,cx0+74,cy1-15,8,'#6a9a3a')+P.basket(iso,cx0+96,cy1-15,8,'#8a3a7a');
 s+=post(cx0+4,cy1-4,36)+post(cx1-4,cy1-4,36);
 // cloth canopy face (sloped) with stripes
 s+=iso.face([[cx0,cy0,52],[cx1,cy0,52],[cx1,cy1,38],[cx0,cy1,38]],{fill:'#b8402e',ao:false,tone:.8,content:({x,y,w,h})=>{let o='';for(let i=0;i<w;i+=20)o+=`<rect x="${x+i}" y="${y}" width="10" height="${h}" fill="#f1e2c0"/>`;return o+`<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="url(#fadeDown)" opacity=".5"/>`;}});
 // scalloped valance on front edge
 s+=iso.onFace([cx0,cy1,38],[cx0+1,cy1,38],[cx0,cy1,37],(()=>{let o='';const n=12,w=cx1-cx0;for(let i=0;i<n;i++)o+=`<path d="M${f(i*w/n)} 0h${f(w/n)}v5a${f(w/n/2)} 4 0 0 1 ${f(-w/n)} 0z" fill="${i%2?'#f1e2c0':'#b8402e'}" stroke="${INK}" stroke-width="1.6"/>`;return o;})());
 s+=iso.onFace([cx1,cy1,38],[cx1,cy1-1,38],[cx1,cy1,37],(()=>{let o='';const n=6,w=cy1-cy0;for(let i=0;i<n;i++)o+=`<path d="M${f(i*w/n)} 0h${f(w/n)}v5a${f(w/n/2)} 4 0 0 1 ${f(-w/n)} 0z" fill="${i%2?'#c9b898':'#8a2e20'}" stroke="${INK}" stroke-width="1.6"/>`;return o;})());
 s+=P.amphora(iso,165,120,0.9,'#b8643a')+P.amphora(iso,176,132,0.8,'#a0522d')+P.sack(iso,160,150,7)+P.crate(iso,150,70,14,'#a87444')+P.crate(iso,152,86,11,'#9a6a3c')+P.palm(iso,168,48,80,12)+P.sack(iso,24,120,6,'#d8c08a');
 return s;});

B.e1_t2=()=>wrap('dirt',iso=>{let s='';
 s+=P.water(iso,118,9,PL-9,PL-9,0,'#2f6f86');
 // pier deck over water + land
 s+=iso.box(30,40,0,180,150,6,{fill:'#9a7048',topTex:'siding',top:{tone:.8,texT:'rotate(90)'},tex:'plank'});
 for(const [x,y] of [[176,44],[176,96],[176,146],[130,146],[80,146]])s+=iso.box(x-3,y-3,-14,x+3,y+3,10,{fill:'#6a4a2e',ao:false,w:2});
 s+=onPlot(iso,'');
 s+=iso.boxShadow(50,50,128,118,60,.3,6);
 const reed='#b89a5a';
 s+=iso.box(50,50,6,128,118,48,{fill:reed,tex:'thatch',texT:'rotate(90)',noTop:true,left:{content:({w,h})=>W.door(w*0.15,12,18,30,{col:'#4a3020'})+W.win(w*0.55,12,16,12,{frame:'#5a3a20'})+`<path d="M0 3H${w}M0 ${h-3}H${w}" stroke="#6a4a2a" stroke-width="3"/>`},right:{content:({w,h})=>W.win(w*0.35,12,14,12,{frame:'#5a3a20'})+`<path d="M0 3H${w}" stroke="#6a4a2a" stroke-width="3"/>`}});
 s+=gable(iso,50,50,128,118,48,34,{axis:'y',fill:'#c9a863',tex:'thatch',ov:9,fascia:'#7a5a30',ridge:'#e8cf8a',gable:{fill:reed,tex:'thatch'}});
 // drying net between poles
 const p1=[150,60],p2=[150,128];for(const p of [p1,p2])s+=iso.box(p[0]-2,p[1]-2,6,p[0]+2,p[1]+2,58,{fill:'#7a5a3a',ao:false,w:2});
 const a=iso.P([150,60,56]),b=iso.P([150,128,56]),c=iso.P([150,128,22]),d=iso.P([150,60,26]);
 let net=`<path d="M${f(a[0])} ${f(a[1])} L${f(b[0])} ${f(b[1])} L${f(c[0])} ${f(c[1])} Q${f((c[0]+d[0])/2)} ${f((c[1]+d[1])/2+14)} ${f(d[0])} ${f(d[1])}Z" fill="#3a3020" opacity=".2"/>`;
 for(let i=0;i<=10;i++){const t=i/10;const top=[a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t],bot=[d[0]+(c[0]-d[0])*t,d[1]+(c[1]-d[1])*t+Math.sin(t*Math.PI)*12];net+=`<path d="M${f(top[0])} ${f(top[1])}L${f(bot[0])} ${f(bot[1])}" stroke="#2a2418" stroke-width="1"/>`;}
 for(let j=0;j<=5;j++){const t=j/5;let dd='';for(let i=0;i<=10;i++){const u=i/10;const top=[a[0]+(b[0]-a[0])*u,a[1]+(b[1]-a[1])*u],bot=[d[0]+(c[0]-d[0])*u,d[1]+(c[1]-d[1])*u+Math.sin(u*Math.PI)*12];dd+=(i?'L':'M')+f(top[0]+(bot[0]-top[0])*t)+' '+f(top[1]+(bot[1]-top[1])*t);}net+=`<path d="${dd}" stroke="#2a2418" stroke-width="1" fill="none"/>`;}
 net+=`<path d="M${f(a[0])} ${f(a[1])}L${f(b[0])} ${f(b[1])}" stroke="${INK}" stroke-width="2.4"/>`;
 for(const [t,cc] of [[.3,'#e8a63a'],[.7,'#e8a63a']]){const q=[d[0]+(c[0]-d[0])*t,d[1]+(c[1]-d[1])*t+8];net+=`<circle cx="${f(q[0])}" cy="${f(q[1])}" r="3.2" fill="${cc}" stroke="${INK}" stroke-width="1.4"/>`;}
 s+=net;
 // boat moored on water
 const bc=iso.P([170,178,0]);s+=`<g transform="translate(${f(bc[0])} ${f(bc[1])}) rotate(-26)"><ellipse cx="2" cy="4" rx="34" ry="7" fill="#1a3a4a" opacity=".5"/><path d="M-32 -6 Q0 14 32 -6 L28 -2 Q0 10 -28 -2Z" fill="#8a5a32" stroke="${INK}" stroke-width="2.4"/><path d="M-32 -6 Q0 4 32 -6 Q0 14 -32 -6Z" fill="#5a3a20" stroke="${INK}" stroke-width="2"/><path d="M-30 -5 Q0 3 30 -5" stroke="#c9945a" stroke-width="1.5" fill="none"/><path d="M-8 0 L14 -30" stroke="${INK}" stroke-width="3"/><path d="M-8 0 L14 -30" stroke="#a07a4a" stroke-width="1.4"/></g>`;
 // fish rack & baskets
 s+=P.basket(iso,90,138,8,'#9fb4c0')+P.basket(iso,108,140,7,'#c0ccd4')+P.barrel(iso,140,40,6,13)+P.crate(iso,30,128,12)+P.sack(iso,40,150,6,'#c9b083');
 s+=P.palm(iso,24,176,74,-8);
 return s;});

B.e1_t3=()=>wrap('dirt',iso=>{let s='';const mud='#c79c68';
 s+=onPlot(iso,iso.boxShadow(30,36,130,130,80,.32)+iso.boxShadow(126,90,176,150,40,.25));
 s+=iso.box(30,36,0,130,130,48,{fill:mud,tex:'brick',texOp:.5,noTop:true,left:{content:({w})=>W.door(w*0.42,14,22,34,{col:'#4a2e1a'})+`<rect x="${w*0.14}" y="14" width="12" height="16" fill="url(#winLit)" stroke="${INK}" stroke-width="2.5"/><rect x="${w*0.76}" y="14" width="12" height="16" fill="url(#winLit)" stroke="${INK}" stroke-width="2.5"/>`+`<path d="M0 5H${w}" stroke="#7a5030" stroke-width="3"/><path d="M${w*0.42-4} 10h30" stroke="#d6a640" stroke-width="3"/>`},right:{content:({w})=>`<rect x="${w*0.2}" y="14" width="12" height="16" fill="url(#winLit)" stroke="${INK}" stroke-width="2.5"/><rect x="${w*0.6}" y="14" width="12" height="16" fill="url(#winLit)" stroke="${INK}" stroke-width="2.5"/>`}});
 s+=flatRoof(iso,30,36,130,130,48,{fill:mud,tex:'plaster',ph:5});
 s+=iso.box(50,50,48,110,100,80,{fill:light(mud,.05),tex:'brick',texOp:.5,noTop:true,left:{content:({w})=>W.win(w*0.4,10,12,16,{frame:'#5a3a20'})},right:{content:({w})=>W.win(w*0.4,10,12,16,{frame:'#5a3a20'})}});
 s+=flatRoof(iso,50,50,110,100,80,{fill:mud,tex:'plaster',ph:5});
 s+=P.flag(iso,80,74,80,40,'#2e5e8a');
 // big beehive kiln on right
 s+=iso.cyl(150,118,22,0,20,'#a0623a',{tex:'brick',top:false});
 s+=iso.dome(150,118,22,20,'#a86a40',{h:40});
 { const c=iso.P([150,140,10]);s+=`<ellipse cx="${f(c[0]-6)}" cy="${f(c[1]-8)}" rx="22" ry="18" fill="#ff8a2a" opacity=".55" filter="url(#blur8)"/><path d="M${f(c[0]-18)} ${f(c[1]+4)} v-14 a10 10 0 0 1 20 -4 v14z" fill="#2a0e04" stroke="${INK}" stroke-width="3"/><path d="M${f(c[0]-15)} ${f(c[1]+2)} v-10 a7 7 0 0 1 14 -3 v10z" fill="url(#winLit)"/><ellipse cx="${f(c[0]-8)}" cy="${f(c[1]-2)}" rx="6" ry="3" fill="#fff6c0"/>`;}
 s+=P.chimney(iso,144,104,40,78,10,'#9a5a36');
 // ingots stacked
 const ing=(x,y,z)=>iso.box(x,y,z,x+10,y+5,z+4,{fill:'#c8893a',ao:false,w:1.8,top:{fill:'#e8b050'}});
 let st='';for(let r=0;r<2;r++)for(let i=0;i<3;i++)st+=ing(150+i*1,160+i*6-r*1,r*4);s+=st;
 s+=P.amphora(iso,44,146,0.8,'#8a4a2a')+P.crate(iso,64,150,13)+P.sack(iso,96,160,7)+P.palm(iso,22,178,84,-10)+P.basket(iso,120,170,7,'#4a4a4a');
 // anvil-like mold + bellows
 s+=iso.box(176,40,0,190,70,8,{fill:'#6a5a4a',tex:'block',ao:false});
 return s;});

// ===== Era 2 Classical =====
const stucco='#e9e0cb',terra='#b9583a',marble='#ece6d8';
B.e2_t1=()=>wrap('marble',iso=>{let s='';
 s+=onPlot(iso,iso.boxShadow(36,40,140,124,90,.33));
 s+=iso.box(36,40,0,140,124,58,{fill:stucco,tex:'plaster',noTop:true,left:{content:({w,h})=>W.band(0,h-8,w,8,'#d4c7a8')+W.door(w*0.12,20,22,38,{col:'#6a3f22',arch:true})+W.win(w*0.5,14,16,20,{arch:true,shut:'#4a6a8a'})+W.win(w*0.8,14,14,20,{arch:true})+W.band(0,6,w,4,'#c9b48a')},right:{content:({w,h})=>W.band(0,h-8,w,8,'#d4c7a8')+W.win(w*0.25,14,14,20,{arch:true})+W.win(w*0.6,14,14,20,{arch:true})+W.band(0,6,w,4,'#c9b48a')}});
 s+=gable(iso,36,40,140,124,58,34,{axis:'x',fill:terra,tex:'rtile',ov:7,fascia:'#7a3a22',ridge:'#d8785a',gable:{fill:stucco,tex:'plaster',content:({w,h})=>`<circle cx="${w/2}" cy="${h*0.62}" r="6" fill="url(#winLit)" stroke="${INK}" stroke-width="2.4"/>`}});
 // awning over door
 s+=iso.face([[40,124,46],[96,124,46],[96,140,36],[40,140,36]],{fill:'#3f6a8a',ao:false,tone:.8,content:({x,y,w,h})=>{let o='';for(let i=0;i<w;i+=14)o+=`<rect x="${x+i}" y="${y}" width="7" height="${h}" fill="#f1e8d0"/>`;return o;}});
 // dome bread oven
 s+=onPlot(iso,iso.boxShadow(150,60,186,96,30,.3));
 s+=iso.box(148,58,0,188,98,14,{fill:'#c9b898',tex:'block',top:{fill:'#b8a888'}});
 s+=iso.dome(168,78,17,14,'#c0704a',{h:30});
 { const c=iso.P([168,95,14]);s+=`<ellipse cx="${f(c[0])}" cy="${f(c[1]-6)}" rx="14" ry="10" fill="#ff8a2a" opacity=".6" filter="url(#blur4)"/><path d="M${f(c[0]-8)} ${f(c[1]+2)}v-8a8 8 0 0 1 16 0v8z" fill="#1a0a04" stroke="${INK}" stroke-width="2.5"/><path d="M${f(c[0]-5)} ${f(c[1]+1)}v-6a5 5 0 0 1 10 0v6z" fill="url(#winLit)"/>`;}
 // bread display table
 s+=iso.box(110,146,0,160,162,16,{fill:'#9a6a3c',tex:'siding',top:{fill:'#b88850',tex:'grain'}});
 for(let i=0;i<4;i++){const c=iso.P([118+i*11,154,16]);s+=`<ellipse cx="${f(c[0])}" cy="${f(c[1]-3)}" rx="7" ry="4.5" fill="#c8843a" stroke="${INK}" stroke-width="1.8"/><path d="M${f(c[0]-4)} ${f(c[1]-4)}l2 -2M${f(c[0])} ${f(c[1]-5)}l2 -2M${f(c[0]+3)} ${f(c[1]-4)}l2 -2" stroke="#f1d08a" stroke-width="1.3"/>`;}
 s+=P.sack(iso,40,150,7,'#ece0c0')+P.sack(iso,52,160,6,'#ece0c0')+P.amphora(iso,176,130,0.85)+P.cypress(iso,186,40,70)+P.cypress(iso,24,176,50)+P.crate(iso,70,160,12);
 return s;});

B.e2_t2=()=>wrap('marble',iso=>{let s='';
 const x0=46,y0=30,x1=150,y1=118;
 s+=onPlot(iso,iso.boxShadow(x0,y0,x1,y1+40,110,.33));
 s+=iso.box(x0-6,y0-6,0,x1+6,y1+44,8,{fill:'#d8cdb5',tex:'stone',top:{tex:'flag'}});
 s+=P.steps(iso,x0+6,y1+44,x1-6,y1+58,2,4,'y').replace(/z0/g,'');
 s+=iso.box(x0,y0,8,x1,y1,78,{fill:marble,tex:'stone',texOp:.45,noTop:true,left:{content:({w,h})=>W.door(w/2-12,h-40,24,40,{col:'#7a5a2a',arch:true})+W.win(w*0.15,20,10,22,{arch:true})+W.win(w*0.85-10,20,10,22,{arch:true})},right:{content:({w,h})=>{let o='';for(let i=0;i<4;i++)o+=W.pilaster(10+i*(w-30)/3,4,8,h-4,'#f4efe2');return o+rowWins(w,22,10,22,3,{arch:true})}}});
 // portico columns
 const cy=y1+34;for(let i=0;i<5;i++)s+=P.column(iso,x0+8+i*22,cy,8,78,5.5,marble,'ionic');
 // entablature beam over columns
 s+=iso.box(x0-2,y1,78,x1+2,y1+42,88,{fill:marble,noTop:true,left:{content:({w,h})=>`<path d="M0 3H${w}" stroke="#b8a888" stroke-width="2"/>`+Array.from({length:14},(_,i)=>`<rect x="${4+i*w/14}" y="5" width="3" height="4" fill="#000" opacity=".25"/>`).join('')}});
 s+=gable(iso,x0-2,y0,x1+2,y1+42,88,30,{axis:'y',fill:terra,tex:'rtile',ov:4,fascia:'#c9bda5',ridge:'#d8785a',gable:{fill:marble,content:({w,h})=>`<path d="M${w*0.2} ${h-3}Q${w/2} ${h*0.35} ${w*0.8} ${h-3}" fill="none" stroke="#b8a888" stroke-width="2"/><circle cx="${w/2}" cy="${h*0.68}" r="6" fill="#d6b04a" stroke="${INK}" stroke-width="1.8"/><path d="M${w*0.34} ${h-6}q4 -6 8 0M${w*0.58} ${h-6}q4 -6 8 0" stroke="#9a8a6a" stroke-width="1.6" fill="none"/>`}});
 s+=P.torch(iso,x0-2,y1+54,22)+P.torch(iso,x1+2,y1+54,22);
 s+=P.cypress(iso,178,40,74)+P.cypress(iso,178,90,62)+P.bush(iso,22,140,9,'#5a7a3a')+P.amphora(iso,175,160,0.8);
 s+=P.banner(iso,[x1,y1,70],[x1,y1-1,70],[x1,y1,69],20,14,30,'#8a2a3a');
 return s;});

B.e2_t3=()=>wrap('marble',iso=>{let s='';
 const x0=40,y0=36,x1=160,y1=150;
 s+=onPlot(iso,iso.boxShadow(x0,y0,x1,y1,150,.33));
 // podium
 s+=iso.box(x0-10,y0-10,0,x1+10,y1+10,12,{fill:'#cfc3a8',tex:'block',top:{tex:'flag',fill:'#ddd2bc'}});
 s+=iso.box(x0+8,y0+8,12,x1-8,y1-8,72,{fill:marble,tex:'stone',texOp:.45,noTop:true,left:{content:({w,h})=>W.door(w/2-14,h-44,28,44,{col:'#a8782a',arch:true})+rowWins(w,14,10,20,4,{arch:true,sill:false})},right:{content:({w,h})=>rowWins(w,14,10,20,4,{arch:true,sill:false})}});
 // colonnade both faces
 for(let i=0;i<6;i++)s+=P.column(iso,x0+i*24,y1,12,72,5,marble);
 for(let i=0;i<5;i++)s+=P.column(iso,x1,y1-24-i*24,12,72,5,marble);
 // fix order: right colonnade drawn after left one; corner column last
 s+=iso.box(x0-6,y0-6,72,x1+6,y1+6,84,{fill:'#f1ebdc',top:{fill:'#d8cdb5',tex:'flag'},left:{content:({w,h})=>`<path d="M0 3H${w}" stroke="#c9a640" stroke-width="2.4"/>`+Array.from({length:18},(_,i)=>`<rect x="${4+i*w/18}" y="6" width="3" height="4" fill="#000" opacity=".25"/>`).join('')},right:{content:({w,h})=>`<path d="M0 3H${w}" stroke="#c9a640" stroke-width="2.4"/>`+Array.from({length:18},(_,i)=>`<rect x="${4+i*w/18}" y="6" width="3" height="4" fill="#000" opacity=".25"/>`).join('')}});
 // drum + dome
 s+=iso.cyl(100,93,34,84,104,'#efe8d8',{top:false,tex:'stone'});
 { // drum windows
  for(const t of[-.6,-.2,.2,.6]){const c=iso.P([100,93,98]);const rx=34*Math.SQRT2;s+=`<rect x="${f(c[0]+t*rx-3)}" y="${f(c[1]+Math.sqrt(1-t*t)*rx/2-10)}" width="6" height="10" rx="3" fill="url(#winLit)" stroke="${INK}" stroke-width="1.6"/>`;}}
 s+=iso.dome(100,93,34,104,'#c9a640',{h:46,ribs:6});
 { const c=iso.P([100,93,104]);s+=`<path d="M${f(c[0])} ${f(c[1]-60)}v-12" stroke="${INK}" stroke-width="4"/><circle cx="${f(c[0])}" cy="${f(c[1]-75)}" r="5" fill="#ffe08a" stroke="${INK}" stroke-width="2"/>`;}
 // gold coin piles + chest on front
 const coin=(x,y,n)=>{let o='';const c=iso.P([x,y,12]);for(let i=0;i<n;i++)o+=`<ellipse cx="${f(c[0])}" cy="${f(c[1]-i*2.6)}" rx="6" ry="3" fill="${i%2?'#e0b04a':'#f1c85a'}" stroke="${INK}" stroke-width="1.3"/>`;return o;};
 s+=coin(52,176,6)+coin(64,182,4)+coin(44,186,3);
 s+=P.banner(iso,[x0,y1+6,80],[x0+1,y1+6,80],[x0,y1+6,79],30,16,36,'#8a1f2a')+P.banner(iso,[x0,y1+6,80],[x0+1,y1+6,80],[x0,y1+6,79],80,16,36,'#8a1f2a');
 s+=P.cypress(iso,190,30,80)+P.torch(iso,170,170,12)+P.torch(iso,30,30,12);
 return s;});

// ===== Era 3 Medieval =====
B.e3_t1=()=>wrap('cobble',iso=>{let s='';
 const x0=36,y0=34,x1=150,y1=132;
 s+=onPlot(iso,iso.boxShadow(x0,y0,x1,y1,130,.35));
 s+=iso.box(x0,y0,0,x1,y1,38,{fill:'#9a8f80',tex:'block',noTop:true,
  left:{content:({w,h})=>W.door(16,10,24,28,{col:'#5a3a22',arch:true})+W.win(62,12,18,15,{shut:'#3f5a3a'})},
  right:{content:({w,h})=>`<rect x="16" y="6" width="54" height="32" fill="#1a0c06" stroke="${INK}" stroke-width="3"/><rect x="18" y="8" width="50" height="30" fill="url(#winLit)" opacity=".9"/><ellipse cx="43" cy="34" rx="22" ry="9" fill="#ff7a1a" opacity=".85"/><path d="M14 6h58" stroke="#5a4a3a" stroke-width="5"/><path d="M30 20l6 -6M40 22l4 -8" stroke="#fff6c0" stroke-width="2" opacity=".6"/>`}});
 s+=iso.box(x0-5,y0,38,x1,y1+5,76,{fill:'#e6d7b2',tex:'plaster',noTop:true,
  left:{content:a=>tf()(a)+W.win(a.w*0.3-8,12,16,16,{frame:'#3a2414'})+W.win(a.w*0.72-8,12,16,16,{frame:'#3a2414'})},
  right:{content:a=>tf()(a)+W.win(a.w*0.5-8,12,16,16,{frame:'#3a2414'})}});
 s+=gable(iso,x0-5,y0,x1,y1+5,76,44,{axis:'x',fill:'#5f6b7a',tex:'slate',gable:{fill:'#e6d7b2',tex:'plaster',content:({w,h})=>`<path d="M${w/2} 0V${h}M0 ${h-2}H${w}" stroke="#3a2414" stroke-width="4"/>`+W.win(w/2-7,h*0.45,14,13,{frame:'#3a2414',sill:false})}});
 s+=P.chimney(iso,66,y0+8,90,140,13,'#7a6a5c');
 const sp=iso.P([x0+64,y1+5,48]);s+=`<path d="M${f(sp[0])} ${f(sp[1])}l-2 18" stroke="${INK}" stroke-width="3"/>`;
 s+=iso.onFace([x0+40,y1+16,52],[x0+41,y1+16,52],[x0+40,y1+16,51],`<path d="M10 -4V0M26 -4V0" stroke="${INK}" stroke-width="1.5"/><rect x="2" y="0" width="32" height="20" rx="2" fill="#5a3a22" stroke="${INK}" stroke-width="2.4"/><rect x="5" y="3" width="26" height="14" fill="none" stroke="#d8a640" stroke-width="1.2"/><path d="M11 15l10 -9m-3 -3l6 6" stroke="#d9dfe6" stroke-width="3" stroke-linecap="round"/>`);
 s+=iso.box(x0+38,y1+5,52,x0+40,y1+18,54,{fill:'#2a2a2a',ao:false,w:1.5});
 s+=onPlot(iso,iso.boxShadow(162,56,180,74,14,.3));
 s+=P.barrel(iso,170,62,7,16)+P.barrel(iso,182,78,7,16,'#7a4a2a')+P.anvil(iso,172,112)+P.crate(iso,118,156,15)+P.crate(iso,138,162,12,'#9a6a3c')+P.sack(iso,96,176,7)+P.lamp(iso,22,150,44)+P.bush(iso,186,180,10)+P.bush(iso,30,186,8,'#5a7f3e');
 return s;});

B.e3_t2=()=>wrap('cobble',iso=>{let s='';
 const x0=40,y0=30,x1=150,y1=136;
 s+=onPlot(iso,iso.boxShadow(x0,y0,x1,y1,170,.35));
 s+=iso.box(x0,y0,0,x1,y1,40,{fill:'#a39886',tex:'block',noTop:true,left:{content:({w,h})=>{let o='';for(let i=0;i<4;i++)o+=W.door(8+i*(w-16)/4,10,(w-16)/4-8,30,{lit:true,arch:true});return o;}},right:{content:({w,h})=>W.door(w/2-12,8,24,32,{col:'#5a3a22',arch:true})}});
 s+=iso.box(x0-5,y0,40,x1+5,y1+5,80,{fill:'#e9dcb8',tex:'plaster',noTop:true,left:{content:a=>tf('#4a2a18')(a)+rowWins(a.w,12,14,18,4,{frame:'#4a2a18'})},right:{content:a=>tf('#4a2a18')(a)+rowWins(a.w,12,14,18,3,{frame:'#4a2a18'})}});
 s+=iso.box(x0-9,y0,80,x1+9,y1+9,114,{fill:'#e9dcb8',tex:'plaster',noTop:true,left:{content:a=>tf('#4a2a18')(a)+rowWins(a.w,10,12,16,5,{frame:'#4a2a18'})},right:{content:a=>tf('#4a2a18')(a)+rowWins(a.w,10,12,16,3,{frame:'#4a2a18'})}});
 s+=gable(iso,x0-9,y0,x1+9,y1+9,114,58,{axis:'x',fill:'#8a4a36',tex:'rtile',ov:6,fascia:'#3a2414',gable:{fill:'#e9dcb8',tex:'plaster',content:({w,h})=>tf('#4a2a18')({w,h})+W.win(w/2-8,h*0.5,16,18,{frame:'#4a2a18',arch:true,sill:false})}});
 // dormers on roof
 for(const dx of[66,110]){const yy=y1-14;s+=iso.box(dx,yy,124,dx+14,yy+14,140,{fill:'#e9dcb8',noTop:true,left:{content:()=>W.win(3,3,8,10,{frame:'#4a2a18',sill:false})}});s+=gable(iso,dx,yy-6,dx+14,yy+14,140,10,{axis:'y',fill:'#8a4a36',tex:'rtile',ov:2,fascia:'#3a2414'});}
 s+=P.chimney(iso,62,40,130,184,12,'#7a6a5c',true);
 s+=P.banner(iso,[x0-9,y1+9,108],[x0-8,y1+9,108],[x0-9,y1+9,107],22,14,32,'#2e4f8a')+P.banner(iso,[x0-9,y1+9,108],[x0-8,y1+9,108],[x0-9,y1+9,107],92,14,32,'#2e4f8a');
 s+=P.flag(iso,154,50,0,90,'#2e4f8a');
 s+=P.cart(iso,150,156)+P.barrel(iso,180,120,7,16)+P.crate(iso,28,160,14)+P.sack(iso,50,176,7)+P.lamp(iso,180,176,40)+P.bush(iso,180,40,10);
 return s;});

B.e3_t3=()=>wrap('cobble',iso=>{let s='';const st='#a29a8c';
 s+=onPlot(iso,iso.boxShadow(30,40,170,120,190,.35));
 // back wall + gate block
 const gx0=46,gx1=150,gy0=46,gy1=118;
 const tower=(x,y,r,h)=>{let o=iso.cyl(x,y,r,0,h,st,{tex:'block',top:false});
  // crenels ring
  o+=iso.cyl(x,y,r+3,h,h+10,light(st,.05),{tex:'block',topFill:'#6a6258'});
  const c=iso.P([x,y,h+10]);const rx=(r+3)*Math.SQRT2;
  // conical roof
  o+=`<path d="M${f(c[0]-rx-2)} ${f(c[1])} L${f(c[0])} ${f(c[1]-r*3.2)} L${f(c[0]+rx+2)} ${f(c[1])} A${f(rx+2)} ${f((rx+2)/2)} 0 0 1 ${f(c[0]-rx-2)} ${f(c[1])}Z" fill="#3f5a8a" stroke="${INK}" stroke-width="3"/>`
   +`<path d="M${f(c[0])} ${f(c[1]-r*3.2)} L${f(c[0]+rx+2)} ${f(c[1])} A${f(rx+2)} ${f((rx+2)/2)} 0 0 1 ${f(c[0]+rx*0.2)} ${f(c[1]+rx*0.48)}Z" fill="#000" opacity=".28"/><path d="M${f(c[0]-2)} ${f(c[1]-r*3.2+6)} L${f(c[0]-rx*0.6)} ${f(c[1]+2)}" stroke="#8ab0e0" stroke-width="2" opacity=".7"/>`
   +Array.from({length:5},(_,i)=>{const t=(i+1)/6;return `<path d="M${f(c[0]-(rx+2)*t)} ${f(c[1]-r*3.2*(1-t)+t*2)} Q${f(c[0])} ${f(c[1]-r*3.2*(1-t)+t*(rx/2+4))} ${f(c[0]+(rx+2)*t)} ${f(c[1]-r*3.2*(1-t)+t*2)}" stroke="${INK}" stroke-width="1" fill="none" opacity=".45"/>`}).join('');
  o+=P.flag(iso,x,y,h+10+r*3.2/1.1,22,'#b8352b');
  for(const t of[-.3,.35]){const cc=iso.P([x,y,h*0.6]);o+=`<rect x="${f(cc[0]+t*r*1.4-2.5)}" y="${f(cc[1]+Math.sqrt(1-t*t)*r*0.7-8)}" width="5" height="12" rx="2" fill="url(#winLit)" stroke="${INK}" stroke-width="1.6"/>`;}
  return o;};
 s+=tower(gx0+6,gy0+4,16,104)+tower(gx1-2,gy0+2,16,104);
 s+=iso.box(gx0,gy0,0,gx1,gy1,92,{fill:st,tex:'block',noTop:true,left:{content:({w,h})=>`<path d="M${w/2-20} ${h}V${h-36}A20 20 0 0 1 ${w/2+20} ${h-36}V${h}Z" fill="#1a120c" stroke="${INK}" stroke-width="3.5"/>`+`<path d="M${w/2-20} ${h-14}V${h-36}A20 20 0 0 1 ${w/2+20} ${h-36}V${h-14}" fill="url(#winLit)" opacity=".35"/>`+Array.from({length:6},(_,i)=>`<path d="M${w/2-17+i*6.8} ${h-52}V${h-8}" stroke="#3a3530" stroke-width="2.6"/>`).join('')+[0,1,2,3].map(j=>`<path d="M${w/2-20} ${h-46+j*10}H${w/2+20}" stroke="#3a3530" stroke-width="2.4"/>`).join('')+W.win(w/2-6,14,12,18,{arch:true,frame:'#2a2018'})+`<path d="M${w/2-22} ${h-58}a22 22 0 0 1 44 0" fill="none" stroke="#d8cbb4" stroke-width="3"/>`},right:{content:({w})=>W.win(w/2-6,20,10,16,{arch:true,frame:'#2a2018'})}});
 // crenellations atop gate
 s+=iso.box(gx0,gy0,92,gx1,gy1,96,{fill:light(st,.05),top:{fill:'#7a7268'}});
 for(let i=0;i<6;i++){const x=gx0+8+i*16;s+=iso.box(x,gy1-8,96,x+8,gy1,106,{fill:st,tex:'block',ao:false,w:2.2});}
 for(let i=0;i<4;i++){const y=gy1-14-i*16;s+=iso.box(gx1-8,y,96,gx1,y+8,106,{fill:st,tex:'block',ao:false,w:2.2});}
 s+=tower(36,gy1+8,20,112);
 s+=tower(154,gy1+8,20,112);
 s+=P.banner(iso,[gx0,gy1,84],[gx0+1,gy1,84],[gx0,gy1,83],22,14,30,'#b8352b')+P.banner(iso,[gx0,gy1,84],[gx0+1,gy1,84],[gx0,gy1,83],68,14,30,'#b8352b');
 s+=P.torch(iso,86,150,22)+P.torch(iso,128,150,22);
 s+=P.bush(iso,22,190,9)+P.bush(iso,188,24,9)+P.barrel(iso,120,170,7,16)+P.crate(iso,140,176,13);
 return s;});


// ===== Era 4 Early Modern =====
const sawtooth=(iso,x0,y0,x1,y1,z,n,th,o={})=>{let s='';const d=(y1-y0)/n;for(let i=0;i<n;i++){const a=y0+i*d,b=a+d;
 s+=iso.face([[x0,a,z],[x1,a,z],[x1,b,z+th],[x0,b,z+th]],{fill:o.fill||'#7a7f88',tex:o.tex||'corrug',ao:false,texT:'rotate(90)'});
 s+=iso.face([[x1,a,z],[x1,b,z],[x1,b,z+th]],{fill:o.end||'#8a4a36',tex:o.endTex||'brick',ao:false});
 s+=iso.face([[x0,b,z+th],[x1,b,z+th],[x1,b,z],[x0,b,z]],{fill:'#9fc6dc',ao:false,tone:.6,content:({x,y,w,h})=>{let q=`<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="url(#winLit)" opacity=".85"/>`;for(let k=0;k<w;k+=10)q+=`<path d="M${x+k} ${y}v${h}" stroke="#3a3a40" stroke-width="1.6"/>`;return q;}});}
 return s;};
const table=(iso,x,y,umb='#2e6a4a')=>{const c=iso.P([x,y,0]);return `<ellipse cx="${f(c[0]+6)}" cy="${f(c[1]+2)}" rx="16" ry="6" fill="#000" opacity=".25" filter="url(#blur2)"/><path d="M${f(c[0])} ${f(c[1])}v-14" stroke="${INK}" stroke-width="2.6"/><ellipse cx="${f(c[0])}" cy="${f(c[1]-12)}" rx="8" ry="4" fill="#d8c8a8" stroke="${INK}" stroke-width="2"/><path d="M${f(c[0])} ${f(c[1]-12)}v-24" stroke="${INK}" stroke-width="2"/><path d="M${f(c[0]-18)} ${f(c[1]-30)}Q${f(c[0])} ${f(c[1]-48)} ${f(c[0]+18)} ${f(c[1]-30)}Q${f(c[0])} ${f(c[1]-26)} ${f(c[0]-18)} ${f(c[1]-30)}Z" fill="${umb}" stroke="${INK}" stroke-width="2.2"/><path d="M${f(c[0]-6)} ${f(c[1]-28)}Q${f(c[0]-2)} ${f(c[1]-40)} ${f(c[0])} ${f(c[1]-42)}L${f(c[0]+6)} ${f(c[1]-28)}Z" fill="#f1e8d0" opacity=".9"/><path d="M${f(c[0]-14)} ${f(c[1]-36)}q8 -8 14 -8" stroke="#fff" stroke-width="1.3" fill="none" opacity=".5"/>`;};
B.e4_t1=()=>wrap('stone',iso=>{let s='';const wall='#e2c98a';
 const x0=40,y0=36,x1=146,y1=126;
 s+=onPlot(iso,iso.boxShadow(x0,y0,x1,y1,120,.33));
 s+=iso.box(x0,y0,0,x1,y1,40,{fill:'#6a3a2a',tex:'siding',noTop:true,left:{content:({w,h})=>W.win(8,8,30,24,{sill:false,frame:'#2a1a10'})+W.door(46,6,18,34,{col:'#2e4a3a'})+W.win(72,8,26,24,{sill:false,frame:'#2a1a10'})+W.band(0,0,w,5,'#c9a640')},right:{content:({w,h})=>W.win(12,8,28,24,{sill:false,frame:'#2a1a10'})+W.win(50,8,28,24,{sill:false,frame:'#2a1a10'})+W.band(0,0,w,5,'#c9a640')}});
 s+=iso.box(x0-3,y0,40,x1+3,y1+3,82,{fill:wall,tex:'plaster',noTop:true,left:{content:({w,h})=>rowWins(w,10,12,20,4,{shut:'#2e5a42'})+W.band(0,h-5,w,5,'#f1e6c8')},right:{content:({w,h})=>rowWins(w,10,12,20,3,{shut:'#2e5a42'})+W.band(0,h-5,w,5,'#f1e6c8')}});
 s+=hip(iso,x0-3,y0,x1+3,y1+3,82,36,{fill:'#4f5866',tex:'slate',ov:6,inset:30});
 s+=P.chimney(iso,70,60,96,128,10,'#8a5a46',true)+P.chimney(iso,120,60,96,124,10,'#8a5a46',false);
 // canvas awnings
 s+=iso.face([[x0,y1,38],[x1,y1,38],[x1,y1+16,26],[x0,y1+16,26]],{fill:'#2e6a4a',ao:false,tone:.8,content:({x,y,w,h})=>{let o='';for(let i=0;i<w;i+=16)o+=`<rect x="${x+i}" y="${y}" width="8" height="${h}" fill="#efe4c8"/>`;return o+`<rect x="${x}" y="${y+h-2}" width="${w}" height="2" fill="#000" opacity=".3"/>`;}});
 s+=iso.face([[x1,y1,38],[x1,y0,38],[x1+16,y0,26],[x1+16,y1,26]],{fill:'#2e6a4a',ao:false,content:({x,y,w,h})=>{let o='';for(let i=0;i<w;i+=16)o+=`<rect x="${x+i}" y="${y}" width="8" height="${h}" fill="#efe4c8"/>`;return o;}});
 s+=iso.onFace([x0+40,y1+3,74],[x0+41,y1+3,74],[x0+40,y1+3,73],'');
 // hanging cup sign
 s+=iso.onFace([x0-16,y1+3,70],[x0-15,y1+3,70],[x0-16,y1+3,69],`<path d="M0 0h16" stroke="${INK}" stroke-width="2.4"/><path d="M3 0v4M13 0v4" stroke="${INK}" stroke-width="1.2"/><rect x="-2" y="4" width="20" height="16" rx="3" fill="#2e4a3a" stroke="${INK}" stroke-width="2.2"/><path d="M3 9h10v4a5 4 0 0 1 -10 0z" fill="#f1e8d8" stroke="${INK}" stroke-width="1.2"/><path d="M13 10a2.5 2.5 0 0 1 0 4" stroke="#f1e8d8" stroke-width="1.4" fill="none"/><path d="M6 7q1 -2 0 -3M9 7q1 -2 0 -3" stroke="#f1e8d8" stroke-width="1" fill="none"/>`);
 s+=table(iso,70,166,'#2e6a4a')+table(iso,110,170,'#8a2e2a')+table(iso,176,150,'#2e6a4a');
 s+=P.lamp(iso,26,140,46)+P.bush(iso,180,40,10)+P.barrel(iso,180,100,6,13)+P.crate(iso,150,180,12);
 return s;});

B.e4_t2=()=>wrap('stone',iso=>{let s='';const br='#8e4a38';
 const x0=50,y0=30,x1=140,y1=136;
 s+=onPlot(iso,iso.boxShadow(x0,y0,x1,y1,180,.35));
 s+=iso.box(x0,y0,0,x1,y1,108,{fill:br,tex:'brick',noTop:true,left:{content:({w,h})=>W.band(0,h-36,w,4,'#d8c8a8')+W.door(w/2-12,h-34,24,34,{col:'#2e3a4a',arch:true})+W.win(8,h-30,22,22,{frame:'#e8e0d0'})+W.win(w-30,h-30,22,22,{frame:'#e8e0d0'})+rowWins(w,h-74,14,24,3,{frame:'#e8e0d0'})+rowWins(w,h-104,12,20,3,{frame:'#e8e0d0'})+W.band(0,h-40,w,4,'#d8c8a8')},right:{content:({w,h})=>W.band(0,h-40,w,4,'#d8c8a8')+rowWins(w,h-32,16,22,4,{frame:'#e8e0d0'})+rowWins(w,h-74,14,24,4,{frame:'#e8e0d0'})+rowWins(w,h-104,12,20,4,{frame:'#e8e0d0'})}});
 // stepped gable toward front-left (y1 face)
 const gz=108;const steps=[[0,1],[0.12,.88],[0.24,.76],[0.36,.64]];
 s+=gable(iso,x0,y0,x1,y1,gz,50,{axis:'y',fill:'#4f5866',tex:'slate',ov:2});
 for(let i=0;i<4;i++){const a=x0+(x1-x0)*i*0.12,b=x1-(x1-x0)*i*0.12;const z=gz+i*13;s+=iso.box(a,y1-6,z,b,y1+2,z+13,{fill:br,tex:'brick',ao:false,w:2.4,top:{fill:'#d8c8a8'}});}
 s+=iso.box(x0+(x1-x0)*0.4,y1-6,gz+52,x1-(x1-x0)*0.4,y1+2,gz+62,{fill:br,tex:'brick',ao:false,top:{fill:'#d8c8a8'}});
 s+=iso.onFace([x0+(x1-x0)*0.5-8,y1+2,gz+36],[x0+(x1-x0)*0.5-7,y1+2,gz+36],[x0+(x1-x0)*0.5-8,y1+2,gz+35],W.win(0,0,16,18,{frame:'#e8e0d0',arch:true,sill:false}));
 // hoist beam + crate
 const hb=iso.P([95,y1+2,gz+48]),he=iso.P([95,y1+20,gz+48]);s+=`<path d="M${f(hb[0])} ${f(hb[1])}L${f(he[0])} ${f(he[1])}" stroke="${INK}" stroke-width="6"/><path d="M${f(hb[0])} ${f(hb[1]-1)}L${f(he[0])} ${f(he[1]-1)}" stroke="#6a4a2e" stroke-width="3"/><path d="M${f(he[0])} ${f(he[1])}V${f(he[1]+60)}" stroke="#2a1a10" stroke-width="1.4"/>`;
 s+=P.crate(iso,90,y1+15,12,'#a87444',gz-62);
 // paper bales
 const bale=(x,y,z)=>iso.box(x,y,z,x+16,y+12,z+8,{fill:'#efe8d8',ao:false,w:2,left:{content:({w,h})=>`<path d="M${w/2} 0V${h}" stroke="#8a5a32" stroke-width="2"/>`},top:{content:({w,h})=>`<path d="M${w/2} 0V${h}" stroke="#8a5a32" stroke-width="2"/>`}});
 s+=bale(150,60,0)+bale(150,76,0)+bale(152,66,8)+bale(170,64,0);
 s+=P.cart(iso,150,140,'#5a6a7a')+bale(152,141,14);
 s+=P.lamp(iso,30,150,46)+P.bush(iso,24,40,9)+P.barrel(iso,40,176,6,13)+P.sack(iso,60,180,6);
 return s;});

B.e4_t3=()=>wrap('stone',iso=>{let s='';const wall='#e8dcc0';
 const x0=30,y0=30,x1=164,y1=140;
 s+=onPlot(iso,iso.boxShadow(x0,y0,x1,y1,160,.35));
 s+=iso.box(x0,y0,0,x1,y1,24,{fill:'#a89a82',tex:'block',noTop:true,left:{content:({w,h})=>rowWins(w,6,12,12,8,{sill:false,frame:'#3a2a1a'})},right:{content:({w,h})=>rowWins(w,6,12,12,6,{sill:false,frame:'#3a2a1a'})}});
 s+=iso.box(x0,y0,24,x1,y1,86,{fill:wall,tex:'stone',texOp:.4,noTop:true,left:{content:({w,h})=>rowWins(w,8,11,20,8,{frame:'#f4efe2'})+rowWins(w,36,11,20,8,{frame:'#f4efe2'})+W.band(0,30,w,3,'#d0c2a2')+W.band(0,h-3,w,3,'#d0c2a2')},right:{content:({w,h})=>rowWins(w,8,11,20,6,{frame:'#f4efe2'})+rowWins(w,36,11,20,6,{frame:'#f4efe2'})+W.band(0,30,w,3,'#d0c2a2')}});
 s+=iso.box(x0-3,y0-3,86,x1+3,y1+3,92,{fill:'#f4efe2',top:{fill:'#d8cdb5'}});
 s+=hip(iso,x0,y0,x1,y1,92,30,{fill:'#4a6a6a',tex:'slate',ov:2,inset:40});
 // central projecting portico on left face
 const px0=74,px1=120;
 s+=iso.box(px0,y1,0,px1,y1+14,92,{fill:light(wall,.05),tex:'stone',texOp:.4,noTop:true,left:{content:({w,h})=>W.door(w/2-11,h-36,22,36,{col:'#4a2e1a',arch:true})+W.win(w/2-6,20,12,22,{arch:true,frame:'#f4efe2'})+W.pilaster(2,0,6,h,'#f4efe2')+W.pilaster(w-8,0,6,h,'#f4efe2')},right:{content:()=>''}});
 s+=gable(iso,px0-2,y1-10,px1+2,y1+16,92,22,{axis:'y',fill:'#4a6a6a',tex:'slate',ov:2,gable:{fill:'#f4efe2',content:({w,h})=>`<circle cx="${w/2}" cy="${h*0.62}" r="7" fill="#f1e8d0" stroke="${INK}" stroke-width="2"/><path d="M${w/2} ${h*0.62}v-5M${w/2} ${h*0.62}h3.5" stroke="${INK}" stroke-width="1.4"/>`}});
 // cupola
 const cx=97,cy=85;s+=iso.box(cx-10,cy-10,118,cx+10,cy+10,138,{fill:'#f4efe2',noTop:true,left:{content:()=>W.win(5,3,10,14,{arch:true,sill:false})},right:{content:()=>W.win(5,3,10,14,{arch:true,sill:false})}});
 s+=iso.dome(cx,cy,11,138,'#4f8a7a',{h:22});const tp=iso.P([cx,cy,138]);s+=`<path d="M${f(tp[0])} ${f(tp[1]-26)}v-14" stroke="${INK}" stroke-width="3"/><circle cx="${f(tp[0])}" cy="${f(tp[1]-41)}" r="3.5" fill="#f1c85a" stroke="${INK}" stroke-width="1.5"/>`;
 s+=P.flag(iso,x0+2,y1,92,40,'#2e4f8a')+P.flag(iso,x1,y1-2,92,40,'#2e4f8a');
 // crates + barrels on dock
 s+=P.crate(iso,140,156,14)+P.crate(iso,156,160,12,'#9a6a3c')+P.crate(iso,146,158,11,'#a87444',14)+P.barrel(iso,176,150,7,15)+P.barrel(iso,186,164,7,15,'#7a4a2a')+P.sack(iso,40,170,7)+P.sack(iso,52,178,6);
 s+=P.lamp(iso,64,160,44)+P.lamp(iso,130,160,44);
 return s;});

// ===== Era 5 Industrial =====
B.e5_t1=()=>wrap('brick',iso=>{let s='';const br='#94503a';
 const x0=40,y0=40,x1=150,y1=130;
 s+=onPlot(iso,iso.boxShadow(x0,y0,x1,y1,90,.35));
 s+=iso.box(x0,y0,0,x1,y1,52,{fill:br,tex:'brick',noTop:true,left:{content:({w,h})=>`<rect x="${w*0.12}" y="${h-44}" width="40" height="44" fill="#1a0c06" stroke="${INK}" stroke-width="3"/><rect x="${w*0.12+3}" y="${h-41}" width="34" height="41" fill="url(#winLit)" opacity=".75"/><path d="M${w*0.12+8} ${h}v-14h24v14" fill="#3a2a1a" opacity=".7"/><path d="M${w*0.12-2} ${h-46}h44" stroke="#c9a640" stroke-width="3"/>`+W.win(w*0.62,12,26,22,{frame:'#2a2a30'})+W.band(0,0,w,4,'#c9b898')},right:{content:({w,h})=>rowWins(w,12,22,22,2,{frame:'#2a2a30'})+W.band(0,0,w,4,'#c9b898')}});
 s+=sawtooth(iso,x0,y0,x1,y1,52,3,18,{end:br});
 s+=iso.box(126,70,52,134,78,92,{fill:'#4a4a50',ao:false});const cp=iso.P([130,74,92]);s+=P.smoke(cp[0]+2,cp[1]-10,1);
 // cog sign on left face
 s+=iso.onFace([x0+20,y1,46],[x0+21,y1,46],[x0+20,y1,45],(()=>{let o=`<circle cx="0" cy="0" r="9" fill="#c9a640" stroke="${INK}" stroke-width="2"/>`;for(let i=0;i<8;i++){const a=i*Math.PI/4;o+=`<rect x="-2.5" y="-13" width="5" height="5" fill="#c9a640" stroke="${INK}" stroke-width="1.6" transform="rotate(${i*45})"/>`;}return `<g transform="translate(70 -2)">${o}<circle r="9" fill="#c9a640"/><circle r="3.5" fill="#3a2a1a" stroke="${INK}" stroke-width="1.5"/></g>`;})());
 s+=P.crate(iso,150,150,14)+P.crate(iso,166,154,12,'#9a6a3c')+P.barrel(iso,176,100,7,15,'#4a5a4a')+P.barrel(iso,180,116,7,15,'#4a5a4a')+P.cart(iso,40,150,'#5a5a60')+P.lamp(iso,26,40,46)+P.sack(iso,120,180,6);
 return s;});

B.e5_t2=()=>wrap('brick',iso=>{let s='';const br='#9a4e38';
 const x0=24,y0=40,x1=160,y1=124;
 s+=onPlot(iso,iso.boxShadow(x0,y0,x1,y1,170,.35));
 s+=iso.box(x0,y0,0,x1,y1,118,{fill:br,tex:'brick',noTop:true,left:{content:({w,h})=>{let o='';for(let r=0;r<4;r++)o+=rowWins(w,8+r*28,12,20,8,{frame:'#e8e0d0',sill:true,arch:true});return o+W.band(0,h-6,w,6,'#7a6a5a')+[1,2,3].map(r=>W.band(0,r*28+2,w,3,'#c9b898')).join('');}},right:{content:({w,h})=>{let o='';for(let r=0;r<4;r++)o+=rowWins(w,8+r*28,12,20,4,{frame:'#e8e0d0',arch:true});return o+W.door(w/2-12,h-30,24,30,{col:'#3a4a3a'});}}});
 s+=flatRoof(iso,x0,y0,x1,y1,118,{fill:'#8a4a36',pfill:'#a85a42',tex:'concrete',ph:7});
 // stair tower
 s+=iso.box(60,y1-4,0,84,y1+14,140,{fill:shade(br,.05),tex:'brick',noTop:true,left:{content:({w,h})=>[0,1,2,3,4].map(i=>W.win(w/2-4,10+i*26,8,14,{frame:'#e8e0d0',sill:false})).join('')+W.door(w/2-8,h-24,16,24,{col:'#3a4a3a'})}});
 s+=gable(iso,60,y1-4,84,y1+14,140,14,{axis:'x',fill:'#4f5866',tex:'slate',ov:3});
 // water tower on roof
 for(const [x,y] of [[118,62],[136,62],[118,82],[136,82]])s+=iso.box(x-1.5,y-1.5,124,x+1.5,y+1.5,146,{fill:'#5a4030',ao:false,w:1.8});
 s+=iso.cyl(127,72,14,146,170,'#8a6440',{tex:'plank',bands:[152,164]});
 const wt=iso.P([127,72,170]);s+=`<path d="M${f(wt[0]-22)} ${f(wt[1])}L${f(wt[0])} ${f(wt[1]-16)}L${f(wt[0]+22)} ${f(wt[1])}A22 11 0 0 1 ${f(wt[0]-22)} ${f(wt[1])}Z" fill="#4f5866" stroke="${INK}" stroke-width="2.6"/><path d="M${f(wt[0])} ${f(wt[1]-16)}L${f(wt[0]+22)} ${f(wt[1])}A22 11 0 0 1 ${f(wt[0]+4)} ${f(wt[1]+11)}Z" fill="#000" opacity=".25"/>`;
 // big chimney
 s+=iso.cyl(170,44,9,0,190,'#8a4a36',{tex:'brick',bands:[180]});const ct=iso.P([170,44,190]);s+=`<g transform="translate(${f(ct[0])} ${f(ct[1]-8)}) scale(1.4)">${P.smoke(0,0,1)}</g>`;
 s+=P.crate(iso,176,150,13)+P.crate(iso,176,168,13,'#9a6a3c')+P.barrel(iso,150,176,7,15,'#4a5a4a')+P.cart(iso,94,150,'#4a4a50')+P.lamp(iso,24,140,46)+P.lamp(iso,140,150,46);
 return s;});

B.e5_t3=()=>wrap('brick',iso=>{let s='';const met='#6f7680';
 const x0=24,y0=60,x1=126,y1=150;
 s+=onPlot(iso,iso.boxShadow(x0,y0,x1,y1,120,.35)+iso.boxShadow(130,40,180,90,140,.3));
 // chimneys at back
 for(const [x,y,h] of [[40,30,160],[70,26,176],[100,24,150]]){s+=iso.cyl(x,y,8,0,h,'#7a3a2a',{tex:'brick',bands:[h-8,h*0.5]});const t=iso.P([x,y,h]);s+=`<g transform="translate(${f(t[0])} ${f(t[1]-6)}) scale(1.25)">${P.smoke(0,0,1).replace(/#d9d6d0/g,'#8a8682')}</g>`;}
 // main hall corrugated with gable roof along x
 s+=iso.box(x0,y0,0,x1,y1,70,{fill:met,tex:'corrug',noTop:true,left:{content:({w,h})=>`<rect x="${w/2-22}" y="${h-46}" width="44" height="46" fill="#1a0a04" stroke="${INK}" stroke-width="3"/><rect x="${w/2-19}" y="${h-43}" width="38" height="43" fill="#ff8a2a"/><rect x="${w/2-19}" y="${h-43}" width="38" height="43" fill="url(#winLit)" opacity=".6"/><ellipse cx="${w/2}" cy="${h-6}" rx="16" ry="5" fill="#fff6c0"/>`+rowWins(w,10,10,14,7,{frame:'#2a2a30',sill:false})},right:{content:({w,h})=>rowWins(w,10,10,14,6,{frame:'#2a2a30',sill:false})}});
 s+=gable(iso,x0,y0,x1,y1,70,30,{axis:'x',fill:'#5a6068',tex:'corrug',ov:4,fascia:'#3a3e46',gable:{fill:met,tex:'corrug',content:({w,h})=>`<circle cx="${w/2}" cy="${h*0.6}" r="7" fill="url(#winLit)" stroke="${INK}" stroke-width="2"/>`}});
 // blast furnace
 s+=iso.cyl(156,64,20,0,90,'#4a4e56',{tex:'plate',bands:[30,60]});
 s+=iso.cyl(156,64,14,90,120,'#3a3e46',{tex:'plate',bands:[]});
 { const c=iso.P([156,84,24]);s+=`<ellipse cx="${f(c[0])}" cy="${f(c[1])}" rx="18" ry="14" fill="#ff7a1a" opacity=".6" filter="url(#blur8)"/><rect x="${f(c[0]-7)}" y="${f(c[1]-10)}" width="14" height="14" rx="3" fill="url(#winLit)" stroke="${INK}" stroke-width="2.4"/>`;}
 s+=P.pipe(iso,[[156,64,110],[156,64,130],[126,64,130],[100,70,100]],4,'#7a8088');
 // molten channel + ingots
 s+=iso.face([[130,120,0.5],[186,120,0.5],[186,128,0.5],[130,128,0.5]],{fill:'#ff8a2a',ao:false,sheen:false,tone:.6,content:({x,y,w,h})=>`<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="url(#winLit)"/>`});
 s+=iso.cyl(186,150,10,0,22,'#6a6e76',{bands:[8]})+iso.cyl(186,176,8,0,18,'#6a6e76');
 // coal pile
 { const c=iso.P([40,176,0]);s+=`<path d="M${f(c[0]-26)} ${f(c[1])} Q${f(c[0]-8)} ${f(c[1]-26)} ${f(c[0]+4)} ${f(c[1]-22)} Q${f(c[0]+20)} ${f(c[1]-14)} ${f(c[0]+28)} ${f(c[1])}Z" fill="#22222a" stroke="${INK}" stroke-width="2.4"/>`+[[-14,-8],[-4,-16],[8,-12],[16,-4],[-18,-2]].map(([dx,dy])=>`<path d="M${f(c[0]+dx)} ${f(c[1]+dy)}l3 -2l3 2" stroke="#7a7a88" stroke-width="1.3" fill="none"/>`).join('');}
 s+=P.lamp(iso,140,180,46)+P.crate(iso,80,170,13);
 return s;});

// ===== Era 6 Modern =====
B.e6_t1=()=>wrap('concrete',iso=>{let s='';
 const x0=40,y0=50,x1=150,y1=124;
 s+=onPlot(iso,iso.boxShadow(x0,y0,x1,y1,60,.35));
 s+=iso.box(x0,y0,0,x1,y1,44,{fill:'#5fb5ad',noTop:true,left:{content:({w,h})=>`<rect x="0" y="0" width="${w}" height="${h}" fill="#cfd6dc"/><rect x="0" y="${h-12}" width="${w}" height="12" fill="#c0392b"/><rect x="0" y="${h-12}" width="${w}" height="2" fill="#fff" opacity=".5"/>`+[0,1,2,3].map(i=>W.win(6+i*24,6,20,20,{sill:false,frame:'#9aa4ae',mull:false})).join('')+W.door(w-16,h-38,14,32,{lit:true})+`<rect x="0" y="0" width="${w}" height="4" fill="#9aa4ae"/>`},right:{content:({w,h})=>`<rect x="0" y="0" width="${w}" height="${h}" fill="#cfd6dc"/><rect x="0" y="${h-12}" width="${w}" height="12" fill="#c0392b"/>`+[0,1].map(i=>W.win(8+i*32,6,26,20,{sill:false,frame:'#9aa4ae',mull:false})).join('')}});
 s+=flatRoof(iso,x0,y0,x1,y1,44,{fill:'#c0392b',pfill:'#d84a3a',tex:'concrete',ph:4,t:3});
 s+=P.ac(iso,60,64,44,14)+P.ac(iso,84,64,44,12);
 // neon sign on roof
 s+=iso.onFace([96,y1-8,92],[97,y1-8,92],[96,y1-8,91],`<rect x="-2" y="40" width="3" height="10" fill="#3a3a40"/><rect x="40" y="40" width="3" height="10" fill="#3a3a40"/><rect x="-6" y="0" width="54" height="40" rx="6" fill="#1f2a44" stroke="${INK}" stroke-width="2.6"/><rect x="-3" y="3" width="48" height="34" rx="4" fill="none" stroke="#ff5a8a" stroke-width="2.4" filter="url(#glow)"/><g filter="url(#glow)"><path d="M10 26h22a11 6 0 0 0 -22 0z" fill="#ffd36b"/><rect x="9" y="27" width="24" height="3" rx="1.5" fill="#7ad36b"/><rect x="9" y="30" width="24" height="3" rx="1.5" fill="#c0603a"/><path d="M9 33h24a2 2 0 0 1 -2 3h-20a2 2 0 0 1 -2 -3z" fill="#ffd36b"/></g>`);
 s+=P.car(iso,150,140,'#e0a030','x')+P.car(iso,150,104,'#3a7ab8','x')+P.lamp(iso,30,140,52,{col:'#5a5f68'})+P.bush(iso,40,180,9)+P.bush(iso,60,186,8);
 // parking lines
 s+=onPlot(iso,[100,136,172].map(y=>iso.face([[146,y-6,0.3],[190,y-6,0.3],[190,y-4,0.3],[146,y-4,0.3]],{fill:'#e8e4d8',ao:false,stroke:false,tone:.6})).join(''));
 return s;});

B.e6_t2=()=>wrap('concrete',iso=>{let s='';const wall='#d8ccb4';
 const x0=24,y0=30,x1=170,y1=120;
 s+=onPlot(iso,iso.boxShadow(x0,y0,x1,y1,100,.35));
 s+=iso.box(x0,y0,0,x1,y1,74,{fill:wall,tex:'concrete',noTop:true,left:{content:({w,h})=>`<rect x="0" y="${h-34}" width="${w}" height="34" fill="#5a6070"/>`+[0,1,2,3,4,5].map(i=>`<rect x="${4+i*w/6}" y="${h-30}" width="${w/6-8}" height="26" fill="url(#winLit)" stroke="${INK}" stroke-width="2"/>`).join('')+[0,1,2].map(i=>`<rect x="${10+i*w/3}" y="10" width="${w/3-20}" height="20" rx="3" fill="${['#c0392b','#2e6ab0','#e0a030'][i]}" stroke="${INK}" stroke-width="2.4"/><rect x="${14+i*w/3}" y="14" width="${w/3-28}" height="4" rx="2" fill="#fff" opacity=".35"/>`).join('')},right:{content:({w,h})=>`<rect x="0" y="${h-34}" width="${w}" height="34" fill="#5a6070"/>`+[0,1,2,3].map(i=>`<rect x="${4+i*w/4}" y="${h-30}" width="${w/4-8}" height="26" fill="url(#winLit)" stroke="${INK}" stroke-width="2"/>`).join('')+`<rect x="10" y="10" width="${w-20}" height="20" rx="3" fill="#7a3a8a" stroke="${INK}" stroke-width="2.4"/>`}});
 s+=flatRoof(iso,x0,y0,x1,y1,74,{fill:'#b8ac94',pfill:'#e8dcc4',tex:'concrete',ph:5});
 s+=P.ac(iso,40,46,74,14)+P.ac(iso,60,46,74,14)+P.ac(iso,140,50,74,14)+P.ac(iso,140,74,74,12);
 // glass atrium entrance
 s+=iso.box(70,96,0,124,132,96,{fill:'#7fb4d6',noTop:false,top:{fill:'#9fd0ea',tex:'glass'},tex:'glass',left:{content:({w,h})=>`<rect x="0" y="0" width="${w}" height="${h}" fill="url(#glassV)" opacity=".7"/><rect x="${w/2-12}" y="${h-28}" width="24" height="28" fill="url(#winLit)" stroke="${INK}" stroke-width="2"/>`+[0,1,2,3].map(i=>`<path d="M0 ${i*24}H${w}" stroke="#2a3a4a" stroke-width="1.6"/>`).join('')+`<path d="M6 ${h-40}L${w*0.5} 6" stroke="#fff" stroke-width="5" opacity=".25"/>`,tex:'glass'},right:{content:({w,h})=>`<rect x="0" y="0" width="${w}" height="${h}" fill="url(#glassV)" opacity=".7"/>`,tex:'glass'}});
 // planters + trees, cars
 s+=P.tree(iso,40,160,14,'#4f7a3a')+P.tree(iso,150,160,14,'#4f7a3a')+P.car(iso,160,130,'#c0392b','y')+P.car(iso,40,128,'#e8e4d8','x').replace('','')+P.lamp(iso,96,174,52,{col:'#5a5f68'});
 return s;});

B.e6_t3=()=>wrap('concrete',iso=>{let s='';
 const x0=24,y0=30,x1=150,y1=128;
 s+=onPlot(iso,iso.boxShadow(x0,y0,x1,y1,110,.35));
 // stacks at back
 for(const [x,y,h] of [[160,30,170],[178,48,150]]){s+=iso.cyl(x,y,7,0,h,'#d8dce2',{bands:[h-10,h-20],bandCol:'#c0392b',bandW:4});const t=iso.P([x,y,h]);s+=`<g transform="translate(${f(t[0])} ${f(t[1]-6)}) scale(1.3)">${P.smoke(0,0,1)}</g>`;}
 s+=iso.box(x0,y0,0,x1,y1,64,{fill:'#c9ccd2',tex:'concrete',noTop:true,left:{content:({w,h})=>[0,1,2].map(i=>`<rect x="${10+i*w/3}" y="${h-38}" width="${w/3-20}" height="38" fill="#3a3e46" stroke="${INK}" stroke-width="2.6"/>`+Array.from({length:7},(_,j)=>`<path d="M${10+i*w/3} ${h-38+j*5.4}h${w/3-20}" stroke="#5a5e68" stroke-width="1.2"/>`).join('')).join('')+`<rect x="0" y="6" width="${w}" height="12" fill="#2e5a9a"/>`+rowWins(w,8,14,8,6,{sill:false,mull:false,frame:'#2a2a30'})},right:{content:({w,h})=>`<rect x="0" y="6" width="${w}" height="12" fill="#2e5a9a"/>`+rowWins(w,26,16,20,4,{sill:false,frame:'#2a2a30'})}});
 s+=sawtooth(iso,x0,y0,x1,y1,64,4,16,{fill:'#8a9098',end:'#c9ccd2',endTex:'concrete'});
 // wheel logo on right face top
 s+=iso.onFace([x1,y1,60],[x1,y1-1,60],[x1,y1,59],`<g transform="translate(${(y1-y0)/2} 0)"><circle r="0"/></g>`);
 // office block front
 s+=iso.box(150,110,0,180,150,50,{fill:'#e8e4dc',tex:'concrete',left:{content:({w,h})=>rowWins(w,6,8,12,2,{sill:false})+rowWins(w,24,8,12,2,{sill:false})+W.door(w/2-6,h-16,12,16,{lit:true})},right:{content:({w,h})=>rowWins(w,6,8,12,3,{sill:false})+rowWins(w,24,8,12,3,{sill:false})},top:{fill:'#b8bcc4'}});
 // finished cars lined up
 s+=P.car(iso,30,150,'#c0392b','x')+P.car(iso,64,150,'#2e6ab0','x')+P.car(iso,98,150,'#e8e4d8','x')+P.car(iso,30,172,'#e0a030','x')+P.car(iso,64,172,'#2e8a5a','x');
 s+=P.lamp(iso,140,186,52,{col:'#5a5f68'});
 return s;});

// ===== Era 7 Information Age =====
const L_=require('./lib');
const glassGrid=(seed,cw=10,ch=12,litP=.55,tint='#3f6d93')=>({x,y,w,h})=>{const r=L_.rng(seed);let o=`<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="url(#glassV)"/>`;
 for(let yy=y+2;yy<y+h-2;yy+=ch)for(let xx=x+1;xx<x+w-1;xx+=cw){if(r()<litP)o+=`<rect x="${xx+1}" y="${yy+1}" width="${cw-2}" height="${ch-2}" fill="${r()<.8?'#ffe6a0':'#bfe8ff'}" opacity="${f(.55+r()*.4)}"/>`;}
 for(let xx=x;xx<x+w;xx+=cw)o+=`<path d="M${xx} ${y}v${h}" stroke="#1a2a3a" stroke-width="1.2"/>`;for(let yy=y;yy<y+h;yy+=ch)o+=`<path d="M${x} ${yy}h${w}" stroke="#1a2a3a" stroke-width="1.6"/>`;
 o+=`<path d="M${x} ${y+h*0.7}L${x+w*0.6} ${y}" stroke="#fff" stroke-width="${w*0.12}" opacity=".12"/>`;return o;};
B.e7_t1=()=>wrap('concrete',iso=>{let s='';
 const x0=40,y0=50,x1=146,y1=128;
 s+=onPlot(iso,iso.boxShadow(x0,y0,x1,y1,90,.35));
 s+=iso.box(x0,y0,0,x1,y1,40,{fill:'#e8eaee',tex:'concrete',noTop:true,left:{content:({w,h})=>`<rect x="6" y="10" width="${w-12}" height="${h-10}" fill="#1a2030" stroke="${INK}" stroke-width="2.6"/>`+glassGrid(3,22,30,.0)({x:8,y:12,w:w-16,h:h-12})+`<rect x="8" y="12" width="${w-16}" height="${h-12}" fill="url(#winLit)" opacity=".55"/>`+[0,1,2].map(i=>`<rect x="${16+i*26}" y="${h-14}" width="14" height="10" fill="#2a3040" stroke="${INK}" stroke-width="1.2"/><rect x="${19+i*26}" y="${h-24}" width="8" height="10" rx="1.5" fill="#1a1e28" stroke="#6ad0ff" stroke-width="1"/>`).join('')},right:{content:({w,h})=>`<rect x="6" y="10" width="${w-12}" height="${h-16}" fill="url(#winLit)" opacity=".6" stroke="${INK}" stroke-width="2.4"/>`}});
 s+=iso.box(x0-3,y0-3,40,x1+3,y1+3,46,{fill:'#2a2e38',top:{fill:'#3a3e48'},left:{content:({w,h})=>`<rect x="0" y="1" width="${w}" height="${h-2}" fill="#2aa8e0" opacity=".9"/>`}});
 s+=iso.box(x0,y0,46,x1,y1-30,84,{fill:'#c8ccd4',tex:'concrete',noTop:true,left:{content:glassGrid(11,12,14,.5)},right:{content:glassGrid(12,12,14,.5)}});
 s+=flatRoof(iso,x0,y0,x1,y1-30,84,{fill:'#9aa0aa',pfill:'#d8dce4',ph:4,t:3});
 // phone pictogram sign on roof edge of lower block
 s+=iso.onFace([x0+66,y1+3,74],[x0+67,y1+3,74],[x0+66,y1+3,73],`<rect x="0" y="0" width="30" height="28" rx="5" fill="#141a28" stroke="${INK}" stroke-width="2.4"/><g filter="url(#glow)"><rect x="9" y="4" width="12" height="20" rx="2.5" fill="none" stroke="#6ad0ff" stroke-width="2.2"/><circle cx="15" cy="20" r="1.4" fill="#6ad0ff"/><path d="M12 7h6" stroke="#6ad0ff" stroke-width="1.4"/></g>`);
 s+=iso.box(x0+64,y1+1,46,x0+66,y1+4,74,{fill:'#3a3e48',ao:false,w:1.5});
 // antenna mast
 const ab=iso.P([70,70,84]);s+=`<path d="M${f(ab[0])} ${f(ab[1])}v-60" stroke="${INK}" stroke-width="4"/><path d="M${f(ab[0])} ${f(ab[1])}v-60" stroke="#b8bec8" stroke-width="2"/>`+[18,32,46].map(d=>`<path d="M${f(ab[0]-8)} ${f(ab[1]-d)}h16" stroke="${INK}" stroke-width="2.4"/>`).join('')+`<circle cx="${f(ab[0])}" cy="${f(ab[1]-62)}" r="3" fill="#ff4a4a" filter="url(#glow)"/>`;
 s+=P.dish(iso,110,66,84,9)+P.ac(iso,120,80,84,10);
 s+=P.tree(iso,170,60,12,'#4f8a4a')+P.tree(iso,176,100,12,'#4f8a4a')+P.lamp(iso,30,150,52,{col:'#5a5f68',glow:'#bfe8ff'})+P.car(iso,150,150,'#e8e4d8','y');
 return s;});

B.e7_t2=()=>wrap('concrete',iso=>{let s='';
 const x0=50,y0=50,x1=146,y1=140;
 s+=onPlot(iso,iso.boxShadow(x0,y0,x1,y1,190,.38));
 s+=iso.box(x0-8,y0-8,0,x1+8,y1+8,26,{fill:'#d8dce4',tex:'concrete',noTop:false,top:{fill:'#9aa0aa',tex:'concrete'},left:{content:({w,h})=>`<rect x="8" y="4" width="${w-16}" height="${h-4}" fill="url(#winLit)" opacity=".8" stroke="${INK}" stroke-width="2"/>`+Array.from({length:8},(_,i)=>`<path d="M${8+i*(w-16)/8} 4V${h}" stroke="#2a3040" stroke-width="1.4"/>`).join('')},right:{content:({w,h})=>`<rect x="8" y="4" width="${w-16}" height="${h-4}" fill="url(#winLit)" opacity=".7" stroke="${INK}" stroke-width="2"/>`}});
 s+=iso.box(x0,y0,26,x1,y1,150,{fill:'#5f88a8',noTop:true,left:{content:glassGrid(21,12,13,.45)},right:{content:glassGrid(22,12,13,.4)}});
 s+=iso.box(x0+12,y0+12,150,x1-12,y1-12,206,{fill:'#5f88a8',noTop:true,left:{content:glassGrid(23,12,13,.45)},right:{content:glassGrid(24,12,13,.4)}});
 // ledges
 s+=iso.box(x0-2,y0-2,150,x1+2,y1+2,154,{fill:'#d8dce4',top:{fill:'#8a909a',tex:'concrete'}}).replace('','');
 s+=iso.box(x0+12,y0+12,150,x1-12,y1-12,206,{fill:'#5f88a8',noTop:true,left:{content:glassGrid(23,12,13,.45)},right:{content:glassGrid(24,12,13,.4)}});
 s+=iso.box(x0+10,y0+10,206,x1-10,y1-10,212,{fill:'#d8dce4',top:{fill:'#5a606a',tex:'concrete'}});
 // helipad
 { const c=iso.P([98,95,212]);s+=`<ellipse cx="${f(c[0])}" cy="${f(c[1])}" rx="30" ry="15" fill="#3a3e48" stroke="#f1c85a" stroke-width="2.4"/><path d="M${f(c[0]-8)} ${f(c[1])}h16M${f(c[0])} ${f(c[1]-4)}v8" stroke="#f1c85a" stroke-width="3"/>`;}
 const ab=iso.P([x0+16,y0+16,212]);s+=`<path d="M${f(ab[0])} ${f(ab[1])}v-24" stroke="${INK}" stroke-width="3.5"/><path d="M${f(ab[0])} ${f(ab[1])}v-24" stroke="#c8ccd4" stroke-width="1.6"/><circle cx="${f(ab[0])}" cy="${f(ab[1]-26)}" r="3" fill="#ff4a4a" filter="url(#glow)"/>`;
 s+=P.tree(iso,30,170,12,'#4f8a4a')+P.tree(iso,176,40,12,'#4f8a4a')+P.tree(iso,176,176,12,'#4f8a4a')+P.lamp(iso,100,176,52,{col:'#5a5f68',glow:'#bfe8ff'})+P.car(iso,160,140,'#2a2e38','y');
 return s;});

B.e7_t3=()=>wrap('concrete',iso=>{let s='';
 const x0=24,y0=30,x1=150,y1=120;
 s+=onPlot(iso,iso.boxShadow(x0,y0,x1,y1,70,.35));
 const vents=({w,h})=>{let o='';for(let i=0;i<Math.floor(w/22);i++){o+=`<rect x="${6+i*22}" y="10" width="16" height="${h-24}" fill="#3a3e48" stroke="${INK}" stroke-width="1.8"/>`;for(let j=0;j<(h-26)/4;j++)o+=`<path d="M${7+i*22} ${12+j*4}h14" stroke="#6a707a" stroke-width="1.2"/>`;}return o+`<rect x="0" y="${h-8}" width="${w}" height="3" fill="#3ad0ff" opacity=".9" filter="url(#glow)"/>`;};
 s+=iso.box(x0,y0,0,x1,y1,56,{fill:'#d0d4dc',tex:'concrete',noTop:true,left:{content:vents},right:{content:a=>vents(a)+W.door(a.w-24,a.h-26,16,26,{col:'#5a606a'})}});
 s+=flatRoof(iso,x0,y0,x1,y1,56,{fill:'#9aa0aa',pfill:'#e0e4ea',ph:4,t:3});
 for(let i=0;i<4;i++)for(let j=0;j<2;j++)s+=P.ac(iso,36+i*26,44+j*34,56,18);
 s+=P.dish(iso,40,100,56,12)+P.dish(iso,130,100,56,10);
 // second hall with glowing server window
 s+=onPlot(iso,iso.boxShadow(120,128,186,186,40,.3));
 s+=iso.box(120,128,0,180,184,36,{fill:'#2a2e3a',tex:'plate',texOp:.5,left:{content:({w,h})=>`<rect x="6" y="6" width="${w-12}" height="${h-14}" fill="#0a1020" stroke="${INK}" stroke-width="2"/>`+Array.from({length:6},(_,i)=>`<rect x="${10+i*(w-20)/6}" y="9" width="${(w-20)/6-3}" height="${h-20}" fill="#141c30" stroke="#2a3a5a" stroke-width="1"/>`+Array.from({length:5},(_,j)=>`<circle cx="${14+i*(w-20)/6}" cy="${13+j*4}" r="1" fill="${(i+j)%3?'#3ad0ff':'#6aff9a'}"/>`).join('')).join('')+`<rect x="6" y="6" width="${w-12}" height="${h-14}" fill="#3ad0ff" opacity=".12"/>`},right:{content:({w,h})=>`<rect x="0" y="${h-6}" width="${w}" height="3" fill="#3ad0ff" filter="url(#glow)"/>`},top:{fill:'#4a4e5a'}});
 // generators / tanks
 s+=iso.cyl(176,60,10,0,30,'#e8eaee',{bands:[10,20],bandCol:'#5a606a'})+iso.cyl(176,90,10,0,30,'#e8eaee',{bands:[10,20],bandCol:'#5a606a'});
 // fence line
 s+=P.pipe(iso,[[24,140,0],[24,140,14]],1,'#8a909a')+P.lamp(iso,30,150,52,{col:'#5a5f68',glow:'#bfe8ff'})+P.lamp(iso,100,150,52,{col:'#5a5f68',glow:'#bfe8ff'})+P.tree(iso,60,180,11,'#4f8a4a');
 return s;});

// ===== Era 8 Space Age =====
const neon='#5ef0ff';
B.e8_t1=()=>wrap('metal',iso=>{let s='';
 const x0=40,y0=46,x1=140,y1=126;
 s+=onPlot(iso,iso.boxShadow(x0,y0,x1,y1,70,.35));
 s+=iso.box(x0,y0,0,x1,y1,50,{fill:'#d8dcea',tex:'scifi',noTop:true,left:{content:({w,h})=>`<path d="M10 ${h}V18Q10 8 20 8H${w-20}Q${w-10} 8 ${w-10} 18V${h}Z" fill="#0a1020" stroke="${INK}" stroke-width="3"/><path d="M14 ${h}V20Q14 12 22 12H${w-22}Q${w-14} 12 ${w-14} 20V${h}Z" fill="${neon}" opacity=".18"/>`+Array.from({length:5},(_,i)=>`<path d="M14 ${18+i*7}H${w-14}" stroke="#4a5a7a" stroke-width="1.5" opacity=".6"/>`).join('')+`<path d="M10 ${h-2}H${w-10}" stroke="${neon}" stroke-width="2.4" filter="url(#glow)"/>`},right:{content:({w,h})=>`<rect x="${w/2-14}" y="12" width="28" height="12" rx="6" fill="${neon}" opacity=".7" stroke="${INK}" stroke-width="2"/>`+`<path d="M0 ${h-6}H${w}" stroke="${neon}" stroke-width="2" filter="url(#glow)"/>`}});
 // rounded roof shell
 s+=iso.box(x0-3,y0-3,50,x1+3,y1+3,56,{fill:'#b8bed0',top:{fill:'#9aa2b8',tex:'scifi'}});
 s+=iso.dome(78,74,20,56,'#8ac8e8',{h:26});
 s+=iso.cyl(122,70,6,56,70,'#e0e4ee',{bands:[64]});
 // hover car with glow
 const hc=iso.P([146,150,0]);s+=`<ellipse cx="${f(hc[0])}" cy="${f(hc[1])}" rx="48" ry="18" fill="${neon}" opacity=".45" filter="url(#blur8)"/><ellipse cx="${f(hc[0])}" cy="${f(hc[1])}" rx="22" ry="9" fill="none" stroke="${neon}" stroke-width="2" opacity=".8"/>`;
 s+=`<g transform="translate(${f(hc[0])} ${f(hc[1]-30)}) scale(1.5)"><path d="M-30 6 Q-26 -6 -8 -8 L14 -10 Q30 -8 32 2 Q30 10 10 12 L-18 12 Q-30 12 -30 6Z" fill="#c0392b" stroke="${INK}" stroke-width="2.6"/><path d="M-12 -7 Q-4 -20 12 -18 Q22 -16 24 -6 L14 -10 Z" fill="#1a2a44" stroke="${INK}" stroke-width="2.2"/><path d="M-8 -9 Q-2 -17 10 -15" stroke="#9fe8ff" stroke-width="2" fill="none"/><path d="M-26 4 Q0 0 30 2" stroke="#fff" stroke-width="1.6" opacity=".45" fill="none"/><path d="M-22 12h34" stroke="${neon}" stroke-width="3" filter="url(#glow)"/><circle cx="30" cy="2" r="2" fill="#fff6c0"/></g>`;
 s+=P.glowPad(iso,60,160,14)+P.lamp(iso,180,60,50,{col:'#3a4058',glow:neon})+P.lamp(iso,26,130,50,{col:'#3a4058',glow:neon});
 s+=iso.box(176,90,0,190,104,12,{fill:'#5a6280',tex:'plate',left:{content:({w,h})=>`<rect x="2" y="3" width="${w-4}" height="2" fill="${neon}"/>`}});
 return s;});

B.e8_t2=()=>wrap('metal',iso=>{let s='';
 s+=onPlot(iso,iso.boxShadow(60,60,136,136,170,.35));
 s+=iso.cyl(98,98,64,0,12,'#6a7490',{tex:'scifi',topFill:'#7a84a0'});
 s+=P.glowPad(iso,98,98,56,neon,12);
 s+=iso.cyl(98,98,34,12,40,'#c8cde0',{tex:'scifi',top:false});
 { const c=iso.P([98,98,22]);const rx=34*Math.SQRT2;for(const t of[-.75,-.45,-.15,.15,.45,.75])s+=`<rect x="${f(c[0]+t*rx-3)}" y="${f(c[1]+Math.sqrt(1-t*t)*rx/2-10)}" width="6" height="14" rx="3" fill="${neon}" opacity=".9"/>`;}
 s+=iso.cyl(98,98,24,40,120,'#dfe3ef',{tex:'scifi',top:false,bands:[70,95]});
 { const c=iso.P([98,98,82]);const rx=24*Math.SQRT2;for(const t of[-.6,-.2,.2,.6])s+=`<rect x="${f(c[0]+t*rx-2.5)}" y="${f(c[1]+Math.sqrt(1-t*t)*rx/2-14)}" width="5" height="28" rx="2.5" fill="#ffe6a0" opacity=".9"/>`;}
 const c=iso.P([98,98,138]);const rx=92,ry=40;
 const ring=(sweep,front)=>`<path d="M${f(c[0]-rx)} ${f(c[1])} A${rx} ${ry} 0 0 ${sweep} ${f(c[0]+rx)} ${f(c[1])}" fill="none" stroke="${INK}" stroke-width="22"/><path d="M${f(c[0]-rx)} ${f(c[1])} A${rx} ${ry} 0 0 ${sweep} ${f(c[0]+rx)} ${f(c[1])}" fill="none" stroke="${front?'#b8c0d8':'#7a84a0'}" stroke-width="16"/><path d="M${f(c[0]-rx)} ${f(c[1]-5)} A${rx} ${ry} 0 0 ${sweep} ${f(c[0]+rx)} ${f(c[1]-5)}" fill="none" stroke="${front?'#e8ecf6':'#9aa4c0'}" stroke-width="4"/>`+(front?`<path d="M${f(c[0]-rx)} ${f(c[1]+3)} A${rx} ${ry} 0 0 0 ${f(c[0]+rx)} ${f(c[1]+3)}" fill="none" stroke="${neon}" stroke-width="3" stroke-dasharray="6 7" filter="url(#glow)"/>`:'');
 s+=ring(1,false);
 // spokes behind tower
 for(const a of[-0.6,-2.5]){const px=c[0]+Math.cos(a)*rx,py=c[1]+Math.sin(a)*ry;s+=`<path d="M${f(c[0])} ${f(c[1])}L${f(px)} ${f(py)}" stroke="${INK}" stroke-width="7"/><path d="M${f(c[0])} ${f(c[1])}L${f(px)} ${f(py)}" stroke="#8a94b0" stroke-width="3.5"/>`;}
 s+=iso.cyl(98,98,16,120,186,'#c8cde0',{tex:'scifi',top:false,bands:[150]});
 s+=iso.cyl(98,98,9,186,206,'#e8ecf6',{topFill:'#ffffff'});
 for(const a of[0.6,2.5]){const px=c[0]+Math.cos(a)*rx,py=c[1]+Math.sin(a)*ry;s+=`<path d="M${f(c[0])} ${f(c[1])}L${f(px)} ${f(py)}" stroke="${INK}" stroke-width="7"/><path d="M${f(c[0])} ${f(c[1])}L${f(px)} ${f(py)}" stroke="#aab2c8" stroke-width="3.5"/>`;}
 s+=ring(0,true);
 { const t=iso.P([98,98,206]);s+=`<path d="M${f(t[0])} ${f(t[1])}v-20" stroke="${INK}" stroke-width="3"/><circle cx="${f(t[0])}" cy="${f(t[1]-22)}" r="5" fill="#ff6a9a" filter="url(#glow)"/>`;}
 // shuttle parked on the pad front-right
 const sc=iso.P([170,150,0]);s+=`<ellipse cx="${f(sc[0])}" cy="${f(sc[1])}" rx="26" ry="10" fill="#000" opacity=".3" filter="url(#blur2)"/><g transform="translate(${f(sc[0])} ${f(sc[1]-12)}) rotate(-26)"><path d="M-28 4 L-20 -6 L18 -8 Q32 -4 30 2 L18 8 L-20 8Z" fill="#e8ecf6" stroke="${INK}" stroke-width="2.6"/><path d="M-14 -6 L-26 -18 L-20 -18 L-2 -7Z" fill="#c0392b" stroke="${INK}" stroke-width="2"/><path d="M-12 8 L-24 16 L-16 16 L4 8Z" fill="#c0392b" stroke="${INK}" stroke-width="2"/><path d="M14 -6 Q26 -4 26 0 L16 0Z" fill="#1a2a44" stroke="${INK}" stroke-width="1.6"/><path d="M-20 0h34" stroke="#9aa4c0" stroke-width="1.5"/><path d="M-30 -1 L-38 2 L-30 5Z" fill="${neon}" filter="url(#glow)"/></g>`;
 const pod=(x,y,col)=>iso.box(x,y,0,x+16,y+10,10,{fill:col,tex:'plate',ao:false,left:{content:({w,h})=>`<rect x="2" y="${h/2-1}" width="${w-4}" height="2" fill="${neon}"/>`}});
 s+=pod(26,150,'#3a7ab8')+pod(26,166,'#e0a030')+pod(28,158,'#c0392b').replace(/z/,'z')+pod(44,176,'#e0a030');
 s+=P.lamp(iso,186,40,50,{col:'#3a4058',glow:neon});
 return s;});

B.e8_t3=()=>wrap('metal',iso=>{let s='';
 s+=onPlot(iso,iso.boxShadow(40,40,160,160,80,.35));
 // cooling towers back
 for(const [x,y] of [[44,40],[150,36]]){s+=iso.cyl(x,y,18,0,90,'#e0e4ee',{tex:'scifi',bands:[30],topFill:'#3a4058'});const t=iso.P([x,y,90]);s+=`<g transform="translate(${f(t[0])} ${f(t[1]-4)}) scale(1.2)">${P.smoke(0,0,1).replace(/#d9d6d0/g,'#e8f4ff')}</g>`;}
 // torus reactor: base + ring + core
 s+=iso.cyl(100,104,56,0,22,'#5a6280',{tex:'plate',topFill:'#6a7290'});
 const c=iso.P([100,104,40]);const rx=74,ry=37;
 s+=`<ellipse cx="${f(c[0])}" cy="${f(c[1])}" rx="${rx+16}" ry="${ry+10}" fill="${neon}" opacity=".25" filter="url(#blur16)"/>`;
 const torusBack=`<path d="M${f(c[0]-rx)} ${f(c[1])} A${rx} ${ry} 0 0 1 ${f(c[0]+rx)} ${f(c[1])}" fill="none" stroke="${INK}" stroke-width="30"/><path d="M${f(c[0]-rx)} ${f(c[1])} A${rx} ${ry} 0 0 1 ${f(c[0]+rx)} ${f(c[1])}" fill="none" stroke="#6a7494" stroke-width="24"/><path d="M${f(c[0]-rx)} ${f(c[1]-6)} A${rx} ${ry} 0 0 1 ${f(c[0]+rx)} ${f(c[1]-6)}" fill="none" stroke="#9aa4c0" stroke-width="6"/>`;
 s+=torusBack;
 // core sphere
 s+=`<radialGradient id="core"><stop offset="0" stop-color="#ffffff"/><stop offset=".35" stop-color="#bff8ff"/><stop offset=".75" stop-color="${neon}"/><stop offset="1" stop-color="#1a6a9a"/></radialGradient>`;
 s+=`<circle cx="${f(c[0])}" cy="${f(c[1]-26)}" r="44" fill="${neon}" opacity=".5" filter="url(#blur16)"/><circle cx="${f(c[0])}" cy="${f(c[1]-26)}" r="26" fill="url(#core)" stroke="${INK}" stroke-width="3"/><path d="M${f(c[0])} ${f(c[1]-52)}V${f(c[1]-160)}" stroke="${neon}" stroke-width="6" opacity=".35" filter="url(#blur4)"/><path d="M${f(c[0])} ${f(c[1]-52)}V${f(c[1]-150)}" stroke="#e8ffff" stroke-width="2" opacity=".8"/>`;
 // containment struts
 for(const t of [-.8,-.3,.3,.8]){s+=`<path d="M${f(c[0]+t*rx*0.55)} ${f(c[1]+4)}L${f(c[0]+t*14)} ${f(c[1]-26)}" stroke="${INK}" stroke-width="5"/><path d="M${f(c[0]+t*rx*0.55)} ${f(c[1]+4)}L${f(c[0]+t*14)} ${f(c[1]-26)}" stroke="#aab2c8" stroke-width="2.4"/>`;}
 const torusFront=`<path d="M${f(c[0]-rx)} ${f(c[1])} A${rx} ${ry} 0 0 0 ${f(c[0]+rx)} ${f(c[1])}" fill="none" stroke="${INK}" stroke-width="30"/><path d="M${f(c[0]-rx)} ${f(c[1])} A${rx} ${ry} 0 0 0 ${f(c[0]+rx)} ${f(c[1])}" fill="none" stroke="#8a94b4" stroke-width="24"/><path d="M${f(c[0]-rx)} ${f(c[1]+8)} A${rx} ${ry} 0 0 0 ${f(c[0]+rx)} ${f(c[1]+8)}" fill="none" stroke="#4a5272" stroke-width="7"/><path d="M${f(c[0]-rx)} ${f(c[1]-7)} A${rx} ${ry} 0 0 0 ${f(c[0]+rx)} ${f(c[1]-7)}" fill="none" stroke="#c8d0e8" stroke-width="4"/>`;
 s+=torusFront;
 for(let i=0;i<9;i++){const a=Math.PI*(0.08+i*0.105);const px=c[0]-Math.cos(a)*rx,py=c[1]+Math.sin(a)*ry;s+=`<rect x="${f(px-3)}" y="${f(py-5)}" width="6" height="10" rx="2" fill="${neon}" filter="url(#glow)"/>`;}
 s+=P.pipe(iso,[[30,150,0],[30,150,20],[50,140,20]],4,'#8a94b0')+P.pipe(iso,[[180,120,0],[180,120,24],[160,120,24]],4,'#8a94b0');
 s+=P.lamp(iso,30,186,50,{col:'#3a4058',glow:neon})+P.lamp(iso,186,170,50,{col:'#3a4058',glow:neon});
 return s;});

// ===== construction site =====
B.construct=()=>wrap('dirt',iso=>{let s='';
 const x0=40,y0=40,x1=160,y1=150,H=110;
 s+=onPlot(iso,iso.boxShadow(x0,y0,x1,y1,H,.35));
 // back poles first
 const pole=(x,y)=>iso.box(x-2.5,y-2.5,0,x+2.5,y+2.5,H,{fill:'#b58550',tex:'grain',ao:false,w:2.2});
 const beamX=(y,z)=>iso.box(x0,y-2,z-3,x1,y+2,z+1,{fill:'#a87444',ao:false,w:2});
 const beamY=(x,z)=>iso.box(x-2,y0,z-3,x+2,y1,z+1,{fill:'#a87444',ao:false,w:2});
 s+=pole(x0,y0)+pole(x1,y0)+pole(x0,y1);
 for(const z of[36,72,H])s+=beamX(y0,z)+beamY(x0,z);
 // tarp: covers top + left + right faces with sag; green canvas
 const tarp='#4f7a4a';
 s+=iso.face([[x0-4,y0-4,H+6],[x1+4,y0-4,H+6],[x1+4,y1+4,H+6],[x0-4,y1+4,H+6]],{fill:tarp,ao:false,tone:.85,content:({x,y,w,h})=>`<path d="M${x} ${y+h*0.5}Q${x+w*0.5} ${y+h*0.62} ${x+w} ${y+h*0.5}M${x+w*0.5} ${y}Q${x+w*0.58} ${y+h*0.5} ${x+w*0.5} ${y+h}" stroke="#2a4a2a" stroke-width="3" fill="none" opacity=".5"/>`});
 const drape=(face)=>({w,h})=>{let o='';for(let i=1;i<6;i++){const xx=i*w/6;o+=`<path d="M${xx} 0Q${xx+6} ${h*0.5} ${xx-2} ${h*0.72}" stroke="#2a4a2a" stroke-width="2.2" fill="none" opacity=".55"/><path d="M${xx+3} 2Q${xx+9} ${h*0.45} ${xx+2} ${h*0.68}" stroke="#9ac08a" stroke-width="1.6" fill="none" opacity=".45"/>`;}
  // rope ties
  o+=`<path d="M0 ${h*0.35}H${w}" stroke="#d8c08a" stroke-width="2"/>`;return o;};
 // tarp hangs down ~70% of height, ragged bottom
 const hz=H*0.32;
 s+=iso.face([[x0-4,y1+4,H+6],[x1+4,y1+4,H+6],[x1+4,y1+4,hz],[x1-20,y1+4,hz-6],[x0+60,y1+4,hz+4],[x0+20,y1+4,hz-4],[x0-4,y1+4,hz]],{fill:tarp,content:drape(),ao:.4});
 s+=iso.face([[x1+4,y1+4,H+6],[x1+4,y0-4,H+6],[x1+4,y0-4,hz+6],[x1+4,y0+40,hz-2],[x1+4,y1-30,hz+4],[x1+4,y1+4,hz]],{fill:tarp,content:drape(),ao:.4});
 // front poles visible below tarp
 s+=pole(x1,y1);
 // exterior scaffold layer on the left face: poles poking above the tarp + walk planks
 for(const x of[x0+6,x0+46,x0+86,x1-4]){s+=iso.box(x-2.5,y1+12,0,x+2.5,y1+17,H+22,{fill:'#c08a50',tex:'grain',ao:false,w:2.2});}
 for(const z of[38,76]){s+=iso.box(x0,y1+8,z-4,x1+2,y1+20,z,{fill:'#b07a44',tex:'grain',ao:false,w:2.2,top:{tex:'siding',texT:'rotate(90)'}});
  s+=iso.box(x0,y1+17,z+12,x1+2,y1+19,z+15,{fill:'#c08a50',ao:false,w:1.8});}
 for(const y of[y0+10,y0+50,y0+90]){s+=iso.box(x1+12,y-2.5,0,x1+17,y+2.5,H+18,{fill:'#c08a50',tex:'grain',ao:false,w:2.2});}
 s+=iso.box(x1+8,y0,56,x1+20,y1+4,60,{fill:'#b07a44',tex:'grain',ao:false,w:2.2});
 s+=iso.box(x0+4,y1+5,0,x0+9,y1+10,hz,{fill:'#b58550',ao:false,w:2});
 // ladder leaning
 const lb=iso.P([x0+70,y1+22,0]),lt=iso.P([x0+70,y1+6,hz+10]);s+=`<path d="M${f(lb[0]-6)} ${f(lb[1])}L${f(lt[0]-6)} ${f(lt[1])}M${f(lb[0]+6)} ${f(lb[1])}L${f(lt[0]+6)} ${f(lt[1])}" stroke="${INK}" stroke-width="5"/><path d="M${f(lb[0]-6)} ${f(lb[1])}L${f(lt[0]-6)} ${f(lt[1])}M${f(lb[0]+6)} ${f(lb[1])}L${f(lt[0]+6)} ${f(lt[1])}" stroke="#c9945a" stroke-width="2.6"/>`+[.15,.3,.45,.6,.75,.9].map(t=>{const y=lb[1]+(lt[1]-lb[1])*t,x=lb[0]+(lt[0]-lb[0])*t;return `<path d="M${f(x-6)} ${f(y)}h12" stroke="${INK}" stroke-width="3.5"/><path d="M${f(x-6)} ${f(y)}h12" stroke="#c9945a" stroke-width="1.6"/>`;}).join('');
 // planks pile + bricks pallet + barrier
 for(let i=0;i<4;i++)s+=iso.box(150,160+i*0.5,i*3,192,168+i*0.5,i*3+3,{fill:i%2?'#c9945a':'#b58550',tex:'grain',ao:false,w:1.8});
 s+=iso.box(30,166,0,52,186,4,{fill:'#8a6440',ao:false})+iso.box(32,168,4,50,184,16,{fill:'#a85a40',tex:'brick',top:{tex:'brick'}});
 s+=P.barrel(iso,180,40,6,13,'#d0a030')+P.sack(iso,176,70,6,'#bab3a4')+P.sack(iso,186,80,6,'#bab3a4');
 // striped barrier
 s+=iso.onFace([84,192,14],[85,192,14],[84,192,13],`<rect x="0" y="0" width="40" height="6" fill="#f1c85a" stroke="${INK}" stroke-width="2"/>`+[0,1,2,3].map(i=>`<path d="M${4+i*10} 6l6 -6h4l-6 6z" fill="#2a2a2a"/>`).join('')+`<rect x="2" y="6" width="3" height="10" fill="#5a5a60" stroke="${INK}" stroke-width="1.2"/><rect x="35" y="6" width="3" height="10" fill="#5a5a60" stroke="${INK}" stroke-width="1.2"/>`);
 return s;});

module.exports=B;
if(require.main===module){const only=process.argv[2];
 const items=Object.entries(B).filter(([k])=>!only||k.startsWith(only)).map(([k,fn])=>({name:k==='construct'?'construct':'prop_'+k,w:512,h:512,svg:fn(),grain:4}));
 renderAll(items);}
