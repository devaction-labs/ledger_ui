// LedgerUI.FabDial: speed-dial. Click toggles; Escape closes and returns focus to the button;
// with the dial open ArrowUp/ArrowDown walk the actions (wrapping), Home/End go to the ends;
// the arrows on the closed button open it; a click on an action, a click outside or focus
// leaving close it. data-state is preserved across patches by `keep-data-state`.
export default {
  mounted() {
    const el = this.el
    this.button = () => el.querySelector('[data-part="fab-dial-button"]')
    this.items = () =>
      Array.from(el.querySelectorAll('[role="menuitem"]:not([disabled]):not([aria-disabled="true"])'))
    this.isOpen = () => el.getAttribute("data-state") === "open"

    this.setOpen = (open) => {
      el.setAttribute("data-state", open ? "open" : "closed")
      this.button()?.setAttribute("aria-expanded", String(open))
    }

    // The server renders aria-controls, the menu id and tabindex="-1" on the actions (closed actions
    // are out of the tab order; open ones are reached with the arrows); the hook only flips aria-expanded.

    const focusItem = (items, i) => items[(i + items.length) % items.length]?.focus()

    this.onClick = (e) => {
      if (e.target.closest('[data-part="fab-dial-button"]')) this.setOpen(!this.isOpen())
      else if (e.target.closest('[role="menuitem"]')) this.setOpen(false)
    }

    this.onKeydown = (e) => {
      const items = this.items()
      const current = items.indexOf(document.activeElement)
      const onButton = document.activeElement === this.button()

      if (e.key === "Escape" && this.isOpen()) {
        e.preventDefault()
        this.setOpen(false)
        this.button()?.focus()
      } else if (e.key === "ArrowDown" || e.key === "ArrowUp") {
        e.preventDefault()
        const down = e.key === "ArrowDown"
        if (!this.isOpen()) this.setOpen(true)
        if (onButton || current < 0) focusItem(items, down ? 0 : items.length - 1)
        else focusItem(items, current + (down ? 1 : -1))
      } else if (this.isOpen() && (e.key === "Home" || e.key === "End")) {
        e.preventDefault()
        focusItem(items, e.key === "Home" ? 0 : items.length - 1)
      }
    }

    this.onOutside = (e) => {
      if (this.isOpen() && !el.contains(e.target)) this.setOpen(false)
    }

    this.onFocusout = (e) => {
      if (this.isOpen() && e.relatedTarget && !el.contains(e.relatedTarget)) this.setOpen(false)
    }

    el.addEventListener("click", this.onClick)
    el.addEventListener("keydown", this.onKeydown)
    el.addEventListener("focusout", this.onFocusout)
    document.addEventListener("pointerdown", this.onOutside)
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("keydown", this.onKeydown)
    this.el.removeEventListener("focusout", this.onFocusout)
    document.removeEventListener("pointerdown", this.onOutside)
  },
}
