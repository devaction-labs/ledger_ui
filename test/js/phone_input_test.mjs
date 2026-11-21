// Mounts `priv/static/ledger_ui/hooks/phone_input.js` in jsdom: the rows are built from the shared
// country data (the HTML carries only the ISO codes) and the picker keeps working.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/phone_input_test.mjs
// jsdom is not a dependency of the package: the test is skipped when it cannot be found.
import {test} from "node:test"
import assert from "node:assert/strict"
import {createRequire} from "node:module"
import {dirname, join} from "node:path"
import {fileURLToPath, pathToFileURL} from "node:url"

const here = dirname(fileURLToPath(import.meta.url))
const require = createRequire(import.meta.url)

let JSDOM
for (const p of [process.env.JSDOM_PATH, "jsdom"].filter(Boolean)) {
  try { ({JSDOM} = require(p)); break } catch (_) { /* try the next */ }
}
const skip = JSDOM ? false : "jsdom not found (set JSDOM_PATH)"

let hook
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true})
  for (const k of ["window", "document", "Node", "HTMLElement", "Event", "KeyboardEvent", "requestAnimationFrame", "cancelAnimationFrame"]) {
    globalThis[k] = dom.window[k]
  }
  dom.window.HTMLElement.prototype.scrollIntoView = function () {}
  hook = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/phone_input.js")))).default
}

function mount({countries = "BR,PT,US,PR", pt = true, flags = false, value = "", country = "BR"} = {}) {
  const el = document.createElement("div")
  el.id = "ph" + Math.random().toString(36).slice(2)
  el.dataset.luCountry = country
  el.dataset.luCountries = countries
  el.dataset.luValue = value
  if (pt) el.dataset.luPt = "true"
  if (flags) el.dataset.luFlags = "true"
  el.innerHTML = `<span data-lu-phone-picker><b data-lu-phone-iso></b><span data-lu-phone-dial></span></span>
    <input data-lu-phone-number><input type="hidden" data-lu-phone-value>
    <div data-lu-phone-pop hidden><input data-lu-phone-search>
      <div role="listbox" data-lu-phone-list data-lu-row-class="row" data-lu-right-class="right"></div>
      <div data-lu-phone-empty hidden></div></div>`
  document.body.appendChild(el)
  const pushed = []
  const h = Object.assign(Object.create(hook), {el, pushEvent: (...a) => pushed.push(a)})
  h.mounted()
  return {el, h, pushed, rows: () => [...el.querySelectorAll("[data-lu-iso]")]}
}

test("builds the rows from the shared data, in the order and locale of the field", {skip}, () => {
  const {rows, el} = mount()
  assert.deepEqual(rows().map((r) => r.dataset.luIso), ["BR", "PT", "US", "PR"])
  const [br, , , pr] = rows()
  assert.equal(br.getAttribute("role"), "option")
  assert.equal(br.className, "row")
  assert.equal(br.getAttribute("aria-selected"), "true")
  assert.equal(pr.getAttribute("aria-selected"), "false")
  assert.equal(br.children[0].textContent, "BR")
  assert.equal(br.children[1].textContent, "Brasil")
  assert.equal(br.children[2].textContent, "+55")
  assert.equal(br.children[2].className, "right")
  assert.match(pr.children[2].textContent, /^\+1 787, 939$/)
  assert.equal(el.querySelector("[data-lu-phone-iso]").textContent, "BR")
})

test("flags and English names", {skip}, () => {
  const {rows} = mount({pt: false, flags: true})
  const br = rows()[0]
  assert.equal(br.children[0].textContent, "🇧🇷")
  assert.equal(br.children[1].textContent, "Brazil")
})

test("an unknown or empty list offers every country", {skip}, () => {
  assert.ok(mount({countries: ""}).rows().length > 90)
})

test("search, arrows and Enter pick a country; the hidden value follows", {skip}, () => {
  const {el, h, rows} = mount({countries: "BR,PT,US,PR,AR"})
  const number = el.querySelector("[data-lu-phone-number]")
  const hidden = el.querySelector("[data-lu-phone-value]")
  h.open()
  assert.equal(h.pop.hidden, false)
  assert.equal(el.querySelector("[data-lu-phone-picker]").getAttribute("aria-expanded"), "true")
  h.search.value = "portu"
  h.filter()
  assert.deepEqual(rows().filter((r) => !r.hidden).map((r) => r.dataset.luIso), ["PT"])
  h.search.value = "zzz"
  h.filter()
  assert.equal(el.querySelector("[data-lu-phone-empty]").hidden, false)
  h.search.value = ""
  h.filter()
  assert.equal(h.hl, 0) // the selected country (BR) is highlighted
  h.onSearchKey({key: "ArrowDown", preventDefault() {}})
  h.onSearchKey({key: "ArrowDown", preventDefault() {}})
  assert.ok(rows()[2].hasAttribute("data-hl"))
  h.onSearchKey({key: "Enter", preventDefault() {}})
  assert.equal(h.pop.hidden, true)
  assert.equal(h.country().iso, "US")
  number.value = "4155550100"
  h.onNumber({stopPropagation() {}})
  assert.equal(hidden.value, "+14155550100")
  assert.equal(rows()[2].getAttribute("aria-selected"), "true")
})

test("typing +351 finds the country through the shared data", {skip}, () => {
  const {el, h} = mount()
  const number = el.querySelector("[data-lu-phone-number]")
  number.value = "+351912345678"
  h.onNumber({stopPropagation() {}})
  assert.equal(h.country().iso, "PT")
  assert.equal(number.value, "912 345 678")
})

test("a new list from the server rebuilds the rows", {skip}, () => {
  const {el, h, rows} = mount()
  el.dataset.luCountries = "PT,BR"
  h.updated()
  assert.deepEqual(rows().map((r) => r.dataset.luIso), ["PT", "BR"])
  assert.equal(rows()[1].getAttribute("aria-selected"), "true")
})
