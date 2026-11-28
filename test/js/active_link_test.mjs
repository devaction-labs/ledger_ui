// LedgerUI.ActiveLink: the active item of a menu follows location.pathname on the client.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/active_link_test.mjs
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

let hook, matchLength, w
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/items"})
  w = dom.window
  Object.assign(globalThis, {window: w, document: w.document})
  const mod = await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/active_link.js")))
  hook = mod.default
  matchLength = mod.matchLength
}

const MENU = `<nav id="m" data-lu-active-class="on bold" data-lu-inactive-class="off">
  <a id="home" class="off" data-lu-match="/">Home</a>
  <a id="items" class="off" data-lu-match="/items">Items</a>
  <a id="new" class="off" data-lu-match="/items/new">New</a>
  <a id="plain" class="off">No match</a>
</nav>`

function mount(html = MENU) {
  document.body.innerHTML = html
  const el = document.getElementById("m")
  const h = Object.assign(Object.create(hook), {el})
  h.mounted()
  return h
}
const go = (path) => w.history.pushState({}, "", path)
const state = () => Object.fromEntries([...document.querySelectorAll("#m a")].map((a) => [a.id, a.getAttribute("aria-current") === "page" ? "on" : "-"]))

test("matchLength: the path, a prefix on a segment boundary, and \"/\" only for the root", {skip}, () => {
  assert.equal(matchLength("/items", "/items"), 6)
  assert.equal(matchLength("/items/3", "/items"), 6)
  assert.equal(matchLength("/items/3", "/items/"), 6)
  assert.equal(matchLength("/items-2", "/items"), -1)
  assert.equal(matchLength("/items", "/items/new"), -1)
  assert.equal(matchLength("/", "/"), 1)
  assert.equal(matchLength("/items", "/"), -1)
  assert.equal(matchLength("/items", null), -1)
})

test("mount marks the item of the current path and gives it the active classes", {skip}, () => {
  go("/items")
  mount()
  assert.deepEqual(state(), {home: "-", items: "on", new: "-", plain: "-"})
  const items = document.getElementById("items")
  assert.equal(items.className, "on bold")
  assert.equal(document.getElementById("new").className, "off")
})

test("the longest prefix wins", {skip}, () => {
  go("/items/new")
  mount()
  assert.deepEqual(state(), {home: "-", items: "-", new: "on", plain: "-"})
  go("/items/42/edit")
  mount()
  assert.deepEqual(state(), {home: "-", items: "on", new: "-", plain: "-"})
})

test("no item matches: nothing is marked", {skip}, () => {
  go("/other")
  mount()
  assert.deepEqual(state(), {home: "-", items: "-", new: "-", plain: "-"})
  go("/")
  mount()
  assert.equal(state().home, "on")
})

test("phx:page-loading-stop and popstate move the mark; destroyed removes the listeners", {skip}, () => {
  go("/items")
  const h = mount()
  go("/items/new")
  w.dispatchEvent(new w.Event("phx:page-loading-stop"))
  assert.equal(state().new, "on")
  assert.equal(state().items, "-")
  assert.equal(document.getElementById("items").className, "off")
  go("/items")
  w.dispatchEvent(new w.Event("popstate"))
  assert.equal(state().items, "on")
  h.destroyed()
  go("/items/new")
  w.dispatchEvent(new w.Event("phx:page-loading-stop"))
  w.dispatchEvent(new w.Event("popstate"))
  assert.equal(state().items, "on", "no listener left")
})

test("updated() puts the mark back after the server patched the items", {skip}, () => {
  go("/items")
  const h = mount()
  const a = document.getElementById("items")
  a.className = "off" // the patch resets the class and the aria-current the server rendered
  a.removeAttribute("aria-current")
  h.updated()
  assert.equal(a.className, "on bold")
  assert.equal(a.getAttribute("aria-current"), "page")
})

test("without data-lu-inactive-class only the active classes are toggled", {skip}, () => {
  go("/items")
  mount(`<nav id="m" data-lu-active-class="on"><a id="items" data-lu-match="/items">I</a><a id="new" data-lu-match="/items/new">N</a></nav>`)
  assert.equal(document.getElementById("items").className, "on")
  go("/items/new")
  w.dispatchEvent(new w.Event("popstate"))
  assert.equal(document.getElementById("items").className, "")
  assert.equal(document.getElementById("new").className, "on")
})
