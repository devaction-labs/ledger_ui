// LedgerUI.TableSelect: optimistic selection of `table/1` with `on_select` / `on_select_all` (#73);
// see the lib module. With `row_groups` and details/copy the `<table>` has the CardTable
// hook, which runs the same code. With `on_viewport_*` (#101) the hook also sits here when
// there is no selection (the `<table>`, or the `<thead>` with `row_groups`), to keep the rows as
// the last child the LiveView's infinite scroll sees.
import {tableSelect, tableOf, viewportRows} from "../lib/table_select.js"

export default {
  mounted() {
    this.table = tableOf(this.el)
    this.sel = this.table.dataset.luSelect != null ? tableSelect(this.table) : null
    this.vp = viewportRows(this.table)
  },
  updated() { this.sel && this.sel.sync() },
  destroyed() { this.sel && this.sel.destroy(); this.vp && this.vp.destroy() }
}
