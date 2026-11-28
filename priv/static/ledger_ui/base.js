// Shared by the "ledger_ui" and "ledger_ui/core" entries: `DOM` plus the global listeners (error page,
// fullscreen, `phx:ledger:*` events). A bundle that imports both entries loads this module once.
import {scrollToSelector} from "./hooks/scroll_target.js"


// Delegated listeners of error_page/1 (back link, copy request id): work with no LiveSocket.
import "./error_page.js"

// Global listener of `lu:fullscreen` (the fullscreen button of navbar_cluster/1).
import "./fullscreen.js"

// Resyncs a form control's derived UI after LiveView patched it: hooks listen to `lu:sync`.
// One microtask per patch: the controls morphed in the same patch are queued in a Set and
// notified together (an element morphed twice is notified once). OPTION is not queued: its
// <select> is morphed in the same patch and notifies for it.
const pendingSync = new Set()

function resyncAfterPatch(el) {
  if (pendingSync.size === 0) queueMicrotask(flushSync)
  pendingSync.add(el)
}

function flushSync() {
  const els = Array.from(pendingSync)
  pendingSync.clear()
  for (const el of els) el.dispatchEvent(new CustomEvent("lu:sync", {bubbles: true}))
}

const isControl = (name) => name === "SELECT" || name === "INPUT" || name === "TEXTAREA"

// `keep-<attr>`: copies <attr> from the old element to the new one, except the three the patch
// handles itself. Walks the attributes by index (no array allocation) and skips at once any name
// that does not start with "k".
function copyKept(from, to) {
  const attrs = from.attributes
  for (let i = 0; i < attrs.length; i++) {
    const full = attrs[i].name
    if (full.charCodeAt(0) !== 107 || !full.startsWith("keep-")) continue
    const name = full.slice(5)
    if (name === "style" || name === "hidden" || name === "class") continue
    if (from.hasAttribute(name)) to.setAttribute(name, from.getAttribute(name))
  }
}

export const DOM = {
  // `keep-<attr>` on an element preserves that attribute across LiveView patches, e.g.
  // <div keep-data-state data-state="open">. (`keep-hidden`, `keep-style`, `keep-class`
  // are handled below.)
  copyDataAttributes(from, to) {
    copyKept(from, to)
  },

  // Preserves client-managed state during LiveView DOM patches:
  // - `keep-hidden`: the `hidden` property
  // - `keep-style`: inline style (positioning, transforms)
  // - `keep-class`: className (animation classes)
  // Overlays (`[data-state]`, `.open`) keep their state automatically.
  onBeforeElUpdated(from, to) {
    const name = from.nodeName
    if (from.attributes.length > 0) {
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
      copyKept(from, to)
    }
    if (isControl(name)) resyncAfterPatch(from)
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

