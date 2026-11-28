// The context_menu hook: right click opens at the pointer, keyboard, Escape and focus restore, outside dismissal (#121).
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/context_menu_test.mjs
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

let menuHook
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/"})
  const w = dom.window
  // jsdom has no layout: every element counts as rendered, the window is 1000x800, the menu 200x100.
  Object.defineProperty(w.HTMLElement.prototype, "offsetParent", {get() { return this.hidden ? null : this.parentNode }})
  Object.defineProperty(w.HTMLElement.prototype, "offsetWidth", {get() { return 200 }})
  Object.defineProperty(w.HTMLElement.prototype, "offsetHeight", {get() { return 100 }})
  Object.defineProperty(w.document.documentElement, "clientWidth", {get() { return 1000 }})
  Object.defineProperty(w.document.documentElement, "clientHeight", {get() { return 800 }})
  Object.assign(globalThis, {window: w, document: w.document, HTMLElement: w.HTMLElement, MutationObserver: w.MutationObserver})
  menuHook = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/context_menu.js")))).default
}

function mount(attrs = "") {
  document.body.innerHTML =
    `<button id="before">before</button>` +
    `<div id="area" ${attrs} tabindex="0"><p id="target">right click me</p>` +
    `<div role="menu" id="menu" hidden>` +
    `<button role="menuitem" id="m-open">Open</button>` +
    `<button role="menuitem" id="m-off" aria-disabled="true">Disabled</button>` +
    `<button role="menuitem" id="m-rename">Rename</button>` +
    `<button role="menuitem" id="m-delete">Delete</button></div></div>`
  const el = document.getElementById("area")
  const hook = Object.assign(Object.create(menuHook), {el})
  hook.mounted()
  const $ = (id) => document.getElementById(id)
  const rightClick = (target, x = 100, y = 120) => {
    const ev = new window.MouseEvent("contextmenu", {bubbles: true, cancelable: true, clientX: x, clientY: y})
    target.dispatchEvent(ev)
    return ev
  }
  const key = (k, init = {}) => { const ev = new window.KeyboardEvent("keydown", {key: k, bubbles: true, cancelable: true, ...init}); document.activeElement.dispatchEvent(ev); return ev }
  return {hook, el, $, rightClick, key, menu: $("menu"), focused: () => document.activeElement && document.activeElement.id}
}

test("setup: the menu gets role=menu items and is hidden until opened", {skip}, () => {
  const t = mount()
  assert.equal(t.menu.hidden, true)
  assert.equal(t.menu.style.position, "fixed")
  t.hook.destroyed()
})

test("a right click opens at the pointer, cancels the native menu and focuses the first enabled item", {skip}, () => {
  const t = mount()
  const ev = t.rightClick(t.$("target"), 100, 120)
  assert.equal(ev.defaultPrevented, true)
  assert.equal(t.menu.hidden, false)
  assert.equal(t.menu.style.left, "100px")
  assert.equal(t.menu.style.top, "120px")
  assert.equal(t.focused(), "m-open")
  t.hook.destroyed()
})

test("placement flips and clamps near the window edge", {skip}, () => {
  const t = mount()
  t.rightClick(t.$("target"), 950, 780)
  assert.equal(t.menu.dataset.side, "top", "no room below: opens upwards")
  assert.equal(t.menu.style.top, "680px", "780 - 100 high")
  assert.equal(t.menu.style.left, "792px", "clamped inside the window (1000 - 200 - 8)")
  t.hook.destroyed()
})

test("arrows move through the enabled items and wrap; Home/End jump", {skip}, () => {
  const t = mount()
  t.rightClick(t.$("target"))
  t.key("ArrowDown")
  assert.equal(t.focused(), "m-rename", "the disabled item is skipped")
  t.key("ArrowDown"); t.key("ArrowDown")
  assert.equal(t.focused(), "m-open", "wraps")
  t.key("ArrowUp")
  assert.equal(t.focused(), "m-delete")
  t.key("Home")
  assert.equal(t.focused(), "m-open")
  t.key("End")
  assert.equal(t.focused(), "m-delete")
  t.hook.destroyed()
})

test("typing a letter focuses the next item that starts with it", {skip}, () => {
  const t = mount()
  t.rightClick(t.$("target"))
  t.key("d")
  assert.equal(t.focused(), "m-delete")
  t.hook.destroyed()
})

test("Escape closes and gives the focus back to where it was", {skip}, () => {
  const t = mount()
  t.$("before").focus()
  t.rightClick(t.$("target"))
  assert.equal(t.focused(), "m-open")
  assert.equal(t.key("Escape").defaultPrevented, true)
  assert.equal(t.menu.hidden, true)
  assert.equal(t.focused(), "before")
  t.hook.destroyed()
})

test("Tab closes without stealing the focus back", {skip}, () => {
  const t = mount()
  t.$("before").focus()
  t.rightClick(t.$("target"))
  const ev = t.key("Tab")
  assert.equal(ev.defaultPrevented, false)
  assert.equal(t.menu.hidden, true)
  assert.notEqual(t.focused(), "before", "silent close: the browser's Tab continues from here")
  t.hook.destroyed()
})

test("clicking an enabled item closes; a disabled one does nothing and keeps it open", {skip}, () => {
  const t = mount()
  t.rightClick(t.$("target"))
  t.$("m-off").click()
  assert.equal(t.menu.hidden, false)
  t.$("m-rename").click()
  assert.equal(t.menu.hidden, true)
  t.hook.destroyed()
})

test("a pointerdown outside closes; inside does not", {skip}, () => {
  const t = mount()
  t.rightClick(t.$("target"))
  t.$("m-open").dispatchEvent(new window.Event("pointerdown", {bubbles: true}))
  assert.equal(t.menu.hidden, false)
  t.$("before").dispatchEvent(new window.Event("pointerdown", {bubbles: true}))
  assert.equal(t.menu.hidden, true)
  t.hook.destroyed()
})

test("a second right click moves the menu; one on the menu itself is swallowed", {skip}, () => {
  const t = mount()
  t.rightClick(t.$("target"), 100, 120)
  t.rightClick(t.$("target"), 300, 200)
  assert.equal(t.menu.style.left, "300px")
  assert.equal(t.menu.hidden, false)
  const ev = t.rightClick(t.$("m-open"), 5, 5)
  assert.equal(ev.defaultPrevented, true)
  assert.equal(t.menu.style.left, "300px", "it did not reopen at the click")
  t.hook.destroyed()
})

test("a menu whose items are all disabled does not throw on arrows", {skip}, () => {
  const t = mount()
  for (const id of ["m-open", "m-rename", "m-delete"]) t.$(id).setAttribute("aria-disabled", "true")
  t.rightClick(t.$("target"))
  const press = (k) => t.menu.dispatchEvent(new window.KeyboardEvent("keydown", {key: k, bubbles: true, cancelable: true}))
  assert.doesNotThrow(() => { press("ArrowDown"); press("ArrowUp"); press("Home"); press("End") })
  t.hook.destroyed()
})

test("destroyed closes the menu and removes the listeners", {skip}, () => {
  const t = mount()
  t.rightClick(t.$("target"))
  t.hook.destroyed()
  assert.equal(t.menu.hidden, true)
  const ev = t.rightClick(t.$("target"))
  assert.equal(ev.defaultPrevented, false, "the native menu is back")
})
