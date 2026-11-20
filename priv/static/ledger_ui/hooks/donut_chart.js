// Hover of the server-rendered `donut_chart/1` (the ring element): dims the other slices, lights the
// plan row and shows the hovered share in the middle. The plan rows (`[data-row]`) are the siblings
// that follow the ring, so the hook listens on the parent. Event delegation, no state outside the DOM.
// Parts are found by `data-part` and the dim/on states are `data-state` (the Elixir component owns the
// utilities that read them).
const SEG = '[data-part="donut-chart-segment"]'

export default {
  mounted() {
    this.scope = this.el.parentElement
    this.on = (e) => {
      const t = e.target.closest(`${SEG}, [data-row]`)
      if (t && this.scope.contains(t)) this.focus(+(t.dataset.i ?? t.dataset.row))
    }
    this.off = (e) => {
      if (e.target.closest(`${SEG}, [data-row]`)) this.focus(null)
    }
    this.scope.addEventListener("mouseover", this.on)
    this.scope.addEventListener("mouseout", this.off)
  },
  destroyed() {
    this.scope.removeEventListener("mouseover", this.on)
    this.scope.removeEventListener("mouseout", this.off)
  },
  focus(i) {
    const k = this.el.querySelector("[data-k]"), v = this.el.querySelector("[data-v]")
    const flag = (n, state) => (state ? n.setAttribute("data-state", state) : n.removeAttribute("data-state"))
    this.el.querySelectorAll(SEG).forEach((c) => flag(c, i != null && +c.dataset.i !== i && "dim"))
    this.scope.querySelectorAll("[data-row]").forEach((r) => flag(r, +r.dataset.row === i && "on"))
    if (!k || !v) return
    if (i == null) {
      k.textContent = k.dataset.luDefault; v.textContent = v.dataset.luDefault
    } else {
      const row = this.scope.querySelector(`[data-row="${i}"]`)
      // the name is the text node that follows the swatch
      const name = row?.querySelector('[data-part="donut-chart-swatch"]')?.nextSibling?.textContent || ""
      k.textContent = name.trim().toUpperCase()
      v.textContent = row?.querySelector('[data-part="donut-chart-percent"]')?.textContent || ""
    }
  }
}
