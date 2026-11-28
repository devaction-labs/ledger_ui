// overlay.js inside a <.portal> (#110): the wrapper `_lv_portal_wrap_<id>` that LiveView teleports to
// `body` holds the overlay; the hook finds everything from `this.el`, by id or by descendant, so
// opening, closing (Esc, click on the backdrop) and the focus work the same as in place.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/overlay_portal_test.mjs
// jsdom is not a dependency of the package: the tests are skipped when it cannot be found.
import {test} from "node:test"
import assert from "node:assert/strict"
import {createRequire} from "node:module"
import {readFileSync, writeFileSync, mkdtempSync} from "node:fs"
import {tmpdir} from "node:os"
import {join, dirname} from "node:path"
import {fileURLToPath, pathToFileURL} from "node:url"

const here = dirname(fileURLToPath(import.meta.url))
const require = createRequire(import.meta.url)

let JSDOM
for (const p of [process.env.JSDOM_PATH, "jsdom"].filter(Boolean)) {
  try { ({JSDOM} = require(p)); break } catch (_) { /* try the next */ }
}
const skip = JSDOM ? false : "jsdom not found (set JSDOM_PATH)"

let hook
let w
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "http://localhost/"})
  w = dom.window
  Object.assign(globalThis, {
    window: w, document: w.document, getComputedStyle: w.getComputedStyle.bind(w),
    MutationObserver: w.MutationObserver, MouseEvent: w.MouseEvent, CSS: {escape: (s) => s},
  })
  const dir = mkdtempSync(join(tmpdir(), "lu-overlay-"))
  writeFileSync(join(dir, "overlay.mjs"), readFileSync(join(here, "../../priv/static/ledger_ui/hooks/overlay.js"), "utf8"))
  hook = (await import(pathToFileURL(join(dir, "overlay.mjs")))).default
}

const OVERLAY = (id) =>
  `<div id="${id}" data-part="modal-overlay" data-lu-overlay data-lu-kind="modal" data-lu-lock-scroll="true" data-state="closed">` +
  `<div data-part="modal" role="dialog" tabindex="-1"><button id="${id}-ok" type="button">OK</button></div></div>`

let seq = 0
// `portal`: the overlay is inside the wrapper LiveView builds and moves to the end of `body`
function mount(portal) {
  document.body.innerHTML = '<main id="page"><button id="trigger" aria-controls="m' + (seq + 1) + '">Open</button></main>'
  const id = "m" + ++seq
  if (portal) {
    const wrap = document.createElement("div")
    wrap.id = "_lv_portal_wrap_" + id + "-portal"
    wrap.setAttribute("data-phx-teleported-src", id + "-portal")
    wrap.style.display = "contents"
    wrap.innerHTML = OVERLAY(id)
    document.body.append(wrap)
  } else {
    document.getElementById("page").insertAdjacentHTML("beforeend", OVERLAY(id))
  }
  const el = document.getElementById(id)
  const pushed = []
  const h = Object.assign(Object.create(hook), {el, pushed, pushEvent(e, p) { pushed.push([e, p]) }, pushEventTo() {}})
  h.mounted()
  return {h, el, id, pushed, open: () => { el.classList.add("open"); h.sync() }, close: () => { el.classList.remove("open"); h.sync() }}
}

for (const portal of [false, true]) {
  const where = portal ? "in a portal" : "in place"

  test(`${where}: opening sets the state, locks the scroll and focuses the card`, {skip}, () => {
    const t = mount(portal)
    assert.equal(t.el.getAttribute("data-state"), "closed")
    t.open()
    assert.equal(t.el.getAttribute("data-state"), "open")
    assert.equal(document.documentElement.style.overflow, "hidden")
    t.close()
    assert.equal(document.documentElement.style.overflow, "")
  })

  test(`${where}: Esc closes it`, {skip}, () => {
    const t = mount(portal)
    t.open()
    document.dispatchEvent(new w.KeyboardEvent("keydown", {key: "Escape", bubbles: true, cancelable: true}))
    assert.equal(t.el.classList.contains("open"), false)
  })

  test(`${where}: a click on the backdrop closes it, a click inside does not`, {skip}, () => {
    const t = mount(portal)
    t.open()
    document.getElementById(t.id + "-ok").dispatchEvent(new w.MouseEvent("click", {bubbles: true}))
    assert.equal(t.el.classList.contains("open"), true)
    t.el.dispatchEvent(new w.MouseEvent("click", {bubbles: true}))
    assert.equal(t.el.classList.contains("open"), false)
  })

  test(`${where}: the trigger found by aria-controls follows the state`, {skip}, () => {
    const t = mount(portal)
    t.open()
    assert.equal(document.getElementById("trigger").getAttribute("aria-expanded"), "true")
    t.close()
    assert.equal(document.getElementById("trigger").getAttribute("aria-expanded"), "false")
  })
}
