// LedgerUI.RightSidebar: a drawer from the right. Open state is the class `open` on the root
// (LedgerUI.open/close/toggle). Esc, the overlay and the close button close it. on_open / on_close
// (data-lu-on-open / data-lu-on-close, or data-on-open-js / data-on-close-js) fire on changes.
// persist_tab (data-lu-persist-tab) remembers the last clicked [data-tab] in sessionStorage.
const store = (k, v) => { try { v === undefined ? sessionStorage.removeItem(k) : sessionStorage.setItem(k, v) } catch (_) {} }
const load = (k) => { try { return sessionStorage.getItem(k) } catch (_) { return null } }

export default {
  mounted() {
    const el = this.el
    this.was = el.classList.contains("open")
    this.key = `ledger-rs-tab:${el.id}`
    this.onClick = (e) => {
      if (e.target.closest("[data-rs-close]")) el.classList.remove("open")
      const tab = e.target.closest("[data-tab]")
      if (tab && el.getAttribute("data-lu-persist-tab")) store(this.key, tab.getAttribute("data-tab"))
    }
    this.onKey = (e) => { if (e.key === "Escape" && el.classList.contains("open")) el.classList.remove("open") }
    this.observer = new MutationObserver(() => this.changed())
    el.addEventListener("click", this.onClick)
    window.addEventListener("keydown", this.onKey)
    this.observer.observe(el, {attributes: true, attributeFilter: ["class"]})
    if (el.getAttribute("data-lu-persist-tab")) {
      const saved = load(this.key)
      const btn = saved && el.querySelector(`[data-tab="${CSS.escape(saved)}"]`)
      if (btn) btn.click()
    }
    this.changed()
  },
  destroyed() {
    this.observer && this.observer.disconnect()
    window.removeEventListener("keydown", this.onKey)
  },
  changed() {
    const el = this.el
    const open = el.classList.contains("open")
    for (const t of document.querySelectorAll(`[aria-controls="${CSS.escape(el.id)}"]`)) t.setAttribute("aria-expanded", String(open))
    if (open === this.was) return
    this.was = open
    const name = open ? "on-open" : "on-close"
    const evt = el.getAttribute(`data-lu-${name}`)
    const js = el.getAttribute(`data-${name}-js`)
    if (evt) {
      const target = el.getAttribute("data-lu-target")
      target ? this.pushEventTo(target, evt, {id: el.id}) : this.pushEvent(evt, {id: el.id})
    }
    if (js && this.liveSocket) this.liveSocket.execJS(el, js)
    if (open) { const c = el.querySelector("[data-rs-close]:not([data-part=right-sidebar-scrim])"); c && c.focus() }
  },
}
