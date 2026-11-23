// LedgerUI.BulkBar: the optimistic side of `<.bulk_bar for="table-id">` (#73). The table's hook
// (lib/table_select.js) dispatches `lu:selection` with `detail = {id, delta, ...}`; when `id` is the
// bar's `for`, the bar shows `count + delta` (`count` = `data-lu-count`, the server's number, which
// the bar never rewrites) at once: it appears (the `hidden` attribute and `data-lu-empty` go) and its
// count text follows (`data-lu-one` / `data-lu-many`: the labels). A server patch brings its own
// count and `delta` goes back to 0 when the table settles, so the bar always ends on the server's
// state; when the server confirms the number already shown the text is not touched.
export default {
  mounted() {
    this.delta = 0
    this.onSel = e => {
      const d = e.detail
      if (d && d.id === this.el.dataset.luFor) { this.delta = d.delta | 0; this.paint() }
    }
    document.addEventListener("lu:selection", this.onSel)
  },
  updated() { this.paint() },
  destroyed() { document.removeEventListener("lu:selection", this.onSel) },
  paint() {
    const el = this.el
    const n = Math.max(0, (parseInt(el.dataset.luCount, 10) || 0) + this.delta)
    const empty = n <= 0
    if (el.hasAttribute("hidden") !== empty) el.toggleAttribute("hidden", empty)
    if (el.hasAttribute("data-lu-empty") !== empty) el.toggleAttribute("data-lu-empty", empty)
    if (empty || el.querySelector("[data-part=bulk-bar-progress]")) return
    const text = `${n} ${(n === 1 ? el.dataset.luOne : el.dataset.luMany) || ""}`
    const b = el.querySelector("[data-part=bulk-bar-count]")
    if (b && b.textContent !== text) b.textContent = text
    if (el.hasAttribute("aria-label") && el.getAttribute("aria-label") !== text) el.setAttribute("aria-label", text)
  }
}
