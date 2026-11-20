// Hover guide and tooltip of the server-rendered `line_chart/1`.
// The geometry and tooltip rows ride in `data-lu-chart-data` (JSON), the SVG is already in the DOM.
export default {
  mounted() {
    this.onMove = (e) => this.move(e)
    this.onLeave = () => this.leave()
    this.bind()
  },
  updated() { this.bind() },
  destroyed() { this.unbind() },

  bind() {
    this.unbind()
    try { this.data = JSON.parse(this.el.dataset.luChartData) } catch (_) { this.data = null }
    this.hit = this.el.querySelector(".lu-hit")
    if (!this.data || !this.hit) return
    this.hit.addEventListener("mousemove", this.onMove)
    this.hit.addEventListener("mouseleave", this.onLeave)
    // Pinned: the server drew the guide and the tooltip; place the tooltip exactly.
    const pinned = this.el.querySelector(".lu-hover")
    if (pinned && pinned.style.display !== "none") this.pinned = true
  },

  unbind() {
    if (this.hit) {
      this.hit.removeEventListener("mousemove", this.onMove)
      this.hit.removeEventListener("mouseleave", this.onLeave)
    }
  },

  move(e) {
    const d = this.data, svg = this.el.querySelector("svg")
    const box = svg.getBoundingClientRect()
    const x = (e.clientX - box.left) * d.w / box.width
    const n = d.xs.length
    const i = Math.max(0, Math.min(n - 1, Math.round((x - d.pl) / d.iw * (n - 1))))
    this.show(i, box.width / d.w)
  },

  show(i, sc) {
    const d = this.data
    const hov = this.el.querySelector(".lu-hover"), tip = this.el.querySelector(".lu-tip")
    const gx = d.xs[i]
    hov.style.display = ""
    const guide = hov.querySelector(".lu-guide")
    guide.setAttribute("x1", gx); guide.setAttribute("x2", gx)
    hov.querySelectorAll(".lu-dot").forEach((c) => {
      c.setAttribute("cx", gx); c.setAttribute("cy", d.ys[+c.dataset.s][i])
    })
    this.el.querySelectorAll(".lu-xl").forEach((t) => t.classList.toggle("on", +t.dataset.i === i))

    const t = d.tips[i]
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
    tip.style.top = Math.max(0, d.ys[0][i] * sc - tip.offsetHeight - 8) + "px"
  },

  leave() {
    if (this.pinned) return
    this.el.querySelector(".lu-hover").style.display = "none"
    this.el.querySelector(".lu-tip").style.display = "none"
  }
}
