// What the date, datetime, time and phone pickers keep across a LiveView patch (#128): `aria-expanded` and the
// scroll of the time list.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/picker_patch_test.mjs
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

const hooks = {}
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true})
  const w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, Event: w.Event, Node: w.Node, HTMLElement: w.HTMLElement,
    requestAnimationFrame: (f) => setTimeout(f, 0), cancelAnimationFrame: clearTimeout})
  w.Element.prototype.scrollIntoView = function () {}
  for (const n of ["date_picker", "datetime_picker", "time_picker", "phone_input"])
    hooks[n] = (await import(pathToFileURL(join(here, `../../priv/static/ledger_ui/hooks/${n}.js`)))).default
}

const mount = (hook, html, cfg) => {
  document.body.innerHTML = `<div id="root" data-lu-config='${JSON.stringify(cfg)}'>${html}</div>`
  const el = document.getElementById("root")
  const h = Object.assign(Object.create(hook), {el, pushEvent() {}, pushEventTo() {}})
  h.mounted()
  return {el, h}
}

const labels = {picker_previous: "<", picker_next: ">", picker_day: "%{day}"}

test("date_picker: aria-expanded follows the open panel after a patch", {skip}, () => {
  const cfg = {mode: "single", today: "2026-11-20", format: "Y-m-d", months: Array(12).fill("m"), weekdays: Array(7).fill("w"),
    weekStart: 0, labels, presets: [], disabledDates: [], disabledWeekdays: [], classes: {base: "", tones: {}, letter: "", today: ""}, name: "d", sep: " - "}
  const html = `<input type="text" aria-expanded="false"><span data-values><input type="hidden" name="d" value=""></span>` +
    `<div role="dialog" hidden><div data-part="date-picker-calendar"><span data-part="date-picker-title"></span>` +
    `<button data-part="date-picker-nav"></button><button data-part="date-picker-nav"></button><div data-part="date-picker-grid"></div></div></div>`
  const c = mount(hooks.date_picker, html, cfg)
  const input = () => c.el.querySelector("input[type=text]")
  c.h.openPop()
  assert.equal(input().getAttribute("aria-expanded"), "true")
  input().setAttribute("aria-expanded", "false")   // the patch puts the server's attribute back
  c.h.updated()
  assert.equal(input().getAttribute("aria-expanded"), "true")
  c.h.close()
  input().setAttribute("aria-expanded", "true")
  c.h.updated()
  assert.equal(input().getAttribute("aria-expanded"), "false")
})

test("datetime_picker: aria-expanded follows the open panel after a patch", {skip}, () => {
  const cfg = {mode: "single", today: "2026-11-20", format: "Y-m-d", months: Array(12).fill("m"), weekdays: Array(7).fill("w"), weekStart: 0, labels, classes: {}}
  const html = `<input type="text" data-field="text" aria-expanded="false"><span data-values></span><div role="dialog" hidden></div>`
  const c = mount(hooks.datetime_picker, html, cfg)
  c.h.draw = () => {}
  c.h.openPop()
  const input = () => c.el.querySelector("input[type=text]")
  assert.equal(input().getAttribute("aria-expanded"), "true")
  input().setAttribute("aria-expanded", "false")
  c.h.updated()
  assert.equal(input().getAttribute("aria-expanded"), "true")
})

test("time_picker: the open list keeps its scroll and aria-expanded after a patch", {skip}, () => {
  const cfg = {variant: "input", h24: false, format: null, min: 0, max: 600, step: 5, defaultHour: 12, classes: {slot: "s"}, labels: {}}
  const html = `<input type="hidden" data-value value=""><input type="text" id="t" aria-expanded="false">` +
    `<div role="dialog" hidden><div data-part="time-picker-list"></div></div>`
  const c = mount(hooks.time_picker, html, cfg)
  const list = () => c.el.querySelector("[data-part=time-picker-list]")
  // jsdom does not scroll: a settable `scrollTop` stands in for it
  let top = 0
  Object.defineProperty(list(), "scrollTop", {get: () => top, set: (v) => { top = v }})
  c.h.openPop()
  assert.ok(list().children.length > 100)
  top = 3068
  c.h.beforeUpdate()
  list().innerHTML = ""   // the server draws the list empty
  top = 0                  // ...and the browser clamps the scroll
  c.el.querySelector("input[type=text]").setAttribute("aria-expanded", "false")
  c.h.updated()
  assert.equal(top, 3068)
  assert.ok(list().children.length > 100)
  assert.equal(c.el.querySelector("input[type=text]").getAttribute("aria-expanded"), "true")
})

test("time_picker: a closed panel is not redrawn on a patch", {skip}, () => {
  const cfg = {variant: "input", h24: false, format: null, min: 0, max: 600, step: 5, defaultHour: 12, classes: {slot: "s"}, labels: {}}
  const html = `<input type="hidden" data-value value=""><input type="text" id="t" aria-expanded="false"><div role="dialog" hidden><div data-part="time-picker-list"></div></div>`
  const c = mount(hooks.time_picker, html, cfg)
  c.h.beforeUpdate()
  c.h.updated()
  assert.equal(c.el.querySelector("[data-part=time-picker-list]").children.length, 0)
})

test("phone_input: aria-expanded follows the open panel after a patch", {skip}, () => {
  const html = `<span data-lu-phone-picker aria-expanded="false"><span data-lu-phone-iso></span><span data-lu-phone-dial></span></span>` +
    `<input data-lu-phone-number><input type="hidden" data-lu-phone-value>` +
    `<div data-lu-phone-pop hidden><input data-lu-phone-search><div data-lu-phone-list></div><div data-lu-phone-empty></div></div>`
  document.body.innerHTML = `<div id="root" data-lu-country="BR" data-lu-countries="BR,PT">${html}</div>`
  const el = document.getElementById("root")
  const h = Object.assign(Object.create(hooks.phone_input), {el, pushEvent() {}, pushEventTo() {}})
  h.mounted()
  const picker = el.querySelector("[data-lu-phone-picker]")
  h.open()
  assert.equal(picker.getAttribute("aria-expanded"), "true")
  picker.setAttribute("aria-expanded", "false")
  h.updated()
  assert.equal(picker.getAttribute("aria-expanded"), "true")
  h.close(false)
  picker.setAttribute("aria-expanded", "true")
  h.updated()
  assert.equal(picker.getAttribute("aria-expanded"), "false")
})

// --- the name of the field is the `data-lu-name` attribute, not part of the config (#96) --------
test("date_picker: the hidden inputs take their name from data-lu-name", {skip}, () => {
  const cfg = {mode: "single", today: "2026-11-20", format: "Y-m-d", months: Array(12).fill("m"), weekdays: Array(7).fill("w"),
    weekStart: 0, labels, presets: [], disabledDates: [], disabledWeekdays: [], classes: {base: "", tones: {}, letter: "", today: ""}, sep: " - "}
  const html = `<input type="text" aria-expanded="false"><span data-values></span>` +
    `<div role="dialog" hidden><div data-part="date-picker-calendar"><span data-part="date-picker-title"></span>` +
    `<button data-part="date-picker-nav"></button><button data-part="date-picker-nav"></button><div data-part="date-picker-grid"></div></div></div>`
  const c = mount(hooks.date_picker, html, cfg)
  c.el.dataset.luName = "f[a]"
  c.h.set([new Date(2026, 10, 5)], false)
  assert.equal(c.el.querySelector("[data-values] input").name, "f[a]")
  assert.equal(c.el.querySelector("[data-values] input").value, "2026-11-05")
  c.h.cfg.mode = "multiple"
  c.h.set([new Date(2026, 10, 5), new Date(2026, 10, 6)], false)
  assert.deepEqual([...c.el.querySelectorAll("[data-values] input")].map((i) => i.name), ["f[a][]", "f[a][]", "f[a][]"])
})

test("datetime_picker: the hidden inputs take their name from data-lu-name", {skip}, () => {
  const cfg = {mode: "single", today: "2026-11-20", format: "Y-m-d", months: Array(12).fill("m"), weekdays: Array(7).fill("w"), weekStart: 0, labels, classes: {}}
  const html = `<input type="text" data-field="text" aria-expanded="false"><span data-values></span><div role="dialog" hidden></div>`
  const c = mount(hooks.datetime_picker, html, cfg)
  c.el.dataset.luName = "f[a]"
  c.h.updateText = () => {}
  c.h.commit([{d: new Date(2026, 10, 5), m: 600}])
  const inp = c.el.querySelector("[data-values] input")
  assert.deepEqual([inp.name, inp.value], ["f[a]", "2026-11-05T10:00"])
})

// --- no `today` in the date picker config: the browser's day (#98) ---------------------------------
test("date_picker: without today in the config the hook marks the browser's day, and days carry only their tone", {skip}, () => {
  const cfg = {mode: "single", format: "Y-m-d", months: Array(12).fill("m"), weekdays: Array(7).fill("w"), weekStart: 0, labels,
    presets: [], disabledDates: [], disabledWeekdays: [], sep: " - ", classes: {tones: {normal: "TONE", out: "OUT"}, letter: "L", today: "TODAY"}}
  const html = `<input type="text" aria-expanded="false"><span data-values></span>` +
    `<div role="dialog" hidden><div data-part="date-picker-calendar"><span data-part="date-picker-title"></span>` +
    `<button data-part="date-picker-nav"></button><button data-part="date-picker-nav"></button><div data-part="date-picker-grid"></div></div></div>`
  const c = mount(hooks.date_picker, html, cfg)
  const n = new Date()
  const iso = `${n.getFullYear()}-${String(n.getMonth() + 1).padStart(2, "0")}-${String(n.getDate()).padStart(2, "0")}`
  const today = c.el.querySelector(`[data-d="${iso}"]`)
  assert.ok(today, "the grid shows the browser's month")
  assert.equal(today.getAttribute("aria-current"), "date")
  assert.match(today.className, /TODAY/)
  assert.doesNotMatch(c.el.querySelector("[data-part=date-picker-day]").className, /relative|h-\[34px\]/)
})

// --- the list of times takes Tab at the current time (#122) -----------------------------------
test("time_picker: one button of the list is in the tab order, the chosen time or the one nearest to the default hour", {skip}, () => {
  const cfg = {variant: "input", h24: false, format: null, min: 0, max: 1439, step: 5, defaultHour: 12, classes: {slot: "s"}, labels: {}}
  const html = (v) => `<input type="hidden" data-value value="${v}"><input type="text" id="t" aria-expanded="false"><div role="dialog" hidden><div data-part="time-picker-list"></div></div>`
  const tabbable = (c) => [...c.el.querySelectorAll("[data-part=time-picker-slot]")].filter((b) => b.tabIndex === 0).map((b) => b.dataset.value)
  const withValue = mount(hooks.time_picker, html("14:35"), cfg)
  withValue.h.openPop()
  assert.deepEqual(tabbable(withValue), ["14:35"])
  const none = mount(hooks.time_picker, html(""), cfg)
  none.h.openPop()
  assert.deepEqual(tabbable(none), ["12:00"])
  const odd = mount(hooks.time_picker, html(""), {...cfg, min: 9 * 60 + 5, max: 11 * 60, step: 30})
  odd.h.openPop()
  assert.deepEqual(tabbable(odd), ["10:35"], "no slot at the default hour: the nearest one")
  assert.equal(none.el.querySelectorAll("[data-part=time-picker-slot]").length, 288)
})
