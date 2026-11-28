// What the client decided survives a server patch with no `dom: {onBeforeElUpdated}` (#123): lib/keep.js,
// the sidebar groups, tabs, shell, overlay, dropdown and the `ledger:js` event of LedgerUI.open/close(socket, id).
// `fakeLV` (support/fake_lv.mjs) stands in for the LiveView client (ignoreAttributes + sticky commands).
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/keep_state_test.mjs
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

let keep, stickAttr, stickClass, Sidebar, Tabs, Shell, Overlay, Dropdown, LandingNav
const listeners = {}
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/"})
  const w = dom.window
  w.matchMedia = () => ({matches: true, addEventListener() {}, removeEventListener() {}})
  const origAdd = w.addEventListener.bind(w)
  w.addEventListener = (type, fn, o) => { (listeners[type] = listeners[type] || []).push(fn); return origAdd(type, fn, o) }
  Object.assign(globalThis, {
    window: w, document: w.document, MutationObserver: w.MutationObserver, Event: w.Event, CustomEvent: w.CustomEvent,
    CSS: {escape: (s) => s}, localStorage: w.localStorage, requestAnimationFrame: (f) => setTimeout(f, 0), cancelAnimationFrame: clearTimeout,
  })
  const base = (p) => pathToFileURL(join(here, "../../priv/static/ledger_ui/", p)).href
  ;({keep, stickAttr, stickClass} = await import(base("lib/keep.js")))
  Sidebar = (await import(base("hooks/sidebar.js"))).default
  Tabs = (await import(base("hooks/tabs.js"))).default
  Shell = (await import(base("hooks/shell.js"))).default
  Overlay = (await import(base("hooks/overlay.js"))).default
  Dropdown = (await import(base("hooks/dropdown.js"))).default
  LandingNav = (await import(base("hooks/landing_nav.js"))).default
  await import(base("base.js"))
}

const lv = fakeLV()
const tick = () => new Promise((r) => setTimeout(r, 0))
const html = (h) => {
  const t = document.createElement("template")
  t.innerHTML = h
  return t.content.firstElementChild
}

test("keep/stickAttr/stickClass go through this.js() and fall back to the DOM without it", {skip}, () => {
  document.body.innerHTML = '<div id="a" class="x"></div>'
  const el = document.getElementById("a")
  const hook = lv.hook({}, el)
  keep(hook, el, ["style"])
  stickAttr(hook, el, "hidden", true)
  stickAttr(hook, el, "data-x", "1")
  assert.equal(el.getAttribute("hidden"), "")
  lv.patch(el, html('<div id="a" class="x" data-x="2"></div>'))
  assert.equal(el.hasAttribute("hidden"), true, "sticky attribute comes back")
  assert.equal(el.getAttribute("data-x"), "1")
  stickAttr(hook, el, "hidden", null)
  lv.patch(el, html('<div id="a" class="x" hidden></div>'))
  assert.equal(el.hasAttribute("hidden"), false, "a sticky removal wins over the server")
  // no js(): plain DOM
  const bare = {}
  stickClass(bare, el, "open", true)
  assert.ok(el.classList.contains("open"))
  stickAttr(bare, el, "data-y", "2")
  assert.equal(el.getAttribute("data-y"), "2")
  keep(bare, el, ["style"]) // nothing to do, does not throw
  keep(hook, null, ["style"])
})

test("stickClass does nothing when the class is already as asked or a call for it is pending", {skip}, () => {
  document.body.innerHTML = '<div id="a" class="open"></div>'
  const el = document.getElementById("a")
  const calls = []
  const js = {addClass: (e, n) => calls.push(["add", n]), removeClass: (e, n) => calls.push(["remove", n])}
  const hook = {js: () => js}
  stickClass(hook, el, "open", true)
  assert.deepEqual(calls, [])
  stickClass(hook, el, "open", false)
  stickClass(hook, el, "open", false) // pending (LiveView applies it in the next frame)
  assert.deepEqual(calls, [["remove", "open"]])
  stickClass(hook, el, "open", true) // the person changed their mind before the frame
  assert.deepEqual(calls, [["remove", "open"], ["add", "open"]])
})

const sidebarHtml = (open) =>
  '<aside id="sb" phx-hook="x" data-lu-groups="true" data-lu-persist="false"><button data-lu-sb-group="g" aria-controls="sb-g" aria-expanded="' + open +
  '">g</button><div id="sb-g"' + (open ? "" : " hidden") + '>items</div>' +
  '<a data-lu-sb-parent="p" aria-expanded="false">p</a><a data-lu-sb-child="p" hidden>c</a></aside>'

test("sidebar: a group and a parent the person opened stay open after a patch, aria-expanded included", {skip}, () => {
  document.body.innerHTML = sidebarHtml(false)
  const el = document.getElementById("sb")
  const h = lv.hook(Sidebar, el)
  h.mounted()
  el.querySelector("[data-lu-sb-group]").click()
  el.querySelector("[data-lu-sb-parent]").click()
  assert.equal(document.getElementById("sb-g").hidden, false)
  lv.patch(el, html(sidebarHtml(false)))
  h.updated()
  assert.equal(document.getElementById("sb-g").hidden, false)
  assert.equal(el.querySelector("[data-lu-sb-group]").getAttribute("aria-expanded"), "true")
  assert.equal(el.querySelector("[data-lu-sb-parent]").getAttribute("aria-expanded"), "true")
  assert.equal(el.querySelector("[data-lu-sb-child]").hidden, false)
  h.destroyed()
})

test("sidebar: collapsed and mobile-open (attributes of the root) survive a patch", {skip}, () => {
  document.body.innerHTML = sidebarHtml(false)
  const el = document.getElementById("sb")
  const h = lv.hook(Sidebar, el)
  h.mounted()
  h.setCollapsed(true)
  h.toggleMobile()
  lv.patch(el, html(sidebarHtml(false)))
  assert.equal(el.hasAttribute("data-collapsed"), true)
  assert.equal(el.hasAttribute("data-mobile-open"), true)
  h.destroyed()
})

test("tabs: the panel the person chose is shown after a patch", {skip}, () => {
  const tabsHtml = (sel) =>
    '<div id="t"><div role="tablist"><button role="tab" id="t-tab-a" data-lu-tab="a" data-state="' + (sel === "a" ? "on" : "") + '">a</button>' +
    '<button role="tab" id="t-tab-b" data-lu-tab="b" data-state="' + (sel === "b" ? "on" : "") + '">b</button></div>' +
    '<div id="t-panel-a" role="tabpanel"' + (sel === "a" ? "" : " hidden") + '>A</div><div id="t-panel-b" role="tabpanel"' + (sel === "b" ? "" : " hidden") + ">B</div></div>"
  document.body.innerHTML = tabsHtml("a")
  const el = document.getElementById("t")
  const panel = (n) => document.getElementById(`t-panel-${n}`)
  const h = lv.hook(Tabs, el)
  h.mounted()
  h.select(document.getElementById("t-tab-b"), true)
  assert.equal(panel("b").hidden, false)
  lv.patch(el, html(tabsHtml("a")))
  h.updated()
  assert.equal(panel("b").hidden, false)
  assert.equal(panel("a").hidden, true)
  h.destroyed()
})

test("shell: the open and is-sidebar-open classes survive a patch that redraws the root", {skip}, async () => {
  const shellHtml = (cls) => `<div id="sh" data-lu-layout="sidebar" data-lu-persist="false" data-lu-open="false" class="${cls}"></div>`
  document.body.innerHTML = shellHtml("shell")
  const el = document.getElementById("sh")
  const h = lv.hook(Shell, el)
  h.mounted()
  h.set(true, false)
  await tick()
  assert.ok(el.classList.contains("open"))
  lv.patch(el, html(shellHtml("shell")))
  h.updated()
  await tick()
  assert.ok(el.classList.contains("open") && el.classList.contains("is-sidebar-open"))
  assert.equal(h.open, true)
  h.destroyed()
})

const modalHtml = '<div id="m" data-lu-overlay data-lu-kind="modal" data-lu-open="false" data-lu-overlay-attr="" data-state="closed" class="modal"><div>card</div></div>'

test("overlay: opened by LedgerUI.open (sticky JS), kept by a patch, closed by Esc/backdrop and not reopened by the next patch", {skip}, async () => {
  document.body.innerHTML = modalHtml
  const el = document.getElementById("m")
  const h = lv.hook(Overlay, el)
  h.mounted()
  lv.js().addClass(el, "open") // what the ledger:js event runs through execJS
  await tick()
  assert.equal(h.isOpen, true)
  lv.patch(el, html(modalHtml))
  h.updated()
  await tick()
  assert.ok(el.classList.contains("open"), "a patch keeps it open")
  assert.equal(el.getAttribute("data-state"), "open")
  h.close() // Esc / backdrop / close button
  await tick()
  assert.equal(h.isOpen, false)
  lv.patch(el, html(modalHtml))
  h.updated()
  await tick()
  assert.equal(el.classList.contains("open"), false, "the old sticky add must not reopen it")
  h.destroyed()
})

test("dropdown: the menu keeps open/hidden/style through ignoreAttributes and the root class is sticky", {skip}, async () => {
  const ddHtml = '<span id="dd" data-part="dropdown"><button id="b">t</button><span id="dd-menu" data-part="dropdown-menu" hidden><div data-part="pop" role="menu"></div></span></span>'
  document.body.innerHTML = ddHtml
  const el = document.getElementById("dd")
  const h = lv.hook(Dropdown, el)
  h.mounted()
  h.open(false)
  await tick()
  const menu = document.getElementById("dd-menu")
  assert.equal(menu.hidden, false)
  menu.style.setProperty("--probe", "10px")
  lv.patch(el, html(ddHtml))
  h.updated()
  await tick()
  assert.equal(menu.hidden, false)
  assert.equal(menu.style.getPropertyValue("--probe"), "10px")
  assert.ok(el.classList.contains("open"))
  assert.equal(document.getElementById("b").getAttribute("aria-expanded"), "true")
  h.close(false, true)
  await tick()
  lv.patch(el, html(ddHtml))
  h.updated()
  assert.equal(el.classList.contains("open"), false)
  h.destroyed()
})

test("landing nav: the mega menu panel the hook opened keeps its display after a patch", {skip}, () => {
  const navHtml = '<nav id="ln" data-lu-open-on="click"><a data-lnav-trigger="0" aria-expanded="false">m</a><div data-lnav-panel="0" style="display:none"><div>mega</div></div></nav>'
  document.body.innerHTML = navHtml
  const el = document.getElementById("ln")
  const h = lv.hook(LandingNav, el)
  h.mounted()
  h.open("0")
  const panel = el.querySelector("[data-lnav-panel]")
  assert.equal(panel.style.display, "contents")
  lv.patch(el, html(navHtml))
  h.updated()
  assert.equal(panel.style.display, "contents")
  assert.equal(el.querySelector("[data-lnav-trigger]").getAttribute("aria-expanded"), "true")
  h.destroyed()
})

test("ledger:js event runs the encoded command with liveSocket.execJS, and falls back to the class without it", {skip}, () => {
  document.body.innerHTML = '<div id="dlg"></div><button aria-controls="dlg" aria-expanded="false"></button>'
  const ops = [["add_class", {names: ["open"], to: "#dlg"}]]
  const fire = (detail) => listeners["phx:ledger:js"].forEach((fn) => fn({detail}))
  const calls = []
  window.liveSocket = {execJS: (el, js) => calls.push([el.id, js])}
  fire({id: "dlg", open: true, js: ops})
  assert.deepEqual(calls, [["dlg", ops]])
  assert.equal(document.getElementById("dlg").classList.contains("open"), false, "LiveView applies it, not the glue")
  delete window.liveSocket
  fire({id: "dlg", open: true, js: ops})
  assert.ok(document.getElementById("dlg").classList.contains("open"))
  assert.equal(document.querySelector("button").getAttribute("aria-expanded"), "true")
  fire({id: "dlg", open: false, js: ops})
  assert.equal(document.getElementById("dlg").classList.contains("open"), false)
  fire({id: "missing", open: true, js: ops}) // no element: nothing happens
  // the events of the earlier versions still work
  listeners["phx:ledger:open"].forEach((fn) => fn({detail: {id: "dlg"}}))
  assert.ok(document.getElementById("dlg").classList.contains("open"))
})
