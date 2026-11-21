// Ledger UI static runtime (ES module, loaded from the page, no CDN, no bundler).
//
// There is no server, so the LiveView never joins. What it still does for us is the client half:
//   1. JS commands (phx-click="[[...]]" etc.) run through the REAL phoenix_live_view.js: a LiveSocket that
//      never connects, with a stub "main view", so `liveSocket.execJS(el, json)` works as in the app.
//   2. Hooks: every [phx-hook] is instantiated with the real ViewHook class (this.js(), this.liveSocket)
//      from the Hooks of ledger_ui.esm.js (+ window.ShowcaseHooks); pushEvent/handleEvent are no-ops.
//   3. The bindings LiveSocket would attach after connecting are re-created here: phx-click, phx-click-away,
//      phx-window-keydown/up, phx-keydown/up (+ phx-key), phx-focus/blur, phx-mounted.
// push is a no-op; navigate/patch become a plain page load of the exported file.
import {Hooks, DOM} from "./ledger_ui/ledger_ui.esm.js"

const LV = window.LiveView, Phoenix = window.Phoenix
const root = window.LU_ROOT || ""

const liveSocket = new LV.LiveSocket("/live", Phoenix.Socket, {
  hooks: {...Hooks, ...window.ShowcaseHooks},
  dom: {onBeforeElUpdated(from, to) { DOM.onBeforeElUpdated(from, to) }},
})
const noPush = () => Promise.resolve({})
const view = {
  liveSocket, id: "static", get el() { return document.body }, isDead: false,
  binding: (n) => "phx-" + n,
  isConnected: () => false, isDestroyed: () => false,
  transition: (time, onStart, onDone = () => {}) => liveSocket.transition(time, onStart, onDone),
  withinTargets() {}, pushHookEvent: noPush, pushEvent: noPush,
}
liveSocket.main = view          // owner(el) -> this.main: this is what makes execJS work without a mount
window.liveSocket = liveSocket

const ops = (json) => { try { return JSON.parse(json) } catch { return null } }
function run(el, json, type) {
  const cmds = ops(json)
  if (!Array.isArray(cmds)) return false                       // "some_event": server only, ignored
  const nav = cmds.filter(([k]) => k === "navigate" || k === "patch")
  if (nav.length) {
    const target = window.luStaticHref(nav[0][1].href)
    if (target) location.href = target
    return true
  }
  try { liveSocket.execJS(el, JSON.stringify(cmds.filter(([k]) => k !== "push")), type) }
  catch (e) { console.error("[static] JS command failed", e, json) }
  return true
}
const visible = (el) => !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length)
const keyOk = (el, e) => { const k = el.getAttribute("phx-key"); return !k || k.split(",").some((x) => x.toLowerCase() === e.key.toLowerCase() || x === e.code) }

// click + click-away
document.addEventListener("click", (e) => {
  const t = e.target
  const el = t.closest && t.closest("[phx-click]")
  if (el && !el.disabled) {
    if (run(el, el.getAttribute("phx-click"), "click") && el.getAttribute("href") === "#") e.preventDefault()
    else if (el.getAttribute("href") === "#") e.preventDefault()
  }
  document.querySelectorAll("[phx-click-away]").forEach((a) => {
    if (!a.contains(t) && visible(a)) run(a, a.getAttribute("phx-click-away"), "click")
  })
}, true)

// keys
for (const ev of ["keydown", "keyup"]) {
  window.addEventListener(ev, (e) => {
    document.querySelectorAll(`[phx-window-${ev}]`).forEach((el) => { if (keyOk(el, e)) run(el, el.getAttribute(`phx-window-${ev}`), ev) })
    const el = e.target.closest && e.target.closest(`[phx-${ev}]`)
    if (el && keyOk(el, e)) run(el, el.getAttribute(`phx-${ev}`), ev)
  })
}
// focus / blur
for (const ev of ["focus", "blur"]) {
  document.addEventListener(ev, (e) => {
    const el = e.target.closest && e.target.closest(`[phx-${ev}]`)
    if (el) run(el, el.getAttribute(`phx-${ev}`), ev)
  }, true)
}
// forms bound to the server must not reload the page
document.addEventListener("submit", (e) => { if (e.target.hasAttribute && e.target.hasAttribute("phx-submit")) { e.preventDefault(); run(e.target, e.target.getAttribute("phx-submit"), "submit") } }, true)

// hooks
const live = []
function mountHook(el) {
  if (el.__luHook) return
  el.__luHook = true
  const name = el.getAttribute("phx-hook")
  const def = liveSocket.getHookDefinition(name)
  if (!def) { console.warn("[static] unknown hook", name); return }
  if (!el.id) el.id = "static-hook-" + live.length
  const hook = new LV.ViewHook(view, el, def)
  hook.pushEvent = noPush; hook.pushEventTo = noPush
  hook.handleEvent = () => () => {}; hook.removeHandleEvent = () => {}
  hook.upload = () => {}; hook.uploadTo = () => {}
  live.push(hook)
  try { hook.mounted && hook.mounted() } catch (e) { console.error("[static] hook " + name + " failed to mount", e) }
}
// Mounts the hooks and runs the phx-mounted commands under `scope`; safe to call again (each element is handled once).
// The vitrine runs it at load; the design-system bundle (window.LU_DEFER set first) calls it itself.
export function start(scope = document) {
  scope.querySelectorAll("[phx-hook]").forEach(mountHook)
  scope.querySelectorAll("[phx-mounted]").forEach((el) => {
    if (el.__luMounted) return
    el.__luMounted = true
    run(el, el.getAttribute("phx-mounted"), "mounted")
  })
  document.documentElement.setAttribute("data-static", "")
}
export {liveSocket}
if (!window.LU_DEFER) start()
