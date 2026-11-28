// Dropdown row marking (data-row-mark) in a jsdom document.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/row_mark_test.mjs
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
const skip = JSDOM ? false : (process.env.CI === "true" || process.env.CI === "1" ? (() => { throw new Error("jsdom not found and CI is set: run `npm install` (or set JSDOM_PATH)") })() : "jsdom not found (run `npm install` or set JSDOM_PATH)")

let Dropdown
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/"})
  Object.assign(globalThis, {window: dom.window, document: dom.window.document, CSS: {escape: (s) => s}, cancelAnimationFrame() {}})
  const dir = mkdtempSync(join(tmpdir(), "lu-rowmark-"))
  for (const n of ["dropdown"])
    writeFileSync(join(dir, `${n}.js`), readFileSync(join(here, `../../priv/static/ledger_ui/hooks/${n}.js`), "utf8"))
  // the hooks are ES modules: .js files in a temp dir need the .mjs extension to import each other
  const fix = (n) => writeFileSync(join(dir, `${n}.mjs`), readFileSync(join(dir, `${n}.js`), "utf8").replace('"./dropdown.js"', '"./dropdown.mjs"'))
  fix("dropdown")
  Dropdown = (await import(pathToFileURL(join(dir, "dropdown.mjs")))).default
}

function build(attr) {
  document.body.innerHTML = `<table><tbody><tr id="row"><td>
    <span id="dd" ${attr}><button>x</button><span data-part="action-menu-panel"><div data-part="pop"></div></span></span>
  </td></tr></tbody></table>`
  return [document.getElementById("row"), document.getElementById("dd")]
}

// open/close without the positioning machinery: only the marking is under test
function instance(hook, el) {
  return Object.assign(Object.create(hook), {
    el, isOpen: false, trigger: el.querySelector("button"), panel: el.firstElementChild.nextElementSibling,
    pop: el.querySelector("[data-part=pop]"), demo: false,
    show() {}, reposition() {}, enter() {}, hide() {}, closeSubs() {}, focusItem() {},
    onDown() {}, onScroll() {},
    liveSocket: {execJS() {}},
  })
}

test("data-row-mark: opening marks the row, closing unmarks it", {skip}, () => {
  const [row, el] = build("data-row-mark")
  row.style.background = "red"
  const h = instance(Dropdown, el)
  h.open(false)
  assert.equal(row.hasAttribute("data-am-open"), true)
  assert.notEqual(row.style.background, "red")
  h.close(false)
  assert.equal(row.hasAttribute("data-am-open"), false)
  assert.equal(row.style.background, "red")
})

test("without data-row-mark or rowMark the row is left alone", {skip}, () => {
  const [row, el] = build("")
  const h = instance(Dropdown, el)
  h.open(false)
  assert.equal(h.isOpen, true)
  assert.equal(row.hasAttribute("data-am-open"), false)
  assert.equal(row.style.background, "")
  h.close(false)
  assert.equal(row.hasAttribute("data-am-open"), false)
})
