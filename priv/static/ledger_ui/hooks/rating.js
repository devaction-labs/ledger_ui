// <.rating> (interactive): previews the grade under the pointer; the radios do the rest.
export default {
  mounted() {
    this.srv = this.drawn()
    this.value = this.srv
    this.onOver = (e) => { const l = e.target.closest && e.target.closest("label"); if (l) this.paint(this.labels().indexOf(l) + 1) }
    this.onLeave = () => this.paint(this.value)
    this.onChange = () => { this.value = this.checked(); this.paint(this.value) }
    this.el.addEventListener("mouseover", this.onOver)
    this.el.addEventListener("mouseleave", this.onLeave)
    this.el.addEventListener("change", this.onChange)
    this.paint(this.value)
  },
  // The grade the server drew changed: it wins. It did not: the person's grade stays, whatever the patch
  // put back into the radios.
  updated() {
    const sv = this.drawn()
    if (sv !== this.srv) { this.srv = sv; this.value = sv }
    this.labels().forEach((l, i) => { l.querySelector("input").checked = i + 1 === this.value })
    this.paint(this.value)
  },
  destroyed() {
    this.el.removeEventListener("mouseover", this.onOver)
    this.el.removeEventListener("mouseleave", this.onLeave)
    this.el.removeEventListener("change", this.onChange)
  },
  labels() { return [...this.el.querySelectorAll("label")] },
  // `defaultChecked` is the `checked` attribute: what the server drew, whatever the person clicked.
  drawn() { return this.labels().findIndex((l) => l.querySelector("input").defaultChecked) + 1 },
  checked() {
    const i = this.labels().findIndex((l) => l.querySelector("input").checked)
    return i + 1
  },
  paint(n) {
    this.labels().forEach((l, i) => {
      const s = l.querySelector("svg")
      s.setAttribute("data-state", i < n ? "on" : "off")
    })
  },
}
