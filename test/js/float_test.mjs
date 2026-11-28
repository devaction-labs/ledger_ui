// The float hook (tooltip, popover): triggers, open state, flip with simulated rectangles, offset, arrow, events (#121).
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/float_test.mjs
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

let float
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/"})
  const w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, MutationObserver: w.MutationObserver, getComputedStyle: w.getComputedStyle.bind(w)})
  float = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/float.js")))).default
}

const tick = (ms = 0) => new Promise((r) => setTimeout(r, ms))

// `rects` maps a placement to the rectangle the floating box would occupy there (jsdom has no layout).
function mount(data = {}, rects = {}) {
  const attrs = Object.entries({"data-lu-kind": "popover", "data-lu-placement": "top", ...data}).map(([k, v]) => `${k}="${String(v).replaceAll('"', "&quot;")}"`).join(" ")
  document.body.innerHTML = `<div id="root" ${attrs}><button id="trig">Open</button>` +
    `<div data-lu-fl id="fl" hidden><div data-part="box" id="box">content</div></div></div><input id="out">`
  const root = document.getElementById("root")
  const fl = document.getElementById("fl")
  fl.getBoundingClientRect = () => {
    const r = rects[fl.getAttribute("data-lu-placement")] || {left: 100, top: 100, right: 200, bottom: 150}
    return {width: r.right - r.left, height: r.bottom - r.top, x: r.left, y: r.top, ...r}
  }
  const events = []
  const hook = Object.assign(Object.create(float), {
    el: root,
    pushEvent(e, p) { events.push([e, p]) },
    pushEventTo(t, e, p) { events.push([e, p, t]) },
    liveSocket: {execJS(el, code) { events.push(["js", code]) }},
  })
  hook.mounted()
  return {hook, root, fl, events, trig: document.getElementById("trig")}
}

const OK = {left: 100, top: 100, right: 200, bottom: 150}
const OFF_TOP = {left: 100, top: -30, right: 200, bottom: 20}
const OFF_LEFT = {left: -50, top: 100, right: 50, bottom: 150}
const OFF_BOTTOM = {left: 100, top: 740, right: 200, bottom: 790}

test("click mode: the trigger opens (hidden off, aria-expanded, aria-controls), a second click closes", {skip}, () => {
  const t = mount({"data-lu-trigger": "click"}, {top: OK})
  assert.equal(t.trig.getAttribute("aria-haspopup"), "dialog")
  assert.equal(t.trig.getAttribute("aria-controls"), "fl")
  t.trig.click()
  assert.ok(t.root.classList.contains("open"))
  assert.equal(t.fl.hidden, false)
  assert.equal(t.trig.getAttribute("aria-expanded"), "true")
  t.trig.click()
  assert.ok(!t.root.classList.contains("open"))
  assert.equal(t.fl.hidden, true)
  assert.equal(t.trig.getAttribute("aria-expanded"), "false")
  t.hook.destroyed()
})

test("a click inside the floating box does not toggle it", {skip}, () => {
  const t = mount({"data-lu-trigger": "click"}, {top: OK})
  t.trig.click()
  document.getElementById("box").click()
  assert.ok(t.root.classList.contains("open"))
  t.hook.destroyed()
})

test("Escape closes; a pointerdown outside closes in click mode, inside does not", {skip}, () => {
  const t = mount({"data-lu-trigger": "click"}, {top: OK})
  t.trig.click()
  document.dispatchEvent(new window.KeyboardEvent("keydown", {key: "Escape", bubbles: true}))
  assert.ok(!t.root.classList.contains("open"))
  t.trig.click()
  document.getElementById("box").dispatchEvent(new window.Event("pointerdown", {bubbles: true}))
  assert.ok(t.root.classList.contains("open"))
  document.getElementById("out").dispatchEvent(new window.Event("pointerdown", {bubbles: true}))
  assert.ok(!t.root.classList.contains("open"))
  t.hook.destroyed()
})

test("hover mode: opens after the delay on mouseenter and closes on mouseleave; leaving before the delay cancels", {skip}, async () => {
  const t = mount({"data-lu-kind": "tooltip", "data-lu-trigger": "hover", "data-lu-delay": "20"}, {top: OK})
  assert.equal(t.trig.getAttribute("aria-describedby"), "fl")
  t.root.dispatchEvent(new window.MouseEvent("mouseenter"))
  assert.ok(!t.root.classList.contains("open"), "not yet")
  t.root.dispatchEvent(new window.MouseEvent("mouseleave"))
  await tick(40)
  assert.ok(!t.root.classList.contains("open"), "left before the delay: never opened")
  t.root.dispatchEvent(new window.MouseEvent("mouseenter"))
  await tick(40)
  assert.ok(t.root.classList.contains("open"))
  assert.equal(t.fl.hidden, false)
  t.root.dispatchEvent(new window.MouseEvent("mouseleave"))
  await tick(40)
  assert.ok(!t.root.classList.contains("open"))
  t.hook.destroyed()
})

test("hover mode also opens on focus and closes when focus leaves the root", {skip}, () => {
  const t = mount({"data-lu-kind": "tooltip", "data-lu-trigger": "hover", "data-lu-delay": "0"}, {top: OK})
  t.trig.focus()
  assert.ok(t.root.classList.contains("open"), "keyboard focus shows the tooltip")
  t.root.dispatchEvent(new window.FocusEvent("focusout", {bubbles: true, relatedTarget: document.getElementById("out")}))
  assert.ok(!t.root.classList.contains("open"))
  t.hook.destroyed()
})

test("placement that fits is kept", {skip}, () => {
  const t = mount({"data-lu-placement": "top", "data-lu-fallbacks": "bottom,right"}, {top: OK, bottom: OK})
  t.hook.setOpen(true)
  assert.equal(t.fl.getAttribute("data-lu-placement"), "top")
  t.hook.destroyed()
})

test("flip: a placement that overflows the window goes to the first fallback that fits", {skip}, () => {
  const t = mount({"data-lu-placement": "top", "data-lu-fallbacks": "left,bottom,right"}, {top: OFF_TOP, left: OFF_LEFT, bottom: OK, right: OK})
  t.hook.setOpen(true)
  assert.equal(t.fl.getAttribute("data-lu-placement"), "bottom", "top and left overflow, bottom fits")
  t.hook.destroyed()
})

test("flip: with no fallback that fits, the preferred placement is restored", {skip}, () => {
  const t = mount({"data-lu-placement": "top", "data-lu-fallbacks": "bottom"}, {top: OFF_TOP, bottom: OFF_BOTTOM})
  t.hook.setOpen(true)
  assert.equal(t.fl.getAttribute("data-lu-placement"), "top")
  t.hook.destroyed()
})

test("the offset becomes a margin on the side facing the trigger (default 8 adds none)", {skip}, () => {
  const t = mount({"data-lu-placement": "top", "data-lu-offset": "14"}, {top: OK})
  t.hook.setOpen(true)
  assert.equal(t.fl.style.marginBottom, "6px")
  const d = mount({"data-lu-placement": "bottom"}, {bottom: OK})
  d.hook.setOpen(true)
  assert.equal(d.fl.style.marginTop, "")
  t.hook.destroyed()
  d.hook.destroyed()
})

test("arrow: drawn once, aria-hidden, on the edge that faces the trigger", {skip}, () => {
  const t = mount({"data-lu-placement": "top-start", "data-lu-arrow": "true"}, {"top-start": OK})
  t.hook.setOpen(true)
  const arrows = t.fl.querySelectorAll("[data-lu-arrow-el]")
  assert.equal(arrows.length, 1)
  assert.equal(arrows[0].getAttribute("aria-hidden"), "true")
  assert.equal(arrows[0].style.bottom, "-5px", "a top hint has the arrow on its bottom edge")
  assert.equal(arrows[0].style.left, "14px")
  t.hook.place()
  assert.equal(t.fl.querySelectorAll("[data-lu-arrow-el]").length, 1, "placing again does not draw a second one")
  t.hook.destroyed()
})

test("on-open and on-close: an event name is pushed with the id, a JS command is executed", {skip}, () => {
  const t = mount({"data-lu-on-open": "opened", "data-lu-on-close": '[["push",{"event":"closed"}]]'}, {top: OK})
  t.hook.setOpen(true)
  assert.deepEqual(t.events[0], ["opened", {id: "root"}])
  t.hook.setOpen(false)
  assert.deepEqual(t.events[1], ["js", '[["push",{"event":"closed"}]]'])
  t.hook.destroyed()
})

test("a class `open` added from outside (LedgerUI.open) is picked up by the observer", {skip}, async () => {
  const t = mount({}, {top: OK})
  t.root.classList.add("open")
  await tick(0)
  assert.equal(t.hook.isOpen, true)
  assert.equal(t.fl.hidden, false)
  t.root.classList.remove("open")
  await tick(0)
  assert.equal(t.fl.hidden, true)
  t.hook.destroyed()
})

test("destroyed removes the document and window listeners", {skip}, () => {
  const t = mount({"data-lu-trigger": "click"}, {top: OK})
  t.trig.click()
  t.hook.destroyed()
  document.dispatchEvent(new window.KeyboardEvent("keydown", {key: "Escape", bubbles: true}))
  assert.ok(t.root.classList.contains("open"), "no listener left to close it")
  assert.equal(t.hook.onKey, null)
})
