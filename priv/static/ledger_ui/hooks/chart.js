// Generic options-driven chart (`chart/1`): an ApexCharts-shaped subset drawn as SVG.
// Supported: chart.type line|area|bar (columns, or rows with plotOptions.bar.horizontal)|donut|pie,
// chart.height, chart.stacked (bar: series pile up in order, one `chart-stack-segment` rect each), series
// (a null value is a hole: the line breaks), xaxis.categories, labels, colors, stroke.curve (string or per series)
// /width/dashArray, markers.size, annotations.xaxis (range bands: x, x2, tone|fillColor, label.text), grid.show,
// yaxis.min/max/tickAmount, xaxis.tickAmount (about N category labels), tooltip (shared tooltip: y.formatter, total),
// legend.show. Anything else is ignored. Formatters are named
// (see `FORMATTERS`: thousands, thousands_round, dollars, number_br, brl, brl_full, thousands_br, k, brl_thousands, percent, percent_round, round, hours, minutes, none). Server push: push_event(socket, "ledger:chart", %{id: id, series: [...]}).
// The nodes it draws take their utility classes from `data-lu-cls` (JSON, written by the Elixir component)
// and carry a `data-part`; the hook never depends on a style class.
const NS = "http://www.w3.org/2000/svg"
const PALETTE = ["var(--lu-chart-1)", "var(--lu-chart-2)", "var(--lu-chart-3)", "var(--lu-chart-4)", "var(--lu-chart-5)"]

const group = (n) => String(n).replace(/\B(?=(\d{3})+(?!\d))/g, ".")
// pt-BR number pieces: one decimal at most, comma as the separator ("1,5"), "12" instead of "12,0"
const dec = (v) => String(Math.round(v * 10) / 10).replace(".", ",")
const big = (v) => Math.abs(v) >= 1000
const brlFull = (v) => {
  const cents = Math.round(Math.abs(v) * 100), int = Math.floor(cents / 100), frac = String(cents % 100).padStart(2, "0")
  return `${v < 0 && cents > 0 ? "-" : ""}R$ ${group(int)},${frac}`
}
const FORMATTERS = {
  thousands: (v) => `${v / 1000}k`,
  thousands_round: (v) => `${Math.round(v / 1000)}k`,
  dollars: (v) => `$${v}`,
  number_br: (v) => group(v),
  brl: (v) => "R$ " + String(v).replace(".", ","),
  thousands_br: (v) => (big(v) ? `${dec(v / 1000)} mil` : dec(v)), // 12000 -> "12 mil", 1500 -> "1,5 mil"
  k: (v) => (big(v) ? `${dec(v / 1000)}k` : dec(v)), // 12000 -> "12k", 1500 -> "1,5k"
  brl_thousands: (v) => (big(v) ? `R$ ${dec(v / 1000)} mil` : `R$ ${dec(v)}`), // 12000 -> "R$ 12 mil"
  brl_full: brlFull, // 1234.56 -> "R$ 1.234,56" (`brl` keeps its old, simpler output)
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

// per-series options: a single value, or a list indexed by series
const pick = (v, i) => (Array.isArray(v) ? v[i] : v)
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
    const svg = el("svg", {viewBox: `0 0 ${W} ${H}`, class: this.cls.svg, "data-part": "chart-svg", role: "img", "aria-label": o.title?.text || this.el.dataset.luChartLabel || "Chart"})
    svg.style.width = "100%"; svg.style.height = H + "px"
    this.tip = null
    if (type === "donut" || type === "pie") this.circular(svg, o, W, H, type === "donut")
    else this.cartesian(svg, o, W, H, type)
    this.canvas.replaceChildren(...[svg, this.tip].filter(Boolean))
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

  // annotations.xaxis: a translucent range behind the series. `x`/`x2` are a category or an index.
  bands(svg, o, cats, g) {
    const list = o.annotations?.xaxis
    if (!Array.isArray(list)) return
    const idx = (v) => (typeof v === "number" ? v : cats.findIndex((c) => String(c) === String(v)))
    const tones = {neg: "var(--lu-neg)", warn: "var(--lu-warn)", pos: "var(--lu-pos)", info: "var(--lu-info)"}
    list.forEach((a) => {
      const i0 = idx(a.x), i1 = a.x2 == null ? i0 : idx(a.x2)
      if (i0 < 0 || i1 < 0) return
      const [lo, hi] = i0 <= i1 ? [i0, i1] : [i1, i0]
      const base = g.horizontal ? g.pt : g.pl, len = g.horizontal ? g.ih : g.iw
      let a0, a1
      if (g.bar) { a0 = base + g.step * lo; a1 = base + g.step * (hi + 1) }
      else {
        const at = (i) => (g.n === 1 ? base + len / 2 : base + i * len / (g.n - 1))
        a0 = at(lo); a1 = at(hi)
        if (a0 === a1) { a0 -= g.step / 2; a1 += g.step / 2 }
      }
      a0 = Math.max(a0, base); a1 = Math.min(a1, base + len)
      // colour: a semantic tone, or a theme variable in fillColor; never a loose hex
      const fc = typeof a.fillColor === "string" && /^var\(--/.test(a.fillColor) ? a.fillColor.replace(/^var\(--(?!lu-|color-)/, "var(--lu-") : null
      const fill = tones[a.tone] || fc || tones.info
      const rect = g.horizontal
        ? {x: g.pl, y: a0, width: g.iw, height: Math.max(0, a1 - a0)}
        : {x: a0, y: g.pt, width: Math.max(0, a1 - a0), height: g.ih}
      svg.appendChild(el("rect", {...rect, fill, "fill-opacity": a.opacity ?? ".15", class: this.cls.band, "data-part": "chart-band"}))
      if (a.label?.text) {
        const tx = g.horizontal ? g.pl + 4 : (a0 + a1) / 2, ty = g.horizontal ? a0 + 12 : g.pt + 11
        svg.appendChild(el("text", {x: tx, y: ty, "text-anchor": g.horizontal ? "start" : "middle", class: this.cls.axis, "data-part": "chart-band-label"}, a.label.text))
      }
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
    if (stacked && o.yaxis?.max == null && max > 0) {
      // stack totals are rarely round: raise the top to a 1/2/2.5/5 x 10^k step so the grid labels read well
      const t = o.yaxis?.tickAmount ?? 4, raw = (max - Math.min(0, min)) / t, mag = 10 ** Math.floor(Math.log10(raw))
      const step = [1, 2, 2.5, 5, 10].map((m) => m * mag).find((c) => c >= raw - 1e-9)
      max = Math.min(0, min) + Math.ceil((max - Math.min(0, min)) / step - 1e-9) * step
    }
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
    // xaxis.tickAmount: about N labels, spread evenly (first and last always kept)
    const want = Number(o.xaxis?.tickAmount) || 0
    const shown = want > 0 && want < n ? new Set(Array.from({length: want}, (_, k) => (want === 1 ? 0 : Math.round(k * (n - 1) / (want - 1))))) : null
    cats.forEach((c, i) => {
      if (shown && !shown.has(i)) return
      if (horizontal) svg.appendChild(el("text", {class: this.cls.axis, "data-part": "chart-axis", x: pl - 8, y: C(i) + 4, "text-anchor": "end"}, String(c)))
      else svg.appendChild(el("text", {class: this.cls.axis, "data-part": "chart-axis", x: C(i), y: H - 6, "text-anchor": "middle"}, String(c)))
    })
    this.bands(svg, o, cats, {horizontal, bar: type === "bar", pl, pt, iw, ih, n, step: type === "bar" ? step : iw / Math.max(n - 1, 1)})
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
      // a nil value is a hole: the line breaks there (no 0 is drawn) and the area does not fill it
      const runs = []
      let run = null
      vals.forEach((v, i) => {
        if (v == null) { run = null; return }
        if (!run) runs.push(run = [])
        run.push([pl + (n === 1 ? iw / 2 : i * iw / (n - 1)), V(v), i])
      })
      if (!runs.length) return
      const straight = (pick(o.stroke?.curve, si) || "smooth") !== "smooth"
      const dOf = (pts) => {
        let d = `M${pts[0][0]} ${pts[0][1]}`
        if (pts.length === 1) return d + ` L${pts[0][0]} ${pts[0][1]}` // a lone point: a round cap shows it
        for (let i = 1; i < pts.length; i++) {
          const [x0, y0] = pts[i - 1], [x1, y1] = pts[i], mx = (x0 + x1) / 2
          d += straight ? ` L${x1} ${y1}` : ` C${mx} ${y0} ${mx} ${y1} ${x1} ${y1}`
        }
        return d
      }
      const ds = runs.map(dOf)
      if (type === "area") svg.appendChild(el("path", {d: runs.map((r, k) => `${ds[k]} L${r.at(-1)[0]} ${pt + ih} L${r[0][0]} ${pt + ih}Z`).join(" "), fill: cols[si], "fill-opacity": ".15"}))
      const w = pick(o.stroke?.width, si)
      const dash = pick(o.stroke?.dashArray, si)
      svg.appendChild(el("path", {d: ds.join(" "), class: this.cls.line, "data-part": "chart-line", style: `stroke:${cols[si]}${w ? `;stroke-width:${w}` : ""}${dash ? `;stroke-dasharray:${dash}` : ""}`}))
      const ms = Number(pick(o.markers?.size, si)) || 0
      if (ms > 0) {
        runs.flat().forEach(([cx, cy, i]) => {
          svg.appendChild(el("circle", {cx, cy, r: ms, fill: cols[si], class: this.cls.marker, "data-part": "chart-marker", "data-series": si, "data-index": i}))
        })
      }
    })
    if (o.legend?.show !== false && series.length > 1) {
      series.forEach((s, i) => {
        svg.appendChild(el("rect", {x: pl + i * 90, y: 0, width: 8, height: 8, rx: 2, fill: cols[i]}))
        svg.appendChild(el("text", {class: this.cls.axis, "data-part": "chart-axis", x: pl + i * 90 + 12, y: 8}, s.name ?? `Series ${i + 1}`))
      })
    }
    const bar = type === "bar"
    const at = (i) => (bar ? C(i) : (pl + (n === 1 ? iw / 2 : i * iw / (n - 1))))
    this.tooltip(svg, o, {W, H, cats, n, horizontal, bar, pl, pt, iw, ih, step, at,
      series: series.map((s, si) => ({name: s.name ?? `Series ${si + 1}`, color: cols[si], vals: s.data.map(yOf)}))})
  },

  // Shared tooltip (`tooltip` option present and not `enabled: false`): a guide and a box with every
  // series at the hovered/focused category. Mouse, or the keyboard once the chart has focus
  // (arrows, Home, End, Escape); the box is a polite live region and a <desc> lists all the data.
  tooltip(svg, o, m) {
    this.tip = null
    if (!o.tooltip || typeof o.tooltip !== "object" || o.tooltip.enabled === false || !m.n) return
    const f = this.fmt(o, "tooltip.y.formatter")
    const val = (v) => (v == null ? "\u2014" : f(v))
    const total = !!o.tooltip.total, totalLabel = o.tooltip.totalLabel || this.el.dataset.luTotalLabel || "Total"
    const sum = (i) => m.series.reduce((a, s) => a + (s.vals[i] == null ? 0 : Number(s.vals[i])), 0)

    const desc = el("desc", {}, [o.title?.text, ...m.cats.map((c, i) =>
      `${c}: ` + m.series.map((s) => `${s.name} ${val(s.vals[i])}`).join(", ") + (total ? `, ${totalLabel} ${f(sum(i))}` : ""))].filter(Boolean).join(". "))
    svg.insertBefore(desc, svg.firstChild)

    const guide = el("line", {class: this.cls.guide, "data-part": "chart-guide"})
    guide.style.display = "none"
    const hit = el("rect", {x: m.pl, y: m.pt, width: m.iw, height: m.ih, fill: "transparent", class: this.cls.hit, "data-part": "chart-hit"})
    svg.append(guide, hit)
    svg.setAttribute("tabindex", "0")

    const tip = document.createElement("div")
    tip.setAttribute("data-part", "chart-tip"); tip.setAttribute("role", "status"); tip.setAttribute("aria-live", "polite")
    if (this.cls.tip) tip.className = this.cls.tip
    tip.style.display = "none"
    this.tip = tip

    const mk = (tag, part, text, cls) => {
      const n = document.createElement(tag)
      n.setAttribute("data-part", `chart-tip-${part}`)
      if (cls) n.className = cls
      if (text != null) n.textContent = text
      return n
    }
    let active = -1
    const show = (i) => {
      active = i
      const x = m.at(i)
      if (m.horizontal) { guide.setAttribute("x1", m.pl); guide.setAttribute("x2", m.pl + m.iw); guide.setAttribute("y1", x); guide.setAttribute("y2", x) }
      else { guide.setAttribute("x1", x); guide.setAttribute("x2", x); guide.setAttribute("y1", m.pt); guide.setAttribute("y2", m.pt + m.ih) }
      guide.style.display = ""
      tip.replaceChildren(mk("b", "title", String(m.cats[i]), this.cls.tip_title))
      m.series.forEach((s) => {
        const row = mk("div", "row", null, this.cls.tip_row)
        const dot = mk("i", "dot", null, this.cls.tip_dot)
        dot.style.background = s.color
        row.append(dot, mk("span", "name", s.name, this.cls.tip_name), mk("em", "value", val(s.vals[i]), this.cls.tip_value))
        tip.appendChild(row)
      })
      if (total) {
        const row = mk("div", "total", null, this.cls.tip_row)
        row.className = `${this.cls.tip_row || ""} ${this.cls.tip_total || ""}`.trim()
        row.append(mk("span", "name", totalLabel, this.cls.tip_name), mk("em", "value", f(sum(i)), this.cls.tip_value))
        tip.appendChild(row)
      }
      tip.style.display = ""
      const sc = svg.getBoundingClientRect().width / m.W || 1
      const px = m.horizontal ? (m.pl + m.iw / 2) * sc : x * sc, tw = tip.offsetWidth
      let left = px + 14
      if (left + tw > m.W * sc) left = Math.max(0, px - tw - 14)
      tip.style.left = left + "px"
      tip.style.top = (m.horizontal ? x * sc : m.pt * sc) + "px"
    }
    const hide = () => { active = -1; guide.style.display = "none"; tip.style.display = "none" }
    const clamp = (i) => Math.max(0, Math.min(m.n - 1, i))
    hit.addEventListener("mousemove", (e) => {
      const box = svg.getBoundingClientRect()
      if (!box.width) return
      const sc = m.W / box.width
      if (m.horizontal) show(clamp(Math.floor(((e.clientY - box.top) * sc - m.pt) / m.step)))
      else if (m.bar) show(clamp(Math.floor(((e.clientX - box.left) * sc - m.pl) / m.step)))
      else show(clamp(Math.round(((e.clientX - box.left) * sc - m.pl) / m.iw * (m.n - 1))))
    })
    hit.addEventListener("mouseleave", hide)
    svg.addEventListener("focus", () => { if (active < 0) show(0) })
    svg.addEventListener("blur", hide)
    svg.addEventListener("keydown", (e) => {
      const next = {ArrowRight: active + 1, ArrowDown: active + 1, ArrowLeft: active - 1, ArrowUp: active - 1, Home: 0, End: m.n - 1}[e.key]
      if (e.key === "Escape") return hide()
      if (next === undefined) return
      e.preventDefault(); show(clamp(next))
    })
  }
}
