// The ARIA of the listbox hooks (#112): `aria-activedescendant` follows the lit row, `aria-expanded` follows
// the list, in `select` (search in the control, in the panel, or none), `tags_input` and `autocomplete` (#113).
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/select_aria_test.mjs
// jsdom is not a dependency of the package: the tests are skipped when it cannot be found.
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

let select, tags, autocomplete
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true})
  const w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, MutationObserver: w.MutationObserver, Event: w.Event, CSS: {escape: (s) => s}})
  globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} }
  w.Element.prototype.scrollIntoView = function () {}
  select = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/select.js")))).default
  tags = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/tags_input.js")))).default
  autocomplete = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/autocomplete.js")))).default
}

const CLS = {chip: "chip", remove: "rm", icon: "ic", right: "rt", ck: "ck", more: "mr"}
const opt = (pop, v, l) => `<button type="button" role="option" id="${pop}-o${v}" data-part="listbox-option" data-lu-value="${v}" aria-selected="false">${l}</button>`

// What the server draws for a single select; `mode` is where the search box is.
function mountSelect(mode) {
  document.body.innerHTML = ""
  const el = document.createElement("div")
  el.id = "s1"
  el.dataset.luCls = JSON.stringify(CLS)
  if (mode === "panel") el.dataset.luSearch = "panel"
  if (mode === "none") el.dataset.luSearch = "none"
  const q = (extra) =>
    `<input type="text" data-part="select-search" data-lu-q role="combobox" aria-haspopup="listbox" aria-autocomplete="list" aria-controls="s1-pop-list" aria-expanded="false" ${extra}>`
  el.innerHTML =
    `<span data-part="select-control" role="combobox" tabindex="0" aria-expanded="false" aria-controls="s1-pop"><span data-part="select-value" data-ph>Pick</span>${mode === "control" ? q("hidden") : ""}</span>` +
    `<div id="s1-pop" data-part="select-panel" hidden>${mode === "panel" ? `<div>${q("")}</div>` : ""}` +
    `<div id="s1-pop-list" role="listbox" data-lu-list>${opt("s1-pop", "a", "Ana")}${opt("s1-pop", "b", "Bia")}${opt("s1-pop", "c", "Caio")}</div><div data-lu-empty hidden></div></div>`
  document.body.appendChild(el)
  const h = Object.assign(Object.create(select), {el, pushEvent() {}, pushEventTo() {}})
  h.mounted()
  return {el, h}
}

const ctrl = (el) => el.querySelector('[data-part="select-control"]')
const search = (el) => el.querySelector("input[data-lu-q]")
const press = (target, k) => {
  const e = new window.KeyboardEvent("keydown", {key: k, bubbles: true, cancelable: true})
  target.dispatchEvent(e)
}
const lit = (el) => el.querySelector("[data-hl]")

for (const mode of ["control", "panel"]) {
  test(`select, search in the ${mode}: aria-activedescendant names the lit row`, {skip}, () => {
    const {el} = mountSelect(mode)
    const q = search(el)
    assert.equal(q.getAttribute("aria-expanded"), "false")
    assert.equal(q.hasAttribute("aria-activedescendant"), false, "closed: names no row")
    press(ctrl(el), "Enter")
    assert.equal(q.getAttribute("aria-expanded"), "true")
    assert.equal(ctrl(el).getAttribute("aria-expanded"), "true")
    assert.equal(q.getAttribute("aria-activedescendant"), lit(el).id, "the first row is lit when it opens")
    assert.equal(lit(el).dataset.luValue, "a")
    press(q, "ArrowDown")
    press(q, "ArrowDown")
    assert.equal(lit(el).dataset.luValue, "c")
    assert.equal(q.getAttribute("aria-activedescendant"), "s1-pop-oc")
    assert.equal(ctrl(el).hasAttribute("aria-activedescendant"), false, "only the field that has the focus")
    press(q, "ArrowUp")
    assert.equal(q.getAttribute("aria-activedescendant"), lit(el).id)
    assert.equal(lit(el).dataset.luValue, "b")
    press(q, "Escape")
    assert.equal(q.getAttribute("aria-expanded"), "false")
    assert.equal(q.hasAttribute("aria-activedescendant"), false, "closed: names no row")
  })
}

test("select without a search box: the control carries aria-activedescendant", {skip}, () => {
  const {el} = mountSelect("none")
  press(ctrl(el), "ArrowDown")
  assert.equal(ctrl(el).getAttribute("aria-activedescendant"), lit(el).id)
  press(ctrl(el), "ArrowDown")
  assert.equal(ctrl(el).getAttribute("aria-activedescendant"), "s1-pop-ob")
  press(ctrl(el), "Escape")
  assert.equal(ctrl(el).hasAttribute("aria-activedescendant"), false)
})

test("select: a row without id (a cached copy, a created one) gets one when it is lit", {skip}, () => {
  const {el, h} = mountSelect("panel")
  const row = document.createElement("button")
  row.type = "button"
  row.dataset.part = "listbox-option"
  row.dataset.luValue = "z"
  row.textContent = "Zed"
  el.querySelector("[data-lu-list]").appendChild(row)
  h.invalidate()
  press(ctrl(el), "Enter")
  h.highlight(row)
  assert.ok(row.id, "an id was given")
  assert.equal(search(el).getAttribute("aria-activedescendant"), row.id)
  assert.equal(document.querySelectorAll(`#${row.id}`).length, 1)
})

test("select: a created row is an option", {skip}, () => {
  const {el, h} = mountSelect("panel")
  el.dataset.luCreate = ""
  el.querySelector("#s1-pop").insertAdjacentHTML("beforeend", `<button type="button" role="option" id="s1-pop-create" data-lu-create-row hidden></button>`)
  press(ctrl(el), "Enter")
  search(el).value = "Novo"
  search(el).dispatchEvent(new window.Event("input", {bubbles: true}))
  h.create()
  const made = el.querySelector("[data-lu-created]")
  assert.equal(made.getAttribute("role"), "option")
  assert.equal(made.getAttribute("aria-selected"), "true")
})

// ---- tags_input

function mountTags({panel = true} = {}) {
  document.body.innerHTML = ""
  const el = document.createElement("span")
  el.id = "t1"
  el.dataset.luCls = JSON.stringify({tag: "tag", remove: "rm", right: "rt", icon: "ic"})
  const role = panel ? `role="combobox" aria-haspopup="listbox" aria-autocomplete="list" aria-controls="t1-pop" aria-expanded="false"` : ""
  el.innerHTML =
    `<input data-part="tags-input-control" ${role}>` +
    (panel
      ? `<div id="t1-pop" role="listbox" hidden data-part="tags-input-panel"><div data-lu-list>` +
        ["a", "b", "c"].map((v) => `<button type="button" role="option" id="t1-pop-o${v}" data-part="listbox-option" data-lu-value="${v}" data-lu-label="${v.toUpperCase()}">${v}</button>`).join("") +
        `</div><button type="button" role="option" id="t1-pop-create" data-part="listbox-option" data-lu-create-row hidden></button><div data-lu-empty hidden></div></div>`
      : "") +
    `<select name="t[]" multiple hidden><option value="" selected></option></select>`
  document.body.appendChild(el)
  const h = Object.assign(Object.create(tags), {el, pushEvent() {}, pushEventTo() {}})
  h.mounted()
  return {el, h}
}

test("tags_input: aria-expanded and aria-activedescendant on the field", {skip}, () => {
  const {el} = mountTags()
  const input = el.querySelector("input")
  assert.equal(input.getAttribute("aria-expanded"), "false")
  assert.equal(input.hasAttribute("aria-activedescendant"), false)
  press(input, "ArrowDown")
  assert.equal(input.getAttribute("aria-expanded"), "true")
  assert.equal(input.getAttribute("aria-activedescendant"), lit(el).id)
  assert.equal(lit(el).dataset.luValue, "b", "the first row was lit already: the arrow goes to the next")
  press(input, "ArrowDown")
  assert.equal(input.getAttribute("aria-activedescendant"), "t1-pop-oc")
  assert.equal(lit(el).id, "t1-pop-oc")
  press(input, "Escape")
  assert.equal(input.getAttribute("aria-expanded"), "false")
  assert.equal(input.hasAttribute("aria-activedescendant"), false)
})

test("tags_input without a panel: a plain input, no ARIA written", {skip}, () => {
  const {el} = mountTags({panel: false})
  const input = el.querySelector("input")
  press(input, "ArrowDown")
  assert.equal(input.hasAttribute("aria-expanded"), false)
  assert.equal(input.hasAttribute("aria-activedescendant"), false)
})

// ---- autocomplete

function mountAuto({ids = true} = {}) {
  document.body.innerHTML = ""
  const el = document.createElement("div")
  el.id = "a1"
  const row = (v) => `<button type="button" role="option" ${ids ? `id="a1-list-o${v}"` : ""} data-part="listbox-option" data-lu-value="${v}" data-lu-label="${v}" aria-selected="false"><span data-lu-lbl>${v}</span></button>`
  el.innerHTML =
    `<span data-part="autocomplete-control"><input type="text" data-lu-q role="combobox" aria-expanded="false" aria-controls="a1-list" aria-labelledby="a1-label"><input type="hidden" data-lu-v value=""></span>` +
    `<div id="a1-list" role="listbox" data-part="autocomplete-panel" hidden><div data-lu-list>${["ana", "bia", "caio"].map(row).join("")}</div>` +
    `<div data-lu-empty hidden></div><div data-lu-loading hidden></div></div>`
  document.body.appendChild(el)
  const h = Object.assign(Object.create(autocomplete), {el, pushEvent() {}, pushEventTo() {}})
  h.mounted()
  return {el, h}
}

test("autocomplete: aria-activedescendant is the id of the lit row, never empty", {skip}, () => {
  const {el} = mountAuto()
  const input = el.querySelector("input[data-lu-q]")
  assert.equal(input.hasAttribute("aria-activedescendant"), false, "closed: names no row")
  press(input, "ArrowDown")
  assert.equal(input.getAttribute("aria-expanded"), "true")
  assert.equal(lit(el).dataset.luValue, "bia", "the first row was lit already: the arrow goes to the next")
  assert.equal(input.getAttribute("aria-activedescendant"), "a1-list-obia")
  press(input, "ArrowDown")
  assert.equal(lit(el).dataset.luValue, "caio")
  assert.equal(input.getAttribute("aria-activedescendant"), lit(el).id)
  assert.notEqual(input.getAttribute("aria-activedescendant"), "")
  press(input, "Escape")
  assert.equal(input.getAttribute("aria-expanded"), "false")
  assert.equal(input.hasAttribute("aria-activedescendant"), false)
})

test("autocomplete: a row without id gets one, so the attribute is not empty", {skip}, () => {
  const {el} = mountAuto({ids: false})
  const input = el.querySelector("input[data-lu-q]")
  press(input, "ArrowDown")
  press(input, "ArrowDown")
  const id = input.getAttribute("aria-activedescendant")
  assert.ok(id, "not empty")
  assert.equal(lit(el).id, id)
  assert.equal(document.querySelectorAll(`[id="${id}"]`).length, 1)
})
