import {esc, push, emitInput} from "../lib/picker.js"

const NS = "http://www.w3.org/2000/svg"
const FONT = "Brush Script MT, Segoe Script, cursive"

// <.signature_pad>: the surface is client-owned (phx-update="ignore"); the hidden input (when
// named) carries the SVG text. Pointer events draw, the `type` mode sets a name in a script font.
export default {
  mounted() {
    this.cfg = JSON.parse(this.el.getAttribute("data-lu-config"))
    this.mode = this.cfg.mode
    this.drawing = null
    this.text = this.cfg.text || ""
    this.last = null
    this.onDown = (e) => this.down(e)
    this.onMove = (e) => this.drawing && this.move(e)
    this.onUp = () => this.up()
    this.onClick = (e) => this.click(e)
    this.onInput = (e) => this.typed(e)
    this.pad().addEventListener("pointerdown", this.onDown)
    window.addEventListener("pointermove", this.onMove)
    window.addEventListener("pointerup", this.onUp)
    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("input", this.onInput)
    this.setup()
    this.restore(this.hidden() ? this.hidden().value : this.pathsFromDom())
    this.status()
  },
  updated() {
    this.cfg = JSON.parse(this.el.getAttribute("data-lu-config"))
    const h = this.hidden()
    if (h && h.value !== this.last) this.restore(h.value)
    this.setup()
    this.status()
  },
  destroyed() {
    this.pad().removeEventListener("pointerdown", this.onDown)
    window.removeEventListener("pointermove", this.onMove)
    window.removeEventListener("pointerup", this.onUp)
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("input", this.onInput)
  },

  pad() { return this.el.querySelector(".lu-sig") },
  hidden() { return this.el.querySelector("[data-sig-value]") },
  svg() { return this.pad().querySelector("svg") },
  btn(sel) { return this.el.querySelector(`.lu-row ${sel}`) },

  setup() {
    const pad = this.pad()
    pad.style.touchAction = "none"
    pad.style.cursor = this.mode === "draw" && !this.cfg.disabled ? "crosshair" : "default"
    // the stylesheet animates demo paths: drawn ones must stay visible
    pad.querySelectorAll("svg path").forEach((p) => { p.style.animation = "none"; p.style.strokeDasharray = "none"; p.style.strokeDashoffset = "0" })
    const status = this.btn(".lu-grow")
    if (status) { status.setAttribute("role", "status"); status.setAttribute("aria-live", "polite"); status.className = "lu-grow lu-xs lu-muted" }
    pad.setAttribute("role", "img")
    pad.setAttribute("aria-label", this.cfg.labels.signature_area)
  },

  pathsFromDom() { return this.svg() && this.svg().querySelector("path") ? "x" : "" },

  // ---- drawing --------------------------------------------------------------------------
  point(e) {
    const svg = this.svg(), pt = svg.createSVGPoint()
    pt.x = e.clientX; pt.y = e.clientY
    const p = pt.matrixTransform(svg.getScreenCTM().inverse())
    return [Math.round(p.x * 10) / 10, Math.round(p.y * 10) / 10]
  },
  ensureViewBox() {
    const svg = this.svg()
    if (!svg.querySelector("path")) {
      const r = this.pad().getBoundingClientRect()
      svg.setAttribute("viewBox", `0 0 ${Math.round(r.width)} ${Math.round(r.height)}`)
    }
  },
  down(e) {
    if (this.mode !== "draw" || this.cfg.disabled || e.button > 0) return
    if (e.target.closest && e.target.closest("button")) return
    this.ensureViewBox()
    const svg = this.svg(), path = document.createElementNS(NS, "path")
    const [x, y] = this.point(e)
    path.setAttribute("d", `M${x} ${y} L${x} ${y}`)
    path.setAttribute("fill", "none")
    path.setAttribute("stroke", "var(--ink)")
    path.setAttribute("stroke-linecap", "round")
    path.setAttribute("stroke-linejoin", "round")
    path.setAttribute("stroke-width", "2.4")
    path.style.animation = "none"; path.style.strokeDasharray = "none"; path.style.strokeDashoffset = "0"
    svg.appendChild(path)
    this.drawing = path
    this.pad().setPointerCapture && this.pad().setPointerCapture(e.pointerId)
    e.preventDefault()
  },
  move(e) {
    const [x, y] = this.point(e)
    this.drawing.setAttribute("d", this.drawing.getAttribute("d") + ` L${x} ${y}`)
  },
  up() {
    if (!this.drawing) return
    this.drawing = null
    this.commit()
  },

  // ---- modes ---------------------------------------------------------------------------
  render() {
    const pad = this.pad()
    pad.querySelectorAll(".base, svg, .typed").forEach((n) => n.remove())
    if (this.mode === "type") {
      const t = document.createElement("span")
      t.className = "typed"
      t.textContent = this.text
      pad.prepend(t)
    } else {
      const svg = document.createElementNS(NS, "svg")
      svg.setAttribute("aria-hidden", "true")
      svg.setAttribute("viewBox", this.vb || "0 0 300 170")
      pad.prepend(svg)
      if (this.cfg.variant !== "classic") { const b = document.createElement("div"); b.className = "base"; pad.prepend(b) }
      ;(this.paths || []).forEach((d) => {
        const p = document.createElementNS(NS, "path")
        p.setAttribute("d", d)
        for (const [k, v] of Object.entries({fill: "none", stroke: "var(--ink)", "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2.4"})) p.setAttribute(k, v)
        svg.appendChild(p)
      })
    }
    this.setup()
  },
  nameEl() { return this.el.querySelector("[data-sig-name]") },
  showMode() {
    this.el.querySelectorAll(".lu-seg button[data-mode]").forEach((b) => {
      const on = b.dataset.mode === this.mode
      b.classList.toggle("on", on); b.setAttribute("aria-selected", String(on))
    })
    const n = this.nameEl()
    if (n) n.hidden = this.mode !== "type"
  },

  click(e) {
    const t = e.target
    const tab = t.closest && t.closest(".lu-seg button[data-mode]")
    if (tab && !this.cfg.disabled) {
      this.paths = this.svg() ? [...this.svg().querySelectorAll("path")].map((p) => p.getAttribute("d")) : this.paths
      this.vb = this.svg() ? this.svg().getAttribute("viewBox") : this.vb
      this.mode = tab.dataset.mode
      this.showMode(); this.render(); this.commit()
      return
    }
    if (t.closest && t.closest(".lu-row .lu-btn.ghost")) { this.paths = []; this.text = ""; const i = this.el.querySelector("[data-sig-name] input"); if (i) i.value = ""; this.render(); this.commit() }
    else if (t.closest && t.closest(".lu-row .lu-btn.primary")) push(this, this.cfg.onConfirm, this.cfg.target, {id: this.el.id, value: this.export()})
  },
  typed(e) {
    if (!e.target.closest || !e.target.closest("[data-sig-name]")) return
    this.text = e.target.value
    const t = this.pad().querySelector(".typed")
    if (t) t.textContent = this.text
    this.commit()
  },

  // ---- value ----------------------------------------------------------------------------
  export() {
    const ink = this.cfg.ink
    if (this.mode === "type") {
      if (!this.text.trim()) return ""
      const r = this.pad().getBoundingClientRect(), w = Math.round(r.width) || 300, h = Math.round(r.height) || 170
      return `<svg xmlns="${NS}" viewBox="0 0 ${w} ${h}"><text x="22" y="${h - 44}" font-family="${FONT}" font-size="30" fill="${esc(ink)}">${esc(this.text)}</text></svg>`
    }
    const svg = this.svg(), paths = svg ? [...svg.querySelectorAll("path")] : []
    if (!paths.length) return ""
    const body = paths.map((p) => `<path d="${esc(p.getAttribute("d"))}" fill="none" stroke="${esc(ink)}" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>`).join("")
    return `<svg xmlns="${NS}" viewBox="${esc(svg.getAttribute("viewBox"))}">${body}</svg>`
  },
  commit() {
    const value = this.export()
    this.last = value
    const h = this.hidden()
    if (h) { h.value = value; emitInput(h) }
    this.status()
    push(this, this.cfg.onChange, this.cfg.target, {id: this.el.id, value})
  },
  restore(value) {
    if (value === "x") return
    this.last = value
    this.paths = []
    if (value) {
      const doc = new DOMParser().parseFromString(value, "image/svg+xml")
      const root = doc.documentElement
      if (root && root.nodeName === "svg") {
        this.vb = root.getAttribute("viewBox") || "0 0 300 170"
        const text = root.querySelector("text")
        if (text) { this.mode = "type"; this.text = text.textContent }
        else this.paths = [...root.querySelectorAll("path")].map((p) => p.getAttribute("d"))
      }
    }
    this.showMode(); this.render()
  },
  status() {
    const s = this.btn(".lu-grow")
    if (!s) return
    const signed = this.mode === "type" ? !!this.text.trim() : !!(this.svg() && this.svg().querySelector("path"))
    s.textContent = signed ? this.cfg.labels.signature_ready : this.cfg.labels.signature_empty
  },
}
