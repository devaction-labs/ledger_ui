// AiComposer: Enter sends the form, Shift+Enter breaks the line; the textarea grows with its
// content (up to 200px) and is cleared after a submit. While the form has data-streaming (or
// data-lu-streaming) Enter does not send (Shift+Enter still breaks the line); it is read at each keypress,
// so Enter sends again as soon as the attribute is gone.
export default {
  mounted() {
    this.max = 200
    this.area = () => this.el.querySelector("textarea")
    this.fit = () => {
      const ta = this.area()
      if (!ta) return
      ta.style.height = "auto"
      ta.style.height = Math.min(ta.scrollHeight, this.max) + "px"
    }
    this.onKeydown = (e) => {
      if (e.target.tagName !== "TEXTAREA") return
      if (e.key !== "Enter" || e.shiftKey || e.isComposing) return
      e.preventDefault()
      if (this.el.hasAttribute("data-streaming") || this.el.hasAttribute("data-lu-streaming")) return
      if (e.target.value.trim() === "") return
      this.el.requestSubmit()
    }
    this.onInput = () => this.fit()
    this.onSubmit = () => {
      // LiveView has read the form by now; clear on the next tick.
      setTimeout(() => {
        const ta = this.area()
        if (ta) {
          ta.value = ""
          this.fit()
        }
      }, 0)
    }
    this.el.addEventListener("keydown", this.onKeydown)
    this.el.addEventListener("input", this.onInput)
    this.el.addEventListener("submit", this.onSubmit)
    this.fit()
  },
  updated() {
    this.fit()
  },
  destroyed() {
    this.el.removeEventListener("keydown", this.onKeydown)
    this.el.removeEventListener("input", this.onInput)
    this.el.removeEventListener("submit", this.onSubmit)
  },
}
