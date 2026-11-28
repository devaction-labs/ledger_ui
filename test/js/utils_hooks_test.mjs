// The hotkey, persist and scroll_target hooks in a jsdom document.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/utils_hooks_test.mjs
// jsdom is a devDependency (npm install): the tests are skipped when it cannot be found, and fail when CI=true.
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
const skip = JSDOM ? false : (process.env.CI === "true" || process.env.CI === "1" ? (() => { throw new Error("jsdom not found and CI is set: run `npm install` (or set JSDOM_PATH)") })() : "jsdom not found (run `npm install` or set JSDOM_PATH)")

let hotkey, hotkeyMod, persist, scroll, scrollMod, w
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/"})
  w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, CSS: {escape: (s) => s}})
  const dir = mkdtempSync(join(tmpdir(), "lu-utils-"))
  const load = async (name) => {
    writeFileSync(join(dir, `${name}.mjs`), readFileSync(join(here, `../../priv/static/ledger_ui/hooks/${name}.js`), "utf8"))
    return import(pathToFileURL(join(dir, `${name}.mjs`)))
  }
  hotkeyMod = await load("hotkey")
  hotkey = hotkeyMod.default
  persist = (await load("persist")).default
  scrollMod = await load("scroll_target")
  scroll = scrollMod.default
}

const calls = () => ({push: [], pushTo: [], js: []})
function instance(hook, el, log = calls()) {
  return Object.assign(Object.create(hook), {
    el,
    pushEvent: (...a) => log.push.push(a),
    pushEventTo: (...a) => log.pushTo.push(a),
    liveSocket: {execJS: (...a) => log.js.push(a)},
  })
}
function node(html) {
  document.body.insertAdjacentHTML("beforeend", html)
  return document.body.lastElementChild
}
const press = (target, init) => {
  const e = new w.KeyboardEvent("keydown", {bubbles: true, cancelable: true, ...init})
  target.dispatchEvent(e)
  return e
}

test("hotkey: Mod is Ctrl off macOS, pushes the event and prevents default", {skip}, () => {
  const el = node(`<span id="hk1" data-lu-keys="Mod+j" data-lu-on-press="toggle"></span>`)
  const log = calls()
  const h = instance(hotkey, el, log)
  h.mounted()
  const e = press(document.body, {key: "j", ctrlKey: true})
  assert.equal(e.defaultPrevented, true)
  assert.deepEqual(log.push, [["toggle", {key: "Mod+j"}]])
  // extra modifier, no modifier, other key: nothing
  assert.equal(press(document.body, {key: "j", ctrlKey: true, shiftKey: true}).defaultPrevented, false)
  assert.equal(press(document.body, {key: "j"}).defaultPrevented, false)
  assert.equal(press(document.body, {key: "k", ctrlKey: true}).defaultPrevented, false)
  assert.equal(log.push.length, 1)
  h.destroyed()
  el.remove()
})

test("hotkey: several combinations, aliases and Shift", {skip}, () => {
  const el = node(`<span data-lu-keys="Mod+Shift+k, Alt+n, Escape" data-lu-on-press="x"></span>`)
  const log = calls()
  const h = instance(hotkey, el, log)
  h.mounted()
  press(document.body, {key: "K", ctrlKey: true, shiftKey: true})
  press(document.body, {key: "Dead", code: "KeyN", altKey: true})
  press(document.body, {key: "Escape"})
  assert.deepEqual(log.push.map((c) => c[1].key), ["Mod+Shift+k", "Alt+n", "Escape"])
  h.destroyed()
  el.remove()
})

test("hotkey: ignores fields unless in_inputs", {skip}, () => {
  const wrap = node(`<div><input id="i"><textarea id="t"></textarea><div id="ce" contenteditable="true"><b id="in">x</b></div><button id="b"></button></div>`)
  const el = node(`<span data-lu-keys="Mod+j" data-lu-on-press="x"></span>`)
  const log = calls()
  const h = instance(hotkey, el, log)
  h.mounted()
  for (const id of ["i", "t", "in"]) assert.equal(press(wrap.querySelector("#" + id), {key: "j", ctrlKey: true}).defaultPrevented, false, id)
  assert.equal(log.push.length, 0)
  assert.equal(press(wrap.querySelector("#b"), {key: "j", ctrlKey: true}).defaultPrevented, true)
  el.setAttribute("data-lu-in-inputs", "true")
  assert.equal(press(wrap.querySelector("#i"), {key: "j", ctrlKey: true}).defaultPrevented, true)
  assert.equal(log.push.length, 2)
  h.destroyed()
  wrap.remove()
  el.remove()
})

test("hotkey: phx-target, %JS{} and listener removed on destroyed", {skip}, () => {
  const el = node(`<span data-lu-keys="Mod+j" data-lu-on-press="x" data-lu-target="#panel" data-lu-on-press-js='[["push",{"event":"y"}]]'></span>`)
  const log = calls()
  const h = instance(hotkey, el, log)
  h.mounted()
  press(document.body, {key: "j", ctrlKey: true})
  assert.deepEqual(log.pushTo, [["#panel", "x", {key: "Mod+j"}]])
  assert.equal(log.js.length, 1)
  assert.equal(log.js[0][1], '[["push",{"event":"y"}]]')
  h.destroyed()
  assert.equal(press(document.body, {key: "j", ctrlKey: true}).defaultPrevented, false)
  assert.equal(log.pushTo.length, 1)
  el.remove()
})

test("hotkey: Mod is Cmd on macOS", {skip}, () => {
  const [c] = hotkeyMod.parseKeys("Mod+j", true)
  assert.deepEqual([c.meta, c.ctrl], [true, false])
  const [d] = hotkeyMod.parseKeys("Mod+j", false)
  assert.deepEqual([d.meta, d.ctrl], [false, true])
  assert.equal(hotkeyMod.parseKeys("Mod++")[0].key, "+")
})

function persistEl(attrs) {
  return node(`<span id="p" data-lu-key="k" ${attrs}></span>`)
}

test("persist: writes on mounted and updated, only when changed", {skip}, () => {
  w.sessionStorage.clear()
  const el = persistEl(`data-lu-value='{"open":false}'`)
  const h = instance(persist, el)
  h.mounted()
  assert.equal(w.sessionStorage.getItem("k"), '{"open":false}')
  el.setAttribute("data-lu-value", '{"open":true}')
  h.updated()
  assert.equal(w.sessionStorage.getItem("k"), '{"open":true}')
  el.remove()
})

test("persist: restores before writing and does not overwrite the saved value", {skip}, () => {
  w.sessionStorage.setItem("k", '{"open":true,"conversation_id":5}')
  const el = persistEl(`data-lu-value='{"open":false}' data-lu-on-restore="aw_restore"`)
  const log = calls()
  const h = instance(persist, el, log)
  h.mounted()
  assert.deepEqual(log.push, [["aw_restore", {value: {open: true, conversation_id: 5}}]])
  assert.equal(w.sessionStorage.getItem("k"), '{"open":true,"conversation_id":5}')
  // the server answers with the restored state: updated writes it
  el.setAttribute("data-lu-value", '{"open":true,"conversation_id":5}')
  h.updated()
  assert.equal(log.push.length, 1)
  assert.equal(w.sessionStorage.getItem("k"), '{"open":true,"conversation_id":5}')
  el.remove()
})

test("persist: survives a new mount (push_navigate) and restores with a target", {skip}, () => {
  w.sessionStorage.clear()
  const a = persistEl(`data-lu-value='{"n":1}' data-lu-on-restore="r"`)
  instance(persist, a).mounted()
  a.remove() // the page is gone
  const b = persistEl(`data-lu-value='{"n":0}' data-lu-on-restore="r" data-lu-target="#t"`)
  const log = calls()
  instance(persist, b, log).mounted()
  assert.deepEqual(log.pushTo, [["#t", "r", {value: {n: 1}}]])
  b.remove()
})

test("persist: invalid JSON is ignored, and the local storage is a different one", {skip}, () => {
  w.sessionStorage.clear()
  w.localStorage.clear()
  w.sessionStorage.setItem("k", "{oops")
  const el = persistEl(`data-lu-value='{"a":1}' data-lu-on-restore="r"`)
  const log = calls()
  instance(persist, el, log).mounted()
  assert.equal(log.push.length, 0)
  assert.equal(w.sessionStorage.getItem("k"), '{"a":1}')
  el.remove()

  const loc = persistEl(`data-lu-storage="local" data-lu-value='{"b":2}'`)
  instance(persist, loc).mounted()
  assert.equal(w.localStorage.getItem("k"), '{"b":2}')
  assert.equal(w.sessionStorage.getItem("k"), '{"a":1}')
  loc.remove()
})

test("persist: blocked storage does not throw", {skip}, () => {
  const proto = Object.getPrototypeOf(w.sessionStorage)
  const orig = proto.setItem
  proto.setItem = () => { throw new Error("blocked") }
  try {
    const el = persistEl(`data-lu-value='{"a":1}'`)
    assert.doesNotThrow(() => { const h = instance(persist, el); h.mounted(); h.updated() })
    el.remove()
  } finally {
    proto.setItem = orig
  }
})

function scrollSetup() {
  const scrolled = []
  w.Element.prototype.scrollIntoView = function (opts) { scrolled.push([this.id, opts]) }
  const root = node(`<div><section id="c" data-block="contracts"></section><section id="a" data-block="alt"></section><div id="box"><section id="c2" data-block="contracts"></section></div></div>`)
  return {scrolled, root}
}

test("scroll_target: scrolls once per change of target", {skip}, () => {
  const {scrolled, root} = scrollSetup()
  const el = node(`<span data-lu-target="contracts" data-lu-block="start"></span>`)
  const h = instance(scroll, el)
  h.mounted()
  assert.deepEqual(scrolled, [["c", {behavior: "smooth", block: "start"}]])
  h.updated() // re-render, same target
  assert.equal(scrolled.length, 1)
  el.setAttribute("data-lu-target", "alt")
  h.updated()
  assert.equal(scrolled.length, 2)
  assert.equal(scrolled[1][0], "a")
  el.removeAttribute("data-lu-target")
  h.updated()
  el.setAttribute("data-lu-target", "nope")
  h.updated() // no such block: nothing
  assert.equal(scrolled.length, 2)
  root.remove()
  el.remove()
})

test("scroll_target: scope limits the search; reduced motion turns the animation off", {skip}, () => {
  const {scrolled, root} = scrollSetup()
  const el = node(`<span data-lu-target="contracts" data-lu-scope="#box"></span>`)
  const h = instance(scroll, el)
  h.mounted()
  assert.equal(scrolled[0][0], "c2")
  assert.equal(scrolled[0][1].block, "nearest")
  w.matchMedia = (q) => ({matches: q.includes("reduced-motion")})
  el.setAttribute("data-lu-target", "alt")
  el.removeAttribute("data-lu-scope")
  h.updated()
  assert.deepEqual(scrolled[1], ["a", {behavior: "auto", block: "nearest"}])
  delete w.matchMedia
  assert.equal(scrollMod.scrollToSelector("#c", {scope: "#missing"}), false)
  assert.equal(scrollMod.scrollToSelector("#c", {block: "bogus"}), true)
  assert.equal(scrolled.at(-1)[1].block, "nearest")
  root.remove()
  el.remove()
})
