import {push, emitInput} from "../lib/picker.js"

const clamp = (n, lo, hi) => Math.min(hi, Math.max(lo, n))
const hex2 = (n) => Math.round(n).toString(16).padStart(2, "0").toUpperCase()

function normalize(v) {
  let h = String(v || "").trim().replace(/^#/, "").toUpperCase()
  if (/^[0-9A-F]{3}$/.test(h)) h = h.split("").map((c) => c + c).join("")
  return /^([0-9A-F]{6}|[0-9A-F]{8})$/.test(h) ? "#" + h : null
}
function toHsv(hex) {
  const r = parseInt(hex.slice(1, 3), 16) / 255, g = parseInt(hex.slice(3, 5), 16) / 255, b = parseInt(hex.slice(5, 7), 16) / 255
  const max = Math.max(r, g, b), d = max - Math.min(r, g, b)
  let h = 0
  if (d) h = max === r ? 60 * (((g - b) / d + 6) % 6) : max === g ? 60 * ((b - r) / d + 2) : 60 * ((r - g) / d + 4)
  const a = hex.length > 7 ? parseInt(hex.slice(7, 9), 16) / 255 : 1
  return {h, s: max ? d / max : 0, v: max, a}
}
function toHex({h, s, v, a}, alpha) {
  const f = (n) => { const k = (n + h / 60) % 6; return v - v * s * Math.max(0, Math.min(k, 4 - k, 1)) }
  const out = "#" + hex2(f(5) * 255) + hex2(f(3) * 255) + hex2(f(1) * 255)
  return alpha && a < 1 ? out + hex2(a * 255) : out
}

// <.color_picker>: state {h,s,v,a}; the hidden input (when named) carries "#RRGGBB[AA]".
export default {
  mounted() {
    this.drag = null
    this.onDown = (e) => this.down(e)
    this.onMove = (e) => this.drag && this.moveTo(e)
    this.onUp = () => this.endDrag()
    this.onClick = (e) => this.click(e)
    this.onInput = (e) => this.hexInput(e)
    this.onKey = (e) => this.key(e)
    this.el.addEventListener("pointerdown", this.onDown)
    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("input", this.onInput)
    this.el.addEventListener("keydown", this.onKey)
    this.init()
    this.srv = this.seen()
  },
  // The colour the server drew did not change (what the patch put back is the one we saw): the person's stays.
  updated() {
    const seen = this.seen()
    if (seen && seen !== normalize(this.value()) && seen === this.srv) {
      const h = this.hidden()
      if (h) h.value = this.value()
      this.paint()
      return
    }
    if (seen) {
      this.srv = seen
      if (seen !== normalize(this.value())) this.st = toHsv(seen)
    }
    this.init()
  },
  destroyed() {
    this.el.removeEventListener("pointerdown", this.onDown)
    this.endDrag()
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("input", this.onInput)
    this.el.removeEventListener("keydown", this.onKey)
  },

  alpha() { return this.el.hasAttribute("data-lu-alpha") },
  hidden() { return this.el.querySelector("[data-color-value]") },
  hexEl() { return document.getElementById(this.el.id + "-hex") },

  // The colour as drawn in the markup (hidden input, pressed swatch, hex field), null when there is none.
  seen() {
    const h = this.hidden()
    return (h && normalize(h.value)) ||
      normalize(this.el.querySelector("[data-part=color-picker-swatch][aria-pressed=true]")?.getAttribute("aria-label")) ||
      normalize("#" + (this.hexEl()?.value || "")) || null
  },

  init() {
    const h = this.hidden()
    const start = (h && normalize(h.value)) || (this.st && toHex(this.st, true)) ||
      normalize(this.el.querySelector("[data-part=color-picker-swatch][aria-pressed=true]")?.getAttribute("aria-label")) ||
      normalize("#" + (this.hexEl()?.value || "")) || "#4C3FE0"
    this.st = toHsv(start)
    this.paint()
  },

  value() { return toHex(this.st, this.alpha()) },

  paint() {
    const {h, s, v, a} = this.st, hex = this.value()
    const area = this.el.querySelector("[data-area]")
    if (area) {
      area.style.background = `linear-gradient(to top,#000,transparent),linear-gradient(to right,#fff,hsl(${Math.round(h)} 100% 50%))`
      const t = area.querySelector("i")
      t.style.left = s * 100 + "%"; t.style.top = (1 - v) * 100 + "%"
    }
    const hue = this.el.querySelector("[data-hue]")
    if (hue) { hue.querySelector("i").style.left = (h / 360) * 100 + "%"; hue.setAttribute("aria-valuenow", Math.round(h)) }
    const al = this.el.querySelector("[data-alpha-track]")
    if (al) {
      al.querySelector("i").style.left = a * 100 + "%"
      al.setAttribute("aria-valuenow", Math.round(a * 100))
      al.style.background = `linear-gradient(90deg,transparent,${toHex({h, s, v, a: 1})}),repeating-conic-gradient(#ccc 0 25%,#fff 0 50%) 0 0/8px 8px`
    }
    const hx = this.hexEl()
    if (hx && document.activeElement !== hx) hx.value = hex.slice(1)
    const base = hex.slice(0, 7)
    this.el.querySelectorAll("[data-part=color-picker-swatch]").forEach((b) => b.setAttribute("aria-pressed", String(normalize(b.getAttribute("aria-label")) === base)))
  },

  commit() {
    const hex = this.value(), hid = this.hidden()
    this.paint()
    if (hid) { hid.value = hex; emitInput(hid) }
    const on = this.el.dataset.luOnChange
    // a `%JS{}` arrives as the JSON of its commands; an event name is pushed
    if (on && on.startsWith("[")) this.js ? this.js().exec(on) : this.liveSocket.execJS(this.el, on)
    else push(this, on, this.el.dataset.luTarget, {id: this.el.id, value: hex})
  },

  down(e) {
    const t = e.target.closest && e.target.closest("[data-area],[data-hue],[data-alpha-track]")
    if (!t) return
    this.drag = t
    // `pointermove` and `pointerup` are listened to on `window` only while a drag lasts
    window.addEventListener("pointermove", this.onMove)
    window.addEventListener("pointerup", this.onUp)
    window.addEventListener("pointercancel", this.onUp)
    t.setPointerCapture && t.setPointerCapture(e.pointerId)
    this.moveTo(e)
  },
  endDrag() {
    this.drag = null
    window.removeEventListener("pointermove", this.onMove)
    window.removeEventListener("pointerup", this.onUp)
    window.removeEventListener("pointercancel", this.onUp)
  },
  moveTo(e) {
    const r = this.drag.getBoundingClientRect()
    const x = clamp((e.clientX - r.left) / r.width, 0, 1), y = clamp((e.clientY - r.top) / r.height, 0, 1)
    if (this.drag.hasAttribute("data-area")) { this.st.s = x; this.st.v = 1 - y }
    else if (this.drag.hasAttribute("data-hue")) this.st.h = x * 360
    else this.st.a = x
    this.commit()
  },

  click(e) {
    const b = e.target.closest && e.target.closest("[data-part=color-picker-swatch]")
    if (!b || b.disabled) return
    const c = normalize(b.getAttribute("aria-label"))
    if (c) { this.st = toHsv(c); this.commit() }
  },

  hexInput(e) {
    if (e.target !== this.hexEl()) return
    const c = normalize(e.target.value)
    if (c) { this.st = toHsv(c); this.commit() }
  },

  key(e) {
    const t = e.target.closest && e.target.closest("[data-area],[data-hue],[data-alpha-track]")
    if (!t) return
    const step = e.shiftKey ? 0.1 : 0.01
    const d = {ArrowLeft: [-step, 0], ArrowRight: [step, 0], ArrowUp: [0, step], ArrowDown: [0, -step]}[e.key]
    if (!d) return
    e.preventDefault()
    if (t.hasAttribute("data-area")) { this.st.s = clamp(this.st.s + d[0], 0, 1); this.st.v = clamp(this.st.v + d[1], 0, 1) }
    else if (t.hasAttribute("data-hue")) this.st.h = clamp(this.st.h + (d[0] || d[1]) * 360, 0, 360)
    else this.st.a = clamp(this.st.a + (d[0] || d[1]), 0, 1)
    this.commit()
  },
}
