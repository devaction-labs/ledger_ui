// LedgerUI.RightSidebar: a drawer from the right. Open state is the class `open` on the root
// (LedgerUI.open/close/toggle). Esc, the overlay and the close button close it. on_open / on_close
// (data-lu-on-open / data-lu-on-close, or data-on-open-js / data-on-close-js) fire on changes.
// persist_tab (data-lu-persist-tab) remembers the last clicked [data-tab] in sessionStorage.
const CSS_ID = "ledger-rs-css"
const CSS = `
.lu-rs.open{display:block!important;position:fixed;inset:0;z-index:60}
.lu-rs .lu-scrim{position:absolute;inset:0;background:var(--bg-overlay)}
.lu-rs-panel{position:absolute;top:0;right:0;bottom:0;width:min(360px,100vw);background:var(--bg-panel);border-left:1px solid var(--line);box-shadow:var(--shadow-lg);display:flex;flex-direction:column}
.lu-rs-top{display:flex;align-items:center;gap:8px;padding:12px 16px;border-bottom:1px solid var(--line)}
.lu-rs-body{flex:1;overflow:auto;padding:12px 0}
.lu-rs-foot{display:flex;justify-content:center;gap:6px;padding:10px;border-top:1px solid var(--line)}
`
const ensureCss = () => {
  if (document.getElementById(CSS_ID)) return
  const el = document.createElement("style")
  el.id = CSS_ID
  el.textContent = CSS
  document.head.appendChild(el)
}
const store = (k, v) => { try { v === undefined ? sessionStorage.removeItem(k) : sessionStorage.setItem(k, v) } catch (_) {} }
const load = (k) => { try { return sessionStorage.getItem(k) } catch (_) { return null } }

export default {
  mounted() {
    ensureCss()
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
    if (open) { const c = el.querySelector("[data-rs-close]:not(.lu-scrim)"); c && c.focus() }
  },
}
