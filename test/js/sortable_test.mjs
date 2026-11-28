// The sortable hook: drag between lists, reorder, cancel, handle, disabled, groups, local moves and touch hold (#121).
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/sortable_test.mjs
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
const skip = JSDOM ? false : (process.env.CI === "true" || process.env.CI === "1" ? (() => { throw new Error("jsdom not found and CI is set: run `npm install` (or set JSDOM_PATH)") })() : "jsdom not found (run `npm install` or set JSDOM_PATH)")

let sortable
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/"})
  const w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, getComputedStyle: w.getComputedStyle.bind(w),
    requestAnimationFrame: (fn) => setTimeout(fn, 1000), cancelAnimationFrame: clearTimeout})
  // jsdom has no layout: lists are 200px-wide columns side by side (data-left), cards 40px tall with a 10px gap.
  const CARD = 40, GAP = 10
  const rectOf = (el) => {
    let r
    if (el.matches("[data-list],[data-part=kanban-column]")) r = {left: Number(el.dataset.left), top: 0, width: 200, height: 400}
    else {
      const list = el.parentElement
      const pos = Array.from(list.children).filter((c) => !c.hasAttribute("data-drop-slot")).indexOf(el)
      r = {left: Number(list.dataset.left), top: GAP + pos * (CARD + GAP), width: 200, height: CARD}
    }
    return {...r, right: r.left + r.width, bottom: r.top + r.height, x: r.left, y: r.top}
  }
  w.HTMLElement.prototype.getBoundingClientRect = function () { return rectOf(this) }
  document.elementsFromPoint = (x, y) =>
    Array.from(document.querySelectorAll("[data-list],[data-part=kanban-column]")).filter((l) => {
      const r = rectOf(l)
      return x >= r.left && x < r.right && y >= r.top && y < r.bottom
    })
  sortable = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/sortable.js")))).default
}

const wait = (ms) => new Promise((r) => setTimeout(r, ms))

// Two columns "todo" (a1 a2 a3) and "done" (b1) in one board; `board`/`todo`/`done`: extra attributes.
function mount({board = "", todo = "", done = "", extra = ""} = {}) {
  document.body.innerHTML =
    `<div id="board" phx-hook="LedgerUI.Sortable" data-event="moved" ${board}>` +
    `<div data-list="todo" data-left="0" ${todo}><div data-id="a1" id="a1">A1 <button id="btn">x</button><span class="grip">::</span></div><div data-id="a2" id="a2">A2</div><div data-id="a3" id="a3">A3</div></div>` +
    `<div data-list="done" data-left="300" ${done}><div data-id="b1" id="b1">B1</div></div>${extra}</div>`
  const el = document.getElementById("board")
  const pushed = []
  const hook = Object.assign(Object.create(sortable), {el, pushEvent(e, p) { pushed.push([e, p]) }, pushEventTo(t, e, p) { pushed.push([e, p, t]) }})
  hook.mounted()
  const $ = (id) => document.getElementById(id)
  const ptr = (type, target, x, y, extra = {}) => {
    const {button = 0, ...props} = extra
    const ev = new window.MouseEvent(type, {bubbles: true, cancelable: true, clientX: x, clientY: y, button})
    Object.assign(ev, {pointerId: 1, isPrimary: true, pointerType: "mouse", ...props})
    target.dispatchEvent(ev)
  }
  return {hook, el, $, pushed,
    down: (target, x, y, extra) => ptr("pointerdown", target, x, y, extra),
    move: (x, y, extra) => ptr("pointermove", window, x, y, extra),
    up: (x, y, extra) => ptr("pointerup", window, x, y, extra),
    ghost: () => document.querySelector("[data-drag-ghost]"),
    slot: () => document.querySelector("[data-drop-slot]"),
    order: (list) => Array.from(document.querySelector(`[data-list=${list}]`).children).filter((c) => c.dataset.id).map((c) => c.dataset.id)}
}

// matchMedia reduced: the drop lands at once (no waiting for the glide)
if (JSDOM) window.matchMedia = () => ({matches: true})

test("dragging a card to another list: ghost, dimmed original, data-over, drop slot, then one event with id/from/to/index", {skip}, () => {
  const t = mount()
  t.down(t.$("a1"), 50, 20)
  t.move(52, 20)
  assert.equal(t.ghost(), null, "under 4px: still a click")
  t.move(60, 30)
  assert.ok(t.ghost(), "past the threshold: the lifted copy exists")
  assert.equal(t.ghost().getAttribute("aria-hidden"), "true")
  assert.equal(t.ghost().hasAttribute("id"), false, "the copy has no duplicate id")
  assert.ok(t.$("a1").hasAttribute("data-dragging"))
  assert.equal(t.$("a1").style.opacity, "0.35")
  t.move(350, 15)
  assert.ok(t.el.querySelector('[data-list=done]').hasAttribute("data-over"))
  assert.ok(!t.el.querySelector('[data-list=todo]').hasAttribute("data-over"))
  assert.equal(t.slot().parentElement.dataset.list, "done")
  assert.deepEqual(t.order("done"), ["b1"], "nothing moved in the browser: the server's render is the order")
  assert.equal(t.slot().nextElementSibling.id, "b1", "y=15 is above b1's middle: lands first")
  t.up(350, 15)
  assert.deepEqual(t.pushed, [["moved", {id: "a1", from: "todo", to: "done", index: 0}]])
  assert.equal(t.ghost(), null)
  assert.equal(t.slot(), null)
  assert.ok(!t.$("a1").hasAttribute("data-dragging"))
  assert.equal(t.$("a1").style.opacity, "")
  assert.ok(!t.el.querySelector('[data-list=done]').hasAttribute("data-over"))
  assert.deepEqual(t.order("todo"), ["a1", "a2", "a3"])
  t.hook.destroyed()
})

test("the index comes from the pointer against each card's middle (after the last when below all)", {skip}, () => {
  const t = mount()
  t.down(t.$("b1"), 350, 20)
  t.move(350, 30); t.move(50, 300)
  t.up(50, 300)
  assert.deepEqual(t.pushed, [["moved", {id: "b1", from: "done", to: "todo", index: 3}]])
  t.hook.destroyed()
  const m = mount()
  m.down(m.$("b1"), 350, 20)
  m.move(350, 30); m.move(50, 40)   // a1 spans 10..50 (middle 30), a2 60..100 (middle 80): y=40 is after a1's middle
  m.up(50, 40)
  assert.equal(m.pushed[0][1].index, 1)
  m.hook.destroyed()
})

test("reordering inside a list; dropping back where it was sends nothing", {skip}, () => {
  const t = mount()
  t.down(t.$("a1"), 50, 20)
  t.move(50, 30); t.move(50, 120)   // past a2's middle (80), before a3's (130)
  t.up(50, 120)
  assert.deepEqual(t.pushed, [["moved", {id: "a1", from: "todo", to: "todo", index: 1}]], "among the others [a2, a3]: between them")
  t.hook.destroyed()
  const same = mount()
  same.down(same.$("a2"), 50, 80)
  same.move(50, 90); same.move(50, 82)
  same.up(50, 82)
  assert.deepEqual(same.pushed, [], "the same list at the same index: no event")
  same.hook.destroyed()
})

test("Escape cancels: no event and everything is cleaned", {skip}, () => {
  const t = mount()
  t.down(t.$("a1"), 50, 20)
  t.move(60, 30); t.move(350, 15)
  window.dispatchEvent(new window.KeyboardEvent("keydown", {key: "Escape", bubbles: true}))
  assert.deepEqual(t.pushed, [])
  assert.equal(t.ghost(), null)
  assert.equal(t.slot(), null)
  assert.ok(!t.el.querySelector("[data-over]"))
  assert.ok(!t.$("a1").hasAttribute("data-dragging"))
  assert.equal(t.hook.drag, null)
  t.hook.destroyed()
})

test("a drop outside any list, and a pointercancel, send nothing", {skip}, () => {
  const t = mount()
  t.down(t.$("a1"), 50, 20)
  t.move(60, 30); t.move(250, 200)   // the gap between columns
  t.up(250, 200)
  assert.deepEqual(t.pushed, [])
  assert.equal(t.ghost(), null)
  t.down(t.$("a1"), 50, 20)
  t.move(60, 30); t.move(350, 15)
  window.dispatchEvent(Object.assign(new window.MouseEvent("pointercancel", {bubbles: true}), {pointerId: 1}))
  assert.deepEqual(t.pushed, [], "cancelled over a valid list: still nothing")
  assert.equal(t.hook.drag, null)
  t.hook.destroyed()
})

test("a press that never moves is a click: no ghost, no event", {skip}, () => {
  const t = mount()
  t.down(t.$("a1"), 50, 20)
  t.up(50, 20)
  assert.equal(t.ghost(), null)
  assert.deepEqual(t.pushed, [])
  assert.equal(t.hook.drag, null)
  t.hook.destroyed()
})

test("it does not start on interactive content, on a secondary button or on a second pointer", {skip}, () => {
  const t = mount()
  t.down(t.$("btn"), 20, 20)
  assert.equal(t.hook.drag, null, "a button inside the card")
  t.down(t.$("a1"), 50, 20, {button: 2})
  assert.equal(t.hook.drag, null, "right button")
  t.down(t.$("a1"), 50, 20, {isPrimary: false})
  assert.equal(t.hook.drag, null, "not the primary pointer")
  t.hook.destroyed()
})

test("data-handle: only the handle starts a drag", {skip}, () => {
  const t = mount({board: 'data-handle=".grip"'})
  t.down(t.$("a1"), 50, 20)
  assert.equal(t.hook.drag, null)
  t.down(t.$("a1").querySelector(".grip"), 50, 20)
  assert.ok(t.hook.drag)
  t.hook.destroyed()
})

test("a disabled list does not drag, and cannot be dropped on", {skip}, () => {
  const t = mount({todo: "data-disabled"})
  t.down(t.$("a1"), 50, 20)
  assert.equal(t.hook.drag, null)
  t.down(t.$("b1"), 350, 20)
  t.move(350, 30); t.move(50, 20)
  assert.ok(!t.el.querySelector('[data-list=todo]').hasAttribute("data-over"), "not a target")
  t.up(50, 20)
  assert.deepEqual(t.pushed, [])
  t.hook.destroyed()
})

test("groups: a list of another group is not a target", {skip}, () => {
  const t = mount({todo: 'data-group="x"', done: 'data-group="y"'})
  t.down(t.$("a1"), 50, 20)
  t.move(60, 30); t.move(350, 15)
  assert.ok(!t.el.querySelector('[data-list=done]').hasAttribute("data-over"))
  t.up(350, 15)
  assert.deepEqual(t.pushed, [])
  t.hook.destroyed()
})

test("data-target sends the event to that component", {skip}, () => {
  const t = mount({board: 'data-target="#cmp"'})
  t.down(t.$("a1"), 50, 20)
  t.move(60, 30); t.move(350, 15); t.up(350, 15)
  assert.deepEqual(t.pushed, [["moved", {id: "a1", from: "todo", to: "done", index: 0}, "#cmp"]])
  t.hook.destroyed()
})

test("no data-event: the drop moves nothing and sends nothing", {skip}, () => {
  const t = mount()
  t.el.removeAttribute("data-event")
  t.down(t.$("a1"), 50, 20)
  t.move(60, 30); t.move(350, 15); t.up(350, 15)
  assert.deepEqual(t.pushed, [])
  t.hook.destroyed()
})

test("data-lu-local: the board moves the card itself and refreshes the counters", {skip}, () => {
  const t = mount({board: "data-lu-local"})
  t.down(t.$("a1"), 50, 20)
  t.move(60, 30); t.move(350, 15); t.up(350, 15)
  assert.deepEqual(t.order("done"), ["a1", "b1"])
  assert.deepEqual(t.order("todo"), ["a2", "a3"])
  t.hook.destroyed()
})

test("touch: a move before the hold is a scroll (no drag); holding starts it", {skip}, async () => {
  const t = mount()
  t.down(t.$("a1"), 50, 20, {pointerType: "touch"})
  t.move(50, 60, {pointerType: "touch"})
  assert.equal(t.hook.drag, null, "moved more than 8px before the hold: it was a scroll")
  const h = mount()
  h.down(h.$("a1"), 50, 20, {pointerType: "touch"})
  assert.equal(h.ghost(), null)
  await wait(300)
  assert.ok(h.ghost(), "after the hold the card lifts")
  h.up(50, 20, {pointerType: "touch"})
  h.hook.destroyed()
  t.hook.destroyed()
})

test("destroyed during a drag removes the ghost, the slot and the listeners", {skip}, () => {
  const t = mount()
  t.down(t.$("a1"), 50, 20)
  t.move(60, 30); t.move(350, 15)
  t.hook.destroyed()
  assert.equal(t.ghost(), null)
  assert.equal(t.slot(), null)
  assert.ok(!t.el.querySelector("[data-over]"))
  t.move(60, 30)
  t.up(60, 30)
  assert.deepEqual(t.pushed, [])
})
