// The tabs hook: click, arrows, Home/End, disabled tabs, panels, reporting and patches (#121).
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/tabs_test.mjs
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

let tabs
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/"})
  const w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, CustomEvent: w.CustomEvent})
  tabs = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/tabs.js")))).default
}

const NAMES = ["a", "b", "c", "d"]

// The server markup: `on` is the selected tab, `disabled` the names that cannot be chosen.
function markup({on = "a", disabled = [], vertical = false, attrs = ""} = {}) {
  const tabsHtml = NAMES.map((n) =>
    `<button type="button" role="tab" id="t-tab-${n}" ${disabled.includes(n) ? "disabled" : ""} data-state="${n === on ? "on" : ""}"` +
    ` aria-selected="${n === on}" tabindex="${n === on ? 0 : -1}">${n}</button>`).join("")
  const panels = NAMES.map((n) => `<div role="tabpanel" id="t-panel-${n}" ${n === on ? "" : "hidden"}>panel ${n}</div>`).join("")
  return `<div id="t" ${attrs}><div role="tablist" ${vertical ? 'aria-orientation="vertical"' : ""}>${tabsHtml}</div></div>${panels}`
}

function mount(opts = {}) {
  document.body.innerHTML = markup(opts)
  const el = document.getElementById("t")
  const events = []
  const changes = []
  el.addEventListener("ledger:change", (e) => changes.push(e.detail))
  const hook = Object.assign(Object.create(tabs), {
    el,
    pushEvent(e, p) { events.push([e, p]) },
    pushEventTo(t, e, p) { events.push([e, p, t]) },
    liveSocket: {execJS(_el, code) { events.push(["js", code]) }},
  })
  hook.mounted()
  const $ = (n) => document.getElementById(`t-tab-${n}`)
  const key = (k) => { const ev = new window.KeyboardEvent("keydown", {key: k, bubbles: true, cancelable: true}); document.activeElement.dispatchEvent(ev); return ev }
  return {hook, el, events, changes, $, key,
    on: () => NAMES.filter((n) => $(n).getAttribute("aria-selected") === "true"),
    visible: () => NAMES.filter((n) => !document.getElementById(`t-panel-${n}`).hidden)}
}

test("mount: the server's tab is selected, its panel visible, the others hidden with tabindex -1", {skip}, () => {
  const t = mount({on: "b"})
  assert.deepEqual(t.on(), ["b"])
  assert.deepEqual(t.visible(), ["b"])
  assert.equal(t.$("b").getAttribute("tabindex"), "0")
  assert.equal(t.$("a").getAttribute("tabindex"), "-1")
  assert.equal(t.$("b").getAttribute("data-state"), "on")
  assert.equal(t.$("a").hasAttribute("data-state"), false)
  assert.equal(t.$("c").getAttribute("aria-controls"), "t-panel-c")
  t.hook.destroyed()
})

test("a click selects: aria-selected, data-state, panel, roving tabindex", {skip}, () => {
  const t = mount()
  t.$("c").click()
  assert.deepEqual(t.on(), ["c"])
  assert.deepEqual(t.visible(), ["c"])
  assert.equal(t.$("c").getAttribute("tabindex"), "0")
  assert.equal(t.$("a").getAttribute("tabindex"), "-1")
  t.hook.destroyed()
})

test("a disabled tab cannot be selected", {skip}, () => {
  const t = mount({disabled: ["b"]})
  t.$("b").click()
  assert.deepEqual(t.on(), ["a"])
  t.hook.destroyed()
})

test("ArrowRight/ArrowLeft move focus and selection, wrapping around, and skip disabled tabs", {skip}, () => {
  const t = mount({disabled: ["b"]})
  t.$("a").focus()
  assert.equal(t.key("ArrowRight").defaultPrevented, true)
  assert.equal(document.activeElement, t.$("c"), "b is disabled: goes to c")
  assert.deepEqual(t.on(), ["c"])
  t.key("ArrowRight")
  assert.equal(document.activeElement, t.$("d"))
  t.key("ArrowRight")
  assert.equal(document.activeElement, t.$("a"), "wraps to the first")
  t.key("ArrowLeft")
  assert.equal(document.activeElement, t.$("d"), "and back to the last")
  t.hook.destroyed()
})

test("Home and End go to the first and last tab", {skip}, () => {
  const t = mount({on: "b"})
  t.$("b").focus()
  t.key("End")
  assert.deepEqual(t.on(), ["d"])
  assert.equal(document.activeElement, t.$("d"))
  t.key("Home")
  assert.deepEqual(t.on(), ["a"])
  t.hook.destroyed()
})

test("vertical: ArrowDown/ArrowUp move; ArrowRight does nothing", {skip}, () => {
  const t = mount({vertical: true})
  t.$("a").focus()
  assert.equal(t.key("ArrowRight").defaultPrevented, false)
  assert.deepEqual(t.on(), ["a"])
  t.key("ArrowDown")
  assert.deepEqual(t.on(), ["b"])
  t.key("ArrowUp")
  assert.deepEqual(t.on(), ["a"])
  t.hook.destroyed()
})

test("keys with the focus outside the tabs do nothing", {skip}, () => {
  const t = mount()
  document.body.insertAdjacentHTML("beforeend", '<input id="x">')
  document.getElementById("x").focus()
  const ev = new window.KeyboardEvent("keydown", {key: "ArrowRight", bubbles: true, cancelable: true})
  t.$("a").dispatchEvent(ev)
  assert.equal(ev.defaultPrevented, false)
  assert.deepEqual(t.on(), ["a"])
  t.hook.destroyed()
})

test("a change is reported once: ledger:change, push (to the target) and the JS command; re-selecting is silent", {skip}, () => {
  const t = mount({attrs: 'data-on-change="picked" data-target="#lv" data-on-change-js=\'[["x"]]\''})
  t.$("b").click()
  assert.deepEqual(t.changes, [{id: "t", value: "b", tab: "b"}])
  assert.deepEqual(t.events, [["picked", {id: "t", value: "b", tab: "b"}, "#lv"], ["js", '[["x"]]']])
  t.$("b").click()
  assert.equal(t.changes.length, 1)
  assert.equal(t.events.length, 2)
  t.hook.destroyed()
})

test("a patch keeps the person's tab; a tab the server selects wins", {skip}, () => {
  const t = mount({on: "a"})
  t.$("c").click()
  // The patch hands the DOM back as the server renders it (still "a" selected).
  const fresh = new window.DOMParser().parseFromString(markup({on: "a"}), "text/html").body
  document.getElementById("t").replaceWith(fresh.querySelector("#t"))
  for (const n of NAMES) document.getElementById(`t-panel-${n}`).replaceWith(fresh.querySelector(`#t-panel-${n}`))
  t.hook.el = document.getElementById("t")
  t.hook.updated()
  assert.deepEqual(t.on(), ["c"], "the server still says a: the person's c stays")
  assert.deepEqual(t.visible(), ["c"])
  // now the server changes its selection
  t.$("b").setAttribute("data-state", "on"); t.$("a").setAttribute("data-state", "")
  t.hook.updated()
  assert.deepEqual(t.on(), ["b"], "the server moved to b: it wins")
  t.hook.destroyed()
})

test("destroyed removes the listeners", {skip}, () => {
  const t = mount()
  t.hook.destroyed()
  t.$("c").click()
  assert.deepEqual(t.on(), ["a"])
})

// folder_tabs: the tabs ask the server (`phx-click`) or are links (`data-phx-link`); the arrows activate them by a click
test("folder_tabs: arrows and Home/End click a tab that has phx-click or is a patch link", {skip}, () => {
  document.body.innerHTML =
    `<div id="t"><div role="tablist">` +
    `<button type="button" role="tab" id="t-tab-a" data-state="on" aria-selected="true" tabindex="0" phx-click="tab" phx-value-tab="a">a</button>` +
    `<button type="button" role="tab" id="t-tab-b" aria-selected="false" tabindex="-1" phx-click="tab" phx-value-tab="b">b</button>` +
    `<a role="tab" id="t-tab-c" href="/x?tab=c" data-phx-link="patch" aria-selected="false" tabindex="-1">c</a>` +
    `</div></div>`
  const el = document.getElementById("t")
  const events = []
  const changes = []
  el.addEventListener("ledger:change", (e) => changes.push(e.detail.tab))
  const clicks = []
  for (const n of ["a", "b", "c"]) document.getElementById(`t-tab-${n}`).addEventListener("click", (e) => { e.preventDefault(); clicks.push(n) })
  const hook = Object.assign(Object.create(tabs), {el, pushEvent(e, p) { events.push([e, p]) }, pushEventTo() {}, liveSocket: {execJS() {}}})
  hook.mounted()
  const key = (k) => document.activeElement.dispatchEvent(new window.KeyboardEvent("keydown", {key: k, bubbles: true, cancelable: true}))
  document.getElementById("t-tab-a").focus()
  key("ArrowRight")
  assert.deepEqual(clicks, ["b"], "the arrow clicks the next tab (LiveView pushes phx-click itself)")
  assert.equal(document.getElementById("t-tab-b").getAttribute("aria-selected"), "true")
  assert.deepEqual(events, [], "the hook does not push a second event: no data-on-change")
  key("End")
  assert.deepEqual(clicks, ["b", "c"], "the patch link is clicked, so it is followed")
  key("Home")
  assert.deepEqual(clicks, ["b", "c", "a"])
  assert.deepEqual(changes, ["b", "c", "a"])
  hook.destroyed()
})
