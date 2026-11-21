// Generic options-driven chart (`chart/1`): an ApexCharts-shaped subset drawn as SVG.
// Supported: chart.type line|area|bar (columns, or rows with plotOptions.bar.horizontal)|donut|pie,
// chart.height, chart.stacked (bar: series pile up in order, one `chart-stack-segment` rect each), series, xaxis.categories, labels, colors, stroke.curve/width, grid.show,
// yaxis.min/max/tickAmount, legend.show. Anything else is ignored. Formatters are named
// (see `FORMATTERS`). Server push: push_event(socket, "ledger:chart", %{id: id, series: [...]}).
// The nodes it draws take their utility classes from `data-lu-cls` (JSON, written by the Elixir component)
// and carry a `data-part`; the hook never depends on a style class.
const NS = "http://www.w3.org/2000/svg"
const PALETTE = ["var(--lu-chart-1)", "var(--lu-chart-2)", "var(--lu-chart-3)", "var(--lu-chart-4)", "var(--lu-chart-5)"]

const group = (n) => String(n).replace(/\B(?=(\d{3})+(?!\d))/g, ".")
const FORMATTERS = {
  thousands: (v) => `${v / 1000}k`,
  thousands_round: (v) => `${Math.round(v / 1000)}k`,
  dollars: (v) => `$${v}`,
  number_br: (v) => group(v),
  brl: (v) => "R$ " + String(v).replace(".", ","),
  percent: (v) => `${v}%`,
  percent_round: (v) => `${Math.round(v)}%`,
  round: (v) => String(Math.round(v)),
  hours: (v) => `${v}h`,
  minutes: (v) => `${v} min`,
  none: () => ""
}

const el = (tag, attrs = {}, text) => {
  const n = document.createElementNS(NS, tag)
  for (const [k, v] of Object.entries(attrs)) if (v !== undefined) n.setAttribute(k, v)
  if (text != null) n.textContent = text
  return n
}

const getPath = (o, path) => path.split(".").reduce((a, k) => (a == null ? a : a[k]), o)
const setPath = (o, path, v) => {
  const ks = path.split("."); const last = ks.pop()
  const t = ks.reduce((a, k) => (a[k] ??= {}), o); t[last] = v
}
const merge = (a, b) => {
  for (const [k, v] of Object.entries(b || {})) {
    a[k] = v && typeof v === "object" && !Array.isArray(v) && a[k] && typeof a[k] === "object" ? merge(a[k], v) : v
  }
  return a
}

export default {
  mounted() {
    this.canvas = this.el.querySelector("[data-canvas]")
    try { this.cls = JSON.parse(this.el.dataset.luCls || "{}") } catch (_) { this.cls = {} }
    this.extra = {}
    this.load()
    this.ro = new ResizeObserver(() => this.draw())
    this.ro.observe(this.el)
    this.handleEvent("ledger:chart", (p) => {
      if (p.id && p.id.replace(/^#/, "") !== this.el.id) return
      if (p.series) this.extra.series = p.series
      if (p.options) merge(this.extra, p.options)
      this.draw()
    })
  },
  updated() { this.extra = {}; this.load() },
  destroyed() { this.ro && this.ro.disconnect() },

  load() {
    try { this.options = JSON.parse(this.el.dataset.options || "{}") } catch (_) { this.options = {} }
    try { this.formatters = JSON.parse(this.el.dataset.formatters || "{}") } catch (_) { this.formatters = {} }
    this.draw()
  },

  config() {
    const o = JSON.parse(JSON.stringify(this.options))
    for (const [path, name] of Object.entries(this.formatters)) setPath(o, path, name)
    const {series, ...rest} = this.extra
    merge(o, rest)
    if (series) {
      o.series = series.map((s, i) => ({...(this.options.series || [])[i], ...(typeof s === "object" && !Array.isArray(s) ? s : {data: s})}))
    }
    this.el.dispatchEvent(new CustomEvent("ledger:chart:options", {bubbles: true, detail: {options: o}}))
    return o
  },

  fmt(o, path) {
    const f = getPath(o, path)
    return typeof f === "function" ? f : FORMATTERS[f] || ((v) => String(v))
  },

  draw() {
    const o = this.config()
    const type = o.chart?.type || "line"
    const W = Math.max(this.el.clientWidth || 600, 120)
    const H = typeof o.chart?.height === "number" ? o.chart.height : parseInt(o.chart?.height) || 300
    const svg = el("svg", {viewBox: `0 0 ${W} ${H}`, class: this.cls.svg, "data-part": "chart-svg", role: "img", "aria-label": o.title?.text || "Chart"})
    svg.style.width = "100%"; svg.style.height = H + "px"
    if (type === "donut" || type === "pie") this.circular(svg, o, W, H, type === "donut")
    else this.cartesian(svg, o, W, H, type)
    this.canvas.replaceChildren(svg)
  },

  colors(o, n) { return Array.from({length: n}, (_, i) => o.colors?.[i] || PALETTE[i % PALETTE.length]) },

  circular(svg, o, W, H, donut) {
    const vals = (o.series || []).map(Number), total = vals.reduce((a, b) => a + b, 0) || 1
    const cols = this.colors(o, vals.length), r = Math.min(W, H) / 2 - 8, cx = W / 2, cy = H / 2
    let a0 = -Math.PI / 2
    vals.forEach((v, i) => {
      const a1 = a0 + v / total * Math.PI * 2 - 1e-4, large = a1 - a0 > Math.PI ? 1 : 0
      const p = (a, rad) => [cx + rad * Math.cos(a), cy + rad * Math.sin(a)]
      const [x0, y0] = p(a0, r), [x1, y1] = p(a1, r), ri = donut ? r * 0.62 : 0
      const [x2, y2] = p(a1, ri), [x3, y3] = p(a0, ri)
      const d = `M${x0} ${y0} A${r} ${r} 0 ${large} 1 ${x1} ${y1} ` + (donut ? `L${x2} ${y2} A${ri} ${ri} 0 ${large} 0 ${x3} ${y3}Z` : `L${cx} ${cy}Z`)
      const path = el("path", {d, fill: cols[i], class: this.cls.seg, "data-part": "chart-segment"})
      path.appendChild(el("title", {}, `${o.labels?.[i] ?? ""} ${v}`.trim()))
      svg.appendChild(path); a0 += v / total * Math.PI * 2
    })
  },

  cartesian(svg, o, W, H, type) {
    const series = (o.series || []).map((s) => (typeof s === "object" && !Array.isArray(s) ? s : {data: s}))
    const horizontal = type === "bar" && o.plotOptions?.bar?.horizontal
    const cats = o.xaxis?.categories || (series[0]?.data || []).map((_, i) => i + 1)
    const n = cats.length, cols = this.colors(o, series.length)
    const stacked = type === "bar" && !!o.chart?.stacked
    const yOf = (d) => (typeof d === "object" && d !== null ? d.y : d)
    let all = series.flatMap((s) => s.data.map(yOf)).filter((v) => v != null)
    if (stacked) {
      // the axis spans the stack totals: positives pile up from 0, negatives down from 0
      const pos = Array(n).fill(0), neg = Array(n).fill(0)
      series.forEach((s) => s.data.forEach((d, i) => { const v = yOf(d); if (v > 0) pos[i] += v; else if (v < 0) neg[i] += v }))
      all = [...pos, ...neg, 0]
    }
    const min = o.yaxis?.min ?? (type === "bar" ? Math.min(0, ...(stacked ? all : [0])) : Math.min(...all))
    let max = o.yaxis?.max ?? Math.max(...all)
    if (min === max) max = min + 1
    const yfmt = this.fmt(o, "yaxis.labels.formatter")
    const pl = horizontal ? 70 : 46, pr = 14, pt = 12, pb = 26, iw = W - pl - pr, ih = H - pt - pb
    const V = (v) => horizontal ? pl + (v - min) / (max - min) * iw : pt + ih - (v - min) / (max - min) * ih
    const ticks = o.yaxis?.tickAmount ?? 4
    if (o.grid?.show !== false) {
      for (let t = 0; t <= ticks; t++) {
        const v = min + (max - min) * t / ticks, p = V(v), label = yfmt(Math.round(v * 100) / 100)
        if (horizontal) {
          svg.appendChild(el("line", {class: this.cls.gridline, "data-part": "chart-gridline", x1: p, x2: p, y1: pt, y2: pt + ih}))
          svg.appendChild(el("text", {class: this.cls.axis, "data-part": "chart-axis", x: p, y: H - 6, "text-anchor": "middle"}, label))
        } else {
          svg.appendChild(el("line", {class: this.cls.gridline, "data-part": "chart-gridline", x1: pl, x2: W - pr, y1: p, y2: p}))
          svg.appendChild(el("text", {class: this.cls.axis, "data-part": "chart-axis", x: pl - 8, y: p + 4, "text-anchor": "end"}, label))
        }
      }
    }
    const step = (horizontal ? ih : iw) / n
    const C = (i) => (horizontal ? pt : pl) + step * (i + 0.5)
    cats.forEach((c, i) => {
      if (horizontal) svg.appendChild(el("text", {class: this.cls.axis, "data-part": "chart-axis", x: pl - 8, y: C(i) + 4, "text-anchor": "end"}, String(c)))
      else svg.appendChild(el("text", {class: this.cls.axis, "data-part": "chart-axis", x: C(i), y: H - 6, "text-anchor": "middle"}, String(c)))
    })
    const posAcc = Array(n).fill(0), negAcc = Array(n).fill(0)
    series.forEach((s, si) => {
      const vals = s.data.map(yOf)
      if (stacked) {
        // series go from the baseline outwards in order (bottom to top, or left to right); one rect each
        const bw = Math.min(step * 0.6, 40)
        const radius = o.plotOptions?.bar?.borderRadius ?? 0
        vals.forEach((v, i) => {
          if (v == null || v === 0) return
          const acc = v > 0 ? posAcc : negAcc
          const a = V(acc[i]), b = V(acc[i] + v)
          acc[i] += v
          const attrs = horizontal
            ? {x: Math.min(a, b), y: C(i) - bw / 2, width: Math.abs(b - a), height: bw}
            : {x: C(i) - bw / 2, y: Math.min(a, b), width: bw, height: Math.abs(a - b)}
          const last = !series.slice(si + 1).some((t) => { const w = yOf(t.data[i]); return w != null && w !== 0 && (w > 0) === (v > 0) })
          const r = el("rect", {...attrs, rx: last ? radius : 0, fill: cols[si], "data-part": "chart-stack-segment", "data-series": si, "data-index": i})
          r.appendChild(el("title", {}, `${s.name ?? ""} ${v}`.trim()))
          svg.appendChild(r)
        })
        return
      }
      if (type === "bar") {
        const bw = Math.min(step * 0.6 / series.length, 40), off = (si - (series.length - 1) / 2) * bw
        vals.forEach((v, i) => {
          if (v == null) return
          const base = V(Math.max(min, 0)), tip = V(v)
          const attrs = horizontal
            ? {x: Math.min(base, tip), y: C(i) + off - bw / 2, width: Math.abs(tip - base), height: bw}
            : {x: C(i) + off - bw / 2, y: Math.min(base, tip), width: bw, height: Math.abs(base - tip)}
          const r = el("rect", {...attrs, rx: o.plotOptions?.bar?.borderRadius ?? 4, fill: cols[si]})
          r.appendChild(el("title", {}, `${s.name ?? ""} ${v}`.trim()))
          svg.appendChild(r)
        })
        return
      }
      const pts = vals.map((v, i) => (v == null ? null : [pl + (n === 1 ? iw / 2 : i * iw / (n - 1)), V(v)])).filter(Boolean)
      if (!pts.length) return
      const straight = (o.stroke?.curve || "smooth") !== "smooth"
      let d = `M${pts[0][0]} ${pts[0][1]}`
      for (let i = 1; i < pts.length; i++) {
        const [x0, y0] = pts[i - 1], [x1, y1] = pts[i], mx = (x0 + x1) / 2
        d += straight ? ` L${x1} ${y1}` : ` C${mx} ${y0} ${mx} ${y1} ${x1} ${y1}`
      }
      if (type === "area") svg.appendChild(el("path", {d: `${d} L${pts.at(-1)[0]} ${pt + ih} L${pts[0][0]} ${pt + ih}Z`, fill: cols[si], "fill-opacity": ".15"}))
      const w = Array.isArray(o.stroke?.width) ? o.stroke.width[si] : o.stroke?.width
      svg.appendChild(el("path", {d, class: this.cls.line, "data-part": "chart-line", style: `stroke:${cols[si]}${w ? `;stroke-width:${w}` : ""}`}))
    })
    if (o.legend?.show !== false && series.length > 1) {
      series.forEach((s, i) => {
        svg.appendChild(el("rect", {x: pl + i * 90, y: 0, width: 8, height: 8, rx: 2, fill: cols[i]}))
        svg.appendChild(el("text", {class: this.cls.axis, "data-part": "chart-axis", x: pl + i * 90 + 12, y: 8}, s.name ?? `Series ${i + 1}`))
      })
    }
  }
}
