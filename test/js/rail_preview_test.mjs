// LedgerUI.RailPreview: the preview cards of rail/1 in jsdom.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/rail_preview_test.mjs
import {test} from "node:test"
import assert from "node:assert/strict"
import {createRequire} from "node:module"
import {pathToFileURL, fileURLToPath} from "node:url"
import {dirname, join} from "node:path"

const here = dirname(fileURLToPath(import.meta.url))
const require = createRequire(import.meta.url)

let JSDOM
for (const p of [process.env.JSDOM_PATH, "jsdom"].filter(Boolean)) {
  try { ({JSDOM} = require(p)); break } catch (_) { /* try the next */ }
}
const skip = JSDOM ? false : "jsdom not found (run `npm install` or set JSDOM_PATH)"

let Hook, w
const docListeners = new Map()
let timers = []
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true})
  w = dom.window
  w.matchMedia = () => ({matches: false, addEventListener() {}, removeEventListener() {}})
  Object.assign(globalThis, {window: w, document: w.document})
  const add = w.document.addEventListener.bind(w.document)
  const remove = w.document.removeEventListener.bind(w.document)
  w.document.addEventListener = (t, f, ...r) => { (docListeners.get(t) || docListeners.set(t, new Set()).get(t)).add(f); add(t, f, ...r) }
  w.document.removeEventListener = (t, f, ...r) => { (docListeners.get(t) || new Set()).delete(f); remove(t, f, ...r) }
  // a fake clock for the 150ms delay
  const realSet = globalThis.setTimeout
  globalThis.setTimeout = (fn, ms) => { const t = {fn, ms, live: true}; timers.push(t); return t }
  globalThis.clearTimeout = (t) => { if (t) t.live = false }
  globalThis.__realSet = realSet
  Hook = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/rail_preview.js")))).default
}

const live = (t) => (docListeners.get(t) || new Set()).size
const pending = () => timers.filter((t) => t.live)
const flush = () => { const due = pending(); timers = []; due.forEach((t) => { t.live = false; t.fn() }) }

function mount(extra = "") {
  timers = []
  document.body.innerHTML = `
    <nav id="rail" data-lu-delay="150" ${extra}>
      <a id="a" href="/a" data-rail-item aria-describedby="pv-a">A</a>
      <a id="b" href="/b" data-rail-item aria-describedby="pv-b">B</a>
      <a id="c" href="/c" data-rail-item>C</a>
      <div id="pv-a" role="tooltip"><b>A</b></div>
      <div id="pv-b" role="tooltip"><b>B</b></div>
    </nav>`
  const el = document.getElementById("rail")
  const h = Object.assign(Object.create(Hook), {el})
  h.mounted()
  return {el, h}
}

const over = (el, from = null) => el.dispatchEvent(new w.MouseEvent("mouseover", {bubbles: true, relatedTarget: from}))
const out = (el, to = null) => el.dispatchEvent(new w.MouseEvent("mouseout", {bubbles: true, relatedTarget: to}))
const open = (id) => document.getElementById(id).hasAttribute("data-open")

test("opens after the delay of hover, not before", {skip}, () => {
  const {h} = mount()
  over(document.getElementById("a"))
  assert.equal(open("pv-a"), false)
  assert.equal(pending().length, 1)
  assert.equal(pending()[0].ms, 150)
  flush()
  assert.equal(open("pv-a"), true)
  h.destroyed()
})

test("data-lu-delay sets the delay", {skip}, () => {
  const {h, el} = mount()
  el.setAttribute("data-lu-delay", "400")
  over(document.getElementById("a"))
  assert.equal(pending()[0].ms, 400)
  h.destroyed()
})

test("focus opens it too", {skip}, () => {
  const {h} = mount()
  document.getElementById("b").dispatchEvent(new w.FocusEvent("focusin", {bubbles: true}))
  flush()
  assert.equal(open("pv-b"), true)
  h.destroyed()
})

test("moving to the next item swaps at once, without the enter animation", {skip}, () => {
  const {h} = mount()
  const animated = []
  for (const id of ["pv-a", "pv-b"]) document.getElementById(id).animate = () => animated.push(id)
  over(document.getElementById("a"))
  flush()
  assert.deepEqual(animated, ["pv-a"])
  over(document.getElementById("b"), document.getElementById("a"))
  assert.equal(pending().length, 0)
  assert.equal(open("pv-a"), false)
  assert.equal(open("pv-b"), true)
  assert.deepEqual(animated, ["pv-a"])
  h.destroyed()
})

test("an item without preview closes the open one", {skip}, () => {
  const {h} = mount()
  over(document.getElementById("a"))
  flush()
  over(document.getElementById("c"), document.getElementById("a"))
  assert.equal(open("pv-a"), false)
  h.destroyed()
})

test("leaving the item before the delay cancels it", {skip}, () => {
  const {h} = mount()
  over(document.getElementById("a"))
  out(document.getElementById("a"), document.body)
  assert.equal(pending().length, 0)
  flush()
  assert.equal(open("pv-a"), false)
  h.destroyed()
})

test("Esc closes it", {skip}, () => {
  const {h} = mount()
  over(document.getElementById("a"))
  flush()
  document.dispatchEvent(new w.KeyboardEvent("keydown", {key: "Escape", bubbles: true}))
  assert.equal(open("pv-a"), false)
  assert.equal(live("keydown"), 0)
  h.destroyed()
})

test("leaving the rail closes it, and so does the focus leaving it", {skip}, () => {
  const {h, el} = mount()
  over(document.getElementById("a"))
  flush()
  el.dispatchEvent(new w.MouseEvent("mouseleave"))
  assert.equal(open("pv-a"), false)
  document.getElementById("b").dispatchEvent(new w.FocusEvent("focusin", {bubbles: true}))
  flush()
  assert.equal(open("pv-b"), true)
  document.getElementById("b").dispatchEvent(new w.FocusEvent("focusout", {bubbles: true, relatedTarget: document.body}))
  assert.equal(open("pv-b"), false)
  h.destroyed()
})

test("no listener on document at rest; only while a card is open", {skip}, () => {
  const {h} = mount()
  assert.equal(live("keydown"), 0)
  over(document.getElementById("a"))
  flush()
  assert.equal(live("keydown"), 1)
  over(document.getElementById("b"), document.getElementById("a"))
  assert.equal(live("keydown"), 1)
  h.destroyed()
  assert.equal(live("keydown"), 0)
})

test("the card is placed beside the item inside the viewport", {skip}, () => {
  const {h} = mount()
  const a = document.getElementById("a")
  a.getBoundingClientRect = () => ({left: 12, right: 52, top: 100, bottom: 140, width: 40, height: 40})
  const card = document.getElementById("pv-a")
  Object.defineProperty(card, "offsetWidth", {value: 236})
  Object.defineProperty(card, "offsetHeight", {value: 170})
  over(a)
  flush()
  assert.equal(card.style.left, "64px")
  assert.ok(parseInt(card.style.top, 10) >= 8)
  assert.match(card.style.getPropertyValue("--ay"), /px$/)
  assert.equal(card.hasAttribute("data-side"), false)
  h.destroyed()
})

test("no room on the right: the card flips to the left", {skip}, () => {
  const {h} = mount()
  const a = document.getElementById("a")
  const vw = document.documentElement.clientWidth || w.innerWidth
  a.getBoundingClientRect = () => ({left: vw - 52, right: vw - 12, top: 100, bottom: 140, width: 40, height: 40})
  const card = document.getElementById("pv-a")
  Object.defineProperty(card, "offsetWidth", {value: 236})
  Object.defineProperty(card, "offsetHeight", {value: 170})
  over(a)
  flush()
  assert.equal(card.getAttribute("data-side"), "left")
  assert.equal(card.style.left, `${vw - 52 - 12 - 236}px`)
  h.destroyed()
})

test("a patch that drops the client attributes gets them back (updated)", {skip}, () => {
  const {h} = mount()
  over(document.getElementById("a"))
  flush()
  document.getElementById("pv-a").removeAttribute("data-open")
  h.updated()
  assert.equal(open("pv-a"), true)
  h.destroyed()
})

test("destroyed clears the timer, the card and every listener", {skip}, () => {
  const {h, el} = mount()
  over(document.getElementById("a"))
  assert.equal(pending().length, 1)
  h.destroyed()
  assert.equal(pending().length, 0)
  over(document.getElementById("b"))
  assert.equal(pending().length, 0)
  const {h: h2} = mount()
  over(document.getElementById("a"))
  flush()
  h2.destroyed()
  assert.equal(open("pv-a"), false)
  assert.equal(live("keydown"), 0)
  el.dispatchEvent(new w.MouseEvent("mouseleave"))
})
