// Global listener of `lu:fullscreen`: dispatch it on any element (`JS.dispatch("lu:fullscreen")`) to
// toggle the browser fullscreen of the page. `detail.to` (a selector) fullscreens that element instead
// of `<html>`. Imported for its side effect by ledger_ui.esm.js. A browser without the Fullscreen API
// does nothing. The buttons marked `data-lu-fullscreen` (navbar_fullscreen/1) follow the state with
// `aria-pressed` (their icon is switched by CSS). The `fullscreenchange` listener exists only while
// the page is fullscreen: it takes itself off when the page leaves it (button, Esc or the browser).
export function syncFullscreen() {
  const on = !!document.fullscreenElement
  for (const b of document.querySelectorAll("[data-lu-fullscreen]")) b.setAttribute("aria-pressed", String(on))
  if (!on) document.removeEventListener("fullscreenchange", syncFullscreen)
}

export function onFullscreen(e) {
  if (document.fullscreenElement) return document.exitFullscreen?.()
  const to = e.detail && e.detail.to
  const target = (to && document.querySelector(to)) || document.documentElement
  const req = target.requestFullscreen?.()
  if (!req) return req
  document.addEventListener("fullscreenchange", syncFullscreen)
  return req.catch(() => document.removeEventListener("fullscreenchange", syncFullscreen))
}

if (typeof window !== "undefined") window.addEventListener("lu:fullscreen", onFullscreen)
