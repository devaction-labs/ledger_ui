import {floatShow, floatHide, floatSync, floatPlace, floatDestroy} from "../lib/popfloat.js"
import {iso, parse, fmt, addDays, addMonths, same, esc, gridDays, rotate, push, dismiss, emitInput} from "../lib/picker.js"

// <.date_picker>: state lives in the hidden inputs (source of truth); the calendar is drawn from it.
export default {
  mounted() {
    this.cfg = JSON.parse(this.el.dataset.luConfig)
    this.view = null
    this.onClick = (e) => this.click(e)
    this.onKey = (e) => this.key(e)
    this.onClear = () => this.set([], true)
    this.onSync = () => this.refresh()
    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("keydown", this.onKey)
    this.el.addEventListener("lu:clear", this.onClear)
    this.el.addEventListener("lu:sync", this.onSync)
    this.undismiss = dismiss(this.el, () => !this.pop().hidden, (back) => this.close(back))
    this.refresh()
  },
  updated() {
    this.cfg = JSON.parse(this.el.dataset.luConfig)
    this.refresh()
    floatSync(this, this.pop())
    // The patch put the server's `aria-expanded` back: write the open state again.
    if (!this.cfg.inline) this.input().setAttribute("aria-expanded", String(!this.pop().hidden))
  },
  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("keydown", this.onKey)
    this.el.removeEventListener("lu:clear", this.onClear)
    this.el.removeEventListener("lu:sync", this.onSync)
    this.undismiss && this.undismiss()
    floatDestroy(this)
  },

  anchor() { const i = this.input(); return (i && i.closest("[data-part=input]")) || this.el },
  pop() { return this.el.querySelector("[role=dialog]") },
  input() { return this.el.querySelector("input[type=text]") },
  vals() { return this.el.querySelector("[data-values]") },

  // Picked dates (ISO strings) read from the hidden inputs.
  selection() {
    return [...this.vals().querySelectorAll("input")].map((i) => i.value).filter(Boolean)
  },

  refresh() {
    const sel = this.selection().map(parse).filter(Boolean)
    if (!this.view || !this.open) this.view = new Date((sel[0] || parse(this.cfg.today)).getFullYear(), (sel[0] || parse(this.cfg.today)).getMonth(), 1)
    this.draw(sel)
  },

  disabled(d) {
    const c = this.cfg, s = iso(d)
    return (c.min && s < c.min) || (c.max && s > c.max) || c.disabledDates.includes(s) || c.disabledWeekdays.includes(d.getDay())
  },

  draw(sel) {
    const c = this.cfg, pop = this.pop()
    const cal = pop.querySelector("[data-part=date-picker-calendar]")
    if (!cal) return
    const isRange = c.mode === "range"
    const [a, b] = isRange ? [sel[0], sel[1]] : []
    const today = parse(c.today), k = c.classes
    cal.querySelector("[data-part=date-picker-title]").textContent = `${c.months[this.view.getMonth()]} ${this.view.getFullYear()}`
    const hb = cal.querySelectorAll("[data-part=date-picker-nav]")
    hb[0].setAttribute("aria-label", c.labels.picker_previous)
    hb[1].setAttribute("aria-label", c.labels.picker_next)
    const letters = rotate(c.weekdays, c.weekStart).map((w) => `<span class="${k.letter}">${esc(w.slice(0, 1))}</span>`).join("")
    const focus = this.focusDate ? iso(this.focusDate) : (sel[0] ? iso(sel[0]) : iso(this.view))
    const days = gridDays(this.view, c.weekStart).map(({d, out}) => {
      const on = isRange ? (a && b && (same(d, a) || same(d, b))) || (a && !b && same(d, a)) : sel.some((x) => same(x, d))
      // one tone per day (range edges > range body > selected > outside the month > plain)
      let tone = out ? "out" : "normal"
      if (!isRange && on) tone = "s"
      if (isRange && a && same(d, a)) tone = b && !same(a, b) ? "rs" : "s"
      else if (isRange && b && same(d, b)) tone = "re"
      else if (isRange && a && b && d > a && d < b) tone = "r"
      const cls = [k.base, k.tones[tone]]
      if (same(d, today)) cls.push(k.today)
      const dis = this.disabled(d) ? " disabled" : ""
      const label = c.labels.picker_day
        .replace("%{weekday}", c.weekdays[d.getDay()]).replace("%{month}", c.months[d.getMonth()])
        .replace("%{day}", d.getDate()).replace("%{year}", d.getFullYear())
      const cur = same(d, today) ? ' aria-current="date"' : ""
      return `<button data-part="date-picker-day" class="${cls.join(" ")}" type="button" data-d="${iso(d)}" role="gridcell" aria-selected="${!!on}" aria-label="${esc(label)}"${cur}${dis} tabindex="${iso(d) === focus ? 0 : -1}">${d.getDate()}</button>`
    })
    cal.querySelector("[data-part=date-picker-grid]").innerHTML = letters + days.join("")
    cal.querySelector("[data-part=date-picker-grid]").setAttribute("role", "grid")
    // presets highlight
    pop.querySelectorAll("[data-part=date-picker-preset]").forEach((btn, i) => {
      const p = c.presets[i]
      btn.setAttribute("aria-pressed", String(!!(p && p.from && a && b && p.from === iso(a) && p.to === iso(b))))
    })
    this.updateText(sel)
    floatPlace(this)
  },

  updateText(sel) {
    const c = this.cfg
    this.input().value = sel.map((d) => fmt(d, c.format, c.months, c.weekdays)).join(c.mode === "range" ? c.sep : ", ")
  },

  // Writes the selection to the hidden inputs, fires `input` and pushes on_change.
  set(list, notify) {
    const c = this.cfg
    list = list.map((d) => iso(d))
    const name = this.el.dataset.luName || ""
    const hid = (n, v) => `<input type="hidden" name="${esc(n)}" value="${esc(v)}">`
    let html
    if (c.mode === "single") html = hid(name, list[0] || "")
    else if (c.mode === "range" && c.startName) html = hid(c.startName, list[0] || "") + hid(c.endName, list[1] || "")
    else html = hid(`${name}[]`, "") + list.map((v) => hid(`${name}[]`, v)).join("")
    this.vals().innerHTML = html
    this.draw(list.map(parse))
    if (notify) {
      emitInput(this.vals().querySelector("input"))
      const value = c.mode === "single" ? list[0] || "" : list
      push(this, c.onChange, c.target, {id: this.input().id, value})
    }
  },

  pick(d) {
    if (this.disabled(d)) return
    const c = this.cfg, sel = this.selection().map(parse)
    if (c.mode === "single") { this.set([d], true); this.close(true) }
    else if (c.mode === "multiple") {
      const has = sel.some((x) => same(x, d))
      this.set(has ? sel.filter((x) => !same(x, d)) : [...sel, d].sort((x, y) => x - y), true)
    } else if (sel.length === 1) {
      this.set([sel[0], d].sort((x, y) => x - y), true)
      this.close(true)
    } else this.set([d], false)
  },

  click(e) {
    const t = e.target
    const day = t.closest && t.closest("[data-part=date-picker-day]")
    if (day && day.dataset.d) return this.pick(parse(day.dataset.d))
    const nav = t.closest && t.closest("[data-part=date-picker-nav]")
    if (nav) {
      const btns = [...nav.parentNode.querySelectorAll("button")]
      this.view = addMonths(this.view, btns.indexOf(nav) === 0 ? -1 : 1)
      return this.draw(this.selection().map(parse))
    }
    const pre = t.closest && t.closest("[data-part=date-picker-preset]")
    if (pre) {
      const items = [...pre.parentNode.querySelectorAll("[data-part=date-picker-preset]")]
      const p = this.cfg.presets[items.indexOf(pre)]
      if (p && p.from) {
        const from = parse(p.from), to = parse(p.to)
        this.set(this.cfg.mode === "range" ? [from, to] : [from], true)
        this.view = new Date(from.getFullYear(), from.getMonth(), 1)
        this.draw(this.selection().map(parse))
        this.close(true)
      }
      return
    }
    if (t.closest && t.closest("[data-part=input]") && !this.input().disabled && !t.closest("button")) this.toggle()
  },

  key(e) {
    const day = e.target.closest && e.target.closest("[data-part=date-picker-day]")
    if (e.target === this.input() && (e.key === "ArrowDown" || e.key === "Enter")) {
      e.preventDefault()
      return this.openPop(true)
    }
    if (!day || !day.dataset.d) return
    const d = parse(day.dataset.d)
    const moves = {ArrowLeft: addDays(d, -1), ArrowRight: addDays(d, 1), ArrowUp: addDays(d, -7), ArrowDown: addDays(d, 7),
      Home: addDays(d, -((d.getDay() - this.cfg.weekStart + 7) % 7)), End: addDays(d, 6 - ((d.getDay() - this.cfg.weekStart + 7) % 7)),
      PageUp: e.shiftKey ? new Date(d.getFullYear() - 1, d.getMonth(), d.getDate()) : new Date(d.getFullYear(), d.getMonth() - 1, d.getDate()),
      PageDown: e.shiftKey ? new Date(d.getFullYear() + 1, d.getMonth(), d.getDate()) : new Date(d.getFullYear(), d.getMonth() + 1, d.getDate())}
    if (moves[e.key]) {
      e.preventDefault()
      this.focusDate = moves[e.key]
      this.view = new Date(this.focusDate.getFullYear(), this.focusDate.getMonth(), 1)
      this.draw(this.selection().map(parse))
      this.pop().querySelector(`[data-d="${iso(this.focusDate)}"]`)?.focus()
    } else if (e.key === "Enter" || e.key === " ") { e.preventDefault(); this.pick(d) }
  },

  toggle() { this.pop().hidden ? this.openPop() : this.close() },
  openPop(focus) {
    if (this.cfg.inline) return
    this.open = true
    floatShow(this, this.pop(), () => this.anchor())
    this.input().setAttribute("aria-expanded", "true")
    this.refresh()
    floatShow(this, this.pop(), () => this.anchor())
    if (focus) (this.pop().querySelector('[data-part=date-picker-day][tabindex="0"]') || this.pop().querySelector("[data-part=date-picker-day]"))?.focus()
  },
  close(back) {
    if (this.cfg.inline) return
    this.open = false
    floatHide(this, this.pop())
    this.input().setAttribute("aria-expanded", "false")
    this.focusDate = null
    if (back) this.input().focus()
  },
}
