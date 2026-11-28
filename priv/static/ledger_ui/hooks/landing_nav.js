// LedgerUI.LandingNav: sticky state (data-stuck after data-lu-stuck-after px) and the mega menu
// panels. open-on="hover" opens a panel when the pointer rests on its trigger, keeps it open while the
// pointer is in the trigger or the panel and closes after it leaves both; a click or tap opens too.
// Escape, a click outside and tabbing out close it; ArrowDown on a trigger opens and focuses the first
// item, arrows walk the items, Escape gives the focus back to the trigger.
//   data-lu-autohide  (with data-lu-sticky) data-hidden is set while scrolling down and removed when scrolling
//                     up, when the focus enters the bar or at the top; never while a mega menu is open.
//   data-lu-spy       the link whose #anchor section is in view gets aria-current="true" (the section is the
//                     last one whose top is above data-lu-spy-offset px; none before the first, the last at the
//                     end of the page). Only "true" is ever removed: aria-current="page" is the server's.
import {keep, stickAttr} from "../lib/keep.js"

const ITEMS = "a[href],button:not([disabled])"

export default {
  mounted() {
    const el = this.el
    this.hover = el.getAttribute("data-lu-open-on") !== "click"
    this.after = parseInt(el.getAttribute("data-lu-stuck-after") || "8", 10)
    this.sticky = el.hasAttribute("data-lu-sticky")
    this.current = null
    this.timer = null
    this.triggers = () => Array.from(el.querySelectorAll("[data-lnav-trigger]"))
    this.panel = (i) => el.querySelector(`[data-lnav-panel="${i}"]`)
    this.keepPanels()

    this.autohide = this.sticky && el.hasAttribute("data-lu-autohide")
    this.spy = el.hasAttribute("data-lu-spy")
    this.spyOffset = parseInt(el.getAttribute("data-lu-spy-offset") || "120", 10)
    this.lastY = window.scrollY
    this.ticking = false

    this.onScroll = () => {
      const y = window.scrollY
      if (this.sticky) el.toggleAttribute("data-stuck", y > this.after)
      if (this.autohide) this.slide(y)
      if (this.spy && !this.ticking) {
        this.ticking = true
        requestAnimationFrame(() => { this.ticking = false; this.mark() })
      }
    }
    this.hidden = false
    this.onFocusIn = () => { this.hidden = false; el.removeAttribute("data-hidden") }
    if (this.sticky || this.spy) {
      window.addEventListener("scroll", this.onScroll, {passive: true})
      if (this.spy) window.addEventListener("resize", this.onScroll, {passive: true})
      this.onScroll()
    }
    if (this.autohide) el.addEventListener("focusin", this.onFocusIn)

    this.onClick = (e) => {
      const t = e.target.closest("[data-lnav-trigger]")
      if (t) { e.preventDefault(); e.stopPropagation(); return this.toggle(t.getAttribute("data-lnav-trigger")) }
    }
    this.onOver = (e) => {
      if (!this.hover) return
      const t = e.target.closest("[data-lnav-trigger]")
      if (t) { clearTimeout(this.timer); this.open(t.getAttribute("data-lnav-trigger")) }
      else if (e.target.closest("[data-lnav-panel]")) clearTimeout(this.timer)
    }
    this.onOut = (e) => {
      if (!this.hover || this.current === null) return
      const to = e.relatedTarget
      if (to && (to.closest("[data-lnav-trigger]") || to.closest("[data-lnav-panel]"))) return
      clearTimeout(this.timer)
      this.timer = setTimeout(() => this.close(), 160)
    }
    this.onDoc = (e) => { if (this.current !== null && !el.contains(e.target)) this.close() }
    this.onKey = (e) => {
      if (e.key === "Escape" && this.current !== null) {
        const t = el.querySelector(`[data-lnav-trigger="${this.current}"]`)
        this.close(); t && t.focus()
        return
      }
      const trig = e.target.closest && e.target.closest("[data-lnav-trigger]")
      if (trig && e.key === "ArrowDown") {
        e.preventDefault(); const i = trig.getAttribute("data-lnav-trigger"); this.open(i); this.items(i)[0]?.focus()
        return
      }
      const panel = e.target.closest && e.target.closest("[data-lnav-panel]")
      if (panel && (e.key === "ArrowDown" || e.key === "ArrowUp")) {
        e.preventDefault()
        const items = this.items(panel.getAttribute("data-lnav-panel"))
        const i = items.indexOf(document.activeElement)
        items[(i + (e.key === "ArrowDown" ? 1 : -1) + items.length) % items.length]?.focus()
      }
    }
    this.onFocusOut = (e) => { if (this.current !== null && e.relatedTarget && !el.contains(e.relatedTarget)) this.close() }
    el.addEventListener("click", this.onClick)
    el.addEventListener("mouseover", this.onOver)
    el.addEventListener("mouseout", this.onOut)
    el.addEventListener("keydown", this.onKey)
    el.addEventListener("focusout", this.onFocusOut)
    document.addEventListener("click", this.onDoc)
  },
  destroyed() {
    const el = this.el
    el.removeEventListener("click", this.onClick)
    el.removeEventListener("mouseover", this.onOver)
    el.removeEventListener("mouseout", this.onOut)
    el.removeEventListener("keydown", this.onKey)
    el.removeEventListener("focusout", this.onFocusOut)
    window.removeEventListener("scroll", this.onScroll)
    if (this.spy) window.removeEventListener("resize", this.onScroll)
    if (this.autohide) el.removeEventListener("focusin", this.onFocusIn)
    document.removeEventListener("click", this.onDoc)
    clearTimeout(this.timer)
  },
  updated() {
    this.keepPanels()
    // a patch drops the attributes the server did not draw: put the client's back
    if (this.sticky && window.scrollY > this.after) this.el.setAttribute("data-stuck", "")
    if (this.autohide && this.hidden) this.el.setAttribute("data-hidden", "")
    if (this.spy) this.mark()
  },
  // The mega menu panels are opened by this hook (`style.display`): a patch leaves their style alone.
  keepPanels() {
    keep(this, this.el.querySelectorAll("[data-lnav-panel]"), ["style"])
  },
  slide(y) {
    const el = this.el
    if (y <= 0) { this.lastY = y; this.hidden = false; el.removeAttribute("data-hidden"); return }
    const dy = y - this.lastY
    if (Math.abs(dy) < 4) return // jitter: keep counting from the last real move
    this.lastY = y
    const hide = dy > 0 && y > el.offsetHeight && this.current === null && !el.contains(document.activeElement)
    this.hidden = hide
    el.toggleAttribute("data-hidden", hide)
  },
  mark() {
    const links = Array.from(this.el.querySelectorAll('a[href^="#"]'))
      .map((link) => ({link, target: this.section(link)}))
      .filter((x) => x.target)
    let current = null
    for (const {link, target} of links)
      if (target.getBoundingClientRect().top - this.spyOffset <= 1) current = link.getAttribute("href")
    const root = document.scrollingElement
    if (links.length && root && root.scrollTop > 0 && root.scrollTop + root.clientHeight >= root.scrollHeight - 2) {
      // the section that comes last in the page, whatever the order of the links
      const last = links.reduce((a, b) => (a.target.compareDocumentPosition(b.target) & Node.DOCUMENT_POSITION_FOLLOWING ? b : a))
      current = last.link.getAttribute("href")
    }
    for (const {link} of links) {
      if (link.getAttribute("href") === current) link.setAttribute("aria-current", "true")
      else if (link.getAttribute("aria-current") === "true") link.removeAttribute("aria-current")
    }
  },
  section(link) {
    const href = link.getAttribute("href") || ""
    if (href.length < 2) return null
    try { return document.getElementById(decodeURIComponent(href.slice(1))) } catch (_) { return null }
  },
  items(i) { const p = this.panel(i); return p ? Array.from(p.querySelectorAll(ITEMS)) : [] },
  toggle(i) { this.current === i ? this.close() : this.open(i) },
  open(i) {
    if (this.current === i) return
    this.close()
    const p = this.panel(i)
    const t = this.el.querySelector(`[data-lnav-trigger="${i}"]`)
    if (!p || !t) return
    p.style.display = "contents"
    const mega = p.firstElementChild
    if (mega) mega.style.left = `${Math.max(t.offsetLeft - 16, 0)}px`
    stickAttr(this, t, "aria-expanded", "true")
    this.current = i
  },
  close() {
    if (this.current === null) return
    const p = this.panel(this.current)
    if (p) p.style.display = "none"
    const t = this.el.querySelector(`[data-lnav-trigger="${this.current}"]`)
    if (t) stickAttr(this, t, "aria-expanded", "false")
    this.current = null
  },
}
