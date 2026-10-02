// officer_1..8: chest-up silhouettes in pure white; detail only through alpha (mask luminance): body 1.0, shade .80, lines .5
const L=require('./lib');const {f,renderAll}=L;
const O={};
const SH='#cfcfcf',LN='#7c7c7c',DK='#a8a8a8'; // mask tones -> alpha .81/.49/.66
const W_='#ffffff';
const fill=(d,c=W_)=>`<path d="${d}" fill="${c}"/>`;
const line=(d,w=5,c=LN)=>`<path d="${d}" fill="none" stroke="${c}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round"/>`;
const dot=(x,y,r,c=LN)=>`<circle cx="${x}" cy="${y}" r="${r}" fill="${c}"/>`;
// base bust: head turned slightly left, neck, shoulders (coat)
function bust({neck=true,shoulderY=372,broad=1}={}){const b=broad;
 let s=fill(`M${256-216*b} 512C${256-214*b} 452 ${256-190*b} 404 ${256-120*b} ${shoulderY}L196 350C206 346 214 340 216 330L296 330C298 340 306 346 316 350L${256+120*b} ${shoulderY}C${256+190*b} 404 ${256+214*b} 452 ${256+216*b} 512Z`);
 if(neck)s+=fill('M212 250L214 338Q256 356 298 338L300 250Z');
 // head: slight 3/4 left: nose bump on left
 s+=fill('M190 204C186 140 220 116 256 116C298 116 324 146 322 206C322 236 314 262 300 282C288 300 272 312 254 314C236 312 220 300 210 286C202 276 198 264 196 252C188 250 182 240 186 228L184 222C180 218 182 210 190 204Z');
 // ear right
 s+=fill('M318 210C330 204 338 214 334 232C332 246 324 252 316 250Z');
 // shading: right side of face & neck
 s+=fill('M300 250V338Q290 344 276 346L280 300C292 290 300 274 300 250Z',SH);
 s+=fill('M296 150C316 170 322 200 318 226C314 254 304 274 290 290C298 260 302 220 296 150Z',SH);
 s+=line('M321 222C326 220 328 228 326 236',3);
 return s;}
const coatShade=(b=1)=>fill(`M${256+130*b} 380C${256+190*b} 408 ${256+212*b} 452 ${256+216*b} 512H330C338 470 346 420 ${256+130*b} 380Z`,SH);
const epaulette=(cx,y,w=72,fringe=true)=>{let s=fill(`M${cx-w/2} ${y+8}Q${cx} ${y-14} ${cx+w/2} ${y+8}L${cx+w/2-4} ${y+22}Q${cx} ${y+12} ${cx-w/2+4} ${y+22}Z`);s+=line(`M${cx-w/2+6} ${y+10}Q${cx} ${y-6} ${cx+w/2-6} ${y+10}`,3,DK);
 if(fringe)for(let i=0;i<9;i++){const x=cx-w/2+6+i*(w-12)/8;s+=`<path d="M${f(x)} ${y+20}v26" stroke="#fff" stroke-width="7" stroke-linecap="round"/><path d="M${f(x+3)} ${y+22}v22" stroke="${LN}" stroke-width="1.6"/>`;}
 return s;};
const buttons=(x,y0,n,dy,r=6)=>Array.from({length:n},(_,i)=>dot(x,y0+i*dy,r,DK)+dot(x-1.5,y0+i*dy-1.5,r*0.4,W_)).join('');
const medal=(x,y)=>line(`M${x-6} ${y-18}L${x} ${y-6}L${x+6} ${y-18}`,3)+`<circle cx="${x}" cy="${y}" r="9" fill="${DK}"/><circle cx="${x}" cy="${y}" r="5" fill="${W_}"/>`;

O.officer_1=()=>{let s=bust();// peaked cap officer
 s+=coatShade();
 // high collar
 s+=fill('M200 330L216 312Q256 330 296 312L312 330L300 372Q256 388 212 372Z')+line('M206 332Q256 356 306 332',4)+line('M256 344V512',5)+line('M210 372L256 420L302 372',4,DK);
 s+=buttons(236,420,4,24,5.5)+buttons(276,420,4,24,5.5);
 s+=epaulette(124,360)+epaulette(388,360);
 // aiguillette cords
 s+=line('M150 380C180 430 220 446 246 430',4,DK)+line('M156 390C184 446 222 462 246 446',4,DK);
 // cap
 s+=fill('M150 168C140 130 190 96 256 96C326 96 372 128 362 168C344 182 168 182 150 168Z');
 s+=fill('M176 168H338L334 200H180Z');s+=line('M180 186H334',5,DK);
 s+=fill('M176 198C200 220 312 220 338 198L344 214C320 242 196 242 170 214Z',SH);s+=line('M172 212C200 236 316 236 342 212',4);
 s+=`<circle cx="256" cy="150" r="17" fill="${DK}"/><circle cx="256" cy="150" r="10" fill="${W_}"/>`+line('M226 138Q256 124 286 138',3,DK);
 s+=line('M160 162Q256 178 352 162',3,DK);
 return s;};

O.officer_2=()=>{let s=bust({broad:1.04});// bicorne admiral
 s+=coatShade(1.04);
 s+=fill('M196 330L214 306Q256 326 298 306L316 330L304 380Q256 394 208 380Z')+line('M204 334Q256 360 308 334',4);
 // lapels with lace
 s+=line('M214 380L246 512M298 380L266 512',5)+line('M222 392L250 500M290 392L262 500',2.5,DK);
 s+=buttons(226,420,4,26,6)+buttons(286,420,4,26,6);
 // sash
 s+=fill('M120 400L148 384L380 500L360 512H330Z',SH)+line('M132 394L372 508',3,LN);
 // big bullion epaulettes
 for(const cx of[118,394]){s+=fill(`M${cx-48} 368Q${cx} 334 ${cx+48} 368L${cx+44} 386Q${cx} 372 ${cx-44} 386Z`);s+=line(`M${cx-40} 368Q${cx} 344 ${cx+40} 368`,3,DK);for(let i=0;i<10;i++){const x=cx-42+i*9.3;s+=`<path d="M${f(x)} 384v36" stroke="#fff" stroke-width="8" stroke-linecap="round"/><path d="M${f(x+3)} 388q-3 14 0 28" stroke="${LN}" stroke-width="1.8" fill="none"/>`;}}
 // bicorne (worn athwart): wide crescent
 s+=fill('M78 196C96 120 176 58 256 52C336 58 416 120 434 196C398 172 340 164 256 166C172 164 114 172 78 196Z');
 s+=fill('M96 184C140 158 200 152 256 154C312 152 372 158 416 184C380 172 330 166 256 168C182 166 132 172 96 184Z',SH);
 s+=line('M104 172C150 120 210 100 256 100C302 100 362 120 408 172',4,DK);
 // cockade + gold loop
 s+=`<circle cx="306" cy="112" r="20" fill="${DK}"/><circle cx="306" cy="112" r="12" fill="${W_}"/><circle cx="306" cy="112" r="5" fill="${DK}"/>`+line('M306 90V150',4,LN);
 s+=line('M96 176Q256 150 416 176',3,LN);
 return s;};

O.officer_3=()=>{let s=bust();// plumed helmet general
 s+=coatShade();
 s+=fill('M198 330L214 310Q256 328 298 310L314 330L302 376Q256 390 210 376Z')+line('M206 334Q256 356 306 334',4);
 // gorget crescent
 s+=fill('M214 370Q256 396 298 370L292 392Q256 412 220 392Z',SH)+line('M218 376Q256 400 294 376',3);
 s+=line('M256 396V512',5);s+=buttons(256,424,4,24,6);
 // medals
 s+=medal(196,440)+medal(220,446)+medal(300,446);
 s+=epaulette(126,358)+epaulette(386,358);
 // helmet: dome + brim + crest + plume
 s+=fill('M170 196C166 128 206 92 256 92C306 92 346 128 342 196Z');
 s+=fill('M160 192H352L348 214H164Z')+line('M164 204H348',4,DK);
 s+=fill('M300 104C328 124 342 156 342 196H318C318 160 312 130 300 104Z',SH);
 s+=fill('M244 92C244 70 268 70 268 92L272 194H240Z')+line('M256 80V192',3,DK);
 // plume flowing up & back to the right
 s+=fill('M256 82C250 40 280 10 330 8C372 6 410 30 428 70C410 56 386 50 366 56C388 70 400 92 402 118C380 96 352 88 330 94C350 108 356 128 352 146C334 120 300 104 272 104Z');
 s+=line('M266 88C286 46 340 26 400 52',3,LN)+line('M272 98C304 70 346 66 384 92',3,LN)+line('M280 104C306 92 330 100 346 128',3,LN);
 // cheek guard
 s+=fill('M184 210C182 240 190 262 206 276L216 240Z',SH)+line('M186 214C186 240 194 260 208 272',3);
 return s;};

O.officer_4=()=>{let s=bust({broad:.96});// top hat diplomat
 s+=coatShade(.96);
 // shirt collar + cravat + lapels
 s+=fill('M212 324L256 360L300 324L316 340L256 420L196 340Z')+line('M214 326L256 362L298 326',4);
 s+=fill('M236 352Q256 344 276 352L270 372Q256 380 242 372Z',DK)+fill('M246 372L256 410L266 372Z',SH);
 s+=line('M196 340L232 512M316 340L280 512',5)+line('M190 360L140 470M322 360L372 470',4,DK);
 s+=line('M196 340L170 372L214 420M316 340L342 372L298 420',4);
 s+=buttons(256,452,3,24,5);
 // pocket square & order star
 s+=fill('M326 438l10 -14l10 14z',DK)+`<path d="M190 440l5 10l11 1l-8 7l3 11l-11 -6l-10 6l3 -11l-8 -7l11 -1z" fill="${DK}"/>`;
 // monocle chain
 s+=`<circle cx="280" cy="214" r="15" fill="none" stroke="${LN}" stroke-width="3.5"/>`+line('M294 222C320 260 318 320 310 360',2.5,LN);
 // top hat
 s+=fill('M196 158L204 40C230 30 284 30 310 40L318 158Z');s+=fill('M286 40C300 42 306 42 310 40L318 158H296Z',SH);
 s+=fill('M200 128H314V156H200Z',DK);s+=line('M200 128H314',3);
 s+=fill('M142 164C150 148 200 146 256 146C312 146 362 148 370 164C366 182 330 186 256 186C182 186 146 182 142 164Z');s+=line('M148 168C180 178 332 178 364 168',3.5);
 s+=line('M212 52C214 90 214 110 214 124',4,'#e6e6e6');
 return s;};

O.officer_5=()=>{let s=bust();// beret commander
 s+=coatShade();
 // field jacket: turtleneck + collar points + shoulder straps + pockets
 s+=fill('M212 318Q256 336 300 318L304 352Q256 370 208 352Z')+line('M210 334Q256 352 302 334',3,DK)+line('M212 346Q256 364 300 346',3,DK);
 s+=fill('M200 348L246 370L220 420Z')+fill('M312 348L266 370L292 420Z',SH)+line('M200 348L246 370L220 420Z',4)+line('M312 348L266 370L292 420Z',4);
 s+=line('M256 372V512',5);
 for(const cx of[132,380])s+=fill(`M${cx-40} 372L${cx+40} 362L${cx+42} 384L${cx-38} 394Z`)+line(`M${cx-40} 372L${cx+40} 362L${cx+42} 384L${cx-38} 394Z`,4)+dot(cx+30,376,5,DK);
 for(const cx of[196,316])s+=line(`M${cx-32} 440h64v50h-64z`,4)+line(`M${cx-34} 440l34 14l34 -14`,4);
 // collar rank tabs
 s+=fill('M214 384l18 -6l4 14l-18 6z',DK)+fill('M298 384l-18 -6l-4 14l18 6z',DK);
 // binocular strap
 s+=line('M150 372C190 430 220 470 236 512',6,DK);
 // beret: tilted to the right
 s+=fill('M176 170C150 140 172 98 230 88C290 78 356 96 372 128C380 146 368 164 340 170C300 178 220 180 176 170Z');
 s+=fill('M300 96C340 106 368 122 372 132C378 150 364 164 340 168C350 140 334 112 300 96Z',SH);
 s+=fill('M182 168C220 178 310 176 338 168L336 184C300 192 220 192 186 184Z',DK)+line('M184 176C220 186 304 184 336 176',3);
 // badge
 s+=`<path d="M208 128l10 -16l10 16l-10 18z" fill="${DK}"/><circle cx="218" cy="130" r="5" fill="${W_}"/>`;
 return s;};

O.officer_6=()=>{let s=bust({broad:1.04});// crowned noble
 // ermine cape collar
 s+=fill('M40 512C44 440 80 396 150 368C190 384 230 392 256 392C282 392 322 384 362 368C432 396 468 440 472 512Z');
 s+=fill('M362 368C432 396 468 440 472 512H400C396 452 386 410 362 368Z',SH);
 for(const [x,y] of[[100,450],[150,420],[200,440],[150,480],[250,470],[310,440],[360,420],[410,450],[360,480],[90,500],[420,500],[220,500],[300,500]])s+=`<path d="M${x} ${y}l-4 10h8z" fill="${LN}"/><circle cx="${x}" cy="${y-2}" r="3" fill="${LN}"/>`;
 s+=line('M150 368C190 400 230 410 256 410C282 410 322 400 362 368',5,DK);
 // chain of office
 s+=line('M176 386C200 446 230 470 256 474C282 470 312 446 336 386',6,LN);for(let i=0;i<9;i++){const t=i/8;const x=176+t*160,y=386+Math.sin(t*Math.PI)*86;s+=`<circle cx="${f(x)}" cy="${f(y)}" r="5.5" fill="${W_}" stroke="${LN}" stroke-width="2.4"/>`;}
 s+=`<circle cx="256" cy="486" r="16" fill="${DK}"/><circle cx="256" cy="486" r="9" fill="${W_}"/>`;
 // ruff collar
 s+=fill('M196 330C210 318 230 324 256 322C282 324 302 318 316 330C326 346 310 362 290 360C276 368 236 368 222 360C202 362 186 346 196 330Z');for(let i=0;i<7;i++){const x=206+i*17;s+=line(`M${x} 334q8 14 0 26`,2.4,DK);}
 // crown
 s+=fill('M184 172L178 92L206 128L230 74L256 118L282 74L306 128L334 92L328 172Z');
 s+=fill('M306 128L334 92L328 172H306Z',SH);
 for(const [x,y] of[[178,90],[230,70],[282,70],[334,90],[256,112]])s+=`<circle cx="${x}" cy="${y}" r="9" fill="${W_}"/><circle cx="${x}" cy="${y}" r="4" fill="${DK}"/>`;
 s+=fill('M180 150H332V176H180Z',DK)+line('M180 150H332',3);for(const x of[204,256,308])s+=`<circle cx="${x}" cy="163" r="6" fill="${W_}"/>`;
 s+=line('M168 182Q256 196 344 182',3,LN);
 return s;};

O.officer_7=()=>{let s='';// hooded spymaster (no bust head visible: hood)
 // cloak shoulders
 s+=fill('M30 512C40 430 100 380 180 352L256 340L332 352C412 380 472 430 482 512Z');
 s+=fill('M332 352C412 380 472 430 482 512H392C384 450 366 398 332 352Z',SH);
 s+=line('M180 352C150 400 130 450 124 512M332 352C362 400 382 450 388 512',4,DK);
 // hood
 s+=fill('M150 360C130 300 136 200 170 140C196 96 230 74 262 70C306 68 346 104 364 160C384 222 380 300 362 362C330 384 292 392 256 392C220 392 182 384 150 360Z');
 s+=fill('M300 82C340 112 366 164 372 230C376 290 370 330 362 362C344 372 330 378 316 382C344 300 340 170 300 82Z',SH);
 // face opening in shadow (darker alpha)
 s+=fill('M200 300C190 250 196 190 222 156C238 136 274 136 292 156C318 186 322 250 312 300C300 330 280 346 256 348C232 346 212 330 200 300Z','#8a8a8a');
 s+=fill('M214 300C208 260 214 214 232 190C246 176 268 176 282 190C302 214 306 260 298 300C290 322 274 334 256 336C238 334 222 322 214 300Z','#6a6a6a');
 // eyes glint
 s+=fill('M226 246h22v6h-22z','#e0e0e0')+fill('M266 246h22v6h-22z','#e0e0e0');
 // hood folds + clasp
 s+=line('M186 150C170 220 168 300 182 360',4,DK)+line('M330 150C346 220 348 300 334 362',4,DK);
 s+=`<circle cx="256" cy="402" r="18" fill="${DK}"/><circle cx="256" cy="402" r="10" fill="${W_}"/>`+line('M200 392L240 400M312 392L272 400',5,DK);
 // scarf over mouth
 s+=fill('M206 306C226 330 286 330 306 306L310 340C286 362 226 362 202 340Z','#bdbdbd');
 return s;};

O.officer_8=()=>{let s=bust();// headset / visor futurist
 // armoured high-tech collar + shoulder plates
 s+=fill('M194 318L220 300Q256 316 292 300L318 318L310 360Q256 380 202 360Z')+line('M200 330Q256 352 312 330',4,DK)+line('M206 346Q256 366 306 346',3,LN);
 for(const sx of[-1,1]){const cx=256+sx*136;s+=fill(`M${cx-sx*64} 368C${cx-sx*30} 340 ${cx+sx*40} 340 ${cx+sx*70} 380L${cx+sx*62} 412C${cx+sx*30} 386 ${cx-sx*30} 384 ${cx-sx*62} 400Z`)+line(`M${cx-sx*56} 376C${cx-sx*24} 356 ${cx+sx*34} 356 ${cx+sx*62} 388`,4,DK)+line(`M${cx-sx*40} 396L${cx+sx*40} 392`,3,LN);}
 s+=coatShade();
 s+=line('M256 380V512',4,DK)+line('M226 420H286M226 446H286',3,LN)+`<rect x="236" y="460" width="40" height="22" rx="5" fill="${DK}"/><rect x="242" y="466" width="28" height="10" rx="3" fill="${W_}"/>`;
 // sleek helmet / hair cap
 s+=fill('M184 206C176 140 208 102 256 100C306 100 340 136 332 208C320 186 300 176 256 176C214 176 194 186 184 206Z');
 s+=fill('M300 108C324 124 336 160 332 208C326 196 318 188 306 182C312 160 310 130 300 108Z',SH);
 // visor band across eyes
 s+=fill('M182 214C200 200 312 200 332 214L330 246C312 256 200 256 184 246Z');
 s+=fill('M190 220C206 210 306 210 324 220L322 238C306 246 206 246 192 238Z','#9c9c9c');
 s+=line('M198 226H316',3,'#efefef');
 // headset: ear cup + mic boom
 s+=`<rect x="314" y="196" width="34" height="56" rx="14" fill="${W_}"/>`+line('M320 210V240',3,DK)+line('M334 252C330 290 300 306 262 300',7,W_)+line('M334 252C330 290 300 306 262 300',2.4,DK)+`<rect x="248" y="292" width="20" height="14" rx="6" fill="${W_}"/>`;
 s+=line('M196 120C226 104 290 104 320 124',3,DK);
 // antenna
 s+=line('M340 196V150',5,W_)+`<circle cx="340" cy="146" r="7" fill="${W_}"/>`;
 return s;};

module.exports=O;
if(require.main===module){renderAll(Object.keys(O).map(k=>({name:k,w:512,h:512,svg:`<mask id="om" maskUnits="userSpaceOnUse" x="0" y="0" width="512" height="512"><rect width="512" height="512" fill="#000"/>${O[k]()}</mask><rect width="512" height="512" fill="#ffffff" mask="url(#om)"/>`,grain:0}))).then(()=>require('child_process').execFileSync('python3',['-c',"from PIL import Image\nimport numpy as np,glob\nfor fn in glob.glob('"+require('path').join(__dirname,'..')+"/officer_*.png'):\n a=np.asarray(Image.open(fn).convert('RGBA')).copy();a[...,:3]=255;Image.fromarray(a,'RGBA').save(fn,optimize=True)"]));}
