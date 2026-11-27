// Shared by the "ledger_ui" and "ledger_ui/core" entries: `DOM` plus the global listeners (error page,
// fullscreen, `phx:ledger:*` events). A bundle that imports both entries loads this module once.
import {scrollToSelector} from "./hooks/scroll_target.js"


// Delegated listeners of error_page/1 (back link, copy request id): work with no LiveSocket.
import "./error_page.js"

// Global listener of `lu:fullscreen` (the fullscreen button of navbar_cluster/1).
import "./fullscreen.js"

// Resyncs a form control's derived UI after LiveView patched it: hooks listen to `lu:sync`.
function resyncAfterPatch(el) {
  queueMicrotask(() => el.dispatchEvent(new CustomEvent("lu:sync", {bubbles: true})))
}

export const DOM = {
  // `keep-<attr>` on an element preserves that attribute across LiveView patches, e.g.
  // <div keep-data-state data-state="open">. (`keep-hidden`, `keep-style`, `keep-class`
  // are handled below.)
  copyDataAttributes(from, to) {
    for (const attr of Array.from(from.attributes)) {
      if (!attr.name.startsWith("keep-")) continue
      const name = attr.name.slice(5)
      if (name === "style" || name === "hidden" || name === "class") continue
      if (from.hasAttribute(name)) to.setAttribute(name, from.getAttribute(name))
    }
  },

  // Preserves client-managed state during LiveView DOM patches:
  // - `keep-hidden`: the `hidden` property
  // - `keep-style`: inline style (positioning, transforms)
  // - `keep-class`: className (animation classes)
  // Overlays (`[data-state]`, `.open`) keep their state automatically.
  onBeforeElUpdated(from, to) {
    if (from.hasAttribute("keep-hidden")) to.hidden = from.hidden
    if (from.hasAttribute("keep-style")) {
      if (from.hasAttribute("style")) to.style.cssText = from.style.cssText
      else to.removeAttribute("style")
    }
    if (from.hasAttribute("keep-class")) to.className = from.className
    else if (from.hasAttribute("data-lu-overlay")) {
      if (from.classList.contains("open")) to.classList.add("open")
      else to.classList.remove("open")
      const state = from.getAttribute("data-state")
      if (state !== null) to.setAttribute("data-state", state)
    }
    this.copyDataAttributes(from, to)
    if (/^(OPTION|SELECT|INPUT|TEXTAREA)$/.test(from.nodeName)) resyncAfterPatch(from)
  },
}

// Server-side LedgerUI.open(socket, id) / close(socket, id).
if (typeof window !== "undefined") {
  const toggleOpen = (id, on) => {
    const el = document.getElementById(id)
    if (!el) return
    el.classList.toggle("open", on)
    for (const t of document.querySelectorAll(`[aria-controls="${CSS.escape(id)}"]`))
      t.setAttribute("aria-expanded", String(on))
  }
  window.addEventListener("phx:ledger:open", (e) => toggleOpen(e.detail.id, true))
  window.addEventListener("phx:ledger:close", (e) => toggleOpen(e.detail.id, false))
  // LedgerUI.scroll_to(socket, selector, opts)
  window.addEventListener("phx:ledger:scroll", (e) => scrollToSelector(e.detail.selector, e.detail))
}

