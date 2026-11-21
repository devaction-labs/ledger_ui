// Floating panels of the pickers (not a hook: lives outside hooks/).
//
// The panel (`<div popover="manual" hidden keep-hidden keep-style data-lu-placement="bottom-start">`)
// goes in the top layer (position: fixed) so no ancestor with `overflow` clips it, and is placed from
// the anchor's rectangle with the same `place` as the dropdown (flip + clamp to the window). Without
// the Popover API it is a fixed box. The `hidden` property stays the open/closed state the hooks use.
import {place} from "../hooks/dropdown.js"

const POPOVER = typeof HTMLElement !== "undefined" && "showPopover" in HTMLElement.prototype

// Opens `pop` next to `anchor()` (a function, so it is read again on every reposition) and follows
// the page (scroll, resize) until `floatHide`.
export function floatShow(hook, pop, anchor) {
  pop.hidden = false
  if (!pop.hasAttribute("popover")) return
  hook.fl = {pop, anchor}
  if (POPOVER && !pop.matches(":popover-open")) pop.showPopover()
  floatPlace(hook)
  if (hook.flOn) return
  hook.flOn = (e) => {
    if (e && e.target instanceof Node && pop.contains(e.target)) return
    cancelAnimationFrame(hook.flRaf)
    hook.flRaf = requestAnimationFrame(() => floatPlace(hook))
  }
  window.addEventListener("scroll", hook.flOn, true)
  window.addEventListener("resize", hook.flOn)
}

export function floatPlace(hook) {
  const fl = hook.fl
  if (!fl || fl.pop.hidden) return
  const el = fl.anchor()
  if (!el) return
  place(fl.pop, el.getBoundingClientRect(), fl.pop.getAttribute("data-lu-placement") || "bottom-start", 4)
}

export function floatHide(hook, pop) {
  pop.hidden = true
  if (hook.flOn) {
    window.removeEventListener("scroll", hook.flOn, true)
    window.removeEventListener("resize", hook.flOn)
    cancelAnimationFrame(hook.flRaf)
    hook.flOn = null
  }
  if (POPOVER && pop.hasAttribute("popover") && pop.matches(":popover-open")) pop.hidePopover()
}

// After a LiveView patch: an open panel stays in the top layer and is placed again.
export function floatSync(hook, pop) {
  if (!pop || pop.hidden || !pop.hasAttribute("popover")) return
  if (POPOVER && !pop.matches(":popover-open")) pop.showPopover()
  floatPlace(hook)
}

export function floatDestroy(hook) {
  if (!hook.flOn) return
  window.removeEventListener("scroll", hook.flOn, true)
  window.removeEventListener("resize", hook.flOn)
  cancelAnimationFrame(hook.flRaf)
  hook.flOn = null
}
