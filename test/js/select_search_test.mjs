// The select hook and the search it tells the server about (#51): clearing the text sends on_search with an empty query.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/select_search_test.mjs
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

let select
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true})
  const w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, MutationObserver: w.MutationObserver, Event: w.Event, CSS: {escape: (s) => s}})
  globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} }
  w.Element.prototype.scrollIntoView = function () {}
  select = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/select.js")))).default
}

const flush = () => new Promise((r) => setTimeout(r, 0))
const CLS = {chip: "chip", remove: "rm", icon: "ic", right: "rt", ck: "ck", more: "mr"}

function mount({multiple = true, search = true, target, cache = true, more = false} = {}) {
  document.body.innerHTML = ""
  const el = document.createElement("div")
  el.id = "sel1"
  el.dataset.luCls = JSON.stringify(CLS)
  el.dataset.luDebounce = "20"
  if (multiple) el.dataset.luMultiple = ""
  if (search) el.dataset.luOnSearch = "find"
  if (target) el.dataset.luTarget = target
  if (!cache) el.dataset.luCache = "false"
  if (more) el.dataset.luOnLoadMore = "more"
  el.dataset.luValue = "[]"
  el.innerHTML =
    `<span data-part="select-control"><span data-part="select-value" data-ph>Pick</span><input data-lu-q hidden><svg></svg></span>` +
    `<div data-part="select-panel" hidden><div role="listbox" data-lu-list>` +
    [1, 2, 3].map((i) => `<button type="button" data-part="listbox-option" data-lu-value="o${i}" aria-selected="false">Option ${i}</button>`).join("") +
    `</div><div data-lu-empty hidden></div></div><select name="f[v]" hidden ${multiple ? "multiple" : ""}></select>`
  document.body.appendChild(el)
  const pushed = []
  const cbs = []
  const h = Object.assign(Object.create(select), {
    el,
    pushEvent: (ev, p, cb) => { pushed.push(["pushEvent", ev, p]); cbs.push(cb) },
    pushEventTo: (t, ev, p, cb) => { pushed.push(["pushEventTo", t, ev, p]); cbs.push(cb) },
  })
  h.mounted()
  return {el, h, pushed, cbs}
}

const q = (el) => el.querySelector("input[data-lu-q]")
const type = (el, text) => { q(el).value = text; q(el).dispatchEvent(new window.Event("input", {bubbles: true})) }
const row = (el, v) => el.querySelector(`[data-lu-value="${v}"]`)

test("multiple: choosing after a search tells the server once, with an empty query", {skip}, async () => {
  const {el, h, pushed} = mount()
  h.setOpen(true)
  type(el, "sau")
  await new Promise((r) => setTimeout(r, 40))
  assert.deepEqual(pushed, [["pushEvent", "find", {id: "sel1", query: "sau"}]])
  pushed.length = 0
  h.choose(row(el, "o2"))
  assert.deepEqual(pushed, [["pushEvent", "find", {id: "sel1", query: ""}]])
  assert.equal(q(el).value, "")
  await flush()
  assert.equal(pushed.length, 1)
})

test("single: choosing after a search (the panel closes) sends the empty query once", {skip}, () => {
  const {el, h, pushed} = mount({multiple: false})
  h.setOpen(true)
  type(el, "sau")
  pushed.length = 0
  h.choose(row(el, "o1"))
  assert.deepEqual(pushed, [["pushEvent", "find", {id: "sel1", query: ""}]])
  h.setOpen(true)
  assert.equal(pushed.length, 1, "reopening with empty text sends nothing more")
})

test("the empty query goes to the same target as the search", {skip}, () => {
  const {el, h, pushed} = mount({target: "#box"})
  h.setOpen(true)
  type(el, "sau")
  h.choose(row(el, "o1"))
  assert.deepEqual(pushed, [["pushEventTo", "#box", "find", {id: "sel1", query: ""}]])
})

test("empty text: choosing, closing and Esc send nothing", {skip}, () => {
  const {el, h, pushed} = mount()
  h.setOpen(true)
  h.choose(row(el, "o1"))
  h.key({key: "Escape", target: el, preventDefault() {}, stopPropagation() {}})
  h.setOpen(true)
  h.setOpen(false)
  assert.deepEqual(pushed, [])
})

test("without on_search nothing is sent", {skip}, () => {
  const {el, h, pushed} = mount({search: false})
  h.setOpen(true)
  type(el, "sau")
  h.choose(row(el, "o1"))
  h.setOpen(false)
  assert.deepEqual(pushed, [])
})

test("a debounced search still pending is cancelled by the empty query", {skip}, async () => {
  const {el, h, pushed} = mount()
  h.setOpen(true)
  type(el, "sau")
  h.choose(row(el, "o1"))
  await new Promise((r) => setTimeout(r, 50))
  assert.deepEqual(pushed, [["pushEvent", "find", {id: "sel1", query: ""}]], "the old search never leaves")
})

test("closing the panel (Esc, outside click) with text tells the server too", {skip}, () => {
  const {el, h, pushed} = mount()
  h.setOpen(true)
  type(el, "sau")
  pushed.length = 0
  h.setOpen(false)
  assert.deepEqual(pushed, [["pushEvent", "find", {id: "sel1", query: ""}]])
})

// ---- the push reply (#74) and the cache (#75) ------------------------------------------------------
const rows = (labels) => labels.map((l) => `<button type="button" data-part="listbox-option" data-lu-value="${l}" data-lu-label="${l}" aria-selected="false">${l}</button>`).join("")
const list = (el) => el.querySelector("[data-lu-list]")
const shown = (el) => [...list(el).children].filter((n) => !n.hidden).map((n) => n.dataset.luValue)
const wait = () => new Promise((r) => setTimeout(r, 40))
// The server answers: patch the list, `updated()`, then the push callback.
const answer = (h, el, cb, labels) => {
  if (labels) {
    list(el).innerHTML = rows(labels)
    h.updated()
  }
  cb({})
}

const mores = (pushed) => pushed.filter((p) => p[1] === "more").length

test("load more: a reply that changes nothing ends the wait, so the next scroll can ask again", {skip}, () => {
  const {h, pushed, cbs} = mount({more: true})
  h.setOpen(true) // the (empty) panel is at the bottom: asks for more
  assert.equal(mores(pushed), 1)
  assert.equal(h.pending, true)
  h.more()
  assert.equal(mores(pushed), 1, "one at a time while waiting")
  cbs[cbs.length - 1]({}) // {:noreply, socket}, no patch
  assert.equal(mores(pushed), 2, "the reply ended the wait; it looks again")
})

test("load more: the reply of an old load does not end the wait of a newer one", {skip}, async () => {
  const {el, h, pushed, cbs} = mount({more: true})
  h.setOpen(true)
  const oldCb = cbs[0]
  type(el, "sau") // a new search: the load in flight is obsolete
  assert.equal(h.pending, false)
  h.more()
  assert.equal(h.pending, true)
  const n = pushed.length
  oldCb({}) // late reply of the first load
  assert.equal(h.pending, true, "the old reply does not end the new wait")
  assert.equal(pushed.length, n)
})

test("cache: a text already searched shows its rows at once and still pushes", {skip}, async () => {
  const {el, h, pushed, cbs} = mount()
  h.setOpen(true)
  type(el, "barb")
  await wait()
  answer(h, el, cbs[0], ["Barbara", "Barbosa"])
  type(el, "zz")
  await wait()
  answer(h, el, cbs[1], ["Zeze"])
  type(el, "barb")
  assert.deepEqual(shown(el), ["Barbara", "Barbosa"], "cached rows now")
  await wait()
  assert.equal(pushed.length, 3, "revalidates")
  assert.equal(pushed[2][2].query, "barb")
  answer(h, el, cbs[2], ["Barbara", "Barbie"])
  assert.deepEqual(shown(el), ["Barbara", "Barbie"], "the server wins")
  assert.equal(list(el).querySelectorAll("[data-lu-cached]").length, 0)
})

test("cache: a cached row can be chosen", {skip}, async () => {
  const {el, h, cbs} = mount({multiple: false})
  h.setOpen(true)
  type(el, "barb")
  await wait()
  answer(h, el, cbs[0], ["Barbara"])
  type(el, "zz")
  await wait()
  answer(h, el, cbs[1], ["Zeze"])
  type(el, "barb")
  h.choose(list(el).querySelector('[data-lu-cached][data-lu-value="Barbara"]'))
  assert.deepEqual(h.sel.map((o) => o.value), ["Barbara"])
})

test("cache: a text that extends the last answer filters the rows on screen while waiting", {skip}, async () => {
  const {el, h, pushed, cbs} = mount()
  h.setOpen(true)
  type(el, "barb")
  await wait()
  answer(h, el, cbs[0], ["Barbara", "Barbosa", "Barbie"])
  type(el, "barbar")
  assert.deepEqual(shown(el), ["Barbara"])
  await wait()
  assert.equal(pushed.length, 2)
  answer(h, el, cbs[1], ["Barbara", "Barbarella"])
  assert.deepEqual(shown(el), ["Barbara", "Barbarella"])
})

test("cache={false}: nothing is reused and the rows are not filtered locally", {skip}, async () => {
  const {el, h, cbs} = mount({cache: false})
  h.setOpen(true)
  type(el, "barb")
  await wait()
  answer(h, el, cbs[0], ["Barbara", "Barbosa"])
  type(el, "barbar")
  assert.deepEqual(shown(el), ["Barbara", "Barbosa"], "the server rows stay as they were")
  await wait()
  answer(h, el, cbs[1], ["Barbara"])
  type(el, "barb")
  assert.deepEqual(shown(el), ["Barbara"], "no cached rows")
  assert.equal(list(el).querySelectorAll("[data-lu-cached]").length, 0)
})
