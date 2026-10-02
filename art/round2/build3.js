// Era country scenes for the COUNTRY tab (Kash 1 Oct): what your country looks like in each era. 480x220, dossier style.
const {chromium}=require('playwright');const fs=require('fs');const path=require('path');
const OUT='out3';const INK='#0b0d10';
const S=(d,fill,w=5)=>`<path d="${d}" fill="${INK}" stroke="${INK}" stroke-width="${w}" stroke-linejoin="round"/><path d="${d}" fill="${fill}"/>`;
const R=(x,y,w,h,fill,sw=4)=>S(`M${x} ${y} h${w} v${h} h${-w}z`,fill,sw);
const win=(x,y,cols,rows,dx,dy,c='#ffd77a')=>{let o='';for(let i=0;i<cols;i++)for(let j=0;j<rows;j++)o+=`<rect x="${x+i*dx}" y="${y+j*dy}" width="${dx*0.45}" height="${dy*0.5}" fill="${c}" opacity=".85"/>`;return o;};
const scene=(sky1,sky2,ground,body,sun='#f6e3a6')=>`<svg id="x" width="480" height="220" viewBox="0 0 480 220"><defs>
<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${sky1}"/><stop offset="1" stop-color="${sky2}"/></linearGradient>
<linearGradient id="gr" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${ground}"/><stop offset="1" stop-color="#8f7a50"/></linearGradient>
<linearGradient id="stone" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e2cfa3"/><stop offset="1" stop-color="#b59d6c"/></linearGradient>
<linearGradient id="grey" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9aa3ad"/><stop offset="1" stop-color="#5d6670"/></linearGradient>
<linearGradient id="dark" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4a525c"/><stop offset="1" stop-color="#262b31"/></linearGradient>
<linearGradient id="glass" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#9fd3f0"/><stop offset="1" stop-color="#3f6f99"/></linearGradient>
<linearGradient id="gold" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffe08a"/><stop offset="1" stop-color="#c99a2e"/></linearGradient>
<linearGradient id="red" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#d9544a"/><stop offset="1" stop-color="#8f2a23"/></linearGradient>
<linearGradient id="wood" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#b07a48"/><stop offset="1" stop-color="#6e4627"/></linearGradient>
</defs><rect width="480" height="220" fill="url(#sky)"/><circle cx="400" cy="52" r="26" fill="${sun}" opacity=".9"/>
<path d="M0 150 C80 140 140 160 220 150 C300 140 380 158 480 148 L480 220 L0 220Z" fill="url(#gr)"/>${body}
<rect x="1.5" y="1.5" width="477" height="217" rx="6" fill="none" stroke="${INK}" stroke-width="3"/></svg>`;
const hut=(x)=>S(`M${x} 160 l18 -16 l18 16z`,'url(#wood)',4)+R(x+4,160,28,14,'#c9a46a',4);
const items={};
items.era_1=scene('#f2b56b','#f7dca4','#d9bf86',
 S('M150 168 h180 l-20 -28 h-140z','url(#stone)')+S('M180 140 h120 l-18 -28 h-84z','url(#stone)')+S('M206 112 h68 l-14 -26 h-40z','url(#stone)')+R(232,70,16,16,'url(#red)',4)
 +hut(40)+hut(90)+hut(370)+hut(420)+S('M20 186 C60 178 110 190 150 182','none',3));
items.era_2=scene('#8fc3e8','#e9eef0','#cdbb8a',
 S('M140 172 h200 v-12 h-200z','url(#stone)')+S('M150 160 h180 v-8 h-180z','url(#stone)')+[0,1,2,3,4,5,6].map(i=>R(160+i*25,104,12,48,'#efe4c6',3)).join('')
 +S('M146 104 L240 64 L334 104Z','url(#stone)')+S('M40 176 h60 v-40 h-60z','url(#stone)')+S('M36 136 h68 l-34 -20z','url(#red)')+S('M380 176 h60 v-40 h-60z','url(#stone)')+S('M376 136 h68 l-34 -20z','url(#red)'));
items.era_3=scene('#7a8fb3','#d8d2c0','#9fae73',
 R(150,108,180,64,'url(#grey)')+[0,1,2,3,4,5,6,7,8].map(i=>R(150+i*20,98,10,12,'url(#grey)',3)).join('')+R(130,70,40,102,'url(#grey)')+R(310,70,40,102,'url(#grey)')
 +S('M126 70 L150 40 L174 70Z','url(#red)')+S('M306 70 L330 40 L354 70Z','url(#red)')+S('M220 172 v-36 a20 20 0 0 1 40 0 v36z','url(#wood)',4)+R(232,30,2,40,INK,1)+S('M234 30 h22 l-6 7 l6 7 h-22z','url(#gold)',3)
 +hut(40)+hut(400));
items.era_4=scene('#6f9fd0','#f0e6cf','#a9b47a',
 R(110,110,260,62,'url(#stone)')+S('M200 110 a40 40 0 0 1 80 0z','url(#grey)')+R(236,52,8,22,'url(#gold)',3)+[0,1,2,3,4,5,6,7,8,9,10,11].map(i=>R(122+i*20,124,10,18,'#3f5b84',2)).join('')
 +S('M110 110 h260 l-10 -10 h-240z','url(#stone)')+R(30,140,60,34,'url(#stone)')+R(390,140,60,34,'url(#stone)')+S('M228 172 h24 v-26 h-24z','url(#wood)',3));
items.era_5=scene('#9a9a92','#d9cfb6','#9a8f6c',
 [[40,96],[90,110],[330,100],[390,90]].map(([x,h])=>R(x,172-h+40,14,h-40,'#6b3a2c',3)+`<circle cx="${x+7}" cy="${172-h+30}" r="12" fill="#cfcfcf" opacity=".7"/><circle cx="${x+16}" cy="${172-h+14}" r="16" fill="#cfcfcf" opacity=".55"/>`).join('')
 +R(20,130,120,42,'url(#red)')+R(320,128,140,44,'url(#red)')+R(170,90,140,82,'url(#grey)')+win(182,100,6,4,22,18)+S('M166 90 h148 l-74 -30z','url(#dark)')+R(232,40,16,22,'url(#dark)',3));
items.era_6=scene('#5d8fc6','#d7e4ef','#8e9b7a',
 R(40,90,60,82,'url(#grey)')+win(48,98,3,4,18,18)+R(110,60,70,112,'url(#dark)')+win(118,70,3,5,22,20)+R(190,30,90,142,'url(#grey)')+win(200,40,4,7,20,18)
 +R(290,70,60,102,'url(#dark)')+win(298,80,3,5,18,18)+R(360,100,80,72,'url(#grey)')+win(368,108,4,3,18,20)+R(232,10,6,22,INK,1));
items.era_7=scene('#2b3f6b','#6f8fb8','#55627a',
 S('M60 172 v-110 l30 -20 v130z','url(#glass)')+S('M120 172 v-140 l40 -16 v156z','url(#glass)')+S('M200 172 v-160 h50 v160z','url(#glass)')+R(222,0,4,14,INK,1)
 +S('M280 172 v-120 l46 -20 v140z','url(#glass)')+S('M350 172 v-90 h60 v90z','url(#glass)')+win(206,24,2,8,22,18,'#e6f6ff')+`<circle cx="420" cy="40" r="3" fill="#fff"/><circle cx="60" cy="30" r="2" fill="#fff"/>`,'#e8f0ff');
items.era_8=scene('#0e1430','#3a2f6b','#3c3f58',
 S('M90 172 C90 120 110 80 120 40 C130 80 150 120 150 172Z','url(#glass)')+S('M200 172 C200 100 225 50 240 10 C255 50 280 100 280 172Z','url(#gold)')+S('M330 172 C330 120 350 90 360 60 C370 90 390 120 390 172Z','url(#glass)')
 +S('M420 172 l12 -50 l12 50z','url(#grey)')+S('M426 122 l6 -18 l6 18z','url(#red)',3)+`<ellipse cx="240" cy="110" rx="80" ry="10" fill="none" stroke="#7ff0e0" stroke-width="3" opacity=".8"/>`
 +[[40,30],[150,20],[300,40],[460,24],[380,80],[20,90]].map(([x,y])=>`<circle cx="${x}" cy="${y}" r="2" fill="#fff"/>`).join(''),'#cfd8ff');
(async()=>{fs.mkdirSync(OUT,{recursive:true});const b=await chromium.launch();const p=await b.newPage({deviceScaleFactor:1});
for(const [k,html] of Object.entries(items)){await p.setContent(`<html><body style="margin:0;background:transparent">${html}</body></html>`);
 await p.locator('#x').screenshot({path:path.join(OUT,'IC_'+k+'.png'),omitBackground:true});}
await b.close();console.log(Object.keys(items).length,'images');})();
