// The carousel hook: arrows, bullets, keyboard, swipe, loop, effects, autoplay and patches (#121).
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/carousel_test.mjs
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

let carousel
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/"})
  const w = dom.window
  Object.assign(globalThis, {window: w, document: w.document, CSS: {escape: (s) => s}})
  // jsdom has no layout: the track is 300px wide, every slide 300px tall.
  Object.defineProperty(w.HTMLElement.prototype, "offsetWidth", {get() { return 300 }})
  Object.defineProperty(w.HTMLElement.prototype, "offsetHeight", {get() { return 200 }})
  carousel = (await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/carousel.js")))).default
}

// `data`: dataset attributes of the root (`data-index`, `data-loop`, `data-lu-effect`...).
function mount(data = {}, slides = 4) {
  const attrs = Object.entries(data).map(([k, v]) => `data-${k}="${v}"`).join(" ")
  document.body.innerHTML =
    `<div id="wrap"><div id="c" ${attrs}><div data-part="carousel-track">` +
    Array.from({length: slides}, (_, i) => `<div class="s" id="s${i}"><img id="img${i}"></div>`).join("") +
    `</div><span data-carousel-fraction></span><i data-carousel-bar></i>` +
    `<button id="prev" data-carousel-prev>p</button><button id="next" data-carousel-next>n</button></div>` +
    `<div id="c-dots">${Array.from({length: slides}, (_, i) => `<button id="d${i}"></button>`).join("")}</div>` +
    `<div id="c-thumbs">${Array.from({length: slides}, (_, i) => `<button id="t${i}"></button>`).join("")}</div></div>`
  const el = document.getElementById("c")
  const events = []
  const handlers = {}
  const hook = Object.assign(Object.create(carousel), {
    el,
    pushEvent(e, p) { events.push([e, p]) },
    pushEventTo(t, e, p) { events.push([e, p, t]) },
    handleEvent(name, fn) { handlers[name] = fn },
    liveSocket: {execJS(_el, code) { events.push(["js", code]) }},
  })
  hook.mounted()
  const $ = (id) => document.getElementById(id)
  const track = el.querySelector("[data-part=carousel-track]")
  return {hook, el, events, handlers, $, track,
    key: (target, k) => { const ev = new window.KeyboardEvent("keydown", {key: k, bubbles: true, cancelable: true}); target.dispatchEvent(ev); return ev },
    shown: () => [...track.children].findIndex((s) => s.getAttribute("aria-hidden") === "false"),
    dots: () => [...$("c-dots").children].findIndex((d) => d.getAttribute("aria-current") === "true")}
}

test("slide effect: a flex track, the first slide shown, the others aria-hidden, the fraction and the bar", {skip}, () => {
  const t = mount()
  assert.equal(t.track.style.display, "flex")
  assert.equal(t.track.style.transform, "translateX(0px)")
  assert.equal(t.shown(), 0)
  assert.deepEqual([...t.track.children].map((s) => s.getAttribute("aria-hidden")), ["false", "true", "true", "true"])
  assert.equal(t.el.querySelector("[data-carousel-fraction]").textContent, "1/4")
  assert.equal(t.el.querySelector("[data-carousel-bar]").style.width, "25%")
  assert.equal(t.dots(), 0)
  t.hook.destroyed()
})

test("next and prev move the track by the slide width and update bullets, thumbnails, fraction", {skip}, () => {
  const t = mount()
  t.$("next").click()
  assert.equal(t.track.style.transform, "translateX(-300px)")
  assert.equal(t.shown(), 1)
  assert.equal(t.dots(), 1)
  assert.equal(t.$("t1").getAttribute("aria-current"), "true")
  assert.equal(t.el.querySelector("[data-carousel-fraction]").textContent, "2/4")
  t.$("next").click(); t.$("prev").click()
  assert.equal(t.shown(), 1)
  t.hook.destroyed()
})

test("without loop the ends clamp; with loop they wrap", {skip}, () => {
  const t = mount()
  t.$("prev").click()
  assert.equal(t.shown(), 0, "before the first: stays")
  for (let i = 0; i < 6; i++) t.$("next").click()
  assert.equal(t.shown(), 3, "after the last: stays")
  t.hook.destroyed()
  const l = mount({loop: "true"})
  l.$("prev").click()
  assert.equal(l.shown(), 3, "loop: prev from the first goes to the last")
  l.$("next").click()
  assert.equal(l.shown(), 0, "and next from the last returns")
  l.hook.destroyed()
})

test("a bullet and a thumbnail go to their slide", {skip}, () => {
  const t = mount()
  t.$("d2").click()
  assert.equal(t.shown(), 2)
  t.$("t3").click()
  assert.equal(t.shown(), 3)
  t.hook.destroyed()
})

test("keyboard: ArrowRight/ArrowLeft move (and are cancelled), Enter on a bullet picks it, other keys are ignored", {skip}, () => {
  const t = mount()
  assert.equal(t.key(t.$("img0"), "ArrowRight").defaultPrevented, true)
  assert.equal(t.shown(), 1)
  t.key(t.$("img1"), "ArrowLeft")
  assert.equal(t.shown(), 0)
  assert.equal(t.key(t.$("d2"), "Enter").defaultPrevented, true)
  assert.equal(t.shown(), 2)
  assert.equal(t.key(t.$("img0"), "a").defaultPrevented, false)
  assert.equal(t.shown(), 2)
  const outside = document.createElement("input"); document.body.append(outside)
  t.key(outside, "ArrowLeft")
  assert.equal(t.shown(), 2, "keys outside the carousel do nothing")
  t.hook.destroyed()
})

test("vertical: a column track, translateY by the slide height, ArrowDown/ArrowUp", {skip}, () => {
  const t = mount({"lu-direction": "vertical"})
  assert.equal(t.track.style.flexDirection, "column")
  t.key(t.$("img0"), "ArrowDown")
  assert.equal(t.track.style.transform, "translateY(-200px)")
  t.key(t.$("img1"), "ArrowUp")
  assert.equal(t.shown(), 0)
  t.hook.destroyed()
})

test("gap counts in the step", {skip}, () => {
  const t = mount({gap: "20"})
  t.$("next").click()
  assert.equal(t.track.style.transform, "translateX(-320px)")
  t.hook.destroyed()
})

test("swipe: a drag past 40px moves a slide, a short one does not", {skip}, () => {
  const t = mount()
  const drag = (x0, x1) => {
    t.el.dispatchEvent(new window.MouseEvent("pointerdown", {clientX: x0, bubbles: true}))
    t.el.dispatchEvent(new window.MouseEvent("pointerup", {clientX: x1, bubbles: true}))
  }
  drag(200, 100)
  assert.equal(t.shown(), 1, "dragged left: next")
  drag(100, 200)
  assert.equal(t.shown(), 0, "dragged right: previous")
  drag(100, 80)
  assert.equal(t.shown(), 0, "20px is a click, not a swipe")
  t.hook.destroyed()
})

test("on_change: pushes the id and index only when the slide changed (to the target when there is one)", {skip}, () => {
  const t = mount({"on-change": "moved", target: "#lv"})
  t.$("next").click()
  assert.deepEqual(t.events, [["moved", {id: "c", index: 1}, "#lv"]])
  t.$("prev").click(); t.$("prev").click()
  assert.equal(t.events.length, 2, "prev at the first slide changes nothing: no event")
  t.hook.destroyed()
  const js = mount({"on-change": '[["push",{"event":"x"}]]'})
  js.$("next").click()
  assert.deepEqual(js.events[0][0], "js")
  js.hook.destroyed()
})

test("effects stack the slides: fade shows only the current one and only it takes the pointer", {skip}, () => {
  const t = mount({"lu-effect": "fade"})
  assert.equal(t.track.style.display, "grid")
  const op = () => [...t.track.children].map((s) => s.style.opacity)
  assert.deepEqual(op(), ["1", "0", "0", "0"])
  t.$("next").click()
  assert.deepEqual(op(), ["0", "1", "0", "0"])
  assert.deepEqual([...t.track.children].map((s) => s.style.pointerEvents), ["none", "auto", "none", "none"])
  t.hook.destroyed()
  const c = mount({"lu-effect": "cards"})
  assert.match(c.$("s1").style.transform, /scale\(0\.94\)/)
  assert.equal(c.$("s0").style.zIndex, "10")
  c.hook.destroyed()
})

test("a patch keeps the person's slide, but a new server index wins", {skip}, () => {
  const t = mount({index: "0"})
  t.$("next").click(); t.$("next").click()
  t.hook.updated()
  assert.equal(t.shown(), 2, "same server index: the person's slide survives")
  assert.equal(t.track.style.display, "flex", "inline styles re-applied")
  t.el.dataset.index = "3"
  t.hook.updated()
  assert.equal(t.shown(), 3, "the server moved: it wins")
  t.hook.destroyed()
})

test("the server can move it with the ledger:carousel event (only for its own id)", {skip}, () => {
  const t = mount()
  t.handlers["ledger:carousel"]({id: "other", index: 2})
  assert.equal(t.shown(), 0)
  t.handlers["ledger:carousel"]({id: "c", index: 2})
  assert.equal(t.shown(), 2)
  t.hook.destroyed()
})

test("double click toggles the zoom on the current slide's content", {skip}, () => {
  const t = mount({zoom: "2"})
  t.el.dispatchEvent(new window.MouseEvent("dblclick", {bubbles: true}))
  assert.equal(t.$("img0").style.transform, "scale(2)")
  t.el.dispatchEvent(new window.MouseEvent("dblclick", {bubbles: true}))
  assert.equal(t.$("img0").style.transform, "")
  t.hook.destroyed()
})

test("autoplay advances on a timer, is held while the pointer is over, and stops on destroy", {skip}, async () => {
  const t = mount({autoplay: "15", loop: "true"})
  await new Promise((r) => setTimeout(r, 40))
  assert.ok(t.shown() >= 1, "moved by itself")
  t.el.dispatchEvent(new window.MouseEvent("mouseenter"))
  const at = t.shown()
  await new Promise((r) => setTimeout(r, 50))
  assert.equal(t.shown(), at, "held while hovered")
  t.el.dispatchEvent(new window.MouseEvent("mouseleave"))
  t.hook.destroyed()
  const after = t.shown()
  await new Promise((r) => setTimeout(r, 40))
  assert.equal(t.shown(), after, "no timer left")
})

test("autoplay without loop returns to the first slide after the last", {skip}, async () => {
  const t = mount({autoplay: "10"}, 2)
  await new Promise((r) => setTimeout(r, 60))
  const seen = new Set()
  for (let i = 0; i < 6; i++) { seen.add(t.shown()); await new Promise((r) => setTimeout(r, 10)) }
  assert.ok(seen.has(0) && seen.has(1), "it cycles: " + [...seen])
  t.hook.destroyed()
})
