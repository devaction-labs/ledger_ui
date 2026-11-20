import {pad, esc, push, dismiss, emitInput} from "../lib/picker.js"

const hhmm = (m) => `${pad(Math.floor(m / 60))}:${pad(m % 60)}`
const text = (m, h24, f) => {
  if (m == null) return ""
  const h = Math.floor(m / 60), mi = m % 60
  if (f) return f.replace(/[HGhiK]/g, (c) => ({H: pad(h), G: h, h: pad(h % 12 || 12), i: pad(mi), K: h < 12 ? "AM" : "PM"}[c]))
  return h24 ? hhmm(m) : `${h % 12 || 12}:${pad(mi)} ${h < 12 ? "AM" : "PM"}`
}
// "9:30", "930", "9:30 pm", "21:15" -> minutes
const parseTyped = (s) => {
  const m = /^\s*(\d{1,2}):?(\d{2})?\s*([ap]m?)?\s*$/i.exec(s || "")
  if (!m) return null
  let h = +m[1]; const mi = +(m[2] || 0)
  if (m[3]) { h = h % 12; if (m[3][0].toLowerCase() === "p") h += 12 }
  return h < 24 && mi < 60 ? h * 60 + mi : null
}

// <.time_picker>: the hidden `[data-value]` input is the source of truth ("HH:MM").
export default {
  mounted() {
    this.cfg = JSON.parse(this.el.dataset.luConfig)
    this.onClick = (e) => this.click(e)
    this.onKey = (e) => this.key(e)
    this.onChange = (e) => { if (e.target === this.input()) this.typed() }
    this.onSync = () => this.refresh()
    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("keydown", this.onKey)
    this.el.addEventListener("change", this.onChange)
    this.el.addEventListener("lu:sync", this.onSync)
    if (this.cfg.variant === "input")
      this.undismiss = dismiss(this.el, () => !this.pop().hidden, (back) => this.close(back))
    this.refresh()
  },
  updated() { this.cfg = JSON.parse(this.el.dataset.luConfig); this.refresh() },
  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("keydown", this.onKey)
    this.el.removeEventListener("change", this.onChange)
    this.el.removeEventListener("lu:sync", this.onSync)
    this.undismiss && this.undismiss()
  },

  input() { return this.el.querySelector("input[type=text]") },
  hidden() { return this.el.querySelector("[data-value]") },
  pop() { return this.el.querySelector("[role=dialog]") },
  value() {
    const m = /^(\d{2}):(\d{2})$/.exec(this.hidden().value)
    return m ? +m[1] * 60 + +m[2] : null
  },

  refresh() {
    if (this.cfg.variant === "input") { this.input().value = text(this.value(), this.cfg.h24, this.cfg.format); this.draw() }
    else this.mark()
  },

  slots() {
    const {min, max, step} = this.cfg, out = []
    for (let m = min; m <= max; m += step) out.push(m)
    return out
  },

  draw() {
    const list = this.pop().querySelector("[data-part=time-picker-list]"), v = this.value(), k = this.cfg.classes
    list.innerHTML = this.slots()
      .map((m) => `<button type="button" data-part="time-picker-slot" role="radio" class="${k.slot}" aria-checked="${m === v}" data-value="${hhmm(m)}">${esc(text(m, this.cfg.h24, this.cfg.format))}</button>`)
      .join("")
  },

  mark() {
    const v = this.value()
    this.el.querySelectorAll("[data-value][role=radio]").forEach((b) => {
      const on = b.dataset.value === (v == null ? "" : hhmm(v))
            b.setAttribute("aria-checked", String(on))
      b.tabIndex = on ? 0 : -1
    })
  },

  set(m) {
    this.hidden().value = m == null ? "" : hhmm(m)
    if (this.cfg.variant === "input") this.input().value = text(m, this.cfg.h24, this.cfg.format)
    this.mark()
    emitInput(this.hidden())
    push(this, this.cfg.onChange, this.cfg.target, {id: (this.input() || this.hidden()).id, value: this.hidden().value})
  },

  typed() {
    const raw = this.input().value
    if (raw.trim() === "") return this.set(null)
    const m = parseTyped(raw)
    if (m != null && m >= this.cfg.min && m <= this.cfg.max) this.set(m)
    else this.input().value = text(this.value(), this.cfg.h24, this.cfg.format)
  },

  click(e) {
    const b = e.target.closest && e.target.closest("[data-value]")
    if (b && b.tagName === "BUTTON") {
      const [h, m] = b.dataset.value.split(":").map(Number)
      this.set(h * 60 + m)
      if (this.cfg.variant === "input") this.close(true)
      return
    }
    if (this.cfg.variant === "input" && e.target.closest("[data-part=input]") && !this.input().disabled && !e.target.closest("button"))
      this.openPop()
  },

  key(e) {
    if (this.cfg.variant === "list") {
      const items = [...this.el.querySelectorAll("[role=radio]")]
      const i = items.indexOf(document.activeElement)
      const d = {ArrowDown: 1, ArrowRight: 1, ArrowUp: -1, ArrowLeft: -1}[e.key]
      if (i >= 0 && d) { e.preventDefault(); const n = items[(i + d + items.length) % items.length]; n.focus(); n.click() }
      return
    }
    if (e.target === this.input() && (e.key === "ArrowDown" || e.key === "Enter")) { e.preventDefault(); this.openPop() }
    if (e.key === "ArrowDown" || e.key === "ArrowUp") {
      const items = [...this.pop().querySelectorAll("button")]
      const i = items.indexOf(document.activeElement)
      if (i >= 0) { e.preventDefault(); items[Math.max(0, Math.min(items.length - 1, i + (e.key === "ArrowDown" ? 1 : -1)))].focus() }
    }
  },

  openPop() {
    this.draw()
    this.pop().hidden = false
    this.input().setAttribute("aria-expanded", "true")
    const list = this.pop().querySelector("[data-part=time-picker-list]")
    const target = list.querySelector("[aria-checked=true]") || list.querySelector(`[data-value="${pad(this.cfg.defaultHour)}:00"]`) || list.firstElementChild
    if (target) list.scrollTop = target.offsetTop - list.clientHeight / 2
  },
  close(back) {
    this.pop().hidden = true
    this.input().setAttribute("aria-expanded", "false")
    if (back) this.input().focus()
  },
}
