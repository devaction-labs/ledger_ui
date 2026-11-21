// LedgerUI.Segmented: the chosen segment slides without a round trip.
//
// Buttons carry `data-lu-value`; the choice is written to the hidden input (`[data-lu-v]`) or, for
// `radio_group variant="segmented"`, to the radio that precedes each button, and a bubbling
// `input` event runs the form's `phx-change`. A value rendered by the server wins; a patch that
// does not change it keeps the person's choice. The chosen look is drawn from `aria-pressed`
// (Tailwind `aria-pressed:` utilities), so the hook only has to keep that attribute in step.

export default {
  mounted() {
    this.srv = this.serverValue()
    this.value = this.srv
    this.onClick = (e) => {
      const b = e.target.closest("button[data-lu-value]")
      if (b && this.el.contains(b) && !b.disabled) this.choose(b.dataset.luValue, true)
    }
    this.onKey = (e) => this.key(e)
    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("keydown", this.onKey)
  },

  updated() {
    const sv = this.serverValue()
    if (sv !== this.srv) {
      this.srv = sv
      this.value = sv
    }
    this.apply()
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("keydown", this.onKey)
  },

  buttons() { return [...this.el.querySelectorAll("button[data-lu-value]")] },
  radio(b) {
    const p = b.previousElementSibling
    return p && p.matches('input[type="radio"]') ? p : null
  },

  serverValue() {
    const r = this.buttons().map((b) => this.radio(b)).find((r) => r && r.checked)
    if (r) return r.value
    const h = this.el.querySelector("input[data-lu-v]")
    if (h) return h.value
    const on = this.buttons().find((b) => b.getAttribute("aria-pressed") === "true")
    return on ? on.dataset.luValue : ""
  },

  apply() {
    const btns = this.buttons()
    const focus = btns.find((b) => b.dataset.luValue === this.value && !b.disabled) || btns.find((b) => !b.disabled)
    for (const b of btns) {
      const on = b.dataset.luValue === this.value
      b.setAttribute("aria-pressed", String(on))
      b.setAttribute("role", this.radio(b) ? "radio" : b.getAttribute("role") || "")
      if (!b.getAttribute("role")) b.removeAttribute("role")
      b.tabIndex = b === focus ? 0 : -1
      const r = this.radio(b)
      if (r) r.checked = on
    }
    const h = this.el.querySelector("input[data-lu-v]")
    if (h && h.value !== this.value) h.value = this.value
  },

  choose(value, user) {
    if (value === this.value) return
    this.value = value
    this.apply()
    if (!user) return
    const h = this.el.querySelector("input[data-lu-v]")
    const radio = this.buttons().map((b) => this.radio(b)).find((r) => r && r.checked)
    const src = radio || h || this.el
    src.dispatchEvent(new Event("input", { bubbles: true }))
    if (radio) radio.dispatchEvent(new Event("change", { bubbles: true }))
    const on = this.el.dataset.luOnChange
    if (on) {
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

  key(e) {
    const btns = this.buttons().filter((b) => !b.disabled)
    const i = btns.indexOf(document.activeElement)
    if (i < 0) return
    let next = null
    if (e.key === "ArrowRight" || e.key === "ArrowDown") next = btns[(i + 1) % btns.length]
    else if (e.key === "ArrowLeft" || e.key === "ArrowUp") next = btns[(i - 1 + btns.length) % btns.length]
    else if (e.key === "Home") next = btns[0]
    else if (e.key === "End") next = btns[btns.length - 1]
    if (next) {
      e.preventDefault()
      btns.forEach((b) => (b.tabIndex = b === next ? 0 : -1))
      next.focus()
    }
  },
}
