// range and color_picker listen to `pointermove`/`pointerup` on `window` only while a drag lasts, and the otp hook
// binds its boxes again only when the patch gave it other boxes (#131).
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/drag_listeners_test.mjs
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
const live = new Map() // "type" -> count of window listeners now
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true})
  const w = dom.window
  const add = w.addEventListener.bind(w), remove = w.removeEventListener.bind(w)
  const seen = new Set()
  w.addEventListener = (t, fn, o) => { const k = t + ":" + (fn.__id ||= Math.random()); if (!seen.has(k)) { seen.add(k); live.set(t, (live.get(t) || 0) + 1) } return add(t, fn, o) }
  w.removeEventListener = (t, fn, o) => { const k = t + ":" + fn.__id; if (seen.delete(k)) live.set(t, live.get(t) - 1); return remove(t, fn, o) }
  Object.assign(globalThis, {window: w, document: w.document, Event: w.Event, HTMLElement: w.HTMLElement})
  for (const n of ["range", "color_picker", "otp"])
    hooks[n] = (await import(pathToFileURL(join(here, `../../priv/static/ledger_ui/hooks/${n}.js`)))).default
}

const mountHook = (hook, html, attrs = {}) => {
  document.body.innerHTML = `<div id="root">${html}</div>`
  const el = document.getElementById("root")
  for (const [k, v] of Object.entries(attrs)) el.setAttribute(k, v)
  const h = Object.assign(Object.create(hook), {el, pushEvent() {}, pushEventTo() {}, liveSocket: {execJS() {}}})
  h.mounted()
  return {el, h}
}
const win = () => ({move: live.get("pointermove") || 0, up: live.get("pointerup") || 0})
const ptr = (type, init = {}) => Object.assign(new window.Event(type, {bubbles: true}), {pointerId: 1, clientX: 50, clientY: 5, button: 0}, init)

test("range: no window listener at rest, two while dragging, none after pointerup", {skip}, () => {
  const before = win()
  const cfg = JSON.stringify({min: 0, max: 100, step: 1, vertical: false, disabled: false, format: "%{value}", marks: [], decrease: "-", increase: "+"})
  const c = mountHook(hooks.range, `<input type="hidden" name="r" value="10" data-range-value><span data-part="range-thumb"></span>`, {"data-lu-config": cfg})
  c.el.getBoundingClientRect = () => ({left: 0, top: 0, width: 100, height: 10})
  assert.deepEqual(win(), before)
  c.el.dispatchEvent(ptr("pointerdown"))
  assert.deepEqual(win(), {move: before.move + 1, up: before.up + 1})
  window.dispatchEvent(ptr("pointermove", {clientX: 70}))
  assert.equal(c.el.querySelector("[data-range-value]").value, "70")
  window.dispatchEvent(ptr("pointerup"))
  assert.deepEqual(win(), before)
  window.dispatchEvent(ptr("pointermove", {clientX: 20}))
  assert.equal(c.el.querySelector("[data-range-value]").value, "70", "a move after the drag does nothing")
  c.h.destroyed()
})

test("range: destroyed in the middle of a drag leaves nothing on window", {skip}, () => {
  const before = win()
  const cfg = JSON.stringify({min: 0, max: 100, step: 1, vertical: false, disabled: false, format: "%{value}", marks: [], decrease: "-", increase: "+"})
  const c = mountHook(hooks.range, `<input type="hidden" name="r" value="10" data-range-value><span data-part="range-thumb"></span>`, {"data-lu-config": cfg})
  c.el.getBoundingClientRect = () => ({left: 0, top: 0, width: 100, height: 10})
  c.el.dispatchEvent(ptr("pointerdown"))
  c.h.destroyed()
  assert.deepEqual(win(), before)
})

test("color_picker: no window listener at rest, two while dragging, none after pointerup", {skip}, () => {
  const before = win()
  const c = mountHook(hooks.color_picker, `<input type="hidden" name="c" value="#1F9282" data-color-value><div data-area><i></i></div>`)
  const area = c.el.querySelector("[data-area]")
  area.getBoundingClientRect = () => ({left: 0, top: 0, width: 100, height: 100})
  assert.deepEqual(win(), before)
  area.dispatchEvent(ptr("pointerdown"))
  assert.deepEqual(win(), {move: before.move + 1, up: before.up + 1})
  window.dispatchEvent(ptr("pointermove", {clientX: 10, clientY: 10}))
  assert.notEqual(c.el.querySelector("[data-color-value]").value, "#1F9282")
  window.dispatchEvent(ptr("pointerup"))
  assert.deepEqual(win(), before)
  c.h.destroyed()
})

test("otp: a patch that keeps the boxes keeps the listeners, other boxes get them", {skip}, () => {
  let adds = 0
  const html = (n) => Array.from({length: n}, () => `<span><input data-lu-otp-box></span>`).join("") + `<input type="hidden" data-lu-otp-value>`
  const c = mountHook(hooks.otp, html(4), {"data-lu-length": "4"})
  const spy = (box) => { const a = box.addEventListener.bind(box); box.addEventListener = (...x) => { adds++; return a(...x) } }
  c.el.querySelectorAll("[data-lu-otp-box]").forEach(spy)
  c.h.updated()
  c.h.updated()
  assert.equal(adds, 0, "same boxes: nothing is bound again")
  // the typing still works after the patches
  const box = c.el.querySelector("[data-lu-otp-box]")
  box.value = "7"
  box.dispatchEvent(new window.Event("input", {bubbles: true}))
  assert.equal(c.el.querySelector("[data-lu-otp-value]").value, "7")
  // the patch replaced the boxes (another length): they are bound
  c.el.innerHTML = html(6)
  c.el.setAttribute("data-lu-length", "6")
  c.h.updated()
  const fresh = c.el.querySelector("[data-lu-otp-box]")
  fresh.value = "9"
  fresh.dispatchEvent(new window.Event("input", {bubbles: true}))
  assert.equal(c.el.querySelector("[data-lu-otp-value]").value, "9")
})
