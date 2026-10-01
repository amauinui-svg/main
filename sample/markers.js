const {chromium}=require('playwright');
// Markers drawn with the same 5-layer rules as the UI buttons (THEME.md): ink edge, top-lit two-stop body, top lip, base bevel.
const pin=(id,top,bot,bevel,inner)=>`<svg id="${id}" width="44" height="56" viewBox="0 0 44 56" xmlns="http://www.w3.org/2000/svg">
 <defs><linearGradient id="b${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${top}"/><stop offset="1" stop-color="${bot}"/></linearGradient></defs>
 <path d="M22 54 C22 54 4 33 4 21 A18 18 0 0 1 40 21 C40 33 22 54 22 54Z" fill="#0b0d10"/>
 <path d="M22 50 C22 50 6.5 32 6.5 21 A15.5 15.5 0 0 1 37.5 21 C37.5 32 22 50 22 50Z" fill="url(#b${id})"/>
 <path d="M22 50 C22 50 9 35 7.4 27 C12 33 32 33 36.6 27 C35 35 22 50 22 50Z" fill="${bevel}"/>
 <path d="M12 12 A13 13 0 0 1 32 12" stroke="rgba(255,255,255,.35)" stroke-width="2.4" fill="none" stroke-linecap="round"/>
 ${inner}</svg>`;
const dot=`<circle cx="22" cy="21" r="6.5" fill="#0b0d10"/><circle cx="22" cy="21" r="4.2" fill="#f4ecd8"/>`;
const star=`<path d="M22 11.5 L24.9 17.6 L31.4 18.3 L26.5 22.7 L27.9 29.2 L22 25.9 L16.1 29.2 L17.5 22.7 L12.6 18.3 L19.1 17.6Z" fill="#0b0d10"/>
<path d="M22 14.2 L24.1 18.7 L28.9 19.2 L25.3 22.4 L26.3 27.2 L22 24.8 L17.7 27.2 L18.7 22.4 L15.1 19.2 L19.9 18.7Z" fill="#ffd45a"/>`;
const sel=`<svg id="ring" width="64" height="64" viewBox="0 0 64 64"><circle cx="32" cy="32" r="27" fill="none" stroke="#0b0d10" stroke-width="7"/><circle cx="32" cy="32" r="27" fill="none" stroke="#e2cfa3" stroke-width="3.5" stroke-dasharray="9 6"/></svg>`;
const items={pin_neutral:pin('pin_neutral','#e2cfa3','#c9b285','#9f8a5f',dot),
 pin_tint:pin('pin_tint','#ffffff','#d6d6d6','#9a9a9a',dot),           // multiply-tinted with the owner's alliance colour
 pin_home:pin('pin_home','#3a4048','#2c3138','#1c2026',star), ring:sel,
 dot_route:`<svg id="dot_route" width="10" height="10"><circle cx="5" cy="5" r="4" fill="#0b0d10"/><circle cx="5" cy="5" r="2.4" fill="#e2cfa3"/></svg>`};
(async()=>{const b=await chromium.launch();const p=await b.newPage({deviceScaleFactor:2});
for(const [k,svg] of Object.entries(items)){await p.setContent(`<html><body style="margin:0;background:transparent">${svg}</body></html>`);
 await p.locator('svg').first().screenshot({path:`mk_${k}.png`,omitBackground:true});}
await b.close();})();
