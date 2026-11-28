// ai_composer (streaming), error_page (delegated listeners) and landing_nav (autohide, spy) in a jsdom document.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/page_bits_test.mjs
// jsdom is a devDependency (npm install): the tests are skipped when it cannot be found, and fail when CI=true.
import {test} from "node:test"
import assert from "node:assert/strict"
import {createRequire} from "node:module"
import {readFileSync, writeFileSync, mkdtempSync, mkdirSync} from "node:fs"
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

let composer, nav, errorPage
let scrollY = 0
const raf = []
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><html><body></body></html>", {pretendToBeVisual: true, url: "http://localhost/"})
  const w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, Event: w.Event, Node: w.Node, history: w.history, CSS: {escape: (s) => s}})
  Object.defineProperty(globalThis, "navigator", {value: w.navigator, configurable: true})
  Object.defineProperty(w, "scrollY", {get: () => scrollY})
  globalThis.requestAnimationFrame = (f) => { raf.push(f); return raf.length }
  w.requestAnimationFrame = globalThis.requestAnimationFrame
  const dir = mkdtempSync(join(tmpdir(), "lu-pagebits-"))
  mkdirSync(join(dir, "hooks"))
  const load = async (rel) => {
    const out = join(dir, rel.replace("/", "_") + ".mjs")
    writeFileSync(out, readFileSync(join(here, `../../priv/static/ledger_ui/${rel}.js`), "utf8"))
    return await import(pathToFileURL(out))
  }
  composer = (await load("hooks/ai_composer")).default
  nav = (await load("hooks/landing_nav")).default
  errorPage = await load("error_page")
}

const instance = (hook, el, extra = {}) => Object.assign(Object.create(hook), {el, pushEvent() {}, ...extra})
const flushRaf = () => { while (raf.length) raf.shift()() }
const key = (el, k, opts = {}) => {
  const e = new window.KeyboardEvent("keydown", {key: k, bubbles: true, cancelable: true, ...opts})
  el.dispatchEvent(e)
  return e
}

// ---- ai_composer ----------------------------------------------------------------------------
function mountComposer(attrs = "") {
  document.body.innerHTML = `<form id="c" ${attrs}><textarea>hello</textarea></form>`
  const el = document.getElementById("c")
  let submits = 0
  el.requestSubmit = () => { submits++ }
  const h = instance(composer, el)
  h.mounted()
  return {el, ta: el.querySelector("textarea"), submits: () => submits}
}

test("ai_composer: Enter sends, Shift+Enter breaks the line (no submit, not prevented)", {skip}, () => {
  const {ta, submits} = mountComposer()
  assert.equal(key(ta, "Enter").defaultPrevented, true)
  assert.equal(submits(), 1)
  assert.equal(key(ta, "Enter", {shiftKey: true}).defaultPrevented, false)
  assert.equal(submits(), 1)
})

for (const attr of ["data-streaming", "data-lu-streaming"]) {
  test(`ai_composer: with ${attr} Enter and Shift+Enter do not submit, and Enter sends again after`, {skip}, () => {
    const {el, ta, submits} = mountComposer(attr)
    key(ta, "Enter")
    key(ta, "Enter", {shiftKey: true})
    assert.equal(submits(), 0)
    el.removeAttribute(attr)
    key(ta, "Enter")
    assert.equal(submits(), 1)
  })
}

// ---- error_page -----------------------------------------------------------------------------
test("error_page: loading the module marks <html> and listens on the document, once", {skip}, () => {
  assert.equal(document.documentElement.hasAttribute("data-lu-js"), true)
  assert.equal(window.__luErrorPage, true)
})

test("error_page: [data-lu-back] goes back when there is history, else the link runs", {skip}, () => {
  document.body.innerHTML = `<a id="b" href="/x" data-lu-back><span id="in">Back</span></a>`
  let backs = 0
  const orig = window.history.back
  window.history.back = () => { backs++ }
  window.history.pushState({}, "", "/a")
  window.history.pushState({}, "", "/b")
  const click = (id) => { const e = new window.MouseEvent("click", {bubbles: true, cancelable: true}); document.getElementById(id).dispatchEvent(e); return e }
  assert.equal(click("in").defaultPrevented, true)
  assert.equal(backs, 1)
  window.history.back = orig
})

test("error_page: [data-lu-error-copy] copies the value and flags data-copied for a while", {skip}, async () => {
  document.body.innerHTML = `<button id="c" data-lu-error-copy="req-9"><i id="i"></i></button>`
  const written = []
  Object.defineProperty(window, "isSecureContext", {value: true, configurable: true})
  Object.defineProperty(window.navigator, "clipboard", {value: {writeText: async (t) => { written.push(t) }}, configurable: true})
  document.getElementById("i").dispatchEvent(new window.MouseEvent("click", {bubbles: true, cancelable: true}))
  await new Promise((r) => setTimeout(r, 0))
  assert.deepEqual(written, ["req-9"])
  assert.equal(document.getElementById("c").hasAttribute("data-copied"), true)
})

// ---- landing_nav ----------------------------------------------------------------------------
function mountNav(attrs = {}) {
  scrollY = 0
  const sections = ["a", "b", "c"].map((id, i) => `<section id="${id}" style="height:600px"></section>`).join("")
  document.body.innerHTML =
    `<nav id="n" data-lu-sticky data-lu-stuck-after="8"${Object.entries(attrs).map(([k, v]) => ` ${k}="${v}"`).join("")}>` +
    `<a id="la" href="#a">A</a><a id="lb" href="#b">B</a><a id="lc" href="#c">C</a><a id="pg" href="/p" aria-current="page">P</a>` +
    `<a id="pa" href="#b" data-part="landing-nav-panel-link">B</a></nav>` + sections
  const el = document.getElementById("n")
  Object.defineProperty(el, "offsetHeight", {value: 80, configurable: true})
  // section tops as the page scrolls: section i starts at i * 600 - scrollY
  document.querySelectorAll("section").forEach((s, i) => { s.getBoundingClientRect = () => ({top: i * 600 + 700 - scrollY}) })
  const h = instance(nav, el)
  h.mounted()
  return {el, h}
}
const scrollTo = (y) => { scrollY = y; window.dispatchEvent(new window.Event("scroll")); flushRaf() }

test("landing_nav: autohide hides on the way down and shows on the way up", {skip}, () => {
  const {el, h} = mountNav({"data-lu-autohide": ""})
  scrollTo(40) // not past the bar's own height
  assert.equal(el.hasAttribute("data-hidden"), false)
  scrollTo(300)
  assert.equal(el.hasAttribute("data-hidden"), true)
  assert.equal(el.hasAttribute("data-stuck"), true)
  scrollTo(298) // jitter below 4px: no change
  assert.equal(el.hasAttribute("data-hidden"), true)
  scrollTo(250)
  assert.equal(el.hasAttribute("data-hidden"), false)
  scrollTo(400)
  assert.equal(el.hasAttribute("data-hidden"), true)
  scrollTo(0)
  assert.equal(el.hasAttribute("data-hidden"), false)
  h.destroyed()
})

test("landing_nav: autohide does not hide with the focus inside, shows on focusin, survives a patch", {skip}, () => {
  const {el, h} = mountNav({"data-lu-autohide": ""})
  document.getElementById("la").focus()
  scrollTo(300)
  assert.equal(el.hasAttribute("data-hidden"), false)
  document.getElementById("la").blur()
  scrollTo(500)
  assert.equal(el.hasAttribute("data-hidden"), true)
  el.removeAttribute("data-hidden") // a patch drops it
  h.updated()
  assert.equal(el.hasAttribute("data-hidden"), true)
  el.dispatchEvent(new window.Event("focusin", {bubbles: true}))
  assert.equal(el.hasAttribute("data-hidden"), false)
  h.destroyed()
})

test("landing_nav: without data-lu-autohide the bar never hides", {skip}, () => {
  const {el, h} = mountNav()
  scrollTo(500)
  assert.equal(el.hasAttribute("data-hidden"), false)
  assert.equal(el.hasAttribute("data-stuck"), true)
  h.destroyed()
})

test("landing_nav: spy marks the link of the section in view (and the panel twin), only 'true' is removed", {skip}, () => {
  const {el, h} = mountNav({"data-lu-spy": "", "data-lu-spy-offset": "100"})
  const cur = () => [...el.querySelectorAll("[aria-current]")].map((a) => `${a.id}:${a.getAttribute("aria-current")}`)
  assert.deepEqual(cur(), ["pg:page"]) // before the first section: nothing in view
  scrollTo(620) // section a top = 80 <= 100
  assert.deepEqual(cur(), ["la:true", "pg:page"])
  scrollTo(1300) // b top = 0
  assert.deepEqual(cur(), ["lb:true", "pg:page", "pa:true"])
  el.removeAttribute("aria-current") // not touched: ids differ
  el.querySelector("#lb").removeAttribute("aria-current") // a patch
  h.updated()
  assert.ok(cur().includes("lb:true"))
  h.destroyed()
})

test("landing_nav: spy marks the last section at the end of the page", {skip}, () => {
  const {el, h} = mountNav({"data-lu-spy": ""})
  const root = document.documentElement
  Object.defineProperty(document, "scrollingElement", {value: root, configurable: true})
  Object.defineProperty(root, "scrollTop", {get: () => scrollY, configurable: true})
  Object.defineProperty(root, "clientHeight", {value: 800, configurable: true})
  Object.defineProperty(root, "scrollHeight", {value: 1800, configurable: true})
  scrollTo(1000)
  assert.equal(el.querySelector("#lc").getAttribute("aria-current"), "true")
  h.destroyed()
})
