// `select_sync="client"` (#100): the table paints the rows from `data-lu-selected`.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/table_select_client_test.mjs
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
const skip = JSDOM ? false : "jsdom not found (set JSDOM_PATH)"

let TableSelect, win
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true})
  win = dom.window
  Object.assign(globalThis, {window: win, document: win.document, HTMLElement: win.HTMLElement, CustomEvent: win.CustomEvent, MutationObserver: win.MutationObserver})
  const dir = mkdtempSync(join(tmpdir(), "lu-tselc-"))
  const base = join(here, "../../priv/static/ledger_ui")
  const put = (name, src) => writeFileSync(join(dir, name), readFileSync(join(base, src), "utf8").replaceAll("../lib/table_select.js", "./table_select.mjs"))
  put("table_select.mjs", "lib/table_select.js")
  put("hook_ts.mjs", "hooks/table_select.js")
  TableSelect = (await import(pathToFileURL(join(dir, "hook_ts.mjs")))).default
}

const flush = () => new Promise(r => setTimeout(r, 0))
const SEL = "bg-sel"
// The rows the server renders in client mode: always unticked, `selected="true"` as the payload.
const row = id =>
  `<tr id="r${id}" aria-selected="false" class=""><td><input data-part="table-checkbox-input" type="checkbox" phx-value-id="${id}" phx-value-selected="true"></td></tr>`

function setup(on = []) {
  document.body.innerHTML = `
    <table id="t" data-lu-select data-lu-sel-class="${SEL}" data-lu-selected='${JSON.stringify(on)}'>
      <thead><tr><th><input id="t-select-all" data-part="table-checkbox-input" type="checkbox"></th></tr></thead>
      <tbody id="b">${[1, 2, 3].map(row).join("")}</tbody>
    </table>`
  const table = document.getElementById("t")
  const t = Object.assign(Object.create(TableSelect), {el: table}); t.mounted()
  return {table, t, box: i => document.querySelector(`#r${i} input`), tr: i => document.getElementById(`r${i}`),
    server: ids => { table.dataset.luSelected = JSON.stringify(ids) }}
}

test("mounted paints the rows from the list of the table", {skip}, () => {
  const s = setup(["2", 3])
  assert.equal(s.box(1).checked, false)
  assert.equal(s.box(2).checked, true)
  assert.equal(s.box(3).checked, true)
  assert.equal(s.tr(2).getAttribute("aria-selected"), "true")
  assert.ok(s.tr(2).classList.contains(SEL))
  assert.equal(s.tr(1).getAttribute("aria-selected"), "false")
  s.t.destroyed()
})

test("the box sends the state it has just taken, read before the LiveView sees the click", {skip}, () => {
  const s = setup(["2"])
  const seen = []
  // the LiveView's own listener: on window, bubbling, so after the one of the table
  window.addEventListener("click", e => seen.push(e.target.getAttribute("phx-value-selected")))
  s.box(1).click()
  s.box(2).click()
  assert.deepEqual(seen, ["true", "false"])
  s.t.destroyed()
})

test("the server list changes: the rows follow with no row markup patched", {skip}, async () => {
  const s = setup()
  s.server(["1", "3"])
  await flush()
  assert.equal(s.box(1).checked, true)
  assert.equal(s.box(2).checked, false)
  assert.equal(s.box(3).checked, true)
  assert.equal(s.tr(3).getAttribute("aria-selected"), "true")
  s.server([])
  await flush()
  assert.equal(s.box(1).checked, false)
  assert.ok(!s.tr(3).classList.contains(SEL))
  s.t.destroyed()
})

test("a click stays on screen until the server answers, then the list prevails", {skip}, async () => {
  const s = setup()
  s.box(1).classList.add("phx-click-loading")
  s.box(1).click()
  assert.equal(s.box(1).checked, true)
  assert.equal(s.tr(1).getAttribute("aria-selected"), "true")
  await flush()
  assert.equal(s.box(1).checked, true, "pending: the optimistic state stays")
  s.server(["1"])
  s.box(1).classList.remove("phx-click-loading")
  await flush()
  assert.equal(s.box(1).checked, true)
  assert.equal(s.tr(1).getAttribute("aria-selected"), "true")
  s.t.destroyed()
})

test("a refusal (the list does not change) undoes the click", {skip}, async () => {
  const s = setup()
  s.box(2).classList.add("phx-click-loading")
  s.box(2).click()
  s.box(2).classList.remove("phx-click-loading")
  await flush()
  assert.equal(s.box(2).checked, false)
  assert.equal(s.tr(2).getAttribute("aria-selected"), "false")
  s.t.destroyed()
})

test("a row inserted later is born with the right state", {skip}, async () => {
  const s = setup(["4", "1"])
  s.table.querySelector("tbody").insertAdjacentHTML("beforeend", row(4) + row(5))
  await flush()
  assert.equal(s.box(4).checked, true)
  assert.equal(s.tr(4).getAttribute("aria-selected"), "true")
  assert.equal(s.box(5).checked, false)
  assert.equal(s.box(1).checked, true)
  s.t.destroyed()
})

test("a patch that resets a box without a mutation is undone by `updated`", {skip}, () => {
  const s = setup(["2"])
  assert.equal(s.box(2).checked, true)
  s.box(2).checked = false // what morphdom does to an input of a re-rendered row
  s.t.updated()
  assert.equal(s.box(2).checked, true)
  assert.equal(s.tr(2).getAttribute("aria-selected"), "true")
  s.t.destroyed()
})

test("the event carries count, delta (against the list) and ids", {skip}, () => {
  const s = setup(["1"])
  const seen = []
  document.addEventListener("lu:selection", e => seen.push(e.detail))
  s.box(3).click()
  assert.deepEqual(seen.at(-1), {id: "t", count: 2, delta: 1, ids: ["1", "3"]})
  s.t.destroyed()
})

test("a table without data-lu-selected keeps the markup as its baseline and sends nothing of its own", {skip}, () => {
  document.body.innerHTML = `<table id="t" data-lu-select data-lu-sel-class="${SEL}"><tbody>${row(1)}</tbody></table>`
  const t = Object.assign(Object.create(TableSelect), {el: document.getElementById("t")}); t.mounted()
  const b = document.querySelector("input")
  b.click()
  assert.equal(b.getAttribute("phx-value-selected"), "true")
  t.updated()
  assert.equal(b.checked, true, "`updated` does nothing in server mode")
  t.destroyed()
})

// The header box of a stream is made from the rows of the page (#100): the server's markup of it
// cannot know them.
test("the header box is indeterminate with some rows selected, checked with all, off with none", {skip}, async () => {
  const s = setup()
  const head = () => document.getElementById("t-select-all")
  const state = () => (head().indeterminate ? "indeterminate" : head().checked ? "checked" : "off")
  assert.equal(state(), "off")
  s.server(["2"])
  await flush()
  assert.equal(state(), "indeterminate")
  s.server(["1", "2", "3"])
  await flush()
  assert.equal(state(), "checked")
  s.server(["1", "3"])
  await flush()
  assert.equal(state(), "indeterminate")
  s.server([])
  await flush()
  assert.equal(state(), "off")
  s.t.destroyed()
})

test("the header box follows a click on a row, the round trip and a row inserted afterwards", {skip}, async () => {
  const s = setup()
  const head = document.getElementById("t-select-all")
  s.box(1).click()
  assert.equal(head.indeterminate, true, "right at the click")
  s.server(["1"])
  await flush()
  assert.equal(head.indeterminate, true, "after the server answered")
  head.click()
  assert.equal(head.checked, true)
  assert.equal(head.indeterminate, false)
  s.server(["1", "2", "3"])
  await flush()
  assert.equal(head.checked, true)
  document.getElementById("b").insertAdjacentHTML("afterbegin", row(9))
  await flush()
  assert.equal(head.checked, false, "a new unselected row: not all")
  assert.equal(head.indeterminate, true)
  s.t.destroyed()
})

test("mounted: a partial list from the server already shows the header as indeterminate", {skip}, () => {
  const s = setup(["3"])
  assert.equal(document.getElementById("t-select-all").indeterminate, true)
  s.t.destroyed()
})
