// LedgerUI.PixelCard (pixel_card.js): the 560 nodes of the matrix are created on demand.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/pixel_card_test.mjs
// jsdom is not a dependency of the package: the tests are skipped when it cannot be found.
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

let hook
let w
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "http://localhost/"})
  w = dom.window
  Object.assign(globalThis, {window: w, document: w.document})
  const dir = mkdtempSync(join(tmpdir(), "lu-px-"))
  writeFileSync(join(dir, "pixel_card.mjs"), readFileSync(join(here, "../../priv/static/ledger_ui/hooks/pixel_card.js"), "utf8"))
  hook = (await import(pathToFileURL(join(dir, "pixel_card.mjs")))).default
}

let seq = 0
function mount(attrs = {}) {
  document.body.innerHTML = ""
  const el = document.createElement("button")
  el.id = "px" + ++seq
  el.dataset.luGridClass = "GRID"
  el.dataset.luCellClass = "CELL"
  for (const [k, v] of Object.entries(attrs)) el.setAttribute(k, v)
  el.innerHTML = "<b>Title</b>"
  document.body.append(el)
  const h = Object.assign(Object.create(hook), {el})
  h.mounted()
  return {h, el, grid: () => el.querySelector('[data-part="pixel-card-grid"]')}
}

test("at rest nothing is drawn", {skip}, () => {
  const t = mount()
  assert.equal(t.grid(), null)
  assert.equal(t.el.querySelectorAll("i").length, 0)
})

test("the first pointerenter draws 28x20 cells with the server's classes, once", {skip}, () => {
  const t = mount()
  t.el.dispatchEvent(new w.Event("pointerenter"))
  const grid = t.grid()
  assert.ok(grid)
  assert.equal(grid.className, "GRID")
  assert.equal(grid.getAttribute("aria-hidden"), "true")
  assert.equal(grid.querySelectorAll("i").length, 560)
  assert.equal(grid.querySelector("i").className, "CELL")
  assert.match(grid.querySelector("i").getAttribute("style"), /--o1:.*--o2:.*--o3:/)
  assert.equal(t.el.firstChild, grid)
  t.el.dispatchEvent(new w.Event("pointerenter"))
  assert.equal(t.el.querySelectorAll('[data-part="pixel-card-grid"]').length, 1)
})

test("keyboard focus draws it too", {skip}, () => {
  const t = mount()
  t.el.dispatchEvent(new w.FocusEvent("focusin", {bubbles: true}))
  assert.equal(t.grid().querySelectorAll("i").length, 560)
})

test("lit and loop draw it at once", {skip}, () => {
  assert.equal(mount({"data-lit": ""}).grid().querySelectorAll("i").length, 560)
  assert.equal(mount({"data-lu-loop": ""}).grid().querySelectorAll("i").length, 560)
})

test("a patch that dropped the matrix: drawn again only while it is on show", {skip}, () => {
  const t = mount()
  t.el.dispatchEvent(new w.Event("pointerenter"))
  t.grid().remove()
  t.h.updated()
  assert.equal(t.grid(), null, "not hovered: stays undrawn until the next pointerenter")
  t.el.dispatchEvent(new w.Event("pointerenter"))
  assert.ok(t.grid())

  const lit = mount({"data-lit": ""})
  lit.grid().remove()
  lit.h.updated()
  assert.ok(lit.grid(), "lit: drawn again")
})

test("lit turned on by the server draws it", {skip}, () => {
  const t = mount()
  t.el.setAttribute("data-lit", "")
  t.h.updated()
  assert.ok(t.grid())
})

test("destroyed removes the listeners", {skip}, () => {
  const t = mount()
  t.h.destroyed()
  t.el.dispatchEvent(new w.Event("pointerenter"))
  t.el.dispatchEvent(new w.FocusEvent("focusin", {bubbles: true}))
  assert.equal(t.grid(), null)
})
