// LedgerUI.ScrollBottom: keeps a growing list scrolled to its end, unless the reader scrolled up
// (within 32px of the end counts as the end).
const NEAR = 32

export default {
  mounted() {
    this.pinned = true
    this.onScroll = () => {
      const el = this.el
      this.pinned = el.scrollHeight - el.scrollTop - el.clientHeight <= NEAR
    }
    this.el.addEventListener("scroll", this.onScroll, {passive: true})
    this.toEnd()
  },
  updated() { if (this.pinned) this.toEnd() },
  destroyed() { this.el.removeEventListener("scroll", this.onScroll) },
  toEnd() { this.el.scrollTop = this.el.scrollHeight },
}
