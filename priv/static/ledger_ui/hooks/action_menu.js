// LedgerUI.ActionMenu: the Dropdown hook plus the marking of the row the menu belongs to
// (`data-am-open` on the nearest [data-am-row], tr or .ledger-ctable-row) while it is open.
import Dropdown from "./dropdown.js"

const TINT = "color-mix(in srgb, var(--accent) 6%, var(--panel, var(--bg-panel)))"

export default {
  ...Dropdown,

  open(focus) {
    Dropdown.open.call(this, focus)
    if (!this.isOpen) return
    this.row = this.el.closest("[data-am-row],tr,.ledger-ctable-row")
    if (this.row) {
      this.row.setAttribute("data-am-open", "")
      this.rowBg = this.row.style.background
      this.row.style.background = TINT
    }
  },

  close(returnFocus, silent) {
    const wasOpen = this.isOpen
    Dropdown.close.call(this, returnFocus, silent)
    if (wasOpen && this.row) {
      this.row.removeAttribute("data-am-open")
      this.row.style.background = this.rowBg || ""
      this.row = null
    }
  },
}
