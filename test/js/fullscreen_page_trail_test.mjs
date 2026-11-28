// lu:fullscreen (the fullscreen button of navbar_cluster) and the Mod+1..6 shortcuts of page_trail in jsdom.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/fullscreen_page_trail_test.mjs
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

let w, fs, trail
const live = new Map() // listeners of `document` by type
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/"})
  w = dom.window
  Object.assign(globalThis, {window: w, document: w.document})
  const add = w.document.addEventListener.bind(w.document)
  const remove = w.document.removeEventListener.bind(w.document)
  w.document.addEventListener = (type, fn, ...rest) => {
    const set = live.get(type) || new Set()
    set.add(fn)
    live.set(type, set)
    add(type, fn, ...rest)
  }
  w.document.removeEventListener = (type, fn, ...rest) => {
    live.get(type)?.delete(fn)
    remove(type, fn, ...rest)
  }
  fs = await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/fullscreen.js")))
  trail = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/page_trail.js")))).default
}
const count = (type) => (live.get(type) || new Set()).size

test("lu:fullscreen enters and leaves fullscreen and the button follows with aria-pressed", {skip}, async () => {
  document.body.innerHTML = `<button id="fs" data-lu-fullscreen aria-pressed="false"></button>`
  const calls = []
  let current = null
  Object.defineProperty(document, "fullscreenElement", {configurable: true, get: () => current})
  document.documentElement.requestFullscreen = () => { calls.push("request"); current = document.documentElement; return Promise.resolve() }
  document.exitFullscreen = () => { calls.push("exit"); current = null; return Promise.resolve() }
  const btn = document.getElementById("fs")

  assert.equal(count("fullscreenchange"), 0, "no listener at rest")
  // the event is dispatched on the button and bubbles to the window listener
  btn.dispatchEvent(new w.CustomEvent("lu:fullscreen", {bubbles: true}))
  assert.deepEqual(calls, ["request"])
  assert.equal(count("fullscreenchange"), 1)
  document.dispatchEvent(new w.Event("fullscreenchange"))
  assert.equal(btn.getAttribute("aria-pressed"), "true")

  btn.dispatchEvent(new w.CustomEvent("lu:fullscreen", {bubbles: true}))
  assert.deepEqual(calls, ["request", "exit"])
  document.dispatchEvent(new w.Event("fullscreenchange"))
  assert.equal(btn.getAttribute("aria-pressed"), "false")
  assert.equal(count("fullscreenchange"), 0, "the listener goes when the page leaves fullscreen")
})

test("lu:fullscreen without the Fullscreen API does nothing", {skip}, () => {
  delete document.documentElement.requestFullscreen
  Object.defineProperty(document, "fullscreenElement", {configurable: true, get: () => null})
  assert.doesNotThrow(() => window.dispatchEvent(new w.CustomEvent("lu:fullscreen")))
  assert.equal(count("fullscreenchange"), 0)
})

function mountTrail(extra = "") {
  const t = {pinned: [{path: "/a", href: "/a?x=1", label: "A", icon: "file"}, {path: "/b", href: "/b", label: "B", icon: "file"}], recent: []}
  document.body.innerHTML = `<nav id="trail" data-lu-key="k" data-lu-trail='${JSON.stringify(t)}' data-lu-path="/a" ${extra}>
    <a data-lu-href="/a?x=1" id="a">A</a><a data-lu-href="/b" id="b">B</a></nav>`
  const el = document.getElementById("trail")
  const clicks = []
  for (const a of el.querySelectorAll("a")) a.addEventListener("click", (e) => { e.preventDefault(); clicks.push(a.id) })
  const h = Object.assign(Object.create(trail), {el, pushEvent() {}})
  h.mounted()
  return {h, clicks}
}
const press = (init) => {
  const e = new w.KeyboardEvent("keydown", {bubbles: true, cancelable: true, ...init})
  document.body.dispatchEvent(e)
  return e
}

test("page_trail: Mod+2 opens the 2nd pinned page; the current one is not reopened; other keys are ignored", {skip}, () => {
  const {h, clicks} = mountTrail()
  const before = count("keydown")
  const e = press({key: "2", ctrlKey: true})
  assert.equal(e.defaultPrevented, true)
  assert.deepEqual(clicks, ["b"])
  press({key: "1", ctrlKey: true}) // /a is the current page
  press({key: "3", ctrlKey: true}) // no third pinned page
  press({key: "2"}) // no modifier
  press({key: "2", ctrlKey: true, shiftKey: true})
  assert.deepEqual(clicks, ["b"])
  h.destroyed()
  assert.equal(count("keydown"), before - 1, "the listener goes with the hook")
})

test("page_trail: data-lu-hotkeys=false turns the shortcuts off", {skip}, () => {
  const {h, clicks} = mountTrail('data-lu-hotkeys="false"')
  const e = press({key: "2", ctrlKey: true})
  assert.equal(e.defaultPrevented, false)
  assert.deepEqual(clicks, [])
  h.destroyed()
})
