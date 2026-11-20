// LedgerUI.ThemePicker: a named palette (grid of previews or menu).
// Puts the id on <html data-palette>, stores it in localStorage["ledger-theme"], marks the option and
// follows the `ledger:palette` window event. Options are the elements with `data-lu-theme`.
// Config comes in data-lu-on-change (pushed with {theme: id}) and data-lu-target.
const KEY = "ledger-theme"
const CHECK = '<svg class="lu-i sm" viewBox="0 0 24 24" aria-hidden="true" data-icon="check"><path d="M5 14L8.5 17.5L19 6.5"/></svg>'

export default {
  mounted() {
    this.variant = this.el.getAttribute("data-lu-variant") || "menu"
    this.onClick = (e) => {
      const opt = e.target.closest("[data-lu-theme]")
      if (!opt || !this.el.contains(opt)) return
      this.choose(opt.getAttribute("data-lu-theme"))
      if (this.variant === "menu") this.el.querySelector(".lu-pop").hidden = true
    }
    this.onKey = (e) => {
      if (e.key === "Escape" && this.variant === "menu") this.el.querySelector(".lu-pop").hidden = true
    }
    this.onPalette = () => this.sync()
    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("keydown", this.onKey)
    window.addEventListener("ledger:palette", this.onPalette)
    const current = this.current()
    if (current) document.documentElement.setAttribute("data-palette", current)
    this.sync()
  },
  updated() { this.sync() },
  destroyed() { window.removeEventListener("ledger:palette", this.onPalette) },
  options() { return Array.from(this.el.querySelectorAll("[data-lu-theme]")) },
  current() {
    try { return localStorage.getItem(KEY) || document.documentElement.getAttribute("data-palette") } catch (_) { return document.documentElement.getAttribute("data-palette") }
  },
  choose(id) {
    try { localStorage.setItem(KEY, id) } catch (_) {}
    document.documentElement.setAttribute("data-palette", id)
    window.dispatchEvent(new CustomEvent("ledger:palette", {detail: {theme: id}}))
    const evt = this.el.getAttribute("data-lu-on-change")
    if (evt) {
      const target = this.el.getAttribute("data-lu-target")
      target ? this.pushEventTo(target, evt, {theme: id}) : this.pushEvent(evt, {theme: id})
    }
  },
  sync() {
    const id = this.current()
    const grid = this.variant === "grid"
    this.el.setAttribute("role", grid ? "radiogroup" : "group")
    if (grid) this.el.setAttribute("aria-label", this.el.getAttribute("data-lu-label") || "Theme")
    for (const opt of this.options()) {
      const on = opt.getAttribute("data-lu-theme") === id
      opt.classList.toggle("on", grid && on)
      opt.classList.toggle("sel", !grid && on)
      opt.setAttribute("role", grid ? "radio" : "menuitemradio")
      opt.setAttribute("aria-checked", String(on))
      if (grid) opt.setAttribute("tabindex", on ? "0" : "-1")
      const host = grid ? opt.querySelector(".nm") : opt
      const has = host.querySelector('[data-icon="check"]')
      if (on && !has) host.insertAdjacentHTML("beforeend", grid ? CHECK : `<span class="r">${CHECK.replace('class="lu-i sm"', 'class="lu-i sm ck"')}</span>`)
      if (!on && has) (grid ? has : has.closest(".r") || has).remove()
    }
  },
}
