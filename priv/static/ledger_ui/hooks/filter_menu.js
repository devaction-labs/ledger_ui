// LedgerUI.FilterMenu: menu of filter groups with staged ticks.
//
// In `apply` mode (default) ticks only stage: the browser owns the state until Apply, the
// group's row counts the staged values, Apply shows how many records they leave (the options'
// `data-lu-count`, or `data-lu-results`) and closing the menu any other way takes the staged values
// back. In `live` mode every tick reaches the form's `phx-change`. Options are real inputs, so
// the form posts them. `on_change`, `on_apply` and `on_clear` push `{id, values}`.

// `hidden` loses to any `display` the stylesheet sets (the option rows, the counters...): set both.
const hide = (el, on, show = "") => {
  el.hidden = on
  el.style.display = on ? "none" : show
}

export default {
  mounted() {
    this.isOpen = !this.panel().hidden
    this.onClick = (e) => this.click(e)
    this.onKey = (e) => this.key(e)
    this.onChange = (e) => this.changed(e)
    this.onDoc = (e) => {
      if (this.isOpen && !this.el.contains(e.target)) this.close(true)
    }
    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("keydown", this.onKey)
    this.el.addEventListener("change", this.onChange)
    this.el.addEventListener("input", this.onChange)
    document.addEventListener("pointerdown", this.onDoc)
    this.refresh()
  },

  updated() {
    // Server re-rendered: the applied state may have changed; staged state is discarded
    // unless the menu is open.
    hide(this.panel(), !this.isOpen)
    this.trigger().setAttribute("aria-expanded", String(this.isOpen))
    if (!this.isOpen) this.revert()
    this.refresh()
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("keydown", this.onKey)
    this.el.removeEventListener("change", this.onChange)
    this.el.removeEventListener("input", this.onChange)
    document.removeEventListener("pointerdown", this.onDoc)
  },

  d() { return this.el.dataset },
  live() { return this.d().luMode === "live" },
  trigger() { return this.el.querySelector("[data-lu-trigger]") },
  panel() { return this.el.querySelector('[data-part="filter-popup"]') },
  groups() { return [...this.panel().querySelectorAll("[data-lu-group]")] },
  filters() { return this.groups().filter((g) => !g.hasAttribute("data-lu-section")) },
  inputs(g) {
    return [...g.querySelectorAll("input[type=checkbox], input[type=radio]")]
  },
  allInputs() { return [...this.panel().querySelectorAll("input[type=checkbox], input[type=radio]")] },
  label(key, fallback) { return this.d()[key] || fallback },

  // ---- state ------------------------------------------------------------------
  values() {
    const out = {}
    for (const g of this.groups()) {
      const name = g.dataset.luGroup.replace(/\[\]$/, "")
      const on = this.inputs(g).filter((i) => i.checked && i.value !== "").map((i) => i.value)
      out[name] = g.dataset.luType === "single" ? on[0] || "" : on
    }
    return out
  },

  appliedCount() {
    let n = 0
    for (const g of this.filters()) n += this.inputs(g).filter((i) => i.defaultChecked && i.value !== "").length
    return n
  },

  revert() {
    for (const i of this.allInputs()) i.checked = i.defaultChecked
    for (const g of this.panel().querySelectorAll("[data-lu-custom-input]")) {
      const grp = g.closest("[data-lu-group]")
      this.customText(grp)
    }
  },

  refresh() {
    // trigger count = applied filters
    const c = this.el.querySelector("[data-lu-count]")
    if (c) {
      const n = this.appliedCount()
      c.textContent = n
      hide(c, n === 0, "inline-grid")
    }
    for (const g of this.filters()) {
      const n = this.inputs(g).filter((i) => i.checked && i.value !== "").length
      const badge = g.querySelector("[data-lu-gcount]")
      if (badge) {
        badge.textContent = n
        hide(badge, n === 0, "inline-grid")
      }
    }
    const apply = this.el.querySelector("[data-lu-apply]")
    if (apply) {
      const n = this.resultCount()
      const word = this.label("applyLabel", "Apply")
      apply.textContent = n === null ? word : `${word} · ${n}`
    }
  },

  // The server's number, or the smallest staged group's total of option counts.
  resultCount() {
    if (this.d().luResults !== undefined && this.d().luResults !== "") return parseInt(this.d().luResults, 10)
    let best = null
    for (const g of this.filters()) {
      const on = this.inputs(g).filter((i) => i.checked && i.value !== "" && !i.hasAttribute("data-lu-custom-input"))
      if (!on.length) continue
      const counts = on.map((i) => parseInt(i.dataset.luCount, 10))
      if (counts.some(Number.isNaN)) return null
      const sum = counts.reduce((a, b) => a + b, 0)
      best = best === null ? sum : Math.min(best, sum)
    }
    return best
  },

  // ---- open / close ---------------------------------------------------------------
  open() {
    if (this.isOpen) return
    this.isOpen = true
    hide(this.panel(), false)
    this.el.setAttribute("data-open", "")
    this.trigger().setAttribute("aria-expanded", "true")
    this.refresh()
    const first = this.focusables()[0]
    if (first) first.focus()
  },

  close(discard, refocus) {
    if (!this.isOpen) return
    this.isOpen = false
    this.closeSubs()
    hide(this.panel(), true)
    this.el.removeAttribute("data-open")
    this.trigger().setAttribute("aria-expanded", "false")
    if (discard) {
      this.revert()
      this.refresh()
    }
    if (refocus) this.trigger().focus()
  },

  closeSubs(except) {
    for (const g of this.filters()) {
      const sub = g.querySelector("[data-lu-sub]")
      if (sub && sub !== except) {
        hide(sub, true)
        g.querySelector("[data-lu-row]").setAttribute("aria-expanded", "false")
      }
    }
  },

  openSub(group, focus) {
    const sub = group.querySelector("[data-lu-sub]")
    if (!sub) return
    this.closeSubs(sub)
    hide(sub, false)
    group.querySelector("[data-lu-row]").setAttribute("aria-expanded", "true")
    // flip to the left when the side panel would leave the window
    sub.style.left = "calc(100% + 6px)"
    sub.style.right = "auto"
    const r = sub.getBoundingClientRect()
    if (r.right > window.innerWidth - 8) {
      sub.style.left = "auto"
      sub.style.right = "calc(100% + 6px)"
    }
    if (focus) {
      const f = this.subFocusables(group)[0]
      if (f) f.focus()
    }
  },

  focusables() {
    const out = []
    for (const g of this.groups()) {
      if (g.hasAttribute("data-lu-section")) out.push(...this.inputs(g))
      else out.push(g.querySelector("[data-lu-row]"))
    }
    out.push(...this.panel().querySelectorAll("[data-lu-clear], [data-lu-apply]"))
    return out.filter((n) => n && !n.disabled)
  },

  subFocusables(group) {
    const sub = group.querySelector("[data-lu-sub]")
    return [...sub.querySelectorAll("input:not([data-lu-custom-input]):not([type=date]), [data-lu-custom-row]")].filter(
      (n) => !n.disabled
    )
  },

  // ---- events -----------------------------------------------------------------------
  click(e) {
    const t = e.target
    if (t.closest("[data-lu-trigger]")) {
      this.isOpen ? this.close(true) : this.open()
      return
    }
    if (!this.panel().contains(t)) return
    const row = t.closest("[data-lu-row]")
    if (row) {
      const g = row.closest("[data-lu-group]")
      const sub = g.querySelector("[data-lu-sub]")
      sub.hidden ? this.openSub(g, false) : this.closeSubs()
      return
    }
    const custom = t.closest("[data-lu-custom-row]")
    if (custom) {
      const g = custom.closest("[data-lu-group]")
      const panel = g.querySelector("[data-lu-custom-panel]")
      hide(panel, !panel.hidden)
      if (!panel.hidden) panel.querySelector("[data-lu-from]").focus()
      return
    }
    if (t.closest("[data-lu-clear]")) return this.clear()
    if (t.closest("[data-lu-apply]")) return this.apply()
  },

  key(e) {
    const t = e.target
    if (t.closest && t.closest("[data-lu-trigger]")) {
      if (!this.isOpen && ["ArrowDown", "Enter", " "].includes(e.key)) {
        e.preventDefault()
        this.open()
      }
      return
    }
    if (!this.isOpen || !this.panel().contains(t)) return
    const group = t.closest("[data-lu-group]")
    const inSub = !!t.closest("[data-lu-sub]")
    if (e.key === "Escape") {
      e.preventDefault()
      e.stopPropagation()
      const cp = t.closest("[data-lu-custom-panel]")
      if (cp) {
        hide(cp, true)
        group.querySelector("[data-lu-custom-row]").focus()
      } else if (inSub) {
        this.closeSubs()
        group.querySelector("[data-lu-row]").focus()
      } else {
        this.close(true, true)
      }
      return
    }
    if (inSub) {
      if (t.matches("input[type=date]")) return
      const list = this.subFocusables(group)
      const i = list.indexOf(t)
      if (e.key === "ArrowDown") {
        e.preventDefault()
        list[Math.min(i + 1, list.length - 1)].focus()
      } else if (e.key === "ArrowUp") {
        e.preventDefault()
        list[Math.max(i - 1, 0)].focus()
      } else if (e.key === "ArrowLeft") {
        e.preventDefault()
        this.closeSubs()
        group.querySelector("[data-lu-row]").focus()
      } else if (e.key === "Enter" && t.matches("input")) {
        e.preventDefault()
        t.click()
      }
      return
    }
    const list = this.focusables()
    const i = list.indexOf(t)
    if (e.key === "ArrowDown") {
      e.preventDefault()
      list[Math.min(i + 1, list.length - 1)].focus()
    } else if (e.key === "ArrowUp") {
      e.preventDefault()
      list[Math.max(i - 1, 0)].focus()
    } else if (t.matches("[data-lu-row]") && ["ArrowRight", "Enter", " "].includes(e.key)) {
      e.preventDefault()
      this.openSub(group, true)
    } else if (e.key === "Enter" && t.matches("input")) {
      e.preventDefault()
      t.click()
    }
  },

  changed(e) {
    const t = e.target
    if (!this.panel().contains(t)) return
    if (t.matches("[data-lu-from], [data-lu-to]")) {
      // The calendar's own inputs never reach the form or the events.
      e.stopPropagation()
      if (e.type === "change") this.pickRange(t.closest("[data-lu-group]"))
      return
    }
    if (!t.matches("input[type=checkbox], input[type=radio]")) return
    this.refresh()
    // apply mode: ticks do not reach the form's phx-change
    if (!this.live()) e.stopPropagation()
    const ev = this.d().luOnChange
    if (ev && e.type === "change") this.push(ev, { id: this.el.id, values: this.values() })
  },

  pickRange(group) {
    const from = group.querySelector("[data-lu-from]").value
    const to = group.querySelector("[data-lu-to]").value
    if (!from || !to) return
    const [a, b] = from <= to ? [from, to] : [to, from]
    const input = group.querySelector("[data-lu-custom-input]")
    input.value = `custom:${a}..${b}`
    input.checked = true
    this.customText(group, a, b)
    hide(group.querySelector("[data-lu-custom-panel]"), true)
    this.refresh()
    const ev = this.d().luOnChange
    if (ev) this.push(ev, { id: this.el.id, values: this.values() })
    if (this.live()) input.dispatchEvent(new Event("input", { bubbles: true }))
  },

  fmt(iso) {
    if (this.d().luLocale !== "pt_BR") return iso
    const [y, m, d] = iso.split("-")
    return `${d}/${m}/${y}`
  },

  customText(group, from, to) {
    const text = group.querySelector("[data-lu-custom-text]")
    if (!text) return
    const input = group.querySelector("[data-lu-custom-input]")
    let f = from
    let t = to
    if (!f && input.checked && input.value.startsWith("custom:")) {
      ;[f, t] = input.value.slice(7).split("..")
    }
    text.textContent = f && t ? `${this.fmt(f)} – ${this.fmt(t)}` : text.dataset.luDefault
  },

  clear() {
    for (const g of this.filters()) for (const i of this.inputs(g)) i.checked = false
    for (const g of this.panel().querySelectorAll("[data-lu-custom-input]")) this.customText(g.closest("[data-lu-group]"))
    this.refresh()
    const ev = this.d().luOnClear
    if (ev) this.push(ev, { id: this.el.id, values: this.values() })
    if (this.live()) {
      const first = this.allInputs()[0]
      if (first) first.dispatchEvent(new Event("input", { bubbles: true }))
    }
  },

  apply() {
    const values = this.values()
    for (const i of this.allInputs()) i.defaultChecked = i.checked
    this.refresh()
    this.close(false, true)
    const ev = this.d().luOnApply
    if (ev) return this.push(ev, { id: this.el.id, values })
    const form = this.el.closest("form")
    if (form) form.requestSubmit()
  },

  push(ev, payload) {
    let target = this.d().luTarget
    if (target && /^\d+$/.test(target)) target = parseInt(target, 10)
    target ? this.pushEventTo(target, ev, payload) : this.pushEvent(ev, payload)
  },
}
