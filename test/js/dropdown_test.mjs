// The dropdown hook: open/close, arrows, Home/End, type-ahead, Escape, Tab, submenus and checkable items (#121).
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/dropdown_test.mjs
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

let dropdown
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/"})
  const w = dom.window
  // jsdom has no layout: every element counts as rendered (the hook skips items with offsetParent null).
  Object.defineProperty(w.HTMLElement.prototype, "offsetParent", {get() { return this.hidden ? null : this.parentNode }})
  Object.assign(globalThis, {window: w, document: w.document, MutationObserver: w.MutationObserver, Event: w.Event,
    HTMLElement: w.HTMLElement, requestAnimationFrame: w.requestAnimationFrame.bind(w), cancelAnimationFrame: w.cancelAnimationFrame.bind(w)})
  dropdown = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/dropdown.js")))).default
}

const item = (id, label, extra = "") => `<button type="button" id="${id}" role="menuitem" data-part="pop-item" ${extra}>${label}</button>`
const MENU = `
  <span id="dd" data-part="dropdown" phx-hook="LedgerUI.Dropdown">
    <button type="button" id="trig">Menu</button>
    <span data-part="dropdown-menu" id="dd-menu" data-lu-placement="bottom-start">
      <div data-part="pop" role="menu">
        ${item("i-apple", "Apple")}
        ${item("i-banana", "Banana")}
        ${item("i-off", "Blueberry", 'aria-disabled="true"')}
        ${item("i-cherry", "Cherry")}
        <div data-dd="sub">
          ${item("i-more", "More")}
          <div data-dd="subpop" role="menu" hidden>${item("s-one", "One")}${item("s-two", "Two")}</div>
        </div>
        <div id="chk" tabindex="-1" role="menuitemcheckbox" aria-checked="false"><input type="checkbox" id="chk-in"><span data-part="pop-check">x</span>Check</div>
      </div>
    </span>
  </span>`

function mount(html = MENU) {
  document.body.innerHTML = `<input id="after">` + html + `<input id="after2">`
  const el = document.getElementById("dd")
  const hook = Object.assign(Object.create(dropdown), {el, liveSocket: {execJS() {}}})
  hook.mounted()
  const $ = (id) => document.getElementById(id)
  const key = (target, k, init = {}) => {
    const ev = new window.KeyboardEvent("keydown", {key: k, bubbles: true, cancelable: true, ...init})
    target.dispatchEvent(ev)
    return ev
  }
  return {hook, el, $, key, trig: $("trig"), focused: () => document.activeElement && document.activeElement.id}
}

test("a click on the trigger opens (class open, aria-expanded, menu shown) and a second click closes", {skip}, () => {
  const t = mount()
  assert.equal(t.trig.getAttribute("aria-haspopup"), "menu")
  assert.equal(t.trig.getAttribute("aria-expanded"), "false")
  assert.equal(t.$("dd-menu").hidden, true)
  t.trig.click()
  assert.ok(t.el.classList.contains("open"))
  assert.equal(t.trig.getAttribute("aria-expanded"), "true")
  assert.equal(t.$("dd-menu").hidden, false)
  t.trig.click()
  assert.ok(!t.el.classList.contains("open"))
  assert.equal(t.trig.getAttribute("aria-expanded"), "false")
  t.hook.destroyed()
})

test("ArrowDown on the trigger opens on the first item, ArrowUp on the last", {skip}, () => {
  const t = mount()
  t.trig.focus()
  const ev = t.key(t.trig, "ArrowDown")
  assert.equal(ev.defaultPrevented, true)
  assert.ok(t.el.classList.contains("open"))
  assert.equal(t.focused(), "i-apple")
  t.hook.close(false)
  t.trig.focus()
  t.key(t.trig, "ArrowUp")
  assert.equal(t.focused(), "chk", "ArrowUp opens on the last item")
  t.hook.destroyed()
})

test("arrows move through the items, skip the disabled one and wrap around", {skip}, () => {
  const t = mount()
  t.hook.open(true)
  assert.equal(t.focused(), "i-apple")
  t.key(t.$("i-apple"), "ArrowDown")
  assert.equal(t.focused(), "i-banana")
  t.key(t.$("i-banana"), "ArrowDown")
  assert.equal(t.focused(), "i-cherry", "aria-disabled is skipped")
  t.key(t.$("i-cherry"), "ArrowUp")
  assert.equal(t.focused(), "i-banana")
  t.key(t.$("i-banana"), "ArrowUp")
  t.key(t.$("i-apple"), "ArrowUp")
  assert.equal(t.focused(), "chk", "wraps to the last")
  t.key(t.$("chk"), "ArrowDown")
  assert.equal(t.focused(), "i-apple", "and back to the first")
  t.hook.destroyed()
})

test("Home and End go to the first and last item", {skip}, () => {
  const t = mount()
  t.hook.open(true)
  t.key(t.$("i-apple"), "End")
  assert.equal(t.focused(), "chk")
  t.key(t.$("chk"), "Home")
  assert.equal(t.focused(), "i-apple")
  t.hook.destroyed()
})

test("typing a letter jumps to the next item that starts with it, wrapping around", {skip}, () => {
  const t = mount()
  t.hook.open(true)
  t.key(t.$("i-apple"), "c")
  assert.equal(t.focused(), "i-cherry")
  t.hook.state.ta = ""
  t.key(t.$("i-cherry"), "a")
  assert.equal(t.focused(), "i-apple", "wraps past the end")
  t.key(t.$("i-apple"), "x", {ctrlKey: true})
  assert.equal(t.focused(), "i-apple", "a chord is not type-ahead")
  t.hook.destroyed()
})

test("type-ahead buffer: 'b' then 'a' reaches Banana, skipping the disabled Blueberry", {skip}, () => {
  const t = mount()
  t.hook.open(true)
  t.key(t.$("i-apple"), "b")
  assert.equal(t.focused(), "i-banana")
  t.key(t.$("i-banana"), "a")
  assert.equal(t.focused(), "i-banana", "'ba' still matches Banana")
  t.hook.destroyed()
})

test("Escape closes and returns focus to the trigger", {skip}, () => {
  const t = mount()
  t.hook.open(true)
  const ev = t.key(t.$("i-banana"), "Escape")
  assert.equal(ev.defaultPrevented, true)
  assert.ok(!t.el.classList.contains("open"))
  assert.equal(t.focused(), "trig")
  t.hook.destroyed()
})

test("Tab closes the menu and puts focus on the trigger, without cancelling the key (the browser moves on from it)", {skip}, () => {
  const t = mount()
  t.hook.open(true)
  assert.equal(t.focused(), "i-apple")
  const ev = t.key(t.$("i-apple"), "Tab")
  assert.equal(ev.defaultPrevented, false, "Tab is not cancelled")
  assert.ok(!t.el.classList.contains("open"))
  assert.equal(t.focused(), "trig", "focus is on the trigger, not <body>")
  t.hook.destroyed()
})

test("Tab hides the menu at once, with no leave animation: its items cannot take the focus (#122)", {skip}, () => {
  const t = mount()
  const menu = t.$("dd-menu")
  let animated = 0
  menu.animate = () => { animated++; return {finished: new Promise(() => {}), cancel() {}} }
  t.hook.open(true)
  animated = 0
  t.key(t.$("i-apple"), "Tab")
  assert.equal(menu.hidden, true, "the panel is hidden when the key is handled")
  assert.equal(animated, 0, "no leave animation on Tab")
  // other ways of closing keep the animation
  t.hook.open(true)
  animated = 0
  t.key(t.$("i-apple"), "Escape")
  assert.equal(animated, 1, "Escape still fades out")
  t.hook.destroyed()
})

test("a click on an item closes the menu and returns focus to the trigger", {skip}, () => {
  const t = mount()
  t.hook.open(true)
  t.$("i-cherry").click()
  assert.ok(!t.el.classList.contains("open"))
  assert.equal(t.focused(), "trig")
  t.hook.destroyed()
})

test("a disabled item does nothing on click and keeps the menu open", {skip}, () => {
  const t = mount()
  t.hook.open(true)
  t.$("i-off").click()
  assert.ok(t.el.classList.contains("open"))
  t.hook.destroyed()
})

test("pointerdown outside closes; inside does not", {skip}, () => {
  const t = mount()
  t.hook.open(false)
  t.$("i-apple").dispatchEvent(new window.Event("pointerdown", {bubbles: true}))
  assert.ok(t.el.classList.contains("open"))
  t.$("after").dispatchEvent(new window.Event("pointerdown", {bubbles: true}))
  assert.ok(!t.el.classList.contains("open"))
  t.hook.destroyed()
})

test("submenu: ArrowRight opens it on its first item, ArrowLeft and Escape close it back to its trigger", {skip}, () => {
  const t = mount()
  t.hook.open(true)
  t.$("i-more").focus()
  t.key(t.$("i-more"), "ArrowRight")
  const subpop = t.el.querySelector('[data-dd="subpop"]')
  assert.equal(subpop.hidden, false)
  assert.equal(t.$("i-more").getAttribute("aria-expanded"), "true")
  assert.equal(t.focused(), "s-one")
  t.key(t.$("s-one"), "ArrowDown")
  assert.equal(t.focused(), "s-two")
  t.key(t.$("s-two"), "ArrowLeft")
  assert.equal(subpop.hidden, true)
  assert.equal(t.focused(), "i-more")
  // Escape in the submenu closes only the submenu
  t.key(t.$("i-more"), "ArrowRight")
  t.key(t.$("s-one"), "Escape")
  assert.equal(subpop.hidden, true)
  assert.ok(t.el.classList.contains("open"), "the root menu stays open")
  assert.equal(t.focused(), "i-more")
  t.hook.destroyed()
})

test("clicking a checkable item toggles aria-checked and the input, and the menu stays open", {skip}, () => {
  const t = mount()
  t.hook.open(false)
  let changes = 0
  t.$("chk-in").addEventListener("change", () => changes++)
  t.$("chk").click()
  assert.equal(t.$("chk").getAttribute("aria-checked"), "true")
  assert.equal(t.$("chk-in").checked, true)
  assert.equal(changes, 1)
  t.$("chk").click()
  assert.equal(t.$("chk").getAttribute("aria-checked"), "false")
  assert.equal(t.$("chk-in").checked, false)
  t.hook.destroyed()
})

test("the open class set from outside (LedgerUI.open) opens the menu; removing it closes", {skip}, async () => {
  const t = mount()
  t.el.classList.add("open")
  await new Promise((r) => setTimeout(r, 0))
  assert.equal(t.hook.isOpen, true)
  assert.equal(t.trig.getAttribute("aria-expanded"), "true")
  t.el.classList.remove("open")
  await new Promise((r) => setTimeout(r, 0))
  assert.equal(t.hook.isOpen, false)
  t.hook.destroyed()
})

test("destroyed removes the document listeners and closes", {skip}, () => {
  const t = mount()
  t.hook.open(false)
  t.hook.destroyed()
  assert.equal(t.hook.isOpen, false)
  assert.ok(!t.el.classList.contains("open"))
})
