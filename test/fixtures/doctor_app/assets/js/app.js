import {Socket} from "phoenix"
import {Hooks as LedgerHooks, DOM as LedgerDOM} from "ledger_ui"

const liveSocket = new LiveSocket("/live", Socket, {hooks: {...LedgerHooks}})
