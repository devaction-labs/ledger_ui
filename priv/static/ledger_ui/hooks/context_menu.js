// LedgerUI.ContextMenu: opens the menu at the pointer on a right click.
// Reuses the placement and item helpers of the Dropdown hook.
import {place, items, typeahead, decorateMenu} from "./dropdown.js"

const POPOVER = typeof HTMLElement !== "undefined" && "showPopover" in HTMLElement.prototype

export default {
  mounted() {
    this.isOpen = false
    this.state = {}
    this.setup()
    this.onContext = (e) => {
      if (this.menu.contains(e.target)) return e.preventDefault()
      e.preventDefault()
      this.open(e.clientX, e.clientY)
    }
    this.onClick = (e) => {
      const item = e.target.closest('[role="menuitem"]')
      if (!item || !this.menu.contains(item)) return
      if (item.getAttribute("aria-disabled") === "true") {
        e.preventDefault()
        e.stopPropagation()
      } else this.close()
    }
    this.onKey = (e) => this.key(e)
    this.onDown = (e) => {
      if (this.isOpen && !this.menu.contains(e.target)) this.close()
    }
    this.onScroll = (e) => {
      if (this.isOpen && !this.menu.contains(e.target)) this.close()
    }
    this.el.addEventListener("contextmenu", this.onContext)
    this.menu.addEventListener("click", this.onClick)
    this.menu.addEventListener("keydown", this.onKey)
  },

  updated() {
    this.setup()
  },

  destroyed() {
    this.close(true)
    this.el.removeEventListener("contextmenu", this.onContext)
    this.menu && this.menu.removeEventListener("click", this.onClick)
    this.menu && this.menu.removeEventListener("keydown", this.onKey)
  },

  setup() {
    this.menu = this.el.querySelector(':scope > [role="menu"]')
    if (!this.menu) return
    decorateMenu(this.menu)
    const s = this.menu.style
    s.position = "fixed"
    s.margin = "0"
    s.zIndex = "var(--ledger-z-popover, 60)"
    if (POPOVER) {
      if (!this.isOpen && this.menu.matches(":popover-open")) this.menu.hidePopover()
    } else this.menu.hidden = !this.isOpen
  },

  open(x, y) {
    if (this.isOpen) this.close(true)
    this.restore = document.activeElement
    this.isOpen = true
    if (POPOVER) this.menu.showPopover()
    else this.menu.hidden = false
    place(this.menu, {left: x, right: x, top: y, bottom: y, width: 0, height: 0}, this.el.dataset.placement || "bottom-start", 0)
    document.addEventListener("pointerdown", this.onDown, true)
    window.addEventListener("scroll", this.onScroll, true)
    window.addEventListener("resize", this.onScroll)
    const first = items(this.menu)[0]
    if (first) first.focus()
  },

  close(silent) {
    if (!this.isOpen) return
    this.isOpen = false
    document.removeEventListener("pointerdown", this.onDown, true)
    window.removeEventListener("scroll", this.onScroll, true)
    window.removeEventListener("resize", this.onScroll)
    if (POPOVER) {
      if (this.menu.matches(":popover-open")) this.menu.hidePopover()
    } else this.menu.hidden = true
    if (!silent && this.restore && this.restore.isConnected) this.restore.focus()
  },

  key(e) {
    if (!this.isOpen) return
    // With no enabled item (all disabled) the arrows have nowhere to go: `list[NaN]` was undefined.
    const list = items(this.menu)
    const i = list.indexOf(document.activeElement)
    switch (e.key) {
      case "Escape":
        e.preventDefault()
        this.close()
        break
      case "Tab":
        this.close(true)
        break
      case "ArrowDown":
        e.preventDefault()
        list[(i + 1) % list.length]?.focus()
        break
      case "ArrowUp":
        e.preventDefault()
        list[(i - 1 + list.length) % list.length]?.focus()
        break
      case "Home":
        e.preventDefault()
        list[0]?.focus()
        break
      case "End":
        e.preventDefault()
        list[list.length - 1]?.focus()
        break
      default:
        if (e.key.length === 1 && !e.ctrlKey && !e.metaKey && !e.altKey)
          typeahead(this.state, this.menu, e.key, document.activeElement)
    }
  },
}
