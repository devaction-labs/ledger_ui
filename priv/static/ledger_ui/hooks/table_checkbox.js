// Draws the "partial selection" dash of a table checkbox: `data-ind="1"` on the input means
// `indeterminate` (a DOM property, so it cannot be set from the server markup).
export default {
  mounted() { this.sync() },
  updated() { this.sync() },
  sync() { this.el.indeterminate = this.el.dataset.ind === "1" && !this.el.checked }
}
