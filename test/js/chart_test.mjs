// Draws `priv/static/ledger_ui/hooks/chart.js` into a jsdom document and checks the SVG.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/chart_test.mjs
// jsdom is not a dependency of the package: the test is skipped when it cannot be found.
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

const CLS = {svg: "svg", gridline: "grid", axis: "axis", line: "line", seg: "seg", tip: "tip", tip_title: "tt", tip_row: "tr", tip_name: "tn", tip_value: "tv", tip_dot: "td", tip_total: "ttot", band: "band", marker: "mk", guide: "gd", sr: "sr"}

let hook
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true})
  globalThis.window = dom.window
  globalThis.document = dom.window.document
  globalThis.CustomEvent = dom.window.CustomEvent
  globalThis.ResizeObserver = class { observe() {} disconnect() {} }
  const dir = mkdtempSync(join(tmpdir(), "lu-chart-"))
  writeFileSync(join(dir, "chart.mjs"), readFileSync(join(here, "../../priv/static/ledger_ui/hooks/chart.js"), "utf8"))
  hook = (await import(pathToFileURL(join(dir, "chart.mjs")))).default
}

// Mounts a chart with the given options and returns {svg, h, canvas}.
function mount(options, formatters = {}) {
  const el = document.createElement("div")
  el.id = "c" + Math.random().toString(36).slice(2)
  el.dataset.luCls = JSON.stringify(CLS)
  el.dataset.options = JSON.stringify(options)
  el.dataset.formatters = JSON.stringify(formatters)
  el.innerHTML = "<div data-canvas></div>"
  document.body.appendChild(el)
  const h = Object.assign(Object.create(hook), {el, handleEvent() {}})
  h.mounted()
  const canvas = el.querySelector("[data-canvas]")
  return {el, h, canvas, svg: canvas.querySelector("svg")}
}
const parts = (root, name) => [...root.querySelectorAll(`[data-part="${name}"]`)]
const num = (n, a) => parseFloat(n.getAttribute(a))

test("stacked columns: heights add up, series go bottom to top", {skip}, () => {
  const {svg} = mount({
    chart: {type: "bar", stacked: true, height: 300},
    series: [{name: "A", data: [10, 20]}, {name: "B", data: [30, 5]}, {name: "C", data: [0, 15]}],
    xaxis: {categories: ["x", "y"]}
  })
  const segs = parts(svg, "chart-stack-segment")
  assert.equal(segs.length, 5) // the 0 of C draws nothing
  const col = (i) => segs.filter((s) => s.dataset.index == i)
  const sum = (c) => c.reduce((a, s) => a + num(s, "height"), 0), h0 = sum(col(0)), h1 = sum(col(1))
  // column 0 totals 40, column 1 totals 40 (20+5+15): same stack height
  assert.ok(Math.abs(h0 - h1) < 1e-6)
  // series A (first) sits below series B: larger y
  const [a, b] = col(0)
  assert.equal(a.dataset.series, "0"); assert.equal(b.dataset.series, "1")
  assert.ok(num(a, "y") > num(b, "y"))
  assert.ok(Math.abs(num(a, "y") - (num(b, "y") + num(b, "height"))) < 1e-6) // B starts where A ends
  assert.ok(Math.abs(num(b, "height") / num(a, "height") - 3) < 1e-6)
})

test("stacked horizontal bars pile up left to right", {skip}, () => {
  const {svg} = mount({
    chart: {type: "bar", stacked: true, height: 200},
    plotOptions: {bar: {horizontal: true}},
    series: [{name: "A", data: [10]}, {name: "B", data: [30]}],
    xaxis: {categories: ["x"]}
  })
  const [a, b] = parts(svg, "chart-stack-segment")
  assert.ok(num(a, "x") < num(b, "x"))
  assert.ok(Math.abs(num(a, "x") + num(a, "width") - num(b, "x")) < 1e-6)
  assert.ok(Math.abs(num(b, "width") / num(a, "width") - 3) < 1e-6)
})

test("without the new options a bar chart has no stack segments", {skip}, () => {
  const {svg} = mount({chart: {type: "bar"}, series: [{data: [1, 2]}], xaxis: {categories: ["a", "b"]}})
  assert.equal(parts(svg, "chart-stack-segment").length, 0)
  assert.equal(svg.querySelectorAll("rect").length, 2)
})
