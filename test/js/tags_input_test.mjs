// The tags_input hook: Enter/Tab/comma create tags, paste splits, Backspace and the remove button take them back,
// the suggestion list filters and is driven by the arrows, the limit and the server's value (#121).
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/tags_input_test.mjs
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

let tags
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/"})
  const w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, Event: w.Event, HTMLElement: w.HTMLElement, requestAnimationFrame: w.requestAnimationFrame.bind(w)})
  tags = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/tags_input.js")))).default
}

const CLS = {tag: "tag", remove: "rm", icon: "ic", right: "kbd"}
const OPTIONS = [["br", "Brasil"], ["pt", "Portugal"], ["fr", "França"]]

// `selected`: the tags the server rendered. `with.panel`: suggestions panel. `data`: the data-lu-* attributes.
function mount({selected = [], panel = true, data = {}} = {}) {
  const el = document.createElement("div")
  el.id = "tg"
  el.dataset.luCls = JSON.stringify(CLS)
  for (const [k, v] of Object.entries(data)) el.dataset[k] = v
  const tagsHtml = selected.map(([v, l]) => `<span data-part="tags-input-tag" data-lu-value="${v}">${l}<button type="button" data-lu-remove aria-label="Remove ${l}"></button></span>`).join("")
  const opts = OPTIONS.map(([v, l]) => `<div data-part="listbox-option" data-lu-value="${v}" data-lu-label="${l}">${l}</div>`).join("")
  el.innerHTML = tagsHtml + `<input type="text" role="combobox">` +
    `<select hidden multiple>${selected.map(([v, l]) => `<option value="${v}" selected>${l}</option>`).join("")}</select>` +
    (panel ? `<div data-part="tags-input-panel" id="tg-pop" hidden><div data-lu-list>${opts}</div><div data-lu-create-row hidden></div><div data-lu-empty hidden></div></div>` : "")
  document.body.innerHTML = ""
  document.body.append(el)
  const events = []
  const hook = Object.assign(Object.create(tags), {el, pushEvent(e, p) { events.push([e, p]) }, pushEventTo(t, e, p) { events.push([e, p, t]) }})
  hook.mounted()
  const input = el.querySelector("input")
  const inputs = []
  el.addEventListener("input", (e) => e.target.tagName === "SELECT" && inputs.push([...e.target.selectedOptions].map((o) => o.value)))
  const type = (text) => { input.value = text; input.dispatchEvent(new window.Event("input", {bubbles: true})) }
  const key = (k) => { const ev = new window.KeyboardEvent("keydown", {key: k, bubbles: true, cancelable: true}); input.dispatchEvent(ev); return ev }
  return {hook, el, input, events, inputs, type, key,
    values: () => [...el.querySelectorAll("select option")].map((o) => o.value),
    labels: () => [...el.querySelectorAll(':scope > [data-part="tags-input-tag"]')].map((t) => t.firstChild.textContent),
    visibleOptions: () => [...el.querySelectorAll('[data-part="listbox-option"]')].filter((o) => !o.hidden).map((o) => o.dataset.luValue)}
}

test("Enter turns the typed text into a tag: select option, bubbling input event, cleared field", {skip}, () => {
  const t = mount({panel: false})
  t.type("alpha")
  const ev = t.key("Enter")
  assert.equal(ev.defaultPrevented, true, "Enter does not submit the form")
  assert.deepEqual(t.labels(), ["alpha"])
  assert.deepEqual(t.values(), ["alpha"])
  assert.deepEqual(t.inputs.at(-1), ["alpha"], "the hidden select fired `input`")
  assert.equal(t.input.value, "")
  t.hook.destroyed()
})

test("a comma ends the tag too; Tab with text adds it and keeps the focus, Tab with no text lets the key through", {skip}, () => {
  const t = mount({panel: false})
  t.type("one")
  assert.equal(t.key(",").defaultPrevented, true)
  t.type("two")
  assert.equal(t.key("Tab").defaultPrevented, true)
  assert.deepEqual(t.values(), ["one", "two"])
  assert.equal(t.key("Tab").defaultPrevented, false, "empty field: Tab leaves")
  t.hook.destroyed()
})

test("a pasted text with commas becomes several tags, blanks dropped; without a comma it is typed normally", {skip}, () => {
  const t = mount({panel: false})
  const paste = (text) => {
    const ev = new window.Event("paste", {bubbles: true, cancelable: true})
    ev.clipboardData = {getData: () => text}
    t.input.dispatchEvent(ev)
    return ev
  }
  assert.equal(paste("a, b,, c ").defaultPrevented, true)
  assert.deepEqual(t.values(), ["a", "b", "c"])
  assert.equal(paste("plain").defaultPrevented, false)
  t.hook.destroyed()
})

test("a duplicate is ignored and the limit stops the field (disabled, counter text)", {skip}, () => {
  const t = mount({panel: false, data: {luMax: "2", luLimitPlaceholder: "Full"}})
  t.type("x"); t.key("Enter")
  t.type("x"); t.key("Enter")
  assert.deepEqual(t.values(), ["x"], "same value twice: one tag")
  t.type("y"); t.key("Enter")
  assert.deepEqual(t.values(), ["x", "y"])
  assert.equal(t.input.disabled, true)
  assert.equal(t.input.placeholder, "Full")
  t.hook.destroyed()
})

test("Backspace on an empty field removes the last tag; with text it only edits", {skip}, () => {
  const t = mount({selected: [["a", "A"], ["b", "B"]], panel: false})
  t.type("zz")
  assert.equal(t.key("Backspace").defaultPrevented, false)
  t.type("")
  assert.equal(t.key("Backspace").defaultPrevented, true)
  assert.deepEqual(t.values(), ["a"])
  assert.deepEqual(t.inputs.at(-1), ["a"])
  t.hook.destroyed()
})

test("the remove button of a tag takes it back", {skip}, () => {
  const t = mount({selected: [["a", "A"], ["b", "B"]], panel: false})
  t.el.querySelector('[data-lu-value="a"] [data-lu-remove]').click()
  assert.deepEqual(t.values(), ["b"])
  assert.deepEqual(t.labels(), ["B"])
  t.hook.destroyed()
})

test("typing filters the suggestions (case and accent insensitive) and opens the list", {skip}, () => {
  const t = mount()
  assert.deepEqual(t.visibleOptions(), ["br", "pt", "fr"])
  t.type("franca")
  assert.deepEqual(t.visibleOptions(), ["fr"], "'franca' finds 'França'")
  assert.equal(t.hook.isOpen, true)
  assert.equal(t.el.querySelector("input").getAttribute("aria-expanded"), "true")
  t.type("zzz")
  assert.deepEqual(t.visibleOptions(), [])
  assert.equal(t.el.querySelector("[data-lu-empty]").hidden, true, "the create row is offered instead of the empty message")
  t.hook.destroyed()
})

test("the create row shows the typed text; Enter on it creates the tag", {skip}, () => {
  const t = mount({data: {luCreateLabel: "Add"}})
  t.type("Peru")
  const row = t.el.querySelector("[data-lu-create-row]")
  assert.equal(row.hidden, false)
  assert.match(row.textContent, /Add “Peru”/)
  t.key("Enter")
  assert.deepEqual(t.values(), ["Peru"])
  t.hook.destroyed()
})

test("ArrowDown/ArrowUp move the highlight and Enter picks the lit suggestion with its value and label", {skip}, () => {
  const t = mount({data: {luCreate: "false"}})
  t.type("r")
  assert.deepEqual(t.visibleOptions(), ["br", "pt", "fr"], "all three contain an r")
  assert.equal(t.hook.active.dataset.luValue, "br")
  t.key("ArrowDown")
  assert.equal(t.hook.active.dataset.luValue, "pt")
  t.key("ArrowDown"); t.key("ArrowDown")
  assert.equal(t.hook.active.dataset.luValue, "fr", "stops at the last")
  t.key("ArrowUp")
  assert.equal(t.hook.active.dataset.luValue, "pt")
  assert.equal(t.input.getAttribute("aria-activedescendant"), t.hook.active.id)
  t.key("Enter")
  assert.deepEqual(t.values(), ["pt"])
  assert.deepEqual(t.labels(), ["Portugal"])
  assert.deepEqual(t.visibleOptions().includes("pt"), false, "a chosen suggestion leaves the list")
  t.hook.destroyed()
})

test("Escape closes an open list and does not bubble; with it closed the key is left alone", {skip}, () => {
  const t = mount()
  t.type("b")
  assert.equal(t.hook.isOpen, true)
  let bubbled = false
  document.addEventListener("keydown", () => (bubbled = true), {once: true})
  assert.equal(t.key("Escape").defaultPrevented, true)
  assert.equal(t.hook.isOpen, false)
  assert.equal(bubbled, false)
  assert.equal(t.key("Escape").defaultPrevented, false)
  t.hook.destroyed()
})

test("create: false (a closed list): Enter adds nothing", {skip}, () => {
  const t = mount({data: {luCreate: "false"}, panel: false})
  t.type("free")
  t.key("Enter")
  assert.deepEqual(t.values(), [])
  t.hook.destroyed()
})

test("on_search: the query goes to the server, debounced, to the target", {skip}, async () => {
  const t = mount({data: {luOnSearch: "find", luDebounce: "10", luTarget: "#cmp"}})
  t.type("a"); t.type("ab")
  assert.equal(t.events.length, 0)
  await new Promise((r) => setTimeout(r, 30))
  assert.deepEqual(t.events, [["find", {id: "tg", query: "ab"}, "#cmp"]], "one push, the last query")
  t.hook.destroyed()
})

test("the server's value wins on update; a browser-side change the server did not touch is kept", {skip}, () => {
  const t = mount({selected: [["a", "A"]], panel: false})
  t.type("b"); t.key("Enter")
  assert.deepEqual(t.values(), ["a", "b"])
  t.hook.updated()
  assert.deepEqual(t.values(), ["a", "b"], "same server value: the browser's tags stay")
  const sel = t.el.querySelector("select")
  sel.innerHTML = '<option value="z" selected>Z</option>'
  t.hook.updated()
  assert.deepEqual(t.hook.tags, [{value: "z", label: "Z"}], "the server changed it: the server wins (its markup is the tags)")
  assert.deepEqual(t.values(), ["z"])
  t.hook.destroyed()
})
