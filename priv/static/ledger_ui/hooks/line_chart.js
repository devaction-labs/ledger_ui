// Responsive layout, hover guide and tooltip of the server-rendered `line_chart/1`.
//
// The server draws the SVG at a default width. The hook measures the container (ResizeObserver,
// one layout per animation frame) and re-lays the SAME geometry out at the real width: the
// viewBox becomes `0 0 <width> <height>` and the SVG gets its CSS height, so 1 user unit is 1 CSS
// pixel and the axis text and strokes keep their CSS size at any width. The geometry (and the
// tooltip rows) ride in `data-lu-chart-data` (JSON); only attributes of existing nodes change.
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
    this.svg = this.el.querySelector("svg")
    this.hit = this.el.querySelector(".lu-hit")
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
    const ys = d.values.map((vs) => vs.map(y))
    this.geo = {W, iw, xs, ys}

    const svg = this.svg
    svg.setAttribute("viewBox", `0 0 ${W} ${H}`)
    svg.style.height = H + "px"
    svg.style.maxHeight = "none"

    const grid = svg.querySelectorAll(".lu-gridline")
    const labels = svg.querySelectorAll(".lu-axis:not(.lu-xl)")
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
    svg.querySelectorAll(".lu-xl").forEach((t) => {
      const i = +t.dataset.i
      t.setAttribute("x", f(xs[i]))
      t.style.display = (n - 1 - i) % skip === 0 ? "" : "none"
    })

    const lines = svg.querySelectorAll("path.lu-line")
    const areas = svg.querySelectorAll('path[fill^="url"]')
    const ends = svg.querySelectorAll(".lu-endpt")
    let ai = 0, ei = 0
    d.values.forEach((_, s) => {
      const dd = this.smooth(xs, ys[s])
      if (lines[s]) lines[s].setAttribute("d", dd)
      if (d.area[s] && areas[ai]) {
        areas[ai++].setAttribute("d", `${dd} L${f(xs[n - 1])} ${pt + ih} L${f(xs[0])} ${pt + ih}Z`)
      }
      if (!d.dashed[s] && ends[ei]) {
        ends[ei].setAttribute("cx", f(xs[n - 1])); ends[ei++].setAttribute("cy", f(ys[s][n - 1]))
      }
    })

    this.hit.setAttribute("x", pl); this.hit.setAttribute("y", pt)
    this.hit.setAttribute("width", iw); this.hit.setAttribute("height", ih)
    const guide = svg.querySelector(".lu-guide")
    guide.setAttribute("y1", pt); guide.setAttribute("y2", pt + ih)

    if (this.pinned) this.show(d.pin)
  },

  smooth(xs, ys) {
    let p = `M${f(xs[0])} ${f(ys[0])}`
    for (let i = 1; i < xs.length; i++) {
      const cx = f((xs[i - 1] + xs[i]) / 2)
      p += ` C${cx} ${f(ys[i - 1])} ${cx} ${f(ys[i])} ${f(xs[i])} ${f(ys[i])}`
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
    const hov = this.el.querySelector(".lu-hover"), tip = this.el.querySelector(".lu-tip")
    const gx = xs[i]
    hov.style.display = ""
    const guide = hov.querySelector(".lu-guide")
    guide.setAttribute("x1", f(gx)); guide.setAttribute("x2", f(gx))
    hov.querySelectorAll(".lu-dot").forEach((c) => {
      c.setAttribute("cx", f(gx)); c.setAttribute("cy", f(ys[+c.dataset.s][i]))
    })
    this.el.querySelectorAll(".lu-xl").forEach((t) => t.classList.toggle("on", +t.dataset.i === i))

    const t = this.data.tips[i]
    tip.replaceChildren()
    const title = document.createElement("b")
    title.textContent = t.title ?? ""
    tip.appendChild(title)
    for (const [name, value, kind] of t.rows) {
      const row = document.createElement("div"); row.className = "r"
      const dot = document.createElement("i"); dot.className = "d " + kind
      const a = document.createElement("span"); a.textContent = name ?? ""
      const b = document.createElement("em"); b.textContent = value
      row.append(dot, a, b); tip.appendChild(row)
    }
    tip.style.display = ""
    tip.style.transform = ""
    let left = gx * sc - tip.offsetWidth - 14
    if (left < 0) left = gx * sc + 14
    tip.style.left = left + "px"
    tip.style.top = Math.max(0, ys[0][i] * sc - tip.offsetHeight - 8) + "px"
  },

  leave() {
    // pinned: the guide and the tooltip go back to the pinned point
    if (this.pinned) return this.show(this.data.pin)
    this.el.querySelector(".lu-hover").style.display = "none"
    this.el.querySelector(".lu-tip").style.display = "none"
  }
}
