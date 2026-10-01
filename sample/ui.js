const {chromium}=require('playwright');
const grain=`<svg width="0" height="0" style="position:absolute"><filter id="g"><feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed="7"/><feColorMatrix values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 0 0 .5 0"/></filter></svg>`;
const piece=(id,w,h,top,bot,{bevel=null,pressed=false,radius=6,rule=null,manilaStrip=false}={})=>`
<div id="${id}" style="position:absolute;left:0;top:0;width:${w}px;height:${h}px">
 <div style="position:absolute;inset:0;border-radius:${radius}px;background:#0b0d10"></div>
 <div style="position:absolute;left:2px;right:2px;top:${2+(pressed?2:0)}px;bottom:2px;border-radius:${radius-1}px;overflow:hidden;
   background:linear-gradient(${top},${bot})">
   <svg style="position:absolute;inset:0;width:100%;height:100%;opacity:.05;mix-blend-mode:overlay"><rect width="100%" height="100%" filter="url(#g)"/></svg>
   <svg style="position:absolute;inset:0;width:100%;height:100%;opacity:.07"><rect width="100%" height="100%" filter="url(#g)"/></svg>
   ${manilaStrip?`<div style="position:absolute;left:0;right:0;top:0;height:5px;background:linear-gradient(#e2cfa3,#c9b285)"></div>`:''}
   <div style="position:absolute;left:3px;right:3px;top:${manilaStrip?5:0}px;height:2px;background:rgba(255,255,255,.22)"></div>
   ${bevel&&!pressed?`<div style="position:absolute;left:0;right:0;bottom:0;height:4px;background:${bevel}"></div>`:''}
   ${rule?`<div style="position:absolute;inset:${manilaStrip?9:4}px 4px 4px 4px;border:1px solid ${rule};border-radius:3px"></div>`:''}
 </div></div>`;
const items=[
 ['panel',160,160,'#2a2f36','#1f2328',{rule:'#444b54'}],
 ['panel_folder',160,160,'#2a2f36','#1f2328',{rule:'#444b54',manilaStrip:true}],
 ['card',160,96,'#30353d','#262a30',{rule:'#3d434b'}],
 ['btn_manila',120,56,'#e2cfa3','#c9b285',{bevel:'#9f8a5f'}],
 ['btn_manila_down',120,56,'#d6c296','#c2ab7e',{bevel:'#9f8a5f',pressed:true}],
 ['btn_slate',120,56,'#3a4048','#2c3138',{bevel:'#1c2026'}],
 ['btn_red',120,56,'#d9544a','#b33a31',{bevel:'#7d2620'}],
 ['btn_green',120,56,'#6fa35c','#557f46',{bevel:'#3a5a2f'}],
 ['btn_locked',120,56,'#5a5f66','#474b51',{bevel:'#33363b'}],
 ['chip',48,28,'#3a4048','#30353c',{radius:5}],
 ['pill',96,40,'#1b1d20','#0f1012',{radius:20}],
];
(async()=>{const b=await chromium.launch();const p=await b.newPage({viewport:{width:400,height:400}});
for(const [id,w,h,t,bt,o] of items){await p.setContent(`<html><body style="margin:0;background:transparent">${grain}${piece(id,w,h,t,bt,o)}</body></html>`);
 await p.locator('#'+id).screenshot({path:`ui_${id}.png`,omitBackground:true});}
// folder tab
await p.setContent(`<html><body style="margin:0;background:transparent">${grain}<div id="t" style="position:absolute;width:124px;height:16px"><div style="position:absolute;inset:0;border-radius:6px 6px 0 0;background:#0b0d10"></div><div style="position:absolute;left:2px;right:2px;top:2px;bottom:0;border-radius:5px 5px 0 0;background:linear-gradient(#e2cfa3,#c9b285)"></div></div></body></html>`);
await p.locator('#t').screenshot({path:'ui_folder_tab.png',omitBackground:true});
await b.close();})();
