// Builds static canvas reference pages: node build_canvas.mjs <designDir> <outDir>
import fs from 'node:fs'; import path from 'node:path';
const [design, out] = process.argv.slice(2);
fs.mkdirSync(out, {recursive: true});
fs.copyFileSync(path.join(design, 'canvas/canvas.css'), path.join(out, 'canvas.css'));
const files = fs.readdirSync(path.join(design, 'canvas')).filter(f => /^G.*Claro.*\.dc\.html$/.test(f)).sort();
for (const f of files) {
  const src = fs.readFileSync(path.join(design, 'canvas', f), 'utf8');
  const m = src.match(/<x-dc>([\s\S]*)<\/x-dc>/); if (!m) { console.error('no x-dc', f); continue; }
  const body = m[1].replace(/<helmet>[\s\S]*?<\/helmet>/, '');
  fs.writeFileSync(path.join(out, f.replace('.dc.html', '.html')),
`<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><link rel="stylesheet" href="canvas.css">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Geist+Mono:wght@400;500&display=swap">
<style>body{margin:0}</style></head><body>${body}</body></html>`);
}
fs.writeFileSync(path.join(out, 'boards.json'), JSON.stringify(files.map(f => f.replace('.dc.html', '.html'))));
// page templates (T*Claro / T*Escuro): one board per theme
const tfiles = fs.readdirSync(path.join(design, 'canvas')).filter(f => /^T.*(Claro|Escuro)\.dc\.html$/.test(f)).sort();
for (const f of tfiles) {
  const src = fs.readFileSync(path.join(design, 'canvas', f), 'utf8');
  const m = src.match(/<x-dc>([\s\S]*)<\/x-dc>/); if (!m) { console.error('no x-dc', f); continue; }
  const body = m[1].replace(/<helmet>[\s\S]*?<\/helmet>/, '');
  fs.writeFileSync(path.join(out, f.replace('.dc.html', '.html')),
`<!doctype html><html lang="pt-BR" data-theme="${/Escuro/.test(f) ? 'dark' : 'light'}"><head><meta charset="utf-8"><link rel="stylesheet" href="canvas.css">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Geist+Mono:wght@400;500&display=swap">
<style>body{margin:0}</style></head><body>${body}</body></html>`);
}
fs.writeFileSync(path.join(out, 'tboards.json'), JSON.stringify(tfiles.map(f => f.replace('.dc.html', '.html'))));
console.log(files.length, 'boards', tfiles.length, 'template boards');
