// Idle Country art round 2 (1 Oct 2026): gear, officer portraits, crates and aura VFX.
// Same State Dossier rules: ink edge #0b0d10, top-lit gradients, no baked text. Rarity colour is applied in Roblox
// (aura images are white so they tint), so one image serves every rarity.
const {chromium}=require('playwright');const fs=require('fs');const path=require('path');
const OUT='out2';const INK='#0b0d10';
const defs=`<defs>
<linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f4f6f9"/><stop offset=".45" stop-color="#c3cad3"/><stop offset="1" stop-color="#7d8794"/></linearGradient>
<linearGradient id="gold" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffe08a"/><stop offset=".5" stop-color="#f0c75a"/><stop offset="1" stop-color="#b8861f"/></linearGradient>
<linearGradient id="wood" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#b07a48"/><stop offset="1" stop-color="#6e4627"/></linearGradient>
<linearGradient id="leather" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8a5a35"/><stop offset="1" stop-color="#5a3820"/></linearGradient>
<linearGradient id="cloth" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3f5b84"/><stop offset="1" stop-color="#26385a"/></linearGradient>
<linearGradient id="red" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#d9544a"/><stop offset="1" stop-color="#8f2a23"/></linearGradient>
<linearGradient id="slate" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4a525c"/><stop offset="1" stop-color="#22262c"/></linearGradient>
<linearGradient id="skin" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e8c3a0"/><stop offset="1" stop-color="#c39672"/></linearGradient>
<linearGradient id="skin2" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#b78360"/><stop offset="1" stop-color="#8a5c3e"/></linearGradient>
<linearGradient id="skin3" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7a5038"/><stop offset="1" stop-color="#553522"/></linearGradient>
<radialGradient id="gem" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#ffffff"/><stop offset=".3" stop-color="#7ff0e0"/><stop offset="1" stop-color="#138a7c"/></radialGradient>
</defs>`;
// draw a shape twice: thick ink outline underneath, fill on top
const S=(d,fill,w=7,extra='')=>`<path d="${d}" fill="${INK}" stroke="${INK}" stroke-width="${w}" stroke-linejoin="round" ${extra}/><path d="${d}" fill="${fill}" ${extra}/>`;
const shine=(d)=>`<path d="${d}" fill="none" stroke="rgba(255,255,255,.55)" stroke-width="3" stroke-linecap="round"/>`;
const svg=(w,h,body)=>`<svg id="x" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${defs}${body}</svg>`;
const items={};
// ---- weapons (128x128, diagonal)
items.gear_sword=svg(128,128,`<g transform="rotate(-45 64 64)">${S('M58 14 L64 6 L70 14 L70 78 L58 78Z','url(#steel)')}${S('M40 78 h48 v9 h-48z','url(#gold)')}${S('M59 87 h10 v22 h-10z','url(#leather)')}${S('M64 108 m-7 0 a7 7 0 1 0 14 0 a7 7 0 1 0 -14 0','url(#gold)')}${shine('M62 16 L62 74')}</g>`);
items.gear_saber=svg(128,128,`<g transform="rotate(-40 64 64)">${S('M60 82 C52 60 52 34 66 10 C70 30 70 58 70 82Z','url(#steel)')}${S('M44 82 h40 v8 h-40z','url(#gold)')}${S('M59 90 h10 v20 h-10z','url(#leather)')}${S('M56 90 C46 98 50 112 60 112','none',6)}${shine('M62 22 C58 42 58 62 63 78')}</g>`);
items.gear_spear=svg(128,128,`<g transform="rotate(-45 64 64)">${S('M61 34 h6 v86 h-6z','url(#wood)')}${S('M64 4 C74 16 74 28 64 40 C54 28 54 16 64 4Z','url(#steel)')}${S('M58 38 h12 v6 h-12z','url(#gold)')}${shine('M62 12 C59 20 59 28 62 34')}</g>`);
items.gear_halberd=svg(128,128,`<g transform="rotate(-45 64 64)">${S('M61 14 h6 v106 h-6z','url(#wood)')}${S('M64 2 L70 16 L58 16Z','url(#steel)')}${S('M67 22 C90 20 96 40 92 56 C84 48 76 46 67 48Z','url(#steel)')}${S('M61 26 L46 32 L61 40Z','url(#steel)')}${shine('M70 26 C84 26 88 36 88 44')}</g>`);
items.gear_musket=svg(128,128,`<g transform="rotate(-40 64 64)">${S('M60 6 h7 v74 h-7z','url(#steel)')}${S('M56 62 h15 v26 l6 30 h-24 l3 -30z','url(#wood)')}${S('M60 84 h7 v8 h-7z','url(#gold)')}${shine('M62 10 L62 70')}</g>`);
items.gear_rifle=svg(128,128,`<g transform="rotate(-40 64 64)">${S('M61 4 h6 v70 h-6z','url(#steel)')}${S('M56 56 h16 v26 l8 32 h-28 l4 -32z','url(#slate)')}${S('M52 44 h24 v8 h-24z','url(#slate)')}${S('M60 82 h8 v12 h-8z','url(#leather)')}${shine('M63 8 L63 52')}</g>`);
// ---- armor
items.gear_helm=svg(128,128,`${S('M24 76 C24 40 44 22 64 22 C84 22 104 40 104 76 L104 92 L24 92Z','url(#steel)')}${S('M60 10 h8 v18 h-8z','url(#red)')}${S('M30 66 h68 v10 h-68z','url(#slate)')}${S('M58 76 h12 v26 h-12z','url(#steel)')}${shine('M36 54 C40 40 50 32 62 30')}`);
items.gear_cuirass=svg(128,128,`${S('M30 24 L50 18 C56 28 72 28 78 18 L98 24 L104 52 L94 60 L92 108 C76 116 52 116 36 108 L34 60 L24 52Z','url(#steel)')}${S('M64 30 v78','none',5)}${S('M44 70 C56 76 72 76 84 70','none',5)}${shine('M40 30 C38 50 40 70 44 90')}`);
items.gear_coat=svg(128,128,`${S('M36 16 L52 12 L64 30 L76 12 L92 16 L108 40 L98 50 L96 116 L32 116 L30 50 L20 40Z','url(#cloth)')}${S('M52 12 L64 30 L76 12 L70 44 L58 44Z','url(#gold)')}${[50,66,82,98].map(y=>S(`M58 ${y} m-4 0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0`,'url(#gold)',4)+S(`M70 ${y} m-4 0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0`,'url(#gold)',4)).join('')}${shine('M40 30 C34 50 36 80 38 104')}`);
items.gear_shield=svg(128,128,`${S('M64 8 L108 22 C108 66 92 98 64 120 C36 98 20 66 20 22Z','url(#red)')}${S('M64 20 L96 30 C96 64 84 88 64 106 C44 88 32 64 32 30Z','url(#gold)')}${S('M64 34 L72 54 L94 56 L76 70 L82 92 L64 80 L46 92 L52 70 L34 56 L56 54Z','url(#slate)',5)}${shine('M30 30 C30 58 40 80 56 98')}`);
items.gear_plate=svg(128,128,`${S('M20 46 C24 26 44 18 64 18 C84 18 104 26 108 46 L100 58 C92 50 76 46 64 46 C52 46 36 50 28 58Z','url(#gold)')}${S('M28 60 C40 52 88 52 100 60 L96 82 C84 74 44 74 32 82Z','url(#steel)')}${S('M34 86 C46 78 82 78 94 86 L90 108 C80 102 48 102 38 108Z','url(#steel)')}${shine('M30 40 C40 28 56 24 66 24')}`);
// ---- officer portraits (160x160): bust with uniform and hat; 8 looks + the Founder
const bust=(skin,coat,trim,hat,extra='')=>svg(160,160,`<circle cx="80" cy="80" r="78" fill="${INK}"/><circle cx="80" cy="80" r="74" fill="url(#slate)"/>
<clipPath id="c"><circle cx="80" cy="80" r="74"/></clipPath><g clip-path="url(#c)">
${S('M22 160 C24 118 48 104 80 104 C112 104 136 118 138 160Z',coat)}${S('M64 104 L80 128 L96 104 L90 100 L80 112 L70 100Z',trim,5)}
${S('M70 88 h20 v20 h-20z',skin,5)}${S('M80 96 C62 96 52 82 52 64 C52 44 64 32 80 32 C96 32 108 44 108 64 C108 82 98 96 80 96Z',skin)}
<circle cx="70" cy="64" r="3.4" fill="${INK}"/><circle cx="90" cy="64" r="3.4" fill="${INK}"/><path d="M72 80 C77 84 83 84 88 80" stroke="${INK}" stroke-width="3" fill="none" stroke-linecap="round"/>
${S('M40 132 h18 v8 h-18z','url(#gold)',4)}${S('M102 132 h18 v8 h-18z','url(#gold)',4)}${hat}${extra}</g>`);
const H={
 bicorne:S('M30 46 C44 18 116 18 130 46 C112 40 48 40 30 46Z','#1d2026')+S('M74 26 m-6 0 a6 6 0 1 0 12 0 a6 6 0 1 0 -12 0','url(#gold)',4),
 peaked:S('M48 46 C50 26 110 26 112 46Z','url(#cloth)')+S('M44 46 h72 l-6 8 h-60z','#1d2026')+S('M74 34 h12 v8 h-12z','url(#gold)',4),
 crown:S('M50 44 L54 22 L66 34 L80 18 L94 34 L106 22 L110 44Z','url(#gold)')+S('M80 32 m-4 0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0','url(#red)',3),
 beret:S('M46 44 C46 24 96 18 116 34 C112 44 72 48 46 44Z','url(#red)'),
 helmet:S('M48 52 C48 26 112 26 112 52Z','#4b5a3c')+S('M44 52 h72 v6 h-72z','#3a4730'),
 tophat:S('M58 42 h44 v-26 h-44z','#1d2026')+S('M48 42 h64 v6 h-64z','#1d2026')+S('M58 34 h44 v5 h-44z','url(#red)',3),
 turban:S('M48 50 C44 28 116 28 112 50 C100 44 60 44 48 50Z','#e8e2d0')+S('M78 32 m-5 0 a5 5 0 1 0 10 0 a5 5 0 1 0 -10 0','url(#gem)',3),
 hair:S('M52 56 C50 30 110 30 108 56 C100 40 60 40 52 56Z','#3a2a1e'),
};
const looks=[['url(#skin)','url(#cloth)','url(#gold)',H.bicorne],['url(#skin2)','url(#red)','url(#gold)',H.peaked],['url(#skin3)','url(#slate)','url(#gold)',H.beret],
 ['url(#skin)','#4b5a3c','url(#gold)',H.helmet],['url(#skin2)','#1d2026','url(#red)',H.tophat],['url(#skin3)','url(#cloth)','url(#gold)',H.turban],
 ['url(#skin)','url(#red)','url(#gold)',H.hair],['url(#skin2)','#4b5a3c','url(#gold)',H.peaked]];
looks.forEach((l,i)=>items['portrait_'+(i+1)]=bust(l[0],l[1],l[2],l[3]));
items.portrait_0=bust('url(#skin)','#2b1d3a','url(#gold)',H.crown,S('M18 160 C20 120 40 112 52 110 L60 160Z','url(#gold)',5)+S('M142 160 C140 120 120 112 108 110 L100 160Z','url(#gold)',5));
// ---- crates (192x192)
items.crate_basic=svg(192,192,`${S('M24 70 L96 42 L168 70 L168 150 L96 178 L24 150Z','url(#wood)')}${S('M24 70 L96 98 L168 70','none',6)}${S('M96 98 v80','none',6)}
${S('M24 92 L96 120 L168 92 L168 104 L96 132 L24 104Z','url(#steel)',5)}${S('M86 112 h20 v24 h-20z','url(#gold)',5)}${shine('M34 76 L92 52')}`);
items.crate_limited=svg(192,192,`${S('M20 86 C20 46 172 46 172 86Z','url(#slate)')}${S('M20 86 h152 v76 h-152z','url(#slate)')}
${S('M20 86 h152 v12 h-152z','url(#gold)',5)}${S('M20 150 h152 v12 h-152z','url(#gold)',5)}${S('M44 50 v112','none',0)}
${S('M38 56 h14 v106 h-14z','url(#gold)',5)}${S('M140 56 h14 v106 h-14z','url(#gold)',5)}
${S('M78 92 h36 v40 l-18 12 l-18 -12z','url(#gold)',5)}${S('M96 104 m-10 0 a10 10 0 1 0 20 0 a10 10 0 1 0 -20 0','url(#gem)',4)}
${shine('M30 74 C46 58 140 56 162 72')}`);
// ---- VFX (white, tinted in Roblox)
items.aura_glow=`<div id="x" style="width:256px;height:256px;background:radial-gradient(circle,rgba(255,255,255,.95) 0%,rgba(255,255,255,.55) 28%,rgba(255,255,255,.15) 52%,rgba(255,255,255,0) 70%)"></div>`;
items.aura_rays=svg(256,256,`<g transform="translate(128 128)">${Array.from({length:12},(_,i)=>`<path d="M0 0 L-9 -124 L9 -124Z" fill="rgba(255,255,255,${i%2?0.35:0.7})" transform="rotate(${i*30})"/>`).join('')}</g><circle cx="128" cy="128" r="128" fill="url(#fade)"/>`.replace('</defs>','<radialGradient id="fade"><stop offset=".2" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient></defs>'));
items.sparkle=svg(64,64,`<path d="M32 2 C35 22 42 29 62 32 C42 35 35 42 32 62 C29 42 22 35 2 32 C22 29 29 22 32 2Z" fill="#ffffff"/>`);
items.icon_info=`<svg id="x" width="64" height="64" viewBox="0 0 64 64"><circle cx="32" cy="32" r="28" fill="none" stroke="#ffffff" stroke-width="5"/><circle cx="32" cy="19" r="4.2" fill="#ffffff"/><path d="M32 29 v19" stroke="#ffffff" stroke-width="6" stroke-linecap="round"/></svg>`;
(async()=>{fs.mkdirSync(OUT,{recursive:true});const b=await chromium.launch();const p=await b.newPage({deviceScaleFactor:1});
for(const [k,html] of Object.entries(items)){await p.setContent(`<html><body style="margin:0;background:transparent">${html}</body></html>`);
 await p.locator('#x').screenshot({path:path.join(OUT,'IC_'+k+'.png'),omitBackground:true});}
await b.close();console.log(Object.keys(items).length,'images');})();
