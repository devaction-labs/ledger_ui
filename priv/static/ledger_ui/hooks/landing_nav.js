// LedgerUI.LandingNav: sticky state (data-stuck after data-lu-stuck-after px) and the mega menu
// panels. open-on="hover" opens a panel when the pointer rests on its trigger, keeps it open while the
// pointer is in the trigger or the panel and closes after it leaves both; a click or tap opens too.
// Escape, a click outside and tabbing out close it; ArrowDown on a trigger opens and focuses the first
// item, arrows walk the items, Escape gives the focus back to the trigger.
const CSS_ID = "ledger-lnav-css"
const CSS = `
.lu-lnav{position:relative}
.lu-lnav[data-stuck]{background:var(--bg-panel);border-bottom:1px solid var(--line);box-shadow:var(--shadow-md)}
.lu-lnav .ham{cursor:pointer;display:none}
.lu-lnav[data-responsive] .ham{display:inline-grid}
.lu-lnav.mobile .ham{display:inline-grid}
@media (min-width:768px){.lu-lnav[data-responsive]:not(.mobile) .ham,.lu-lnav-mobile{display:none!important}}
@media (max-width:767px){.lu-lnav[data-responsive]:not(.mobile)>a,.lu-lnav[data-responsive]:not(.mobile)>button:not(.lu-lnav-mobile *),.lu-lnav[data-responsive]:not(.mobile)>[data-lnav-trigger],.lu-lnav[data-responsive]>[data-lnav-panel]{display:none!important}.lu-lnav[data-responsive] .ham{margin-left:auto}}
`
const ensureCss = () => {
  if (document.getElementById(CSS_ID)) return
  const el = document.createElement("style")
  el.id = CSS_ID
  el.textContent = CSS
  document.head.appendChild(el)
}
const ITEMS = "a[href],button:not([disabled])"

export default {
  mounted() {
    ensureCss()
    const el = this.el
    this.hover = el.getAttribute("data-lu-open-on") !== "click"
    this.after = parseInt(el.getAttribute("data-lu-stuck-after") || "8", 10)
    this.sticky = el.hasAttribute("data-lu-sticky")
    this.current = null
    this.timer = null
    this.triggers = () => Array.from(el.querySelectorAll("[data-lnav-trigger]"))
    this.panel = (i) => el.querySelector(`[data-lnav-panel="${i}"]`)

    this.onScroll = () => el.toggleAttribute("data-stuck", this.sticky && window.scrollY > this.after)
    if (this.sticky) { window.addEventListener("scroll", this.onScroll, {passive: true}); this.onScroll() }

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
    window.removeEventListener("scroll", this.onScroll)
    document.removeEventListener("click", this.onDoc)
    clearTimeout(this.timer)
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
    t.setAttribute("aria-expanded", "true")
    this.current = i
  },
  close() {
    if (this.current === null) return
    const p = this.panel(this.current)
    if (p) p.style.display = "none"
    const t = this.el.querySelector(`[data-lnav-trigger="${this.current}"]`)
    if (t) t.setAttribute("aria-expanded", "false")
    this.current = null
  },
}
