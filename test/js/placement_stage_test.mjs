// The placement_stage hook in a jsdom document.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/placement_stage_test.mjs
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
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true})
  Object.assign(globalThis, {window: dom.window, document: dom.window.document})
  const dir = mkdtempSync(join(tmpdir(), "lu-stage-"))
  writeFileSync(join(dir, "placement_stage.mjs"), readFileSync(join(here, "../../priv/static/ledger_ui/hooks/placement_stage.js"), "utf8"))
  hook = (await import(pathToFileURL(join(dir, "placement_stage.mjs")))).default
}

const W = 400, H = 500 // the image, at (100, 50) on the page

// Builds the markup of the component, mounts the hook and records what it pushes.
function mount({box = [10, 20, 30, 8], resizable = true, disabled = false, target = null} = {}) {
  document.body.innerHTML = `<div id="s" data-lu-box="${box.join(",")}" data-lu-on-place="place" data-lu-on-resize="resize"
      ${disabled ? 'data-lu-disabled="true"' : ""} ${target ? `phx-target="${target}"` : ""}>
    <img src="/p.png">
    <div data-part="placement-box" tabindex="0" style="left:${box[0]}%;bottom:${box[1]}%;width:${box[2]}%;height:${box[3]}%">
      ${resizable ? '<span data-handle></span>' : ""}
    </div></div>`
  const el = document.getElementById("s")
  el.querySelector("img").getBoundingClientRect = () => ({left: 100, top: 50, width: W, height: H, right: 100 + W, bottom: 50 + H})
  const calls = []
  const replies = []
  const inst = Object.assign(Object.create(hook), {
    el,
    pushEvent(event, payload, cb) { calls.push({event, payload, target: null}); replies.push(cb) },
    pushEventTo(target, event, payload, cb) { calls.push({event, payload, target}); replies.push(cb) },
  })
  inst.mounted()
  const box$ = el.querySelector('[data-part="placement-box"]')
  const ev = (type, init = {}) => {
    const e = new window.Event(type, {bubbles: true, cancelable: true})
    Object.assign(e, {pointerId: 1, pointerType: "mouse", button: 0, ...init})
    return e
  }
  const pointer = (type, x, y, target = el.querySelector("img")) => target.dispatchEvent(ev(type, {clientX: 100 + x * W, clientY: 50 + y * H}))
  const style = () => ["left", "bottom", "width", "height"].map((k) => parseFloat(box$.style[k]))
  const key = (k, extra = {}) => { const e = ev("keydown", {key: k, ...extra}); box$.dispatchEvent(e); return e }
  return {el, inst, calls, replies, box$, pointer, style, key}
}

const near = (actual, expected) => actual.forEach((v, i) => assert.ok(Math.abs(v - expected[i]) < 1e-3, `${actual} != ${expected}`))

test("pressing moves the box at once, centre under the pointer, y from the top", {skip}, () => {
  const t = mount()
  t.pointer("pointerdown", 0.5, 0.4)
  near(t.style(), [35, 56, 30, 8]) // left 50-15, bottom 100-40-4
  assert.equal(t.calls.length, 0)
})

test("pointerup pushes the centre as fractions", {skip}, () => {
  const t = mount()
  t.pointer("pointerdown", 0.5, 0.4)
  t.pointer("pointerup", 0.5, 0.4)
  assert.deepEqual(t.calls, [{event: "place", payload: {x: 0.5, y: 0.4}, target: null}])
})

test("dragging follows the pointer and pushes only once, at the end", {skip}, () => {
  const t = mount()
  t.pointer("pointerdown", 0.3, 0.3)
  t.pointer("pointermove", 0.5, 0.5)
  near(t.style(), [35, 46, 30, 8])
  t.pointer("pointermove", 0.6, 0.7)
  assert.equal(t.calls.length, 0)
  t.pointer("pointerup", 0.6, 0.7)
  assert.deepEqual(t.calls.map((c) => c.payload), [{x: 0.6, y: 0.7}])
})

test("the box stays inside the edges and the payload is the limited centre", {skip}, () => {
  const t = mount()
  t.pointer("pointerdown", 0, 0)
  near(t.style(), [0, 92, 30, 8])
  t.pointer("pointerup", 0, 0)
  assert.deepEqual(t.calls[0].payload, {x: 0.15, y: 0.04})
  t.pointer("pointerdown", 1.5, 1.5)
  near(t.style(), [70, 0, 30, 8])
  t.pointer("pointerup", 1.5, 1.5)
  assert.deepEqual(t.calls[1].payload, {x: 0.85, y: 0.96})
})

test("moves without a press do nothing; other mouse buttons are ignored", {skip}, () => {
  const t = mount()
  t.pointer("pointermove", 0.5, 0.5)
  near(t.style(), [10, 20, 30, 8])
  t.el.querySelector("img").dispatchEvent(Object.assign(new window.Event("pointerdown", {bubbles: true}), {pointerId: 1, pointerType: "mouse", button: 2, clientX: 300, clientY: 300}))
  near(t.style(), [10, 20, 30, 8])
})

test("touch presses place too", {skip}, () => {
  const t = mount()
  t.el.querySelector("img").dispatchEvent(Object.assign(new window.Event("pointerdown", {bubbles: true, cancelable: true}), {pointerId: 2, pointerType: "touch", button: 0, clientX: 100 + 0.5 * W, clientY: 50 + 0.5 * H}))
  near(t.style(), [35, 46, 30, 8])
})

test("the handle resizes around the centre, keeps proportions and pushes the width", {skip}, () => {
  const t = mount() // centre (25, 24); handle drag to 40% of the image width
  const handle = t.el.querySelector("[data-handle]")
  t.pointer("pointerdown", 0.4, 0.5, handle)
  // width = 2 * (40 - 25) = 30 -> unchanged; drag further
  t.pointer("pointermove", 0.5, 0.5, handle)
  near(t.style(), [0, 24 - 6.666666667, 50, 13.333333333]) // width 2 * (50 - 25), height 8 * 50/30
  t.pointer("pointerup", 0.5, 0.5, handle)
  assert.deepEqual(t.calls, [{event: "resize", payload: {width: 0.5}, target: null}])
  const [l, b, w, h] = t.style()
  assert.ok(Math.abs(l + w / 2 - 25) < 1e-3 && Math.abs(b + h / 2 - 24) < 1e-3)
})

test("resizing is limited: minimum 5% and never past the edges", {skip}, () => {
  const t = mount()
  const handle = t.el.querySelector("[data-handle]")
  t.pointer("pointerdown", 0.25, 0.5, handle) // on the centre: width 0 -> 5
  assert.equal(t.style()[2], 5)
  t.pointer("pointermove", 1, 0.5, handle)
  const [l, b, w, h] = t.style()
  assert.ok(l >= 0 && l + w <= 100 + 1e-6 && b >= 0 && b + h <= 100 + 1e-6)
  assert.ok(Math.abs(w - 50) < 1e-3) // 2 * min(25, 75)
})

test("without a handle there is no resize gesture", {skip}, () => {
  const t = mount({resizable: false})
  assert.equal(t.el.querySelector("[data-handle]"), null)
})

test("arrow keys move 1%, Shift 10%, limited, and push every time", {skip}, () => {
  const t = mount()
  const e = t.key("ArrowRight")
  assert.ok(e.defaultPrevented)
  near(t.style(), [11, 20, 30, 8])
  assert.deepEqual(t.calls[0], {event: "place", payload: {x: 0.26, y: 0.76}, target: null})
  t.key("ArrowUp")
  near(t.style(), [11, 21, 30, 8])
  t.key("ArrowDown", {shiftKey: true})
  near(t.style(), [11, 11, 30, 8])
  t.key("ArrowLeft", {shiftKey: true})
  near(t.style(), [1, 11, 30, 8])
  t.key("ArrowLeft", {shiftKey: true})
  near(t.style(), [0, 11, 30, 8])
  assert.equal(t.calls.length, 5)
  assert.deepEqual(t.calls[4].payload, {x: 0.15, y: 0.85})
})

test("other keys and modified arrows are left alone", {skip}, () => {
  const t = mount()
  assert.ok(!t.key("a").defaultPrevented)
  assert.ok(!t.key("ArrowRight", {ctrlKey: true}).defaultPrevented)
  assert.equal(t.calls.length, 0)
})

test("disabled: no gesture, no keys", {skip}, () => {
  const t = mount({disabled: true})
  t.pointer("pointerdown", 0.5, 0.5)
  t.pointer("pointerup", 0.5, 0.5)
  t.key("ArrowRight")
  near(t.style(), [10, 20, 30, 8])
  assert.equal(t.calls.length, 0)
})

test("phx-target sends the events to the component", {skip}, () => {
  const t = mount({target: "#form"})
  t.key("ArrowRight")
  assert.equal(t.calls[0].target, "#form")
  const c = mount({target: "3"})
  c.key("ArrowRight")
  assert.equal(c.calls[0].target, '[data-phx-component="3"]')
})

test("a cancelled gesture goes back and sends nothing", {skip}, () => {
  const t = mount()
  t.pointer("pointerdown", 0.8, 0.8)
  t.pointer("pointercancel", 0.8, 0.8)
  near(t.style(), [10, 20, 30, 8])
  assert.equal(t.calls.length, 0)
})

// What LiveView does on a patch: the style goes back to what the server rendered, data-lu-box says it.
const patch = (t, box) => {
  t.el.setAttribute("data-lu-box", box.join(","))
  const [left, bottom, width, height] = box
  Object.assign(t.box$.style, {left: left + "%", bottom: bottom + "%", width: width + "%", height: height + "%"})
  t.inst.updated()
}

test("the server wins: a new box is adopted", {skip}, () => {
  const t = mount()
  patch(t, [40, 40, 20, 5])
  near(t.style(), [40, 40, 20, 5])
})

test("a new box during a drag does not fight the gesture", {skip}, () => {
  const t = mount()
  t.pointer("pointerdown", 0.5, 0.5)
  patch(t, [0, 0, 30, 8])
  near(t.style(), [35, 46, 30, 8])
  t.pointer("pointermove", 0.6, 0.5)
  near(t.style(), [45, 46, 30, 8])
  t.pointer("pointerup", 0.6, 0.5)
  patch(t, [60, 60, 30, 8]) // changed again, after the gesture, with the event unanswered
  near(t.style(), [60, 60, 30, 8])
})

test("an unchanged box does not undo a move still on its way; once answered, the server box stands", {skip}, () => {
  const t = mount()
  t.key("ArrowRight")
  patch(t, [10, 20, 30, 8]) // an unrelated patch
  near(t.style(), [11, 20, 30, 8])
  t.replies[0]()
  patch(t, [12, 20, 30, 8])
  near(t.style(), [12, 20, 30, 8])
  patch(t, [12, 20, 30, 8])
  near(t.style(), [12, 20, 30, 8])
})

test("destroyed removes the listeners", {skip}, () => {
  const t = mount()
  t.inst.destroyed()
  t.pointer("pointerdown", 0.5, 0.5)
  t.key("ArrowRight")
  near(t.style(), [10, 20, 30, 8])
})
