import {spawn} from 'node:child_process'; import fs from 'node:fs';
const out=process.argv[2]||'/tmp/claude-1000/';const BASE=process.argv[3]||'http://localhost:4800';
const pr=spawn('/usr/bin/chromium',['--headless=new','--remote-debugging-port=9334','--no-first-run','--user-data-dir=/tmp/claude-1000/lu-chrome2','about:blank'],{stdio:'ignore'});
await new Promise(r=>setTimeout(r,2500));
const t=(await (await fetch('http://127.0.0.1:9334/json/list')).json()).find(x=>x.type==='page');
const ws=new WebSocket(t.webSocketDebuggerUrl); await new Promise(r=>ws.onopen=r);
let n=0;const P={};const errs=[];
ws.onmessage=e=>{const m=JSON.parse(e.data);if(m.id&&P[m.id]){P[m.id](m.result||m.error);delete P[m.id]}
 if(m.method==='Runtime.exceptionThrown')errs.push(m.params.exceptionDetails.exception?.description?.split('\n')[0]);
 if(m.method==='Runtime.consoleAPICalled'&&m.params.type==='error')errs.push(m.params.args.map(a=>a.value||a.description).join(' '))};
const send=(method,params={})=>new Promise(r=>{const id=++n;P[id]=r;ws.send(JSON.stringify({id,method,params}))});
const ev=async(x)=>(await send('Runtime.evaluate',{expression:x,returnByValue:true,awaitPromise:true})).result?.value;
const shot=async(name)=>{const s=await send('Page.captureScreenshot',{format:'png'});fs.writeFileSync(out+name+'.png',Buffer.from(s.data,'base64'))};
await send('Runtime.enable');await send('Page.enable');
await send('Emulation.setDeviceMetricsOverride',{width:1440,height:900,deviceScaleFactor:1,mobile:false});
const sampler=(sel)=>`(async()=>{const r=[];const t0=performance.now();for(let i=0;i<14;i++){const el=document.querySelector(${JSON.stringify(sel)});if(el){const b=el.getBoundingClientRect();const cs=getComputedStyle(el);r.push([Math.round(performance.now()-t0),Math.round(b.left),Math.round(b.top),(+cs.opacity).toFixed(2)])}else r.push([Math.round(performance.now()-t0),'gone']);await new Promise(z=>setTimeout(z,30))}return r})()`;
await send('Page.navigate',{url:BASE+'/templates/tabela'});await new Promise(r=>setTimeout(r,2500));
console.log('connected',await ev(`!!document.querySelector('.phx-connected')`));
// click first row
const rowSel=await ev(`(()=>{const r=document.querySelector('tbody tr[phx-click], tbody tr[data-lu-href], tbody tr');return r? (r.click(),'clicked'):'norow'})()`);
console.log('row',rowSel);
const s1=await ev(sampler('.lu-drawer'));console.log('DRAWER OPEN',JSON.stringify(s1));
await shot('drawer_open');
// close via overlay x
await ev(`(()=>{const x=document.querySelector('.lu-drawer .lu-x, .lu-drawer [aria-label*=echar], .lu-drawer [aria-label*=lose]');x&&x.click();return !!x})()`);
const s2=await ev(sampler('.lu-drawer'));console.log('DRAWER CLOSE',JSON.stringify(s2));
// modal
await ev(`(()=>{const b=[...document.querySelectorAll('button,a')].find(b=>/Novo pedido/.test(b.textContent));b&&b.click();return !!b})()`);
await new Promise(r=>setTimeout(r,60));await shot('modal_mid');
const s3=await ev(sampler('.lu-modal'));console.log('MODAL OPEN',JSON.stringify(s3));
await shot('modal_open');
await ev(`(()=>{const x=document.querySelector('.lu-modal .lu-x, .lu-modal [aria-label*=echar]');x&&x.click();return !!x})()`);
const s4=await ev(sampler('.lu-modal'));console.log('MODAL CLOSE',JSON.stringify(s4));
console.log('errors',JSON.stringify(errs));
ws.close();pr.kill();process.exit(0);
