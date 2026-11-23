// Optimistic selection of a table (#73). `tableSelect(table)` listens on the <table> of `table/1` /
// `card_table/1` (it carries `data-lu-select`, and `data-lu-sel-class` with the classes the server puts
// on a selected row). On a click on a row checkbox or on the header one, at once, in the browser:
//   * the row gets `aria-selected` and the selected classes (what the server renders for it);
//   * the header checkbox gets `checked` / `indeterminate` from the rows of the page;
//   * a `lu:selection` CustomEvent (bubbles) goes up from the table with
//     `detail = {id, count, delta, ids}`: `count`/`ids` are the checked rows of the page,
//     `delta` is how many rows differ from what the server last rendered (+1 = one more checked).
//     `<.bulk_bar for="table-id">` reads `delta` (see bulk_bar.js).
// The event to the server (`on_select` / `on_select_all`) is sent as before, with the same payload.
//
// The server prevails. The server markup is the baseline: the `checked` attribute (`defaultChecked`)
// of every box. A patch that changes it also syncs the property (morphdom), so a confirmation is
// the same state the browser already shows (no flicker) and a different one replaces it. A patch
// that does not touch a row (the diff of #70, or a refusal that changes nothing) sends no markup:
// once every `phx-click-loading` of the table's boxes is gone (the server answered) the boxes go
// back to the baseline, so what stays on screen is what the server confirmed.
// Limitation: "select all" assumes the rows of the page; rows the server selects off the page show
// up with the patch.
const ROW = "input[data-part=table-checkbox-input][phx-value-id]"
const HEAD = "thead input[data-part=table-checkbox-input]"

export function tableSelect(table) {
  let dirty = false
  const rows = () => [...table.querySelectorAll(ROW)]

  const paint = () => {
    const boxes = rows()
    const cls = (table.dataset.luSelClass || "").split(/\s+/).filter(Boolean)
    const ids = []
    let delta = 0
    for (const b of boxes) {
      const on = b.checked
      if (on) ids.push(b.getAttribute("phx-value-id"))
      if (on !== b.defaultChecked) delta += on ? 1 : -1
      const tr = b.closest("tr")
      if (tr && tr.getAttribute("aria-selected") !== String(on)) {
        tr.setAttribute("aria-selected", String(on))
        for (const c of cls) tr.classList.toggle(c, on)
      }
    }
    const head = table.querySelector(HEAD)
    if (head && dirty) {
      const all = ids.length > 0 && ids.length === boxes.length
      head.checked = all
      head.indeterminate = ids.length > 0 && !all
    }
    table.dispatchEvent(new CustomEvent("lu:selection", {bubbles: true, detail: {id: table.id, count: ids.length, delta, ids}}))
  }

  // Back to the server's state, once no selection event of the table is in flight.
  const settle = () => {
    if (table.querySelector("input.phx-click-loading")) return
    if (dirty) {
      for (const b of rows()) b.checked = b.defaultChecked
      const head = table.querySelector(HEAD)
      if (head) {
        head.checked = head.defaultChecked
        head.indeterminate = head.dataset.ind === "1" && !head.checked
      }
      dirty = false
    }
    paint()
  }

  const onClick = e => {
    const t = e.target
    if (!t || !t.matches) return
    if (t.matches(ROW)) {
      dirty = true
    } else if (t.matches(HEAD)) {
      for (const b of rows()) b.checked = t.checked
      t.indeterminate = false
      dirty = true
    } else return
    paint()
  }

  const obs = new MutationObserver(list => {
    const relevant = list.some(m => m.type === "childList" || (m.target.matches && m.target.matches("input[data-part=table-checkbox-input]")))
    if (relevant) settle()
  })
  table.addEventListener("click", onClick)
  obs.observe(table, {subtree: true, childList: true, attributes: true, attributeFilter: ["class", "checked", "data-ind"]})

  return {destroy() { table.removeEventListener("click", onClick); obs.disconnect() }}
}
