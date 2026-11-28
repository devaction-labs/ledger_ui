// `%JS{}` for the `on_*` events of the pickers, the signature pad, the text editor and the filter menu (#119):
// an event name is pushed, a command (its JSON starts with `[`) is run in the browser.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/on_js_events_test.mjs
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

let picker, editor, filter
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/"})
  const w = dom.window
  Object.assign(globalThis, {
    window: w, document: w.document, DOMParser: w.DOMParser, CustomEvent: w.CustomEvent, Event: w.Event,
    Node: w.Node, HTMLElement: w.HTMLElement, getComputedStyle: w.getComputedStyle.bind(w),
  })
  const load = async (p) => await import(pathToFileURL(join(here, "../../priv/static/ledger_ui", p)))
  picker = await load("lib/picker.js")
  editor = (await load("hooks/text_editor.js")).default
  filter = (await load("hooks/filter_menu.js")).default
}

const JSON_CMD = '[["push",{"event":"x"}]]'

function fake(base, {viaJs = true} = {}) {
  const el = document.createElement("div")
  el.id = "h1"
  const calls = {push: [], js: [], liveSocket: []}
  const h = Object.assign(base ? Object.create(base) : {}, {
    el,
    pushEvent: (ev, p) => calls.push.push({ev, p}),
    pushEventTo: (t, ev, p) => calls.push.push({t, ev, p}),
  })
  if (viaJs) h.js = () => ({exec: (j) => calls.js.push(j)})
  else h.liveSocket = {execJS: (e, j) => calls.liveSocket.push({e, j})}
  return {h, el, calls}
}

test("picker push: an event name is pushed (to the target when given)", {skip}, () => {
  const {h, calls} = fake()
  picker.push(h, "chosen", null, {id: "i", value: "v"})
  picker.push(h, "chosen", "#t", {id: "i", value: "v"})
  assert.deepEqual(calls.push, [{ev: "chosen", p: {id: "i", value: "v"}}, {t: "#t", ev: "chosen", p: {id: "i", value: "v"}}])
  assert.deepEqual(calls.js, [])
})

test("picker push: a JS command is run, with this.js() or liveSocket.execJS", {skip}, () => {
  const a = fake()
  picker.push(a.h, JSON_CMD, null, {id: "i"})
  assert.deepEqual(a.calls.js, [JSON_CMD])
  assert.deepEqual(a.calls.push, [])

  const b = fake(null, {viaJs: false})
  picker.push(b.h, JSON_CMD, "#t", {id: "i"})
  assert.deepEqual(b.calls.liveSocket, [{e: b.el, j: JSON_CMD}])
  assert.deepEqual(b.calls.push, [])
})

test("picker push: nothing without an event", {skip}, () => {
  const {h, calls} = fake()
  picker.push(h, null, null, {})
  assert.deepEqual([calls.push, calls.js], [[], []])
})

test("text_editor push: name pushed, JS run", {skip}, () => {
  const a = fake(editor)
  a.h.push("save", {id: "h1"})
  assert.deepEqual(a.calls.push, [{ev: "save", p: {id: "h1"}}])
  a.h.push(JSON_CMD, {id: "h1"})
  assert.deepEqual(a.calls.js, [JSON_CMD])
  assert.equal(a.calls.push.length, 1)
})

test("filter_menu push: name pushed, JS run", {skip}, () => {
  const a = fake(filter)
  a.h.d = () => a.el.dataset
  a.h.push("cleared", {id: "h1", values: {}})
  assert.deepEqual(a.calls.push, [{ev: "cleared", p: {id: "h1", values: {}}}])
  a.h.push(JSON_CMD, {id: "h1", values: {}})
  assert.deepEqual(a.calls.js, [JSON_CMD])
  assert.equal(a.calls.push.length, 1)
})
