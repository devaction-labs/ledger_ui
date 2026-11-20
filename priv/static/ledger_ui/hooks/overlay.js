// LedgerUI.Overlay: modal, drawer and command palette.
//
// The root element carries `data-lu-overlay`, `data-lu-kind` ("modal" | "drawer" | "palette") and the
// other `data-lu-*` settings rendered by the components. The state is the class `open` (what
// LedgerUI.open/close/toggle change); this hook reacts to it: mirrors it in `data-state`
// ("open" | "closing" | "closed", the CSS in ledger_ui.css shows/hides from it, never an inline
// `display`), plays the open / close animation, traps the focus, closes on Esc / backdrop, returns
// the focus, locks the page's scroll and runs on_open / on_close.

const stack = []
let locks = 0
let savedOverflow = ""
let listening = false

const FOCUSABLE =
  "a[href],button:not([disabled]),input:not([disabled]):not([type=hidden]),select:not([disabled])," +
  "textarea:not([disabled]),[tabindex]:not([tabindex='-1']),summary"

const reduced = () => window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches
const norm = (s) => (s || "").normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase()

function lock() {
  if (locks++ === 0) {
    savedOverflow = document.documentElement.style.overflow
    document.documentElement.style.overflow = "hidden"
  }
}

function unlock() {
  if (locks > 0 && --locks === 0) document.documentElement.style.overflow = savedOverflow
}

function onKeydown(e) {
  const top = stack[stack.length - 1]
  if (!top) return
  if (e.key === "Escape") {
    if (!top.preventClose) {
      e.preventDefault()
      e.stopPropagation()
      top.close()
    }
  } else if (e.key === "Tab") {
    top.trap(e)
  }
}

function listen() {
  if (listening) return
  document.addEventListener("keydown", onKeydown, true)
  listening = true
}

const visible = (el) => el.offsetParent !== null || el === document.activeElement

const CARD_ANIM = {
  fade: () => null,
  scale: (o) => ({keyframes: [{transform: "scale(.95)", opacity: 0}, {transform: "none", opacity: 1}], origin: o}),
  sheet: () => ({keyframes: [{transform: "translateY(32px)", opacity: 0}, {transform: "none", opacity: 1}]}),
  "shift-down": () => ({keyframes: [{transform: "translateY(-16px)", opacity: 0}, {transform: "none", opacity: 1}]}),
  "shift-up": () => ({keyframes: [{transform: "translateY(16px)", opacity: 0}, {transform: "none", opacity: 1}]}),
}

export default {
  mounted() {
    this.isOpen = false
    this.readConfig()
    this.serverOpen = this.attr("open")
    this.observer = new MutationObserver(() => this.sync())
    this.observer.observe(this.el, {attributes: true, attributeFilter: ["class"]})
    this.onClick = (e) => {
      if (e.target === this.el && !this.preventClose && this.overlay) this.close()
    }
    this.el.addEventListener("click", this.onClick)
    if (this.kind === "palette") this.paletteInit()
    if (this.el.classList.contains("open") || this.attr("open") === "true" || this.state() === "open") {
      this.el.classList.add("open")
      this.sync(true)
    } else {
      this.setState("closed")
    }
  },

  updated() {
    this.readConfig()
    const s = this.attr("open")
    if (s !== this.serverOpen) {
      this.serverOpen = s
      this.el.classList.toggle("open", s === "true")
      this.sync()
    }
    if (!this.closing) this.setState(this.isOpen ? "open" : "closed")
    if (this.kind === "palette") this.paletteUpdated()
  },

  destroyed() {
    this.cancelClose()
    this.observer && this.observer.disconnect()
    this.el.removeEventListener("click", this.onClick)
    if (this.isOpen) this.release()
    if (this.kind === "palette") this.paletteDestroyed()
  },

  attr(name) {
    return this.el.getAttribute("data-lu-" + name)
  },

  state() {
    return this.el.getAttribute("data-state")
  },

  setState(v) {
    if (this.state() !== v) this.el.setAttribute("data-state", v)
  },

  readConfig() {
    this.kind = this.attr("kind")
    this.preventClose = this.attr("prevent-close") === "true"
    this.lockScroll = this.attr("lock-scroll") === "true"
    this.overlay = this.attr("overlay") !== "false"
    this.panel = this.el.firstElementChild
  },

  fire(name, payload = {}) {
    const v = this.attr(name)
    if (v == null || v === "") return
    if (v.startsWith("[")) {
      const ls = this.liveSocket || window.liveSocket
      ls && ls.execJS(this.el, v)
    } else {
      const data = {id: this.el.id, ...payload}
      const target = this.attr("target")
      if (target) this.pushEventTo(target, v, data)
      else this.pushEvent(v, data)
    }
  },

  controls(on) {
    for (const t of document.querySelectorAll(`[aria-controls="${CSS.escape(this.el.id)}"]`))
      t.setAttribute("aria-expanded", String(on))
  },

  close() {
    this.el.classList.remove("open")
    this.sync()
  },

  sync(initial = false) {
    const open = this.el.classList.contains("open")
    if (open === this.isOpen) return
    this.isOpen = open
    open ? this.opened(initial) : this.closed()
  },

  opened(initial) {
    this.cancelClose()
    this.setState("open")
    this.returnTo = document.activeElement
    this.locked = this.lockScroll
    if (this.locked) lock()
    stack.push(this)
    listen()
    this.controls(true)
    if (!initial) this.animate()
    this.focusInitial()
    if (this.kind === "palette") this.paletteOpened()
    if (!initial) this.fire("on-open")
  },

  closed() {
    this.release()
    this.animateClose()
    this.controls(false)
    const t = this.returnTo
    this.returnTo = null
    if (t && t.isConnected && typeof t.focus === "function") t.focus({preventScroll: true})
    this.fire("on-close")
  },

  release() {
    const i = stack.indexOf(this)
    if (i >= 0) stack.splice(i, 1)
    if (this.locked) unlock()
    this.locked = false
  },

  // The panel's keyframes for entering (reversed when leaving): [from, to].
  panelMotion() {
    if (this.kind === "drawer") {
      const side = this.panel.classList.contains("lu-sheet")
        ? "bottom"
        : this.panel.style.left && this.panel.style.left !== "auto"
          ? "left"
          : "right"
      const from = {left: "translateX(-110%)", right: "translateX(110%)", bottom: "translateY(110%)"}[side]
      return {keyframes: [{transform: from}, {transform: "none"}], enter: 260, leave: 200, easing: "cubic-bezier(.2,.8,.2,1)"}
    }
    const spec = (CARD_ANIM[this.attr("animation")] || CARD_ANIM.fade)(this.attr("origin") || "center")
    if (!spec) return null
    if (spec.origin) this.panel.style.transformOrigin = spec.origin
    return {keyframes: spec.keyframes, enter: 220, leave: 160, easing: "cubic-bezier(.2,.8,.2,1)"}
  },

  animate() {
    if (reduced() || !this.panel || !this.el.animate) return
    this.el.animate([{opacity: 0}, {opacity: 1}], {duration: 180, easing: "ease-out"})
    const m = this.panelMotion()
    if (m) this.panel.animate(m.keyframes, {duration: m.enter, easing: m.easing})
  },

  // Leaving: `data-state="closing"` keeps the element on screen while the reverse animation plays,
  // then "closed" hides it (CSS). Without animation (reduced motion) it hides at once.
  animateClose() {
    this.cancelClose()
    if (reduced() || !this.panel || !this.el.animate || !this.el.isConnected) {
      this.setState("closed")
      return
    }
    this.closing = true
    this.setState("closing")
    const anims = [this.el.animate([{opacity: 1}, {opacity: 0}], {duration: 140, easing: "ease-in", fill: "forwards"})]
    const m = this.panelMotion()
    if (m)
      anims.push(
        this.panel.animate([...m.keyframes].reverse(), {duration: m.leave, easing: "ease-in", fill: "forwards"}),
      )
    this.outAnims = anims
    Promise.all(anims.map((a) => a.finished)).then(
      () => this.finishClose(),
      () => {},
    )
  },

  finishClose() {
    this.cancelClose()
    if (!this.isOpen) this.setState("closed")
  },

  cancelClose() {
    this.closing = false
    const anims = this.outAnims
    this.outAnims = null
    if (anims) for (const a of anims) a.cancel()
  },

  focusables() {
    return Array.from(this.panel.querySelectorAll(FOCUSABLE)).filter(visible)
  },

  focusInitial() {
    let target = null
    if (this.kind === "palette") target = this.panel.querySelector(".q input")
    target = target || this.panel.querySelector("[autofocus]")
    if (!target) {
      const list = this.focusables()
      target = list.find((el) => !el.classList.contains("lu-x")) || list[0] || this.panel
    }
    target && target.focus && target.focus({preventScroll: true})
  },

  trap(e) {
    const list = this.focusables()
    if (list.length === 0) {
      e.preventDefault()
      this.panel.focus()
      return
    }
    const first = list[0]
    const last = list[list.length - 1]
    const active = document.activeElement
    if (!this.panel.contains(active)) {
      e.preventDefault()
      first.focus()
    } else if (e.shiftKey && (active === first || active === this.panel)) {
      e.preventDefault()
      last.focus()
    } else if (!e.shiftKey && active === last) {
      e.preventDefault()
      first.focus()
    }
  },

  // ---------------------------------------------------------------- command palette

  paletteInit() {
    this.pActive = -1
    this.pScope = null
    this.pTimer = null
    this.pTyped = false
    this.onPInput = () => {
      this.pTyped = true
      this.pActive = -1
      this.paletteFilter()
      this.paletteSearch()
    }
    this.onPClick = (e) => {
      const chip = e.target.closest(".lu-chip[data-lu-scope]")
      if (chip && this.el.contains(chip)) {
        this.paletteScope(chip.getAttribute("data-lu-scope"))
        this.input && this.input.focus()
        return
      }
      const item = e.target.closest(".lu-menu-item")
      if (!item || !this.el.contains(item)) return
      if (item.hasAttribute("data-lu-assistant")) {
        this.fire("on-assistant", {query: this.input.value})
        this.close()
      } else {
        this.fire("on-select", {value: item.getAttribute("data-lu-value"), new_tab: e.ctrlKey || e.metaKey})
        this.close()
      }
    }
    this.onPMove = (e) => {
      const item = e.target.closest(".lu-menu-item")
      if (!item || !this.el.contains(item)) return
      const i = this.pItems().indexOf(item)
      if (i >= 0 && i !== this.pActive) {
        this.pTyped = true
        this.pSetActive(i)
      }
    }
    this.onPKey = (e) => {
      if (e.target !== this.input) return
      const n = this.pVisible().length
      if (e.key === "ArrowDown" || e.key === "ArrowUp") {
        e.preventDefault()
        this.pTyped = true
        if (n) {
          const down = e.key === "ArrowDown"
          this.pSetActive(down ? (this.pActive < 0 ? 0 : (this.pActive + 1) % n) : this.pActive <= 0 ? n - 1 : this.pActive - 1)
        }
      } else if (e.key === "Enter") {
        const row = this.pVisible()[this.pActive] || this.assistantRow()
        if (row && !row.hidden) {
          e.preventDefault()
          row.dispatchEvent(
            new MouseEvent("click", {bubbles: true, cancelable: true, ctrlKey: e.ctrlKey, metaKey: e.metaKey}),
          )
        }
      }
    }
    this.onShortcut = (e) => {
      const sc = this.attr("shortcut")
      if (!sc) return
      const parts = sc.split("+")
      const key = parts[parts.length - 1].toLowerCase()
      const mod = parts.includes("Mod") ? e.ctrlKey || e.metaKey : true
      if (mod && e.key.toLowerCase() === key && !e.altKey && !e.shiftKey) {
        e.preventDefault()
        this.el.classList.toggle("open")
        this.sync()
      }
    }
    this.el.addEventListener("input", this.onPInput)
    this.el.addEventListener("click", this.onPClick)
    this.el.addEventListener("pointermove", this.onPMove)
    this.el.addEventListener("keydown", this.onPKey)
    document.addEventListener("keydown", this.onShortcut)
    this.paletteDecorate()
  },

  paletteDestroyed() {
    this.el.removeEventListener("input", this.onPInput)
    this.el.removeEventListener("click", this.onPClick)
    this.el.removeEventListener("pointermove", this.onPMove)
    this.el.removeEventListener("keydown", this.onPKey)
    document.removeEventListener("keydown", this.onShortcut)
    clearTimeout(this.pTimer)
  },

  paletteUpdated() {
    this.paletteDecorate()
    this.paletteFilter()
  },

  paletteOpened() {
    this.pTyped = false
    this.input.value = this.attr("query") || ""
    const first = this.el.querySelector(".lu-chip[data-lu-scope]")
    this.pScope = first ? first.getAttribute("data-lu-scope") : null
    this.paletteChips()
    this.paletteFilter()
    this.input.focus({preventScroll: true})
  },

  paletteDecorate() {
    this.input = this.el.querySelector(".q input")
    this.list = this.el.querySelector(".list")
    if (!this.input || !this.list) return
    // The server renders the roles (dialog, combobox, listbox, option), ids and aria-controls.
    this.input.setAttribute("autocomplete", "off")
    this.input.setAttribute("spellcheck", "false")
    // Static previews (inline/bare) never get here; if a row has no id, give it one.
    this.pItems().forEach((el, i) => {
      if (!el.id) el.id = this.el.id + "-opt-" + i
    })
  },

  pItems() {
    return Array.from(this.list.querySelectorAll(":scope > .lu-menu-item:not([data-lu-assistant])"))
  },

  assistantRow() {
    return this.list.querySelector(":scope > [data-lu-assistant]")
  },

  pVisible() {
    return this.pItems().filter((el) => !el.hidden)
  },

  paletteScope(value) {
    this.pScope = value
    this.paletteChips()
    this.paletteFilter()
    this.paletteSearch()
  },

  paletteChips() {
    for (const chip of this.el.querySelectorAll(".lu-chip[data-lu-scope]")) {
      const on = chip.getAttribute("data-lu-scope") === this.pScope
      chip.classList.toggle("on", on)
      chip.setAttribute("aria-pressed", String(on))
    }
  },

  paletteSearch() {
    const ev = this.attr("on-search")
    if (!ev) return
    clearTimeout(this.pTimer)
    this.pTimer = setTimeout(
      () => this.fire("on-search", {query: this.input.value, scope: this.pScope}),
      parseInt(this.attr("debounce") || "200", 10),
    )
  },

  paletteFilter() {
    if (!this.list) return
    const q = norm(this.input.value.trim())
    const server = !!this.attr("on-search")
    const scope = this.pScope
    let anyVisible = false
    for (const item of this.pItems()) {
      const scopeOk = !scope || scope === "all" || item.getAttribute("data-lu-scope") === scope
      const textOk = server || !q || norm(item.textContent + " " + (item.getAttribute("data-lu-keywords") || "")).includes(q)
      const show = scopeOk && textOk
      item.hidden = !show
      anyVisible = anyVisible || show
    }
    // Group headings follow the rows under them.
    let label = null
    let shown = false
    const flush = () => label && (label.hidden = !shown)
    for (const el of this.list.children) {
      if (el.classList.contains("lu-menu-label")) {
        flush()
        label = el
        shown = false
      } else if (el.classList.contains("lu-menu-item") && !el.hasAttribute("data-lu-assistant")) {
        shown = shown || !el.hidden
      }
    }
    flush()

    const assistant = this.assistantRow()
    const always = this.attr("assistant-mode") === "always"
    const showAssistant = assistant && q && (!anyVisible || always)
    if (assistant) {
      assistant.hidden = !showAssistant
      const tpl = assistant.getAttribute("data-lu-label") || ""
      for (const n of assistant.childNodes) {
        if (n.nodeType === 3 && n.textContent.trim()) n.textContent = tpl.replace("%{query}", this.input.value)
      }
    }
    let empty = this.list.querySelector(":scope > [data-lu-empty-el]")
    if (!empty) {
      empty = document.createElement("div")
      empty.setAttribute("data-lu-empty-el", "")
      empty.className = "lu-small lu-muted"
      empty.style.padding = "12px 14px"
      this.list.appendChild(empty)
    }
    empty.textContent = this.attr("empty") || ""
    empty.hidden = anyVisible || !!showAssistant

    const rows = this.pVisible()
    const highlight = this.attr("highlight") !== "typed" || this.pTyped
    this.pSetActive(rows.length && highlight ? Math.min(Math.max(this.pActive, 0), rows.length - 1) : -1, false)
    if (this.pActive >= 0 && this.pActive >= rows.length) this.pSetActive(0, false)
  },

  pSetActive(i, scroll = true) {
    const rows = this.pVisible()
    this.pActive = i
    for (const el of this.pItems()) {
      el.classList.remove("hl")
      el.removeAttribute("aria-selected")
    }
    const row = rows[i]
    if (row) {
      row.classList.add("hl")
      row.setAttribute("aria-selected", "true")
      this.input.setAttribute("aria-activedescendant", row.id)
      if (scroll) row.scrollIntoView({block: "nearest"})
    } else {
      this.input.removeAttribute("aria-activedescendant")
    }
  },
}
