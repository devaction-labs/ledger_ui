import {floatShow, floatHide, floatSync, floatDestroy} from "../lib/popfloat.js"

// LedgerUI.AvatarMore: the "+N" popover of <.avatar_group hidden=...>. The list goes in the top layer
// (see lib/popfloat.js) so a card or table cell with `overflow` does not clip it.
// Root: `[data-part=avatar-more-wrap]` with the button (`aria-controls`) and the `[popover]` list.
export default {
  mounted() {
    this.onClick = (e) => {
      if (this.btn().contains(e.target)) this.isOpen() ? this.close() : this.open()
    }
    this.onDown = (e) => { if (this.isOpen() && !this.el.contains(e.target)) this.close() }
    this.onKey = (e) => {
      if (e.key === "Escape" && this.isOpen()) { e.stopPropagation(); this.close(); this.btn().focus() }
    }
    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("keydown", this.onKey)
    document.addEventListener("mousedown", this.onDown)
  },
  updated() { floatSync(this, this.pop()) },
  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("keydown", this.onKey)
    document.removeEventListener("mousedown", this.onDown)
    floatDestroy(this)
  },
  btn() { return this.el.querySelector("[data-part=avatar-more]") },
  pop() { return this.el.querySelector("[data-part=avatar-more-menu]") },
  isOpen() { return !this.pop().hidden },
  open() {
    floatShow(this, this.pop(), () => this.btn())
    this.btn().setAttribute("aria-expanded", "true")
  },
  close() {
    floatHide(this, this.pop())
    this.btn().setAttribute("aria-expanded", "false")
  },
}
