// Treeview keyboard (APG): arrows, Home/End, parent/first child, type-ahead; Enter on a leaf (#115).
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/treeview_keys_test.mjs
import {test} from "node:test"
import assert from "node:assert/strict"
import {createRequire} from "node:module"
import {join, dirname} from "node:path"
import {fileURLToPath, pathToFileURL} from "node:url"

const here = dirname(fileURLToPath(import.meta.url))
const require = createRequire(import.meta.url)

let JSDOM
for (const p of [process.env.JSDOM_PATH, "jsdom"].filter(Boolean)) {
  try { ({JSDOM} = require(p)); break } catch (_) { /* try the next */ }
}
const skip = JSDOM ? false : "jsdom not found (set JSDOM_PATH)"

let tree
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/"})
  const w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, MutationObserver: w.MutationObserver, Event: w.Event, KeyboardEvent: w.KeyboardEvent, CSS: {escape: (s) => s}})
  tree = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/treeview.js")))).default
}

const chev = (open) => `<span data-part="tree-chevron"><svg data-icon="chevron-${open ? "down" : "right"}"></svg></span>`
const branch = (id, label, open, kids) =>
  `<div id="${id}" data-part="tree-item" role="treeitem" tabindex="-1" aria-expanded="${open}">${chev(open)}${label}<span data-part="tree-count">9</span></div>` +
  `<div data-part="tree-children" role="group"${open ? "" : " hidden"}>${kids}</div>`
const leaf = (id, label) => `<div id="${id}" data-part="tree-item" role="treeitem" tabindex="-1"><span data-part="tree-spacer"></span>${label}</div>`

function mount() {
  document.body.innerHTML =
    '<div id="tree">' +
    branch("a", "Pasta A", true, leaf("a1", "Arquivo 1") + leaf("a2", "Arquivo 2")) +
    branch("b", "Pasta B", false, leaf("b1", "Arquivo 3")) +
    leaf("p", "Projetos") + leaf("q", "Quadro") +
    "</div>"
  const el = document.getElementById("tree")
  const h = Object.assign(Object.create(tree), {el, pushEvent() {}, pushEventTo() {}})
  h.mounted()
  const press = (id, key, init = {}) => {
    const row = document.getElementById(id)
    row.focus()
    const ev = new window.KeyboardEvent("keydown", {key, bubbles: true, cancelable: true, ...init})
    row.dispatchEvent(ev)
    return ev
  }
  return {h, el, press, active: () => document.activeElement.id}
}

test("ArrowLeft on a leaf goes to the parent; on a top-level leaf nothing moves", {skip}, () => {
  const t = mount()
  t.press("a1", "ArrowLeft")
  assert.equal(t.active(), "a")
  t.press("p", "ArrowLeft")
  assert.equal(t.active(), "p")
  t.h.destroyed()
})

test("ArrowLeft on an open branch closes it; on a closed branch (nested) goes to the parent", {skip}, () => {
  const t = mount()
  t.press("a", "ArrowLeft")
  assert.equal(document.getElementById("a").getAttribute("aria-expanded"), "false")
  t.press("a", "ArrowLeft") // closed top-level: stays
  assert.equal(t.active(), "a")
  t.h.destroyed()
})

test("ArrowRight opens a closed branch, then goes to its first child", {skip}, () => {
  const t = mount()
  t.press("b", "ArrowRight")
  assert.equal(document.getElementById("b").getAttribute("aria-expanded"), "true")
  assert.equal(t.active(), "b")
  t.press("b", "ArrowRight")
  assert.equal(t.active(), "b1")
  t.press("a", "ArrowRight")
  assert.equal(t.active(), "a1")
  t.press("p", "ArrowRight") // a leaf: nothing
  assert.equal(t.active(), "p")
  t.h.destroyed()
})

test("Home and End go to the first and the last visible row", {skip}, () => {
  const t = mount()
  t.press("a2", "End")
  assert.equal(t.active(), "q")
  t.press("q", "Home")
  assert.equal(t.active(), "a")
  // b is closed: b1 is not visible, End must not land on it
  t.press("a", "End")
  assert.equal(t.active(), "q")
  t.h.destroyed()
})

test("type-ahead: a letter goes to the next row that starts with it; the same letter again cycles, wrapping", {skip}, () => {
  const t = mount()
  t.press("a", "p")
  assert.equal(t.active(), "b", "Pasta B")
  t.press("b", "p")
  assert.equal(t.active(), "p", "Projetos")
  t.press("p", "p")
  assert.equal(t.active(), "a", "wraps to Pasta A")
  t.h.destroyed()
})

test("type-ahead: the buffer is cleared after a pause", {skip}, async () => {
  const t = mount()
  t.press("a", "p")
  await new Promise((r) => setTimeout(r, 600))
  t.press("b", "q")
  assert.equal(t.active(), "q")
  t.h.destroyed()
})

test("type-ahead: a quick sequence builds a prefix; the count text is not part of the label", {skip}, () => {
  const t = mount()
  t.press("a", "p")
  t.press("p", "r")
  assert.equal(t.active(), "p", "'pr' still matches Projetos")
  t.press("p", "x")
  assert.equal(t.active(), "p", "no match: focus stays")
  t.h.destroyed()
})

test("type-ahead ignores shortcuts with Ctrl/Meta/Alt", {skip}, () => {
  const t = mount()
  t.press("a", "p", {ctrlKey: true})
  assert.equal(t.active(), "a")
  t.h.destroyed()
})

test("Enter on a leaf does not touch expansion attributes and selects it", {skip}, () => {
  const t = mount()
  const sent = []
  t.h.emit = (name, row) => sent.push([name, row.id])
  t.press("a1", "Enter")
  const r = document.getElementById("a1")
  assert.equal(r.hasAttribute("aria-expanded"), false)
  assert.equal(r.getAttribute("aria-selected"), "true")
  assert.deepEqual(sent, [["onSelect", "a1"]])
  t.h.destroyed()
})
