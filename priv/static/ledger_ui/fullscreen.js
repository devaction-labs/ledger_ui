// Global listener of `lu:fullscreen`: dispatch it on any element (`JS.dispatch("lu:fullscreen")`) to
// toggle the browser fullscreen of the page. `detail.to` (a selector) fullscreens that element instead
// of `<html>`. Imported for its side effect by ledger_ui.esm.js. A browser without the Fullscreen API
// does nothing.
export function onFullscreen(e) {
  if (document.fullscreenElement) return document.exitFullscreen?.()
  const to = e.detail && e.detail.to
  const target = (to && document.querySelector(to)) || document.documentElement
  return target.requestFullscreen?.()?.catch(() => {})
}

if (typeof window !== "undefined") window.addEventListener("lu:fullscreen", onFullscreen)
