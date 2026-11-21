// The treeview, select and landing_nav hooks in a jsdom document: what `updated` costs and what it keeps.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/hooks_perf_test.mjs
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

let tree, select, nav
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true})
  const w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, MutationObserver: w.MutationObserver, Event: w.Event, CSS: {escape: (s) => s}})
  globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} }
  w.Element.prototype.scrollIntoView = function () {}
  const dir = mkdtempSync(join(tmpdir(), "lu-hooks-"))
  const load = async (name) => {
    writeFileSync(join(dir, `${name}.mjs`), readFileSync(join(here, `../../priv/static/ledger_ui/hooks/${name}.js`), "utf8"))
    return (await import(pathToFileURL(join(dir, `${name}.mjs`)))).default
  }
  tree = await load("treeview")
  select = await load("select")
  nav = await load("landing_nav")
}

const flush = () => new Promise((r) => setTimeout(r, 0))
const instance = (hook, el, extra = {}) => Object.assign(Object.create(hook), {el, pushEvent() {}, pushEventTo() {}, ...extra})
// Counts the calls to the given methods of an element.
const spy = (el, names) => {
  const calls = {}
  for (const n of names) {
    const f = el[n].bind(el)
    calls[n] = 0
    el[n] = (...a) => { calls[n]++; return f(...a) }
  }
  return calls
}

// ---- treeview -------------------------------------------------------------------------------
const row = (id, label, {branch = false, open = false, selected = false} = {}) =>
  `<div id="${id}" data-part="tree-item" role="treeitem" tabindex="-1" aria-selected="${selected}"${branch ? ` aria-expanded="${open}"` : ""}>` +
  (branch ? `<span data-part="tree-chevron"><svg data-icon="${open ? "chevron-down" : "chevron-right"}"></svg></span>` : "") +
  `<span data-part="tree-check"><input type="checkbox" data-part="tree-check-input"></span>${label}</div>`

function mountTree(branches = 5, leaves = 20) {
  document.body.innerHTML = "" // one tree at a time: the ids repeat from test to test
  const el = document.createElement("div")
  el.id = "t" + Math.random().toString(36).slice(2)
  el.dataset.onSelect = "sel"
  el.dataset.onToggle = "tog"
  let html = ""
  for (let b = 0; b < branches; b++) {
    html += row(`b${b}`, `B${b}`, {branch: true, open: b === 0}) + `<div data-part="tree-children" id="b${b}-kids">`
    for (let l = 0; l < leaves; l++) html += row(`b${b}l${l}`, `L${l}`)
    html += "</div>"
  }
  el.innerHTML = html
  document.body.appendChild(el)
  const pushed = []
  const h = instance(tree, el, {pushEvent: (ev, p) => pushed.push([ev, p])})
  h.mounted()
  return {el, h, pushed}
}

test("treeview: mounted puts one row in the tab order and closes the branches the server drew closed", {skip}, () => {
  const {el} = mountTree()
  assert.equal(el.querySelectorAll('[data-part="tree-item"][tabindex="0"]').length, 1)
  assert.equal(el.querySelector("#b0-kids").hidden, false)
  assert.equal(el.querySelector("#b1-kids").hidden, true)
  assert.equal(el.querySelector("#b1").getAttribute("aria-expanded"), "false")
})

test("treeview: a patch that touches no node costs no scan", {skip}, async () => {
  const {el, h} = mountTree(10, 100)
  el.querySelector("#b1").click() // the person opens b1
  await flush()
  const calls = spy(el, ["querySelectorAll"])
  el.dataset.tick = "1" // the root's own attribute, as a patch that only changes assigns
  h.updated()
  assert.equal(calls.querySelectorAll, 0)
  assert.equal(el.querySelector("#b1-kids").hidden, false) // the person's toggle survives
})

test("treeview: a patch that inserts a row applies the state to that row only", {skip}, async () => {
  const {el, h} = mountTree(3, 5)
  await flush()
  el.querySelector("#b0-kids").insertAdjacentHTML("afterbegin", row("fresh", "new"))
  el.querySelector("#b2-kids").hidden = false // a patch undoing a client toggle on an untouched branch is not seen
  h.updated()
  assert.equal(el.querySelector("#fresh").getAttribute("aria-selected"), "false")
  // keyboard: the new row is part of the walk
  const order = []
  const first = el.querySelector("#b0")
  first.focus()
  for (let i = 0; i < 3; i++) {
    const cur = document.activeElement
    cur.dispatchEvent(new window.KeyboardEvent("keydown", {key: "ArrowDown", bubbles: true, cancelable: true}))
    order.push(document.activeElement.id)
  }
  assert.deepEqual(order, ["fresh", "b0l0", "b0l1"])
})

test("treeview: a removed row leaves the walk and the tab stop is kept", {skip}, async () => {
  const {el, h} = mountTree(2, 3)
  await flush()
  el.querySelector("#b0").tabIndex = -1
  el.querySelector("#b0l0").remove()
  h.updated()
  assert.equal(el.querySelectorAll('[data-part="tree-item"][tabindex="0"]').length, 1)
  el.querySelector("#b0").focus()
  el.querySelector("#b0").dispatchEvent(new window.KeyboardEvent("keydown", {key: "ArrowDown", bubbles: true, cancelable: true}))
  assert.equal(document.activeElement.id, "b0l1")
})

test("treeview: a server-listed branch is opened again by every patch", {skip}, async () => {
  const {el, h} = mountTree(3, 2)
  el.dataset.expanded = JSON.stringify(["b1"])
  h.updated()
  assert.equal(el.querySelector("#b1-kids").hidden, false)
  el.querySelector("#b1").click() // the person closes it
  assert.equal(el.querySelector("#b1-kids").hidden, true)
  h.updated()
  assert.equal(el.querySelector("#b1-kids").hidden, false)
})

test("treeview: selecting a leaf moves aria-selected and pushes the id; the box sums its branch", {skip}, () => {
  const {el, h, pushed} = mountTree(2, 2)
  el.querySelector("#b0l0").click()
  el.querySelector("#b0l1").click()
  assert.deepEqual([...el.querySelectorAll('[aria-selected="true"]')].map((r) => r.id), ["b0l1"])
  assert.deepEqual(pushed.at(-1), ["sel", {id: "b0l1"}])
  const box = (id) => el.querySelector(`#${id} input`)
  box("b0l0").checked = true
  box("b0l0").dispatchEvent(new window.Event("change", {bubbles: true}))
  assert.equal(box("b0").indeterminate, true)
  box("b0l1").checked = true
  box("b0l1").dispatchEvent(new window.Event("change", {bubbles: true}))
  assert.equal(box("b0").checked, true)
  assert.equal(box("b0").indeterminate, false)
  h.destroyed()
})

// ---- select ---------------------------------------------------------------------------------
const CLS = {chip: "chip", remove: "rm", icon: "ic", right: "rt", ck: "ck", item: "it", more: "mr"}
function mountSelect(count = 50, selected = ["o1"]) {
  document.body.innerHTML = ""
  const el = document.createElement("div")
  el.id = "s" + Math.random().toString(36).slice(2)
  el.dataset.luCls = JSON.stringify(CLS)
  el.dataset.luMultiple = ""
  el.dataset.luRemovable = ""
  el.dataset.luFooterCount = "%{count} of %{total}"
  let items = ""
  for (let i = 1; i <= count; i++) items += `<button data-part="listbox-option" data-lu-value="o${i}" data-lu-label="Option ${i}" aria-selected="${selected.includes("o" + i)}">Option ${i}</button>`
  el.innerHTML =
    `<select hidden multiple>${selected.map((v) => `<option value="${v}" selected>${v.replace("o", "Option ")}</option>`).join("")}</select>` +
    `<div data-part="select-control"><input data-lu-q><svg></svg></div>` +
    `<div data-part="select-panel" hidden><div data-lu-list>${items}</div><span data-lu-footer-count></span><div data-lu-empty hidden></div></div>`
  document.body.appendChild(el)
  const h = instance(select, el)
  h.mounted()
  return {el, h}
}

test("select: a patch leaves the chips, the panel listener and the observer where they are", {skip}, () => {
  const {el, h} = mountSelect()
  h.sel = [{value: "o1", label: "Option 1"}, {value: "o3", label: "Option 3"}]
  h.dirty = true
  h.render()
  const chips = [...el.querySelectorAll('[data-part="select-chip"]')]
  assert.equal(chips.length, 2)
  const pop = el.querySelector('[data-part="select-panel"]')
  const calls = spy(pop, ["addEventListener", "removeEventListener"])
  h.updated()
  assert.deepEqual([...el.querySelectorAll('[data-part="select-chip"]')], chips) // the same nodes
  assert.equal(calls.addEventListener + calls.removeEventListener, 0)
  assert.equal(el.querySelector("[data-lu-footer-count]").textContent, "2 of 50")
  h.destroyed()
})

test("select: the options are listed once per patch, not once per use", {skip}, () => {
  const {el, h} = mountSelect(200)
  const list = el.querySelector("[data-lu-list]")
  const calls = spy(list, ["querySelectorAll"])
  h.updated()
  assert.equal(calls.querySelectorAll, 1)
  h.sel = [{value: "o2", label: "Option 2"}, {value: "o9", label: "Option 9"}, {value: "o10", label: "Option 10"}]
  h.dirty = true
  h.render() // chips, footer, filter...: no new scan
  assert.equal(calls.querySelectorAll, 1)
  assert.equal(el.querySelector("[data-lu-footer-count]").textContent, "3 of 200")
})

test("select: filtering hides what does not match and the arrows walk what is left", {skip}, () => {
  const {el, h} = mountSelect(30, [])
  h.q = "option 2"
  h.filter()
  const shown = [...el.querySelectorAll('[data-part="listbox-option"]')].filter((i) => !i.hidden)
  assert.deepEqual(shown.map((i) => i.dataset.luValue), ["o2", "o20", "o21", "o22", "o23", "o24", "o25", "o26", "o27", "o28", "o29"])
  assert.equal(h.visible().length, shown.length)
  assert.equal(el.querySelectorAll("[data-hl]").length, 1)
  h.highlight(shown[3])
  assert.equal(el.querySelectorAll("[data-hl]").length, 1)
  assert.equal(el.querySelector("[data-hl]").dataset.luValue, "o22")
  h.q = ""
  h.filter()
  assert.equal(h.visible().length, 30)
})

test("select: choosing then removing a chip keeps the options and the footer in step", {skip}, () => {
  const {el, h} = mountSelect(10, [])
  h.choose(el.querySelector('[data-part="listbox-option"][data-lu-value="o4"]'))
  h.choose(el.querySelector('[data-part="listbox-option"][data-lu-value="o5"]'))
  assert.deepEqual([...el.querySelectorAll('[data-part="select-chip"]')].map((c) => c.dataset.luValue), ["o4", "o5"])
  assert.equal(el.querySelector('[data-part="listbox-option"][data-lu-value="o4"]').getAttribute("aria-selected"), "true")
  assert.equal(el.querySelector("[data-lu-footer-count]").textContent, "2 of 10")
  el.querySelector('[data-lu-remove="o4"]').dispatchEvent(new window.Event("click", {bubbles: true, cancelable: true}))
  assert.deepEqual([...el.querySelectorAll('[data-part="select-chip"]')].map((c) => c.dataset.luValue), ["o5"])
  assert.equal(el.querySelector('[data-part="listbox-option"][data-lu-value="o4"]').getAttribute("aria-selected"), "false")
  assert.equal(el.querySelector("[data-lu-footer-count]").textContent, "1 of 10")
  h.destroyed()
})

// ---- landing_nav ----------------------------------------------------------------------------
test("landing_nav: destroyed takes back every listener mounted added", {skip}, () => {
  const el = document.createElement("div")
  el.setAttribute("data-lu-sticky", "")
  document.body.appendChild(el)
  const added = [], removed = []
  const track = (target, name) => {
    const a = target.addEventListener.bind(target), r = target.removeEventListener.bind(target)
    target.addEventListener = (t, f, o) => { added.push(`${name}:${t}`); return a(t, f, o) }
    target.removeEventListener = (t, f, o) => { removed.push(`${name}:${t}`); return r(t, f, o) }
  }
  track(window, "window"); track(document, "document"); track(el, "el")
  const h = instance(nav, el)
  h.mounted()
  h.destroyed()
  assert.deepEqual([...added].sort(), [...removed].sort())
  assert.ok(added.includes("window:scroll") && added.includes("document:click"))
})
