// The select hook and the search it tells the server about (#51): clearing the text sends on_search with an empty query.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/select_search_test.mjs
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

let select
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true})
  const w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, MutationObserver: w.MutationObserver, Event: w.Event, CSS: {escape: (s) => s}})
  globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} }
  w.Element.prototype.scrollIntoView = function () {}
  const dir = mkdtempSync(join(tmpdir(), "lu-select-"))
  writeFileSync(join(dir, "select.mjs"), readFileSync(join(here, "../../priv/static/ledger_ui/hooks/select.js"), "utf8"))
  select = (await import(pathToFileURL(join(dir, "select.mjs")))).default
}

const flush = () => new Promise((r) => setTimeout(r, 0))
const CLS = {chip: "chip", remove: "rm", icon: "ic", right: "rt", ck: "ck", more: "mr"}

function mount({multiple = true, search = true, target} = {}) {
  document.body.innerHTML = ""
  const el = document.createElement("div")
  el.id = "sel1"
  el.dataset.luCls = JSON.stringify(CLS)
  el.dataset.luDebounce = "20"
  if (multiple) el.dataset.luMultiple = ""
  if (search) el.dataset.luOnSearch = "find"
  if (target) el.dataset.luTarget = target
  el.dataset.luValue = "[]"
  el.innerHTML =
    `<span data-part="select-control"><span data-part="select-value" data-ph>Pick</span><input data-lu-q hidden><svg></svg></span>` +
    `<div data-part="select-panel" hidden><div role="listbox" data-lu-list>` +
    [1, 2, 3].map((i) => `<button type="button" data-part="listbox-option" data-lu-value="o${i}" aria-selected="false">Option ${i}</button>`).join("") +
    `</div><div data-lu-empty hidden></div></div><select name="f[v]" hidden ${multiple ? "multiple" : ""}></select>`
  document.body.appendChild(el)
  const pushed = []
  const h = Object.assign(Object.create(select), {
    el,
    pushEvent: (ev, p) => pushed.push(["pushEvent", ev, p]),
    pushEventTo: (t, ev, p) => pushed.push(["pushEventTo", t, ev, p]),
  })
  h.mounted()
  return {el, h, pushed}
}

const q = (el) => el.querySelector("input[data-lu-q]")
const type = (el, text) => { q(el).value = text; q(el).dispatchEvent(new window.Event("input", {bubbles: true})) }
const row = (el, v) => el.querySelector(`[data-lu-value="${v}"]`)

test("multiple: choosing after a search tells the server once, with an empty query", {skip}, async () => {
  const {el, h, pushed} = mount()
  h.setOpen(true)
  type(el, "sau")
  await new Promise((r) => setTimeout(r, 40))
  assert.deepEqual(pushed, [["pushEvent", "find", {id: "sel1", query: "sau"}]])
  pushed.length = 0
  h.choose(row(el, "o2"))
  assert.deepEqual(pushed, [["pushEvent", "find", {id: "sel1", query: ""}]])
  assert.equal(q(el).value, "")
  await flush()
  assert.equal(pushed.length, 1)
})

test("single: choosing after a search (the panel closes) sends the empty query once", {skip}, () => {
  const {el, h, pushed} = mount({multiple: false})
  h.setOpen(true)
  type(el, "sau")
  pushed.length = 0
  h.choose(row(el, "o1"))
  assert.deepEqual(pushed, [["pushEvent", "find", {id: "sel1", query: ""}]])
  h.setOpen(true)
  assert.equal(pushed.length, 1, "reopening with empty text sends nothing more")
})

test("the empty query goes to the same target as the search", {skip}, () => {
  const {el, h, pushed} = mount({target: "#box"})
  h.setOpen(true)
  type(el, "sau")
  h.choose(row(el, "o1"))
  assert.deepEqual(pushed, [["pushEventTo", "#box", "find", {id: "sel1", query: ""}]])
})

test("empty text: choosing, closing and Esc send nothing", {skip}, () => {
  const {el, h, pushed} = mount()
  h.setOpen(true)
  h.choose(row(el, "o1"))
  h.key({key: "Escape", target: el, preventDefault() {}, stopPropagation() {}})
  h.setOpen(true)
  h.setOpen(false)
  assert.deepEqual(pushed, [])
})

test("without on_search nothing is sent", {skip}, () => {
  const {el, h, pushed} = mount({search: false})
  h.setOpen(true)
  type(el, "sau")
  h.choose(row(el, "o1"))
  h.setOpen(false)
  assert.deepEqual(pushed, [])
})

test("a debounced search still pending is cancelled by the empty query", {skip}, async () => {
  const {el, h, pushed} = mount()
  h.setOpen(true)
  type(el, "sau")
  h.choose(row(el, "o1"))
  await new Promise((r) => setTimeout(r, 50))
  assert.deepEqual(pushed, [["pushEvent", "find", {id: "sel1", query: ""}]], "the old search never leaves")
})

test("closing the panel (Esc, outside click) with text tells the server too", {skip}, () => {
  const {el, h, pushed} = mount()
  h.setOpen(true)
  type(el, "sau")
  pushed.length = 0
  h.setOpen(false)
  assert.deepEqual(pushed, [["pushEvent", "find", {id: "sel1", query: ""}]])
})
