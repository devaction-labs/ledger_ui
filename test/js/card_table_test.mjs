// The card_table hook in a jsdom document: the details panel with `row_groups` (a <tbody> per row,
// hook on the <table>) and the copy toast.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/card_table_test.mjs
// jsdom is not a dependency of the package: the tests are skipped when it cannot be found.
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

let hook, win
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true})
  win = dom.window
  Object.assign(globalThis, {window: win, document: win.document, HTMLElement: win.HTMLElement, CustomEvent: win.CustomEvent})
  Object.defineProperty(globalThis, "navigator", {value: {clipboard: {writeText: async () => {}}}, configurable: true})
  win.isSecureContext = true
  globalThis.isSecureContext = true
  const dir = mkdtempSync(join(tmpdir(), "lu-ct-"))
  // the hook imports ../lib/table_select.js: both go to a temp dir as .mjs
  const base = join(here, "../../priv/static/ledger_ui")
  writeFileSync(join(dir, "table_select.mjs"), readFileSync(join(base, "lib/table_select.js"), "utf8"))
  writeFileSync(join(dir, "card_table.mjs"), readFileSync(join(base, "hooks/card_table.js"), "utf8").replaceAll("../lib/table_select.js", "./table_select.mjs"))
  hook = (await import(pathToFileURL(join(dir, "card_table.mjs")))).default
}

const flush = () => new Promise((r) => setTimeout(r, 0))
const mount = (el) => {
  const h = Object.assign(Object.create(hook), {el})
  h.mounted()
  return h
}

test("row_groups: rows are owned through their <tbody>, the hook is on the <table>", {skip}, () => {
  document.body.innerHTML = `<table id="t"><thead><tr><th>a</th></tr></thead>
    <tbody id="g1"><tr id="g1-row" data-ct-row><td>1</td></tr><tr id="g1-panel" data-part="table-panel-row" hidden><td></td></tr></tbody>
    <tbody id="g2"><tr id="g2-row" data-ct-row><td>2</td></tr></tbody></table>`
  const h = mount(document.getElementById("t"))
  const rows = h.rows()
  assert.deepEqual(rows.map((r) => r.id), ["g1-row", "g2-row"])
  assert.ok(h.owns(rows[0]))
  assert.equal(h.panelOf(rows[0]).id, "g1-panel")
  assert.equal(h.panelOf(rows[1]), null)
  h.destroyed()
})

test("single <tbody>: the rows are its children", {skip}, () => {
  document.body.innerHTML = `<table><tbody id="b"><tr id="r1" data-ct-row></tr><tr data-part="table-panel-row" hidden></tr></tbody>
    <tbody><tr id="other" data-ct-row></tr></tbody></table>`
  const h = mount(document.getElementById("b"))
  assert.deepEqual(h.rows().map((r) => r.id), ["r1"])
  h.destroyed()
})

const copyTable = (toast) => {
  document.body.innerHTML = `<div phx-hook="LedgerUI.Toaster" id="toaster"></div>
    <table><tbody id="b"><tr data-ct-row><td><button data-lu-ct-copy="PUB-1"${toast ? ` data-lu-ct-toast="${toast}"` : ""}></button></td></tr></tbody></table>`
  const events = []
  document.getElementById("toaster").addEventListener("ledger:toast", (e) => events.push(e.detail))
  const h = mount(document.getElementById("b"))
  return {h, events, btn: document.querySelector("button")}
}

test("a copy with data-lu-ct-toast sends ledger:toast to the toaster", {skip}, async () => {
  const {h, events, btn} = copyTable("**PUB-1** copiado")
  btn.click()
  await flush(); await flush()
  assert.deepEqual(events, [{op: "show", message: "**PUB-1** copiado", kind: "success"}])
  assert.ok(btn.hasAttribute("data-copied"))
  h.destroyed()
})

test("a copy without data-lu-ct-toast shows no toast", {skip}, async () => {
  const {h, events, btn} = copyTable(null)
  btn.click()
  await flush(); await flush()
  assert.deepEqual(events, [])
  assert.ok(btn.hasAttribute("data-copied"))
  h.destroyed()
})

test("a failed copy shows no toast", {skip}, async () => {
  const {h, events, btn} = copyTable("m")
  const prev = navigator.clipboard.writeText
  navigator.clipboard.writeText = async () => { throw new Error("denied") }
  btn.click()
  await flush(); await flush()
  navigator.clipboard.writeText = prev
  assert.deepEqual(events, [])
  assert.ok(!btn.hasAttribute("data-copied"))
  h.destroyed()
})
