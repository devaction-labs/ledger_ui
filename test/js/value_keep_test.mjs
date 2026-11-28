// otp, number_input, range, rating and color_picker keep the person's value across a patch that does not change
// the value the server drew (#129), and let the server win when it does.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/value_keep_test.mjs
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
  Object.assign(globalThis, {window: w, document: w.document, Event: w.Event, HTMLElement: w.HTMLElement})
  for (const n of ["otp", "number_input", "range", "rating", "color_picker"])
    hooks[n] = (await import(pathToFileURL(join(here, `../../priv/static/ledger_ui/hooks/${n}.js`)))).default
}

const mountHook = (hook, html, attrs = {}) => {
  document.body.innerHTML = `<div id="root">${html}</div>`
  const el = document.getElementById("root")
  for (const [k, v] of Object.entries(attrs)) el.setAttribute(k, v)
  const h = Object.assign(Object.create(hook), {el, pushEvent() {}, pushEventTo() {}, liveSocket: {execJS() {}}})
  h.mounted()
  return {el, h}
}
// A patch: the server's markup replaces the root's children (and attributes), then `updated`.
const patch = (ctx, html, attrs) => {
  ctx.el.innerHTML = html
  for (const [k, v] of Object.entries(attrs || {})) ctx.el.setAttribute(k, v)
  ctx.h.updated()
}

// --- otp ------------------------------------------------------------------------------------
const otpHtml = (code = "") =>
  Array.from({length: 4}, (_, i) => `<span><input data-lu-otp-box value="${code[i] || ""}"></span>`).join("") +
  `<input type="hidden" name="otp" data-lu-otp-value value="${code}">`
const otp = (code = "") => mountHook(hooks.otp, otpHtml(code), {"data-lu-length": "4", "data-lu-value": code})
const typeOtp = (c, text) => {
  const boxes = c.el.querySelectorAll("[data-lu-otp-box]")
  ;[...text].forEach((ch, i) => { boxes[i].value = ch; boxes[i].dispatchEvent(new window.Event("input", {bubbles: true})) })
}
const otpState = (c) => [[...c.el.querySelectorAll("[data-lu-otp-box]")].map((b) => b.value).join("|"), c.el.querySelector("[data-lu-otp-value]").value]

test("otp: a patch that keeps the server's code keeps the typed one", {skip}, () => {
  const c = otp("")
  typeOtp(c, "12")
  assert.deepEqual(otpState(c), ["1|2||", "12"])
  patch(c, otpHtml(""))
  assert.deepEqual(otpState(c), ["1|2||", "12"])
})

test("otp: a code the server changed wins over the typed one", {skip}, () => {
  const c = otp("")
  typeOtp(c, "12")
  patch(c, otpHtml("9876"), {"data-lu-value": "9876"})
  assert.deepEqual(otpState(c), ["9|8|7|6", "9876"])
})

// --- number_input ---------------------------------------------------------------------------
const numHtml = (v) =>
  `<input type="hidden" name="n" value="${v}" data-num-value><button type="button" data-part="number-minus"></button>` +
  `<span data-part="number-value">${v}</span><button type="button" data-part="number-plus"></button>`
const CFG = JSON.stringify({dec: ".", thou: "", step: 1, min: null, max: null, decimals: null, maxDecimals: null})
const num = (v) => mountHook(hooks.number_input, numHtml(v), {"data-lu-config": CFG})
const numState = (c) => [c.el.querySelector("[data-num-value]").value, c.el.querySelector("[data-part=number-value]").textContent]

test("number_input: a patch that keeps the server's value keeps the stepped one", {skip}, () => {
  const c = num(3)
  c.el.querySelector("[data-part=number-plus]").click()
  c.el.querySelector("[data-part=number-plus]").click()
  assert.deepEqual(numState(c), ["5", "5"])
  patch(c, numHtml(3))
  assert.deepEqual(numState(c), ["5", "5"])
  patch(c, numHtml(3))
  assert.deepEqual(numState(c), ["5", "5"])
})

test("number_input: a value the server changed wins over the stepped one", {skip}, () => {
  const c = num(3)
  c.el.querySelector("[data-part=number-plus]").click()
  patch(c, numHtml(10))
  assert.deepEqual(numState(c), ["10", "10"])
  // ...and a later patch with the new server value keeps what the person does after that
  c.el.querySelector("[data-part=number-minus]").click()
  patch(c, numHtml(10))
  assert.deepEqual(numState(c), ["9", "9"])
})

// --- range ----------------------------------------------------------------------------------
const rangeHtml = (v) =>
  `<input type="hidden" name="r" value="${v}" data-range-value><span data-part="range-track"></span><span data-part="range-fill"></span>` +
  `<span data-part="range-thumb" aria-valuenow="${v}"></span>`
const RCFG = JSON.stringify({min: 0, max: 100, step: 1, pair: false, vertical: false, disabled: false, format: "%{value}", marks: [], decrease: "-", increase: "+"})
const range = (v) => mountHook(hooks.range, rangeHtml(v), {"data-lu-config": RCFG})
const rangeState = (c) => [c.el.querySelector("[data-range-value]").value, c.el.querySelector("[data-part=range-thumb]").getAttribute("aria-valuenow")]
const press = (c, key) =>
  c.el.querySelector("[data-part=range-thumb]").dispatchEvent(new window.KeyboardEvent("keydown", {key, bubbles: true}))

test("range: a patch that keeps the server's value keeps the keyboard's", {skip}, () => {
  const c = range(54)
  for (let i = 0; i < 5; i++) press(c, "ArrowRight")
  assert.deepEqual(rangeState(c), ["59", "59"])
  patch(c, rangeHtml(54))
  assert.deepEqual(rangeState(c), ["59", "59"])
})

test("range: a value the server changed wins over the keyboard's", {skip}, () => {
  const c = range(54)
  press(c, "ArrowRight")
  patch(c, rangeHtml(20))
  assert.deepEqual(rangeState(c), ["20", "20"])
  press(c, "ArrowRight")
  patch(c, rangeHtml(20))
  assert.deepEqual(rangeState(c), ["21", "21"])
})

// --- rating ---------------------------------------------------------------------------------
const ratingHtml = (grade) =>
  Array.from({length: 5}, (_, i) => `<label><input type="radio" name="rt" value="${i + 1}"${i + 1 === grade ? " checked" : ""}><svg data-state="${i < grade ? "on" : "off"}"></svg></label>`).join("")
const rating = (g) => mountHook(hooks.rating, ratingHtml(g))
const grade = (c) => [...c.el.querySelectorAll("input")].findIndex((i) => i.checked) + 1
const stars = (c) => [...c.el.querySelectorAll("svg")].filter((s) => s.getAttribute("data-state") === "on").length
const pick = (c, n) => { const i = c.el.querySelectorAll("input")[n - 1]; i.checked = true; i.dispatchEvent(new window.Event("change", {bubbles: true})) }

test("rating: a patch that keeps the server's grade keeps the clicked one", {skip}, () => {
  const c = rating(0)
  pick(c, 4)
  assert.equal(grade(c), 4)
  patch(c, ratingHtml(0))
  assert.deepEqual([grade(c), stars(c)], [4, 4])
  patch(c, ratingHtml(0))
  assert.deepEqual([grade(c), stars(c)], [4, 4])
})

test("rating: a grade the server changed wins over the clicked one", {skip}, () => {
  const c = rating(2)
  pick(c, 4)
  patch(c, ratingHtml(1))
  assert.deepEqual([grade(c), stars(c)], [1, 1])
  pick(c, 5)
  patch(c, ratingHtml(1))
  assert.deepEqual([grade(c), stars(c)], [5, 5])
})

// --- color_picker ---------------------------------------------------------------------------
const SW = ["#1F9282", "#4C3FE0", "#6A4FD8"]
const colorHtml = (v) =>
  `<input type="hidden" name="cp" value="${v}" data-color-value>` +
  SW.map((c) => `<button type="button" data-part="color-picker-swatch" aria-label="${c}" aria-pressed="${c === v}"></button>`).join("")
const color = (v) => mountHook(hooks.color_picker, colorHtml(v))
const colorState = (c) => [c.el.querySelector("[data-color-value]").value, c.el.querySelector("[aria-pressed=true]")?.getAttribute("aria-label")]

test("color_picker: a patch that keeps the server's colour keeps the chosen swatch", {skip}, () => {
  const c = color("#1F9282")
  c.el.querySelectorAll("[data-part=color-picker-swatch]")[2].click()
  assert.deepEqual(colorState(c), ["#6A4FD8", "#6A4FD8"])
  patch(c, colorHtml("#1F9282"))
  assert.deepEqual(colorState(c), ["#6A4FD8", "#6A4FD8"])
})

test("color_picker: a colour the server changed wins over the chosen swatch", {skip}, () => {
  const c = color("#1F9282")
  c.el.querySelectorAll("[data-part=color-picker-swatch]")[2].click()
  patch(c, colorHtml("#4C3FE0"))
  assert.deepEqual(colorState(c), ["#4C3FE0", "#4C3FE0"])
})

test("color_picker: on_change as the JSON of a %JS{} is run, an event name is pushed (#119)", {skip}, () => {
  const run = (on) => {
    const c = mountHook(hooks.color_picker, colorHtml("#1F9282"), {"data-lu-on-change": on})
    const calls = {js: [], push: []}
    c.h.liveSocket = {execJS: (el, code) => calls.js.push(code)}
    c.h.pushEvent = (ev, payload) => calls.push.push([ev, payload])
    c.el.querySelectorAll("[data-part=color-picker-swatch]")[2].click()
    return calls
  }
  const js = run('[["push",{"event":"pick"}]]')
  assert.deepEqual(js.js, ['[["push",{"event":"pick"}]]'])
  assert.deepEqual(js.push, [])
  const ev = run("pick")
  assert.deepEqual(ev.js, [])
  assert.equal(ev.push.length, 1)
  assert.equal(ev.push[0][0], "pick")
  assert.equal(ev.push[0][1].value, "#6A4FD8")
})
