// The light tooltips (tip.js, `tip_host/1` + `tip/1`): one delegated hook creates the hint on demand.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/tip_test.mjs
// jsdom is not a dependency of the package: the tests are skipped when it cannot be found.
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
let w
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "http://localhost/"})
  w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, getComputedStyle: w.getComputedStyle.bind(w)})
  const dir = mkdtempSync(join(tmpdir(), "lu-tip-"))
  writeFileSync(join(dir, "tip.mjs"), readFileSync(join(here, "../../priv/static/ledger_ui/hooks/tip.js"), "utf8"))
  hook = (await import(pathToFileURL(join(dir, "tip.mjs")))).default
}

const CLASSES = {neutral: "bg-ink", success: "bg-(--c)"}
let seq = 0
function mount(inner) {
  document.body.innerHTML = ""
  const el = document.createElement("div")
  el.id = "tips" + ++seq
  el.dataset.luFloatClass = "FLOAT"
  el.dataset.luTipClasses = JSON.stringify(CLASSES)
  el.innerHTML = inner
  document.body.append(el)
  const h = Object.assign(Object.create(hook), {el})
  h.mounted()
  const fire = (target, type, init = {}) => target.dispatchEvent(new w.MouseEvent(type, {bubbles: true, ...init}))
  return {h, el, fire,
    panel: () => el.querySelector("[role=tooltip]"),
    enter: (t) => fire(t, "mouseover", {relatedTarget: document.body}),
    leave: (t) => fire(t, "mouseout", {relatedTarget: document.body})}
}

const ONE = '<span data-lu-tip="Save the draft"><button id="b">Save</button></span>'

test("nothing is in the DOM until the pointer enters the trigger", {skip}, () => {
  const t = mount(ONE)
  assert.equal(t.panel(), null)
  assert.equal(document.getElementById("b").hasAttribute("aria-describedby"), false)
})

test("hover creates the hint with the same markup as the tooltip and links it with aria-describedby", {skip}, () => {
  const t = mount(ONE)
  const b = document.getElementById("b")
  t.enter(b)
  const p = t.panel()
  assert.ok(p)
  assert.equal(p.getAttribute("role"), "tooltip")
  assert.equal(p.getAttribute("data-part"), "tooltip-float")
  assert.equal(p.hasAttribute("data-lu-fl"), true)
  assert.equal(p.getAttribute("data-lu-placement"), "top")
  assert.equal(p.className, "FLOAT")
  const tip = p.querySelector("[data-part=tooltip-tip]")
  assert.equal(tip.className, "bg-ink")
  assert.equal(tip.firstChild.textContent, "Save the draft")
  assert.equal(b.getAttribute("aria-describedby"), p.id)
  assert.equal(b.parentElement, p.parentElement, "the hint lives inside the trigger's wrapper")
})

test("leaving removes the hint and the aria-describedby", {skip}, () => {
  const t = mount(ONE)
  const b = document.getElementById("b")
  t.enter(b)
  t.leave(b)
  assert.equal(t.panel(), null)
  assert.equal(b.hasAttribute("aria-describedby"), false)
})

test("moving between the trigger and its own hint keeps it open", {skip}, () => {
  const t = mount(ONE)
  const b = document.getElementById("b")
  t.enter(b)
  t.fire(b, "mouseout", {relatedTarget: t.panel()})
  assert.ok(t.panel())
})

test("keyboard focus shows it and blur hides it", {skip}, () => {
  const t = mount(ONE)
  const b = document.getElementById("b")
  t.fire(b, "focusin")
  assert.ok(t.panel())
  t.fire(b, "focusout", {relatedTarget: document.body})
  assert.equal(t.panel(), null)
})

test("Esc closes it", {skip}, () => {
  const t = mount(ONE)
  t.enter(document.getElementById("b"))
  document.dispatchEvent(new w.KeyboardEvent("keydown", {key: "Escape", bubbles: true}))
  assert.equal(t.panel(), null)
  assert.equal(document.getElementById("b").hasAttribute("aria-describedby"), false)
})

test("an existing aria-describedby is kept and restored", {skip}, () => {
  const t = mount('<span data-lu-tip="x"><button id="b" aria-describedby="other">B</button></span>')
  const b = document.getElementById("b")
  t.enter(b)
  assert.equal(b.getAttribute("aria-describedby"), "other " + t.panel().id)
  t.leave(b)
  assert.equal(b.getAttribute("aria-describedby"), "other")
})

test("placement, colour and arrow come from the trigger's attributes", {skip}, () => {
  const t = mount('<span data-lu-tip="x" data-lu-tip-placement="bottom-end" data-lu-tip-color="success"><button id="b">B</button></span>')
  t.enter(document.getElementById("b"))
  const p = t.panel()
  assert.equal(p.getAttribute("data-lu-placement"), "bottom-end")
  const tip = p.querySelector("[data-part=tooltip-tip]")
  assert.equal(tip.className, "bg-(--c)")
  const arrow = tip.querySelector("[data-lu-arrow-el]")
  assert.ok(arrow)
  assert.equal(arrow.getAttribute("aria-hidden"), "true")
  assert.equal(arrow.style.top, "-5px")
  assert.equal(arrow.style.right, "14px")
})

test("arrow=false draws no arrow; an unknown colour falls back to neutral", {skip}, () => {
  const t = mount('<span data-lu-tip="x" data-lu-tip-arrow="false" data-lu-tip-color="nope"><button id="b">B</button></span>')
  t.enter(document.getElementById("b"))
  assert.equal(t.panel().querySelector("[data-lu-arrow-el]"), null)
  assert.equal(t.panel().querySelector("[data-part=tooltip-tip]").className, "bg-ink")
})

test("only one hint at a time", {skip}, () => {
  const t = mount('<span data-lu-tip="A"><button id="a">A</button></span><span data-lu-tip="B"><button id="b">B</button></span>')
  t.enter(document.getElementById("a"))
  t.enter(document.getElementById("b"))
  assert.equal(t.el.querySelectorAll("[role=tooltip]").length, 1)
  assert.equal(t.panel().textContent, "B")
  assert.equal(document.getElementById("a").hasAttribute("aria-describedby"), false)
})

test("delay: the hint appears after it, and not at all if the pointer left first", {skip}, async () => {
  const t = mount('<span data-lu-tip="x" data-lu-tip-delay="30"><button id="b">B</button></span>')
  const b = document.getElementById("b")
  t.enter(b)
  assert.equal(t.panel(), null)
  await new Promise((r) => setTimeout(r, 60))
  assert.ok(t.panel())
  t.leave(b)
  t.enter(b)
  t.leave(b)
  await new Promise((r) => setTimeout(r, 60))
  assert.equal(t.panel(), null)
})

test("the text is text, never HTML", {skip}, () => {
  const t = mount('<span data-lu-tip="<img src=x onerror=1>"><button id="b">B</button></span>')
  t.enter(document.getElementById("b"))
  assert.equal(t.panel().querySelector("img"), null)
  assert.equal(t.panel().textContent, "<img src=x onerror=1>")
})

test("a patch that drops the hint gets it back; a new text is followed", {skip}, () => {
  const t = mount(ONE)
  const b = document.getElementById("b")
  t.enter(b)
  const p = t.panel()
  p.remove()
  t.h.updated()
  assert.equal(t.panel(), p)
  b.parentElement.setAttribute("data-lu-tip", "New text")
  t.h.updated()
  assert.equal(t.panel().textContent, "New text")
})

test("a trigger that left the DOM closes the hint on update", {skip}, () => {
  const t = mount(ONE)
  t.enter(document.getElementById("b"))
  document.getElementById("b").parentElement.remove()
  t.h.updated()
  assert.equal(t.h.cur, null)
})

test("destroyed removes the hint and every listener", {skip}, () => {
  const t = mount(ONE)
  t.enter(document.getElementById("b"))
  t.h.destroyed()
  assert.equal(t.panel(), null)
  t.enter(document.getElementById("b"))
  assert.equal(t.panel(), null)
})

test("elements outside the host are ignored", {skip}, () => {
  const t = mount(ONE)
  const out = document.createElement("span")
  out.setAttribute("data-lu-tip", "x")
  out.innerHTML = "<button id='o'>o</button>"
  document.body.append(out)
  t.enter(document.getElementById("o"))
  assert.equal(document.querySelector("[role=tooltip]"), null)
})

test("a scroll while the trigger is in view keeps the hint (the browser scrolls it into view on the first hover)", {skip}, () => {
  const t = mount(ONE)
  t.enter(document.getElementById("b"))
  window.dispatchEvent(new w.Event("scroll"))
  document.dispatchEvent(new w.Event("scroll", {bubbles: true}))
  assert.ok(t.panel())
})

test("a scroll that takes the trigger out of the viewport closes it", {skip}, () => {
  const t = mount(ONE)
  const b = document.getElementById("b")
  b.getBoundingClientRect = () => ({top: -100, bottom: -50, left: 0, right: 10})
  b.parentElement.getBoundingClientRect = b.getBoundingClientRect
  t.enter(b)
  window.dispatchEvent(new w.Event("scroll"))
  assert.equal(t.panel(), null)
})
