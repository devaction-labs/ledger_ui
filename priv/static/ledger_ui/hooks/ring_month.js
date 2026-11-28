// Keyboard and list link of the server-rendered `ring_month/1`.
//
// Hover is plain CSS (`:has()` / `:hover` in the component's utilities); an element is "active" when it
// is hovered OR has `data-active`. This hook only sets `data-active` for what CSS cannot see:
//   * the keyboard: the day spokes (`[data-tgt="day"]`) and the series arcs (`[data-tgt="series"]`) are
//     roving tab stops (one each); arrows / Home / End walk them, focus lights them, Esc goes back to the summary;
//   * the rows of a `breakdown_list` linked with `ring={id}` (`[data-lu-ring="<id>"] [data-lu-series]`):
//     pointer or focus on a row lights the series with that id (`data-id`), and the row gets `data-active`.
// The root gets `data-active-day` / `data-active-series` while something is active. Everything is removed in `destroyed()`.
const DAY = '[data-tgt="day"]'
const SER = '[data-tgt="series"]'

export default {
  mounted() {
    this.rows = []
    this.onKey = (e) => this.key(e)
    this.onFocusIn = (e) => {
      const n = e.target.closest && e.target.closest(`${DAY}, ${SER}`)
      if (n && this.el.contains(n)) { this.rove(n); this.activate(n) }
    }
    this.onFocusOut = (e) => {
      const n = e.target.closest && e.target.closest(`${DAY}, ${SER}`)
      if (n) this.clear()
    }
    this.el.addEventListener("keydown", this.onKey)
    this.el.addEventListener("focusin", this.onFocusIn)
    this.el.addEventListener("focusout", this.onFocusOut)
    this.mo = typeof MutationObserver === "function" ? new MutationObserver(() => this.bindRows()) : null
    this.bind()
  },
  updated() { this.bind() },
  destroyed() {
    this.el.removeEventListener("keydown", this.onKey)
    this.el.removeEventListener("focusin", this.onFocusIn)
    this.el.removeEventListener("focusout", this.onFocusOut)
    this.unbindRows()
    this.mo && this.mo.disconnect()
    this.clear()
  },

  days() { return [...this.el.querySelectorAll(DAY)].filter((g) => g.querySelector('[data-part="ring-month-hit"]')) },
  series() { return [...this.el.querySelectorAll(SER)] },

  bind() {
    for (const list of [this.days(), this.series()]) {
      const cur = list.findIndex((n) => n === this.cur) >= 0 ? list.indexOf(this.cur) : 0
      list.forEach((n, i) => n.setAttribute("tabindex", i === cur ? "0" : "-1"))
    }
    this.bindRows()
  },

  // roving tabindex: the focused one is the only tab stop of its group
  rove(n) {
    const list = n.matches(DAY) ? this.days() : this.series()
    list.forEach((x) => x.setAttribute("tabindex", x === n ? "0" : "-1"))
    this.cur = n
  },

  key(e) {
    const n = e.target.closest && e.target.closest(`${DAY}, ${SER}`)
    if (e.key === "Escape") { this.clear(); n && n.blur && n.blur(); return }
    if (!n || !this.el.contains(n)) return
    const list = n.matches(DAY) ? this.days() : this.series()
    const i = list.indexOf(n)
    let to = null
    if (e.key === "ArrowRight" || e.key === "ArrowDown") to = list[(i + 1) % list.length]
    else if (e.key === "ArrowLeft" || e.key === "ArrowUp") to = list[(i - 1 + list.length) % list.length]
    else if (e.key === "Home") to = list[0]
    else if (e.key === "End") to = list[list.length - 1]
    if (to) { e.preventDefault(); this.rove(to); to.focus() }
  },

  activate(n) {
    this.clear()
    n.setAttribute("data-active", "")
    if (n.matches(DAY)) this.el.setAttribute("data-active-day", n.dataset.day)
    else {
      this.el.setAttribute("data-active-series", n.dataset.id)
      this.rows.forEach((r) => r.dataset.luSeries === n.dataset.id && r.setAttribute("data-active", ""))
    }
  },

  clear() {
    this.el.querySelectorAll("[data-active]").forEach((n) => n.removeAttribute("data-active"))
    this.rows.forEach((r) => r.removeAttribute("data-active"))
    this.el.removeAttribute("data-active-day")
    this.el.removeAttribute("data-active-series")
  },

  // the linked list: rows are found in the document (it is another component) and watched for patches
  listRoots() { return [...document.querySelectorAll(`[data-lu-ring="${CSS.escape(this.el.id)}"]`)] },

  bindRows() {
    this.unbindRows()
    this.roots = this.listRoots()
    this.rows = this.roots.flatMap((r) => [...r.querySelectorAll("[data-lu-series]")])
    this.handlers = new Map()
    for (const row of this.rows) {
      const on = () => {
        const n = this.series().find((s) => s.dataset.id === row.dataset.luSeries)
        if (n) this.activate(n)
      }
      const off = () => this.clear()
      this.handlers.set(row, {on, off})
      row.addEventListener("pointerenter", on)
      row.addEventListener("pointerleave", off)
      row.addEventListener("focus", on)
      row.addEventListener("blur", off)
    }
    if (this.mo) this.roots.forEach((r) => this.mo.observe(r, {childList: true, subtree: true}))
  },

  unbindRows() {
    if (this.mo) this.mo.disconnect()
    for (const [row, h] of this.handlers || []) {
      row.removeEventListener("pointerenter", h.on)
      row.removeEventListener("pointerleave", h.off)
      row.removeEventListener("focus", h.on)
      row.removeEventListener("blur", h.off)
    }
    this.handlers = new Map()
  }
}
