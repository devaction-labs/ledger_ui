// LedgerUI.AppShell: the page frame. Keeps the sidebar open state (`open` + `is-sidebar-open`
// classes on the root), persists it at xl and up (localStorage["ledger-sidebar"]), closes it below
// xl, tells the server through on_toggle (an event name in data-lu-on-toggle or a JS command in
// data-on-toggle-js). The styles of the shell parts are Tailwind utilities in the components.
const KEY = "ledger-sidebar"
const read = (k) => { try { return localStorage.getItem(k) } catch (_) { return null } }
const write = (k, v) => { try { localStorage.setItem(k, v) } catch (_) {} }
const xl = () => window.matchMedia("(min-width: 1280px)").matches

export default {
  mounted() {
    const el = this.el
    this.serverOpen = el.getAttribute("data-lu-open") === "true"
    this.open = el.classList.contains("open")
    const sidebarLayout = ["sidebar", "minimal", "sideblock"].includes(el.getAttribute("data-lu-layout"))
    this.persist = el.getAttribute("data-lu-persist") !== "false"
    if (sidebarLayout) {
      const saved = this.persist ? read(KEY) : null
      if (!xl()) this.open = false
      else if (saved === "0" || saved === "1") this.open = saved === "1"
    }
    this.onClick = (e) => {
      if (e.target.closest("[data-sidebar-toggle]")) this.set(!this.open, true)
    }
    this.observer = new MutationObserver(() => {
      const has = el.classList.contains("open")
      if (has !== this.open) this.set(has, false)
      else this.mirror()
    })
    this.mq = window.matchMedia("(min-width: 1280px)")
    this.onMq = () => { if (!this.mq.matches && this.open) this.set(false, false) }
    this.mq.addEventListener("change", this.onMq)
    el.addEventListener("click", this.onClick)
    this.mirror()
    this.observer.observe(el, {attributes: true, attributeFilter: ["class"]})
    const pre = el.querySelector("[data-preloader]")
    if (pre) { pre.style.transition = "opacity .3s"; requestAnimationFrame(() => { pre.style.opacity = 0; setTimeout(() => pre.remove(), 320) }) }
    if (this.open !== this.serverOpen) this.notify()
  },
  updated() {
    const now = this.el.getAttribute("data-lu-open") === "true"
    if (now !== this.serverOpen) { this.serverOpen = now; this.open = now }
    this.mirror()
  },
  destroyed() {
    this.observer && this.observer.disconnect()
    this.mq && this.mq.removeEventListener("change", this.onMq)
  },
  mirror() {
    this.observer && this.observer.disconnect()
    this.el.classList.toggle("open", this.open)
    this.el.classList.toggle("is-sidebar-open", this.open)
    this.observer && this.observer.observe(this.el, {attributes: true, attributeFilter: ["class"]})
  },
  set(v, user) {
    this.open = v
    this.mirror()
    if (user && this.persist && xl()) write(KEY, v ? "1" : "0")
    this.notify()
  },
  notify() {
    const el = this.el
    const evt = el.getAttribute("data-lu-on-toggle")
    const js = el.getAttribute("data-on-toggle-js")
    if (evt) {
      const payload = {id: el.id, open: this.open}
      const target = el.getAttribute("data-lu-target")
      target ? this.pushEventTo(target, evt, payload) : this.pushEvent(evt, payload)
    }
    if (js && this.liveSocket) this.liveSocket.execJS(el, js)
  },
}
