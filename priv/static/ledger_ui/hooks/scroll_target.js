// LedgerUI.ScrollTarget: scrolls to [data-block="<target>"] once each time the target changes.
//   data-lu-target  value of data-block ("" or none: nothing)
//   data-lu-block   start | center | end | nearest (default nearest)
//   data-lu-scope   selector of the container searched (default: the document)
// `scrollToSelector` is also what the server event "ledger:scroll" (LedgerUI.scroll_to/3) runs.
const BLOCKS = ["start", "center", "end", "nearest"]

export function scrollToSelector(selector, {block = "nearest", scope = null} = {}) {
  if (!selector) return false
  let root = document
  if (scope) {
    try { root = document.querySelector(scope) } catch (_e) { root = null }
    if (!root) return false
  }
  let node
  try { node = root.querySelector(selector) } catch (_e) { return false }
  if (!node) return false
  const reduced = typeof window.matchMedia === "function" && window.matchMedia("(prefers-reduced-motion: reduce)").matches
  node.scrollIntoView({behavior: reduced ? "auto" : "smooth", block: BLOCKS.includes(block) ? block : "nearest"})
  return true
}

const quote = (s) => `"${String(s).replace(/["\\]/g, "\\$&")}"`

export default {
  mounted() {
    this.last = null
    this.sync()
  },

  updated() {
    this.sync()
  },

  sync() {
    const el = this.el
    const target = el.getAttribute("data-lu-target") || null
    if (target === this.last) return
    this.last = target
    if (target == null) return
    scrollToSelector(`[data-block=${quote(target)}]`, {
      block: el.getAttribute("data-lu-block") || "nearest",
      scope: el.getAttribute("data-lu-scope"),
    })
  },
}
