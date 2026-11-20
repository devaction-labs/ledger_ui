// LedgerUI.MonochromeToggle: toggles `is-monochrome` on <body>, keeps it in
// localStorage["monochrome-mode"], and every toggle on the page follows (`ledger:monochrome`).
const KEY = "monochrome-mode"
const CSS_ID = "ledger-mono-css"
const read = () => { try { return localStorage.getItem(KEY) === "true" } catch (_) { return false } }

export default {
  mounted() {
    if (!document.getElementById(CSS_ID)) {
      const s = document.createElement("style")
      s.id = CSS_ID
      s.textContent = "body.is-monochrome{filter:grayscale(1)}"
      document.head.appendChild(s)
    }
    this.onClick = () => this.set(!document.body.classList.contains("is-monochrome"))
    this.onEvt = () => this.sync()
    this.el.addEventListener("click", this.onClick)
    window.addEventListener("ledger:monochrome", this.onEvt)
    document.body.classList.toggle("is-monochrome", read())
    this.sync()
  },
  updated() { this.sync() },
  destroyed() { window.removeEventListener("ledger:monochrome", this.onEvt) },
  set(on) {
    document.body.classList.toggle("is-monochrome", on)
    try { localStorage.setItem(KEY, String(on)) } catch (_) {}
    window.dispatchEvent(new CustomEvent("ledger:monochrome", {detail: {monochrome: on}}))
    const evt = this.el.getAttribute("phx-value-on-change")
    const js = this.el.getAttribute("data-on-change-js")
    if (evt) {
      const target = this.el.getAttribute("phx-value-target")
      const payload = {monochrome: on}
      target ? this.pushEventTo(target, evt, payload) : this.pushEvent(evt, payload)
    }
    if (js && this.liveSocket) this.liveSocket.execJS(this.el, js)
  },
  sync() {
    const on = document.body.classList.contains("is-monochrome")
    this.el.setAttribute("aria-pressed", String(on))
    if (this.el.getAttribute("phx-value-variant") === "switch") {
      this.el.classList.toggle("on", on)
      this.el.setAttribute("role", "switch")
      this.el.setAttribute("aria-checked", String(on))
      this.el.setAttribute("tabindex", "0")
    }
  },
}
