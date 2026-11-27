// The command palette's `defer_items` mode (overlay.js): the server sends no rows; the hook builds them
// from the compact JSON when the palette opens. Run in a jsdom document.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/palette_defer_test.mjs
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
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "http://localhost/"})
  const w = dom.window
  Object.assign(globalThis, {
    window: w, document: w.document, getComputedStyle: w.getComputedStyle.bind(w),
    MutationObserver: w.MutationObserver, MouseEvent: w.MouseEvent, CSS: {escape: (s) => s},
  })
  w.Element.prototype.scrollIntoView = () => {}
  const dir = mkdtempSync(join(tmpdir(), "lu-palette-"))
  writeFileSync(join(dir, "overlay.mjs"), readFileSync(join(here, "../../priv/static/ledger_ui/hooks/overlay.js"), "utf8"))
  hook = (await import(pathToFileURL(join(dir, "overlay.mjs")))).default
}

const SVG_CLASS = "inline size-[18px]"
const ITEMS = {
  r: [
    {l: "Orders", n: "/orders", i: "cart", sc: "pages", kw: "sales", k: ["G", "O"], g: "Go to"},
    {l: "Invoices", p: "/inv", sc: "pages", c: 3},
    {l: "Docs", h: "https://x.y", a: ["CD", "#d97a1e"]},
    {l: "New order", v: "new-order", sc: "actions", i: "plus", s: "Opens the form", st: "color:red", g: "Actions"},
    {l: "Anon", a: ["AB"]},
  ],
  a: {l: "Ask: %{query}", s: "AI", i: "cart"},
}
const CLS = {item: "ROW", label: "LBL", avatar: "AV", kbd: "KBD", keys: "KEYS", count: "CNT", sub: "SUB"}

function dataHtml(payload) {
  const attrs = Object.entries(CLS).map(([k, v]) => `data-lu-c-${k}="${v}"`).join(" ")
  return `<div hidden data-part="palette-data" ${attrs}>` +
    `<script type="application/json" data-part="palette-items">${JSON.stringify(payload)}</script>` +
    `<template id="p-ic-cart" data-lu-icon="cart"><path d="M1 1"/></template>` +
    `<template id="p-ic-plus" data-lu-icon="plus"><path d="M2 2"/><path d="M3 3"/></template></div>`
}

let seq = 0
function mount({payload = ITEMS, extra = {}, defer = true} = {}) {
  document.body.innerHTML = ""
  const el = document.createElement("div")
  el.id = "pal" + ++seq
  el.setAttribute("data-lu-overlay", "")
  el.dataset.luKind = "palette"
  el.dataset.luEmpty = "Nothing found"
  el.dataset.luHighlight = "always"
  el.dataset.luAssistantMode = "no_match"
  el.dataset.luOnSelect = "sel"
  el.dataset.luOnAssistant = "asst"
  for (const [k, v] of Object.entries(extra)) el.dataset[k] = v
  el.innerHTML =
    `<div data-part="palette" role="dialog">` +
    `<div data-part="palette-search"><svg class="${SVG_CLASS}" viewBox="0 0 24 24" aria-hidden="true" data-icon="search"><path d="M0 0"/></svg>` +
    `<input data-part="palette-input" role="combobox"></div>` +
    `<div data-part="palette-scopes"><button type="button" data-part="palette-scope" data-lu-scope="all" aria-pressed="true">All</button>` +
    `<button type="button" data-part="palette-scope" data-lu-scope="pages">Pages</button></div>` +
    `<div data-part="palette-list" id="${el.id}-list" role="listbox" ${defer ? 'phx-update="ignore"' : ""}></div></div>` +
    (defer ? dataHtml(payload) : "")
  document.body.append(el)
  const pushed = []
  const h = Object.assign(Object.create(hook), {
    el, pushed,
    pushEvent(e, p) { pushed.push([e, p]) },
    pushEventTo(t, e, p) { pushed.push([e, p, t]) },
  })
  h.mounted()
  const list = el.querySelector("[data-part=palette-list]")
  const input = el.querySelector("[data-part=palette-input]")
  const open = () => { el.classList.add("open"); h.sync() }
  const rows = () => Array.from(list.querySelectorAll(":scope > [data-part=palette-item]:not([data-lu-assistant])"))
  const visible = () => rows().filter((r) => !r.hidden).map((r) => r.getAttribute("data-lu-value"))
  const type = (text) => { input.value = text; input.dispatchEvent(new window.Event("input", {bubbles: true})) }
  const key = (k, init = {}) => input.dispatchEvent(new window.KeyboardEvent("keydown", {key: k, bubbles: true, cancelable: true, ...init}))
  return {h, el, list, input, pushed, open, rows, visible, type, key}
}

test("closed: no rows are built (the server sent none)", {skip}, () => {
  const t = mount()
  assert.equal(t.list.querySelectorAll("[data-part=palette-item]").length, 0)
  assert.equal(t.list.querySelectorAll("[data-part=palette-label]").length, 0)
})

test("opening builds the rows, the headings and the assistant row from the data", {skip}, () => {
  const t = mount()
  t.open()
  assert.equal(t.rows().length, 5)
  assert.deepEqual(Array.from(t.list.querySelectorAll("[data-part=palette-label]")).map((n) => n.textContent), ["Go to", "Actions"])
  assert.equal(t.list.querySelector("[data-part=palette-label]").className, "LBL")
  assert.equal(t.list.querySelector("[data-part=palette-label]").getAttribute("role"), "presentation")
  const [orders, inv, docs, neu, anon] = t.rows()
  for (const r of t.rows()) {
    assert.equal(r.className, "ROW")
    assert.equal(r.getAttribute("role"), "option")
    assert.ok(r.id.startsWith(t.el.id + "-opt-"), "every row has a stable id")
  }
  // links: navigate / patch / href, like <.link>
  assert.equal(orders.tagName, "A")
  assert.equal(orders.getAttribute("href"), "/orders")
  assert.equal(orders.getAttribute("data-phx-link"), "redirect")
  assert.equal(orders.getAttribute("data-phx-link-state"), "push")
  assert.equal(inv.getAttribute("data-phx-link"), "patch")
  assert.equal(docs.getAttribute("href"), "https://x.y")
  assert.equal(docs.hasAttribute("data-phx-link"), false)
  // action rows are buttons
  assert.equal(neu.tagName, "BUTTON")
  assert.equal(neu.getAttribute("type"), "button")
  assert.equal(neu.getAttribute("style"), "color:red")
  assert.equal(neu.getAttribute("data-lu-value"), "new-order")
  assert.equal(orders.getAttribute("data-lu-value"), "Orders")
  assert.equal(orders.getAttribute("data-lu-scope"), "pages")
  assert.equal(orders.getAttribute("data-lu-keywords"), "sales")
  // the icon: a clone of the search field's svg with the template's shapes
  const svg = orders.querySelector("svg")
  assert.equal(svg.getAttribute("class"), SVG_CLASS)
  assert.equal(svg.getAttribute("viewBox"), "0 0 24 24")
  assert.equal(svg.getAttribute("data-icon"), "cart")
  assert.equal(svg.querySelectorAll("path").length, 1)
  assert.equal(neu.querySelectorAll("svg path").length, 2)
  // keys, count, avatar, sub
  assert.deepEqual(Array.from(orders.querySelectorAll("kbd")).map((k) => [k.textContent, k.className]), [["G", "KBD"], ["O", "KBD"]])
  assert.equal(orders.querySelector("[data-part=palette-keys]").className, "KEYS")
  assert.equal(inv.querySelector("[data-part=palette-count]").textContent, "3")
  assert.equal(inv.querySelector("[data-part=palette-count]").className, "CNT")
  assert.equal(docs.querySelector("[data-part=palette-avatar]").getAttribute("style"), "background:#d97a1e")
  assert.equal(docs.querySelector("[data-part=palette-avatar]").className, "AV")
  assert.equal(anon.querySelector("[data-part=palette-avatar]").className, "AV bg-sunken")
  assert.equal(neu.querySelector("[data-part=palette-sub]").textContent, "Opens the form")
  // the assistant row is hidden until nothing matches
  const asst = t.list.querySelector("[data-lu-assistant]")
  assert.equal(asst.hidden, true)
  assert.equal(asst.getAttribute("data-lu-label"), "Ask: %{query}")
})

test("the first row is highlighted and the input points at it (aria-activedescendant)", {skip}, () => {
  const t = mount()
  t.open()
  const first = t.rows()[0]
  assert.equal(first.hasAttribute("data-lu-hl"), true)
  assert.equal(first.getAttribute("aria-selected"), "true")
  assert.equal(t.input.getAttribute("aria-activedescendant"), first.id)
})

test("the local filter works on the built rows: text, keywords, accents, scope, group headings", {skip}, () => {
  const t = mount()
  t.open()
  t.type("ord")
  assert.deepEqual(t.visible(), ["Orders", "new-order"])
  t.type("SALES")
  assert.deepEqual(t.visible(), ["Orders"])
  const labels = Array.from(t.list.querySelectorAll("[data-part=palette-label]"))
  assert.deepEqual(labels.map((l) => l.hidden), [false, true])
  t.type("")
  t.el.querySelector("[data-lu-scope=pages]").click()
  assert.deepEqual(t.visible(), ["Orders", "Invoices"])
})

test("no match: the empty text, then the assistant row with the query", {skip}, () => {
  const t = mount()
  t.open()
  t.type("zzz")
  assert.deepEqual(t.visible(), [])
  assert.equal(t.list.querySelector("[data-lu-empty-el]").hidden, true)
  const asst = t.list.querySelector("[data-lu-assistant]")
  assert.equal(asst.hidden, false)
  assert.ok(asst.textContent.includes("Ask: zzz"))
  asst.click()
  assert.deepEqual(t.pushed.pop(), ["asst", {id: t.el.id, query: "zzz"}])
})

test("keyboard: arrows move the highlight, Enter selects, Ctrl Enter asks for a new tab", {skip}, () => {
  const t = mount()
  t.open()
  t.key("ArrowDown")
  assert.equal(t.rows()[1].hasAttribute("data-lu-hl"), true)
  t.key("ArrowUp")
  t.key("ArrowUp")
  assert.equal(t.rows()[4].hasAttribute("data-lu-hl"), true, "wraps to the last row")
  t.key("Enter")
  assert.deepEqual(t.pushed.pop(), ["sel", {id: t.el.id, value: "Anon", new_tab: false}])
  t.open()
  t.key("Enter", {ctrlKey: true})
  assert.equal(t.pushed.pop()[1].new_tab, true)
})

test("clicking a row selects it with its value and closes the palette", {skip}, () => {
  const t = mount()
  t.open()
  t.rows()[3].click()
  assert.deepEqual(t.pushed.pop(), ["sel", {id: t.el.id, value: "new-order", new_tab: false}])
  assert.equal(t.el.classList.contains("open"), false)
})

test("changed data: rebuilt on update when open; when closed, on the next opening", {skip}, () => {
  const t = mount()
  t.open()
  t.el.querySelector("script[data-part=palette-items]").textContent = JSON.stringify({r: [{l: "Only"}]})
  t.h.updated()
  assert.deepEqual(t.visible(), ["Only"])
  t.el.classList.remove("open")
  t.h.sync()
  t.el.querySelector("script[data-part=palette-items]").textContent = JSON.stringify({r: [{l: "A"}, {l: "B"}]})
  t.h.updated()
  assert.deepEqual(t.visible(), ["Only"], "closed: not rebuilt yet")
  t.open()
  assert.deepEqual(t.visible(), ["A", "B"])
})

test("the same data on update does not touch the rows", {skip}, () => {
  const t = mount()
  t.open()
  const before = t.rows()[0]
  t.h.updated()
  assert.equal(t.rows()[0], before)
})

test("the icon is skipped when its template is missing; no prototype svg still builds one", {skip}, () => {
  const t = mount({payload: {r: [{l: "X", i: "missing"}, {l: "Y", i: "cart"}]}})
  t.el.querySelector("[data-part=palette-search] svg").remove()
  t.open()
  const [x, y] = t.rows()
  assert.equal(x.querySelector("svg"), null)
  assert.equal(y.querySelector("svg").getAttribute("viewBox"), "0 0 24 24")
})

test("without [data-part=palette-data] (the default mode) the server rows are left alone", {skip}, () => {
  const t = mount({defer: false})
  t.list.innerHTML = '<button data-part="palette-item" data-lu-value="a">Alpha</button><button data-part="palette-item" data-lu-value="b">Beta</button>'
  t.open()
  assert.deepEqual(t.visible(), ["a", "b"])
  t.type("bet")
  assert.deepEqual(t.visible(), ["b"])
})

test("text with HTML in a label stays text", {skip}, () => {
  const t = mount({payload: {r: [{l: "<img src=x onerror=1>", s: "<b>s</b>", g: "<i>g</i>"}]}})
  t.open()
  assert.equal(t.list.querySelector("img"), null)
  assert.equal(t.list.querySelector("b"), null)
  assert.equal(t.list.querySelector("i"), null)
})
