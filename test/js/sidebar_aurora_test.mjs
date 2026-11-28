// LedgerUI.Sidebar, format="aurora" (collapse, persistence, Ctrl/Cmd+B, peek, submenu, keys) and the
// `data-lu-when="collapsed"` mode of LedgerUI.RailPreview, in jsdom.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/sidebar_aurora_test.mjs
import {test} from "node:test"
import assert from "node:assert/strict"
import {createRequire} from "node:module"
import {pathToFileURL, fileURLToPath} from "node:url"
import {dirname, join} from "node:path"

const here = dirname(fileURLToPath(import.meta.url))
const require = createRequire(import.meta.url)

let JSDOM
for (const p of [process.env.JSDOM_PATH, "jsdom"].filter(Boolean)) {
  try { ({JSDOM} = require(p)); break } catch (_) { /* try the next */ }
}
const skip = JSDOM ? false : (process.env.CI === "true" || process.env.CI === "1" ? (() => { throw new Error("jsdom not found and CI is set: run `npm install` (or set JSDOM_PATH)") })() : "jsdom not found (run `npm install` or set JSDOM_PATH)")

let Sidebar, Preview, w
const docListeners = new Map()
const winListeners = new Map()
let timers = []
const store = {}
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/"})
  w = dom.window
  w.matchMedia = () => ({matches: false, addEventListener() {}, removeEventListener() {}})
  Object.defineProperty(w, "localStorage", {value: {getItem: (k) => (k in store ? store[k] : null), setItem: (k, v) => { store[k] = String(v) }}})
  Object.assign(globalThis, {window: w, document: w.document, localStorage: w.localStorage, CSS: {escape: (s) => s}, CustomEvent: w.CustomEvent})
  const track = (target, map) => {
    const add = target.addEventListener.bind(target)
    const remove = target.removeEventListener.bind(target)
    target.addEventListener = (t, f, ...r) => { (map.get(t) || map.set(t, new Set()).get(t)).add(f); add(t, f, ...r) }
    target.removeEventListener = (t, f, ...r) => { (map.get(t) || new Set()).delete(f); remove(t, f, ...r) }
  }
  track(w.document, docListeners)
  track(w, winListeners)
  // a fake clock: the hook's delays (peek 300, submenu close 150, preview 150) are run by `tick`
  globalThis.setTimeout = (fn, ms) => { const t = {fn, ms, live: true}; timers.push(t); return t }
  globalThis.clearTimeout = (t) => { if (t) t.live = false }
  const load = async (n) => (await import(pathToFileURL(join(here, `../../priv/static/ledger_ui/hooks/${n}.js`)))).default
  Sidebar = await load("sidebar")
  Preview = await load("rail_preview")
}

const pending = () => timers.filter((t) => t.live)
const tick = () => { const due = pending(); timers = []; due.forEach((t) => { t.live = false; t.fn() }) }
const count = (map) => [...map.values()].reduce((n, s) => n + s.size, 0)

const html = (attrs = "") => `
<aside id="nav" data-lu-format="aurora" data-lu-collapsed="false" data-lu-persist="true" data-lu-shortcut="b" data-lu-groups="true"
  data-lu-burger-class="hidden" data-lu-mobile-label="Menu" ${attrs}>
  <div data-part="sidebar-aurora">
    <button id="tog" data-lu-sb-toggle aria-label="Collapse"></button>
    <button id="search" data-lu-au-nav>Search</button>
    <nav id="nav-nav" phx-hook="LedgerUI.RailPreview" data-lu-when="collapsed" data-lu-delay="150">
      <div data-part="sidebar-aurora-nav">
        <a id="home" href="/" data-lu-au-item data-lu-au-nav data-rail-item aria-describedby="pv-home"><span data-lu-au-label>Home</span></a>
        <a id="plain" href="/p" data-lu-au-item data-lu-au-nav><span data-lu-au-label>Plain</span></a>
        <button id="g-sales" data-lu-sb-group="Sales" data-lu-au-nav aria-expanded="true" aria-controls="b-sales"></button>
        <div id="b-sales" data-lu-au-body>
          <button id="orders" type="button" data-lu-au-item data-lu-au-nav data-lu-sb-parent="Orders" data-lu-au-kids="k-orders" data-lu-au-menu="m-orders" aria-expanded="true" aria-controls="k-orders">Orders</button>
          <div id="k-orders" data-lu-au-body>
            <a id="c1" href="/p1" data-lu-au-nav data-lu-au-of="Orders">Proposals</a>
            <a id="c2" href="/p2" data-lu-au-nav data-lu-au-of="Orders">Contracts</a>
          </div>
          <a id="rep" href="/r" data-lu-au-item data-lu-au-nav>Reports</a>
        </div>
        <button id="g-admin" data-lu-sb-group="Admin" data-lu-au-nav aria-expanded="true" aria-controls="b-admin"></button>
        <div id="b-admin" data-lu-au-body><a id="team" href="/t" data-lu-au-item data-lu-au-nav>Team</a></div>
        <div id="pv-home" role="tooltip" data-lu-rail-preview><b>Home</b></div>
        <div id="m-orders" role="menu" data-lu-au-menu-box>
          <div>Orders</div>
          <a id="mi1" role="menuitem" tabindex="-1" href="/p1">Proposals</a>
          <a id="mi2" role="menuitem" tabindex="-1" href="/p2">Contracts</a>
        </div>
      </div>
    </nav>
  </div>
</aside>`

function mount(attrs = "", {saved} = {}) {
  timers = []
  for (const k of Object.keys(store)) delete store[k]
  if (saved) Object.assign(store, saved)
  document.documentElement.removeAttribute("data-collapsed")
  document.body.innerHTML = html()
  const el = document.getElementById("nav")
  // `attrs` are written over the markup's own, as the server would have rendered them
  for (const m of attrs.matchAll(/([\w-]+)="([^"]*)"/g)) el.setAttribute(m[1], m[2])
  const pushed = []
  const mk = (H, node) => Object.assign(Object.create(H), {el: node, pushEvent: (e, p) => pushed.push([e, p]), pushEventTo() {}})
  const h = mk(Sidebar, el)
  const p = mk(Preview, document.getElementById("nav-nav"))
  h.mounted()
  p.mounted()
  return {el, h, p, pushed, root: document.documentElement}
}

const $ = (id) => document.getElementById(id)
const over = (el) => el.dispatchEvent(new w.MouseEvent("mouseover", {bubbles: true}))
const move = (el) => el.dispatchEvent(new w.MouseEvent("mousemove", {bubbles: true}))
const leave = (el) => el.dispatchEvent(new w.MouseEvent("mouseleave"))
const key = (el, k, extra = {}) => { const e = new w.KeyboardEvent("keydown", {key: k, bubbles: true, cancelable: true, ...extra}); el.dispatchEvent(e); return e }
const collapse = (ctx) => $("tog").click() || ctx

test("toggle: collapses with no server trip, on the menu and on <html>, saved, pushed", {skip}, () => {
  const ctx = mount('data-lu-on-collapse="saved"')
  assert.equal(ctx.el.hasAttribute("data-collapsed"), false)
  assert.equal(ctx.root.hasAttribute("data-collapsed"), false)
  $("tog").click()
  assert.equal(ctx.el.hasAttribute("data-collapsed"), true)
  assert.equal(ctx.root.hasAttribute("data-collapsed"), true)
  assert.equal(store["ledger-rail"], "1")
  assert.equal($("tog").getAttribute("aria-pressed"), "true")
  assert.deepEqual(ctx.pushed, [["saved", {id: "nav", collapsed: true}]])
  $("tog").click()
  assert.equal(ctx.el.hasAttribute("data-collapsed"), false)
  assert.equal(ctx.root.hasAttribute("data-collapsed"), false)
  assert.equal(store["ledger-rail"], "0")
})

test("restore: the saved choice is applied on mount (menu and <html>)", {skip}, () => {
  const ctx = mount("", {saved: {"ledger-rail": "1"}})
  assert.equal(ctx.el.hasAttribute("data-collapsed"), true)
  assert.equal(ctx.root.hasAttribute("data-collapsed"), true)
})

test("restore: persist=false ignores what was saved and saves nothing", {skip}, () => {
  const ctx = mount('data-lu-persist="false"', {saved: {"ledger-rail": "1"}})
  assert.equal(ctx.el.hasAttribute("data-collapsed"), false)
  $("tog").click()
  assert.equal(store["ledger-rail"], "1") // untouched (it was the earlier value)
  assert.equal(ctx.el.hasAttribute("data-collapsed"), true)
})

test("Ctrl+B and Cmd+B toggle; not while typing; another letter does nothing", {skip}, () => {
  const ctx = mount()
  key(w, "b", {ctrlKey: true})
  assert.equal(ctx.el.hasAttribute("data-collapsed"), true)
  key(w, "B", {metaKey: true})
  assert.equal(ctx.el.hasAttribute("data-collapsed"), false)
  key(w, "j", {ctrlKey: true})
  assert.equal(ctx.el.hasAttribute("data-collapsed"), false)
  const input = document.createElement("input")
  document.body.appendChild(input)
  input.dispatchEvent(new w.KeyboardEvent("keydown", {key: "b", ctrlKey: true, bubbles: true}))
  assert.equal(ctx.el.hasAttribute("data-collapsed"), false)
})

test("groups: the title opens and closes (data-closed, aria-expanded) and it is remembered and restored", {skip}, () => {
  let ctx = mount()
  $("g-sales").click()
  assert.equal($("b-sales").hasAttribute("data-closed"), true)
  assert.equal($("g-sales").getAttribute("aria-expanded"), "false")
  assert.equal($("b-sales").hasAttribute("hidden"), false)
  assert.deepEqual(JSON.parse(store["ledger-sidebar-groups:nav"]), {Sales: false})
  $("g-sales").click()
  assert.equal($("b-sales").hasAttribute("data-closed"), false)
  $("g-admin").click()
  const saved = {"ledger-sidebar-groups:nav": store["ledger-sidebar-groups:nav"]}
  ctx = mount("", {saved})
  assert.equal($("b-admin").hasAttribute("data-closed"), true)
  assert.equal($("g-admin").getAttribute("aria-expanded"), "false")
  assert.equal($("b-sales").hasAttribute("data-closed"), false)
})

test("parent: the children open and close; collapsed state keeps its own truth", {skip}, () => {
  mount()
  $("orders").click()
  assert.equal($("k-orders").hasAttribute("data-closed"), true)
  assert.equal($("orders").getAttribute("aria-expanded"), "false")
  $("orders").click()
  assert.equal($("k-orders").hasAttribute("data-closed"), false)
  assert.equal($("orders").getAttribute("aria-expanded"), "true")
})

test("collapsed: the parent owns a menu (aria-haspopup, aria-controls) and goes back to a disclosure when expanded", {skip}, () => {
  const ctx = mount("", {saved: {"ledger-rail": "1"}})
  assert.equal($("orders").getAttribute("aria-haspopup"), "menu")
  assert.equal($("orders").getAttribute("aria-controls"), "m-orders")
  assert.equal($("orders").getAttribute("aria-expanded"), "false")
  $("tog").click()
  assert.equal($("orders").hasAttribute("aria-haspopup"), false)
  assert.equal($("orders").getAttribute("aria-controls"), "k-orders")
  assert.equal($("orders").getAttribute("aria-expanded"), "true")
  assert.ok(ctx.el)
})

test("collapsed: items without a card get a native title, removed when expanded", {skip}, () => {
  mount("", {saved: {"ledger-rail": "1"}})
  assert.equal($("plain").getAttribute("title"), "Plain")
  assert.equal($("home").hasAttribute("title"), false) // has a preview card
  $("tog").click()
  assert.equal($("plain").hasAttribute("title"), false)
})

test("submenu: hover opens and places it, leaving closes after 150ms, hovering the menu keeps it", {skip}, () => {
  mount("", {saved: {"ledger-rail": "1"}})
  over($("orders"))
  assert.equal($("m-orders").hasAttribute("data-open"), true)
  assert.equal($("orders").getAttribute("aria-expanded"), "true")
  assert.ok($("m-orders").style.left !== "")
  over($("rep")) // moves to another item: a close is due, not immediate
  assert.equal($("m-orders").hasAttribute("data-open"), true)
  over($("mi1")) // reached the menu in time
  tick()
  assert.equal($("m-orders").hasAttribute("data-open"), true)
  leave($("nav"))
  tick()
  assert.equal($("m-orders").hasAttribute("data-open"), false)
  assert.equal($("orders").getAttribute("aria-expanded"), "false")
})

test("submenu: not while expanded; focus opens it collapsed; focus elsewhere closes", {skip}, () => {
  const ctx = mount()
  over($("orders"))
  assert.equal($("m-orders").hasAttribute("data-open"), false)
  $("tog").click()
  $("orders").focus()
  assert.equal($("m-orders").hasAttribute("data-open"), true)
  $("plain").focus()
  assert.equal($("m-orders").hasAttribute("data-open"), false)
  assert.ok(ctx.el)
})

test("submenu: a click on a collapsed parent button opens it; expanding closes it", {skip}, () => {
  mount("", {saved: {"ledger-rail": "1"}})
  $("orders").click()
  assert.equal($("m-orders").hasAttribute("data-open"), true)
  assert.equal($("k-orders").hasAttribute("data-closed"), false) // the disclosure was not touched
  $("tog").click()
  assert.equal($("m-orders").hasAttribute("data-open"), false)
})

test("Esc closes the submenu (focus back on the parent) and a preview", {skip}, () => {
  const ctx = mount("", {saved: {"ledger-rail": "1"}})
  over($("orders"))
  $("mi1").focus()
  key($("mi1"), "Escape")
  assert.equal($("m-orders").hasAttribute("data-open"), false)
  assert.equal(document.activeElement, $("orders"))
  // a preview card
  over($("home"))
  tick()
  assert.equal($("pv-home").hasAttribute("data-open"), true)
  key($("home"), "Escape")
  assert.equal($("pv-home").hasAttribute("data-open"), false)
  assert.ok(ctx.el)
})

test("peek: a pointer that rests for 300ms opens the whole menu over the page; leaving closes it", {skip}, () => {
  const ctx = mount('data-lu-peek="true" data-lu-peek-delay="300"', {saved: {"ledger-rail": "1"}})
  move($("home"))
  assert.equal(pending().find((t) => t.ms === 300) !== undefined, true)
  assert.equal(ctx.el.hasAttribute("data-peek"), false)
  tick()
  assert.equal(ctx.el.hasAttribute("data-peek"), true)
  assert.equal(ctx.el.hasAttribute("data-collapsed"), false) // drawn expanded
  assert.equal(ctx.root.hasAttribute("data-collapsed"), false)
  assert.equal(store["ledger-rail"], "1") // the choice is still collapsed
  leave(ctx.el)
  assert.equal(ctx.el.hasAttribute("data-peek"), false)
  assert.equal(ctx.el.hasAttribute("data-collapsed"), true)
  assert.equal(ctx.root.hasAttribute("data-collapsed"), true)
})

test("peek: moving restarts the wait; leaving before it cancels it; nothing without the option or when expanded", {skip}, () => {
  let ctx = mount('data-lu-peek="true"', {saved: {"ledger-rail": "1"}})
  move($("home"))
  const first = pending().find((t) => t.ms === 300)
  move($("plain"))
  assert.equal(first.live, false)
  leave(ctx.el)
  assert.equal(pending().filter((t) => t.ms === 300).length, 0)
  tick()
  assert.equal(ctx.el.hasAttribute("data-peek"), false)

  ctx = mount("", {saved: {"ledger-rail": "1"}}) // no peek
  move($("home"))
  tick()
  assert.equal(ctx.el.hasAttribute("data-peek"), false)

  ctx = mount('data-lu-peek="true"') // expanded
  move($("home"))
  assert.equal(pending().filter((t) => t.ms === 300).length, 0)
})

test("peek: closes an open submenu and previews; the toggle ends it; Esc ends it", {skip}, () => {
  const ctx = mount('data-lu-peek="true"', {saved: {"ledger-rail": "1"}})
  over($("orders"))
  assert.equal($("m-orders").hasAttribute("data-open"), true)
  move($("orders"))
  tick() // the peek (the menu close is also due: both run)
  assert.equal(ctx.el.hasAttribute("data-peek"), true)
  assert.equal($("m-orders").hasAttribute("data-open"), false)
  $("tog").click() // expands for good
  assert.equal(ctx.el.hasAttribute("data-peek"), false)
  assert.equal(ctx.el.hasAttribute("data-collapsed"), false)
  $("tog").click() // collapses again
  move($("home"))
  tick()
  assert.equal(ctx.el.hasAttribute("data-peek"), true)
  key($("home"), "Escape")
  assert.equal(ctx.el.hasAttribute("data-peek"), false)
  assert.equal(ctx.el.hasAttribute("data-collapsed"), true)
})

test("preview (RailPreview, data-lu-when=collapsed): only collapsed; closes on ledger:preview-off", {skip}, () => {
  mount()
  over($("home"))
  tick()
  assert.equal($("pv-home").hasAttribute("data-open"), false) // expanded: no card
  $("tog").click()
  over($("home"))
  tick()
  assert.equal($("pv-home").hasAttribute("data-open"), true)
  $("nav-nav").dispatchEvent(new w.CustomEvent("ledger:preview-off"))
  assert.equal($("pv-home").hasAttribute("data-open"), false)
})

test("arrows: Down and Up walk the items (wrapping), skipping the closed group", {skip}, () => {
  mount()
  $("g-admin").click() // closed
  $("search").focus()
  key($("search"), "ArrowDown")
  assert.equal(document.activeElement, $("home"))
  key($("home"), "ArrowDown")
  assert.equal(document.activeElement, $("plain"))
  key($("plain"), "ArrowDown")
  assert.equal(document.activeElement, $("g-sales"))
  key($("g-sales"), "ArrowDown")
  assert.equal(document.activeElement, $("orders"))
  key($("orders"), "ArrowUp")
  assert.equal(document.activeElement, $("g-sales"))
  $("g-admin").focus()
  key($("g-admin"), "ArrowDown") // Team is inside the closed group: wraps to the first
  assert.equal(document.activeElement, $("search"))
  key($("search"), "ArrowUp")
  assert.equal(document.activeElement, $("g-admin"))
})

test("arrows: collapsed, the walk skips group titles and children", {skip}, () => {
  mount("", {saved: {"ledger-rail": "1"}})
  $("plain").focus()
  key($("plain"), "ArrowDown")
  assert.equal(document.activeElement, $("orders"))
  key($("orders"), "ArrowDown")
  assert.equal(document.activeElement, $("rep"))
})

test("arrows: Right opens a group and a parent, Left closes them, Left on a child goes to the parent", {skip}, () => {
  mount()
  $("g-sales").focus()
  key($("g-sales"), "ArrowRight") // already open: nothing
  assert.equal($("b-sales").hasAttribute("data-closed"), false)
  key($("g-sales"), "ArrowLeft")
  assert.equal($("b-sales").hasAttribute("data-closed"), true)
  key($("g-sales"), "ArrowRight")
  assert.equal($("b-sales").hasAttribute("data-closed"), false)
  key($("orders"), "ArrowLeft")
  assert.equal($("k-orders").hasAttribute("data-closed"), true)
  key($("orders"), "ArrowRight")
  assert.equal($("k-orders").hasAttribute("data-closed"), false)
  $("c2").focus()
  key($("c2"), "ArrowLeft")
  assert.equal(document.activeElement, $("orders"))
})

test("arrows: collapsed, Right on a parent opens the submenu on its first item; Down walks it; Left closes it", {skip}, () => {
  mount("", {saved: {"ledger-rail": "1"}})
  $("orders").focus()
  key($("orders"), "ArrowRight")
  assert.equal($("m-orders").hasAttribute("data-open"), true)
  assert.equal(document.activeElement, $("mi1"))
  key($("mi1"), "ArrowDown")
  assert.equal(document.activeElement, $("mi2"))
  key($("mi2"), "ArrowDown")
  assert.equal(document.activeElement, $("mi1"))
  key($("mi1"), "ArrowLeft")
  assert.equal($("m-orders").hasAttribute("data-open"), false)
  assert.equal(document.activeElement, $("orders"))
})

test("at rest: only the two listeners every format has on document and window; none for peek, submenu or arrows", {skip}, () => {
  docListeners.clear()
  winListeners.clear()
  const ctx = mount('data-lu-peek="true"')
  assert.deepEqual([...docListeners].filter(([, s]) => s.size).map(([t]) => t), ["click"])
  assert.deepEqual([...winListeners].filter(([, s]) => s.size).map(([t]) => t), ["keydown"])
  over($("orders"))
  $("tog").click()
  over($("orders"))
  assert.equal(count(docListeners), 1) // the submenu and the peek add none
  assert.equal(count(winListeners), 1)
  assert.ok(ctx.el)
})

test("destroyed: every listener, timer and the <html> mark go away", {skip}, () => {
  docListeners.clear()
  winListeners.clear()
  const ctx = mount('data-lu-peek="true"', {saved: {"ledger-rail": "1"}})
  over($("orders"))
  move($("home"))
  assert.ok(pending().length > 0)
  ctx.h.destroyed()
  ctx.p.destroyed()
  assert.equal(count(docListeners), 0)
  assert.equal(count(winListeners), 0)
  assert.equal(pending().length, 0)
  assert.equal(ctx.root.hasAttribute("data-collapsed"), false)
  assert.equal($("m-orders").hasAttribute("data-open"), false)
  // the element listeners are gone: nothing reacts any more
  ctx.el.hasAttribute("data-peek")
  move($("home"))
  assert.equal(pending().length, 0)
  over($("orders"))
  assert.equal($("m-orders").hasAttribute("data-open"), false)
})

test("updated: a patch that dropped what the client set puts the state and the open submenu back", {skip}, () => {
  const ctx = mount("", {saved: {"ledger-rail": "1"}})
  over($("orders"))
  $("m-orders").removeAttribute("data-open")
  $("m-orders").style.left = ""
  ctx.el.removeAttribute("data-collapsed")
  ctx.h.updated()
  assert.equal(ctx.el.hasAttribute("data-collapsed"), true)
  assert.equal($("m-orders").hasAttribute("data-open"), true)
  assert.ok($("m-orders").style.left !== "")
})
