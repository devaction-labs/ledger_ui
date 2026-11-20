// LedgerUI.Otp: one-time code made of single-character boxes.
//
// Root attributes (LedgerUI.Components.OtpInput): data-lu-length, data-lu-mode ("numeric" |
// "alphanumeric"), data-lu-value (the server's code), data-lu-autofocus, data-lu-on-complete (event name),
// data-lu-on-complete-js (encoded JS commands), data-lu-target. The hidden input [data-lu-otp-value]
// carries the joined code and fires a bubbling `input` event when it changes.


// `data-lu-*` attributes through the camelCase `dataset` API: ds(el).onChange <-> data-lu-on-change.
const ds = (el) =>
  new Proxy(el.dataset, {
    get: (t, k) => (typeof k === "string" ? t["lu" + k[0].toUpperCase() + k.slice(1)] : t[k]),
    set: (t, k, v) => { t["lu" + k[0].toUpperCase() + k.slice(1)] = v; return true },
    has: (t, k) => ("lu" + k[0].toUpperCase() + k.slice(1)) in t,
  })

export default {
  mounted() {
    this.serverValue = ds(this.el).value || ""
    this.last = this.serverValue
    this.bind()
    this.syncBoxes(this.serverValue)
    if (ds(this.el).autofocus === "true") this.focusFirstEmpty()
  },

  updated() {
    this.bind()
    const server = ds(this.el).value || ""
    if (server !== this.serverValue) {
      // The server sent another code: it wins over the browser's.
      this.serverValue = server
      this.syncBoxes(server)
      this.last = server
    } else {
      // LiveView may have put the stale server value back: the browser's code stays.
      this.syncBoxes(this.code())
    }
  },

  destroyed() {
    this.unbind()
  },

  boxes() { return Array.from(this.el.querySelectorAll("[data-lu-otp-box]")) },
  hidden() { return this.el.querySelector("[data-lu-otp-value]") },
  code() { return this.boxes().map((b) => b.value).join("") },
  length() { return this.boxes().length },

  allowed(ch) {
    return ds(this.el).mode === "alphanumeric" ? /^[0-9a-z]$/i.test(ch) : /^[0-9]$/.test(ch)
  },
  clean(text) { return Array.from(text || "").filter((c) => this.allowed(c)) },

  bind() {
    this.unbind()
    this.handlers = []
    const on = (el, ev, fn) => { el.addEventListener(ev, fn); this.handlers.push([el, ev, fn]) }
    this.boxes().forEach((box, i) => {
      on(box, "input", (e) => this.onInput(i, e))
      on(box, "keydown", (e) => this.onKey(i, e))
      on(box, "paste", (e) => this.onPaste(i, e))
      on(box, "focus", () => { this.mark(i, true); box.select() })
      on(box, "blur", () => this.mark(i, false))
    })
  },

  unbind() {
    (this.handlers || []).forEach(([el, ev, fn]) => el.removeEventListener(ev, fn))
    this.handlers = []
  },

  mark(i, on) {
    const cell = this.boxes()[i]?.parentElement
    // the focus ring and the caret read `data-on` (Tailwind `data-on:` utilities)
    if (cell) cell.toggleAttribute("data-on", on)
  },

  // Typed text, an autofill or a paste lands here: spread it from the box `i`.
  onInput(i, e) {
    const box = e.target
    const chars = this.clean(box.value)
    box.value = ""
    if (chars.length === 0) return this.commit()
    // A text as long as the whole code always starts at the first box.
    this.spread(chars.length >= this.length() ? 0 : i, chars)
  },

  onPaste(i, e) {
    e.preventDefault()
    const text = (e.clipboardData || window.clipboardData).getData("text")
    const chars = this.clean(text)
    if (chars.length) this.spread(chars.length >= this.length() ? 0 : i, chars)
  },

  spread(start, chars) {
    const boxes = this.boxes()
    let pos = start
    for (const ch of chars) {
      if (pos >= boxes.length) break
      boxes[pos].value = ch
      pos++
    }
    this.commit()
    const next = Math.min(pos, boxes.length - 1)
    boxes[next].focus()
  },

  onKey(i, e) {
    const boxes = this.boxes()
    const box = boxes[i]
    switch (e.key) {
      case "Backspace":
        e.preventDefault()
        if (box.value) { box.value = ""; this.commit() }
        else if (i > 0) { boxes[i - 1].value = ""; boxes[i - 1].focus(); this.commit() }
        break
      case "Delete":
        e.preventDefault()
        box.value = ""
        this.commit()
        break
      case "ArrowLeft": e.preventDefault(); boxes[Math.max(0, i - 1)].focus(); break
      case "ArrowRight": e.preventDefault(); boxes[Math.min(boxes.length - 1, i + 1)].focus(); break
      case "Home": e.preventDefault(); boxes[0].focus(); break
      case "End": e.preventDefault(); boxes[boxes.length - 1].focus(); break
      default:
        // A single allowed character replaces the box and moves on; the rest is left to `input`.
        if (e.key.length === 1 && !e.ctrlKey && !e.metaKey && !e.altKey) {
          if (this.allowed(e.key)) {
            e.preventDefault()
            box.value = e.key
            this.commit()
            if (i < boxes.length - 1) boxes[i + 1].focus()
          } else {
            e.preventDefault()
          }
        }
    }
  },

  syncBoxes(code) {
    const chars = Array.from(code || "")
    this.boxes().forEach((b, i) => {
      const ch = chars[i] || ""
      if (b.value !== ch) b.value = ch
      b.parentElement.toggleAttribute("data-lu-filled", ch !== "")
    })
    const h = this.hidden()
    const joined = chars.slice(0, this.length()).join("")
    if (h && h.value !== joined) h.value = joined
  },

  commit() {
    const code = this.code()
    this.boxes().forEach((b) => b.parentElement.toggleAttribute("data-lu-filled", b.value !== ""))
    const h = this.hidden()
    if (h) h.value = code
    if (code === this.last) return
    this.last = code
    if (h) h.dispatchEvent(new Event("input", { bubbles: true }))
    if (code.length === this.length() && Array.from(code).length === this.length()) this.complete(code)
  },

  complete(code) {
    const d = ds(this.el)
    const payload = { id: this.el.id, name: (this.hidden() || {}).name || "", value: code }
    if (d.onComplete) {
      if (d.target) this.pushEventTo(d.target, d.onComplete, payload)
      else this.pushEvent(d.onComplete, payload)
    }
    if (d.onCompleteJs && this.liveSocket && this.liveSocket.execJS) {
      this.liveSocket.execJS(this.el, d.onCompleteJs)
    }
  },

  focusFirstEmpty() {
    const boxes = this.boxes()
    const target = boxes.find((b) => !b.value) || boxes[boxes.length - 1]
    if (target) target.focus()
  },
}
