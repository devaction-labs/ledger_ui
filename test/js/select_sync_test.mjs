// The select hook and the value the server drew (#40): what a patch does to the person's choice, and what a form reset does.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/select_sync_test.mjs
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

let select
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true})
  const w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, MutationObserver: w.MutationObserver, Event: w.Event, CSS: {escape: (s) => s}})
  globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} }
  w.Element.prototype.scrollIntoView = function () {}
  const dir = mkdtempSync(join(tmpdir(), "lu-select-"))
  writeFileSync(join(dir, "select.mjs"), readFileSync(join(here, "../../priv/static/ledger_ui/hooks/select.js"), "utf8"))
  select = (await import(pathToFileURL(join(dir, "select.mjs")))).default
}

const flush = () => new Promise((r) => setTimeout(r, 0))
const CLS = {chip: "chip", remove: "rm", icon: "ic", right: "rt", ck: "ck", more: "mr"}
const label = (v) => v.replace("o", "Option ")

// The root as the server renders it for `value`: chips (or the single value), the hidden <select>, the rows
// (no `data-lu-label`: the label is the row's text) and `data-lu-value`.
function draw(el, value, {multiple}) {
  const chosen = value.map((v) => ({value: v, label: label(v)}))
  el.dataset.luValue = JSON.stringify(chosen)
  const rows = []
  for (let i = 1; i <= 12; i++) {
    const on = value.includes("o" + i)
    rows.push(`<button type="button" data-part="listbox-option" data-lu-value="o${i}" aria-selected="${on}">Option ${i}</button>`)
  }
  rows.push(`<button type="button" data-part="listbox-option" data-lu-value="d1" aria-selected="false"><span data-part="person-avatar">DX</span>Delta<span data-part="listbox-option-right">12</span></button>`)
  const control = multiple
    ? chosen.map((c) => `<span data-part="select-chip" data-lu-value="${c.value}">${c.label}</span>`).join("")
    : `<span data-part="select-value"${chosen.length ? "" : " data-ph"}>${chosen.length ? chosen[0].label : "Pick"}</span>`
  el.innerHTML =
    `<span data-part="select-control" data-one="">${control}<input data-lu-q hidden><svg></svg></span>` +
    `<div data-part="select-panel" hidden><div role="listbox" data-lu-list>${rows.join("")}</div><div data-lu-empty hidden></div></div>` +
    `<select name="f[v]" hidden ${multiple ? "multiple" : ""}>${multiple ? '<option value="" selected></option>' : ""}${chosen.map((c) => `<option value="${c.value}" selected>${c.label}</option>`).join("")}</select>`
}

function mount(value = ["o1"], {multiple = true} = {}) {
  document.body.innerHTML = ""
  const form = document.createElement("form")
  const el = document.createElement("div")
  el.id = "s" + Math.random().toString(36).slice(2)
  el.dataset.luCls = JSON.stringify(CLS)
  el.dataset.luPlaceholder = "Pick"
  if (multiple) el.dataset.luMultiple = ""
  el.dataset.luRemovable = ""
  form.appendChild(el)
  document.body.appendChild(form)
  draw(el, value, {multiple})
  const pushed = []
  const h = Object.assign(Object.create(select), {el, pushEvent() {}, pushEventTo() {}})
  h.mounted()
  el.addEventListener("input", () => pushed.push(values(el)))
  // A patch: the server's markup over the browser's, then `updated`.
  const patch = (v) => { draw(el, v, {multiple}); h.updated() }
  return {el, h, form, patch, pushed}
}

const chips = (el) => [...el.querySelectorAll('[data-part="select-chip"]')].filter((c) => !c.hidden).map((c) => c.dataset.luValue)
const values = (el) => [...el.querySelector("select").options].filter((o) => o.value && o.selected).map((o) => o.value)
const aria = (el) => [...el.querySelectorAll('[data-lu-value][aria-selected="true"]')].map((r) => r.dataset.luValue)
const row = (el, v) => el.querySelector(`[data-part="listbox-option"][data-lu-value="${v}"]`)
const everywhere = (el, want) => {
  assert.deepEqual(chips(el), want, "chips")
  assert.deepEqual(values(el), want, "hidden select")
  assert.deepEqual(aria(el), want, "aria-selected")
}

test("a patch that does not change the value leaves the person's choice in the chip, the hidden select and aria-selected", {skip}, () => {
  const {el, h, patch} = mount(["o1"])
  h.choose(row(el, "o10"))
  everywhere(el, ["o1", "o10"])
  patch(["o1"]) // a tick: the server draws what it drew before
  everywhere(el, ["o1", "o10"])
  patch(["o1"])
  everywhere(el, ["o1", "o10"])
})

test("a patch that changes the value makes the server win, everywhere at once", {skip}, () => {
  const {el, h, patch} = mount(["o1"])
  h.choose(row(el, "o10"))
  patch(["o3"])
  everywhere(el, ["o3"])
  // and the next patch that does not change it keeps what the person chooses from there
  h.choose(row(el, "o4"))
  patch(["o3"])
  everywhere(el, ["o3", "o4"])
})

test("the server clearing the value clears the chips, the hidden select and aria-selected", {skip}, () => {
  const {el, h, patch} = mount(["o1", "o2"])
  h.choose(row(el, "o3"))
  patch([])
  everywhere(el, [])
  assert.equal(el.querySelector("[data-lu-clear]"), null)
})

test("the server echoing the choice (phx-change) draws the same thing the browser already shows", {skip}, () => {
  const {el, h, patch, pushed} = mount(["o1"])
  h.choose(row(el, "o10"))
  assert.deepEqual(pushed.at(-1), ["o1", "o10"]) // what phx-change sends
  patch(["o1", "o10"])
  everywhere(el, ["o1", "o10"])
  patch(["o1", "o10"]) // a patch after the echo: nothing moved
  everywhere(el, ["o1", "o10"])
})

test("two choices before the first echo arrives: the echo is a new server value, so it wins until the next one", {skip}, () => {
  const {el, h, patch} = mount(["o1"])
  h.choose(row(el, "o10"))
  h.choose(row(el, "o11"))
  patch(["o1", "o10"]) // the echo of the first
  everywhere(el, ["o1", "o10"])
  patch(["o1", "o10", "o11"]) // the echo of the second
  everywhere(el, ["o1", "o10", "o11"])
})

test("a single select keeps the choice through a patch and takes the server's new value", {skip}, () => {
  const {el, h, patch} = mount(["o1"], {multiple: false})
  h.choose(row(el, "o7"))
  assert.equal(el.querySelector('[data-part="select-value"]').textContent, "Option 7")
  patch(["o1"])
  assert.equal(el.querySelector('[data-part="select-value"]').textContent, "Option 7")
  assert.deepEqual(values(el), ["o7"])
  assert.deepEqual(aria(el), ["o7"])
  patch(["o2"])
  assert.equal(el.querySelector('[data-part="select-value"]').textContent, "Option 2")
  assert.deepEqual(values(el), ["o2"])
  assert.deepEqual(aria(el), ["o2"])
  patch([])
  assert.equal(el.querySelector('[data-part="select-value"]').textContent, "Pick")
  assert.deepEqual(aria(el), [])
})

test("a form reset gives back the value the server drew last", {skip}, async () => {
  const {el, h, form, patch} = mount(["o1"])
  h.choose(row(el, "o10"))
  patch(["o1"])
  form.dispatchEvent(new window.Event("reset", {bubbles: true}))
  await flush()
  everywhere(el, ["o1"])
  patch(["o5"]) // the server moved on; a later reset goes back to that one
  h.choose(row(el, "o6"))
  form.dispatchEvent(new window.Event("reset", {bubbles: true}))
  await flush()
  everywhere(el, ["o5"])
  h.destroyed()
})

test("a reset of another form leaves the choice alone, and destroyed stops listening", {skip}, async () => {
  const {el, h} = mount(["o1"])
  h.choose(row(el, "o10"))
  const other = document.createElement("form")
  document.body.appendChild(other)
  other.dispatchEvent(new window.Event("reset", {bubbles: true}))
  await flush()
  everywhere(el, ["o1", "o10"])
  h.destroyed()
  h.sel = [{value: "zzz", label: "zzz"}]
  document.dispatchEvent(new window.Event("reset"))
  await flush()
  assert.equal(h.sel[0].value, "zzz")
})

test("the label of a row without data-lu-label is its own text, not the avatar or the count", {skip}, () => {
  const {el, h} = mount([])
  h.choose(row(el, "d1"))
  assert.deepEqual(h.sel, [{value: "d1", label: "Delta"}])
  assert.equal(el.querySelector('[data-part="select-chip"]').dataset.luLabel, "Delta")
  h.q = "delt"
  h.filter()
  assert.equal(row(el, "d1").hidden, false)
  assert.equal(row(el, "o1").hidden, true)
  h.destroyed()
})

test("chips are drawn after a patch has dropped the cached options (itemFor after invalidate)", {skip}, () => {
  const {el, h, patch} = mount(["o1"])
  h.choose(row(el, "o2"))
  assert.doesNotThrow(() => patch(["o1"])) // redraws the chips (the server's ones lack the label) from a dropped cache
  everywhere(el, ["o1", "o2"])
})
