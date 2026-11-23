// Responsive layout, hover guide and tooltip of the server-rendered `line_chart/1`.
//
// The server draws the SVG at a default width. The hook measures the container (ResizeObserver,
// one layout per animation frame) and re-lays the SAME geometry out at the real width: the
// viewBox becomes `0 0 <width> <height>` and the SVG gets its CSS height, so 1 user unit is 1 CSS
// pixel and the axis text and strokes keep their CSS size at any width. The geometry (and the
// tooltip rows) ride in `data-lu-chart-data` (JSON); only attributes of existing nodes change.
// Nodes are found by `data-part`, never by a style class; the tooltip rows the hook builds take their
// classes from `data-lu-config` (written by the Elixir component, which owns the utilities).
const part = (root, name) => root.querySelector(`[data-part="line-chart-${name}"]`)
const parts = (root, name) => root.querySelectorAll(`[data-part="line-chart-${name}"]`)

const MIN_LABEL_GAP = 30 // px between two X labels before every other one is hidden

const f = (v) => String(Math.round(v * 100) / 100)

export default {
  mounted() {
    this.onMove = (e) => this.move(e)
    this.onLeave = () => this.leave()
    this.width = 0
    this.ro = new ResizeObserver(() => this.schedule())
    this.ro.observe(this.el)
    this.bind()
  },
  updated() { this.bind() },
  destroyed() {
    this.unbind()
    this.ro && this.ro.disconnect()
    cancelAnimationFrame(this.raf)
  },

  bind() {
    this.unbind()
    try { this.data = JSON.parse(this.el.dataset.luChartData) } catch (_) { this.data = null }
    try { this.cls = JSON.parse(this.el.dataset.luConfig) } catch (_) { this.cls = {} }
    this.svg = this.el.querySelector("svg")
    this.hit = part(this.el, "hit")
    if (!this.data || !this.hit) return
    this.hit.addEventListener("mousemove", this.onMove)
    this.hit.addEventListener("mouseleave", this.onLeave)
    this.pinned = this.data.pin != null
    this.width = 0 // a patch put the server geometry back: lay out again
    this.layout()
  },

  unbind() {
    if (this.hit) {
      this.hit.removeEventListener("mousemove", this.onMove)
      this.hit.removeEventListener("mouseleave", this.onLeave)
    }
  },

  schedule() {
    cancelAnimationFrame(this.raf)
    this.raf = requestAnimationFrame(() => this.layout())
  },

  // Port of `line_geo/1` (chart.ex), at the measured width.
  layout() {
    const d = this.data
    if (!d || !this.svg) return
    const W = Math.max(Math.round(this.el.clientWidth), 120)
    if (W === this.width) return
    this.width = W

    const {h: H, pl, pr, pt, pb} = d
    const n = d.values[0].length
    const iw = W - pl - pr, ih = H - pt - pb
    const range = d.max === d.min ? 1 : d.max - d.min
    const x = (i) => n === 1 ? pl + iw / 2 : pl + i * iw / (n - 1)
    const y = (v) => pt + ih - (v - d.min) / range * ih
    const xs = Array.from({length: n}, (_, i) => x(i))
    const ys = d.values.map((vs) => vs.map((v) => (v == null ? null : y(v)))) // null: no data
    this.geo = {W, iw, xs, ys}

    const svg = this.svg
    svg.setAttribute("viewBox", `0 0 ${W} ${H}`)
    svg.style.height = H + "px"
    svg.style.maxHeight = "none"

    const grid = parts(svg, "gridline")
    const labels = parts(svg, "axis")
    grid.forEach((g, t) => {
      const yy = y(d.min + (d.max - d.min) * t / d.ticks)
      g.setAttribute("x1", pl); g.setAttribute("x2", W - pr)
      g.setAttribute("y1", f(yy)); g.setAttribute("y2", f(yy))
      const l = labels[t]
      if (l) { l.setAttribute("x", pl - 8); l.setAttribute("y", f(yy + 4)) }
    })

    // X labels: drop every other one while they would touch, keeping the last (the pinned one).
    const step = n > 1 ? iw / (n - 1) : iw
    const skip = Math.max(1, Math.ceil(MIN_LABEL_GAP / step))
    parts(svg, "x-label").forEach((t) => {
      const i = +t.dataset.i
      t.setAttribute("x", f(xs[i]))
      t.style.display = (n - 1 - i) % skip === 0 ? "" : "none"
    })

    const lines = parts(svg, "line")
    const areas = parts(svg, "area")
    const ends = parts(svg, "endpoint")
    let ai = 0, ei = 0
    d.values.forEach((_, s) => {
      const runs = this.runs(xs, ys[s])
      const holes = ys[s].some((v) => v == null)
      const ds = runs.map((r) => this.smooth(r, holes))
      if (lines[s]) lines[s].setAttribute("d", ds.join(" "))
      if (d.area[s] && areas[ai]) {
        areas[ai++].setAttribute("d", runs.map((r, k) => `${ds[k]} L${f(r.at(-1)[0])} ${pt + ih} L${f(r[0][0])} ${pt + ih}Z`).join(" "))
      }
      if (!d.dashed[s] && ends[ei]) {
        const last = runs.length ? runs.at(-1).at(-1) : null
        if (last) { ends[ei].setAttribute("cx", f(last[0])); ends[ei].setAttribute("cy", f(last[1])); ends[ei].style.display = "" }
        else ends[ei].style.display = "none"
        ei++
      }
    })

    // uncertainty bands (closed path along `upper`, back along `lower`) and the split line
    if (d.band) {
      parts(svg, "band").forEach((b) => {
        const bd = d.band[+b.dataset.s]
        if (!bd) return
        const pts = bd.lower.map((l, i) => (l == null || bd.upper[i] == null ? null : [xs[i], y(bd.upper[i]), y(l)]))
        const runs = []
        let run = null
        pts.forEach((p) => { if (!p) { run = null; return } if (!run) runs.push(run = []); run.push(p) })
        b.setAttribute("d", runs.map((r) => {
          const up = r.map((p) => [p[0], p[1]]), lo = r.map((p) => [p[0], p[2]]).reverse()
          return `${this.smooth(up, false)} ${this.smooth(lo, false).replace(/^M/, "L")} Z`
        }).join(" "))
      })
    }
    if (d.split) {
      const at = d.split.at, gx = (xs[at] + xs[at + 1]) / 2
      const sl = part(svg, "split")
      if (sl) { sl.setAttribute("x1", f(gx)); sl.setAttribute("x2", f(gx)); sl.setAttribute("y1", pt); sl.setAttribute("y2", pt + ih) }
      parts(svg, "split-label").forEach((t) => t.setAttribute("x", f(gx + (t.dataset.side === "before" ? -6 : 6))))
    }

    this.hit.setAttribute("x", pl); this.hit.setAttribute("y", pt)
    this.hit.setAttribute("width", iw); this.hit.setAttribute("height", ih)
    const guide = part(svg, "guide")
    guide.setAttribute("y1", pt); guide.setAttribute("y2", pt + ih)

    if (this.pinned) this.show(d.pin)
  },

  // Runs of consecutive points ([x, y] pairs): a null y is a hole between two runs.
  runs(xs, ys) {
    const out = []
    let run = null
    ys.forEach((y, i) => {
      if (y == null) { run = null; return }
      if (!run) out.push(run = [])
      run.push([xs[i], y])
    })
    return out
  },

  smooth(pts, holes) {
    let p = `M${f(pts[0][0])} ${f(pts[0][1])}`
    if (pts.length === 1 && holes) return `${p} L${f(pts[0][0])} ${f(pts[0][1])}` // a lone point: a round cap shows it
    for (let i = 1; i < pts.length; i++) {
      const cx = f((pts[i - 1][0] + pts[i][0]) / 2)
      p += ` C${cx} ${f(pts[i - 1][1])} ${cx} ${f(pts[i][1])} ${f(pts[i][0])} ${f(pts[i][1])}`
    }
    return p
  },

  move(e) {
    if (!this.geo) return
    const {W, xs} = this.geo, d = this.data
    const box = this.svg.getBoundingClientRect()
    const x = (e.clientX - box.left) * W / box.width
    const n = xs.length
    const i = Math.max(0, Math.min(n - 1, Math.round((x - d.pl) / this.geo.iw * (n - 1))))
    this.show(i)
  },

  show(i) {
    const {W, xs, ys} = this.geo
    const sc = this.svg.getBoundingClientRect().width / W || 1
    const hov = part(this.el, "hover"), tip = part(this.el, "tip")
    const gx = xs[i]
    hov.style.display = ""
    const guide = part(hov, "guide")
    guide.setAttribute("x1", f(gx)); guide.setAttribute("x2", f(gx))
    parts(hov, "dot").forEach((c) => {
      const yy = ys[+c.dataset.s][i]
      c.style.display = yy == null ? "none" : ""
      if (yy != null) { c.setAttribute("cx", f(gx)); c.setAttribute("cy", f(yy)) }
    })
    parts(this.el, "x-label").forEach((t) => {
      if (+t.dataset.i === i) t.setAttribute("data-state", "on"); else t.removeAttribute("data-state")
    })

    const t = this.data.tips[i]
    tip.replaceChildren()
    const c = this.cls, kinds = c.kinds || {}
    const make = (tag, name, text, cls) => {
      const n = document.createElement(tag)
      n.setAttribute("data-part", `line-chart-tip-${name}`)
      if (cls) n.className = cls
      if (text != null) n.textContent = text
      return n
    }
    tip.appendChild(make("b", "title", t.title ?? "", c.title))
    for (const [name, value, kind] of t.rows) {
      const row = make("div", "row", null, c.row)
      // `band` / `band:<css colour>`: the translucent dot of an uncertainty row (the colour at 30%)
      const dot = make("i", "dot", null, `${c.dot || ""} ${kinds[kind] || ""}`.trim())
      if (typeof kind === "string" && kind.startsWith("band")) {
        dot.style.background = `color-mix(in srgb, ${kind.slice(5) || "var(--lu-accent-500)"} 30%, transparent)`
      }
      row.append(
        dot,
        make("span", "name", name ?? "", c.name),
        make("em", "value", value, c.value)
      )
      tip.appendChild(row)
    }
    tip.style.display = ""
    tip.style.transform = ""
    let left = gx * sc - tip.offsetWidth - 14
    if (left < 0) left = gx * sc + 14
    tip.style.left = left + "px"
    const y0 = ys.map((s) => s[i]).find((v) => v != null) ?? 0
    tip.style.top = Math.max(0, y0 * sc - tip.offsetHeight - 8) + "px"
  },

  leave() {
    // pinned: the guide and the tooltip go back to the pinned point
    if (this.pinned) return this.show(this.data.pin)
    part(this.el, "hover").style.display = "none"
    part(this.el, "tip").style.display = "none"
  }
}
