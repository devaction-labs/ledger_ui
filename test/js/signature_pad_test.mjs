// signature_pad: the window pointer listeners exist only while a stroke is being drawn (#131).
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/signature_pad_test.mjs
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

let hook, w
const live = new Map() // type -> count of window listeners
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/"})
  w = dom.window
  const add = w.addEventListener.bind(w)
  const remove = w.removeEventListener.bind(w)
  w.addEventListener = (type, fn, o) => { live.set(type, (live.get(type) || 0) + 1); add(type, fn, o) }
  w.removeEventListener = (type, fn, o) => { live.set(type, (live.get(type) || 0) - 1); remove(type, fn, o) }
  Object.assign(globalThis, {window: w, document: w.document, DOMParser: w.DOMParser, CustomEvent: w.CustomEvent, Event: w.Event})
  hook = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/signature_pad.js")))).default
}

const cfg = {
  mode: "draw", disabled: false, variant: "classic", ink: "#000", onChange: null, onConfirm: null, target: null,
  labels: {signature_area: "Area", signature_ready: "ok", signature_empty: "empty"},
  classes: {path: "p", typed: "t", base: "b"},
}

function mount() {
  document.body.innerHTML =
    `<div id="sig" data-lu-config='${JSON.stringify(cfg)}'><div data-part="signature-surface"></div></div>`
  const el = document.getElementById("sig")
  const h = Object.assign(Object.create(hook), {el, pushEvent() {}, pushEventTo() {}})
  const svgProto = w.SVGSVGElement.prototype
  svgProto.createSVGPoint = () => ({x: 0, y: 0, matrixTransform() { return {x: this.x, y: this.y} }})
  svgProto.getScreenCTM = () => ({inverse: () => ({})})
  h.mounted()
  return h
}

const count = (t) => live.get(t) || 0
const ptr = (type, init = {}) => new w.Event(type, {bubbles: true, ...init})

test("mounted leaves no pointermove/pointerup on window", {skip}, () => {
  live.clear()
  const h = mount()
  assert.equal(count("pointermove"), 0)
  assert.equal(count("pointerup"), 0)
  h.destroyed()
})

test("a stroke adds them on pointerdown and removes them on pointerup; the path grows with the pointer", {skip}, () => {
  live.clear()
  const h = mount()
  const pad = h.pad()
  const down = ptr("pointerdown", {cancelable: true})
  Object.assign(down, {button: 0, clientX: 5, clientY: 6, pointerId: 1})
  pad.dispatchEvent(down)
  assert.ok(h.drawing)
  assert.equal(count("pointermove"), 1)
  assert.equal(count("pointerup"), 1)
  const mv = ptr("pointermove")
  Object.assign(mv, {clientX: 9, clientY: 9})
  w.dispatchEvent(mv)
  assert.match(h.drawing.getAttribute("d"), /L9 9$/)
  w.dispatchEvent(ptr("pointerup"))
  assert.equal(h.drawing, null)
  assert.equal(count("pointermove"), 0)
  assert.equal(count("pointerup"), 0)
  assert.equal(count("pointercancel"), 0)
  h.destroyed()
})

test("destroyed in the middle of a stroke removes them too", {skip}, () => {
  live.clear()
  const h = mount()
  const down = ptr("pointerdown", {cancelable: true})
  Object.assign(down, {button: 0, clientX: 1, clientY: 1, pointerId: 1})
  h.pad().dispatchEvent(down)
  h.destroyed()
  assert.equal(count("pointermove"), 0)
  assert.equal(count("pointerup"), 0)
  assert.equal(count("pointercancel"), 0)
})
