import {createHash} from "node:crypto"
// Static export of the showcase. Called by vitrine.sh with a running showcase.
//   node vitrine.mjs <base_url> <out_dir> <ids_file>
// Dead-renders every route over HTTP, rewrites it for static hosting, copies the assets, writes the runtime.
import fs from "node:fs"
import path from "node:path"
import vm from "node:vm"
import {fileURLToPath} from "node:url"

const [BASE, OUT, IDS_FILE] = process.argv.slice(2)
const here = path.dirname(fileURLToPath(import.meta.url))
const repo = path.resolve(here, "../..")
const showcase = path.join(repo, "showcase")
const depsDir = process.env.MIX_DEPS_PATH || path.join(showcase, "deps")
const WITH_FULL = process.env.FULL !== "0"
const cacheDir = path.resolve(OUT, "../_cache")

const luHrefSrc = fs.readFileSync(path.join(here, "lu-href.js"), "utf8")
const luHref = vm.runInNewContext(luHrefSrc + ";luHref")
const w = (rel, data) => { const f = path.join(OUT, rel); fs.mkdirSync(path.dirname(f), {recursive: true}); fs.writeFileSync(f, data) }
const warnings = []

async function get(p) {
  const r = await fetch(BASE + p, {redirect: "manual"})
  return {status: r.status, body: r.status === 200 ? await r.text() : ""}
}
const ids = fs.readFileSync(IDS_FILE, "utf8").split("\n").map((s) => s.trim()).filter(Boolean)

// ---- crawl -----------------------------------------------------------------------------------------
const pages = new Map() // route path (no query) -> html
const queue = ["/", "/instalacao", "/cores", "/temas", "/novidades", "/templates", ...ids.map((i) => "/c/" + i)]
if (WITH_FULL) queue.push(...ids.map((i) => "/full/" + i))
const seen = new Set(queue)
while (queue.length) {
  const p = queue.shift()
  const r = await get(p)
  if (r.status !== 200) { warnings.push(`${p}: HTTP ${r.status}, skipped`); continue }
  pages.set(p, r.body)
  for (const m of r.body.matchAll(/(?:href|src)="(\/templates\/[a-z0-9-]+)(?:\?[^"]*)?"/g))
    if (!seen.has(m[1])) { seen.add(m[1]); queue.push(m[1]) }
}

// ---- rewrite ---------------------------------------------------------------------------------------
const ASSET = [
  [/^\/assets\/(app|showcase)\.(css|js)$/, (m) => `assets/${m[1]}.${m[2]}`],
  [/^\/ledger_ui\/(.+)$/, (m) => `assets/ledger_ui/${m[1]}`],
  [/^\/phoenix\/phoenix\.js$/, () => "assets/phoenix.js"],
  [/^\/phoenix_live_view\/phoenix_live_view\.js$/, () => "assets/phoenix_live_view.js"],
]
function mapUrl(url, root) {
  for (const [re, f] of ASSET) { const m = re.exec(url); if (m) return root + f(m) }
  const r = luHref(url, root)
  if (r !== null) return r
  // example content pointing at files the showcase never had (/images/jane.jpg): neutral inline placeholder
  if (/\.(jpe?g|png|gif|webp|svg)(\?.*)?$/i.test(url)) return PLACEHOLDER
  if (/^\/runs\//.test(url)) return "#" // demo link of a component example
  warnings.push(`unmapped url ${url}`)
  return null
}
const PLACEHOLDER = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' fill='%23c9ccd6'/%3E%3Ccircle cx='32' cy='25' r='11' fill='%23eceef3'/%3E%3Cpath d='M10 64c2-16 12-24 22-24s20 8 22 24z' fill='%23eceef3'/%3E%3C/svg%3E"
const unesc = (s) => s.replace(/&amp;/g, "&")
function rewrite(html, route) {
  const root = route.split("/").length > 1 ? "../" : ""
  html = html.replace(/<meta name="csrf-token"[^>]*>/, "")
  html = html.replace(/<link rel="preconnect"[^>]*>\s*/g, "")
  html = html.replace(/<link\s+rel="stylesheet"\s+href="https:\/\/fonts\.googleapis\.com[^>]*>/, `<link rel="stylesheet" href="${root}assets/fonts.css" />`)
  const mod = /<script type="module">[\s\S]*?<\/script>/
  if (!mod.test(html)) throw new Error("LiveSocket module script not found in " + route)
  html = html.replace(mod, `<script type="module" src="${root}assets/ledger-static.js"></script>`)
  // the legacy "#id" -> route redirect only makes sense on the live "/" route
  html = html.replace('location.pathname === "/"', "false")
  html = html.replace(/<head>/, `<head>\n<script>window.LU_ROOT=${JSON.stringify(root)};${luHrefSrc}\nwindow.luStaticHref=function(p){return luHref(p,window.LU_ROOT)||p}</script>`)
  html = html.replace(/\s(?:data-phx-link-state|data-phx-link|data-phx-session|data-phx-static|data-phx-main)(?:="[^"]*")?/g, "")
  html = html.replace(/\b(href|src)="(\/[^"]*)"/g, (all, a, v) => {
    const u = unesc(v), r = mapUrl(u, root)
    return r === null ? all : `${a}="${r.replace(/&/g, "&amp;")}"`
  })
  return html
}
let nPages = 0
for (const [route, html] of pages) {
  const file = luHref(route, "")
  if (!file) { warnings.push("no file for " + route); continue }
  let out = rewrite(html, file)
  // the old (pre-0.3) vitrine routed by hash: keep its shared links (#dropdown, #tpl-dashboard, #temas) working
  if (file === "index.html") {
    const legacy = `<script>(function(){var h=(location.hash||"").slice(1);if(!h)return;var top={inicio:"index.html",instalacao:"instalacao.html",cores:"cores.html",temas:"temas.html",novidades:"novidades.html"};var to=top[h]||(h.indexOf("tpl-")===0?"templates.html":(/^[a-z0-9-]+$/.test(h)?"c/"+h+".html":null));if(to&&to!=="index.html")location.replace(to)})()</script>`
    out = out.replace("</head>", legacy + "</head>")
  }
  w(file, out)
  nPages++
}

// ---- assets ----------------------------------------------------------------------------------------
const cp = (from, to) => { fs.mkdirSync(path.dirname(path.join(OUT, to)), {recursive: true}); fs.cpSync(from, path.join(OUT, to), {recursive: true}) }
const lv = path.join(depsDir, "phoenix_live_view/priv/static/phoenix_live_view.js")
cp(path.join(showcase, "priv/static/assets/app.css"), "assets/app.css")
cp(path.join(depsDir, "phoenix/priv/static/phoenix.js"), "assets/phoenix.js")
cp(lv, "assets/phoenix_live_view.js")
cp(path.join(repo, "priv/static/ledger_ui"), "assets/ledger_ui")
// dot-files (hooks/.keep) are refused by the artifact host
for (const f of fs.readdirSync(path.join(OUT, "assets/ledger_ui"), {recursive: true})) if (path.basename(String(f)).startsWith(".")) fs.rmSync(path.join(OUT, "assets/ledger_ui", String(f)))
cp(path.join(repo, "priv/static/ledger_ui.esm.js"), "assets/ledger_ui/ledger_ui.esm.js")
cp(path.join(repo, "priv/static/ledger.js"), "assets/ledger_ui/ledger.js")
// esm.js imports "./ledger_ui/hooks/x.js": it now sits INSIDE assets/ledger_ui, so lift the prefix
{
  const f = path.join(OUT, "assets/ledger_ui/ledger_ui.esm.js")
  fs.writeFileSync(f, fs.readFileSync(f, "utf8").replaceAll('"./ledger_ui/', '"./'))
}
// showcase.js: absolute routes -> static files
{
  let js = fs.readFileSync(path.join(showcase, "priv/static/assets/showcase.js"), "utf8")
  const sub = (a, b) => { if (!js.includes(a)) throw new Error("showcase.js changed, cannot patch: " + a); js = js.replace(a, b) }
  sub(`'<a href="/c/' + esc(i[0]) + '" data-phx-link="patch" data-phx-link-state="push" class="'`, `'<a href="' + esc(luStaticHref('/c/' + i[0])) + '" class="'`)
  sub(`$('fsf').src = '/full/' + encodeURIComponent(full.dataset.id) + '?theme=' + theme + '&palette=' + palette;`, `$('fsf').src = luStaticHref('/full/' + encodeURIComponent(full.dataset.id) + '?theme=' + theme + '&palette=' + palette);`)
  sub(`location.pathname === '/'`, `false`)
  w("assets/showcase.js", js)
}
const showcaseCss = path.join(showcase, "priv/static/assets/showcase.css")
cp(showcaseCss, "assets/showcase.css")
w("assets/ledger-static.js", fs.readFileSync(path.join(here, "ledger-static.src.js"), "utf8"))

// ---- fonts (Google Fonts, latin + latin-ext only; cached under out/publish/_cache) --------------------
{
  fs.mkdirSync(cacheDir, {recursive: true})
  const cssFile = path.join(cacheDir, "fonts.css")
  let css
  if (fs.existsSync(cssFile)) css = fs.readFileSync(cssFile, "utf8")
  else {
    const url = "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Inter+Tight:wght@500;600;700&family=Geist+Mono:wght@400;500&display=swap"
    const r = await fetch(url, {headers: {"user-agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/130 Safari/537.36"}})
    if (!r.ok) throw new Error("fonts css: HTTP " + r.status)
    css = await r.text(); fs.writeFileSync(cssFile, css)
  }
  const blocks = [...css.matchAll(/\/\*\s*([a-z-]+)\s*\*\/\s*(@font-face\s*\{[^}]*\})/g)].filter((m) => m[1] === "latin" || m[1] === "latin-ext")
  const files = new Map()
  let out = ""
  for (const [, , block] of blocks) {
    const u = /url\((https:[^)]+)\)/.exec(block)[1]
    if (!files.has(u)) {
      // stable, URL-safe file name (Google Fonts may serve ".../l/font?kit=...&v=..", unusable as a static path)
      const name = createHash("sha1").update(u).digest("hex").slice(0, 16) + ".woff2"
      const cf = path.join(cacheDir, name)
      if (!fs.existsSync(cf)) { const r = await fetch(u); if (!r.ok) throw new Error("font " + u); fs.writeFileSync(cf, Buffer.from(await r.arrayBuffer())) }
      files.set(u, name); cp(cf, "assets/fonts/" + name)
    }
    out += block.replace(u, "fonts/" + files.get(u)) + "\n"
  }
  w("assets/fonts.css", out)
}

// ---- local check: nothing may point at the server ---------------------------------------------------
const bad = []
;(function walk(d) {
  for (const e of fs.readdirSync(d, {withFileTypes: true})) {
    const f = path.join(d, e.name)
    if (e.isDirectory()) walk(f)
    else if (/\.(html|css)$/.test(e.name)) {
      const s = fs.readFileSync(f, "utf8")
      if (/https?:\/\/(localhost|127\.0\.0\.1)/.test(s)) bad.push(f)
      if (/(?:href|src)="\/[^/]/.test(s) || /url\(\s*['"]?\/[^/]/.test(s)) bad.push(f + " (absolute path)")
    }
  }
})(OUT)

let files = 0, bytes = 0
;(function walk(d) { for (const e of fs.readdirSync(d, {withFileTypes: true})) { const f = path.join(d, e.name); if (e.isDirectory()) walk(f); else { files++; bytes += fs.statSync(f).size } } })(OUT)
console.log(`pages: ${nPages}  files: ${files}  bytes: ${bytes}`)
for (const x of warnings) console.log("WARN", x)
for (const x of bad) console.log("BAD", x)
if (bad.length) process.exit(1)
