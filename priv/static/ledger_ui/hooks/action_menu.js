// LedgerUI.ActionMenu: the Dropdown hook with the row marking on (`data-am-open` on the nearest
// [data-am-row], tr or .ledger-ctable-row while open). Kept as an alias for apps that registered
// it: `dropdown` with `row_mark` does the same through the plain Dropdown hook.
import Dropdown from "./dropdown.js"

export default {
  ...Dropdown,
  rowMark: true,
}
