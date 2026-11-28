// Regressions of theme_switch (matchMedia listener), treeview (rows without id) and sidebar (mobile burger) in jsdom.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/hooks_leaks_test.mjs
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

let theme, tree, sidebar
const mqls = new Set() // every MediaQueryList handed out, to count the listeners still attached
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/"})
  const w = dom.window
  // a fresh object per call, like a real browser's matchMedia
  w.matchMedia = () => {
    const ls = new Set()
    const m = {matches: false, ls, addEventListener: (_, f) => ls.add(f), removeEventListener: (_, f) => ls.delete(f)}
    mqls.add(m)
    return m
  }
  const store = {}
  Object.defineProperty(w, "localStorage", {value: {getItem: (k) => (k in store ? store[k] : null), setItem: (k, v) => { store[k] = String(v) }}})
  Object.assign(globalThis, {window: w, document: w.document, MutationObserver: w.MutationObserver, Event: w.Event, localStorage: w.localStorage, CSS: {escape: (s) => s}})
  const load = async (name) => (await import(pathToFileURL(join(here, `../../priv/static/ledger_ui/hooks/${name}.js`)))).default
  theme = await load("theme_switch")
  tree = await load("treeview")
  sidebar = await load("sidebar")
}

const instance = (hook, el, extra = {}) => Object.assign(Object.create(hook), {el, pushEvent() {}, pushEventTo() {}, ...extra})

test("theme_switch: destroyed removes the matchMedia listener it added (10 cycles leave none)", {skip}, () => {
  mqls.clear()
  for (let i = 0; i < 10; i++) {
    document.body.innerHTML = '<div id="ts" data-lu-variant="toggle"></div>'
    const h = instance(theme, document.getElementById("ts"))
    h.mounted()
    h.destroyed()
  }
  const left = [...mqls].reduce((n, m) => n + m.ls.size, 0)
  assert.equal(left, 0)
})

test("treeview: updated with rows without id does not throw and keeps the branch the person opened", {skip}, async () => {
  document.body.innerHTML = ""
  const el = document.createElement("div")
  el.id = "tree"
  const r = (label, branch) =>
    `<div data-part="tree-item" role="treeitem" tabindex="-1"${branch ? ' aria-expanded="false"' : ""}>` +
    (branch ? '<span data-part="tree-chevron"><svg data-icon="chevron-right"></svg></span>' : "") + `${label}</div>`
  el.innerHTML = r("Fiscal", true) + '<div data-part="tree-children">' + r("NF-e") + "</div>" + r("Financeiro", true) + '<div data-part="tree-children"></div>'
  document.body.appendChild(el)
  const h = instance(tree, el)
  h.mounted()
  const kids = el.querySelector("[data-part=tree-children]")
  assert.equal(kids.hidden, true)
  el.querySelector("[data-part=tree-item]").click()
  assert.equal(kids.hidden, false)
  el.setAttribute("data-tick", "1") // the root's own attribute is ignored: touch a row, as a patch would
  el.querySelectorAll("[data-part=tree-item]")[2].setAttribute("data-x", "1")
  await Promise.resolve()
  assert.doesNotThrow(() => h.updated())
  assert.equal(kids.hidden, false)
})

function mountSidebar(extra = "") {
  document.body.innerHTML = `<aside id="sb" data-lu-burger-class="md:hidden" data-lu-mobile-label="Menu" ${extra}><nav><a data-lu-sb-item>x</a></nav></aside>`
  const el = document.getElementById("sb")
  const h = instance(sidebar, el)
  h.mounted()
  return {el, h}
}

test("sidebar: the mobile burger is put back by updated after a patch removed it", {skip}, () => {
  const {el, h} = mountSidebar()
  assert.ok(el.querySelector("[data-lu-sb-burger]"))
  el.querySelector("[data-lu-sb-burger]").remove() // what morphdom does to a node the server never rendered
  h.updated()
  const b = el.querySelector("[data-lu-sb-burger]")
  assert.ok(b)
  assert.equal(el.firstChild, b)
  assert.equal(b.className, "md:hidden")
  assert.equal(b.getAttribute("aria-expanded"), "false")
  b.click()
  assert.ok(el.hasAttribute("data-mobile-open"))
  assert.equal(b.getAttribute("aria-expanded"), "true")
})

test("sidebar: updated keeps a single burger and aria-expanded follows the open menu", {skip}, () => {
  const {el, h} = mountSidebar()
  el.setAttribute("data-mobile-open", "")
  el.querySelector("[data-lu-sb-burger]").setAttribute("aria-expanded", "false") // stale after a patch
  h.updated()
  assert.equal(el.querySelectorAll("[data-lu-sb-burger]").length, 1)
  assert.equal(el.querySelector("[data-lu-sb-burger]").getAttribute("aria-expanded"), "true")
})
