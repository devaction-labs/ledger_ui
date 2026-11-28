// #129 with the legacy `dom: {onBeforeElUpdated}` callback installed: number_input, range and color_picker keep the
// person's value for several patches in a row (it used to come back on the second one), and the server wins when it changes.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/legacy_dom_callback_test.mjs
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

const hooks = {}
let DOM
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true})
  const w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, Event: w.Event, CustomEvent: w.CustomEvent, HTMLElement: w.HTMLElement, CSS: {escape: (s) => s}})
  for (const n of ["number_input", "range", "color_picker"])
    hooks[n] = (await import(pathToFileURL(join(here, `../../priv/static/ledger_ui/hooks/${n}.js`)))).default
  DOM = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/base.js")))).DOM
}

const mountHook = (hook, html, attrs = {}) => {
  document.body.innerHTML = `<div id="root">${html}</div>`
  const el = document.getElementById("root")
  for (const [k, v] of Object.entries(attrs)) el.setAttribute(k, v)
  const h = Object.assign(Object.create(hook), {el, pushEvent() {}, pushEventTo() {}, liveSocket: {execJS() {}}})
  h.mounted()
  return {el, h}
}
// A patch as LiveView does it with the legacy callback: `onBeforeElUpdated` for each control, the morph, `updated`,
// then the microtask in which the old code emitted `lu:sync`.
const patch = async (ctx, html, control) => {
  const from = ctx.el.querySelector(control)
  DOM.onBeforeElUpdated(from, from.cloneNode(true))
  ctx.el.innerHTML = html
  // morphdom keeps the node it morphs (and with it the event target of `lu:sync`): put it back with the server's value
  const fresh = ctx.el.querySelector(control)
  from.value = fresh.value
  fresh.replaceWith(from)
  ctx.h.updated()
  await Promise.resolve()
}

const numHtml = (v) =>
  `<input type="hidden" name="n" value="${v}" data-num-value><button type="button" data-part="number-minus"></button>` +
  `<span data-part="number-value">${v}</span><button type="button" data-part="number-plus"></button>`
const CFG = JSON.stringify({dec: ".", thou: "", step: 1, min: null, max: null, decimals: null, maxDecimals: null})
const numState = (c) => [c.el.querySelector("[data-num-value]").value, c.el.querySelector("[data-part=number-value]").textContent]

test("number_input with the legacy callback: the stepped value survives 4 patches", {skip}, async () => {
  const c = mountHook(hooks.number_input, numHtml(3), {"data-lu-config": CFG})
  c.el.querySelector("[data-part=number-plus]").click()
  c.el.querySelector("[data-part=number-plus]").click()
  for (let i = 0; i < 4; i++) {
    await patch(c, numHtml(3), "[data-num-value]")
    assert.deepEqual(numState(c), ["5", "5"], `patch ${i + 1}`)
  }
  await patch(c, numHtml(10), "[data-num-value]")
  assert.deepEqual(numState(c), ["10", "10"], "the server wins when it changes")
  await patch(c, numHtml(10), "[data-num-value]")
  assert.deepEqual(numState(c), ["10", "10"])
})

const rangeHtml = (v) =>
  `<input type="hidden" name="r" value="${v}" data-range-value><span data-part="range-track"></span><span data-part="range-fill"></span>` +
  `<span data-part="range-thumb" aria-valuenow="${v}"></span>`
const RCFG = JSON.stringify({min: 0, max: 100, step: 1, pair: false, vertical: false, disabled: false, format: "%{value}", marks: [], decrease: "-", increase: "+"})
const rangeState = (c) => [c.el.querySelector("[data-range-value]").value, c.el.querySelector("[data-part=range-thumb]").getAttribute("aria-valuenow")]

test("range with the legacy callback: the keyboard's value survives 4 patches", {skip}, async () => {
  const c = mountHook(hooks.range, rangeHtml(54), {"data-lu-config": RCFG})
  for (let i = 0; i < 5; i++)
    c.el.querySelector("[data-part=range-thumb]").dispatchEvent(new window.KeyboardEvent("keydown", {key: "ArrowRight", bubbles: true}))
  for (let i = 0; i < 4; i++) {
    await patch(c, rangeHtml(54), "[data-range-value]")
    assert.deepEqual(rangeState(c), ["59", "59"], `patch ${i + 1}`)
  }
  await patch(c, rangeHtml(20), "[data-range-value]")
  assert.deepEqual(rangeState(c), ["20", "20"], "the server wins when it changes")
})

const SW = ["#1F9282", "#4C3FE0", "#6A4FD8"]
const colorHtml = (v) =>
  `<input type="hidden" name="cp" value="${v}" data-color-value>` +
  SW.map((c) => `<button type="button" data-part="color-picker-swatch" aria-label="${c}" aria-pressed="${c === v}"></button>`).join("")
const colorState = (c) => [c.el.querySelector("[data-color-value]").value, c.el.querySelector("[aria-pressed=true]")?.getAttribute("aria-label")]

test("color_picker with the legacy callback: the chosen swatch survives 4 patches", {skip}, async () => {
  const c = mountHook(hooks.color_picker, colorHtml("#1F9282"))
  c.el.querySelectorAll("[data-part=color-picker-swatch]")[2].click()
  for (let i = 0; i < 4; i++) {
    await patch(c, colorHtml("#1F9282"), "[data-color-value]")
    assert.deepEqual(colorState(c), ["#6A4FD8", "#6A4FD8"], `patch ${i + 1}`)
  }
  await patch(c, colorHtml("#4C3FE0"), "[data-color-value]")
  assert.deepEqual(colorState(c), ["#4C3FE0", "#4C3FE0"], "the server wins when it changes")
})
