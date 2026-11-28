// popover, tooltip, collapse and fab_dial keep what the person did when the server re-renders them (#128).
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/patch_state_test.mjs
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

const instance = (hook, el) => Object.assign(Object.create(hook), {el, pushEvent() {}, pushEventTo() {}})
const tick = () => new Promise((r) => setTimeout(r, 0))

const popoverHtml = (extra = "") =>
  `<span id="pop" data-lu-kind="popover" data-lu-trigger="click" data-lu-open="false" ${extra}>` +
  '<button id="t" aria-haspopup="dialog" aria-expanded="false" aria-controls="pop-panel">Open</button>' +
  '<span id="pop-panel" data-lu-fl="" hidden>body</span></span>'

// what a LiveView patch does to a root the server re-rendered with the same attributes
function patchPopover(el) {
  el.className = ""
  const t = el.querySelector("#t")
  t.setAttribute("aria-expanded", "false")
  el.querySelector("[data-lu-fl]").hidden = true
}

test("popover: a patch with the same server state keeps it open (class, aria-expanded, panel)", {skip}, async () => {
  document.body.innerHTML = popoverHtml()
  const el = document.getElementById("pop")
  const h = instance(Float, el)
  h.mounted()
  document.getElementById("t").click()
  assert.ok(el.classList.contains("open"))
  patchPopover(el)
  h.updated()
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
  h.updated()
  await tick()
  assert.equal(el.classList.contains("open"), false)
  assert.equal(el.querySelector("[data-lu-fl]").hidden, true)
  h.destroyed()
})

test("popover: the server changing data-lu-open still wins", {skip}, async () => {
  document.body.innerHTML = popoverHtml()
  const el = document.getElementById("pop")
  const h = instance(Float, el)
  h.mounted()
  document.getElementById("t").click()
  patchPopover(el)
  el.setAttribute("data-lu-open", "true")
  h.updated()
  await tick()
  assert.ok(el.classList.contains("open"))
  el.className = ""
  el.setAttribute("data-lu-open", "false")
  h.updated()
  await tick()
  assert.equal(el.classList.contains("open"), false)
  assert.equal(h.isOpen, false)
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
  document.body.innerHTML =
    '<span id="tt" data-lu-kind="tooltip" data-lu-trigger="hover"><button id="b">x</button>' +
    '<span id="tt-tip" role="tooltip" data-lu-fl="" hidden>hint</span></span>'
  const el = document.getElementById("tt")
  const h = instance(Float, el)
  h.mounted()
  el.dispatchEvent(new window.MouseEvent("mouseenter"))
  assert.ok(el.classList.contains("open"))
  el.className = ""
  el.querySelector("[data-lu-fl]").hidden = true
  h.updated()
  await tick()
  assert.ok(el.classList.contains("open"))
  assert.equal(el.querySelector("[data-lu-fl]").hidden, false)
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
  el.removeAttribute("open") // the patch
  el.className = ""
  h.updated()
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
  el.setAttribute("open", "") // the patch brings the server's open back
  h.updated()
  await tick()
  assert.equal(el.open, false)
  el.setAttribute("data-lu-open", "true")
  h.updated()
  await tick()
  assert.equal(el.open, true)
  h.destroyed()
})

test("fab_dial: updated restores aria-expanded from data-state", {skip}, () => {
  document.body.innerHTML =
    '<div id="fd" data-state="open"><button data-part="fab-dial-button" aria-expanded="false"></button></div>'
  const el = document.getElementById("fd")
  const h = instance(FabDial, el)
  h.mounted()
  h.updated()
  assert.equal(el.querySelector("button").getAttribute("aria-expanded"), "true")
  el.setAttribute("data-state", "closed")
  h.updated()
  assert.equal(el.querySelector("button").getAttribute("aria-expanded"), "false")
  h.destroyed()
})
