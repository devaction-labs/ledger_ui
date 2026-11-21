import {emitInput} from "../lib/picker.js"

// <.number_input>: `span.v` is the editable text; the hidden input carries the machine value.
export default {
  mounted() {
    this.cfg = JSON.parse(this.el.getAttribute("data-lu-config"))
    this.onClick = (e) => this.click(e)
    this.onKey = (e) => this.key(e)
    this.onBlur = () => this.commitText()
    this.onSync = () => this.readHidden()
    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("keydown", this.onKey)
    this.vEl().addEventListener("blur", this.onBlur)
    this.el.addEventListener("lu:sync", this.onSync)
    this.setup()
  },
  updated() { this.cfg = JSON.parse(this.el.getAttribute("data-lu-config")); this.setup() },
  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("keydown", this.onKey)
    this.vEl().removeEventListener("blur", this.onBlur)
    this.el.removeEventListener("lu:sync", this.onSync)
  },

  vEl() { return this.el.querySelector('[data-part="number-value"]') },
  hidden() { return this.el.querySelector("[data-num-value]") },
  buttons() {
    return {
      minus: this.el.querySelector('[data-part="number-minus"]'),
      plus: this.el.querySelector('[data-part="number-plus"]'),
    }
  },

  // The text shown -> number (null when not a number).
  parse(text) {
    const {dec, thou} = this.cfg
    let t = String(text).replace(/\s/g, "")
    if (thou) t = t.split(thou).join("")
    if (dec !== ".") t = t.replace(dec, ".")
    return /^-?\d+(\.\d+)?$|^-?\d*\.\d+$/.test(t) ? parseFloat(t) : null
  },
  value() {
    const h = this.hidden()
    if (h) return h.value === "" ? null : parseFloat(h.value)
    return this.parse(this.vEl().textContent)
  },
  places(n) {
    const c = this.cfg
    return c.decimals != null ? c.decimals : c.maxDecimals != null ? c.maxDecimals : null
  },
  clamp(n) {
    const c = this.cfg
    if (c.min != null) n = Math.max(n, parseFloat(c.min))
    if (c.max != null) n = Math.min(n, parseFloat(c.max))
    return n
  },
  round(n) {
    const p = this.places()
    return p == null ? n : Math.round((n + Number.EPSILON) * 10 ** p) / 10 ** p
  },
  format(n) {
    const c = this.cfg, p = c.decimals
    let [i, f = ""] = Math.abs(n).toFixed(c.decimals != null ? c.decimals : c.maxDecimals != null ? c.maxDecimals : 10).split(".")
    if (c.decimals == null) f = f.replace(/0+$/, "")
    if (c.thou) i = i.replace(/\B(?=(\d{3})+(?!\d))/g, c.thou)
    return (n < 0 && (+i || +f) ? "-" : "") + i + (f ? c.dec + f : "")
  },

  setup() {
    const v = this.vEl()
    if (!this.cfg.disabled) { v.setAttribute("contenteditable", "plaintext-only"); v.tabIndex = 0 }
    v.setAttribute("role", "spinbutton")
    v.setAttribute("inputmode", "decimal")
    v.setAttribute("autocapitalize", "off")
    this.limits()
    const {minus, plus} = this.buttons()
    if (this.cfg.disabled) [minus, plus].forEach((b) => b && (b.disabled = true))
  },
  limits() {
    const n = this.value(), c = this.cfg, {minus, plus} = this.buttons(), v = this.vEl()
    if (n != null) v.setAttribute("aria-valuenow", n)
    else v.removeAttribute("aria-valuenow")
    if (c.min != null) v.setAttribute("aria-valuemin", c.min)
    if (c.max != null) v.setAttribute("aria-valuemax", c.max)
    if (this.cfg.disabled) return
    if (minus) minus.disabled = n != null && c.min != null && n <= parseFloat(c.min)
    if (plus) plus.disabled = n != null && c.max != null && n >= parseFloat(c.max)
  },
  readHidden() {
    const n = this.value()
    this.vEl().textContent = n == null ? "" : this.format(n)
    this.limits()
  },

  set(n, notify = true) {
    n = n == null ? null : this.round(this.clamp(n))
    this.vEl().textContent = n == null ? "" : this.format(n)
    const h = this.hidden()
    if (h) {
      const text = n == null ? "" : String(n)
      if (h.value !== text) { h.value = text; if (notify) emitInput(h) }
    }
    this.limits()
  },

  commitText() {
    const raw = this.vEl().textContent
    if (raw.trim() === "") return this.set(null)
    const n = this.parse(raw)
    if (n == null) { this.readHidden(); return }
    this.set(n)
  },

  step(dir, times = 1) {
    if (this.cfg.disabled) return
    const base = this.value() ?? (this.cfg.min != null ? parseFloat(this.cfg.min) - dir * parseFloat(this.cfg.step) : 0)
    this.set(base + dir * times * parseFloat(this.cfg.step))
  },

  click(e) {
    const b = e.target.closest && e.target.closest("button")
    if (!b || b.disabled) return
    this.step(b.dataset.part === "number-plus" ? 1 : -1)
  },

  key(e) {
    if (!e.target.closest || !e.target.closest('[data-part="number-value"]')) return
    const k = {ArrowUp: [1, 1], ArrowDown: [-1, 1], PageUp: [1, 10], PageDown: [-1, 10]}[e.key]
    if (k) { e.preventDefault(); this.step(k[0], k[1]) }
    else if (e.key === "Enter") { e.preventDefault(); this.commitText() }
    else if (e.key.length === 1 && !e.ctrlKey && !e.metaKey && !/[\d\-.,]/.test(e.key)) e.preventDefault()
  },
}
