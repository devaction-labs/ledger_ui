// CodeBlock: the copy button ([data-lu-copy]) copies its attribute to the clipboard and shows
// "done" for a moment. One delegated listener on the block.
export default {
  mounted() {
    this.timers = new Set()
    this.onClick = (e) => {
      const btn = e.target.closest("[data-lu-copy]")
      if (!btn || !this.el.contains(btn)) return
      const text = btn.getAttribute("data-lu-copy") || ""
      if (navigator.clipboard) navigator.clipboard.writeText(text).catch(() => {})
      const label = btn.querySelector(".lu-copy-label")
      const old = label ? label.textContent : null
      btn.classList.add("done")
      if (label) label.textContent = btn.dataset.copied || "✓"
      const t = setTimeout(() => {
        this.timers.delete(t)
        btn.classList.remove("done")
        if (label && old !== null) label.textContent = old
      }, 1400)
      this.timers.add(t)
    }
    this.el.addEventListener("click", this.onClick)
  },
  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    this.timers.forEach(clearTimeout)
  },
}
