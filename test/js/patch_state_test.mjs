// popover, tooltip, collapse and fab_dial keep what the person did when the server re-renders them (#128),
// with no `dom: {onBeforeElUpdated}` in the LiveSocket (#123): the hooks use `this.js()` (ignoreAttributes
// and the sticky commands). `fakeLV` (support/fake_lv.mjs) stands in for the LiveView client: it keeps what
// those commands registered and applies it to the re-rendered element, like a patch does.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/patch_state_test.mjs
import {test} from "node:test"
import assert from "node:assert/strict"
import {createRequire} from "node:module"
import {join, dirname} from "node:path"
import {fileURLToPath, pathToFileURL} from "node:url"

import {fakeLV} from "./support/fake_lv.mjs"

const here = dirname(fileURLToPath(import.meta.url))
const require = createRequire(import.meta.url)

let JSDOM
for (const p of [process.env.JSDOM_PATH, "jsdom"].filter(Boolean)) {
  try { ({JSDOM} = require(p)); break } catch (_) { /* try the next */ }
}
const skip = JSDOM ? false : "jsdom not found (set JSDOM_PATH)"

let Float, Collapse, FabDial
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/"})
  const w = dom.window
  w.matchMedia = () => ({matches: true, addEventListener() {}, removeEventListener() {}})
  Object.assign(globalThis, {window: w, document: w.document, MutationObserver: w.MutationObserver, Event: w.Event, CSS: {escape: (s) => s}})
  const load = async (name) => (await import(pathToFileURL(join(here, `../../priv/static/ledger_ui/hooks/${name}.js`)))).default
  Float = await load("float")
  Collapse = await load("collapse")
  FabDial = await load("fab_dial")
}

const lv = fakeLV()
const instance = (hook, el) => lv.hook(hook, el)
const tick = () => new Promise((r) => setTimeout(r, 0))
const html = (h) => {
  const t = document.createElement("template")
  t.innerHTML = h
  return t.content.firstElementChild
}

const popoverHtml = (extra = "") =>
  `<span id="pop" data-lu-kind="popover" data-lu-trigger="click" data-lu-open="false" ${extra}>` +
  '<button id="t" aria-haspopup="dialog" aria-expanded="false" aria-controls="pop-panel">Open</button>' +
  '<span id="pop-panel" data-lu-fl="" hidden>body</span></span>'

// what a LiveView patch does to a root the server re-rendered with the same attributes
const patch = (el, markup, hook) => {
  lv.patch(el, html(markup))
  hook.updated()
}

test("popover: a patch with the same server state keeps it open (class, aria-expanded, panel)", {skip}, async () => {
  document.body.innerHTML = popoverHtml()
  const el = document.getElementById("pop")
  const h = instance(Float, el)
  h.mounted()
  document.getElementById("t").click()
  assert.ok(el.classList.contains("open"))
  patch(el, popoverHtml(), h)
  await tick() // the observer must not read the patch's class as a close
  assert.ok(el.classList.contains("open"))
  assert.equal(h.isOpen, true)
  assert.equal(document.getElementById("t").getAttribute("aria-expanded"), "true")
  assert.equal(el.querySelector("[data-lu-fl]").hidden, false)
  h.destroyed()
})

test("popover: a patch keeps it closed when the person had closed it", {skip}, async () => {
  document.body.innerHTML = popoverHtml()
  const el = document.getElementById("pop")
  const h = instance(Float, el)
  h.mounted()
  document.getElementById("t").click()
  document.getElementById("t").click() // open, then closed again
  await tick()
  patch(el, popoverHtml(), h)
  await tick()
  assert.equal(el.classList.contains("open"), false)
  assert.equal(document.getElementById("t").getAttribute("aria-expanded"), "false")
  assert.equal(el.querySelector("[data-lu-fl]").hidden, true)
  h.destroyed()
})

test("popover: the server changing data-lu-open still wins", {skip}, async () => {
  document.body.innerHTML = popoverHtml()
  const el = document.getElementById("pop")
  const h = instance(Float, el)
  h.mounted()
  document.getElementById("t").click()
  patch(el, popoverHtml(), h)
  el.setAttribute("data-lu-open", "true")
  h.updated()
  await tick()
  assert.ok(el.classList.contains("open"))
  patch(el, popoverHtml().replace('data-lu-open="false"', 'data-lu-open="false"'), h)
  el.setAttribute("data-lu-open", "false")
  h.updated()
  await tick()
  assert.equal(el.classList.contains("open"), false)
  assert.equal(h.isOpen, false)
  h.destroyed()
})

test("popover: the panel's position (style) survives a patch", {skip}, async () => {
  document.body.innerHTML = popoverHtml()
  const el = document.getElementById("pop")
  const h = instance(Float, el)
  h.mounted()
  const fl = el.querySelector("[data-lu-fl]")
  fl.style.cssText = "top: 40px; left: 12px;"
  patch(el, popoverHtml(), h)
  assert.equal(fl.style.cssText, "top: 40px; left: 12px;")
  h.destroyed()
})

test("tooltip: aria-describedby comes back after a patch removed it", {skip}, async () => {
  document.body.innerHTML =
    '<span id="tt" data-lu-kind="tooltip" data-lu-trigger="hover"><button id="b">x</button>' +
    '<span id="tt-tip" role="tooltip" data-lu-fl="" hidden>hint</span></span>'
  const el = document.getElementById("tt")
  const h = instance(Float, el)
  h.mounted()
  const b = document.getElementById("b")
  assert.equal(b.getAttribute("aria-describedby"), "tt-tip")
  b.removeAttribute("aria-describedby") // the patch gave the trigger back without it
  h.updated()
  assert.equal(b.getAttribute("aria-describedby"), "tt-tip")
  h.destroyed()
})

test("tooltip: an open tooltip stays open after a patch", {skip}, async () => {
  const tip =
    '<span id="tt" data-lu-kind="tooltip" data-lu-trigger="hover"><button id="b">x</button>' +
    '<span id="tt-tip" role="tooltip" data-lu-fl="" hidden>hint</span></span>'
  document.body.innerHTML = tip
  const el = document.getElementById("tt")
  const h = instance(Float, el)
  h.mounted()
  el.dispatchEvent(new window.MouseEvent("mouseenter"))
  assert.ok(el.classList.contains("open"))
  patch(el, tip, h)
  await tick()
  assert.ok(el.classList.contains("open"))
  assert.equal(el.querySelector("[data-lu-fl]").hidden, false)
  h.destroyed()
})

test("popover: a class that LedgerUI.open set (a JS command) is dropped when the person closes it", {skip}, async () => {
  document.body.innerHTML = popoverHtml()
  const el = document.getElementById("pop")
  const h = instance(Float, el)
  h.mounted()
  lv.js().addClass(el, "open") // LedgerUI.open("pop") runs this, sticky
  await tick()
  assert.equal(h.isOpen, true)
  document.getElementById("t").click() // the person closes it
  await tick()
  patch(el, popoverHtml(), h)
  await tick()
  assert.equal(el.classList.contains("open"), false, "a patch must not bring the old sticky class back")
  h.destroyed()
})

const detailsHtml = (open) =>
  `<details id="col" data-lu-kind="collapse" data-lu-open="false"${open ? " open" : ""}><summary>s</summary>body</details>`

test("collapse: a patch that closes the <details> does not close what the person opened", {skip}, async () => {
  document.body.innerHTML = detailsHtml(false)
  const el = document.getElementById("col")
  const h = instance(Collapse, el)
  h.mounted()
  el.open = true
  await tick() // toggle event mirrors the state
  assert.ok(el.classList.contains("open"))
  patch(el, detailsHtml(false), h)
  await tick()
  assert.equal(el.open, true)
  assert.ok(el.classList.contains("open"))
  h.destroyed()
})

test("collapse: a patch keeps it closed when the person closed it, and the server's open still wins", {skip}, async () => {
  document.body.innerHTML = detailsHtml(true)
  const el = document.getElementById("col")
  const h = instance(Collapse, el)
  h.mounted()
  el.open = false
  await tick()
  patch(el, detailsHtml(true), h) // the patch brings the server's open back
  await tick()
  assert.equal(el.open, false)
  el.setAttribute("data-lu-open", "true")
  h.updated()
  await tick()
  assert.equal(el.open, true)
  h.destroyed()
})

const itemHtml = (on) =>
  `<div id="ac" data-part="accordion-item" data-lu-kind="item" data-state="${on ? "open" : "closed"}" class="item${on ? " on open" : ""}">` +
  '<div id="ac-h" data-part="accordion-header" aria-expanded="' + (on ? "true" : "false") + '"><span data-part="accordion-chevron"></span></div>' +
  `<div id="ac-b" data-part="accordion-body" style="${on ? "" : "display: none;"}">b</div></div>`

test("accordion: a patch keeps the item the person opened (class, data-state, aria-expanded, body)", {skip}, async () => {
  document.body.innerHTML = itemHtml(false)
  const el = document.getElementById("ac")
  const h = instance(Collapse, el)
  h.mounted()
  el.querySelector("[data-part=accordion-header]").click()
  await tick()
  assert.ok(el.classList.contains("open"))
  patch(el, itemHtml(false), h)
  await tick()
  assert.ok(el.classList.contains("on"))
  assert.equal(el.getAttribute("data-state"), "open")
  assert.equal(el.querySelector("[data-part=accordion-header]").getAttribute("aria-expanded"), "true")
  assert.equal(el.querySelector("[data-part=accordion-body]").style.display, "")
  h.destroyed()
})

const dialHtml = (state) =>
  `<div id="fd" data-state="${state}"><button data-part="fab-dial-button" aria-expanded="${state === "open"}"></button>` +
  '<a role="menuitem" href="#">a</a></div>'

test("fab_dial: a patch keeps data-state and aria-expanded of what the person did", {skip}, () => {
  document.body.innerHTML = dialHtml("closed")
  const el = document.getElementById("fd")
  const h = instance(FabDial, el)
  h.mounted()
  el.querySelector("button").click()
  assert.equal(el.getAttribute("data-state"), "open")
  lv.patch(el, html(dialHtml("closed"))) // the server draws it closed again
  assert.equal(el.getAttribute("data-state"), "open")
  assert.equal(el.querySelector("button").getAttribute("aria-expanded"), "true")
  el.querySelector("button").click()
  lv.patch(el, html(dialHtml("open")))
  assert.equal(el.getAttribute("data-state"), "closed")
  assert.equal(el.querySelector("button").getAttribute("aria-expanded"), "false")
  h.destroyed()
})
