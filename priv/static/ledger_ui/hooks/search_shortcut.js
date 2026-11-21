// LedgerUI.SearchShortcut: a key that focuses the search field of the box it sits on.
//   data-lu-shortcut  a combination as in LedgerUI.Hotkey ("/", "Mod+k")
// Ignored while the focus is in another field, and with modifiers the combination does not name.
// Esc inside the field blurs it. With several boxes on the page the first visible one answers.
import {parseKeys, matches, FIELD} from "./hotkey.js"

const visible = (el) => el.isConnected && (el.getClientRects().length > 0 || el.offsetParent !== null)

export default {
  mounted() {
    this.parsed = null
    this.parsedFrom = null
    this.onKey = (e) => {
      const el = this.el
      const input = el.querySelector("[data-part=input-control]")
      if (!input) return
      if (e.key === "Escape" && e.target === input) { input.blur(); return }
      const spec = el.getAttribute("data-lu-shortcut")
      if (spec !== this.parsedFrom) { this.parsed = parseKeys(spec); this.parsedFrom = spec }
      if (!this.parsed.some((c) => matches(c, e))) return
      if (e.target?.closest?.(FIELD)) return
      const first = [...document.querySelectorAll("[data-lu-shortcut]")].find(visible)
      if (first !== el || input.disabled) return
      e.preventDefault()
      input.focus()
    }
    document.addEventListener("keydown", this.onKey)
  },

  destroyed() {
    document.removeEventListener("keydown", this.onKey)
  },
}
