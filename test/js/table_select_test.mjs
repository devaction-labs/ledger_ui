// Optimistic selection (#73): the table hook and the bulk_bar hook in a jsdom document.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/table_select_test.mjs
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
const skip = JSDOM ? false : (process.env.CI === "true" || process.env.CI === "1" ? (() => { throw new Error("jsdom not found and CI is set: run `npm install` (or set JSDOM_PATH)") })() : "jsdom not found (run `npm install` or set JSDOM_PATH)")

let TableSelect, BulkBar, Lib, win
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true})
  win = dom.window
  Object.assign(globalThis, {window: win, document: win.document, HTMLElement: win.HTMLElement, CustomEvent: win.CustomEvent, MutationObserver: win.MutationObserver})
  const dir = mkdtempSync(join(tmpdir(), "lu-tsel-"))
  const base = join(here, "../../priv/static/ledger_ui")
  const put = (name, src) => writeFileSync(join(dir, name), readFileSync(join(base, src), "utf8").replaceAll("../lib/table_select.js", "./table_select.mjs"))
  put("table_select.mjs", "lib/table_select.js")
  put("hook_ts.mjs", "hooks/table_select.js")
  put("hook_bb.mjs", "hooks/bulk_bar.js")
  Lib = await import(pathToFileURL(join(dir, "table_select.mjs")))
  TableSelect = (await import(pathToFileURL(join(dir, "hook_ts.mjs")))).default
  BulkBar = (await import(pathToFileURL(join(dir, "hook_bb.mjs")))).default
}

const flush = () => new Promise(r => setTimeout(r, 0))
const SEL = "bg-sel"
const row = (id, checked) =>
  `<tr id="r${id}" aria-selected="${!!checked}" class="${checked ? SEL : ""}"><td><input data-part="table-checkbox-input" type="checkbox" phx-value-id="${id}" ${checked ? "checked" : ""}></td></tr>`

// A table with rows 1..3 (`on` are checked) and a bar bound to it; the bar's server count is `count`.
function setup({on = [], count = on.length, ind = ""} = {}) {
  document.body.innerHTML = `
    <table id="t" data-lu-select data-lu-sel-class="${SEL}">
      <thead><tr><th><input id="t-select-all" data-part="table-checkbox-input" type="checkbox" ${ind ? 'data-ind="1"' : ""} ${on.length === 3 ? "checked" : ""}></th></tr></thead>
      <tbody>${[1, 2, 3].map(i => row(i, on.includes(i))).join("")}</tbody>
    </table>
    <div id="bar" role="region" aria-label="${count} sel" data-lu-for="t" data-lu-count="${count}" data-lu-one="selected" data-lu-many="selecteds" ${count <= 0 ? "hidden data-lu-empty" : ""}><b data-part="bulk-bar-count">${count} selecteds</b></div>`
  const table = document.getElementById("t"), bar = document.getElementById("bar")
  const t = Object.assign(Object.create(TableSelect), {el: table}); t.mounted()
  const b = Object.assign(Object.create(BulkBar), {el: bar}); b.mounted()
  const box = i => document.querySelector(`#r${i} input`)
  const head = document.getElementById("t-select-all")
  return {table, bar, box, head, t, b, tr: i => document.getElementById(`r${i}`), text: () => bar.querySelector("b").textContent}
}

test("a row click updates box, row, header and bar before any reply", {skip}, () => {
  const s = setup()
  assert.ok(s.bar.hidden)
  s.box(2).click()
  assert.equal(s.box(2).checked, true)
  assert.equal(s.tr(2).getAttribute("aria-selected"), "true")
  assert.ok(s.tr(2).classList.contains(SEL))
  assert.equal(s.head.indeterminate, true)
  assert.equal(s.head.checked, false)
  assert.equal(s.bar.hidden, false)
  assert.equal(s.text(), "1 selected")
  s.box(1).click(); s.box(3).click()
  assert.equal(s.head.checked, true)
  assert.equal(s.head.indeterminate, false)
  assert.equal(s.text(), "3 selecteds")
  s.t.destroyed(); s.b.destroyed()
})

test("unchecking the last one hides the bar and clears the header", {skip}, () => {
  const s = setup({on: [2]})
  s.box(2).click()
  assert.equal(s.tr(2).getAttribute("aria-selected"), "false")
  assert.ok(!s.tr(2).classList.contains(SEL))
  assert.equal(s.head.indeterminate, false)
  assert.equal(s.bar.hidden, true)
  assert.ok(s.bar.hasAttribute("data-lu-empty"))
  s.t.destroyed(); s.b.destroyed()
})

test("the header click selects the rows of the page", {skip}, () => {
  const s = setup({on: [1]})
  s.head.click()
  for (const i of [1, 2, 3]) { assert.equal(s.box(i).checked, true); assert.equal(s.tr(i).getAttribute("aria-selected"), "true") }
  assert.equal(s.text(), "3 selecteds")
  s.head.click()
  for (const i of [1, 2, 3]) assert.equal(s.box(i).checked, false)
  assert.equal(s.bar.hidden, true)
  s.t.destroyed(); s.b.destroyed()
})

test("the event carries count, delta and ids", {skip}, () => {
  const s = setup({on: [1]})
  const seen = []
  document.addEventListener("lu:selection", e => seen.push(e.detail))
  s.box(3).click()
  assert.deepEqual(seen.at(-1), {id: "t", count: 2, delta: 1, ids: ["1", "3"]})
  s.t.destroyed(); s.b.destroyed()
})

test("a patch with a different state prevails over the optimistic one", {skip}, async () => {
  const s = setup()
  s.box(1).classList.add("phx-click-loading")
  s.box(1).click(); s.box(2).click()
  assert.equal(s.text(), "2 selecteds")
  // the server selects 3 and refuses the others (an off-page "select all N": count 5)
  s.box(1).checked = false; s.box(2).checked = false
  s.box(3).checked = true; s.box(3).setAttribute("checked", "")
  s.tr(3).setAttribute("aria-selected", "true"); s.tr(3).classList.add(SEL)
  s.bar.dataset.luCount = "5"
  s.box(1).classList.remove("phx-click-loading")
  await flush()
  assert.equal(s.box(1).checked, false)
  assert.equal(s.tr(1).getAttribute("aria-selected"), "false")
  assert.equal(s.tr(2).getAttribute("aria-selected"), "false")
  assert.equal(s.box(3).checked, true)
  s.b.updated()
  assert.equal(s.text(), "5 selecteds")
  s.t.destroyed(); s.b.destroyed()
})

test("a reply that changes nothing (refusal) undoes the optimistic state", {skip}, async () => {
  const s = setup()
  s.box(2).classList.add("phx-click-loading")
  s.box(2).click()
  assert.equal(s.bar.hidden, false)
  await flush()
  assert.equal(s.bar.hidden, false, "still pending: the optimistic state stays")
  s.box(2).classList.remove("phx-click-loading")
  await flush()
  assert.equal(s.box(2).checked, false)
  assert.equal(s.tr(2).getAttribute("aria-selected"), "false")
  assert.ok(!s.tr(2).classList.contains(SEL))
  assert.equal(s.head.indeterminate, false)
  assert.equal(s.bar.hidden, true)
  s.t.destroyed(); s.b.destroyed()
})

test("a confirming patch does not touch what is already shown", {skip}, async () => {
  const s = setup()
  s.box(2).classList.add("phx-click-loading")
  s.box(2).click()
  const textNode = s.bar.querySelector("b").firstChild
  // the patch: attribute checked, bar count 1, loading class gone
  s.box(2).setAttribute("checked", ""); s.head.dataset.ind = "1"; s.bar.dataset.luCount = "1"; s.bar.removeAttribute("hidden"); s.bar.removeAttribute("data-lu-empty")
  s.bar.querySelector("b").textContent = "1 selected"
  s.b.updated()
  s.box(2).classList.remove("phx-click-loading")
  await flush()
  assert.equal(s.box(2).checked, true)
  assert.equal(s.bar.hidden, false)
  assert.equal(s.text(), "1 selected")
  assert.equal(s.head.indeterminate, true)
  assert.notEqual(textNode, null)
  s.t.destroyed(); s.b.destroyed()
})

test("a bar for another table ignores the event", {skip}, () => {
  const s = setup()
  s.bar.dataset.luFor = "other"
  s.box(1).click()
  assert.equal(s.bar.hidden, true)
  s.t.destroyed(); s.b.destroyed()
})

// `on_viewport_*` (#101): the LiveView reads `lastElementChild` of the stream container; with
// `row_groups` the <thead> (a non-stream child) is the last one.
const groups = () => {
  document.body.innerHTML = `<table id="t" phx-viewport-bottom="more"><tbody id="a" data-phx-stream="s"></tbody>
    <tbody id="b" data-phx-stream="s"></tbody><thead id="h"></thead><tfoot id="f"></tfoot></table>`
  return document.getElementById("t")
}

test("viewportRows: while a scroll is handled lastElementChild is the last stream item", {skip}, async () => {
  const t = groups()
  const vp = Lib.viewportRows(t)
  assert.equal(t.lastElementChild.id, "f")
  let seen
  window.addEventListener("scroll", () => { seen = t.lastElementChild.id })
  window.dispatchEvent(new win.Event("scroll"))
  assert.equal(seen, "b")
  // after the event the DOM answers as always (the LiveView places new items by it)
  assert.equal(t.lastElementChild.id, "f")
  await flush()
  assert.equal(t.lastElementChild.id, "f")
  vp.destroy()
  assert.equal(t.lastElementChild.id, "f")
})

test("viewportRows: a scroll of an element is handled the same way, and the flag does not stay", {skip}, async () => {
  const t = groups()
  const box = document.createElement("div")
  box.appendChild(t)
  document.body.appendChild(box)
  const vp = Lib.viewportRows(t)
  let seen
  box.addEventListener("scroll", () => { seen = t.lastElementChild.id })
  box.dispatchEvent(new win.Event("scroll"))
  assert.equal(seen, "b")
  assert.equal(t.lastElementChild.id, "f")
  vp.destroy()
})

test("viewportRows: nothing to do without phx-viewport-*, and the hook on a <thead> finds its table", {skip}, () => {
  document.body.innerHTML = `<table id="t"><thead id="h"></thead><tbody></tbody></table>`
  assert.equal(Lib.viewportRows(document.getElementById("t")), null)
  assert.equal(Lib.tableOf(document.getElementById("h")), document.getElementById("t"))
  document.body.innerHTML = `<div id="w"><table id="t2"></table></div>`
  assert.equal(Lib.tableOf(document.getElementById("w")), document.getElementById("t2"))
})

test("the TableSelect hook on a <thead>: selection of its table and the viewport rows", {skip}, () => {
  document.body.innerHTML = `<table id="t" phx-viewport-bottom="more" data-lu-select data-lu-sel-class="bg-sel"><thead id="h"></thead>
    <tbody id="a" data-phx-stream="s"></tbody><tfoot id="f"></tfoot></table>`
  const h = Object.assign(Object.create(TableSelect), {el: document.getElementById("h")})
  h.mounted()
  assert.equal(h.table.id, "t")
  assert.ok(h.sel && h.vp)
  h.destroyed()
})
