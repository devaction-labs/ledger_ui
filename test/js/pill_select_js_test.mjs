// pill_select `on_change` (#119): an event name is pushed with the value, a `%JS{}` (its JSON starts with `[`) is run.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/pill_select_js_test.mjs
// jsdom is not a dependency of the package: the tests are skipped when it cannot be found.
import {test} from "node:test"
import assert from "node:assert/strict"
import {createRequire} from "node:module"
import {join, dirname} from "node:path"
import {fileURLToPath, pathToFileURL} from "node:url"

const here = dirname(fileURLToPath(import.meta.url))
const require = createRequire(import.meta.url)

let JSDOM
for (const p of [process.env.JSDOM_PATH, "jsdom"].filter(Boolean)) {
  try { ({JSDOM} = require(p)); break } catch (_) { /* try the next */ }
}
const skip = JSDOM ? false : "jsdom not found (set JSDOM_PATH)"

let pill
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true})
  const w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, Event: w.Event})
  pill = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/pill_select.js")))).default
}

function mount(onChange, {viaJs = true} = {}) {
  document.body.innerHTML = ""
  const el = document.createElement("div")
  el.id = "p1"
  el.dataset.luOnChange = onChange
  el.innerHTML = `<button type="button" data-lu-toggle data-lu-value="a" aria-pressed="false">A</button><button type="button" data-lu-toggle data-lu-value="b" aria-pressed="false">B</button>`
  document.body.appendChild(el)
  const calls = {push: [], js: [], liveSocket: []}
  const h = Object.assign(Object.create(pill), {
    el,
    pushEvent: (ev, p) => calls.push.push({ev, p}),
    pushEventTo: (t, ev, p) => calls.push.push({t, ev, p}),
  })
  if (viaJs) h.js = () => ({exec: (j) => calls.js.push(j)})
  else h.liveSocket = {execJS: (e, j) => calls.liveSocket.push({e, j})}
  h.mounted()
  return {el, h, calls}
}

const click = (el, v) => el.querySelector(`[data-lu-value="${v}"]`).dispatchEvent(new window.Event("click", {bubbles: true}))

test("an event name is pushed with the id and the value", {skip}, () => {
  const {el, calls} = mount("chosen")
  click(el, "b")
  assert.deepEqual(calls.push, [{ev: "chosen", p: {id: "p1", value: "b"}}])
  assert.deepEqual(calls.js, [])
})

test("a JS command is run, not pushed as an event name", {skip}, () => {
  const json = '[["push",{"event":"x"}]]'
  const {el, calls} = mount(json)
  click(el, "a")
  assert.deepEqual(calls.js, [json])
  assert.deepEqual(calls.push, [])
})

test("a JS command is run through liveSocket when the hook has no js()", {skip}, () => {
  const json = '[["push",{"event":"x"}]]'
  const {el, calls} = mount(json, {viaJs: false})
  click(el, "a")
  assert.equal(calls.liveSocket.length, 1)
  assert.equal(calls.liveSocket[0].j, json)
  assert.equal(calls.liveSocket[0].e, el)
  assert.deepEqual(calls.push, [])
})
