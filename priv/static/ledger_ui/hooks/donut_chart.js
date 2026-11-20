// Hover of the server-rendered `donut_chart/1` (the `.lu-donut` element): dims the other slices,
// lights the plan row and shows the hovered share in the middle. The plan rows (`[data-row]`) are
// the siblings that follow the ring, so the hook listens on the parent. Event delegation, no
// state outside the DOM.
export default {
  mounted() {
    this.scope = this.el.parentElement
    this.on = (e) => {
      const t = e.target.closest(".lu-seg, [data-row]")
      if (t && this.scope.contains(t)) this.focus(+(t.dataset.i ?? t.dataset.row))
    }
    this.off = (e) => {
      if (e.target.closest(".lu-seg, [data-row]")) this.focus(null)
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
    this.el.querySelectorAll(".lu-seg").forEach((c) => c.classList.toggle("dim", i != null && +c.dataset.i !== i))
    this.scope.querySelectorAll("[data-row]").forEach((r) => r.classList.toggle("on", +r.dataset.row === i))
    if (!k || !v) return
    if (i == null) {
      k.textContent = k.dataset.default; v.textContent = v.dataset.default
    } else {
      const row = this.scope.querySelector(`[data-row="${i}"]`)
      const name = row?.querySelector("i")?.nextSibling?.textContent || ""
      k.textContent = name.trim().toUpperCase()
      v.textContent = row?.querySelector(".p")?.textContent || ""
    }
  }
}
