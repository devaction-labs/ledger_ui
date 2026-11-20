// LedgerUI.Sticky: adds `data-stuck-class` (or a 1px bottom line) and data-stuck once the page is
// scrolled past `data-offset` pixels; takes them off when it is back.
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
    if (cls.length) cls.forEach((c) => el.classList.toggle(c, stuck))
    else el.style.boxShadow = stuck ? "0 1px 0 var(--line)" : ""
    if (stuck) el.setAttribute("data-stuck", ""); else el.removeAttribute("data-stuck")
  },
}
