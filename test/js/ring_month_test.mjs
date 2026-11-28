// LedgerUI.RingMonth: roving tabindex and arrows over the days and the series, focus lights them (`data-active`),
// Esc goes back to the summary, and the rows of a linked list (`[data-lu-ring][data-lu-series]`) light the series.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/ring_month_test.mjs
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

let hook
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true})
  const w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, Event: w.Event, MutationObserver: w.MutationObserver})
  globalThis.CSS = w.CSS || {escape: (s) => s}
  hook = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/ring_month.js")))).default
}

const day = (n) => `<g data-tgt="day" data-day="${n}"><line data-part="ring-month-hit"/></g>`
const futureDay = `<g data-tgt="day" data-day="9"></g>` // no hit: not a stop
const series = (id, n) => `<g data-tgt="series" data-n="s${n}" data-id="${id}"><path data-part="ring-month-arc"/></g>`

function mount() {
  document.body.innerHTML = `<div id="r"><svg>${day(1)}${day(2)}${day(3)}${futureDay}${series("direct", 1)}${series("cd", 2)}</svg></div>
    <ol data-lu-ring="r"><li data-lu-series="direct" tabindex="0">Direta</li><li data-lu-series="cd" tabindex="0">CD</li></ol>
    <ol data-lu-ring="other"><li data-lu-series="direct" tabindex="0">Nao</li></ol>`
  const el = document.getElementById("r")
  const h = Object.assign(Object.create(hook), {el})
  h.mounted()
  return {el, h}
}

const key = (target, k) => target.dispatchEvent(new window.KeyboardEvent("keydown", {key: k, bubbles: true}))
const fire = (target, type) => target.dispatchEvent(new window.Event(type, {bubbles: type !== "pointerenter" && type !== "pointerleave"}))
const g = (el, sel) => el.querySelector(sel)

test("roving tabindex: one tab stop for the days (those with a hit) and one for the series", {skip}, () => {
  const {el} = mount()
  const days = [...el.querySelectorAll('[data-tgt="day"]')]
  assert.deepEqual(days.map((d) => d.getAttribute("tabindex")), ["0", "-1", "-1", null])
  assert.deepEqual([...el.querySelectorAll('[data-tgt="series"]')].map((d) => d.getAttribute("tabindex")), ["0", "-1"])
})

test("arrows walk the days, Home and End jump, focus lights the day", {skip}, () => {
  const {el} = mount()
  const d1 = g(el, '[data-day="1"]'), d2 = g(el, '[data-day="2"]'), d3 = g(el, '[data-day="3"]')
  d1.focus(); fire(d1, "focusin")
  assert.equal(d1.hasAttribute("data-active"), true)
  assert.equal(el.getAttribute("data-active-day"), "1")
  key(d1, "ArrowRight")
  assert.equal(document.activeElement, d2)
  assert.equal(d2.getAttribute("tabindex"), "0")
  assert.equal(d1.getAttribute("tabindex"), "-1")
  fire(d2, "focusin")
  assert.equal(el.getAttribute("data-active-day"), "2")
  assert.equal(d1.hasAttribute("data-active"), false)
  key(d2, "ArrowDown"); assert.equal(document.activeElement, d3)
  key(d3, "ArrowRight"); assert.equal(document.activeElement, d1, "wraps over the days with data")
  key(d1, "ArrowLeft"); assert.equal(document.activeElement, d3)
  key(d3, "Home"); assert.equal(document.activeElement, d1)
  key(d1, "End"); assert.equal(document.activeElement, d3)
})

test("focus on a series arc lights it and the linked row", {skip}, () => {
  const {el} = mount()
  const s = g(el, '[data-id="direct"]')
  s.focus(); fire(s, "focusin")
  assert.equal(s.hasAttribute("data-active"), true)
  assert.equal(el.getAttribute("data-active-series"), "direct")
  assert.equal(document.querySelector('[data-lu-ring="r"] [data-lu-series="direct"]').hasAttribute("data-active"), true)
  assert.equal(document.querySelector('[data-lu-ring="r"] [data-lu-series="cd"]').hasAttribute("data-active"), false)
  key(s, "ArrowRight")
  assert.equal(document.activeElement, g(el, '[data-id="cd"]'))
})

test("Esc goes back to the summary", {skip}, () => {
  const {el} = mount()
  const d1 = g(el, '[data-day="1"]')
  d1.focus(); fire(d1, "focusin")
  key(d1, "Escape")
  assert.equal(el.querySelector("[data-active]"), null)
  assert.equal(el.hasAttribute("data-active-day"), false)
})

test("a row of the linked list lights its series by pointer and by focus, and clears on leave and blur", {skip}, () => {
  const {el} = mount()
  const row = document.querySelector('[data-lu-ring="r"] [data-lu-series="cd"]')
  fire(row, "pointerenter")
  assert.equal(g(el, '[data-id="cd"]').hasAttribute("data-active"), true)
  assert.equal(row.hasAttribute("data-active"), true)
  assert.equal(el.getAttribute("data-active-series"), "cd")
  fire(row, "pointerleave")
  assert.equal(el.querySelector("[data-active]"), null)
  assert.equal(row.hasAttribute("data-active"), false)
  fire(row, "focus")
  assert.equal(g(el, '[data-id="cd"]').hasAttribute("data-active"), true)
  fire(row, "blur")
  assert.equal(g(el, '[data-id="cd"]').hasAttribute("data-active"), false)
})

test("rows of another ring are not linked", {skip}, () => {
  const {el} = mount()
  fire(document.querySelector('[data-lu-ring="other"] [data-lu-series]'), "pointerenter")
  assert.equal(el.querySelector("[data-active]"), null)
})

test("updated() binds new rows of the list", {skip}, () => {
  const {el, h} = mount()
  const ol = document.querySelector('[data-lu-ring="r"]')
  ol.innerHTML = `<li data-lu-series="direct" tabindex="0">Nova</li>`
  h.updated()
  fire(ol.firstChild, "pointerenter")
  assert.equal(g(el, '[data-id="direct"]').hasAttribute("data-active"), true)
})

test("destroyed() removes the listeners and the state", {skip}, () => {
  const {el, h} = mount()
  const row = document.querySelector('[data-lu-ring="r"] [data-lu-series="direct"]')
  fire(row, "pointerenter")
  h.destroyed()
  assert.equal(el.querySelector("[data-active]"), null)
  fire(row, "pointerenter")
  assert.equal(el.querySelector("[data-active]"), null)
  const d1 = g(el, '[data-day="1"]')
  fire(d1, "focusin")
  assert.equal(el.querySelector("[data-active]"), null)
})
