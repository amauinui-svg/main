const {chromium}=require('playwright');
const badge=(id,glyph)=>`<svg id="${id}" width="48" height="48" viewBox="0 0 48 48"><defs><linearGradient id="g${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e2cfa3"/><stop offset="1" stop-color="#c9b285"/></linearGradient></defs>
<circle cx="24" cy="24" r="22" fill="#0b0d10"/><circle cx="24" cy="24" r="19" fill="url(#g${id})"/>
<path d="M24 43 A19 19 0 0 1 7 33 A22 22 0 0 0 41 33 A19 19 0 0 1 24 43Z" fill="#9f8a5f"/>
<path d="M12 13 A16 16 0 0 1 36 13" stroke="rgba(255,255,255,.4)" stroke-width="2.2" fill="none" stroke-linecap="round"/>${glyph}</svg>`;
const cart=`<path d="M11 18 h20 l3 4 h3 v9 H11Z" fill="#2a2214"/><path d="M13 20 h16 v4 H13Z" fill="#c9b285"/>
<circle cx="16" cy="32" r="4.6" fill="#2a2214"/><circle cx="16" cy="32" r="1.8" fill="#e2cfa3"/><circle cx="31" cy="32" r="4.6" fill="#2a2214"/><circle cx="31" cy="32" r="1.8" fill="#e2cfa3"/>`;
const ship=`<path d="M24 9 v18" stroke="#2a2214" stroke-width="2.4"/><path d="M25.5 10 L35 25 H25.5Z" fill="#2a2214"/><path d="M22.5 13 L15 25 H22.5Z" fill="#2a2214"/>
<path d="M9 28 H39 L34 36 H14Z" fill="#2a2214"/>`;
(async()=>{const b=await chromium.launch();const p=await b.newPage({deviceScaleFactor:2});
for(const [k,g] of [['convoy_land',cart],['convoy_sea',ship]]){await p.setContent(`<html><body style="margin:0;background:transparent">${badge(k,g)}</body></html>`);
 await p.locator('svg').screenshot({path:`mk_${k}.png`,omitBackground:true});}
await b.close();})();
