// search_shortcut (the "/" key of <.input shortcut="/">) in a jsdom document.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/search_shortcut_test.mjs
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

let hook, w
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/"})
  w = dom.window
  Object.assign(globalThis, {window: w, document: w.document})
  const dir = mkdtempSync(join(tmpdir(), "lu-search-"))
  for (const name of ["hotkey", "search_shortcut"]) {
    writeFileSync(join(dir, `${name}.mjs`), readFileSync(join(here, `../../priv/static/ledger_ui/hooks/${name}.js`), "utf8").replace("./hotkey.js", "./hotkey.mjs"))
  }
  hook = (await import(pathToFileURL(join(dir, "search_shortcut.mjs")))).default
}

const box = (id, spec = "/") =>
  `<span id="${id}-box" data-lu-shortcut="${spec}"><input id="${id}" data-part="input-control"><kbd>${spec}</kbd></span>`
function mount(html) {
  document.body.insertAdjacentHTML("beforeend", html)
  const el = document.body.lastElementChild
  // jsdom has no layout: every box counts as visible unless it is marked hidden
  el.getClientRects = () => (el.hasAttribute("data-off") ? [] : [{}])
  const h = Object.assign(Object.create(hook), {el})
  h.mounted()
  return h
}
const press = (target, init) => {
  const e = new w.KeyboardEvent("keydown", {bubbles: true, cancelable: true, ...init})
  target.dispatchEvent(e)
  return e
}
const clean = () => { document.body.innerHTML = "" }

test("search shortcut: / focuses the field and prevents the character", {skip}, () => {
  const h = mount(box("q"))
  const e = press(document.body, {key: "/"})
  assert.equal(document.activeElement.id, "q")
  assert.equal(e.defaultPrevented, true)
  h.destroyed()
  clean()
})

test("search shortcut: ignored from other fields, contenteditable and with Ctrl, Meta or Alt", {skip}, () => {
  document.body.insertAdjacentHTML("beforeend", `<input id="o"><div id="ce" contenteditable="true"><b id="in">x</b></div><textarea id="t"></textarea><button id="b"></button>`)
  const h = mount(box("q"))
  for (const id of ["o", "in", "t"]) {
    assert.equal(press(document.getElementById(id), {key: "/"}).defaultPrevented, false, id)
  }
  for (const m of ["ctrlKey", "metaKey", "altKey"]) {
    assert.equal(press(document.getElementById("b"), {key: "/", [m]: true}).defaultPrevented, false, m)
  }
  assert.notEqual(document.activeElement.id, "q")
  assert.equal(press(document.getElementById("b"), {key: "/"}).defaultPrevented, true)
  assert.equal(document.activeElement.id, "q")
  h.destroyed()
  clean()
})

test("search shortcut: Esc inside the field blurs it", {skip}, () => {
  const h = mount(box("q"))
  const input = document.getElementById("q")
  input.focus()
  assert.equal(document.activeElement, input)
  press(input, {key: "Escape"})
  assert.notEqual(document.activeElement, input)
  // Esc elsewhere does nothing
  press(document.body, {key: "Escape"})
  h.destroyed()
  clean()
})

test("search shortcut: only the first visible box answers", {skip}, () => {
  document.body.insertAdjacentHTML("beforeend", `<span id="x-box" data-off data-lu-shortcut="/"><input id="x" data-part="input-control"></span>`)
  const off = document.getElementById("x-box")
  off.getClientRects = () => []
  const hx = Object.assign(Object.create(hook), {el: off})
  hx.mounted()
  const h1 = mount(box("a"))
  const h2 = mount(box("b"))
  press(document.body, {key: "/"})
  assert.equal(document.activeElement.id, "a")
  for (const h of [hx, h1, h2]) h.destroyed()
  clean()
})

test("search shortcut: a custom combination, and the listener goes away on destroyed", {skip}, () => {
  const h = mount(box("q", "Mod+k"))
  assert.equal(press(document.body, {key: "/"}).defaultPrevented, false)
  assert.equal(press(document.body, {key: "k", ctrlKey: true}).defaultPrevented, true)
  document.getElementById("q").blur()
  h.destroyed()
  assert.equal(press(document.body, {key: "k", ctrlKey: true}).defaultPrevented, false)
  clean()
})
