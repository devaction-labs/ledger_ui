// LedgerUI.Sticky: adds `data-stuck-class` and `data-stuck` once the page is scrolled past `data-offset`
// pixels; takes them off when it is back. Without a stuck class the component draws the 1px bottom
// line itself (`data-[stuck]:shadow-…`).
export default {
  mounted() {
    this.stuck = false
    this.raf = null
    this.onScroll = () => {
      if (this.raf) return
      this.raf = requestAnimationFrame(() => { this.raf = null; this.check() })
    }
    window.addEventListener("scroll", this.onScroll, {passive: true})
    this.check()
  },
  updated() { this.apply(this.stuck) },
  destroyed() { window.removeEventListener("scroll", this.onScroll) },
  check() {
    const offset = parseInt(this.el.dataset.offset || "0", 10)
    const stuck = (window.scrollY || document.documentElement.scrollTop) > offset
    if (stuck !== this.stuck) { this.stuck = stuck; this.apply(stuck) }
  },
  apply(stuck) {
    const el = this.el
    const cls = (el.dataset.stuckClass || "").split(/\s+/).filter(Boolean)
    cls.forEach((c) => el.classList.toggle(c, stuck))
    if (stuck) el.setAttribute("data-stuck", ""); else el.removeAttribute("data-stuck")
  },
}
