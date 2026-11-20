// Usage: node motion_probe2.mjs OUTDIR BASE. rAF-based sampling of overlay motion (left/top/opacity per frame).
import {spawn} from 'node:child_process'; import fs from 'node:fs';
const out=process.argv[2]||'/tmp/claude-1000/';const BASE=process.argv[3]||'http://localhost:4800';
const pr=spawn('/usr/bin/chromium',['--headless=new','--remote-debugging-port=9335','--no-first-run','--user-data-dir=/tmp/claude-1000/lu-chrome3','about:blank'],{stdio:'ignore'});
await new Promise(r=>setTimeout(r,2500));
const t=(await (await fetch('http://127.0.0.1:9335/json/list')).json()).find(x=>x.type==='page');
const ws=new WebSocket(t.webSocketDebuggerUrl); await new Promise(r=>ws.onopen=r);
let n=0;const P={};
ws.onmessage=e=>{const m=JSON.parse(e.data);if(m.id&&P[m.id]){P[m.id](m.result||m.error);delete P[m.id]}};
const send=(method,params={})=>new Promise(r=>{const id=++n;P[id]=r;ws.send(JSON.stringify({id,method,params}))});
const ev=async(x)=>(await send('Runtime.evaluate',{expression:x,returnByValue:true,awaitPromise:true})).result?.value;
const shot=async(name)=>{const s=await send('Page.captureScreenshot',{format:'png'});fs.writeFileSync(out+name+'.png',Buffer.from(s.data,'base64'))};
await send('Runtime.enable');await send('Page.enable');
await send('Emulation.setDeviceMetricsOverride',{width:1440,height:900,deviceScaleFactor:1,mobile:false});
const nav=async(u)=>{await send('Page.navigate',{url:BASE+u});await new Promise(r=>setTimeout(r,2500))};
// rec(sel, actionJs, ms): start rAF sampling, run action, return frames [t,left,top,opacity,transform] (first of each ~ change)
const rec=(sel,action,ms=700)=>ev(`(async()=>{const r=[];const t0=performance.now();let stop=false;
 const f=()=>{const el=document.querySelector(${JSON.stringify(sel)});const t=Math.round(performance.now()-t0);
  if(el){const b=el.getBoundingClientRect();const cs=getComputedStyle(el);r.push([t,Math.round(b.left),Math.round(b.top),(+cs.opacity).toFixed(2)])}else r.push([t,'gone']);
  if(!stop)requestAnimationFrame(f)};requestAnimationFrame(f);
 ${action};await new Promise(z=>setTimeout(z,${ms}));stop=true;
 const o=[];let last='';for(const x of r){const k=x.slice(1).join();if(k!==last){o.push(x);last=k}}return o})()`);
const show=(l,a)=>console.log(l,JSON.stringify(a));
const clickRow=`document.querySelector('tbody tr').click()`;
const clickX=(s)=>`(document.querySelector('${s} .lu-x')||document.querySelector('${s} [aria-label*=echar]')).click()`;
const clickNovo=`[...document.querySelectorAll('button')].find(b=>/Novo pedido/.test(b.textContent)).click()`;
const which=process.argv[4]||'all';
if(which==='all'||which==='tabela'){
await nav('/templates/tabela');
show('TABELA drawer open',await rec('.lu-drawer',clickRow));
await shot('p_drawer_open');
show('TABELA drawer close',await rec('.lu-drawer',clickX('.lu-drawer')));
show('TABELA modal open',await rec('.lu-modal',clickNovo));
show('TABELA modal close',await rec('.lu-modal',clickX('.lu-modal')));
show('TABELA modal-overlay probe (overlay)',await rec('.lu-overlay',clickNovo,400));
}
if(which==='all'||which==='direct'){
await nav('/templates/tabela?pedido=2493');
show('DIRECT ?pedido drawer (post-load)',await rec('.lu-drawer','0',200));
}
if(which==='all'||which==='gaveta'){
await nav('/templates/tabela-gaveta');
show('GAVETA drawer (post-load)',await rec('.lu-drawer','0',200));
}
if(which==='all'||which==='ref'){
await nav('/c/drawer');
show('REF drawer open',await rec('#lv-dr-right .lv-dr',`document.getElementById('lv-dr-right').classList.add('open')`));
show('REF drawer close',await rec('#lv-dr-right .lv-dr',`document.getElementById('lv-dr-right').classList.remove('open')`));
await nav('/c/modal');
show('REF modal open',await rec('#lv-md-scale .lv-md',`document.getElementById('lv-md-scale').classList.add('open')`));
show('REF modal close',await rec('#lv-md-scale .lv-md',`document.getElementById('lv-md-scale').classList.remove('open')`));
}
if(which==='all'||which==='load'){
await send('Page.addScriptToEvaluateOnNewDocument',{source:`window.__rec=[];(function f(){const e=document.querySelector('.lu-drawer');const t=Math.round(performance.now());if(e){const b=e.getBoundingClientRect();window.__rec.push([t,Math.round(b.left),Math.round(b.top)])}if(t<2500)requestAnimationFrame(f)})()`});
for(const u of ['/templates/tabela?pedido=2493','/templates/tabela-gaveta']){
await send('Page.navigate',{url:BASE+u});await new Promise(r=>setTimeout(r,3000));
const r=await ev('window.__rec');const o=[];let last='';for(const x of r){const k=x.slice(1).join();if(k!==last){o.push(x);last=k}}
show('LOAD '+u+' (ms since nav)',o.slice(0,30));
}}
if(which==='shots'){
for(const id of [2493,2491,2495]){await nav('/templates/tabela?pedido='+id);await new Promise(r=>setTimeout(r,600));await shot('o_'+id)}
await nav('/templates/tabela');await ev(clickRow);await new Promise(r=>setTimeout(r,800));await shot('o_selected_click');
console.log('selected after click',await ev(`document.querySelectorAll('tbody tr.sel').length+' bulk:'+!!document.querySelector('.lu-bulkfloat')`));
await nav('/templates/tabela?pedido=2493');console.log('direct pedido sel rows',await ev(`document.querySelectorAll('tbody tr.sel').length+' bulk:'+!!document.querySelector('.lu-bulkfloat')`));
}
if(which==='hook'){
// the hook-driven overlays (LedgerUI.open/close), mounted by hand from a markup file rendered by the components
const html=fs.readFileSync('/tmp/claude-1000/hooks_markup.html','utf8');
await nav('/templates/tabela');
await ev(`(async()=>{document.body.insertAdjacentHTML('beforeend',${JSON.stringify(html)});const H=(await import('/ledger_ui/ledger_ui/hooks/overlay.js')).default;window.__h={};
 for(const el of document.querySelectorAll('[data-lu-overlay]')){const h=Object.create(H);h.el=el;h.pushEvent=()=>{};h.mounted();window.__h[el.id]=h}})()`);
const op=(id)=>`document.getElementById('${id}').classList.add('open')`, cl=(id)=>`document.getElementById('${id}').classList.remove('open')`;
const sel=(id,part)=>`#${id} ${part}`;
show('HOOK drawer(left) open',await rec(sel('hd','.lu-drawer'),op('hd')));
show('HOOK drawer(left) close',await rec(sel('hd','.lu-drawer'),cl('hd')));
show('HOOK modal(fade) open',await rec(sel('hm','.lu-modal'),op('hm')));
show('HOOK modal(fade) close',await rec(sel('hm','.lu-modal'),cl('hm')));
show('HOOK modal(scale) open',await rec(sel('hm2','.lu-modal'),op('hm2')));
show('HOOK modal(scale) close',await rec(sel('hm2','.lu-modal'),cl('hm2')));
}
if(which==='dbg'){await nav('/templates/tabela');console.log(JSON.stringify(await ev(`(async()=>{document.querySelector('tbody tr').click();const o=[];for(let i=0;i<6;i++){await new Promise(r=>requestAnimationFrame(r));const d=document.querySelector('.lu-drawer');if(d)o.push([Math.round(performance.now()),d.getAnimations().map(a=>a.animationName+':'+a.playState+':'+Math.round(a.currentTime)),getComputedStyle(d).transform,d.getBoundingClientRect().left,d.offsetWidth])}return o})()`)))}
if(which==='dbg2'){await nav('/templates/tabela');console.log(JSON.stringify(await ev(`(async()=>{document.querySelector('tbody tr').click();await new Promise(r=>setTimeout(r,60));const o=[];let e=document.querySelector('.lu-drawer');while(e){if(e.scrollLeft||e.scrollTop)o.push([e.tagName,e.className,e.scrollLeft,e.scrollTop,getComputedStyle(e).overflowX]);e=e.parentElement}return o})()`)))}
if(which==='dbg3'){await nav('/c/drawer');console.log(JSON.stringify(await ev(`[...document.querySelectorAll('[data-lv-open]')].map(e=>e.dataset.lvOpen).join()+' ## '+[...document.querySelectorAll('.lv-ov')].map(e=>e.id).join()`)))}
ws.close();pr.kill();process.exit(0);
