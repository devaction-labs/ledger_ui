// LedgerUI.Collapse: `collapse` (a native <details>), accordion items and `collapse_text`.
//
// `data-lu-kind` is "collapse" | "item" | "collapse-text". For the first two the state is mirrored in the
// class `open`, so LedgerUI.open/close/toggle("id") work; the server's `open` wins when it changes.

const clampStyle = (lines) =>
  `display:-webkit-box;-webkit-box-orient:vertical;-webkit-line-clamp:${lines};overflow:hidden`

export default {
  mounted() {
    this.readConfig()
    this.serverOpen = this.attr("open")
    if (this.kind === "collapse") this.initDetails()
    else if (this.kind === "item") this.initItem()
    else if (this.kind === "collapse-text") this.initText()
  },

  updated() {
    this.readConfig()
    const s = this.attr("open")
    const serverChanged = s !== this.serverOpen
    this.serverOpen = s
    if (this.kind === "collapse") {
      if (serverChanged) this.el.open = s === "true"
      this.chevron()
    } else if (this.kind === "item") {
      this.itemSetup()
      if (serverChanged) this.apply(s === "true")
      else this.apply(this.state, true)
    } else if (this.kind === "collapse-text") {
      this.textRender()
    }
  },

  destroyed() {
    this.observer && this.observer.disconnect()
    for (const [t, type, fn] of this.listeners || []) t.removeEventListener(type, fn)
  },

  attr(name) {
    return this.el.getAttribute("data-lu-" + name)
  },

  readConfig() {
    this.kind = this.attr("kind")
  },

  listen(target, type, fn) {
    target.addEventListener(type, fn)
    ;(this.listeners = this.listeners || []).push([target, type, fn])
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

  // ---------------------------------------------------------------- <details>

  initDetails() {
    this.mirror()
    this.chevron()
    this.listen(this.el, "toggle", () => {
      this.mirror()
      this.chevron()
      this.fire(this.el.open ? "on-open" : "on-close")
    })
    this.observer = new MutationObserver(() => {
      const want = this.el.classList.contains("open")
      if (want !== this.el.open) this.el.open = want
    })
    this.observer.observe(this.el, {attributes: true, attributeFilter: ["class"]})
  },

  mirror() {
    this.el.classList.toggle("open", this.el.open)
  },

  chevron() {
    const kind = this.attr("chevron")
    const icon = this.el.querySelector(":scope > summary [data-lu-chevron-el]")
    if (!icon || !kind) return
    icon.style.transition = "transform .2s"
    icon.style.transform = this.el.open ? (kind === "right" ? "rotate(90deg)" : "rotate(180deg)") : ""
  },

  // ---------------------------------------------------------------- accordion item

  initItem() {
    this.state = this.el.classList.contains("on")
    this.itemSetup()
    this.apply(this.state, true)
    const toggle = () => this.apply(!this.state)
    this.listen(this.el, "click", (e) => {
      const hd = e.target.closest("[data-part='accordion-header']")
      if (hd && hd.parentElement === this.el) toggle()
    })
    this.listen(this.el, "keydown", (e) => {
      const hd = e.target.closest("[data-part='accordion-header']")
      if (hd && hd.parentElement === this.el && (e.key === "Enter" || e.key === " ")) {
        e.preventDefault()
        toggle()
      }
    })
    this.observer = new MutationObserver(() => {
      const on = this.el.classList.contains("on")
      const op = this.el.classList.contains("open")
      let next = this.state
      if (on !== this.state) next = on
      else if (op !== this.state) next = op
      this.apply(next)
    })
    this.observer.observe(this.el, {attributes: true, attributeFilter: ["class"]})
  },

  itemSetup() {
    this.hd = this.el.querySelector(":scope > [data-part='accordion-header']")
    this.bd = this.el.querySelector(":scope > [data-part='accordion-body']")
    if (!this.hd) return
    // role="button", tabindex, aria-controls/-labelledby and the chevron's label come from the server;
    // the hook only keeps aria-expanded up to date (see apply()).
  },

  apply(next, initial = false) {
    const changed = next !== this.state
    this.state = next
    this.el.classList.toggle("on", next)
    this.el.classList.toggle("open", next)
    this.el.setAttribute("data-state", next ? "open" : "closed")
    if (this.bd) this.bd.style.display = next ? "" : "none"
    if (this.hd) {
      this.hd.setAttribute("aria-expanded", String(next))
      const ch = this.hd.querySelector("[data-part='accordion-chevron']")
      if (ch) {
        ch.style.transition = "transform .2s"
        ch.style.transform = next ? "rotate(180deg)" : ""
      }
    }
    if (!changed || initial) return
    if (next && this.parentMultiple() === false) {
      for (const sib of this.el.parentElement.children) {
        if (sib !== this.el && sib.getAttribute("data-part") === "accordion-item") {
          sib.classList.remove("on")
          sib.classList.remove("open")
          sib.setAttribute("data-state", "closed")
        }
      }
    }
    this.fire(next ? "on-open" : "on-close")
  },

  parentMultiple() {
    const p = this.el.parentElement
    return p && p.getAttribute("data-lu-multiple") === "true"
  },

  // ---------------------------------------------------------------- collapse_text

  initText() {
    this.text = this.el.querySelector(":scope > [id$='-text']")
    this.btn = this.el.querySelector(":scope > [data-lu-more]")
    this.textOpen = this.attr("open") === "true"
    this.listen(this.el, "click", (e) => {
      if (e.target.closest("[data-lu-more]")) {
        this.textOpen = !this.textOpen
        this.textRender()
      }
    })
    this.textRender()
  },

  textRender() {
    this.text = this.el.querySelector(":scope > [id$='-text']")
    this.btn = this.el.querySelector(":scope > [data-lu-more]")
    if (!this.text || !this.btn) return
    const lines = this.attr("lines") || "2"
    this.text.style.cssText = this.textOpen ? "" : clampStyle(lines)
    const label = this.textOpen ? this.attr("less") : this.attr("more")
    // Replace only the button's text, leaving any icon inside it alone.
    const node = Array.from(this.btn.childNodes).find((n) => n.nodeType === 3 && n.textContent.trim())
    if (node && label) node.textContent = label
    this.btn.setAttribute("aria-expanded", String(this.textOpen))
    // Nothing to reveal when the text already fits.
    const overflows = this.text.scrollHeight > this.text.clientHeight + 1
    this.btn.style.display = this.textOpen || overflows ? "" : "none"
  },
}
