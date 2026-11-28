// DOM.onBeforeElUpdated / copyDataAttributes (base.js): the `keep-*` protocol and the grouped `lu:sync` (#123).
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/base_dom_test.mjs
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

let DOM
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/"})
  const w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, CustomEvent: w.CustomEvent, CSS: {escape: (s) => s}})
  DOM = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/base.js")))).DOM
}

const el = (html) => {
  const t = document.createElement("template")
  t.innerHTML = html
  return t.content.firstElementChild
}
const micro = () => new Promise((r) => queueMicrotask(r))

test("keep-<attr> copies the attribute, keep-hidden/style/class are handled apart", {skip}, () => {
  const from = el('<div keep-data-state data-state="open" keep-hidden keep-style keep-class class="a open" style="top:3px" hidden></div>')
  const to = el('<div keep-data-state data-state="closed" keep-hidden keep-style keep-class class="b"></div>')
  DOM.onBeforeElUpdated(from, to)
  assert.equal(to.getAttribute("data-state"), "open")
  assert.equal(to.hidden, true)
  assert.equal(to.style.cssText, "top: 3px;")
  assert.equal(to.className, "a open")
})

test("keep-style without a style on the old element removes the new one's", {skip}, () => {
  const from = el("<div keep-style></div>")
  const to = el('<div keep-style style="top:1px"></div>')
  DOM.onBeforeElUpdated(from, to)
  assert.equal(to.hasAttribute("style"), false)
})

test("data-lu-overlay keeps open and data-state", {skip}, () => {
  const from = el('<div data-lu-overlay class="open" data-state="open"></div>')
  const to = el('<div data-lu-overlay data-state="closed"></div>')
  DOM.onBeforeElUpdated(from, to)
  assert.ok(to.classList.contains("open"))
  assert.equal(to.getAttribute("data-state"), "open")
})

test("copyDataAttributes: only keep-* with the attribute present on the old element", {skip}, () => {
  const from = el('<div keep-aria-expanded aria-expanded="true" keep-title data-x="1"></div>')
  const to = el('<div aria-expanded="false" data-x="2"></div>')
  DOM.copyDataAttributes(from, to)
  assert.equal(to.getAttribute("aria-expanded"), "true")
  assert.equal(to.getAttribute("data-x"), "2")
  assert.equal(to.hasAttribute("title"), false)
})

test("an element without attributes and without form role is untouched and does not throw", {skip}, () => {
  DOM.onBeforeElUpdated(document.createElement("span"), document.createElement("span"))
})

test("lu:sync: one microtask per patch, one event per control, none for OPTION", {skip}, async () => {
  document.body.innerHTML = "<select id=s><option id=o>a</option></select><input id=i><textarea id=t></textarea><div id=d></div>"
  const seen = []
  document.addEventListener("lu:sync", (e) => seen.push(e.target.id))
  const g = (id) => document.getElementById(id)
  for (const id of ["s", "o", "i", "t", "d", "i"]) DOM.onBeforeElUpdated(g(id), g(id).cloneNode(true))
  assert.deepEqual(seen, [], "nothing is emitted synchronously")
  await micro()
  assert.deepEqual(seen, ["s", "i", "t"])
  DOM.onBeforeElUpdated(g("i"), g("i").cloneNode(true))
  await micro()
  assert.deepEqual(seen, ["s", "i", "t", "i"], "the next patch notifies again")
})
