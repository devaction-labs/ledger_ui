// The autocomplete hook and its server search: the "searching" state ends on the push reply (#74) and
// the answers are cached per text in the browser (#75).
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/autocomplete_search_test.mjs
// jsdom is a devDependency (npm install): the tests are skipped when it cannot be found, and fail when CI=true.
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
const skip = JSDOM ? false : (process.env.CI === "true" || process.env.CI === "1" ? (() => { throw new Error("jsdom not found and CI is set: run `npm install` (or set JSDOM_PATH)") })() : "jsdom not found (run `npm install` or set JSDOM_PATH)")

let autocomplete
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true})
  const w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, Event: w.Event})
  w.Element.prototype.scrollIntoView = function () {}
  autocomplete = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/autocomplete.js")))).default
}

const rows = (labels) =>
  labels.map((l) => `<button type="button" data-part="listbox-option" data-lu-value="${l}" data-lu-label="${l}" aria-selected="false"><span data-lu-lbl>${l}</span></button>`).join("")

function mount({cache = true, initial = []} = {}) {
  document.body.innerHTML = ""
  const el = document.createElement("div")
  el.id = "ac1"
  el.dataset.luOnSearch = "find"
  el.dataset.luDebounce = "0"
  if (!cache) el.dataset.luCache = "false"
  el.innerHTML =
    `<span data-part="autocomplete-control"><input type="text" data-lu-q><input type="hidden" data-lu-v value=""></span>` +
    `<div data-part="autocomplete-panel" hidden><div data-lu-list>${rows(initial)}</div>` +
    `<div data-lu-empty hidden></div><div data-lu-loading hidden>Searching</div></div>`
  document.body.appendChild(el)
  const pushed = []
  const h = Object.assign(Object.create(autocomplete), {
    el,
    pushEvent: (ev, p, cb) => pushed.push({ev, p, cb}),
  })
  h.mounted()
  return {el, h, pushed}
}

const input = (el) => el.querySelector("input[data-lu-q]")
const type = (el, text) => { input(el).value = text; input(el).dispatchEvent(new window.Event("input", {bubbles: true})) }
const tick = () => new Promise((r) => setTimeout(r, 5))
const list = (el) => el.querySelector("[data-lu-list]")
const visible = (el) => [...list(el).children].filter((n) => !n.hidden).map((n) => n.dataset.luValue)
const loading = (el) => !el.querySelector("[data-lu-loading]").hidden
// What the server does on a reply: patch the list, then `updated()`, then the push callback.
const answer = (h, el, call, labels, {patch = true} = {}) => {
  if (patch) {
    list(el).innerHTML = rows(labels)
    h.updated()
  }
  call.cb({})
}

test("a reply that changes nothing still ends the searching state", {skip}, async () => {
  const {el, h, pushed} = mount({initial: ["Ana"]})
  type(el, "an")
  await tick()
  assert.equal(loading(el), true)
  assert.equal(el.getAttribute("aria-busy"), "true")
  answer(h, el, pushed[0], [], {patch: false}) // {:noreply, socket} with the same DOM
  assert.equal(loading(el), false)
  assert.equal(el.getAttribute("aria-busy"), "false")
  assert.deepEqual(visible(el), ["Ana"])
})

test("an old reply does not end the wait of a newer search", {skip}, async () => {
  const {el, h, pushed} = mount()
  type(el, "b")
  await tick()
  type(el, "ba")
  await tick()
  assert.equal(pushed.length, 2)
  pushed[0].cb({}) // late reply of "b"
  assert.equal(loading(el), true)
  // a patch alone (the answer of "b" arriving) does not end it either
  list(el).innerHTML = rows(["Bia"])
  h.updated()
  assert.equal(loading(el), true)
  pushed[1].cb({})
  assert.equal(loading(el), false)
})

test("cache: a text already searched shows its rows at once, without searching, and still pushes", {skip}, async () => {
  const {el, h, pushed} = mount()
  type(el, "barb")
  await tick()
  answer(h, el, pushed[0], ["Barbara", "Barbosa"])
  type(el, "zz")
  await tick()
  answer(h, el, pushed[1], ["Zeze"])
  assert.deepEqual(visible(el), ["Zeze"])
  type(el, "barb")
  assert.equal(loading(el), false, "no Searching")
  assert.deepEqual(visible(el), ["Barbara", "Barbosa"])
  await tick()
  assert.equal(pushed.length, 3, "the search is still sent")
  assert.equal(pushed[2].p.query, "barb")
  // the server wins when it replies
  answer(h, el, pushed[2], ["Barbara", "Barbosa", "Barbie"])
  assert.deepEqual(visible(el), ["Barbara", "Barbosa", "Barbie"])
  assert.equal(list(el).querySelectorAll("[data-lu-cached]").length, 0)
})

test("cache: a cached row can be chosen", {skip}, async () => {
  const {el, h, pushed} = mount()
  type(el, "barb")
  await tick()
  answer(h, el, pushed[0], ["Barbara"])
  type(el, "zz")
  await tick()
  answer(h, el, pushed[1], ["Zeze"])
  type(el, "barb")
  const row = list(el).querySelector('[data-lu-cached][data-lu-value="Barbara"]')
  h.choose(row)
  assert.equal(el.querySelector("input[data-lu-v]").value, "Barbara")
})

test("cache: a reply that patches nothing keeps the cached text working", {skip}, async () => {
  const {el, h, pushed} = mount()
  type(el, "ab")
  await tick()
  answer(h, el, pushed[0], ["Abel"])
  type(el, "x")
  await tick()
  answer(h, el, pushed[1], ["Xena"])
  type(el, "ab")
  await tick()
  answer(h, el, pushed[2], [], {patch: false})
  assert.equal(loading(el), false)
  assert.equal(list(el).querySelectorAll("[data-lu-cached]").length, 0)
})

test("cache: an extension of the last answer filters the rows on screen while waiting", {skip}, async () => {
  const {el, h, pushed} = mount()
  type(el, "barb")
  await tick()
  answer(h, el, pushed[0], ["Barbara", "Barbosa", "Barbie"])
  type(el, "barbar")
  await tick()
  assert.equal(loading(el), false, "no Searching: the rows are filtered in the browser")
  assert.deepEqual(visible(el), ["Barbara"])
  assert.equal(pushed.length, 2)
  answer(h, el, pushed[1], ["Barbara", "Barbarella"])
  assert.deepEqual(visible(el), ["Barbara", "Barbarella"])
})

test("cache={false}: every text shows Searching and nothing is reused", {skip}, async () => {
  const {el, h, pushed} = mount({cache: false})
  type(el, "barb")
  await tick()
  answer(h, el, pushed[0], ["Barbara", "Barbosa"])
  type(el, "barbar") // an extension: no local filter either
  await tick()
  assert.equal(loading(el), true)
  assert.deepEqual(visible(el), [])
  answer(h, el, pushed[1], ["Barbara"])
  type(el, "barb") // already searched: no cache
  assert.equal(loading(el), true)
  assert.deepEqual(visible(el), [])
  await tick()
  assert.equal(pushed.length, 3)
})

test("cache: keeps at most 20 texts per field", {skip}, async () => {
  const {el, h, pushed} = mount()
  for (let i = 0; i < 21; i++) {
    type(el, `t${i}x`)
    await tick()
    answer(h, el, pushed[i], [`R${i}`])
  }
  type(el, "t0x") // the oldest was evicted
  assert.equal(loading(el), true)
  type(el, "t20x")
  assert.equal(loading(el), false)
  assert.deepEqual(visible(el), ["R20"])
})
