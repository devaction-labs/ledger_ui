// select, autocomplete and tags_input do not leave a listener on `document` per instance (#131): the
// `pointerdown` that closes a list is there only while that list is open, and a form reset reaches all the
// selects through one listener, which goes when the last select is destroyed.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/document_listeners_test.mjs
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

// The listeners on `document`, by type (what is added minus what is removed).
const live = new Map()
let select, autocomplete, tags
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true})
  const w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, MutationObserver: w.MutationObserver, Event: w.Event, CSS: {escape: (s) => s}})
  globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} }
  w.Element.prototype.scrollIntoView = function () {}
  const add = w.document.addEventListener.bind(w.document)
  const remove = w.document.removeEventListener.bind(w.document)
  const fns = new Map()
  w.document.addEventListener = (type, fn, ...rest) => {
    const set = fns.get(type) || new Set()
    if (!set.has(fn)) { set.add(fn); fns.set(type, set) }
    add(type, fn, ...rest)
  }
  w.document.removeEventListener = (type, fn, ...rest) => {
    const set = fns.get(type)
    if (set) set.delete(fn)
    remove(type, fn, ...rest)
  }
  live.get = (type) => (fns.get(type) || new Set()).size
  select = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/select.js")))).default
  autocomplete = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/autocomplete.js")))).default
  tags = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/tags_input.js")))).default
}

const CLS = {chip: "chip", remove: "rm", icon: "ic", right: "rt", ck: "ck", more: "mr"}
const press = (target, k) => target.dispatchEvent(new window.KeyboardEvent("keydown", {key: k, bubbles: true, cancelable: true}))
const hook = (def, el) => Object.assign(Object.create(def), {el, pushEvent() {}, pushEventTo() {}})

function selectEl(i) {
  const el = document.createElement("div")
  el.id = `s${i}`
  el.dataset.luCls = JSON.stringify(CLS)
  el.innerHTML =
    `<span data-part="select-control" tabindex="0"><span data-part="select-value" data-ph>Pick</span></span>` +
    `<div data-part="select-panel" hidden><div data-lu-list><button type="button" data-part="listbox-option" data-lu-value="a">A</button></div><div data-lu-empty hidden></div></div>` +
    `<select name="f[v]" hidden><option value="" selected></option></select>`
  return el
}
function autoEl(i) {
  const el = document.createElement("div")
  el.id = `a${i}`
  el.innerHTML =
    `<span data-part="autocomplete-control"><input type="text" data-lu-q><input type="hidden" data-lu-v value=""></span>` +
    `<div data-part="autocomplete-panel" hidden><div data-lu-list><button type="button" data-part="listbox-option" data-lu-value="a" data-lu-label="A"><span data-lu-lbl>A</span></button></div><div data-lu-empty hidden></div></div>`
  return el
}
function tagsEl(i) {
  const el = document.createElement("span")
  el.id = `t${i}`
  el.dataset.luCls = JSON.stringify({tag: "tag", remove: "rm", right: "rt", icon: "ic"})
  el.innerHTML =
    `<input data-part="tags-input-control">` +
    `<div data-part="tags-input-panel" hidden><div data-lu-list><button type="button" data-part="listbox-option" data-lu-value="a" data-lu-label="A">A</button></div><div data-lu-empty hidden></div></div>` +
    `<select name="t[]" multiple hidden><option value="" selected></option></select>`
  return el
}

const KINDS = [
  ["select", () => select, selectEl, (el) => el.querySelector('[data-part="select-control"]')],
  ["autocomplete", () => autocomplete, autoEl, (el) => el.querySelector("input[data-lu-q]")],
  ["tags_input", () => tags, tagsEl, (el) => el.querySelector("input")],
]

for (const [name, def, make, opener] of KINDS) {
  test(`${name}: ten closed instances leave no pointerdown on document; one open leaves one`, {skip}, () => {
    document.body.innerHTML = ""
    const before = live.get("pointerdown")
    const hooks = []
    for (let i = 0; i < 10; i++) {
      const el = make(i)
      document.body.appendChild(el)
      const h = hook(def(), el)
      h.mounted()
      hooks.push(h)
    }
    assert.equal(live.get("pointerdown"), before, "closed: none")
    press(opener(hooks[3].el), "ArrowDown")
    assert.equal(live.get("pointerdown"), before + 1, "open: one")
    // A pointerdown outside closes it and takes the listener off.
    document.body.dispatchEvent(new window.Event("pointerdown", {bubbles: true}))
    assert.equal(live.get("pointerdown"), before, "closed again: none")
    press(opener(hooks[3].el), "ArrowDown")
    assert.equal(live.get("pointerdown"), before + 1)
    hooks[3].destroyed()
    assert.equal(live.get("pointerdown"), before, "destroyed while open: none")
    for (const h of hooks) h.destroyed()
  })

  test(`${name}: a pointerdown inside does not close it`, {skip}, () => {
    document.body.innerHTML = ""
    const el = make(0)
    document.body.appendChild(el)
    const h = hook(def(), el)
    h.mounted()
    press(opener(el), "ArrowDown")
    assert.equal(h.isOpen, true)
    el.dispatchEvent(new window.Event("pointerdown", {bubbles: true}))
    assert.equal(h.isOpen, true)
    document.body.dispatchEvent(new window.Event("pointerdown", {bubbles: true}))
    assert.equal(h.isOpen, false)
    h.destroyed()
  })
}

test("select: one reset listener for all the selects, removed with the last", {skip}, async () => {
  document.body.innerHTML = ""
  const before = live.get("reset")
  const form = document.createElement("form")
  document.body.appendChild(form)
  const hooks = []
  for (let i = 0; i < 12; i++) {
    const el = selectEl(i)
    form.appendChild(el)
    const h = hook(select, el)
    h.mounted()
    hooks.push(h)
  }
  assert.equal(live.get("reset"), before + 1)
  // The reset still reaches each of them (the browser fires `reset` on the form, bubbling to document).
  let reset = 0
  for (const h of hooks) { const f = h.reset; h.reset = function () { reset++; return f.call(this) } }
  form.dispatchEvent(new window.Event("reset", {bubbles: true}))
  await new Promise((r) => setTimeout(r, 5))
  assert.equal(reset, 12)
  for (const h of hooks.slice(0, 11)) h.destroyed()
  assert.equal(live.get("reset"), before + 1, "one is left")
  hooks[11].destroyed()
  assert.equal(live.get("reset"), before, "none is left")
})
