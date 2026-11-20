// LedgerUI.ChoiceGroup: keeps the `on` look of radio/checkbox chips, tiles and cards in step
// with the native input they hold (the stylesheet draws `.on`, not `:checked`).
//
// The inputs are real, so the form, the arrow keys and `phx-change` work natively; this hook
// only mirrors `checked` onto the label (`on`, the `✓` tick of a checkbox chip, the accent tint
// of a card's icon box).

export default {
  mounted() {
    this.onChange = () => this.sync()
    this.el.addEventListener("change", this.onChange)
    this.sync()
  },

  updated() {
    this.sync()
  },

  destroyed() {
    this.el.removeEventListener("change", this.onChange)
  },

  sync() {
    for (const input of this.el.querySelectorAll("input[type=radio], input[type=checkbox]")) {
      const label = input.closest("label")
      if (!label) continue
      if (label.matches(".lu-rchip, .lu-rtile")) label.classList.toggle("on", input.checked)
      const tick = label.querySelector("[data-lu-tick]")
      if (tick) tick.hidden = !input.checked
      const ic = label.querySelector(".lu-choice-ic")
      if (ic) ic.classList.toggle("acc", input.checked)
    }
  },
}
