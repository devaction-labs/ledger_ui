// LedgerUI.Scrollspy: marks the link of the section in view.
//
// Watches the elements the links point at (#hash hrefs) and sets aria-current="true" and the class
// `on` on the link of the last section whose top is above `offset` pixels from the top of the
// view (data-offset, 120 by default). Clicks scroll to the section.

export default {
  mounted() {
    this.ticking = false
    this.onScroll = () => {
      if (this.ticking) return
      this.ticking = true
      requestAnimationFrame(() => {
        this.ticking = false
        this.update()
      })
    }
    this.onClick = (e) => {
      const link = e.target.closest("a")
      const target = link && this.target(link)
      if (!target) return
      e.preventDefault()
      const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches
      target.scrollIntoView({behavior: reduce ? "auto" : "smooth", block: "start"})
      if (history.replaceState) history.replaceState(null, "", link.getAttribute("href"))
      this.mark(link)
    }
    window.addEventListener("scroll", this.onScroll, {passive: true, capture: true})
    window.addEventListener("resize", this.onScroll, {passive: true})
    this.el.addEventListener("click", this.onClick)
    this.update()
  },

  updated() {
    this.update()
  },

  destroyed() {
    window.removeEventListener("scroll", this.onScroll, {capture: true})
    window.removeEventListener("resize", this.onScroll)
    this.el.removeEventListener("click", this.onClick)
  },

  offset() {
    const n = Number(this.el.getAttribute("data-offset"))
    return Number.isFinite(n) && n > 0 ? n : 120
  },

  target(link) {
    const href = link.getAttribute("href") || ""
    if (href.length < 2 || href[0] !== "#") return null
    return document.getElementById(decodeURIComponent(href.slice(1)))
  },

  update() {
    const offset = this.offset()
    let current = null
    for (const link of this.el.querySelectorAll("a")) {
      const target = this.target(link)
      if (!target) continue
      if (target.getBoundingClientRect().top - offset <= 1) current = link
    }
    if (!current) current = Array.from(this.el.querySelectorAll("a")).find((l) => this.target(l)) || null
    // At the very end of the page the last section may never reach the offset.
    const root = document.scrollingElement
    if (root && root.scrollTop + root.clientHeight >= root.scrollHeight - 2) {
      const last = Array.from(this.el.querySelectorAll("a")).filter((l) => this.target(l)).pop()
      if (last) current = last
    }
    this.mark(current)
  },

  mark(current) {
    for (const link of this.el.querySelectorAll("a")) {
      const on = link === current
      if (on) link.setAttribute("aria-current", "true")
      else link.removeAttribute("aria-current")
      link.classList.toggle("on", on)
    }
  },
}
