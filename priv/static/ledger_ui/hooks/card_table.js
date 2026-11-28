// LedgerUI.CardTable: the details panel and the copy buttons of `card_table/1` (on the <tbody>, or on
// the <table> with `row_groups`, where each row sits in its own <tbody> with its panel row).
//   rows carry `data-ct-row`, `tabindex=0`, `aria-expanded`; the panel is the next `tr[data-part=table-panel-row]`.
//   data-lu-ct-copy      on a button: the text it copies (2s `data-copied` state, CSS swaps icon/tooltip)
//   data-lu-ct-toast     message shown (event "ledger:toast" on the page toaster, `**bold**`) after a copy
// A click on a row opens its panel at the click (16px to the left, 8px inside both sides of the
// row); a second click, Esc (focus back to the row), a click outside or on a control closes it.
// Enter/Space on a focused row toggles it at a fixed anchor (96px, 72px under 720px).
import {tableSelect, tableOf, viewportRows} from "../lib/table_select.js"

const CONTROLS = "a,button,input,select,textarea,label,summary,[role=menuitem],[role=button],[data-lu-ct-copy]"
const COPIED_MS = 2000

async function writeText(text) {
  if (navigator.clipboard && window.isSecureContext) return navigator.clipboard.writeText(text)
  const area = document.createElement("textarea")
  area.value = text
  area.setAttribute("readonly", "")
  area.style.cssText = "position:fixed;top:0;left:0;opacity:0"
  document.body.appendChild(area)
  area.select()
  const ok = document.execCommand("copy")
  area.remove()
  if (!ok) throw new Error("copy failed")
}

export default {
  mounted() {
    // with `row_groups` the hook sits on the <table>, which then also runs the optimistic selection (#73)
    // With `on_viewport_*` (#101) the LiveView takes the `<tbody>`/`<table>` that holds the stream
    // for its own hook, so this one sits on the `<table>` or on the `<thead>` of it: `root` is the
    // element that holds the rows either way.
    this.root = this.el.matches("table,tbody") ? this.el : tableOf(this.el)
    this.sel = this.root.dataset.luSelect != null ? tableSelect(this.root) : null
    this.vp = viewportRows(this.root)
    // a hook on the <thead> is not "updated" by the patches of the rows: watch them
    this.obs = null
    if (this.root !== this.el && typeof MutationObserver !== "undefined") {
      this.obs = new MutationObserver(() => this.reapply())
      this.obs.observe(this.root, {childList: true, subtree: true, attributes: true, attributeFilter: ["aria-expanded"]})
    }
    this.state = null
    this.timers = new Map()
    this.onClick = e => this.click(e)
    this.onKey = e => this.key(e)
    this.onDocClick = e => { if (this.state && !this.root.contains(e.target)) this.close(false) }
    this.onDocKey = e => { if (e.key === "Escape" && this.state) { e.preventDefault(); this.close(true) } }
    this.root.addEventListener("click", this.onClick)
    this.root.addEventListener("keydown", this.onKey)
    document.addEventListener("click", this.onDocClick)
    document.addEventListener("keydown", this.onDocKey)
  },

  updated() {
    if (this.sel) this.sel.sync()
    // A patch re-sends the server's `aria-expanded="false"`: put the open state back.
    const s = this.state
    if (!s) return
    const row = s.id ? document.getElementById(s.id) : s.row
    if (row && row.isConnected && this.panelOf(row)) this.apply(row, s)
    else this.state = null
  },

  // `updated` for a hook that is not on the element the patch touches: only when the state was lost
  reapply() {
    const s = this.state
    if (!s) return
    const row = s.id ? document.getElementById(s.id) : s.row
    if (row && row.isConnected && this.panelOf(row) && row.getAttribute("aria-expanded") !== "true") this.apply(row, s)
  },

  destroyed() {
    this.sel && this.sel.destroy()
    this.vp && this.vp.destroy()
    this.obs && this.obs.disconnect()
    this.root.removeEventListener("click", this.onClick)
    this.root.removeEventListener("keydown", this.onKey)
    document.removeEventListener("click", this.onDocClick)
    document.removeEventListener("keydown", this.onDocKey)
    this.timers.forEach(t => clearTimeout(t))
  },

  panelOf(row) {
    const p = row.nextElementSibling
    return p && p.dataset.part === "table-panel-row" ? p : null
  },

  click(e) {
    const copy = e.target.closest("[data-lu-ct-copy]")
    if (copy && this.root.contains(copy)) this.copy(copy)

    const inPanel = e.target.closest("[data-part=table-panel]")
    if (inPanel) return
    const row = e.target.closest("tr[data-ct-row]")
    if (!row || !this.owns(row)) return
    if (e.target.closest(CONTROLS) && e.target.closest(CONTROLS) !== row) {
      this.close(false)
      return
    }
    if (this.state && this.state.row === row) this.close(false)
    else this.open(row, e.clientX)
  },

  key(e) {
    const row = e.target
    if (!(row instanceof HTMLElement) || !row.matches("tr[data-ct-row]") || !this.owns(row)) return
    if (e.key === "Enter" || e.key === " ") {
      e.preventDefault()
      if (this.state && this.state.row === row) this.close(false)
      else this.open(row, null)
    }
  },

  // a row of this table: a child of the hook element (<tbody>), or of a <tbody> child of it (<table>)
  owns(row) {
    const g = row.parentNode
    return g === this.root || g.parentNode === this.root
  },

  rows() { return Array.from(this.root.querySelectorAll("tr[data-ct-row]")).filter(r => this.owns(r)) },

  open(row, clientX) {
    this.close(false)
    const panel = this.panelOf(row)
    if (!panel) return
    panel.hidden = false
    const box = panel.querySelector("[data-part=table-panel]")
    const visible = Array.from(panel.querySelectorAll("[data-part=table-panel-item]")).some(i => i.offsetParent !== null)
    if (!visible) { panel.hidden = true; return }
    const rect = row.getBoundingClientRect()
    let x = clientX == null ? (rect.width < 720 ? 72 : 96) : clientX - rect.left - 16
    x = Math.max(8, Math.min(x, rect.width - box.offsetWidth - 8))
    const rows = this.rows()
    const up = rows.indexOf(row) >= rows.length - 2
    this.state = {row, id: row.id || null, x, up, rh: row.offsetHeight}
    this.apply(row, this.state)
  },

  apply(row, s) {
    const panel = this.panelOf(row)
    s.row = row
    row.setAttribute("aria-expanded", "true")
    row.setAttribute("data-open", "")
    panel.hidden = false
    const box = panel.querySelector("[data-part=table-panel]")
    box.style.setProperty("--ct-x", s.x + "px")
    // under the row, or above it (`--ct-top`/`--ct-bottom` are read by the panel's utilities)
    if (s.up) {
      box.style.setProperty("--ct-top", "auto")
      box.style.setProperty("--ct-bottom", `calc(${s.rh}px + 2px)`)
    } else {
      box.style.removeProperty("--ct-top")
      box.style.removeProperty("--ct-bottom")
    }
  },

  close(focus) {
    const s = this.state
    if (!s) return
    this.state = null
    const row = s.id ? document.getElementById(s.id) || s.row : s.row
    row.setAttribute("aria-expanded", "false")
    row.removeAttribute("data-open")
    const panel = this.panelOf(row)
    if (panel) panel.hidden = true
    if (focus) row.focus()
  },

  // The contract of the `clipboard` hook: the toaster listens on its own element (`window` if the page has none).
  toast(message, kind) {
    if (!message) return
    const target = document.querySelector('[phx-hook="LedgerUI.Toaster"]') || window
    target.dispatchEvent(new CustomEvent("ledger:toast", {detail: {op: "show", message, kind}}))
  },

  async copy(btn) {
    const text = btn.getAttribute("data-lu-ct-copy")
    if (text == null) return
    try { await writeText(text) } catch (_e) { return }
    this.toast(btn.getAttribute("data-lu-ct-toast"), "success")
    btn.setAttribute("data-copied", "")
    clearTimeout(this.timers.get(btn))
    this.timers.set(btn, setTimeout(() => { btn.removeAttribute("data-copied"); this.timers.delete(btn) }, COPIED_MS))
  },
}
