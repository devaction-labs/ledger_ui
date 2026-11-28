// LedgerUI.TableSelect: optimistic selection of `table/1` with `on_select` / `on_select_all` (#73);
// see the lib module. With `row_groups` and details/copy the `<table>` has the CardTable
// hook, which runs the same code.
import {tableSelect} from "../lib/table_select.js"

export default {
  mounted() { this.sel = tableSelect(this.el) },
  updated() { this.sel && this.sel.sync() },
  destroyed() { this.sel && this.sel.destroy() }
}
