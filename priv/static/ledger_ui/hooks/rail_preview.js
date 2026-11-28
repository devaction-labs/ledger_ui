// LedgerUI.RailPreview: the preview cards of `rail/1`.
// Every item (`[data-rail-item]`) points at its card with `aria-describedby`; the cards are in the DOM, hidden.
// This hook only shows and places them:
//   * opens after `data-lu-delay` ms (default 150) of hover or focus on an item;
//   * with a card already open, the next item swaps it at once and without the enter animation;
//   * closes when the pointer or the focus leaves the rail, and on Esc;
//   * the card sits beside the item (right, or left when there is no room), inside the viewport, and its
//     arrow points at the icon (`--ay`).
// Nothing listens on `document` or `window` while no card is open: the Esc listener is added on open and
// removed on close. Cards are off below `md` (CSS) and with reduced motion they do not animate.
const GAP = 12
const MARGIN = 8
const ARROW = 6 // half the 12px arrow
const reduced = () => !!(window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches)

export default {
  mounted() {
    this.cur = null // {item, card}
    this.timer = null
    this.target = null
    this.onKey = (e) => { if (e.key === "Escape") this.close() }
    this.onOver = (e) => {
      const item = this.item(e.target)
      if (item) this.want(item)
    }
    this.onOut = (e) => {
      // the pointer left an item for a gap: no preview is due any more (an open card stays until the rail is left)
      if (this.item(e.target) && !this.item(e.relatedTarget)) this.cancel()
    }
    this.onFocusIn = (e) => {
      const item = this.item(e.target)
      if (item) this.want(item)
    }
    this.onFocusOut = (e) => {
      if (!e.relatedTarget || !this.el.contains(e.relatedTarget)) this.close()
    }
    this.onLeave = () => this.close()
    this.el.addEventListener("mouseover", this.onOver)
    this.el.addEventListener("mouseout", this.onOut)
    this.el.addEventListener("focusin", this.onFocusIn)
    this.el.addEventListener("focusout", this.onFocusOut)
    this.el.addEventListener("mouseleave", this.onLeave)
  },

  // A patch drops the attributes the client set on the open card: set them again.
  updated() {
    if (!this.cur) return
    if (!this.cur.item.isConnected || !this.cur.card.isConnected) return this.close()
    this.cur.card.setAttribute("data-open", "")
    this.place(this.cur.item, this.cur.card)
  },

  destroyed() {
    this.close()
    this.el.removeEventListener("mouseover", this.onOver)
    this.el.removeEventListener("mouseout", this.onOut)
    this.el.removeEventListener("focusin", this.onFocusIn)
    this.el.removeEventListener("focusout", this.onFocusOut)
    this.el.removeEventListener("mouseleave", this.onLeave)
  },

  item(node) {
    const el = node && node.closest ? node.closest("[data-rail-item]") : null
    return el && this.el.contains(el) ? el : null
  },

  card(item) {
    const id = item.getAttribute("aria-describedby")
    return id ? document.getElementById(id) : null
  },

  delay() {
    const n = parseInt(this.el.getAttribute("data-lu-delay"), 10)
    return Number.isFinite(n) && n >= 0 ? n : 150
  },

  cancel() {
    if (this.timer) clearTimeout(this.timer)
    this.timer = null
    this.target = null
  },

  want(item) {
    if (this.cur && this.cur.item === item) return this.cancel()
    this.cancel()
    // a card is open: swap without waiting and without animating
    if (this.cur) return this.show(item, false)
    this.target = item
    this.timer = setTimeout(() => {
      this.timer = null
      const t = this.target
      this.target = null
      if (t && t.isConnected) this.show(t, true)
    }, this.delay())
  },

  show(item, animate) {
    const card = this.card(item)
    const first = !this.cur
    if (this.cur) this.hide()
    if (!card) return this.close()
    card.setAttribute("data-open", "")
    this.cur = {item, card}
    this.place(item, card)
    if (first) document.addEventListener("keydown", this.onKey)
    if (animate && !reduced() && card.animate) {
      const side = card.getAttribute("data-side") === "left" ? 4 : -4
      card.animate(
        [{opacity: 0, transform: `translateX(${side}px)`}, {opacity: 1, transform: "none"}],
        {duration: 140, easing: "cubic-bezier(.2,.8,.2,1)"}
      )
    }
  },

  hide() {
    if (!this.cur) return
    this.cur.card.removeAttribute("data-open")
    this.cur.card.removeAttribute("data-side")
    this.cur = null
  },

  close() {
    this.cancel()
    this.hide()
    document.removeEventListener("keydown", this.onKey)
  },

  place(item, card) {
    const r = item.getBoundingClientRect()
    const vw = document.documentElement.clientWidth || window.innerWidth
    const vh = document.documentElement.clientHeight || window.innerHeight
    const w = card.offsetWidth || 236
    const h = card.offsetHeight || 0
    const left = r.right + GAP + w + MARGIN <= vw || r.left - GAP - w < MARGIN
    const x = left ? r.right + GAP : r.left - GAP - w
    const cy = r.top + r.height / 2
    let y = cy - (26 + ARROW)
    y = Math.max(MARGIN, Math.min(y, vh - h - MARGIN))
    const ay = Math.max(10, Math.min(cy - y - ARROW, Math.max(10, h - 22)))
    if (left) card.removeAttribute("data-side")
    else card.setAttribute("data-side", "left")
    card.style.left = `${Math.round(x)}px`
    card.style.top = `${Math.round(y)}px`
    card.style.setProperty("--ay", `${Math.round(ay)}px`)
  },
}
