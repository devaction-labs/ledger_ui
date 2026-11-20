// LedgerUI.Fab: the retract="auto" behaviour of <.fab variant="pill">.
// Starts expanded, retracts after data-after ms or as soon as the page scrolls, expands again on
// hover/focus. Touch devices (no hover) keep the bubble and a tap runs the action directly.
// data-state is preserved across patches by `keep-data-state`.
export default {
  mounted() {
    const el = this.el
    const coarse = window.matchMedia("(pointer: coarse)")
    const set = (state) => {
      if (!coarse.matches) el.setAttribute("data-state", state)
    }
    const after = parseInt(el.getAttribute("data-after") || "4000", 10)

    this.timer = null
    this.retract = () => {
      clearTimeout(this.timer)
      this.timer = null
      set("collapsed")
    }
    this.expand = () => {
      clearTimeout(this.timer)
      this.timer = null
      set("expanded")
    }
    this.leave = () => {
      if (!el.contains(document.activeElement)) set("collapsed")
    }

    el.addEventListener("mouseenter", this.expand)
    el.addEventListener("focusin", this.expand)
    el.addEventListener("mouseleave", this.leave)
    el.addEventListener("focusout", this.leave)
    window.addEventListener("scroll", this.retract, {capture: true, passive: true})

    set("expanded")
    this.timer = setTimeout(this.retract, after)
  },

  destroyed() {
    const el = this.el
    clearTimeout(this.timer)
    el.removeEventListener("mouseenter", this.expand)
    el.removeEventListener("focusin", this.expand)
    el.removeEventListener("mouseleave", this.leave)
    el.removeEventListener("focusout", this.leave)
    window.removeEventListener("scroll", this.retract, {capture: true})
  },
}
