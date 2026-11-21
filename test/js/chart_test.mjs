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

const line = (extra = {}, series) => mount({
  chart: {type: "line", height: 300},
  series: series || [{name: "A", data: [1, 2, 3, 4, 5]}, {name: "B", data: [5, 4, 3, 2, 1]}],
  xaxis: {categories: ["a", "b", "c", "d", "e"]},
  ...extra
})

test("band: a tone rect spans the categories, behind the series", {skip}, () => {
  const {svg} = line({annotations: {xaxis: [{x: "b", x2: "d", tone: "neg", label: {text: "Ruptura"}}]}})
  const [band] = parts(svg, "chart-band")
  assert.equal(band.getAttribute("fill"), "var(--lu-neg)")
  assert.equal(band.getAttribute("fill-opacity"), ".15")
  assert.equal(band.getAttribute("class"), "band")
  // plot is 600 wide: pl 46, pr 14 -> iw 540, point spacing 135: b = 181, d = 451
  assert.equal(num(band, "x"), 181); assert.equal(num(band, "width"), 270)
  assert.equal(parts(svg, "chart-band-label")[0].textContent, "Ruptura")
  const all = [...svg.children]
  assert.ok(all.indexOf(band) < all.indexOf(parts(svg, "chart-line")[0]))
})

test("band: index x, fillColor only as a theme variable, loose hex is ignored", {skip}, () => {
  const {svg} = line({annotations: {xaxis: [{x: 0, x2: 1, fillColor: "var(--chart-3)"}, {x: 2, fillColor: "#ff0000"}]}})
  const [b1, b2] = parts(svg, "chart-band")
  assert.equal(b1.getAttribute("fill"), "var(--lu-chart-3)")
  assert.equal(b2.getAttribute("fill"), "var(--lu-info)")
})

test("band on bars covers whole slots", {skip}, () => {
  const {svg} = mount({chart: {type: "bar"}, series: [{data: [1, 2, 3]}], xaxis: {categories: ["a", "b", "c"]}, annotations: {xaxis: [{x: "b", tone: "warn"}]}})
  const [band] = parts(svg, "chart-band")
  assert.equal(num(band, "x"), 46 + 180); assert.equal(num(band, "width"), 180)
})

test("markers: size as number or per series", {skip}, () => {
  assert.equal(parts(line({markers: {size: 4}}).svg, "chart-marker").length, 10)
  const {svg} = line({markers: {size: [0, 5]}})
  const ms = parts(svg, "chart-marker")
  assert.equal(ms.length, 5)
  assert.ok(ms.every((m) => m.getAttribute("r") === "5" && m.dataset.series === "1"))
  assert.equal(parts(line().svg, "chart-marker").length, 0)
})

test("stroke.dashArray: number or list", {skip}, () => {
  const lines = (o) => parts(line(o).svg, "chart-line").map((l) => l.getAttribute("style"))
  assert.ok(lines({stroke: {dashArray: 5}}).every((s) => s.includes("stroke-dasharray:5")))
  const [a, b] = lines({stroke: {dashArray: [0, 6]}})
  assert.ok(!a.includes("dasharray")); assert.ok(b.includes("stroke-dasharray:6"))
  assert.ok(!lines({})[0].includes("dasharray"))
})

test("stroke.curve: smooth is the default, straight per series or global", {skip}, () => {
  const d = (o) => parts(line(o).svg, "chart-line").map((l) => l.getAttribute("d"))
  assert.ok(d({})[0].includes("C"))
  assert.ok(d({stroke: {curve: "straight"}}).every((p) => !p.includes("C") && p.includes("L")))
  const [a, b] = d({stroke: {curve: ["straight", "smooth"]}})
  assert.ok(!a.includes("C")); assert.ok(b.includes("C"))
})

const fire = (node, type, init = {}) => node.dispatchEvent(new window.Event(type, {bubbles: true, ...init}))
const key = (node, k) => node.dispatchEvent(new window.KeyboardEvent("keydown", {key: k, bubbles: true, cancelable: true}))
const rows = (c) => [...c.querySelectorAll('[data-part="chart-tip-row"],[data-part="chart-tip-total"]')].map((r) => [parts(r, "chart-tip-name")[0].textContent, parts(r, "chart-tip-value")[0].textContent])

test("tooltip: off without the tooltip option, so the SVG is unchanged", {skip}, () => {
  const {svg, canvas} = line()
  assert.equal(parts(svg, "chart-hit").length, 0)
  assert.equal(parts(canvas, "chart-tip").length, 0)
  assert.equal(svg.getAttribute("tabindex"), null)
})

test("tooltip: keyboard focus shows a guide and one row per series, formatted", {skip}, () => {
  const {svg, canvas} = line({tooltip: {y: {formatter: "percent"}}}, [{name: "A", data: [12, 20, 3, 4, 5]}, {name: "B", data: [5, 1.5, 3, 2, 1]}])
  const tip = parts(canvas, "chart-tip")[0]
  assert.equal(tip.style.display, "none")
  assert.equal(svg.getAttribute("tabindex"), "0")
  fire(svg, "focus")
  assert.equal(tip.style.display, "")
  assert.equal(parts(tip, "chart-tip-title")[0].textContent, "a")
  assert.deepEqual(rows(tip), [["A", "12%"], ["B", "5%"]])
  assert.notEqual(parts(svg, "chart-guide")[0].style.display, "none")
  key(svg, "ArrowRight")
  assert.equal(parts(tip, "chart-tip-title")[0].textContent, "b")
  assert.deepEqual(rows(tip), [["A", "20%"], ["B", "1.5%"]])
  key(svg, "End"); assert.equal(parts(tip, "chart-tip-title")[0].textContent, "e")
  key(svg, "Escape"); assert.equal(tip.style.display, "none")
  assert.equal(tip.getAttribute("aria-live"), "polite")
  assert.match(svg.querySelector("desc").textContent, /a: A 12%, B 5%\./)
})

test("tooltip.total adds a total row (stacked)", {skip}, () => {
  const {svg, canvas} = mount({chart: {type: "bar", stacked: true}, series: [{name: "A", data: [10, 1]}, {name: "B", data: [30, 2]}], xaxis: {categories: ["x", "y"]}, tooltip: {total: true}})
  fire(svg, "focus")
  const tip = parts(canvas, "chart-tip")[0]
  assert.deepEqual(rows(tip), [["A", "10"], ["B", "30"], ["Total", "40"]])
  assert.equal(parts(tip, "chart-tip-total").length, 1)
})

const xlabels = (svg, cats) => parts(svg, "chart-axis").map((t) => t.textContent).filter((t) => cats.includes(t))

test("xaxis.tickAmount limits the category labels, evenly, keeping first and last", {skip}, () => {
  const cats = Array.from({length: 13}, (_, i) => `c${i}`)
  const data = cats.map((_, i) => i)
  const mk = (extra) => mount({chart: {type: "line"}, series: [{data}], xaxis: {categories: cats, ...extra}}).svg
  assert.equal(xlabels(mk({}), cats).length, 13)
  assert.deepEqual(xlabels(mk({tickAmount: 5}), cats), ["c0", "c3", "c6", "c9", "c12"])
  assert.deepEqual(xlabels(mk({tickAmount: 1}), cats), ["c0"])
  assert.equal(xlabels(mk({tickAmount: 40}), cats).length, 13)
})

test("nil breaks the line (no 0 drawn), the area and the markers skip it", {skip}, () => {
  const {svg} = mount({chart: {type: "area", height: 300}, series: [{name: "A", data: [1, 2, null, 4, 5]}], xaxis: {categories: ["a", "b", "c", "d", "e"]}, stroke: {curve: "straight"}, markers: {size: 3}})
  const [path] = parts(svg, "chart-line")
  assert.equal((path.getAttribute("d").match(/M/g) || []).length, 2) // two runs
  assert.equal((path.getAttribute("d").match(/L/g) || []).length, 2)
  // axis range is 1..5: the nil is not a 0, so the lowest point sits on the bottom grid line (y = 12 + 262)
  const ys = parts(svg, "chart-marker").map((m) => num(m, "cy"))
  assert.equal(ys.length, 4)
  assert.equal(Math.max(...ys), 274)
  const area = svg.querySelector("path[fill-opacity]").getAttribute("d")
  assert.equal((area.match(/Z/g) || []).length, 2)
  assert.deepEqual(parts(svg, "chart-marker").map((m) => m.dataset.index), ["0", "1", "3", "4"])
})

test("nil: lone points still show, all-nil series draw nothing, tooltip says em dash", {skip}, () => {
  const {svg, canvas} = mount({chart: {type: "line"}, series: [{name: "A", data: [1, null, 3]}, {name: "B", data: [null, null, null]}], xaxis: {categories: ["a", "b", "c"]}, tooltip: {}})
  const lines = parts(svg, "chart-line")
  assert.equal(lines.length, 1)
  assert.match(lines[0].getAttribute("d"), /^M[\d.]+ [\d.]+ L[\d.]+ [\d.]+ M[\d.]+ [\d.]+ L/)
  fire(svg, "focus"); key(svg, "ArrowRight")
  assert.deepEqual(rows(parts(canvas, "chart-tip")[0]), [["A", "\u2014"], ["B", "\u2014"]])
})

test("formatters: thousands_br, k, brl_thousands, brl_full (and brl untouched)", {skip}, () => {
  const fmt = (name, v) => {
    const {svg, canvas} = mount({chart: {type: "bar", stacked: true}, series: [{name: "A", data: [v]}], xaxis: {categories: ["x"]}, tooltip: {}}, {"tooltip.y.formatter": name})
    fire(svg, "focus")
    return rows(parts(canvas, "chart-tip")[0])[0][1]
  }
  assert.equal(fmt("thousands_br", 12000), "12 mil")
  assert.equal(fmt("thousands_br", 1500), "1,5 mil")
  assert.equal(fmt("thousands_br", 500), "500")
  assert.equal(fmt("k", 12000), "12k")
  assert.equal(fmt("k", 1500), "1,5k")
  assert.equal(fmt("brl_thousands", 12000), "R$ 12 mil")
  assert.equal(fmt("brl_thousands", 800), "R$ 800")
  assert.equal(fmt("brl_full", 1234.56), "R$ 1.234,56")
  assert.equal(fmt("brl_full", 5), "R$ 5,00")
  assert.equal(fmt("brl_full", -1234.5), "-R$ 1.234,50")
  assert.equal(fmt("brl", 1234.5), "R$ 1234,5") // unchanged
})

test("formatters on the axes", {skip}, () => {
  const {svg} = mount({chart: {type: "bar"}, series: [{data: [0, 12000]}], xaxis: {categories: ["a", "b"]}, yaxis: {tickAmount: 1}}, {"yaxis.labels.formatter": "k"})
  assert.deepEqual(parts(svg, "chart-axis").map((t) => t.textContent).slice(0, 2), ["0", "12k"])
})

test("Nexus Pro cases: sales by segment (stacked + total) and stock projection", {skip}, () => {
  const seg = mount({
    chart: {type: "bar", stacked: true, height: 280},
    series: [{name: "Loja", data: [12000, 18000, 9000]}, {name: "Online", data: [7000, 9000, 15000]}],
    xaxis: {categories: ["Jan", "Fev", "Mar"]},
    colors: ["var(--lu-chart-1)", "var(--lu-chart-3)"],
    tooltip: {total: true}
  }, {"yaxis.labels.formatter": "k", "tooltip.y.formatter": "brl_thousands"})
  fire(seg.svg, "focus")
  assert.deepEqual(rows(parts(seg.canvas, "chart-tip")[0]), [["Loja", "R$ 12 mil"], ["Online", "R$ 7 mil"], ["Total", "R$ 19 mil"]])

  const proj = mount({
    chart: {type: "line", height: 280},
    series: [{name: "Estoque", data: [120, 90, 60, 30, null, null]}, {name: "Projeção", data: [null, null, null, 30, 10, -5]}],
    xaxis: {categories: ["S1", "S2", "S3", "S4", "S5", "S6"], tickAmount: 3},
    stroke: {curve: "straight", width: [2.5, 2], dashArray: [0, 6]},
    markers: {size: [4, 3]},
    annotations: {xaxis: [{x: "S5", x2: "S6", tone: "neg", label: {text: "Ruptura"}}]},
    tooltip: {}
  })
  assert.equal(parts(proj.svg, "chart-band").length, 1)
  assert.equal(parts(proj.svg, "chart-marker").length, 4 + 3)
  assert.ok(parts(proj.svg, "chart-line")[1].getAttribute("style").includes("stroke-dasharray:6"))
})
