// <.calendar on_select=...>: roving tabindex and arrow keys over the day cells.
const addDays = (s, n) => {
  const [y, m, d] = s.split("-").map(Number)
  const t = new Date(y, m - 1, d + n)
  return `${t.getFullYear()}-${String(t.getMonth() + 1).padStart(2, "0")}-${String(t.getDate()).padStart(2, "0")}`
}

export default {
  mounted() {
    this.onKey = (e) => this.key(e)
    this.el.addEventListener("keydown", this.onKey)
    this.focusPending()
  },
  updated() { this.focusPending() },
  destroyed() { this.el.removeEventListener("keydown", this.onKey) },

  cell(date) { return this.el.querySelector(`[data-date="${date}"][tabindex]`) },
  navButtons() { return this.el.querySelectorAll("[data-part=calendar-nav]") },

  focusPending() {
    if (!this.pending) return
    const c = this.cell(this.pending)
    if (c) { this.setFocus(c); this.pending = null }
  },

  setFocus(c) {
    this.el.querySelectorAll('[data-date][tabindex="0"]').forEach((x) => (x.tabIndex = -1))
    c.tabIndex = 0
    c.focus()
  },

  key(e) {
    const cur = e.target.closest && e.target.closest("[data-date][tabindex]")
    if (!cur) return
    const date = cur.dataset.date
    const moves = {ArrowLeft: -1, ArrowRight: 1, ArrowUp: -7, ArrowDown: 7}
    if (e.key in moves) {
      e.preventDefault()
      const to = addDays(date, moves[e.key])
      const c = this.cell(to)
      if (c) return this.setFocus(c)
      // past the edge: ask the server for the neighbour period
      const [prev, next] = this.navButtons()
      this.pending = to
      ;(moves[e.key] < 0 ? prev : next)?.click()
    } else if (e.key === "PageUp" || e.key === "PageDown") {
      e.preventDefault()
      const [prev, next] = this.navButtons()
      ;(e.key === "PageUp" ? prev : next)?.click()
    } else if (e.key === "Home" || e.key === "End") {
      e.preventDefault()
      const cells = [...this.el.querySelectorAll("[data-date][tabindex]")]
      const i = cells.indexOf(cur), row = Math.floor(i / 7) * 7
      this.setFocus(cells[e.key === "Home" ? row : Math.min(row + 6, cells.length - 1)])
    } else if (e.key === "Enter" || e.key === " ") {
      e.preventDefault()
      cur.click()
    }
  },
}
