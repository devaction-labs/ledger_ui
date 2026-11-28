// Shared by the "ledger_ui" and "ledger_ui/core" entries: `DOM` plus the global listeners (error page,
// fullscreen, `phx:ledger:*` events). A bundle that imports both entries loads this module once.
import {scrollToSelector} from "./hooks/scroll_target.js"


// Delegated listeners of error_page/1 (back link, copy request id): work with no LiveSocket.
import "./error_page.js"

// Global listener of `lu:fullscreen` (the fullscreen button of navbar_cluster/1).
import "./fullscreen.js"

export const DOM = {
  // Legacy, kept so an `app.js` that still installs it (`dom: {onBeforeElUpdated}`) keeps working.
  // Both are no-ops: the hooks keep what the client decided with the LiveView 1.2 API (`ignoreAttributes`
  // and the sticky `setAttribute`/`addClass`, see lib/keep.js) and resync their own `updated()`, so the old
  // `keep-*` attributes, `data-lu-overlay` and the `lu:sync` event are gone: with or without the callback,
  // nothing is lost and nothing is notified twice.
  copyDataAttributes() {},

  onBeforeElUpdated() {},
}

// Server-side LedgerUI.open(socket, id) / close(socket, id): the event carries the JS command
// (`Phoenix.LiveView.JS.to_encodable/1`), run with `liveSocket.execJS`, so the class `open` and the
// triggers' `aria-expanded` are sticky like any `JS.*` command (a patch leaves them).
if (typeof window !== "undefined") {
  const toggleOpen = (id, on) => {
    const el = document.getElementById(id)
    if (!el) return
    el.classList.toggle("open", on)
    for (const t of document.querySelectorAll(`[aria-controls="${CSS.escape(id)}"]`))
      t.setAttribute("aria-expanded", String(on))
  }
  window.addEventListener("phx:ledger:js", (e) => {
    const {id, js, open} = e.detail || {}
    const el = document.getElementById(id)
    if (!el) return
    const ls = window.liveSocket
    if (ls && typeof ls.execJS === "function" && js) ls.execJS(el, js)
    else toggleOpen(id, open !== false)
  })
  // The events of the earlier versions (a server that is not updated yet).
  window.addEventListener("phx:ledger:open", (e) => toggleOpen(e.detail.id, true))
  window.addEventListener("phx:ledger:close", (e) => toggleOpen(e.detail.id, false))
  // LedgerUI.scroll_to(socket, selector, opts)
  window.addEventListener("phx:ledger:scroll", (e) => scrollToSelector(e.detail.selector, e.detail))
}
