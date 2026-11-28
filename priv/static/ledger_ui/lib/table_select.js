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
//
// `select_sync="client"` (#100): for a table over a stream, whose rows the server cannot re-render
// just to tick a box. The <table> then carries `data-lu-selected`, the JSON list of the selected
// ids (the `phx-value-id` of the boxes), and the rows are rendered unticked. The state of a box is
// that list, not its markup: `mounted`, `updated`, an inserted row and the end of a round trip put
// `checked`, `aria-selected` and the classes of every row from it. The `selected` value a box sends
// is set at the click, from the box itself, since the markup of a row does not know it.
// Limitation: "select all" assumes the rows of the page; rows the server selects off the page show
// up with the patch.
const ROW = "input[data-part=table-checkbox-input][phx-value-id]"
const HEAD = "thead input[data-part=table-checkbox-input]"

export function tableSelect(table) {
  let dirty = false
  let raw = null
  let serverSel = new Set()
  const client = () => table.dataset.luSelected != null
  const idOf = b => b.getAttribute("phx-value-id")
  // the selection the server last sent (client mode), parsed once per value
  const readServer = () => {
    const now = table.dataset.luSelected
    if (now === raw) return
    raw = now
    try { serverSel = new Set(JSON.parse(now).map(String)) } catch (_) { serverSel = new Set() }
  }
  // what the server says about a box: its markup, or the list of the table (client mode)
  const baseline = b => client() ? serverSel.has(idOf(b)) : b.defaultChecked
  const rows = () => [...table.querySelectorAll(ROW)]

  const paint = () => {
    readServer()
    const boxes = rows()
    const cls = (table.dataset.luSelClass || "").split(/\s+/).filter(Boolean)
    const ids = []
    let delta = 0
    for (const b of boxes) {
      const on = b.checked
      if (on) ids.push(idOf(b))
      if (on !== baseline(b)) delta += on ? 1 : -1
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
    readServer()
    if (dirty || client()) for (const b of rows()) { const want = baseline(b); if (b.checked !== want) b.checked = want }
    if (dirty) {
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
    // client mode: the markup of the box has no state to send, the box has (it is already toggled)
    if (client()) t.setAttribute("phx-value-selected", String(t.checked))
    paint()
  }

  const obs = new MutationObserver(list => {
    const relevant = list.some(m => m.type === "childList" || m.target === table || (m.target.matches && m.target.matches("input[data-part=table-checkbox-input]")))
    if (relevant) settle()
  })
  table.addEventListener("click", onClick)
  obs.observe(table, {subtree: true, childList: true, attributes: true, attributeFilter: ["class", "checked", "data-ind", "data-lu-selected"]})
  if (client()) settle()

  // `sync`: for the hook's `updated`, a patch can reset a box without leaving a mutation to see
  return {sync() { if (client()) settle() }, destroy() { table.removeEventListener("click", onClick); obs.disconnect() }}
}
