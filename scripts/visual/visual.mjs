// Visual comparison: design canvas (static pages) vs LiveView showcase, in headless Chromium (CDP).
//
//   node scripts/visual/visual.mjs canvas   <out>   # screenshots of the canvas demos (+ hover) -> manifest
//   node scripts/visual/visual.mjs showcase <out>   # same for the showcase
//   node scripts/visual/visual.mjs diff     <out>   # pixel diff in the browser -> results.json
//   node scripts/visual/visual.mjs report   <out>   # visual-report/index.html
//
// Pairing: showcase section = `examples/<id>/NN.heex` = NN-th `.d-ex` of /full/<id>; canvas demo = leaf `.lu-demo` whose `.lu-spec`
// title equals the NN-th title of design/vitrine/sec/<id>.json (then the canvas-only titles of design/canvas/extras.json). No `lu-*` class
// is needed on the SHOWCASE side: hover targets are paired by tag + accessible text + occurrence (see `sk` in HELPERS).
//
// env: DESIGN (design dir), CANVAS_URL (static canvas server), SHOW_URL, ONLY (comma ids), THEMES,
//      THRESHOLD (max % diff per section, default 0.6), INK_THRESHOLD (max diff / non-background pixels, default 15), STRICT=1 (report mode exits 1 when a section is over the threshold)
import {spawn} from 'node:child_process'; import fs from 'node:fs'; import path from 'node:path';

const [mode, OUT] = process.argv.slice(2);
const DESIGN = process.env.DESIGN || 'design';
const CANVAS_URL = process.env.CANVAS_URL || 'http://127.0.0.1:4600';
const SHOW_URL = process.env.SHOW_URL || 'http://localhost:4500';
const ONLY = process.env.ONLY ? new Set(process.env.ONLY.split(',')) : null;
const THEMES = (process.env.THEMES || 'light,dark').split(',');
const THRESHOLD = Number(process.env.THRESHOLD ?? 0.6), INK_THRESHOLD = Number(process.env.INK_THRESHOLD ?? 15);
const W = 1520, MAXHOV = 4;
fs.mkdirSync(path.join(OUT, 'raw'), {recursive: true});
const sleep = ms => new Promise(r => setTimeout(r, ms));
const key = (id, idx) => `${id}|${idx}`;
const fname = (theme, id, idx, state) => `${theme}__${id}__${String(idx).padStart(2, '0')}__${state}.png`;

// ---------- CDP ----------
let chrome, ws, nid = 0; const pend = {};
async function launch() {
  // fresh profile per run: a reused one keeps stale CSS (HTTP cache) between runs
  const udd = path.resolve(OUT, '.chrome-' + mode); fs.rmSync(udd, {recursive: true, force: true});
  // blink-settings: headless reports `(hover: hover)` false, which disables every Tailwind `hover:` utility (v4 wraps them in @media (hover: hover))
  // port 0 = free port chosen by chromium (several agents run in parallel), read back from DevToolsActivePort
  chrome = spawn('/usr/bin/chromium', ['--headless=new', '--remote-debugging-port=0', '--blink-settings=primaryHoverType=2,availableHoverTypes=2,primaryPointerType=4,availablePointerTypes=4', '--no-first-run', '--hide-scrollbars',
    '--force-device-scale-factor=1', '--force-color-profile=srgb', '--font-render-hinting=none', '--disable-lcd-text',
    `--user-data-dir=${udd}`, 'about:blank'], {stdio: 'ignore'});
  let v; for (let i = 0; i < 100; i++) { try { const port = fs.readFileSync(path.join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0]; v = await (await fetch(`http://127.0.0.1:${port}/json/version`)).json(); break } catch { await sleep(300) } }
  ws = new WebSocket(v.webSocketDebuggerUrl); await new Promise(r => ws.onopen = r);
  ws.onmessage = e => { const m = JSON.parse(e.data); if (m.id && pend[m.id]) { pend[m.id](m); delete pend[m.id] } };
}
const send = (method, params = {}, sessionId) => new Promise((res, rej) => {
  const id = ++nid; pend[id] = m => m.error ? rej(new Error(method + ': ' + m.error.message)) : res(m.result);
  ws.send(JSON.stringify({id, method, params, sessionId}));
});
async function newPage() {
  const {targetId} = await send('Target.createTarget', {url: 'about:blank'});
  const {sessionId} = await send('Target.attachToTarget', {targetId, flatten: true});
  const s = (m, p) => send(m, p, sessionId);
  await s('Page.enable'); await s('Runtime.enable');
  const page = {
    s,
    async eval(expr) { const r = await s('Runtime.evaluate', {expression: expr, returnByValue: true, awaitPromise: true}); if (r.exceptionDetails) throw new Error(r.exceptionDetails.exception?.description || r.exceptionDetails.text); return r.result.value },
    async goto(url) { await s('Page.navigate', {url}); for (let i = 0; i < 100; i++) { await sleep(100); try { if (await page.eval('document.readyState') === 'complete') break } catch {} } await page.eval('document.fonts.ready.then(()=>1)') },
    async size(w, h) { await s('Emulation.setDeviceMetricsOverride', {width: w, height: h, deviceScaleFactor: 1, mobile: false}) },
    async shot(r, file) { const x = await s('Page.captureScreenshot', {format: 'png', captureBeyondViewport: true, clip: {x: r.x, y: r.y, width: r.w, height: r.h, scale: 1}}); fs.writeFileSync(file, Buffer.from(x.data, 'base64')) },
    async move(x, y) { await s('Input.dispatchMouseEvent', {type: 'mouseMoved', x, y}) },
  };
  return page;
}

// ---------- page-side helpers (both pages) ----------
const HELPERS = `(() => {
const FREEZE = '*,*::before,*::after{animation-play-state:paused!important;animation-delay:-0.5s!important;transition:none!important;caret-color:transparent!important}.d-exp{overflow:visible!important}';
const st = document.createElement('style'); st.textContent = FREEZE; document.head.appendChild(st);
const depthSplit = (s, sep) => { const o = []; let d = 0, c = ''; for (const ch of s) { if ('([' .includes(ch)) d++; if (')]'.includes(ch)) d--; if (ch === sep && d === 0) { o.push(c); c = '' } else c += ch } o.push(c); return o };
const hoverTarget = sel => { const i = sel.indexOf(':hover'); if (i < 0) return null; let d = 0, e = i + 6;
  for (; e < sel.length; e++) { const ch = sel[e]; if ('(['.includes(ch)) d++; else if (')]'.includes(ch)) d--; else if (d === 0 && /[\\s>+~]/.test(ch)) break }
  const t = sel.slice(0, e).replaceAll(':hover', '').trim(); return t && !t.includes('::') ? t : null };
const set = new Set();
const walk = rules => { for (const r of rules) { if (r.selectorText === undefined) { if (r.cssRules) walk(r.cssRules); continue }
  if (!r.selectorText.includes(':hover')) continue;
  for (const s of depthSplit(r.selectorText, ',')) { const t = hoverTarget(s.trim()); if (t) { try { document.querySelector(t); set.add(t) } catch {} } } } };
for (const ss of document.styleSheets) { try { walk(ss.cssRules) } catch {} }
const BASE = 'button,a[href],[role=button],input,select,textarea,summary,tr,.lu-card,.lu-chip,.lu-menu-item';
const HOVER = BASE + ',' + [...set].filter(t => !/^(html|body|:root|\\*|\\.lu-board)$/.test(t)).join(',');
window.__roots = {};
const rect = els => { let x1 = 1e9, y1 = 1e9, x2 = -1e9, y2 = -1e9; for (const e of els) { const r = e.getBoundingClientRect(); if (r.width < 1 && r.height < 1) continue;
  x1 = Math.min(x1, r.left + scrollX); y1 = Math.min(y1, r.top + scrollY); x2 = Math.max(x2, r.right + scrollX); y2 = Math.max(y2, r.bottom + scrollY) }
  return x2 < x1 ? null : {x: Math.floor(x1), y: Math.floor(y1), w: Math.ceil(x2) - Math.floor(x1), h: Math.ceil(y2) - Math.floor(y1)} };
// hover signature WITHOUT lu-* classes: tag + accessible text (aria-label | title | text | icon name) + occurrence among all elements of the roots with the same tag/text
const label = e => (e.getAttribute('aria-label') || e.getAttribute('title') || e.textContent.replace(/\\s+/g, ' ').trim() || e.querySelector('svg[data-icon]')?.getAttribute('data-icon') || '').slice(0, 40);
const sk = e => e.tagName.toLowerCase() + '|' + label(e);
const all = els => els.flatMap(r => [r, ...r.querySelectorAll('*')]);
const sig = (e, els) => { const k = sk(e); return k + '|' + all(els).filter(x => sk(x) === k).indexOf(e) };
const visible = e => { const r = e.getBoundingClientRect(); return r.width >= 1 && r.height >= 1 && !e.disabled && getComputedStyle(e).visibility !== 'hidden' && getComputedStyle(e).pointerEvents !== 'none' };
const cands = els => { const out = new Map(); for (const e of all(els)) { let ok = false; try { ok = e.matches(HOVER) } catch {} if (ok && visible(e)) { const s = sig(e, els); if (!out.has(s)) out.set(s, e) } } return out };
// showcase side: find the element by signature, no stylesheet knowledge needed
const bySig = (els, s) => { const i = s.lastIndexOf('|'), k = s.slice(0, i), n = +s.slice(i + 1); const e = all(els).filter(x => sk(x) === k)[n]; return e && visible(e) ? e : null };
window.__v = {
  rect: k => rect(window.__roots[k] || []),
  hovers: k => [...cands(window.__roots[k]).keys()],
  hoverPoint: (k, s, side) => { const e = side === 'show' ? bySig(window.__roots[k], s) : cands(window.__roots[k]).get(s); if (!e) return null; e.scrollIntoView({block: 'nearest', inline: 'nearest'}); const r = e.getBoundingClientRect(); return {x: r.left + r.width / 2, y: r.top + r.height / 2} },
  setTheme: t => { document.documentElement.setAttribute('data-theme', t); document.querySelectorAll('.lu-board').forEach(b => b.setAttribute('data-theme', t)) },
  hoverCount: () => set.size,
  // deterministic animation phase: CSS animations that were already running when the freeze style was added keep their elapsed time, so rewind all to 0 (the freeze style adds the -0.5s delay)
  freeze: () => { for (const a of document.getAnimations()) { if (a.transitionProperty) continue; try { a.pause(); a.currentTime = 0 } catch {} } return 1 },
};
})()`;

// ---------- canvas side ----------
const docs = JSON.parse(fs.readFileSync(path.join(DESIGN, 'vitrine/docs.json'), 'utf8'));
const NAMES = Object.fromEntries(docs.map(d => [d.name, d.id]));
const TITLES = {};
const EXTRAS = fs.existsSync(path.join(DESIGN, 'canvas/extras.json')) ? JSON.parse(fs.readFileSync(path.join(DESIGN, 'canvas/extras.json'), 'utf8')) : {};
// NN of an example = position in vitrine/sec/<id>.json, then the canvas-only demos (extras.json) - same order as LedgerShowcase.Examples
for (const d of docs) { const f = path.join(DESIGN, 'vitrine/sec', d.id + '.json'); if (fs.existsSync(f)) TITLES[d.id] = JSON.parse(fs.readFileSync(f, 'utf8')).map(s => s.t).concat((EXTRAS[d.id] || []).map(s => s.t)) }
const MAP = `((names, titles) => {
const txt = e => e.textContent.replace(/\\s+/g, ' ').trim();
const out = []; document.querySelectorAll('section').forEach(sec => {
  const h2 = sec.querySelector('h2'); if (!h2) return; const id = names[txt(h2)]; if (!id || !titles[id]) return; const ts = titles[id];
  const demos = [...sec.querySelectorAll('.lu-demo')].filter(d => !d.querySelector('.lu-demo'));
  if (!demos.length) { const stage = sec.querySelector('.lu-stage'); if (ts.length === 1 && stage) { stage.setAttribute('data-vk', id + '|1'); window.__roots[id + '|1'] = [...stage.children]; out.push({id, idx: 1}) } return }
  const seen = {};
  demos.forEach(d => { const kids = [...d.children]; const spec = kids.find(k => k.classList.contains('lu-spec')); const body = kids.filter(k => !k.classList.contains('lu-spec'));
    const title = spec ? txt(spec).replace(/\\s*·\\s*em loop$/u, '').trim() : null; const n = seen[title] || 0;
    const idxs = []; ts.forEach((t, i) => { if (t.trim() === title) idxs.push(i + 1) }); const idx = idxs[n];
    seen[title] = n + 1; if (idx) { window.__roots[id + '|' + idx] = body; out.push({id, idx}) } }) });
return out })`;

async function canvasPhase() {
  const boards = JSON.parse(await (await fetch(CANVAS_URL + '/boards.json')).text());
  const pg = await newPage(); await pg.size(W, 1000);
  const winner = {}; // key -> board (last wins)
  for (const b of boards) { await pg.goto(`${CANVAS_URL}/${b}`); await pg.eval(HELPERS);
    const m = await pg.eval(`JSON.stringify(${MAP}(${JSON.stringify(NAMES)}, ${JSON.stringify(TITLES)}))`);
    for (const {id, idx} of JSON.parse(m)) winner[key(id, idx)] = b; }
  const manifest = {};
  for (const theme of THEMES) for (const b of boards) {
    const mine = Object.entries(winner).filter(([k, bb]) => bb === b && (!ONLY || ONLY.has(k.split('|')[0]))).map(([k]) => k);
    if (!mine.length) continue;
    await pg.goto(`${CANVAS_URL}/${b}`); await pg.eval(HELPERS); await pg.eval(`__v.setTheme(${JSON.stringify(theme)})`);
    await pg.eval(`JSON.stringify(${MAP}(${JSON.stringify(NAMES)}, ${JSON.stringify(TITLES)})).length`);
    const h = await pg.eval('document.documentElement.scrollHeight'); await pg.size(W, Math.min(h, 15000)); await sleep(300);
    for (const k of mine) {
      const [id, idx] = k.split('|'); await pg.eval('scrollTo(0, 0); __v.freeze()'); const r = await pg.eval(`__v.rect(${JSON.stringify(k)})`); if (!r) continue; // scroll reset: hovers of the previous entry scroll the page and the clip is relative to the viewport
      const e = manifest[k] ||= {id, idx: +idx, board: b, w: r.w, h: r.h, themes: {}};
      await pg.shot(r, path.join(OUT, 'raw', 'canvas__' + fname(theme, id, idx, 'base')));
      const hovers = JSON.parse(await pg.eval(`JSON.stringify(__v.hovers(${JSON.stringify(k)}))`)).slice(0, MAXHOV);
      e.themes[theme] = {hovers: []};
      for (let n = 0; n < hovers.length; n++) {
        const p = await pg.eval(`JSON.stringify(__v.hoverPoint(${JSON.stringify(k)}, ${JSON.stringify(hovers[n])}))`); if (!p || p === 'null') continue;
        const {x, y} = JSON.parse(p); await pg.move(x, y); await sleep(60); await pg.eval('__v.freeze()');
        const r2 = r; // same clip as base (page coords unchanged: scroll does not move page coords)
        await pg.shot(r2, path.join(OUT, 'raw', 'canvas__' + fname(theme, id, idx, 'h' + n)));
        e.themes[theme].hovers.push({n, sig: hovers[n]}); await pg.move(0, 0);
      }
    }
    console.log('canvas', theme, b, mine.length);
  }
  fs.writeFileSync(path.join(OUT, 'manifest.json'), JSON.stringify(manifest, null, 1));
}

// ---------- showcase side ----------
async function showcasePhase() {
  const manifest = JSON.parse(fs.readFileSync(path.join(OUT, 'manifest.json'), 'utf8'));
  const ids = [...new Set(Object.values(manifest).filter(e => !e.tpl).map(e => e.id))].filter(id => !ONLY || ONLY.has(id));
  const pg = await newPage(); await pg.size(W, 1000);
  const meta = fs.existsSync(path.join(OUT, 'showcase_meta.json')) ? JSON.parse(fs.readFileSync(path.join(OUT, 'showcase_meta.json'), 'utf8')) : {};
  for (const theme of THEMES) for (const id of ids) {
    await pg.goto(`${SHOW_URL}/full/${id}?theme=${theme}&palette=ledger`); // the palette is stored (lu-palette): always pass it
    for (let i = 0; i < 40; i++) { if (await pg.eval(`!!document.querySelector('.phx-connected')&&document.querySelectorAll('.d-ex').length>0`)) break; await sleep(150) }
    await pg.eval(HELPERS); await sleep(250);
    const entries = Object.values(manifest).filter(e => e.id === id && !e.tpl);
    for (const e of entries) {
      const k = key(id, e.idx);
      const ok = await pg.eval(`(() => { const ex = document.querySelectorAll('.d-ex')[${e.idx - 1}]; if (!ex) return false; const d = ex.querySelector('.d-in2'); if (!d) return false;
        d.querySelectorAll('.lu-grid[data-cols0]').forEach(g => g.style.setProperty('--cols', g.getAttribute('data-cols0'))); // undo the showcase's narrow-page collapse (act.js): the canvas is wider
        d.style.setProperty('width', '${e.w}px', 'important'); d.style.setProperty('align-items', 'stretch', 'important'); d.style.setProperty('gap', '4px', 'important');
        d.style.setProperty('max-width', 'none', 'important'); window.__roots[${JSON.stringify(k)}] = [...d.children]; ex.setAttribute('data-vk', ${JSON.stringify(k)}); return true })()`);
      if (!ok) { (meta[theme] ||= {})[k] = {missing: true}; continue }
      const h = await pg.eval('document.documentElement.scrollHeight'); await pg.size(W, Math.min(Math.max(h, 1000), 15000)); await pg.eval('scrollTo(0, 0); __v.freeze()');
      const r = await pg.eval(`JSON.stringify(__v.rect(${JSON.stringify(k)}))`); if (r === 'null') { (meta[theme] ||= {})[k] = {empty: true}; continue }
      const rr = JSON.parse(r); await pg.move(0, 0);
      await pg.shot(rr, path.join(OUT, 'raw', 'show__' + fname(theme, id, e.idx, 'base')));
      const m = (meta[theme] ||= {})[k] = {w: rr.w, h: rr.h, hovers: [], hoverMissing: []};
      for (const hv of e.themes[theme]?.hovers || []) {
        const p = await pg.eval(`JSON.stringify(__v.hoverPoint(${JSON.stringify(k)}, ${JSON.stringify(hv.sig)}, 'show'))`);
        if (p === 'null') { m.hoverMissing.push(hv.sig); continue }
        const {x, y} = JSON.parse(p); await pg.move(x, y); await sleep(60); await pg.eval('__v.freeze()');
        await pg.shot(rr, path.join(OUT, 'raw', 'show__' + fname(theme, id, e.idx, 'h' + hv.n))); m.hovers.push(hv.n); await pg.move(0, 0);
      }
    }
    console.log('showcase', theme, id, entries.length);
  }
  fs.writeFileSync(path.join(OUT, 'showcase_meta.json'), JSON.stringify(meta, null, 1));
}


// ---------- page templates: /templates/<slug> vs T*Claro / T*Escuro boards ----------
// idx 1 = full board (base + hover), idx 2 = 1440x900 viewport (base only, only when the board is taller than 900)
const TPL = {AuthLogin: 'auth-login', AuthLoginErro: 'auth-login-erro', AuthCadastro: 'auth-cadastro', AuthCodigo: 'auth-codigo', AuthSenha: 'auth-senha',
  Dashboard: 'dashboard', Tabela: 'tabela', TabelaGaveta: 'tabela-gaveta', TabelaModal: 'tabela-modal',
  CrepAuthLogin: 'crep-auth-login', CrepDashboard: 'crep-dashboard', CrepPaleta: 'crep-paleta'};
// the Crepúsculo boards are the same pages with ?palette=crepusculo (the palette page has its own route)
const TPL_PATH = {'crep-auth-login': 'auth-login?palette=crepusculo', 'crep-dashboard': 'dashboard?palette=crepusculo', 'crep-paleta': 'paleta'};
const tplUrl = (slug, theme) => { const p = TPL_PATH[slug] || slug; return `${SHOW_URL}/templates/${p}${p.includes('?') ? '&' : '?'}theme=${theme}${p.includes('palette=') ? '' : '&palette=ledger'}` };
const MAXHOV_T = 12, VH = 900;
const tplSlug = b => TPL[b.replace(/^T/, '').replace(/(Claro|Escuro)\.html$/, '')];
async function tplCanvasPhase() {
  const boards = JSON.parse(await (await fetch(CANVAS_URL + '/tboards.json')).text());
  const pg = await newPage(); await pg.size(1440, VH);
  const manifest = JSON.parse(fs.readFileSync(path.join(OUT, 'manifest.json'), 'utf8'));
  for (const b of boards) {
    const slug = tplSlug(b), theme = /Escuro/.test(b) ? 'dark' : 'light'; const id = 'tpl-' + slug;
    if (!THEMES.includes(theme) || (ONLY && !ONLY.has(id))) continue;
    await pg.goto(`${CANVAS_URL}/${b}`); await pg.eval(HELPERS);
    await pg.eval(`window.__roots['${id}|1'] = [document.querySelector('.lu-board')]; 1`); await sleep(300); await pg.eval('__v.freeze()');
    const r = JSON.parse(await pg.eval(`JSON.stringify(__v.rect('${id}|1'))`));
    const e = manifest[key(id, 1)] ||= {id, idx: 1, tpl: true, board: b, w: r.w, h: r.h, themes: {}};
    const e2 = r.h > VH ? (manifest[key(id, 2)] ||= {id, idx: 2, tpl: true, board: b, w: r.w, h: VH, themes: {}}) : null;
    await pg.shot(r, path.join(OUT, 'raw', 'canvas__' + fname(theme, id, 1, 'base')));
    if (e2) { e2.themes[theme] = {hovers: []}; await pg.shot({x: r.x, y: r.y, w: r.w, h: VH}, path.join(OUT, 'raw', 'canvas__' + fname(theme, id, 2, 'base'))) }
    const hovers = JSON.parse(await pg.eval(`JSON.stringify(__v.hovers('${id}|1'))`)).slice(0, MAXHOV_T);
    e.themes[theme] = {hovers: []};
    for (let n = 0; n < hovers.length; n++) {
      const p = await pg.eval(`JSON.stringify(__v.hoverPoint('${id}|1', ${JSON.stringify(hovers[n])}))`); if (p === 'null') continue;
      const {x, y} = JSON.parse(p); await pg.move(x, y); await sleep(60); await pg.eval('__v.freeze()');
      await pg.shot(r, path.join(OUT, 'raw', 'canvas__' + fname(theme, id, 1, 'h' + n)));
      e.themes[theme].hovers.push({n, sig: hovers[n]}); await pg.move(0, 0);
    }
    console.log('canvas template', theme, slug, r.w + 'x' + r.h, 'hovers', hovers.length);
  }
  fs.writeFileSync(path.join(OUT, 'manifest.json'), JSON.stringify(manifest, null, 1));
}
async function tplShowcasePhase() {
  const manifest = JSON.parse(fs.readFileSync(path.join(OUT, 'manifest.json'), 'utf8'));
  const pg = await newPage(); await pg.size(1440, VH);
  const meta = fs.existsSync(path.join(OUT, 'showcase_meta.json')) ? JSON.parse(fs.readFileSync(path.join(OUT, 'showcase_meta.json'), 'utf8')) : {};
  for (const theme of THEMES) for (const e of Object.values(manifest).filter(e => e.tpl && e.idx === 1 && (!ONLY || ONLY.has(e.id)))) {
    const slug = e.id.slice(4); const k = key(e.id, 1), k2 = key(e.id, 2);
    await pg.size(1440, e.h); // viewport = board height so fixed overlays / 100vh match the canvas board
    await pg.goto(tplUrl(slug, theme));
    for (let i = 0; i < 40; i++) { if (await pg.eval(`!!document.querySelector('.phx-connected')`)) break; await sleep(150) }
    await pg.eval(HELPERS); await pg.eval("(() => { const s = document.createElement('style'); s.textContent = '.tpl-chrome{display:none!important}'; document.head.appendChild(s) })()"); await sleep(400); await pg.eval('__v.freeze()'); // the back/theme buttons are showcase chrome, not part of the template
    await pg.eval(`window.__roots[${JSON.stringify(k)}] = [document.body]; 1`);
    const rr = {x: 0, y: 0, w: e.w, h: e.h}; await pg.move(0, 0);
    await pg.shot(rr, path.join(OUT, 'raw', 'show__' + fname(theme, e.id, 1, 'base')));
    const m = (meta[theme] ||= {})[k] = {w: e.w, h: e.h, hovers: [], hoverMissing: [], docH: await pg.eval('document.documentElement.scrollHeight')};
    if (manifest[k2]) { await pg.size(1440, VH); await sleep(400); await pg.shot({x: 0, y: 0, w: e.w, h: VH}, path.join(OUT, 'raw', 'show__' + fname(theme, e.id, 2, 'base'))); (meta[theme][k2] = {w: e.w, h: VH, hovers: [], hoverMissing: []}); await pg.size(1440, e.h); await sleep(400) }
    for (const hv of e.themes[theme]?.hovers || []) {
      await pg.eval(`window.__roots[${JSON.stringify(k)}] = [document.body]; 1`);
      const p = await pg.eval(`JSON.stringify(__v.hoverPoint(${JSON.stringify(k)}, ${JSON.stringify(hv.sig)}, 'show'))`);
      if (p === 'null') { m.hoverMissing.push(hv.sig); continue }
      const {x, y} = JSON.parse(p); await pg.move(x, y); await sleep(60); await pg.eval('__v.freeze()');
      await pg.shot(rr, path.join(OUT, 'raw', 'show__' + fname(theme, e.id, 1, 'h' + hv.n))); m.hovers.push(hv.n); await pg.move(0, 0);
    }
    console.log('showcase template', theme, slug);
  }
  fs.writeFileSync(path.join(OUT, 'showcase_meta.json'), JSON.stringify(meta, null, 1));
}

// ---------- diff (in the browser) ----------
const DIFF = `window.__diff = async (a64, b64) => {
  const load = async b => { const bin = atob(b); const u = new Uint8Array(bin.length); for (let i = 0; i < bin.length; i++) u[i] = bin.charCodeAt(i); return createImageBitmap(new Blob([u], {type: 'image/png'})) };
  const [A, B] = [await load(a64), await load(b64)];
  const px = im => { const c = document.createElement('canvas'); c.width = im.width; c.height = im.height; const x = c.getContext('2d', {willReadFrequently: true}); x.drawImage(im, 0, 0); return x.getImageData(0, 0, im.width, im.height).data };
  const da = px(A), db = px(B), T = 24;
  const bga = [da[0], da[1], da[2]], bgb = [db[0], db[1], db[2]];
  const far = (d, i, bg) => Math.abs(d[i] - bg[0]) > T || Math.abs(d[i + 1] - bg[1]) > T || Math.abs(d[i + 2] - bg[2]) > T;
  // B is placed at (dx,dy) relative to A; only the overlapping region is compared
  const cmp = (dx, dy, od) => { const x0 = Math.max(0, dx), x1 = Math.min(A.width, B.width + dx), y0 = Math.max(0, dy), y1 = Math.min(A.height, B.height + dy);
    let diff = 0, ink = 0; for (let y = y0; y < y1; y++) for (let x = x0; x < x1; x++) { const i = (y * A.width + x) * 4, j = ((y - dy) * B.width + (x - dx)) * 4;
      const ia = far(da, i, bga), ib = far(db, j, bgb); const d = Math.abs(da[i] - db[j]) > T || Math.abs(da[i + 1] - db[j + 1]) > T || Math.abs(da[i + 2] - db[j + 2]) > T;
      if (ia || ib || d) ink++; if (d) diff++;
      if (od) { if (d) { od[i] = 255; od[i + 1] = 30; od[i + 2] = 60 } else { const g = (da[i] + da[i + 1] + da[i + 2]) / 3; od[i] = od[i + 1] = od[i + 2] = 235 - (235 - g) * 0.35 } od[i + 3] = 255 } }
    return {diff, ink, area: Math.max(1, (x1 - x0) * (y1 - y0))} };
  let best = {...cmp(0, 0), dx: 0, dy: 0};
  if (best.diff / best.area > 0.003) for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) { if (!dx && !dy) continue; const r = cmp(dx, dy); if (r.diff < best.diff) best = {...r, dx, dy} }
  const out = document.createElement('canvas'); out.width = A.width; out.height = A.height; const ox = out.getContext('2d'); const id = ox.createImageData(A.width, A.height);
  for (let i = 3; i < id.data.length; i += 4) id.data[i] = 255; for (let i = 0; i < id.data.length; i += 4) id.data[i] = id.data[i + 1] = id.data[i + 2] = 200;
  cmp(best.dx, best.dy, id.data); ox.putImageData(id, 0, 0);
  const w = Math.max(A.width, B.width), h = Math.max(A.height, B.height);
  const s = Math.min(1, 420 / w, 520 / h), gap = 6; const M = document.createElement('canvas'); M.width = Math.round(w * s * 3 + gap * 2); M.height = Math.round(h * s);
  const mx = M.getContext('2d'); mx.fillStyle = '#888'; mx.fillRect(0, 0, M.width, M.height);
  [A, B, out].forEach((im, n) => { mx.drawImage(im, 0, 0, im.width, im.height, n * (w * s + gap), 0, im.width * s, im.height * s) });
  return {w1: A.width, h1: A.height, w2: B.width, h2: B.height, diff: best.diff, area: best.area, ink: best.ink, dx: best.dx, dy: best.dy, montage: M.toDataURL('image/jpeg', 0.72).split(',')[1]};
}`;

async function diffPhase() {
  const manifest = JSON.parse(fs.readFileSync(path.join(OUT, 'manifest.json'), 'utf8'));
  const meta = JSON.parse(fs.readFileSync(path.join(OUT, 'showcase_meta.json'), 'utf8'));
  const pg = await newPage(); await pg.eval(DIFF);
  fs.mkdirSync(path.join(OUT, 'img'), {recursive: true});
  const results = [];
  const rd = f => fs.readFileSync(path.join(OUT, 'raw', f)).toString('base64');
  for (const theme of THEMES) for (const e of Object.values(manifest)) {
    if (ONLY && !ONLY.has(e.id)) continue;
    const m = meta[theme]?.[key(e.id, e.idx)]; if (!m) continue;
    if (m.missing || m.empty) { results.push({id: e.id, idx: e.idx, theme, state: 'base', error: m.missing ? 'no showcase example' : 'empty'}); continue }
    const states = ['base', ...m.hovers.map(n => 'h' + n)];
    let baseA, baseB;
    for (const st of states) {
      const fa = 'canvas__' + fname(theme, e.id, e.idx, st), fb = 'show__' + fname(theme, e.id, e.idx, st);
      if (!fs.existsSync(path.join(OUT, 'raw', fa)) || !fs.existsSync(path.join(OUT, 'raw', fb))) continue;
      const a = rd(fa), b = rd(fb);
      const r = await pg.eval(`__diff(${JSON.stringify(a)}, ${JSON.stringify(b)}).then(r => JSON.stringify(r))`).then(JSON.parse);
      const sig = st === 'base' ? '' : e.themes[theme].hovers.find(h => 'h' + h.n === st).sig;
      const o = {id: e.id, idx: e.idx, theme, state: st, sig, off: r.dx || r.dy ? r.dx + ',' + r.dy : '', w1: r.w1, h1: r.h1, w2: r.w2, h2: r.h2, pct: +(100 * r.diff / r.area).toFixed(3), inkPct: r.ink ? +(100 * r.diff / r.ink).toFixed(2) : 0};
      if (st === 'base') { baseA = a; baseB = b } else {
        // does the hover change anything on each side? (compare with the base shot of that side)
        const ca = await pg.eval(`__diff(${JSON.stringify(baseA)}, ${JSON.stringify(a)}).then(r => r.diff)`);
        const cb = await pg.eval(`__diff(${JSON.stringify(baseB)}, ${JSON.stringify(b)}).then(r => r.diff)`);
        o.canvasChange = ca; o.showChange = cb; o.hoverMissing = ca > 0 && cb === 0;
      }
      const name = fname(theme, e.id, e.idx, st).replace('.png', '.jpg');
      if (o.pct >= 0.3 || o.hoverMissing) fs.writeFileSync(path.join(OUT, 'img', name), Buffer.from(r.montage, 'base64'));
      else o.noimg = true;
      o.img = name; results.push(o);
    }
    for (const sg of m.hoverMissing) results.push({id: e.id, idx: e.idx, theme, state: 'hover', sig: sg, unpaired: true, pct: 0, inkPct: 0});
  }
  // partial runs (ONLY) keep the previous results of the other ids
  const rf = path.join(OUT, 'results.json'); let all = results;
  if (ONLY && fs.existsSync(rf)) { const keep = JSON.parse(fs.readFileSync(rf, 'utf8')).filter(r => !ONLY.has(r.id)); all = keep.concat(results) }
  fs.writeFileSync(rf, JSON.stringify(all));
  console.log('results', results.length);
}

// ---------- report ----------
function reportPhase() {
  const res = JSON.parse(fs.readFileSync(path.join(OUT, 'results.json'), 'utf8'));
  const before = fs.existsSync(path.join(OUT, 'results-before.json')) ? JSON.parse(fs.readFileSync(path.join(OUT, 'results-before.json'), 'utf8')) : null;
  const ok = res.filter(r => !r.error && !r.unpaired); const bk = r => `${r.theme}|${r.id}|${r.idx}|${r.state}`;
  const bmap = before ? new Map(before.map(r => [bk(r), r])) : null;
  const stat = (arr) => ({n: arr.length, lt1: arr.filter(r => r.pct < 1).length, lt5: arr.filter(r => r.pct < 5).length, avg: arr.length ? +(arr.reduce((s, r) => s + r.pct, 0) / arr.length).toFixed(2) : 0});
  const isT = r => r.id.startsWith('tpl-'); const okC = ok.filter(r => !isT(r)), okT = ok.filter(isT);
  const groups = {light: okC.filter(r => r.theme === 'light' && r.state === 'base'), dark: okC.filter(r => r.theme === 'dark' && r.state === 'base'), hover: okC.filter(r => r.state !== 'base'),
    tLight: okT.filter(r => r.theme === 'light' && r.state === 'base'), tDark: okT.filter(r => r.theme === 'dark' && r.state === 'base'), tHover: okT.filter(r => r.state !== 'base')};
  const hv = groups.hover; const miss = hv.filter(r => r.hoverMissing);
  const sorted = [...ok.filter(r => r.pct >= 0.3 || r.hoverMissing)].sort((a, b) => b.pct - a.pct);
  const esc = s => String(s).replace(/[&<>]/g, c => ({'&': '&amp;', '<': '&lt;', '>': '&gt;'}[c]));
  const row = r => { const img = r.noimg ? '' : (fs.existsSync(path.join(OUT, 'img', r.img)) ? `<img loading=lazy src="data:image/jpeg;base64,${fs.readFileSync(path.join(OUT, 'img', r.img)).toString('base64')}">` : '');
    const b = bmap?.get(bk(r)); return `<tr><td>${r.id} #${r.idx}</td><td>${r.theme}</td><td>${r.state}${r.sig ? '<br><small>' + esc(r.sig) + '</small>' : ''}</td><td><b>${r.pct}%</b>${b ? `<br><small>before ${b.pct}%</small>` : ''}<br><small>ink ${r.inkPct}%</small></td><td>${r.w1}x${r.h1} | ${r.w2}x${r.h2}${Math.abs(r.w1 - r.w2) > 1 || Math.abs(r.h1 - r.h2) > 1 ? ' <b style="color:#c00">size</b>' : ''}</td><td>${r.hoverMissing ? '<b style="color:#c00">canvas hover changes ' + r.canvasChange + 'px, showcase 0</b>' : (r.canvasChange !== undefined ? `hover px canvas ${r.canvasChange} / showcase ${r.showChange}` : '')}</td><td>${img}</td></tr>` };
  const sumRow = (n, s) => `<tr><td>${n}</td><td>${s.n}</td><td>${s.lt1}</td><td>${s.lt5}</td><td>${s.avg}%</td></tr>`;
  // per-section summary (components only): worst pct over themes/states; `inkPct` = diff / (non-background pixels), stricter for small widgets
  const secs = {};
  for (const r of res.filter(r => !isT(r))) { const k = r.id + '|' + r.idx; const e = secs[k] ||= {id: r.id, idx: r.idx, themes: {}, hover: [], max: 0, maxInk: 0, errors: [], unpaired: 0, sizeMismatch: false};
    if (r.error) { e.errors.push(r.theme + ': ' + r.error); continue } if (r.unpaired) { e.unpaired++; continue }
    if (r.state === 'base') e.themes[r.theme] = {pct: r.pct, inkPct: r.inkPct, canvas: [r.w1, r.h1], showcase: [r.w2, r.h2]}; else e.hover.push({theme: r.theme, state: r.state, sig: r.sig, pct: r.pct, hoverMissing: !!r.hoverMissing});
    e.max = Math.max(e.max, r.pct); e.maxInk = Math.max(e.maxInk, r.inkPct); if (Math.abs(r.w1 - r.w2) > 1 || Math.abs(r.h1 - r.h2) > 1) e.sizeMismatch = true; if (r.hoverMissing) e.hoverMissing = true }
  const list = Object.values(secs).sort((a, b) => a.id.localeCompare(b.id) || a.idx - b.idx);
  for (const e of list) e.pass = !e.errors.length && e.max <= THRESHOLD && e.maxInk <= INK_THRESHOLD && !e.hoverMissing;
  const summary = {threshold: THRESHOLD, inkThreshold: INK_THRESHOLD, sections: list.length, pass: list.filter(e => e.pass).length, over: list.filter(e => !e.errors.length && (e.max > THRESHOLD || e.maxInk > INK_THRESHOLD)).length, errors: list.filter(e => e.errors.length).length, hoverMissing: list.filter(e => e.hoverMissing).length};
  fs.writeFileSync(path.join(OUT, 'report.json'), JSON.stringify({summary, sections: list, templates: {light: stat(groups.tLight), dark: stat(groups.tDark)}}, null, 1));
  const imgTag = r => { const f = path.join(OUT, 'img', r.img || ''); return r.img && !r.noimg && fs.existsSync(f) ? `<img loading=lazy src="data:image/jpeg;base64,${fs.readFileSync(f).toString('base64')}">` : '' };
  const secRow = e => { const worst = res.filter(r => r.id === e.id && r.idx === e.idx && !r.error && !r.unpaired).sort((a, b) => b.pct - a.pct)[0];
    return `<tr class="${e.pass ? 'ok' : 'bad'}"><td><b>${e.id}</b> #${e.idx}</td><td>${e.pass ? 'ok' : e.errors.length ? 'error' : 'over'}</td><td><b>${e.max}%</b><br><small>ink ${e.maxInk}%</small></td><td>${['light', 'dark'].map(t => e.themes[t] ? `${t} ${e.themes[t].pct}%` : '').join('<br>')}</td><td>${e.hover.map(h => `${h.theme} ${esc(h.sig)}: ${h.pct}%${h.hoverMissing ? ' (hover missing)' : ''}`).join('<br>')}</td><td>${e.errors.join('<br>')}${e.sizeMismatch ? '<b style="color:#c00">size differs</b>' : ''}${e.unpaired ? ` <small>${e.unpaired} unpaired hover</small>` : ''}</td><td>${worst ? imgTag(worst) : ''}</td></tr>` };
  const html = `<!doctype html><meta charset=utf-8><title>Ledger UI visual report</title><style>body{font:13px system-ui;margin:20px}table{border-collapse:collapse}td,th{border:1px solid #ccc;padding:4px 8px;vertical-align:top}img{max-width:1300px;display:block}small{color:#666}tr.bad td:nth-child(2){color:#c00;font-weight:bold}tr.ok td:nth-child(2){color:#080}</style>
<h1>Canvas vs showcase, per section</h1>
<p>threshold <b>${THRESHOLD}%</b> of the box and <b>${INK_THRESHOLD}%</b> of the inked pixels (max over light/dark base + hover): ${summary.pass}/${summary.sections} sections ok, ${summary.over} over, ${summary.errors} without showcase example/empty, ${summary.hoverMissing} with a canvas hover that does nothing in the showcase.</p>
<table><tr><th>set</th><th>compared</th><th>&lt;1%</th><th>&lt;5%</th><th>avg diff</th></tr>${sumRow('light base', stat(groups.light))}${sumRow('dark base', stat(groups.dark))}${sumRow('hover', stat(hv))}${sumRow('templates light (full + viewport)', stat(groups.tLight))}${sumRow('templates dark (full + viewport)', stat(groups.tDark))}${sumRow('templates hover', stat(groups.tHover))}</table>
<h2>Sections (worst first)</h2><table><tr><th>section</th><th>status</th><th>max diff</th><th>base</th><th>hover</th><th>notes</th><th>canvas | showcase | diff (worst state)</th></tr>${[...list].sort((a, b) => b.max - a.max).map(secRow).join('')}</table>
<h2>Entries with diff &ge; 0.3% (all states)</h2><table><tr><th>section</th><th>theme</th><th>state</th><th>diff</th><th>size canvas | showcase</th><th>hover</th><th>canvas | showcase | diff</th></tr>${sorted.map(row).join('')}</table>
<h2>Unpaired hover targets</h2><ul>${res.filter(r => r.unpaired).map(r => `<li>${r.id} #${r.idx} ${r.theme}: ${esc(r.sig)}</li>`).join('')}</ul>`;
  fs.writeFileSync(path.join(OUT, 'report.html'), html);
  console.log(JSON.stringify({summary, light: stat(groups.light), dark: stat(groups.dark), hover: stat(hv), tLight: stat(groups.tLight), tDark: stat(groups.tDark)}));
  console.log('report:', path.join(OUT, 'report.html'), path.join(OUT, 'report.json'));
  for (const e of list.filter(e => !e.pass)) console.log(`${e.errors.length ? 'ERR ' : e.hoverMissing && e.max <= THRESHOLD ? 'HOVR' : 'OVER'} ${e.id}#${e.idx} max ${e.max}% ink ${e.maxInk}%${e.errors.length ? ' ' + e.errors[0] : ''}${e.hoverMissing ? ' (canvas hover changes, showcase does not)' : ''}`);
  if (process.env.STRICT === '1' && (summary.over || summary.errors || summary.hoverMissing)) process.exitCode = 1;
}

if (mode === 'report') reportPhase(); else {
  await launch();
  try { if (mode === 'canvas') await canvasPhase(); else if (mode === 'showcase') await showcasePhase(); else if (mode === 'tcanvas') await tplCanvasPhase(); else if (mode === 'tshowcase') await tplShowcasePhase(); else if (mode === 'diff') await diffPhase(); }
  finally { try { ws.close() } catch {} chrome.kill(); }
  process.exit(0);
}
