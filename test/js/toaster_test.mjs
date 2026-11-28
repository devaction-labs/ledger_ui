// The toaster hook in a jsdom document: formats, queue, dedupe, progress, timers, flash.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/toaster_test.mjs
// jsdom is a devDependency (npm install): the tests are skipped when it cannot be found, and fail when CI=true.
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

// jsdom has no Web Animations: a toast's countdown is recorded here (its duration) and finished by hand.
const clocks = []
let hook
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "http://localhost/"})
  const w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, getComputedStyle: w.getComputedStyle.bind(w), requestAnimationFrame: w.requestAnimationFrame.bind(w)})
  w.Element.prototype.animate = function (_frames, opts) {
    const a = {duration: opts.duration, el: this, cancelled: false, paused: false, onfinish: null,
      cancel() { a.cancelled = true }, pause() { a.paused = true }, play() { a.paused = false }, finish() { a.onfinish && a.onfinish() }}
    clocks.push(a)
    return a
  }
  const dir = mkdtempSync(join(tmpdir(), "lu-toaster-"))
  writeFileSync(join(dir, "toaster.mjs"), readFileSync(join(here, "../../priv/static/ledger_ui/hooks/toaster.js"), "utf8"))
  hook = (await import(pathToFileURL(join(dir, "toaster.mjs")))).default
}

const CLS = {
  stoast: "stoast", msg: "msg", act: "act", act_ghost: "ghost", st_pct: "stpct", st_set: "stset", st_auto: "stauto", st_queue: "stqueue",
  st_liquid: "liquid", dot_ok: "dotok", dot_err: "doterr", dot_warn: "dotwarn", card: "card", light: "light", dark: "dark", fail: "fail", tile: "tile",
  tile_light: "tl", tile_dark: "td", body: "body", desc_light: "dl", desc_dark: "dd", close: "close", fill: "fill", fill_run: "fr",
  fill_done: "fd", pct: "pct", segs: "segs", seg: "seg", seg_done: "sd", seg_cur: "sc", counter: "counter", bar: "bar", bar_fill: "bf",
  wrap: "wrap", tile_filling: "filling", tile_fill: "tfill", icon: "icon", icon_sm: "is", icon_md: "im", spinner: "sp", spinner_tile: "spt",
  colors: {}, buttons: {}, stack: {kids: "kids", top: "top", bottom: "bottom"},
  aura: {base: "a", modes: {}, tones: {}, widths: {}, shadow: ""},
}

let seq = 0
// Mounts the hook on a toaster element; `data` are its `data-*` attributes.
function mount(data = {}) {
  document.body.innerHTML = ""
  clocks.length = 0
  const el = document.createElement("div")
  el.id = "ledger-toaster-" + ++seq
  el.dataset.pos = data.pos || "center-bottom"
  el.dataset.luCls = JSON.stringify(CLS)
  for (const [k, v] of Object.entries(data)) if (k !== "pos") el.dataset[k] = v
  el.innerHTML = '<div data-part="toast-stack"></div>'
  document.body.append(el)
  const handlers = {}
  const pushed = []
  const h = Object.assign(Object.create(hook), {
    el, pushed,
    handleEvent(name, fn) { handlers[name] = fn },
    pushEvent(e, p) { pushed.push([e, p]) },
    pushEventTo(t, e, p) { pushed.push([e, p, t]) },
  })
  h.mounted()
  return {h, el, handlers, pushed,
    toast: (id) => el.querySelector(`[data-toast-id="${id}"]`),
    ids: () => Array.from(el.querySelectorAll("[data-toast-id]")).map((n) => n.dataset.toastId),
    clock: (id) => clocks.filter((c) => c.el.closest("[data-toast-id]")?.dataset.toastId === id && !c.cancelled).pop()}
}

test("the status pill: no description, at most one action, **object** in bold", {skip}, () => {
  const t = mount()
  t.h.handle({op: "show", id: "a", title: "Imported **orders.csv**", kind: "status", actions: [{label: "Open", event: "open"}, {label: "Undo"}]})
  const pill = t.toast("a")
  assert.equal(pill.dataset.format, "status")
  assert.equal(pill.dataset.part, "status-toast")
  assert.equal(pill.querySelector("b").textContent, "orders.csv")
  assert.equal(pill.querySelectorAll("[data-part=toast-action]").length, 1)
  pill.querySelector("[data-part=toast-action]").click()
  assert.deepEqual(t.pushed, [["open", {toast_id: "a"}]])
})

test("the pill never runs raw HTML", {skip}, () => {
  const t = mount()
  t.h.handle({op: "show", id: "x", title: "<img src=x onerror=1> **<b>**"})
  assert.equal(t.toast("x").querySelector("img"), null)
})

test("the format is inferred: description or more than one action make a card", {skip}, () => {
  const t = mount({luStack: "false", luMaxVisible: "9"})
  t.h.handle({op: "show", id: "plain", title: "Saved", kind: "success"})
  t.h.handle({op: "show", id: "desc", title: "Saved", description: "3 rows", kind: "success"})
  t.h.handle({op: "show", id: "two", title: "Saved", actions: [{label: "A"}, {label: "B"}]})
  t.h.handle({op: "show", id: "one", title: "Saved", actions: [{label: "A"}]})
  t.h.handle({op: "show", id: "forced", title: "Saved", description: "d", kind: "status"})
  t.h.handle({op: "show", id: "forcedcard", title: "Saved", kind: "card"})
  const f = (id) => t.toast(id).dataset.format
  assert.deepEqual(["plain", "desc", "two", "one", "forced", "forcedcard"].map(f), ["status", "card", "card", "status", "status", "card"])
})

test("the card: description, several actions and a title with no **", {skip}, () => {
  const t = mount()
  t.h.handle({op: "show", id: "c", kind: "card", title: "Report **ready**", description: "12 pages", actions: [{label: "Open"}, {label: "Share"}]})
  const card = t.toast("c")
  assert.equal(card.querySelector("[data-part=toast-title]").textContent, "Report ready")
  assert.equal(card.querySelector("[data-part=toast-description]").textContent, "12 pages")
  assert.equal(card.querySelectorAll("[data-part=toast-action]").length, 2)
  assert.ok(card.querySelector("[data-part=toast-close]"), "a card closes")
})

test("progress: the pill fills and shows the %, the update moves it, 100 ends it", {skip}, () => {
  const t = mount()
  t.h.handle({op: "show", id: "p", title: "Importing", status: "run", progress: 20})
  const lead = () => t.toast("p").querySelector("[data-part=status-toast-lead]")
  assert.equal(lead().style.getPropertyValue("--lu-stp"), "20%")
  assert.equal(t.toast("p").querySelector("[data-part=status-toast-pct]").textContent, "20%")
  assert.equal(t.clock("p"), undefined, "a running toast has no countdown")
  t.h.handle({op: "update", id: "p", value: 64})
  assert.equal(t.ids().length, 1)
  assert.equal(t.toast("p").querySelector("[data-part=status-toast-pct]").textContent, "64%")
  assert.equal(t.toast("p").querySelector("[data-part=status-toast-msg]").textContent, "Importing", "update keeps the rest")
  t.h.handle({op: "update", id: "p", value: 100, status: "ok"})
  assert.ok(t.toast("p").querySelector("[data-part=status-toast-dot]"))
  assert.equal(t.clock("p").duration, 1600)
})

test("a card shows progress and steps", {skip}, () => {
  const t = mount()
  t.h.handle({op: "show", id: "s", kind: "card", title: "Sending", value: 40, steps: 4, step: 1})
  const c = t.toast("s")
  assert.equal(c.querySelector("[data-part=toast-pct]").textContent, "40%")
  assert.equal(c.querySelector("[data-part=toast-fill]").style.transform, "scaleX(0.4)")
  assert.equal(c.querySelectorAll("[data-part=toast-seg]").length, 4)
  assert.match(c.querySelector("[data-part=toast-title]").textContent, /1\/4/)
  assert.equal(t.clock("s"), undefined)
})

test("auto-dismiss: 5 s, 8 s with an action, none while it runs", {skip}, () => {
  const t = mount({luStack: "false", luMaxVisible: "9"})
  t.h.handle({op: "show", id: "a", title: "Done"})
  t.h.handle({op: "show", id: "b", title: "Done", actions: [{label: "Undo"}]})
  t.h.handle({op: "show", id: "c", title: "Working", kind: "loading"})
  t.h.handle({op: "show", id: "d", title: "Queued", status: "queue"})
  assert.equal(t.clock("a").duration, 5000)
  assert.equal(t.clock("b").duration, 8000)
  assert.equal(t.clock("c"), undefined)
  assert.equal(t.clock("d"), undefined)
  assert.ok(t.toast("d").querySelector("[data-part=status-toast-lead]").className.includes("stqueue"), "the queue ring")
  t.clock("a").finish()
  t.h.dismiss("a")
  assert.equal(t.h.toasts.has("a"), false)
})

test("the toaster's duration and a toast's own duration", {skip}, () => {
  const t = mount({luDuration: "3000"})
  t.h.handle({op: "show", id: "a", title: "x"})
  t.h.handle({op: "show", id: "b", title: "x", duration: 700})
  t.h.handle({op: "show", id: "c", title: "x", duration: "infinity"})
  assert.equal(t.clock("a").duration, 3000)
  assert.equal(t.clock("b").duration, 700)
  assert.equal(t.clock("c"), undefined)
})

test("an error or a warning card stays until closed (persist_errors)", {skip}, () => {
  const t = mount({luPersistErrors: "true"})
  t.h.handle({op: "show", id: "e", kind: "card", color: "error", title: "Failed", description: "x"})
  t.h.handle({op: "show", id: "w", kind: "card", color: "warning", title: "Careful", description: "x"})
  t.h.handle({op: "show", id: "i", kind: "card", color: "info", title: "FYI", description: "x"})
  assert.equal(t.clock("e"), undefined)
  assert.equal(t.clock("w"), undefined)
  assert.equal(t.clock("i").duration, 5000)
  t.toast("e").querySelector("[data-part=toast-close]").click()
  assert.equal(t.h.toasts.has("e"), false)
})

test("a stack shows max_visible toasts and queues the rest; a place freed lets the next in", {skip}, () => {
  const t = mount()
  for (const id of ["1", "2", "3", "4", "5"]) t.h.handle({op: "show", id, title: "n" + id})
  assert.deepEqual(t.ids(), ["1", "2", "3"])
  assert.equal(t.h.pending.size, 2)
  assert.equal(t.clock("4"), undefined, "a queued toast has no clock yet")
  t.h.handle({op: "dismiss", id: "2"})
  assert.deepEqual(t.ids().filter((id) => t.h.toasts.has(id)), ["1", "3", "4"])
  assert.equal(t.clock("4").duration, 5000, "its clock starts when it comes in")
  t.h.handle({op: "dismiss", id: "5"}) // dismissing a queued toast drops it
  assert.equal(t.h.pending.size, 0)
})

test("max_visible is the toaster's, never above the three blades", {skip}, () => {
  const two = mount({luMaxVisible: "2"})
  for (const id of ["1", "2", "3"]) two.h.handle({op: "show", id, title: id})
  assert.deepEqual(two.ids(), ["1", "2"])
  const nine = mount({luMaxVisible: "9"})
  for (const id of ["1", "2", "3", "4"]) nine.h.handle({op: "show", id, title: id})
  assert.equal(nine.ids().length, 3)
  const flat = mount({luMaxVisible: "5", luStack: "false"})
  for (const id of ["1", "2", "3", "4", "5", "6"]) flat.h.handle({op: "show", id, title: id})
  assert.equal(flat.ids().length, 5)
})

test("clear empties the stack and the queue", {skip}, () => {
  const t = mount()
  for (const id of ["1", "2", "3", "4"]) t.h.handle({op: "show", id, title: id})
  t.h.handle({op: "clear"})
  assert.equal(t.h.toasts.size, 0)
  assert.equal(t.h.pending.size, 0)
})

test("dedupe: the same id updates the toast, in view or queued", {skip}, () => {
  const t = mount()
  t.h.handle({op: "show", id: "a", title: "First"})
  t.h.handle({op: "show", id: "a", title: "Second"})
  assert.equal(t.ids().length, 1)
  assert.equal(t.toast("a").textContent.includes("Second"), true)
  for (const id of ["b", "c", "q"]) t.h.handle({op: "show", id, title: id})
  t.h.handle({op: "show", id: "q", title: "Queued again"})
  t.h.handle({op: "update", id: "q", title: "Queued updated"})
  assert.equal(t.h.pending.size, 1)
  assert.equal(t.h.pending.get("q").data.title, "Queued updated")
})

test("update replace: swaps the whole toast, format included, and starts its clock", {skip}, () => {
  const t = mount()
  t.h.handle({op: "show", id: "w", title: "Working", kind: "loading", duration: "infinity", close: true})
  t.h.handle({op: "update", id: "w", replace: true, kind: "status", color: "success", title: "Sent"})
  assert.equal(t.toast("w").querySelector("[data-part=status-toast-msg]").textContent, "Sent")
  assert.equal(t.toast("w").querySelector("[data-part=status-toast-close]"), null)
  assert.equal(t.clock("w").duration, 5000)
  t.h.handle({op: "update", id: "w", replace: true, kind: "card", color: "success", title: "Sent", description: "all"})
  assert.equal(t.toast("w").dataset.format, "card")
  assert.equal(t.ids().length, 1)
})

test("an update of an unknown id opens the toast", {skip}, () => {
  const t = mount()
  t.h.handle({op: "update", id: "z", title: "New"})
  assert.deepEqual(t.ids(), ["z"])
})

test("position by format: the card goes to its own stack", {skip}, () => {
  const t = mount({luCardPosition: "right-top"})
  t.h.handle({op: "show", id: "s", title: "pill"})
  t.h.handle({op: "show", id: "c", title: "card", kind: "card"})
  t.h.handle({op: "show", id: "o", title: "own", position: "left-top"})
  const pos = (id) => t.toast(id).parentNode.dataset.pos
  assert.equal(pos("s"), undefined, "the pill stays in the toaster's stack")
  assert.equal(pos("c"), "right-top")
  assert.equal(pos("o"), "left-top")
  const stat = mount({luStatusPosition: "center-top"})
  stat.h.handle({op: "show", id: "s", title: "pill"})
  assert.equal(stat.toast("s").parentNode.dataset.pos, "center-top")
})

test("the max_visible of each stack is its own", {skip}, () => {
  const t = mount({luCardPosition: "right-top"})
  for (const id of ["1", "2", "3", "4"]) t.h.handle({op: "show", id, title: id})
  t.h.handle({op: "show", id: "c", title: "card", kind: "card"})
  assert.equal(t.ids().length, 4)
  assert.deepEqual(Array.from(t.h.pending.keys()), ["4"])
})

test("accessibility: status or alert by kind, with aria-live", {skip}, () => {
  const t = mount({luStack: "false", luMaxVisible: "9"})
  t.h.handle({op: "show", id: "i", title: "ok", kind: "info"})
  t.h.handle({op: "show", id: "e", title: "bad", kind: "error"})
  t.h.handle({op: "show", id: "w", title: "warn", kind: "card", color: "warning"})
  t.h.handle({op: "show", id: "c", title: "card", kind: "card", color: "success"})
  const a = (id) => [t.toast(id).getAttribute("role"), t.toast(id).getAttribute("aria-live")]
  assert.deepEqual(a("i"), ["status", "polite"])
  assert.deepEqual(a("e"), ["alert", "assertive"])
  assert.deepEqual(a("w"), ["alert", "assertive"])
  assert.deepEqual(a("c"), ["status", "polite"])
})

test("reduced motion: a toast leaves at once", {skip}, () => {
  const t = mount()
  window.matchMedia = () => ({matches: true})
  t.h.handle({op: "show", id: "a", title: "x"})
  const el = t.toast("a")
  t.h.dismiss("a")
  assert.equal(el.isConnected, false)
  window.matchMedia = undefined
})

test("transport: toast:* events (the server's push_event and the DOM) and ledger:toast", {skip}, () => {
  const t = mount()
  t.handlers["toast:show"]({id: "a", title: "pushed"})
  t.handlers["ledger:toast"]({op: "show", id: "b", title: "pushed"})
  t.el.dispatchEvent(new window.CustomEvent("toast:show", {detail: {id: "c", title: "dom"}}))
  t.el.dispatchEvent(new window.CustomEvent("ledger:toast", {detail: {op: "show", message: "Copied", kind: "success", id: "d"}}))
  assert.deepEqual(t.ids(), ["a", "b", "c"])
  assert.equal(t.h.pending.size, 1, "the fourth waits")
  t.handlers["toast:update"]({id: "a", title: "changed"})
  assert.ok(t.toast("a").textContent.includes("changed"))
  t.handlers["toast:dismiss"]({id: "a"})
  assert.equal(t.h.toasts.has("a"), false)
})

test("the clipboard contract: ledger:toast {op: show, message, kind}", {skip}, () => {
  const t = mount()
  t.el.dispatchEvent(new window.CustomEvent("ledger:toast", {detail: {op: "show", message: "Copied", kind: "success"}}))
  const [id] = t.ids()
  assert.ok(t.toast(id).textContent.includes("Copied"))
  assert.equal(t.toast(id).dataset.format, "status")
})

test("flash: shown once per key, again only if the key leaves and returns", {skip}, () => {
  const t = mount({luFlash: JSON.stringify([{title: "Saved", kind: "success", _k: "k1"}, {title: "Boom", kind: "error", _k: "k2"}])})
  assert.deepEqual(t.ids().length, 2)
  t.h.updated()
  assert.equal(t.ids().length, 2, "a patch with the same flash shows nothing new")
  t.el.dataset.luFlash = JSON.stringify([{title: "Next", _k: "k3"}])
  t.h.updated()
  assert.equal(t.ids().length, 3)
})

test("destroyed removes the listeners the hook put on the toaster", {skip}, () => {
  const t = mount()
  t.h.destroyed()
  t.el.dispatchEvent(new window.CustomEvent("toast:show", {detail: {id: "x", title: "late"}}))
  t.el.dispatchEvent(new window.CustomEvent("ledger:toast", {detail: {op: "show", id: "y", title: "late"}}))
  assert.equal(t.ids().length, 0)
})

test("a warning pill has the amber dot, an error pill the red one", {skip}, () => {
  const t = mount({luStack: "false", luMaxVisible: "9"})
  t.h.handle({op: "show", id: "w", title: "Careful", kind: "status", color: "warning"})
  t.h.handle({op: "show", id: "e", title: "Failed", kind: "status", color: "error"})
  t.h.handle({op: "show", id: "w2", title: "Careful", kind: "warning"})
  assert.ok(t.toast("w").querySelector("[data-part=status-toast-dot]").className.includes("dotwarn"))
  assert.ok(t.toast("w2").querySelector("[data-part=status-toast-dot]").className.includes("dotwarn"))
  assert.ok(t.toast("e").querySelector("[data-part=status-toast-dot]").className.includes("doterr"))
  assert.equal(t.toast("w").getAttribute("role"), "alert")
})

test("the pill: a ghost action is text only, the default is the full button (events and toast:*)", {skip}, () => {
  const t = mount({luStack: "false", luMaxVisible: "9"})
  t.h.handle({op: "show", id: "g", title: "Hiding", kind: "status", status: "ok", action: {label: "Undo", variant: "ghost", event: "undo"}})
  t.h.handle({op: "show", id: "f", title: "Done", kind: "status", status: "ok", actions: [{label: "View", event: "view"}]})
  t.el.dispatchEvent(new window.CustomEvent("toast:show", {detail: {id: "e", title: "Evt", kind: "status", status: "ok", action: {label: "Hide", variant: "ghost"}}}))
  const cls = (id) => t.toast(id).querySelector("[data-part=toast-action]").className
  assert.equal(cls("g"), "ghost")
  assert.equal(cls("f"), "act")
  assert.equal(cls("e"), "ghost")
  t.toast("g").querySelector("[data-part=toast-action]").click()
  assert.deepEqual(t.pushed, [["undo", {toast_id: "g"}]])
})

test("the card in progress with icon keeps the icon and fills the tile; update moves the level", {skip}, () => {
  const t = mount()
  t.h.handle({op: "show", id: "p", kind: "card", title: "NF-e", icon: "check", progress: 30})
  let card = t.toast("p")
  const fill = card.querySelector("[data-part=toast-tile-fill]")
  assert.ok(fill, "tile fill")
  assert.equal(fill.style.transform, "scaleY(0.3)")
  assert.ok(card.querySelector("[data-part=toast-tile]").className.includes("filling"))
  assert.ok(card.querySelector("[data-part=toast-tile] svg"), "icon stays")
  assert.equal(card.querySelector("[data-part=spinner]"), null, "no ring")
  t.h.handle({op: "update", id: "p", progress: 70})
  assert.equal(t.toast("p").querySelector("[data-part=toast-tile-fill]").style.transform, "scaleY(0.3)", "starts from the old level")
  t.h.handle({op: "update", id: "p", progress: 100})
  assert.equal(t.toast("p").querySelector("[data-part=toast-tile-fill]"), null, "done: check, no fill")
})

test("the card in progress without icon is unchanged (ring)", {skip}, () => {
  const t = mount()
  t.h.handle({op: "show", id: "n", kind: "card", title: "NF-e", progress: 30})
  assert.equal(t.toast("n").querySelector("[data-part=toast-tile-fill]"), null)
  assert.ok(t.toast("n").querySelector("[data-part=spinner]"))
})

test("the icon's shapes sent by the server are drawn in the tile (not only the built-ins)", {skip}, () => {
  const t = mount()
  t.h.handle({op: "show", id: "s", kind: "card", title: "NF-e", icon: "layers", icon_shapes: '<path d="M1 1"/>', progress: 30})
  assert.ok(t.toast("s").querySelector("[data-part=toast-tile] svg path"))
})

test("navigate/patch actions are LiveView links, close the toast on click and href stays a plain link", {skip}, () => {
  const t = mount({luStack: "false", luMaxVisible: "9"})
  t.h.handle({op: "show", id: "n", title: "Sent", kind: "status", status: "ok", action: {label: "View", navigate: "/orders/7?x=1#top"}})
  t.h.handle({op: "show", id: "p", title: "Sent", kind: "status", status: "ok", action: {label: "Tab", patch: "/orders?tab=open"}})
  t.h.handle({op: "show", id: "h", title: "Sent", kind: "status", status: "ok", action: {label: "Plain", href: "/orders"}})
  t.h.handle({op: "show", id: "c", kind: "card", title: "Sent", actions: [{label: "A", navigate: "/a"}, {label: "B", href: "/b"}]})
  const a = (id, i = 0) => t.toast(id).querySelectorAll("[data-part=toast-action]")[i]
  assert.equal(a("n").getAttribute("href"), "/orders/7?x=1#top")
  assert.equal(a("n").dataset.phxLink, "redirect")
  assert.equal(a("n").dataset.phxLinkState, "push")
  assert.equal(a("p").dataset.phxLink, "patch")
  assert.equal(a("p").dataset.phxLinkState, "push")
  assert.equal(a("h").getAttribute("href"), "/orders")
  assert.equal(a("h").dataset.phxLink, undefined)
  assert.equal(a("c", 0).dataset.phxLink, "redirect")
  assert.equal(a("c", 1).dataset.phxLink, undefined)
  a("n").click()
  assert.ok(!t.h.toasts.has("n"), "the click closes the toast")
})

test("navigate/patch only take paths of this site", {skip}, () => {
  const t = mount({luStack: "false", luMaxVisible: "9"})
  const bad = ["javascript:alert(1)", "https://evil.example/x", "//evil.example/x", "/\\evil.example", "data:text/html,x", " javascript:1"]
  bad.forEach((url, i) => t.h.handle({op: "show", id: "b" + i, title: "x", kind: "status", status: "ok", action: {label: "Go", navigate: url}}))
  bad.forEach((_, i) => {
    const el = t.toast("b" + i).querySelector("[data-part=toast-action]")
    assert.equal(el.dataset.phxLink, undefined, bad[i])
    assert.notEqual(el.tagName, "A", bad[i])
  })
  t.h.handle({op: "show", id: "ok", title: "x", kind: "status", status: "ok", action: {label: "Go", patch: "http://localhost/same/host"}})
  assert.equal(t.toast("ok").querySelector("a").getAttribute("href"), "/same/host")
})

test("a flash toast with navigate is shown once, not again on each update", {skip}, () => {
  const flash = JSON.stringify([{_k: "k1", title: "Sent", kind: "status", status: "ok", actions: [{label: "View", navigate: "/orders/1"}]}])
  const t = mount({luFlash: flash})
  assert.equal(t.ids().length, 1)
  t.toast(t.ids()[0]).querySelector("a").click()
  assert.equal(t.h.toasts.size, 0)
  t.h.updated()
  t.h.updated()
  assert.equal(t.h.toasts.size, 0, "the closed flash toast does not come back")
})
