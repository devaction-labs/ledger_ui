// LedgerUI.Shell hook: the open state of the app frame (class mirror, persistence, on_toggle) in jsdom.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/shell_test.mjs
import {test} from "node:test"
import assert from "node:assert/strict"
import {createRequire} from "node:module"
import {pathToFileURL, fileURLToPath} from "node:url"
import {dirname, join} from "node:path"

const here = dirname(fileURLToPath(import.meta.url))
const require = createRequire(import.meta.url)

let JSDOM
for (const p of [process.env.JSDOM_PATH, "jsdom"].filter(Boolean)) {
  try { ({JSDOM} = require(p)); break } catch (_) { /* try the next */ }
}
const skip = JSDOM ? false : "jsdom not found (set JSDOM_PATH)"

let Shell, store
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/"})
  store = {}
  const matches = {value: true}
  dom.window.matchMedia = () => ({get matches() { return matches.value }, addEventListener() {}, removeEventListener() {}})
  Object.defineProperty(dom.window, "localStorage", {
    value: {getItem: (k) => (k in store ? store[k] : null), setItem: (k, v) => { store[k] = String(v) }},
  })
  Object.assign(globalThis, {
    window: dom.window, document: dom.window.document, MutationObserver: dom.window.MutationObserver,
    localStorage: dom.window.localStorage, requestAnimationFrame: (f) => f(),
  })
  Shell = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/shell.js")))).default
}

function mount(attrs, cls = "open is-sidebar-open") {
  document.body.innerHTML = `<div id="shell" class="${cls}" ${attrs}><button data-sidebar-toggle id="t"></button></div>`
  const el = document.getElementById("shell")
  const pushed = []
  const h = Object.assign(Object.create(Shell), {el, pushEvent: (e, p) => pushed.push([e, p]), pushEventTo: () => {}})
  h.mounted()
  return {el, h, pushed}
}

test("the toggle button closes the frame, mirrors the classes, persists and notifies", {skip}, () => {
  store = {}
  const {el, h, pushed} = mount('data-lu-layout="sidebar" data-lu-open="true" data-lu-persist="true" data-lu-on-toggle="side"')
  assert.equal(h.open, true)
  document.getElementById("t").click()
  assert.equal(h.open, false)
  assert.equal(el.classList.contains("is-sidebar-open"), false)
  assert.equal(el.classList.contains("open"), false)
  assert.deepEqual(pushed, [["side", {id: "shell", open: false}]])
  h.destroyed()
})

test("a saved choice wins at xl and persist=false ignores it", {skip}, () => {
  const stored = () => { try { return globalThis.localStorage.getItem("ledger-sidebar") } catch (_) { return null } }
  globalThis.localStorage.setItem("ledger-sidebar", "0")
  const a = mount('data-lu-layout="sidebar" data-lu-open="true" data-lu-persist="true"')
  assert.equal(a.h.open, false)
  a.h.destroyed()
  const b = mount('data-lu-layout="sidebar" data-lu-open="true" data-lu-persist="false"')
  assert.equal(b.h.open, true)
  b.h.destroyed()
  assert.equal(stored(), "0")
})

test("the preloader is faded out and the horizontal layout keeps its own state", {skip}, () => {
  document.body.innerHTML = `<div id="shell" data-lu-layout="horizontal" data-lu-open="false" data-lu-persist="true"><div data-preloader></div></div>`
  const el = document.getElementById("shell")
  const h = Object.assign(Object.create(Shell), {el, pushEvent() {}, pushEventTo() {}})
  h.mounted()
  assert.equal(h.open, false)
  assert.equal(el.querySelector("[data-preloader]").style.opacity, "0")
  h.destroyed()
})
