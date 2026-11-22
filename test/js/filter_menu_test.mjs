// FilterMenu hook: the Apply button's text follows data-lu-apply-label (the locale).
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/filter_menu_test.mjs
import {test} from "node:test"
import assert from "node:assert/strict"
import {createRequire} from "node:module"
import {readFileSync, writeFileSync, mkdtempSync} from "node:fs"
import {tmpdir} from "node:os"
import {join, dirname} from "node:path"
import {fileURLToPath, pathToFileURL} from "node:url"

const here = dirname(fileURLToPath(import.meta.url))
const require = createRequire(import.meta.url)

let JSDOM
for (const p of [process.env.JSDOM_PATH, "jsdom"].filter(Boolean)) {
  try { ({JSDOM} = require(p)); break } catch (_) { /* try the next */ }
}
const skip = JSDOM ? false : "jsdom not found (set JSDOM_PATH)"

let FilterMenu
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/"})
  Object.assign(globalThis, {window: dom.window, document: dom.window.document})
  const dir = mkdtempSync(join(tmpdir(), "lu-filter-"))
  writeFileSync(join(dir, "filter_menu.mjs"), readFileSync(join(here, "../../priv/static/ledger_ui/hooks/filter_menu.js"), "utf8"))
  FilterMenu = (await import(pathToFileURL(join(dir, "filter_menu.mjs")))).default
}

function mount(attrs) {
  document.body.innerHTML = `<span id="fm" ${attrs}>
    <button data-lu-trigger>Filtros</button><span data-lu-count hidden>0</span>
    <span data-part="filter-popup" hidden><div data-lu-group="s[]" data-lu-type="multiple">
      <input type="checkbox" name="s[]" value="a" data-lu-count="2" checked>
    </div><button data-lu-clear>Limpar</button><button data-lu-apply>Aplicar</button></span></span>`
  const el = document.getElementById("fm")
  const hook = Object.assign({el, pushEvent() {}, pushEventTo() {}}, FilterMenu)
  hook.mounted()
  return el
}

test("Apply keeps the locale's label once refreshed", {skip}, () => {
  const el = mount('data-lu-locale="pt_BR" data-lu-apply-label="Aplicar" data-lu-results-label="resultados"')
  assert.match(el.querySelector("[data-lu-apply]").textContent, /^Aplicar · 2$/)
})

test("Apply falls back to English with no label", {skip}, () => {
  const el = mount("")
  assert.match(el.querySelector("[data-lu-apply]").textContent, /^Apply · 2$/)
})
