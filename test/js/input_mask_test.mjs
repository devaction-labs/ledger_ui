// The input_mask hook: the masks (card, CPF/CNPJ, date, time, numeral, blocks, phone), the caret, raw submit and clear on submit (#121).
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/input_mask_test.mjs
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

let mask
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/"})
  const w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, Event: w.Event, HTMLElement: w.HTMLElement})
  mask = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/input_mask.js")))).default
}

// Mounts an <input> with the mask; `opts` are the data-lu-mask-options; `raw` adds the hidden input; `form` wraps it in a form.
function mount(type, {opts, raw = false, form = false, value = "", clear = false} = {}) {
  document.body.innerHTML = ""
  const box = document.createElement(form ? "form" : "div")
  box.innerHTML = `<input id="in" type="text" value="${value}" data-lu-mask="${type}"` +
    (opts ? ` data-lu-mask-options='${JSON.stringify(opts)}'` : "") +
    (raw ? ` data-lu-mask-raw="true"` : "") + (clear ? ` data-lu-clear-on-submit="true"` : "") + `>` +
    (raw ? `<input type="hidden" id="hid" name="v">` : "")
  document.body.append(box)
  const el = document.getElementById("in")
  const hook = Object.assign(Object.create(mask), {el})
  hook.mounted()
  const hidden = document.getElementById("hid")
  const hiddenEvents = []
  hidden && hidden.addEventListener("input", () => hiddenEvents.push(hidden.value))
  const seen = []
  box.addEventListener("input", (e) => seen.push(e.target.id))
  // Types `text` as the new value (the caret at its end), like a keystroke would.
  const type_ = (text, inputType = "insertText") => {
    el.focus()
    el.value = text
    el.setSelectionRange(text.length, text.length)
    el.dispatchEvent(new window.InputEvent("input", {bubbles: true, inputType}))
  }
  return {hook, el, hidden, hiddenEvents, seen, type: type_, form: box}
}

const cases = [
  ["credit_card", undefined, "4111111111111111", "4111 1111 1111 1111"],
  ["credit_card", undefined, "378282246310005", "3782 822463 10005"],
  ["credit_card", undefined, "30569309025904", "3056 930902 5904"],
  ["cpf_cnpj", undefined, "12345678901", "123.456.789-01"],
  ["cpf_cnpj", undefined, "12345678000199", "12.345.678/0001-99"],
  ["cpf_cnpj", undefined, "123", "123"],
  ["date", undefined, "25122024", "25/12/2024"],
  ["date", undefined, "45132024", "31/12/2024"],
  ["date", {pattern: ["Y", "m", "d"], delimiter: "-"}, "20240229", "2024-02-29"],
  ["time", undefined, "2561", "23:59"],
  ["time", {pattern: ["h", "m"]}, "0930", "09:30"],
  ["phone", undefined, "5551234567", "555 123 4567"],
  ["blocks", {blocks: [2, 3], delimiter: "-", numeric: true}, "ab12345", "12-345"],
  ["blocks", {blocks: [3, 3], delimiter: " ", uppercase: true}, "abcdef", "ABC DEF"],
  ["blocks", {blocks: [2, 2], prefix: "ID-", delimiter: "-"}, "ID-1234", "ID-12-34"],
  ["blocks", {blocks: [2], delimiter: "-"}, "abcd", "ab-cd"],
  ["numeral", undefined, "1234567.891", "1,234,567.89"],
  ["numeral", undefined, "0001234", "1,234"],
  ["numeral", {decimals: 0}, "12345.67", "1,234,567"],
  ["numeral", {delimiter: ".", decimal_mark: ","}, "1234,5", "1.234,5"],
  ["numeral", {prefix: "R$ "}, "R$ 1234.5", "R$ 1,234.5"],
  ["numeral", undefined, "-1234", "-1,234"],
  ["numeral", {positive: true}, "-1234", "1,234"],
]
for (const [type, opts, typed, expected] of cases) {
  test(`${type} ${opts ? JSON.stringify(opts) : ""}: ${typed} -> ${expected}`, {skip}, () => {
    const t = mount(type, {opts})
    t.type(typed)
    assert.equal(t.el.value, expected)
    t.hook.destroyed()
  })
}

test("a value rendered by the server is masked on mount", {skip}, () => {
  const t = mount("cpf_cnpj", {value: "12345678901"})
  assert.equal(t.el.value, "123.456.789-01")
  t.hook.destroyed()
})

test("junk is dropped: letters in a numeric mask, and an empty result is an empty field", {skip}, () => {
  const t = mount("credit_card")
  t.type("4a1b1c1")
  assert.equal(t.el.value, "4111")
  t.type("abc")
  assert.equal(t.el.value, "")
  t.hook.destroyed()
})

test("the caret stays after the digit that was typed in the middle", {skip}, () => {
  const t = mount("date")
  t.type("2512")            // "25/12"
  assert.equal(t.el.value, "25/12")
  // the person types a 0 in the middle: "25/1" + "0" + "2" (caret after the 0)
  t.el.value = "25/102"
  t.el.setSelectionRange(5, 5)
  t.el.dispatchEvent(new window.InputEvent("input", {bubbles: true, inputType: "insertText"}))
  assert.equal(t.el.value, "25/10/2")
  assert.equal(t.el.selectionStart, 5, "caret right after the 0 that was typed, not at the end")
  t.hook.destroyed()
})

test("Backspace over a delimiter removes the digit before it instead of doing nothing", {skip}, () => {
  const t = mount("date")
  t.type("25/12")
  assert.equal(t.el.value, "25/12")
  // Backspace right after the "/" of "25/12": the browser yields "2512" with the delimiter gone, caret at 3
  t.el.value = "2512"
  t.el.setSelectionRange(2, 2)
  t.el.dispatchEvent(new window.InputEvent("input", {bubbles: true, inputType: "deleteContentBackward"}))
  assert.equal(t.el.value, "21/2", "the mask alone would restore 25/12; so the digit before the delimiter (the 5) goes")
  assert.equal(t.el.selectionStart, 1)
  t.hook.destroyed()
})

test("mask_submit raw: the hidden input carries the digits, fires `input`, and the masked field stays silent", {skip}, () => {
  const t = mount("cpf_cnpj", {raw: true})
  t.type("12345678901")
  assert.equal(t.el.value, "123.456.789-01")
  assert.equal(t.hidden.value, "12345678901")
  assert.deepEqual(t.hiddenEvents, ["12345678901"])
  assert.ok(!t.seen.includes("in"), "the masked field's `input` did not bubble to the form")
  assert.ok(t.seen.includes("hid"))
  t.hook.destroyed()
})

test("raw numeral: the hidden input is a plain number string", {skip}, () => {
  const t = mount("numeral", {raw: true})
  t.type("1234.5")
  assert.equal(t.hidden.value, "1234.5")
  t.type("-9")
  assert.equal(t.hidden.value, "-9")
  t.type("")
  assert.equal(t.hidden.value, "")
  t.hook.destroyed()
})

test("clear_on_submit: the first update after a submit takes the server's (empty) value, even while focused", {skip}, () => {
  const t = mount("cpf_cnpj", {form: true, clear: true})
  t.type("12345678901")
  t.form.dispatchEvent(new window.Event("submit", {cancelable: true}))
  assert.equal(t.hook.cleared, true)
  t.hook.updated()
  assert.equal(t.el.value, "", "cleared")
  assert.equal(t.hook.cleared, false)
  t.hook.destroyed()
})

test("destroyed removes the input listener", {skip}, () => {
  const t = mount("credit_card")
  t.hook.destroyed()
  t.type("4111")
  assert.equal(t.el.value, "4111")
  t.el.value = "41111111"
  t.el.dispatchEvent(new window.InputEvent("input", {bubbles: true, inputType: "insertText"}))
  assert.equal(t.el.value, "41111111", "no longer masked")
})
