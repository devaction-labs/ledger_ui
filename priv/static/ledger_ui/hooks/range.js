import {emitInput} from "../lib/picker.js"

const clamp = (n, lo, hi) => Math.min(hi, Math.max(lo, n))

// <.range>: a track, a fill and `[data-part=range-thumb]` thumbs; hidden `[data-range-value]` inputs (when named) hold the values.
export default {
  mounted() {
    this.cfg = JSON.parse(this.el.getAttribute("data-lu-config"))
    this.drag = null
    this.vals = this.read()
    this.srv = [...this.vals]
    this.onDown = (e) => this.down(e)
    this.onMove = (e) => this.drag != null && this.move(e)
    this.onUp = () => { this.drag = null }
    this.onKey = (e) => this.key(e)
    this.onClick = (e) => this.click(e)
    this.onSync = () => { this.vals = this.read(); this.srv = [...this.vals]; this.paint() }
    this.el.addEventListener("pointerdown", this.onDown)
    window.addEventListener("pointermove", this.onMove)
    window.addEventListener("pointerup", this.onUp)
    this.el.addEventListener("keydown", this.onKey)
    this.wrap()?.addEventListener("click", this.onClick)
    this.el.addEventListener("lu:sync", this.onSync)
    this.setup()
    this.paint(false)
  },
  updated() {
    this.cfg = JSON.parse(this.el.getAttribute("data-lu-config"))
    // The server drew the value we saw before: the person's stays. Another one: it wins.
    const seen = this.read(), key = (a) => a.join(",")
    if (key(seen) === key(this.vals)) this.srv = [...seen]
    else if (key(seen) !== key(this.srv)) { this.vals = seen; this.srv = [...seen] }
    this.setup()
    this.paint(false)
  },
  destroyed() {
    this.el.removeEventListener("pointerdown", this.onDown)
    window.removeEventListener("pointermove", this.onMove)
    window.removeEventListener("pointerup", this.onUp)
    this.el.removeEventListener("keydown", this.onKey)
    this.wrap()?.removeEventListener("click", this.onClick)
    this.el.removeEventListener("lu:sync", this.onSync)
  },

  wrap() { return this.el.closest("[data-part=range-wrap]") },
  thumbs() { return [...this.el.querySelectorAll("[data-part=range-thumb]")] },   // [lower?, upper]
  inputs() { return [...this.el.querySelectorAll("[data-range-value]")] },

  // Current values: from the hidden inputs or from --lu-sp / --lu-rlo
  read() {
    const c = this.cfg, ins = this.inputs()
    if (ins.length) return ins.map((i) => parseFloat(i.value))
    const sp = parseFloat(this.el.style.getPropertyValue("--lu-sp")) || 0
    const a = parseFloat(this.el.style.getPropertyValue("--lu-rlo")) || 0
    const toV = (p) => c.min + (p / 100) * (c.max - c.min)
    return c.pair ? [toV(a), toV(sp)] : [toV(sp)]
  },
  pos(v) { const c = this.cfg; return c.max === c.min ? 0 : ((v - c.min) / (c.max - c.min)) * 100 },
  snap(v) {
    const c = this.cfg
    const s = Math.round((v - c.min) / c.step) * c.step + c.min
    return clamp(Math.round(s * 1e6) / 1e6, c.min, c.max)
  },
  fmt(v) { return String(Math.round(v * 100) / 100) },

  setup() {
    const c = this.cfg, th = this.thumbs()
    this.el.style.touchAction = "none"
    th.forEach((t, i) => {
      t.setAttribute("role", "slider")
      t.tabIndex = c.disabled ? -1 : 0
      t.setAttribute("aria-orientation", c.vertical ? "vertical" : "horizontal")
      t.setAttribute("aria-valuemin", c.min)
      t.setAttribute("aria-valuemax", c.max)
      if (c.disabled) t.setAttribute("aria-disabled", "true")
      if (c.label) t.setAttribute("aria-label", c.pair ? `${c.label} ${i === 0 ? c.minWord || "min" : c.maxWord || "max"}` : c.label)
    })
    const b = this.wrap()?.querySelectorAll("[data-part=range-step]")
    if (b && b.length === 2) {
      b[0].setAttribute("aria-label", c.decrease); b[1].setAttribute("aria-label", c.increase)
      b[0].disabled = b[1].disabled = !!c.disabled
    }
    this.wrap()?.querySelectorAll("[data-part=range-mark]").forEach((s) => (s.style.cursor = c.disabled ? "default" : "pointer"))
  },

  paint(emit = false) {
    const c = this.cfg, v = this.vals
    this.el.style.setProperty("--lu-sp", this.pos(v[v.length - 1]) + "%")
    if (c.pair) this.el.style.setProperty("--lu-rlo", this.pos(v[0]) + "%")
    this.thumbs().forEach((t, i) => t.setAttribute("aria-valuenow", this.fmt(v[i])))
    const vv = this.wrap()?.querySelector("[data-part=range-value]")
    if (vv) vv.textContent = c.format.replace("%{value}", v.map((x) => this.fmt(x)).join(" – "))
    this.inputs().forEach((inp, i) => {
      const t = this.fmt(v[i])
      if (inp.value !== t) { inp.value = t; if (emit) emitInput(inp) }
    })
  },

  set(i, value) {
    const c = this.cfg
    let v = this.snap(value)
    if (c.pair) v = i === 0 ? Math.min(v, this.vals[1]) : Math.max(v, this.vals[0])
    if (v === this.vals[i]) return
    this.vals[i] = v
    this.paint(true)
  },

  ratio(e) {
    const r = this.el.getBoundingClientRect()
    const t = this.cfg.vertical ? 1 - (e.clientY - r.top) / r.height : (e.clientX - r.left) / r.width
    return clamp(t, 0, 1)
  },
  valueAt(e) { const c = this.cfg; return c.min + this.ratio(e) * (c.max - c.min) },
  nearest(v) { return this.cfg.pair && Math.abs(v - this.vals[0]) < Math.abs(v - this.vals[1]) ? 0 : this.vals.length - 1 },

  down(e) {
    if (this.cfg.disabled || (e.button != null && e.button > 0)) return
    const v = this.valueAt(e)
    const t = e.target.closest && e.target.closest("[data-part=range-thumb]")
    this.drag = t ? Math.max(0, this.thumbs().indexOf(t)) : this.nearest(v)
    if (this.cfg.pair && this.thumbs().length === 1) this.drag = 0
    this.el.setPointerCapture && this.el.setPointerCapture(e.pointerId)
    this.thumbs()[this.drag]?.focus({preventScroll: true})
    this.set(this.drag, v)
    e.preventDefault()
  },
  move(e) { this.set(this.drag, this.valueAt(e)) },

  key(e) {
    const t = e.target.closest && e.target.closest("[data-part=range-thumb]")
    if (!t || this.cfg.disabled) return
    const i = Math.max(0, this.thumbs().indexOf(t)), c = this.cfg
    const big = Math.max(c.step, (c.max - c.min) / 10)
    const d = {ArrowRight: c.step, ArrowUp: c.step, ArrowLeft: -c.step, ArrowDown: -c.step, PageUp: big, PageDown: -big}[e.key]
    if (d != null) { e.preventDefault(); this.set(i, this.vals[i] + d) }
    else if (e.key === "Home") { e.preventDefault(); this.set(i, c.min) }
    else if (e.key === "End") { e.preventDefault(); this.set(i, c.max) }
  },

  click(e) {
    if (this.cfg.disabled) return
    const w = this.wrap(), c = this.cfg
    const btn = e.target.closest && e.target.closest("[data-part=range-step]")
    if (btn) {
      const bs = [...w.querySelectorAll("[data-part=range-step]")], dir = bs.indexOf(btn) === 0 ? -1 : 1
      return this.set(this.vals.length - 1, this.vals[this.vals.length - 1] + dir * c.step)
    }
    const mark = e.target.closest && e.target.closest("[data-part=range-mark]")
    if (mark && c.marks.length) {
      const i = [...mark.parentNode.children].indexOf(mark), v = c.marks[i]?.v
      if (v != null) this.set(this.nearest(v), v)
    }
  },
}
