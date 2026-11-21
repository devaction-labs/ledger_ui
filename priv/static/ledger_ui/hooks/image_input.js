// <.image_input name=...>: shows the chosen file at once; the button reverts it, or empties the
// field and sets the hidden `<name>_remove` input to "1".
export default {
  mounted() {
    this.first = this.frame().querySelector("img")?.getAttribute("src") || null
    this.onChange = (e) => { if (e.target === this.input()) this.pick() }
    this.onClick = (e) => { if (e.target.closest && e.target.closest("[data-image-reset]")) this.reset() }
    this.onEnter = () => this.flag("hover", true)
    this.onLeave = () => this.flag("hover", false)
    this.el.addEventListener("change", this.onChange)
    this.el.addEventListener("click", this.onClick)
    this.frame().addEventListener("mouseenter", this.onEnter)
    this.frame().addEventListener("mouseleave", this.onLeave)
  },
  destroyed() {
    this.el.removeEventListener("change", this.onChange)
    this.el.removeEventListener("click", this.onClick)
    this.frame()?.removeEventListener("mouseenter", this.onEnter)
    this.frame()?.removeEventListener("mouseleave", this.onLeave)
    if (this.url) URL.revokeObjectURL(this.url)
  },
  // `data-state` holds the frame's flags (`has`, `hover`) as space separated tokens
  flag(name, on) {
    const f = this.frame(), t = new Set((f.getAttribute("data-state") || "").split(" ").filter(Boolean))
    on ? t.add(name) : t.delete(name)
    t.size ? f.setAttribute("data-state", [...t].join(" ")) : f.removeAttribute("data-state")
  },
  frame() { return this.el.querySelector("[data-part=image-input-frame]") },
  input() { return this.el.querySelector("input[type=file]") },
  removal() { return this.el.querySelector("[data-image-remove]") },
  button() { return this.el.querySelector("[data-image-reset]") },

  show(src) {
    const f = this.frame()
    let img = f.querySelector("img")
    f.querySelector("[data-part=image-input-placeholder]")?.remove()
    if (src) {
      if (!img) { img = document.createElement("img"); img.alt = ""; img.className = "absolute inset-0 size-full object-cover"; f.prepend(img) }
      img.src = src
      this.flag("has", true)
    } else {
      img && img.remove()
      this.flag("has", false)
    }
  },
  pick() {
    const file = this.input().files[0]
    if (!file) return
    if (this.url) URL.revokeObjectURL(this.url)
    this.url = URL.createObjectURL(file)
    this.show(this.url)
    this.removal().value = ""
    this.button().hidden = false
  },
  reset() {
    if (this.input().files.length) {
      // a file is chosen: put the first picture back
      this.input().value = ""
      this.show(this.first)
      this.button().hidden = !this.first
    } else {
      // nothing chosen: empty the field
      this.show(null)
      this.removal().value = "1"
      this.button().hidden = true
    }
  },
}
