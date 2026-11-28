// LedgerUI.PillSelect: chip toggles chosen in the browser (the chosen look is `aria-pressed`).
//
// One choice (radio-like) or several (`data-lu-multiple`). The values travel in hidden inputs named
// like the field; a bubbling `input` event runs the form's `phx-change`. A value rendered by the
// server wins; a patch that does not change it keeps the person's choice.

const PATHS = {
  x: '<path d="M19.0005 4.99988L5.00049 18.9999M5.00049 4.99988L19.0005 18.9999"/>',
  check: '<path d="M5 14L8.5 17.5L19 6.5"/>',
}
// `cls` comes from the server (`data-lu-icon-class`): the utilities of `<.icon size="sm">`.
const icon = (name, cls = "") => {
  const t = document.createElement("template")
  t.innerHTML = `<svg class="${cls}" viewBox="0 0 24 24" aria-hidden="true" data-icon="${name}">${PATHS[name]}</svg>`
  return t.content.firstElementChild
}

export default {
  mounted() {
    this.srv = this.serverValues()
    this.values = this.srv
    this.onClick = (e) => {
      const b = e.target.closest("button[data-lu-toggle]")
      if (b && this.el.contains(b) && !b.disabled) this.toggle(this.val(b))
    }
    this.el.addEventListener("click", this.onClick)
  },

  updated() {
    const sv = this.serverValues()
    if (JSON.stringify(sv) !== JSON.stringify(this.srv)) {
      this.srv = sv
      this.values = sv
    }
    this.apply()
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
  },

  // `data-lu-value` is only rendered when the value differs from the label.
  val(b) {
    if (b.dataset.luValue !== undefined) return b.dataset.luValue
    return [...b.childNodes].filter((n) => n.nodeType === 3).map((n) => n.textContent).join("").trim()
  },
  multiple() { return "multiple" in this.el.dataset },
  buttons() { return [...this.el.querySelectorAll("button[data-lu-toggle]")] },
  hiddenInputs() { return [...this.el.querySelectorAll('input[type="hidden"]')] },

  serverValues() {
    const named = this.hiddenInputs().filter((i) => i.value !== "")
    if (named.length || this.hiddenInputs().length) return named.map((i) => i.value)
    return this.buttons().filter((b) => b.getAttribute("aria-pressed") === "true").map((b) => this.val(b))
  },

  apply() {
    const multiple = this.multiple()
    for (const b of this.buttons()) {
      const on = this.values.includes(this.val(b))
      b.setAttribute("aria-pressed", String(on))
      if (multiple) {
        const ck = b.querySelector(":scope > svg[data-icon]")
        if (on && !ck) {
          b.insertBefore(icon("check", this.el.dataset.luIconClass), b.firstChild)
        } else if (!on && ck) {
          ck.remove()
        }
      }
    }
    // hidden inputs
    const any = this.hiddenInputs()
    if (!any.length) return
    const name = any[0].name
    any.filter((i) => i.hasAttribute("data-lu-v")).forEach((i) => i.remove())
    const values = this.values.length ? this.values : multiple ? [] : [""]
    for (const v of values) {
      const i = document.createElement("input")
      i.type = "hidden"
      i.name = name
      i.value = v
      i.setAttribute("data-lu-v", "")
      this.el.appendChild(i)
    }
  },

  toggle(value) {
    if (this.multiple()) {
      this.values = this.values.includes(value) ? this.values.filter((v) => v !== value) : [...this.values, value]
    } else {
      this.values = [value]
    }
    this.apply()
    const src = this.el.querySelector("input[data-lu-v]") || this.el
    src.dispatchEvent(new Event("input", { bubbles: true }))
    const on = this.el.dataset.luOnChange
    if (on) {
      // A `%JS{}` (its JSON starts with `[`) runs as it is, as in `segmented`; a name is pushed with the value.
      if (on.startsWith("[")) {
        this.js ? this.js().exec(on) : this.liveSocket.execJS(this.el, on)
      } else {
        let target = this.el.dataset.luTarget
        if (target && /^\d+$/.test(target)) target = parseInt(target, 10)
        const payload = { id: this.el.id, value }
        target ? this.pushEventTo(target, on, payload) : this.pushEvent(on, payload)
      }
    }
  },
}
