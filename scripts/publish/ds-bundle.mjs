// Builds components/bundle.js for the Design System export: ONE classic script (IIFE) that assigns window.LedgerUI and embeds
// phoenix + phoenix_live_view + the hooks of priv/static/ledger_ui.esm.js + scripts/publish/ledger-static.src.js.
//   node ds-bundle.mjs <esbuild_module_dir> <repo> <deps_dir> <build_dir> <out_file>
import fs from "node:fs"
import path from "node:path"
import {createRequire} from "node:module"

const [ESB, REPO, DEPS, BUILD, OUT] = process.argv.slice(2)
const esbuild = createRequire(path.join(ESB, "x.js"))("esbuild")
const version = JSON.parse(fs.readFileSync(path.join(REPO, "package.json"), "utf8")).version
const q = JSON.stringify
fs.mkdirSync(BUILD, {recursive: true})

// 1. globals the static runtime reads (window.Phoenix / window.LiveView) -- evaluated before ledger-static
fs.writeFileSync(path.join(BUILD, "ds-globals.js"), `
import * as Phoenix from ${q(path.join(DEPS, "phoenix/priv/static/phoenix.mjs"))}
import * as LiveView from ${q(path.join(DEPS, "phoenix_live_view/priv/static/phoenix_live_view.esm.js"))}
window.Phoenix = Phoenix
window.LiveView = LiveView
window.LU_DEFER = true                  // ledger-static must not start by itself: the page may not exist yet
window.luStaticHref = () => null        // navigate/patch commands do nothing inside a preview frame
`)
// 2. the entry
fs.writeFileSync(path.join(BUILD, "ds-entry.js"), `
import "./ds-globals.js"
import {Hooks, DOM} from ${q(path.join(REPO, "priv/static/ledger_ui.esm.js"))}
import {start, liveSocket} from ${q(path.join(REPO, "scripts/publish/ledger-static.src.js"))}

const init = (scope) => start(scope || document)
function boot() {
  init()
  let t = 0   // previews may be inserted after DOMContentLoaded: mount what shows up later (start() is idempotent)
  new MutationObserver(() => { clearTimeout(t); t = setTimeout(init, 30) }).observe(document.documentElement, {childList: true, subtree: true})
}
window.LedgerUI = {version: ${q(version)}, Hooks, DOM, liveSocket, init}
if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", boot)
else boot()
`)

const resolveStatic = {
  name: "ledger-static-esm",   // ledger-static.src.js imports "./ledger_ui/ledger_ui.esm.js" (its place in the vitrine export)
  setup(b) {
    b.onResolve({filter: /^\.\/ledger_ui\/ledger_ui\.esm\.js$/}, () => ({path: path.join(REPO, "priv/static/ledger_ui.esm.js")}))
  },
}
const r = await esbuild.build({
  entryPoints: [path.join(BUILD, "ds-entry.js")], bundle: true, format: "iife", platform: "browser", target: "es2020",
  minify: true, legalComments: "none", write: false, plugins: [resolveStatic], logLevel: "warning",
})
let js = r.outputFiles[0].text
// consumers inline the file: the literals "<\/script" and "<!--" must not appear (inside strings, regexes: same value)
js = js.replaceAll("</script", "\\x3C/script").replaceAll("<!--", "\\x3C!--")
js = `/* @ds-bundle: {"format":4,"namespace":"LedgerUI","components":[]} */\n` + js
fs.mkdirSync(path.dirname(OUT), {recursive: true})
fs.writeFileSync(OUT, js)
console.log(`bundle.js: ${js.length} bytes`)
