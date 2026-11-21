// LedgerUI.Tabs: switches tabs in the browser (click, arrows, Home/End), no round trip.
//
// The server renders the ARIA (`role="tablist"`/`tab`/`tabpanel`, aria-selected, aria-controls, the
// roving tabindex, aria-orientation) and the `data-state="on"` attribute on the selected tab (ids are
// "<id>-tab-<name>", panels "<id>-panel-<name>"); the hook only updates aria-selected/tabindex/`data-state`
// as the selection changes (the tab utilities read it), shows the matching panel and reports the choice (`data-on-change`,
// `data-on-change-js`, `data-target`) and the bubbling `ledger:change` event.
//
// A choice made in the browser survives patches; when the server changes the selected tab the
// server wins.

export default {
  mounted() {
    this.onClick = (e) => {
      const tab = e.target.closest('[role="tab"]')
      if (!tab || !this.list.contains(tab) || tab.disabled) return
      this.select(tab, true)
    }
    this.onKey = (e) => this.key(e)
    this.list = this.findList()
    this.list.addEventListener("click", this.onClick)
    this.list.addEventListener("keydown", this.onKey)
    this.serverSel = this.selectedName()
    this.current = this.serverSel
    this.sync()
  },

  updated() {
    const list = this.findList()
    if (list !== this.list) {
      this.list.removeEventListener("click", this.onClick)
      this.list.removeEventListener("keydown", this.onKey)
      this.list = list
      this.list.addEventListener("click", this.onClick)
      this.list.addEventListener("keydown", this.onKey)
    }
    const fromServer = this.selectedName()
    if (fromServer !== this.serverSel) {
      this.serverSel = fromServer
      this.current = fromServer
    }
    this.sync()
  },

  destroyed() {
    this.list.removeEventListener("click", this.onClick)
    this.list.removeEventListener("keydown", this.onKey)
  },

  findList() {
    return this.el.matches('[role="tablist"]')
      ? this.el
      : this.el.querySelector('[role="tablist"]') || this.el
  },

  tabs() {
    return Array.from(this.list.querySelectorAll(':scope > [role="tab"]'))
  },

  prefix() {
    return `${this.el.id}-tab-`
  },

  nameOf(tab) {
    return tab.id.startsWith(this.prefix()) ? tab.id.slice(this.prefix().length) : tab.id
  },

  selectedName() {
    const tab = this.tabs().find((t) => t.getAttribute("data-state") === "on")
    return tab ? this.nameOf(tab) : null
  },

  panel(name) {
    return document.getElementById(`${this.el.id}-panel-${name}`)
  },

  // Paints `this.current` into the DOM (classes, ARIA, panels).
  sync() {
    const tabs = this.tabs()
    let current = this.current
    if (!tabs.some((t) => this.nameOf(t) === current)) current = tabs.length ? this.nameOf(tabs[0]) : null
    this.current = current
    for (const tab of tabs) {
      const name = this.nameOf(tab)
      const on = name === current
      if (on) tab.setAttribute("data-state", "on")
      else tab.removeAttribute("data-state")
      tab.setAttribute("aria-selected", String(on))
      tab.setAttribute("tabindex", on ? "0" : "-1")
      const panel = this.panel(name)
      if (panel) {
        tab.setAttribute("aria-controls", panel.id)
        panel.hidden = !on
      }
    }
  },

  select(tab, report) {
    const name = this.nameOf(tab)
    const changed = name !== this.current
    this.current = name
    this.sync()
    if (report && changed) this.report(name)
  },

  report(name) {
    const detail = {id: this.el.id, value: name, tab: name}
    this.el.dispatchEvent(new CustomEvent("ledger:change", {bubbles: true, detail}))
    const event = this.el.getAttribute("data-on-change")
    const js = this.el.getAttribute("data-on-change-js")
    const target = this.el.getAttribute("data-target")
    const payload = {id: detail.id, value: name, tab: name}
    if (event) target ? this.pushEventTo(target, event, payload) : this.pushEvent(event, payload)
    if (js) this.liveSocket.execJS(this.el, js)
  },

  key(e) {
    const vertical = this.list.getAttribute("aria-orientation") === "vertical"
    const prev = vertical ? "ArrowUp" : "ArrowLeft"
    const next = vertical ? "ArrowDown" : "ArrowRight"
    const tabs = this.tabs().filter((t) => !t.disabled)
    const i = tabs.indexOf(document.activeElement)
    let target = null
    if (e.key === next) target = tabs[(i + 1) % tabs.length]
    else if (e.key === prev) target = tabs[(i - 1 + tabs.length) % tabs.length]
    else if (e.key === "Home") target = tabs[0]
    else if (e.key === "End") target = tabs[tabs.length - 1]
    if (!target || i < 0) return
    e.preventDefault()
    target.focus()
    this.select(target, true)
  },
}
