// LedgerUI.TextEditor: rich text editor on a contenteditable (see LedgerUI.Components.TextEditor).
//
// Root attributes: data-lu-value (the server's sanitized HTML), data-lu-config (JSON: slash, slashItems,
// slashTitle, variables, variableLabel, variableTitle, mentions, mentionTitle, images, debounce,
// clearOnSubmit), data-lu-disabled, data-lu-variant, data-lu-on-change / on-image / on-ai / on-slash /
// on-submit, data-lu-target, data-*-label.
// Children: [data-lu-body] (phx-update="ignore"), [data-lu-editor-value] hidden input, .tb toolbar with
// [data-lu-tool], [data-lu-ph] placeholder, [data-lu-footer] [data-lu-words], and the popups under
// #<id>-ui ([data-lu-pop="link"|"image"], [data-lu-menu]).


// `data-lu-*` attributes through the camelCase `dataset` API: ds(el).onChange <-> data-lu-on-change.
const ds = (el) =>
  new Proxy(el.dataset, {
    get: (t, k) => (typeof k === "string" ? t["lu" + k[0].toUpperCase() + k.slice(1)] : t[k]),
    set: (t, k, v) => { t["lu" + k[0].toUpperCase() + k.slice(1)] = v; return true },
    has: (t, k) => ("lu" + k[0].toUpperCase() + k.slice(1)) in t,
  })

const ALLOWED = new Set("P DIV BR SPAN B STRONG I EM U S STRIKE DEL INS SUB SUP BLOCKQUOTE PRE CODE H1 H2 H3 H4 UL OL LI A HR MARK IMG".split(" "))
const STYLE_PROPS = new Set(["color", "background-color", "background", "font-size", "font-family", "font-weight", "font-style", "text-align", "text-decoration", "padding-left", "margin-left", "direction"])
const BLOCKS = new Set(["P", "DIV", "H1", "H2", "H3", "H4", "LI", "BLOCKQUOTE", "PRE"])

const safeHref = (v) => /^(https?:\/\/|mailto:|tel:|\/(?!\/)|#)/i.test(v)
const safeSrc = (v) => /^(https?:\/\/|\/(?!\/))/i.test(v)

function cleanStyle(style) {
  return style.split(";").map((d) => {
    const i = d.indexOf(":")
    if (i < 0) return ""
    const prop = d.slice(0, i).trim().toLowerCase()
    const val = d.slice(i + 1).trim()
    if (!STYLE_PROPS.has(prop) || !/^[#\w\s,.%()'"-]+$/.test(val) || /url\s*\(|expression|javascript|@import/i.test(val)) return ""
    return prop + ":" + val
  }).filter(Boolean).join(";")
}

// Copies `src` into `dest`, keeping only allowed tags/attributes (DOM based allowlist).
function cleanInto(src, dest, images) {
  for (const node of Array.from(src.childNodes)) {
    if (node.nodeType === 3) { dest.appendChild(document.createTextNode(node.nodeValue)); continue }
    if (node.nodeType !== 1) continue
    const tag = node.tagName
    if (tag === "IMG") {
      const s = node.getAttribute("src") || ""
      if (!images || !safeSrc(s)) continue
      const img = document.createElement("img")
      img.setAttribute("src", s)
      img.setAttribute("alt", (node.getAttribute("alt") || "").slice(0, 300))
      for (const k of ["width", "height"]) {
        const n = parseInt(node.getAttribute(k), 10)
        if (n >= 1 && n <= 4000) img.setAttribute(k, String(n))
      }
      dest.appendChild(img)
      continue
    }
    if (!ALLOWED.has(tag)) { cleanInto(node, dest, images); continue } // unwrap unknown tags
    const el = document.createElement(tag.toLowerCase())
    if (tag === "A") {
      const h = (node.getAttribute("href") || "").trim()
      if (safeHref(h)) { el.setAttribute("href", h); el.setAttribute("rel", "noopener noreferrer") }
    }
    const dir = node.getAttribute("dir")
    if (dir === "rtl" || dir === "ltr") el.setAttribute("dir", dir)
    const st = node.getAttribute("style")
    if (st) { const c = cleanStyle(st); if (c) el.setAttribute("style", c) }
    // Chips are kept in the editor (data-lu-var / data-lu-mention) and turned to text on submit.
    if (ds(node) && (ds(node).var || ds(node).mention)) {
      el.className = CLS.mention || ""
      el.setAttribute("contenteditable", "false")
      if (ds(node).var) ds(el).var = ds(node).var
      if (ds(node).mention) ds(el).mention = ds(node).mention
    }
    cleanInto(node, el, images)
    dest.appendChild(el)
  }
}

export function cleanHtml(html, images) {
  const doc = new DOMParser().parseFromString("<body>" + (html || "") + "</body>", "text/html")
  const box = document.createElement("div")
  cleanInto(doc.body, box, images)
  return box
}

// the classes of the chips and of the menu (sent by the component in the config)
const CLS = {}

const pos = (el, x, y) => {
  el.style.left = Math.max(8, Math.min(x, window.innerWidth - el.offsetWidth - 8)) + "px"
  el.style.top = Math.max(8, Math.min(y, window.innerHeight - el.offsetHeight - 8)) + "px"
}

export default {
  mounted() {
    this.handlers = []
    this.root = this.el
    this.body = this.el.querySelector("[data-lu-body]")
    this.hiddenInput = this.el.querySelector("[data-lu-editor-value]")
    this.ph = this.el.querySelector("[data-lu-ph]")
    this.words = this.el.querySelector("[data-lu-words]")
    this.ui = document.getElementById(this.el.id + "-ui")
    this.menu = this.ui.querySelector("[data-lu-menu]")
    this.cfg = this.readConfig()
    Object.assign(CLS, this.cfg.classes || {})
    this.menuState = null
    this.range = null

    this.serverValue = ds(this.el).value || ""
    this.loadHtml(this.serverValue)
    this.lastSent = this.serialize()
    this.syncHidden(false)
    this.applyDisabled()
    this.refreshChrome()
    const on = (el, ev, fn, opt) => { el.addEventListener(ev, fn, opt); this.handlers.push([el, ev, fn, opt]) }
    this.on = on

    on(this.body, "input", () => this.onEdit())
    on(this.body, "keydown", (e) => this.onKeydown(e))
    on(this.body, "paste", (e) => this.onPaste(e))
    on(this.body, "blur", () => { this.saveRange() })
    on(document, "selectionchange", () => { if (this.inBody()) { this.saveRange(); this.refreshState() } })
    on(document, "mousedown", (e) => {
      if (!this.ui.contains(e.target) && !this.el.contains(e.target)) this.closeUi()
    })
    on(this.ui, "input", (e) => e.stopPropagation())

    // Toolbar: keep the selection on mousedown, act on click / change / input.
    this.el.querySelectorAll("[data-lu-tool]").forEach((ctl) => {
      const tool = ds(ctl).tool
      if (ctl.tagName === "BUTTON") {
        on(ctl, "mousedown", (e) => e.preventDefault())
        on(ctl, "click", () => this.tool(tool, ctl))
      } else if (ctl.tagName === "SELECT") {
        on(ctl, "change", () => { this.restoreRange(); this.picker(tool, ctl.value); ctl.selectedIndex = 0; this.body.focus() })
      } else if (ctl.type === "color") {
        on(ctl, "mousedown", () => this.saveRange())
        on(ctl, "change", () => { this.restoreRange(); this.picker(tool, ctl.value); this.body.focus() })
      }
    })

    // Popups.
    this.ui.querySelectorAll("[data-lu-pop]").forEach((pop) => {
      const save = pop.querySelector("[data-lu-pop-save]")
      on(save, "click", () => this.savePop(pop))
      pop.querySelectorAll("input").forEach((i) =>
        on(i, "keydown", (e) => {
          if (e.key === "Enter") { e.preventDefault(); this.savePop(pop) }
          if (e.key === "Escape") { e.preventDefault(); this.closeUi(); this.body.focus() }
        }))
    })
    on(this.menu, "mousedown", (e) => e.preventDefault())
    on(this.menu, "click", (e) => {
      const item = e.target.closest("[data-lu-i]")
      if (item) this.pickMenu(parseInt(ds(item).i, 10))
    })

    this.handleEvent("lu:editor:insert", ({ id, html }) => {
      if (id === this.el.id) this.insertHtml(html)
    })
  },

  updated() {
    this.cfg = this.readConfig()
    this.applyDisabled()
    const server = ds(this.el).value || ""
    if (server !== this.serverValue) {
      this.serverValue = server
      // The server echoes what the editor sent: leave the text (and the caret) alone.
      if (this.normalize(server) !== this.serialize()) {
        this.loadHtml(server)
        this.lastSent = this.serialize()
      }
    }
    this.syncHidden(false)
    this.refreshChrome()
  },

  destroyed() {
    for (const [el, ev, fn, opt] of this.handlers || []) el.removeEventListener(ev, fn, opt)
    clearTimeout(this.timer)
  },

  readConfig() {
    try { return JSON.parse(ds(this.el).config || "{}") } catch (_e) { return {} }
  },

  // -- content ---------------------------------------------------------------------------
  normalize(html) {
    const box = cleanHtml(html, this.cfg.images)
    this.chipify(box)
    return this.serializeNode(box)
  },

  loadHtml(html) {
    const box = cleanHtml(html, this.cfg.images)
    this.chipify(box)
    this.body.replaceChildren(...Array.from(box.childNodes))
  },

  // `{name}` of a known variable and `@handle` of a known mention become chips.
  chipify(root) {
    const vars = new Set(this.cfg.variables || [])
    const mentions = new Map((this.cfg.mentions || []).map((m) => [m.handle, m.label]))
    if (!vars.size && !mentions.size) return
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT)
    const nodes = []
    while (walker.nextNode()) nodes.push(walker.currentNode)
    for (const n of nodes) {
      if (n.parentElement && n.parentElement.closest("[data-lu-var],[data-lu-mention]")) continue
      const parts = n.nodeValue.split(/(\{[^{}\s]+\}|@[\w.-]+)/)
      if (parts.length === 1) continue
      const frag = document.createDocumentFragment()
      let last = null
      for (const part of parts) {
        const v = part.match(/^\{([^{}\s]+)\}$/)
        const m = part.match(/^@([\w.-]+)$/)
        if (v && vars.has(v[1])) frag.append((last = this.chip("var", v[1], part)))
        else if (m && mentions.has(m[1])) frag.append((last = this.chip("mention", m[1], "@" + mentions.get(m[1]))))
        else if (part !== "") frag.append(part)
      }
      // Nothing became a chip: leave the text node (and the caret in it) alone.
      if (!last) continue
      const sel = document.getSelection()
      const hadCaret = sel && sel.anchorNode === n
      n.replaceWith(frag)
      if (hadCaret) {
        if (!last.nextSibling) last.after(document.createTextNode("\u00a0"))
        const r = document.createRange()
        r.setStartAfter(last.nextSibling || last)
        r.collapse(true)
        sel.removeAllRanges()
        sel.addRange(r)
      }
    }
  },

  chip(kind, key, label) {
    const s = document.createElement("span")
    s.className = CLS.mention || ""
    s.setAttribute("contenteditable", "false")
    ds(s)[kind] = key
    s.textContent = label
    return s
  },

  // HTML as the server gets it: chips back to `{name}` / `@handle`.
  serializeNode(root) {
    const copy = root.cloneNode(true)
    copy.querySelectorAll("[data-lu-var]").forEach((c) => c.replaceWith("{" + ds(c).var + "}"))
    copy.querySelectorAll("[data-lu-mention]").forEach((c) => c.replaceWith("@" + ds(c).mention))
    if (!copy.querySelector("img,hr") && copy.textContent.replace(/​/g, "").trim() === "") return ""
    return copy.innerHTML
  },

  serialize() { return this.serializeNode(this.body) },

  mentionHandles() {
    return Array.from(this.body.querySelectorAll("[data-lu-mention]")).map((c) => ds(c).mention)
  },

  syncHidden(announce) {
    const html = this.serialize()
    if (this.hiddenInput) {
      if (this.hiddenInput.value !== html) this.hiddenInput.value = html
      if (announce) this.hiddenInput.dispatchEvent(new Event("input", { bubbles: true }))
    }
  },

  onEdit() {
    this.chipify(this.body)
    const html = this.serialize()
    this.refreshChrome()
    this.refreshState()
    this.detectTrigger()
    if (html === this.lastSent) return
    this.lastSent = html
    this.syncHidden(true)
    const d = ds(this.el)
    if (d.onChange) {
      clearTimeout(this.timer)
      this.timer = setTimeout(() => this.push(d.onChange, { id: this.el.id, value: this.serialize() }), this.cfg.debounce || 300)
    }
  },

  refreshChrome() {
    const empty = this.serialize() === ""
    if (this.ph) this.ph.hidden = !empty
    if (this.words) {
      const text = this.body.textContent.trim()
      this.words.textContent = text ? text.split(/\s+/).length : 0
    }
  },

  applyDisabled() {
    const off = ds(this.el).disabled === "true"
    this.body.contentEditable = off ? "false" : "true"
  },

  push(event, payload) {
    // a `%JS{}` arrives as the JSON of its commands: run in the browser, no payload
    if (event.startsWith("[")) return this.js ? this.js().exec(event) : this.liveSocket.execJS(this.el, event)
    const t = ds(this.el).target
    if (t) this.pushEventTo(t, event, payload)
    else this.pushEvent(event, payload)
  },

  // -- selection -------------------------------------------------------------------------
  inBody() {
    const s = document.getSelection()
    return s && s.rangeCount > 0 && this.body.contains(s.anchorNode)
  },
  saveRange() {
    const s = document.getSelection()
    if (s && s.rangeCount > 0 && this.body.contains(s.anchorNode)) this.range = s.getRangeAt(0).cloneRange()
  },
  restoreRange() {
    this.body.focus()
    if (!this.range) return
    const s = document.getSelection()
    s.removeAllRanges()
    s.addRange(this.range)
  },
  selectedText() { const s = document.getSelection(); return this.inBody() ? s.toString() : "" },

  closestBlock() {
    const s = document.getSelection()
    let n = s && s.anchorNode
    while (n && n !== this.body) {
      if (n.nodeType === 1 && BLOCKS.has(n.tagName)) return n
      n = n.parentNode
    }
    return null
  },
  closest(selector) {
    const s = document.getSelection()
    let n = s && s.anchorNode
    if (n && n.nodeType === 3) n = n.parentElement
    return n && this.body.contains(n) ? n.closest(selector) : null
  },

  refreshState() {
    const st = (c) => { try { return document.queryCommandState(c) } catch (_e) { return false } }
    const on = {
      bold: st("bold"), italic: st("italic"), underline: st("underline"), strike: st("strikeThrough"),
      "script-sub": st("subscript"), "script-super": st("superscript"),
      "list-ordered": !!this.closest("ol"), "list-bullet": !!this.closest("ul"),
      blockquote: !!this.closest("blockquote"), "code-block": !!this.closest("pre"), code: !!this.closest("code"),
      "header-1": !!this.closest("h1"), "header-2": !!this.closest("h2"),
      heading: !!(this.closest("h1") || this.closest("h2")),
      link: !!this.closest("a"), mark: !!this.closest("mark"),
      "direction-rtl": !!this.closest("[dir=rtl]"),
    }
    this.el.querySelectorAll("[data-part=text-editor-toolbar] button[data-lu-tool]").forEach((b) => {
      if (ds(b).tool in on) {
        b.setAttribute("aria-pressed", String(on[ds(b).tool]))
      }
    })
  },

  // -- commands --------------------------------------------------------------------------
  // Typographic commands produce a style attribute (allowed by the cleaner); the others use tags.
  exec(cmd, val = null) {
    this.body.focus()
    const css = ["fontSize", "fontName", "foreColor", "hiliteColor", "justifyLeft", "justifyCenter", "justifyRight", "justifyFull"].includes(cmd)
    try { document.execCommand("styleWithCSS", false, css) } catch (_e) { /* old browsers */ }
    document.execCommand(cmd, false, val)
    this.onEdit()
  },

  toggleBlock(tag) {
    const cur = this.closest(tag)
    this.exec("formatBlock", cur ? "p" : tag)
  },

  wrap(tag) {
    this.restoreRange()
    const existing = this.closest(tag)
    const s = document.getSelection()
    if (existing) {
      existing.replaceWith(...Array.from(existing.childNodes))
    } else if (s.rangeCount && !s.isCollapsed) {
      const r = s.getRangeAt(0)
      const el = document.createElement(tag)
      el.appendChild(r.extractContents())
      r.insertNode(el)
      s.removeAllRanges()
      const nr = document.createRange()
      nr.selectNodeContents(el)
      s.addRange(nr)
    }
    this.onEdit()
  },

  tool(tool, ctl) {
    this.restoreRange()
    switch (tool) {
      case "bold": return this.exec("bold")
      case "italic": return this.exec("italic")
      case "underline": return this.exec("underline")
      case "strike": return this.exec("strikeThrough")
      case "blockquote": return this.toggleBlock("blockquote")
      case "code-block": return this.toggleBlock("pre")
      case "code": return this.wrap("code")
      case "heading": return this.toggleBlock("h2")
      case "header-1": return this.toggleBlock("h1")
      case "header-2": return this.toggleBlock("h2")
      case "list-ordered": return this.exec("insertOrderedList")
      case "list-bullet": return this.exec("insertUnorderedList")
      case "script-sub": return this.exec("subscript")
      case "script-super": return this.exec("superscript")
      case "indent-minus1": return this.exec("outdent")
      case "indent-plus1": return this.exec("indent")
      case "direction-rtl": return this.toggleDir()
      case "clean": this.exec("removeFormat"); this.exec("unlink"); return this.exec("formatBlock", "p")
      case "mark": return this.wrap("mark")
      case "link": return this.openPop("link", ctl)
      case "image":
        if (ds(this.el).onImage) return this.push(ds(this.el).onImage, { id: this.el.id })
        return this.openPop("image", ctl)
      case "variable": return this.openMenu("variable", ctl.getBoundingClientRect())
      case "ai":
        return this.push(ds(this.el).onAi, { id: this.el.id, value: this.serialize(), selection: this.selectedText() })
      case "mention": return this.openMenu("mention", ctl.getBoundingClientRect())
      case "submit": return this.submit()
    }
  },

  picker(tool, value) {
    switch (tool) {
      case "size": if (value) this.exec("fontSize", value); break
      case "header": this.exec("formatBlock", value || "p"); break
      case "font": if (value) this.exec("fontName", value); break
      case "align": this.exec({ left: "justifyLeft", center: "justifyCenter", right: "justifyRight", justify: "justifyFull" }[value] || "justifyLeft"); break
      case "color": this.exec("foreColor", value); break
      case "background": this.exec("hiliteColor", value); break
    }
  },

  toggleDir() {
    const block = this.closestBlock()
    if (!block) return
    if (block.getAttribute("dir") === "rtl") block.removeAttribute("dir")
    else block.setAttribute("dir", "rtl")
    this.onEdit()
  },

  // -- popups: link / image ----------------------------------------------------------------
  openPop(kind, anchor) {
    this.closeUi()
    const pop = this.ui.querySelector(`[data-lu-pop="${kind}"]`)
    pop.hidden = false
    const r = anchor.getBoundingClientRect()
    pos(pop, r.left, r.bottom + 6)
    const first = pop.querySelector("input")
    first.value = kind === "link" ? (this.closest("a")?.getAttribute("href") || "") : ""
    first.focus()
  },

  savePop(pop) {
    const kind = ds(pop).pop
    this.restoreRange()
    if (kind === "link") {
      const url = pop.querySelector("[data-lu-pop-url]").value.trim()
      if (!url) this.exec("unlink")
      else if (safeHref(url)) this.exec("createLink", url)
    } else {
      const src = pop.querySelector("[data-lu-pop-src]").value.trim()
      const alt = pop.querySelector("[data-lu-pop-alt]").value.trim()
      if (safeSrc(src)) this.insertHtml(`<img src="${src.replace(/"/g, "&quot;")}" alt="${alt.replace(/"/g, "&quot;")}">`)
    }
    this.closeUi()
  },

  insertHtml(html) {
    this.restoreRange()
    const box = cleanHtml(html, true)
    this.chipify(box)
    document.execCommand("insertHTML", false, box.innerHTML)
    this.onEdit()
  },

  // -- slash / mention / variable menus --------------------------------------------------------
  // Text before the caret in the current text node.
  textBefore() {
    const s = document.getSelection()
    if (!s || !s.rangeCount || !s.isCollapsed) return null
    let n = s.anchorNode
    let offset = s.anchorOffset
    if (n && n.nodeType === 1 && this.body.contains(n)) {
      // The caret sits between nodes: the text node just before it, if there is one.
      const prev = n.childNodes[offset - 1]
      if (prev && prev.nodeType === 3) { n = prev; offset = prev.nodeValue.length } else return null
    }
    if (!n || n.nodeType !== 3 || !this.body.contains(n)) return null
    return { node: n, offset, text: n.nodeValue.slice(0, offset) }
  },

  detectTrigger() {
    const tb = this.textBefore()
    if (!tb) return this.closeMenu()
    const slash = this.cfg.slash && tb.text.match(/(^|\s)\/([^\s/]*)$/)
    const at = (this.cfg.mentions || []).length && tb.text.match(/(^|\s)@([^\s@]*)$/)
    if (slash) this.openMenu("slash", null, slash[2], slash[0].length - (slash[1] ? 1 : 0) - 0)
    else if (at) this.openMenu("mention", null, at[2], at[0].length - at[1].length)
    else if (this.menuState && this.menuState.auto) this.closeMenu()
  },

  items(kind, q) {
    const f = (s) => (s || "").toLowerCase()
    const query = f(q)
    const match = (...xs) => !query || xs.some((x) => f(x).includes(query))
    if (kind === "mention")
      return (this.cfg.mentions || []).filter((m) => match(m.label, m.handle)).map((m) => ({ kind, label: m.label, hint: "@" + m.handle, icon: "@", data: m }))
    if (kind === "variable")
      return (this.cfg.variables || []).filter((v) => match(v)).map((v) => ({ kind: "variable", label: "{" + v + "}", hint: this.cfg.variableLabel, icon: "{}", data: v }))
    const out = (this.cfg.slashItems || []).filter((i) => match(i.label, i.key)).map((i) => ({ kind: "slash", label: i.label, hint: i.hint, icon: i.icon, data: i }))
    for (const v of this.cfg.variables || [])
      if (match(v)) out.push({ kind: "variable", label: "{" + v + "}", hint: this.cfg.variableLabel, icon: "{}", data: v })
    return out
  },

  // `triggerLen`: how many characters before the caret ("/query", "@query") get removed on pick.
  openMenu(kind, rect, q = "", triggerLen = null) {
    if (kind !== "slash" && rect) this.restoreRange()
    const items = this.items(kind, q)
    if (!items.length) return this.closeMenu()
    const title = { slash: this.cfg.slashTitle, mention: this.cfg.mentionTitle, variable: this.cfg.variableTitle }[kind]
    const keep = this.menuState && this.menuState.kind === kind ? this.menuState.index : 0
    this.menuState = { kind, items, index: Math.min(keep, items.length - 1), auto: !rect, triggerLen: triggerLen == null ? 0 : q.length + 1 }
    const m = this.menu
    m.replaceChildren()
    const label = document.createElement("div")
    label.className = CLS.menu_label || ""
    label.textContent = title
    m.append(label)
    items.forEach((it, i) => {
      const b = document.createElement("button")
      b.type = "button"
      b.className = CLS.menu_item || ""
      b.setAttribute("aria-selected", String(i === this.menuState.index))
      ds(b).i = String(i)
      b.setAttribute("role", "option")
      const ic = document.createElement("span")
      ic.className = CLS.menu_icon || ""
      ic.textContent = it.icon || ""
      const tx = document.createElement("span")
      tx.textContent = it.label
      const hint = document.createElement("span")
      hint.className = CLS.menu_hint || ""
      hint.textContent = it.hint || ""
      b.append(ic, tx, hint)
      m.append(b)
    })
    m.hidden = false
    let r = rect
    if (!r) {
      const s = document.getSelection()
      r = s.rangeCount ? s.getRangeAt(0).getBoundingClientRect() : this.body.getBoundingClientRect()
      if (!r.width && !r.height) r = this.body.getBoundingClientRect()
    }
    pos(m, r.left, r.bottom + 6)
  },

  closeMenu() {
    if (this.menu) this.menu.hidden = true
    this.menuState = null
  },

  closeUi() {
    this.closeMenu()
    this.ui.querySelectorAll("[data-lu-pop]").forEach((p) => { p.hidden = true })
  },

  moveMenu(d) {
    const st = this.menuState
    st.index = (st.index + d + st.items.length) % st.items.length
    this.menu.querySelectorAll("[data-lu-i]").forEach((b, i) => {
      b.setAttribute("aria-selected", String(i === st.index))
      if (i === st.index) b.scrollIntoView({ block: "nearest" })
    })
  },

  // Removes the "/query" or "@query" typed before the caret.
  eraseTrigger(len) {
    const tb = this.textBefore()
    if (!tb || !len) return
    const r = document.createRange()
    r.setStart(tb.node, Math.max(0, tb.offset - len))
    r.setEnd(tb.node, tb.offset)
    r.deleteContents()
    const s = document.getSelection()
    s.removeAllRanges()
    s.addRange(r)
  },

  pickMenu(i) {
    const st = this.menuState
    if (!st) return
    const it = st.items[i]
    this.closeMenu()
    if (st.auto) this.eraseTrigger(st.triggerLen)
    this.body.focus()
    if (it.kind === "mention") {
      this.insertChip(this.chip("mention", it.data.handle, "@" + it.data.label))
    } else if (it.kind === "variable") {
      this.insertChip(this.chip("var", it.data, "{" + it.data + "}"))
    } else {
      this.runSlash(it.data)
    }
    this.onEdit()
  },

  insertChip(chip) {
    const s = document.getSelection()
    if (!s.rangeCount) return
    const r = s.getRangeAt(0)
    r.deleteContents()
    r.insertNode(document.createTextNode(" "))
    r.insertNode(chip)
    r.setStartAfter(chip.nextSibling || chip)
    r.collapse(true)
    s.removeAllRanges()
    s.addRange(r)
  },

  runSlash(item) {
    switch (item.key) {
      case "paragraph": return document.execCommand("formatBlock", false, "p")
      case "h1": return document.execCommand("formatBlock", false, "h1")
      case "h2": return document.execCommand("formatBlock", false, "h2")
      case "bullet": return document.execCommand("insertUnorderedList")
      case "ordered": return document.execCommand("insertOrderedList")
      case "quote": return document.execCommand("formatBlock", false, "blockquote")
      case "code": return document.execCommand("formatBlock", false, "pre")
      case "divider": return document.execCommand("insertHorizontalRule")
      default:
        if (ds(this.el).onSlash) this.push(ds(this.el).onSlash, { id: this.el.id, key: item.key })
    }
  },

  // -- keyboard, paste, submit -----------------------------------------------------------------
  onKeydown(e) {
    if (this.menuState && !this.menu.hidden) {
      if (e.key === "ArrowDown") { e.preventDefault(); return this.moveMenu(1) }
      if (e.key === "ArrowUp") { e.preventDefault(); return this.moveMenu(-1) }
      if (e.key === "Enter" || e.key === "Tab") { e.preventDefault(); return this.pickMenu(this.menuState.index) }
      if (e.key === "Escape") { e.preventDefault(); return this.closeMenu() }
    }
    if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) { e.preventDefault(); this.submit() }
  },

  onPaste(e) {
    const cd = e.clipboardData
    if (!cd) return
    const html = cd.getData("text/html")
    e.preventDefault()
    if (html) {
      const box = cleanHtml(html, this.cfg.images)
      document.execCommand("insertHTML", false, box.innerHTML)
    } else {
      document.execCommand("insertText", false, cd.getData("text/plain"))
    }
    this.onEdit()
  },

  submit() {
    const d = ds(this.el)
    const value = this.serialize()
    if (d.onSubmit) this.push(d.onSubmit, { id: this.el.id, value, mentions: this.mentionHandles() })
    if (this.cfg.clearOnSubmit !== false && d.onSubmit) {
      this.body.replaceChildren()
      this.onEdit()
    }
  },
}
