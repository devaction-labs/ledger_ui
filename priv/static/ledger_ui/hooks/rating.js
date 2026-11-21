// <.rating> (interactive): previews the grade under the pointer; the radios do the rest.
export default {
  mounted() {
    this.onOver = (e) => { const l = e.target.closest && e.target.closest("label"); if (l) this.paint(this.labels().indexOf(l) + 1) }
    this.onLeave = () => this.paint(this.checked())
    this.onChange = () => this.paint(this.checked())
    this.el.addEventListener("mouseover", this.onOver)
    this.el.addEventListener("mouseleave", this.onLeave)
    this.el.addEventListener("change", this.onChange)
    this.paint(this.checked())
  },
  updated() { this.paint(this.checked()) },
  destroyed() {
    this.el.removeEventListener("mouseover", this.onOver)
    this.el.removeEventListener("mouseleave", this.onLeave)
    this.el.removeEventListener("change", this.onChange)
  },
  labels() { return [...this.el.querySelectorAll("label")] },
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
