// The hooks write no text of their own: the strings come from the server in `data-lu-*` attributes
// (the locale's), with English as the fallback when the attribute is absent.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/i18n_hooks_test.mjs
// jsdom is not a dependency of the package: the tests are skipped when it cannot be found.
import {test} from "node:test"
import assert from "node:assert/strict"
import {createRequire} from "node:module"
import {readFileSync, writeFileSync, mkdtempSync, mkdirSync} from "node:fs"
import {tmpdir} from "node:os"
import {join, dirname} from "node:path"
import {fileURLToPath, pathToFileURL} from "node:url"

const here = dirname(fileURLToPath(import.meta.url))
const priv = join(here, "../../priv/static/ledger_ui")
const require = createRequire(import.meta.url)

let JSDOM
for (const p of [process.env.JSDOM_PATH, "jsdom"].filter(Boolean)) {
  try { ({JSDOM} = require(p)); break } catch (_) { /* try the next */ }
}
const skip = JSDOM ? false : "jsdom not found (set JSDOM_PATH)"

let select, tags, range, chart
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true})
  const w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, MutationObserver: w.MutationObserver, Event: w.Event, CustomEvent: w.CustomEvent, CSS: {escape: (s) => s}})
  globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} }
  w.Element.prototype.scrollIntoView = function () {}
  // a tiny ESM package, so the hooks keep their relative imports (`../lib/picker.js`)
  const dir = mkdtempSync(join(tmpdir(), "lu-i18n-"))
  writeFileSync(join(dir, "package.json"), '{"type":"module"}')
  mkdirSync(join(dir, "hooks")); mkdirSync(join(dir, "lib"))
  writeFileSync(join(dir, "lib/picker.js"), readFileSync(join(priv, "lib/picker.js"), "utf8"))
  const load = async (name) => {
    writeFileSync(join(dir, `hooks/${name}.js`), readFileSync(join(priv, `hooks/${name}.js`), "utf8"))
    return (await import(pathToFileURL(join(dir, `hooks/${name}.js`)))).default
  }
  select = await load("select")
  tags = await load("tags_input")
  range = await load("range")
  chart = await load("chart")
}

const CLS = {chip: "chip", remove: "rm", icon: "ic", right: "rt", ck: "ck", more: "mr"}
const hookOf = (hook, el) => Object.assign(Object.create(hook), {el, pushEvent() {}, pushEventTo() {}, handleEvent() {}})

// --- select ----------------------------------------------------------------------------------

function mountSelect(attrs = {}) {
  document.body.innerHTML = ""
  const el = document.createElement("div")
  el.id = "sel1"
  el.dataset.luCls = JSON.stringify(CLS)
  el.dataset.luMultiple = ""
  el.dataset.luRemovable = ""
  el.dataset.luValue = JSON.stringify(["o1"])
  for (const [k, v] of Object.entries(attrs)) el.dataset[k] = v
  el.innerHTML =
    `<span data-part="select-control"><span data-part="select-value" data-ph>Pick</span><input data-lu-q hidden><svg></svg></span>` +
    `<div data-part="select-panel" hidden><div role="listbox" data-lu-list>` +
    [1, 2].map((i) => `<button type="button" data-part="listbox-option" data-lu-value="o${i}" aria-selected="${i === 1}">Option ${i}</button>`).join("") +
    `</div><div data-lu-empty hidden></div></div><select name="f[v]" hidden multiple><option value="o1" selected>Option 1</option></select>`
  document.body.appendChild(el)
  const h = hookOf(select, el)
  h.mounted()
  h.dirty = true // the hook draws the chips itself once something changed
  h.render()
  h.setOpen(true)
  const q = el.querySelector("input[data-lu-q]")
  q.value = "zzz"
  q.dispatchEvent(new window.Event("input", {bubbles: true}))
  return el
}

test("select: the empty text and the remove label come from the data attributes", {skip}, () => {
  const el = mountSelect({luNoResults: "Nada para %{query}", luRemoveLabel: "Remover"})
  assert.equal(el.querySelector("[data-lu-empty]").textContent, "Nada para zzz")
  assert.match(el.querySelector("[data-lu-remove]").getAttribute("aria-label"), /^Remover /)
})

test("select: English is the fallback without the attributes", {skip}, () => {
  const el = mountSelect()
  assert.equal(el.querySelector("[data-lu-empty]").textContent, "No results found")
  assert.match(el.querySelector("[data-lu-remove]").getAttribute("aria-label"), /^Remove /)
})

// --- tags_input ------------------------------------------------------------------------------

function mountTags(attrs = {}) {
  document.body.innerHTML = ""
  const el = document.createElement("div")
  el.id = "tags1"
  el.dataset.luCls = JSON.stringify(CLS)
  el.dataset.luMax = "1"
  for (const [k, v] of Object.entries(attrs)) el.dataset[k] = v
  el.innerHTML = `<span data-part="tags-input-tag" data-lu-value="a">a</span><input type="text"><select hidden multiple><option value="a" selected>a</option></select>`
  document.body.appendChild(el)
  const h = hookOf(tags, el)
  h.mounted()
  return el
}

test("tags_input: the limit placeholder comes from the data attribute", {skip}, () => {
  assert.equal(mountTags({luLimitPlaceholder: "Limite atingido"}).querySelector("input").placeholder, "Limite atingido")
  assert.equal(mountTags().querySelector("input").placeholder, "Limit reached")
})

// --- range -----------------------------------------------------------------------------------

function mountRange(extra = {}) {
  document.body.innerHTML = ""
  const el = document.createElement("div")
  el.id = "rg1"
  el.setAttribute("data-lu-config", JSON.stringify({min: 0, max: 10, step: 1, pair: true, vertical: false, format: "%{value}", marks: [], names: ["a", "b"], disabled: false, label: "Preco", ...extra}))
  el.innerHTML = `<span data-part="range-track"></span><span data-part="range-fill"></span><span data-part="range-thumb"></span><span data-part="range-thumb"></span>`
  document.body.appendChild(el)
  const h = hookOf(range, el)
  h.mounted()
  return [...el.querySelectorAll("[data-part=range-thumb]")].map((t) => t.getAttribute("aria-label"))
}

test("range: the words of the two thumbs come from the config", {skip}, () => {
  assert.deepEqual(mountRange({minWord: "mín", maxWord: "máx"}), ["Preco mín", "Preco máx"])
  assert.deepEqual(mountRange(), ["Preco min", "Preco max"])
})

// --- chart -----------------------------------------------------------------------------------

function mountChart(attrs = {}, options = {}) {
  document.body.innerHTML = ""
  const el = document.createElement("div")
  el.id = "ch1"
  el.dataset.luCls = JSON.stringify({svg: "svg", gridline: "g", axis: "a", line: "l", tip: "tip", tip_title: "tt", tip_row: "tr", tip_name: "tn", tip_value: "tv", tip_dot: "td", tip_total: "tot", band: "b", marker: "m", guide: "gd", seg: "s"})
  el.dataset.options = JSON.stringify({chart: {type: "line", height: 100}, series: [{name: "A", data: [1, 2]}, {name: "B", data: [3, 4]}], xaxis: {categories: ["x", "y"]}, ...options})
  el.dataset.formatters = "{}"
  for (const [k, v] of Object.entries(attrs)) el.dataset[k] = v
  el.innerHTML = "<div data-canvas></div>"
  document.body.appendChild(el)
  hookOf(chart, el).mounted()
  return el.querySelector("svg")
}

test("chart: the SVG name comes from the data attribute, then the options, then English", {skip}, () => {
  assert.equal(mountChart({luChartLabel: "Gráfico"}).getAttribute("aria-label"), "Gráfico")
  assert.equal(mountChart({luChartLabel: "Gráfico"}, {title: {text: "Receita"}}).getAttribute("aria-label"), "Receita")
  assert.equal(mountChart().getAttribute("aria-label"), "Chart")
})
