// LedgerUI.Indeterminate: sets the `indeterminate` property of a checkbox rendered with
// `data-ind="1"` (the dash of a partial selection) and keeps `aria-checked="mixed"` in step.
// A click clears the dash (the browser does it); the server brings it back by re-rendering
// `data-ind="1"` after a change of that attribute.

export default {
  mounted() {
    this.last = this.el.dataset.ind
    this.onChange = () => this.sync()
    this.el.addEventListener("change", this.onChange)
    this.apply()
  },

  updated() {
    // A patch that leaves data-ind as it was must not undo the person's click.
    if (this.el.dataset.ind !== this.last) {
      this.last = this.el.dataset.ind
      this.apply()
    } else {
      this.sync()
    }
  },

  destroyed() {
    this.el.removeEventListener("change", this.onChange)
  },

  apply() {
    this.el.indeterminate = this.el.dataset.ind === "1"
    this.sync()
  },

  sync() {
    if (this.el.indeterminate) this.el.setAttribute("aria-checked", "mixed")
    else this.el.removeAttribute("aria-checked")
  },
}
