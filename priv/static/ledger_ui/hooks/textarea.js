// LedgerUI.Textarea: live character counter, autogrow and the {{token}} mirror.
//
// Attributes on the <textarea> (LedgerUI.Components.Textarea): data-lu-counter (id of the counter
// element), data-lu-min, data-lu-max, data-lu-format, data-lu-min-format, data-lu-autogrow, data-lu-max-rows,
// data-lu-tokens.


// `data-lu-*` attributes through the camelCase `dataset` API: ds(el).onChange <-> data-lu-on-change.
const ds = (el) =>
  new Proxy(el.dataset, {
    get: (t, k) => (typeof k === "string" ? t["lu" + k[0].toUpperCase() + k.slice(1)] : t[k]),
    set: (t, k, v) => { t["lu" + k[0].toUpperCase() + k.slice(1)] = v; return true },
    has: (t, k) => ("lu" + k[0].toUpperCase() + k.slice(1)) in t,
  })

const TOKEN = /\{\{[^{}]*\}\}/g

export default {
  mounted() {
    this.onInput = () => this.refresh()
    this.onScroll = () => this.syncScroll()
    this.el.addEventListener("input", this.onInput)
    this.el.addEventListener("scroll", this.onScroll)
    this.refresh()
  },

  updated() { this.refresh() },

  destroyed() {
    this.el.removeEventListener("input", this.onInput)
    this.el.removeEventListener("scroll", this.onScroll)
  },

  refresh() {
    const d = ds(this.el)
    if (d.counter) this.counter(d)
    if (d.autogrow === "true") this.grow(d)
    if (d.tokens === "true") this.mirror()
  },

  counter(d) {
    const out = document.getElementById(d.counter)
    if (!out) return
    const count = Array.from(this.el.value).length
    const max = d.max ? parseInt(d.max, 10) : null
    const min = d.min ? parseInt(d.min, 10) : null
    let text
    if (max) text = (d.format || "%{count} / %{max}").replace("%{count}", count).replace("%{max}", max)
    else if (min) text = (d.minFormat || "%{count} / %{min}").replace("%{count}", count).replace("%{min}", min)
    else text = String(count)
    if (out.textContent !== text) out.textContent = text
    // the counter's colour reads `data-state` (Tailwind `data-[state=over]:` utilities)
    const state = !max ? "" : count > max ? "over" : count * 10 >= max * 9 ? "warn" : ""
    if (state) out.dataset.state = state
    else delete out.dataset.state
  },

  grow(d) {
    const el = this.el
    el.style.height = "auto"
    const cs = getComputedStyle(el)
    const pad = parseFloat(cs.paddingTop) + parseFloat(cs.paddingBottom)
    let height = el.scrollHeight
    let scroll = false
    if (d.maxRows) {
      const line = parseFloat(cs.lineHeight) || 21
      const max = line * parseInt(d.maxRows, 10) + pad
      if (height > max) { height = max; scroll = true }
    }
    el.style.height = height + "px"
    el.style.overflowY = scroll ? "auto" : "hidden"
  },

  mirror() {
    const box = this.el.parentElement && this.el.parentElement.querySelector("[data-lu-mirror]")
    if (!box) return
    const text = this.el.value
    const frag = document.createDocumentFragment()
    let last = 0
    for (const m of text.matchAll(TOKEN)) {
      frag.append(text.slice(last, m.index))
      const code = document.createElement("code")
      code.textContent = m[0]
      frag.append(code)
      last = m.index + m[0].length
    }
    frag.append(text.slice(last) + "​")
    box.replaceChildren(frag)
    this.syncScroll()
  },

  syncScroll() {
    const box = this.el.parentElement && this.el.parentElement.querySelector("[data-lu-mirror]")
    if (box) box.scrollTop = this.el.scrollTop
  },
}
