// The text_editor hook: the HTML sanitizer (paste and server value), chips, the slash/mention menus, the keyboard,
// submit and the server's value (#121). jsdom has no `execCommand`: the editing commands are recorded by a stub.
//   JSDOM_PATH=/path/to/node_modules/jsdom node --test test/js/text_editor_test.mjs
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

let editor, cleanHtml
const commands = []
if (JSDOM) {
  const dom = new JSDOM("<!doctype html><body></body>", {pretendToBeVisual: true, url: "https://example.test/"})
  const w = dom.window
  w.Element.prototype.scrollIntoView = () => {}
  w.Range.prototype.getBoundingClientRect = () => ({left: 10, right: 10, top: 10, bottom: 30, width: 0, height: 0})
  w.document.execCommand = (cmd, _ui, val) => { commands.push([cmd, val]); return true }
  Object.assign(globalThis, {window: w, document: w.document, DOMParser: w.DOMParser, NodeFilter: w.NodeFilter, Event: w.Event, HTMLElement: w.HTMLElement})
  const mod = await import(pathToFileURL(join(here, "../../priv/static/ledger_ui/hooks/text_editor.js")))
  editor = mod.default
  cleanHtml = mod.cleanHtml
}

const clean = (html, images = false) => cleanHtml(html, images).innerHTML

// ---- the sanitizer -------------------------------------------------------------------------------

test("sanitizer: scripts, handlers, iframes and unknown tags never survive; text of unknown tags is kept", {skip}, () => {
  assert.equal(clean('<p onclick="x()">hi<script>alert(1)</script></p>'), "<p>hialert(1)</p>", "the script TAG goes (its text is plain text)")
  assert.equal(clean('<p>a</p><iframe src="https://x"></iframe><object data="x"></object>'), "<p>a</p>")
  assert.equal(clean("<custom-tag><b>bold</b> text</custom-tag>"), "<b>bold</b> text", "unknown tags are unwrapped")
  assert.ok(!clean('<svg onload="x()"><circle/></svg>').includes("onload"))
  assert.ok(!clean('<div onmouseover="x()">t</div>').includes("onmouseover"))
})

test("sanitizer: only http(s), mailto, tel, relative and # links; the rest lose the href", {skip}, () => {
  assert.equal(clean('<a href="https://ok.test/a?b=1">x</a>'), '<a href="https://ok.test/a?b=1" rel="noopener noreferrer">x</a>')
  assert.equal(clean('<a href="mailto:a@b.c">x</a>'), '<a href="mailto:a@b.c" rel="noopener noreferrer">x</a>')
  assert.equal(clean('<a href="/path">x</a>'), '<a href="/path" rel="noopener noreferrer">x</a>')
  for (const bad of ["javascript:alert(1)", " JaVaScRiPt:alert(1)", "data:text/html,<b>", "//evil.test/x", "vbscript:x"]) {
    assert.equal(clean(`<a href="${bad}">x</a>`), "<a>x</a>", bad)
  }
})

test("sanitizer: images only when allowed and only http(s)/relative sources, with clamped size", {skip}, () => {
  assert.equal(clean('<img src="https://i.test/a.png" alt="A" width="40" height="9999">', false), "", "images off")
  assert.equal(clean('<img src="https://i.test/a.png" alt="A" width="40" height="9999">', true), '<img src="https://i.test/a.png" alt="A" width="40">')
  assert.equal(clean('<img src="javascript:alert(1)">', true), "")
  assert.equal(clean('<img src="data:image/png;base64,AAAA">', true), "")
  assert.equal(clean('<img src="//evil.test/a.png">', true), "")
  assert.equal(clean('<img src="/local.png" onerror="x()">', true), '<img src="/local.png" alt="">')
})

test("sanitizer: styles keep a short allowlist and drop url(), expression and anything else", {skip}, () => {
  assert.equal(clean('<span style="color:#f00;position:fixed;font-size:14px">x</span>'), '<span style="color:#f00;font-size:14px">x</span>')
  assert.equal(clean('<span style="background:url(http://x/y.png)">x</span>'), "<span>x</span>")
  assert.equal(clean('<span style="color:expression(alert(1))">x</span>'), "<span>x</span>")
  assert.equal(clean('<p style="text-align:center">x</p>'), '<p style="text-align:center">x</p>')
  assert.equal(clean('<p dir="rtl">x</p><p dir="evil">y</p>'), '<p dir="rtl">x</p><p>y</p>')
})

test("sanitizer: structure tags survive", {skip}, () => {
  const html = "<h1>t</h1><ul><li>a</li></ul><blockquote>q</blockquote><pre><code>c</code></pre><p><b>b</b><i>i</i><u>u</u><s>s</s></p><hr>"
  assert.equal(clean(html), html)
})

// ---- the hook -------------------------------------------------------------------------------------

function mount({value = "", config = {}, data = {}} = {}) {
  const cfg = {slash: true, slashItems: [{key: "h1", label: "Heading 1", hint: "#", icon: "H"}, {key: "bullet", label: "Bullet list", hint: "-", icon: "*"}, {key: "custom", label: "Custom"}],
    variables: ["name"], variableLabel: "Variable", mentions: [{handle: "ana", label: "Ana"}, {handle: "bob", label: "Bob"}], debounce: 5, images: false, ...config}
  document.body.innerHTML = ""
  const el = document.createElement("div")
  el.id = "ed"
  el.dataset.luValue = value
  el.dataset.luConfig = JSON.stringify(cfg)
  for (const [k, v] of Object.entries(data)) el.dataset[k] = v
  el.innerHTML = `<div data-lu-body phx-update="ignore"></div><input type="hidden" data-lu-editor-value><span data-lu-ph hidden>Write</span>` +
    `<span data-lu-words></span><div class="tb" data-part="text-editor-toolbar"><button type="button" data-lu-tool="bold">B</button><button type="button" data-lu-tool="submit">Send</button></div>`
  const ui = document.createElement("div")
  ui.id = "ed-ui"
  ui.innerHTML = `<div data-lu-menu hidden></div>`
  document.body.append(el, ui)
  const pushed = []
  const handlers = {}
  const hook = Object.assign(Object.create(editor), {el, handleEvent(n, fn) { handlers[n] = fn }, pushEvent(e, p) { pushed.push([e, p]) }, pushEventTo(t, e, p) { pushed.push([e, p, t]) }})
  hook.mounted()
  const body = el.querySelector("[data-lu-body]")
  commands.length = 0
  // Puts the caret at the end of the first text node of the body.
  const caretEnd = () => {
    const node = body.firstChild
    const r = document.createRange()
    r.setStart(node, node.nodeValue.length)
    r.collapse(true)
    const s = document.getSelection()
    s.removeAllRanges(); s.addRange(r)
  }
  const type = (text) => { body.textContent = text; caretEnd(); body.dispatchEvent(new window.Event("input", {bubbles: true})) }
  const key = (k, init = {}) => { const ev = new window.KeyboardEvent("keydown", {key: k, bubbles: true, cancelable: true, ...init}); body.dispatchEvent(ev); return ev }
  return {hook, el, body, pushed, handlers, type, key, caretEnd, menu: el.ownerDocument.querySelector("[data-lu-menu]"),
    hidden: () => el.querySelector("[data-lu-editor-value]").value}
}

test("mount: the server's value is sanitized into the body; the placeholder and the word count follow", {skip}, () => {
  const t = mount({value: '<p>hello <b>big</b> world</p><script>x()</script>'})
  assert.equal(t.body.innerHTML, "<p>hello <b>big</b> world</p>x()")
  assert.equal(t.el.querySelector("[data-lu-words]").textContent, "3", "hello big worldx()")
  assert.equal(t.el.querySelector("[data-lu-ph]").hidden, true)
  const e = mount()
  assert.equal(e.el.querySelector("[data-lu-ph]").hidden, false, "empty: the placeholder shows")
  assert.equal(e.el.querySelector("[data-lu-words]").textContent, "0")
  e.hook.destroyed(); t.hook.destroyed()
})

test("known {variables} and @mentions become non-editable chips; unknown ones stay text", {skip}, () => {
  const t = mount({value: "<p>Hi {name}, {other} and @ana, @zed</p>"})
  const chips = [...t.body.querySelectorAll("[data-lu-var],[data-lu-mention]")]
  assert.equal(chips.length, 2)
  assert.equal(chips[0].getAttribute("contenteditable"), "false")
  assert.equal(chips[0].dataset.luVar, "name")
  assert.equal(chips[0].textContent, "{name}")
  assert.equal(chips[1].dataset.luMention, "ana")
  assert.equal(chips[1].textContent, "@Ana", "the chip shows the label")
  assert.equal(t.hook.serialize(), "<p>Hi {name}, {other} and @ana, @zed</p>", "chips go back to their text for the server")
  t.hook.destroyed()
})

test("typing: hidden input updated with a bubbling input event, on_change debounced with the serialized value", {skip}, async () => {
  const t = mount({data: {luOnChange: "changed"}})
  let seen = 0
  t.el.addEventListener("input", (e) => e.target.matches("[data-lu-editor-value]") && seen++)
  t.type("first")
  t.type("final text")
  assert.equal(t.hidden(), "final text")
  assert.equal(seen, 2)
  assert.deepEqual(t.pushed, [], "debounced")
  await new Promise((r) => setTimeout(r, 30))
  assert.deepEqual(t.pushed, [["changed", {id: "ed", value: "final text"}]], "one push, the last value")
  t.hook.destroyed()
})

test("the server echoing what the editor sent does not touch the body; a different value replaces it", {skip}, () => {
  const t = mount()
  t.type("mine")
  const node = t.body.firstChild
  t.el.dataset.luValue = "mine"
  t.hook.updated()
  assert.equal(t.body.firstChild, node, "same text node: the caret is safe")
  t.el.dataset.luValue = "<p>from server</p>"
  t.hook.updated()
  assert.equal(t.body.innerHTML, "<p>from server</p>")
  t.hook.destroyed()
})

test("disabled: the body is not editable", {skip}, () => {
  const t = mount({data: {luDisabled: "true"}})
  assert.equal(t.body.contentEditable, "false")
  t.hook.destroyed()
})

test("paste: HTML is sanitized before it is inserted; plain text goes as text; the native paste is cancelled", {skip}, () => {
  const t = mount()
  const paste = (data) => {
    const ev = new window.Event("paste", {bubbles: true, cancelable: true})
    ev.clipboardData = {getData: (type) => data[type] || ""}
    t.body.dispatchEvent(ev)
    return ev
  }
  const ev = paste({"text/html": '<p onclick="x()">ok <img src="https://i.test/a.png"><script>bad()</script> <a href="javascript:x()">l</a></p>'})
  assert.equal(ev.defaultPrevented, true)
  assert.deepEqual(commands.find(([c]) => c === "insertHTML"), ["insertHTML", "<p>ok bad() <a>l</a></p>"], "no handler, no image (images off), no script tag, no javascript: href")
  commands.length = 0
  paste({"text/plain": "<b>not html</b>"})
  assert.deepEqual(commands.find(([c]) => c === "insertText"), ["insertText", "<b>not html</b>"])
  t.hook.destroyed()
})

test("paste: images are kept when the editor allows them (safe sources only)", {skip}, () => {
  const t = mount({config: {images: true}})
  const ev = new window.Event("paste", {bubbles: true, cancelable: true})
  ev.clipboardData = {getData: (type) => (type === "text/html" ? '<img src="https://i.test/a.png"><img src="javascript:x()">' : "")}
  t.body.dispatchEvent(ev)
  assert.deepEqual(commands.find(([c]) => c === "insertHTML"), ["insertHTML", '<img src="https://i.test/a.png" alt="">'])
  t.hook.destroyed()
})

test("toolbar buttons run their command: bold -> execCommand(bold)", {skip}, () => {
  const t = mount()
  t.el.querySelector('[data-lu-tool="bold"]').click()
  assert.ok(commands.some(([c]) => c === "bold"))
  t.hook.destroyed()
})

test("slash menu: '/' + query opens the filtered list; arrows move; Enter erases the trigger and runs the command", {skip}, () => {
  const t = mount({value: ""})
  t.type("/")
  assert.equal(t.menu.hidden, false)
  assert.equal(t.menu.querySelectorAll("[data-lu-i]").length, 4, "3 commands + the variable")
  t.type("/bul")
  const items = [...t.menu.querySelectorAll("[data-lu-i]")]
  assert.equal(items.length, 1)
  assert.equal(items[0].textContent.includes("Bullet list"), true)
  assert.equal(items[0].getAttribute("role"), "option")
  t.type("/")
  assert.equal(t.key("ArrowDown").defaultPrevented, true)
  assert.equal(t.menu.querySelectorAll("[data-lu-i]")[1].getAttribute("aria-selected"), "true")
  t.key("ArrowUp"); t.key("ArrowUp")
  assert.equal(t.menu.querySelectorAll("[data-lu-i]")[3].getAttribute("aria-selected"), "true", "wraps to the last")
  t.type("/bul")
  const ev = t.key("Enter")
  assert.equal(ev.defaultPrevented, true)
  assert.equal(t.menu.hidden, true)
  assert.equal(t.body.textContent, "", "the '/bul' trigger was removed")
  assert.ok(commands.some(([c]) => c === "insertUnorderedList"))
  t.hook.destroyed()
})

test("slash menu: Escape closes it; a text with no trigger closes it; a custom command goes to on_slash", {skip}, () => {
  const t = mount({data: {luOnSlash: "slashed"}})
  t.type("/h")
  assert.equal(t.menu.hidden, false)
  assert.equal(t.key("Escape").defaultPrevented, true)
  assert.equal(t.menu.hidden, true)
  t.type("/h")
  t.type("plain")
  assert.equal(t.menu.hidden, true, "no trigger before the caret")
  t.type("/cus")
  t.key("Enter")
  assert.deepEqual(t.pushed.filter(([e]) => e === "slashed"), [["slashed", {id: "ed", key: "custom"}]])
  t.hook.destroyed()
})

test("a URL slash in the middle of a word is not a trigger", {skip}, () => {
  const t = mount()
  t.type("see a/b")
  assert.equal(t.menu.hidden, true)
  t.type("path /he")
  assert.equal(t.menu.hidden, false, "after a space it is")
  t.hook.destroyed()
})

test("mention menu: '@' + query lists matches; Enter inserts a chip, and the serialized text is @handle", {skip}, () => {
  const t = mount()
  t.type("hi @b")
  const items = [...t.menu.querySelectorAll("[data-lu-i]")]
  assert.equal(items.length, 1)
  assert.equal(items[0].textContent.includes("Bob"), true)
  t.key("Enter")
  const chip = t.body.querySelector("[data-lu-mention]")
  assert.ok(chip, "a chip was inserted")
  assert.equal(chip.dataset.luMention, "bob")
  assert.equal(t.hook.serialize().startsWith("hi @bob"), true)
  assert.equal(t.hidden().startsWith("hi @bob"), true)
  t.hook.destroyed()
})

test("Ctrl+Enter submits: on_submit gets the value and the mentions, and the editor clears", {skip}, () => {
  const t = mount({value: "<p>hello @ana</p>", data: {luOnSubmit: "send"}})
  const ev = t.key("Enter", {ctrlKey: true})
  assert.equal(ev.defaultPrevented, true)
  assert.deepEqual(t.pushed, [["send", {id: "ed", value: "<p>hello @ana</p>", mentions: ["ana"]}]])
  assert.equal(t.body.innerHTML, "", "cleared after submit")
  assert.equal(t.hidden(), "")
  t.hook.destroyed()
})

test("submit does not clear when clearOnSubmit is false; a plain Enter is left to the editor", {skip}, () => {
  const t = mount({value: "<p>keep</p>", config: {clearOnSubmit: false}, data: {luOnSubmit: "send"}})
  assert.equal(t.key("Enter").defaultPrevented, false)
  t.key("Enter", {metaKey: true})
  assert.equal(t.pushed.length, 1)
  assert.equal(t.body.innerHTML, "<p>keep</p>")
  t.hook.destroyed()
})

test("the lu:editor:insert event inserts sanitized HTML, only for its own id", {skip}, () => {
  const t = mount()
  t.handlers["lu:editor:insert"]({id: "other", html: "<b>x</b>"})
  assert.equal(commands.length, 0)
  t.handlers["lu:editor:insert"]({id: "ed", html: '<b onclick="x()">x</b><script>y()</script>'})
  assert.deepEqual(commands.find(([c]) => c === "insertHTML"), ["insertHTML", "<b>x</b>y()"])
  t.hook.destroyed()
})

test("destroyed removes every listener", {skip}, () => {
  const t = mount({data: {luOnChange: "c"}})
  t.hook.destroyed()
  t.type("after")
  assert.equal(t.hidden(), "")
})
