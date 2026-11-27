// LedgerUI.Tip: the light tooltips of `tip_host/1` + `tip/1`, with ONE delegated hook.
//
// A trigger is any element with `data-lu-tip="text"` inside the host (plus `data-lu-tip-placement`,
// `-color`, `-arrow` and `-delay`, all optional). Nothing is in the DOM until the pointer enters it or
// the focus reaches it: then the hint (`role="tooltip"`, the same markup and utilities as the heavy
// tooltip: the host carries `data-lu-float-class` and `data-lu-tip-classes`, a JSON by colour) is
// appended to the trigger, the trigger gets `aria-describedby`, and everything is undone when the
// pointer or the focus leaves, on Esc, on scroll and on resize. One hint is shown at a time.

const OPPOSITE = {top: "bottom", bottom: "top", left: "right", right: "left"}
const EASE_OUT = "cubic-bezier(.2,.8,.2,1)"
const SHIFT = {top: "0 4px", bottom: "0 -4px", left: "4px 0", right: "-4px 0"}
const reduced = () => window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches
let seq = 0

export default {
  mounted() {
    this.cur = null
    this.timer = null
    this.classes = null
    this.onOver = (e) => {
      const t = this.trigger(e.target)
      if (t && (!e.relatedTarget || !t.contains(e.relatedTarget))) this.schedule(t)
    }
    this.onOut = (e) => {
      const t = this.trigger(e.target)
      if (t && (!e.relatedTarget || !t.contains(e.relatedTarget))) this.hide(t)
    }
    this.onFocusIn = (e) => {
      const t = this.trigger(e.target)
      if (t) this.schedule(t)
    }
    this.onFocusOut = (e) => {
      const t = this.trigger(e.target)
      if (t && !(e.relatedTarget && t.contains(e.relatedTarget))) this.hide(t)
    }
    this.onKey = (e) => {
      if (e.key === "Escape" && this.cur) this.hideNow()
    }
    this.onReflow = () => this.cur && this.hideNow()
    this.el.addEventListener("mouseover", this.onOver)
    this.el.addEventListener("mouseout", this.onOut)
    this.el.addEventListener("focusin", this.onFocusIn)
    this.el.addEventListener("focusout", this.onFocusOut)
    document.addEventListener("keydown", this.onKey)
    window.addEventListener("scroll", this.onReflow, true)
    window.addEventListener("resize", this.onReflow)
  },

  // A patch may drop the hint (it is not in the server's markup) or change its text: put it back.
  updated() {
    this.classes = null
    if (!this.cur) return
    if (!this.cur.trigger.isConnected) return this.hideNow()
    if (!this.cur.panel.isConnected) this.cur.trigger.appendChild(this.cur.panel)
    const tip = this.cur.panel.firstElementChild
    const text = this.cur.trigger.getAttribute("data-lu-tip")
    if (tip && text != null && tip.firstChild && tip.firstChild.nodeType === 3) tip.firstChild.textContent = text
  },

  destroyed() {
    this.hideNow()
    this.el.removeEventListener("mouseover", this.onOver)
    this.el.removeEventListener("mouseout", this.onOut)
    this.el.removeEventListener("focusin", this.onFocusIn)
    this.el.removeEventListener("focusout", this.onFocusOut)
    document.removeEventListener("keydown", this.onKey)
    window.removeEventListener("scroll", this.onReflow, true)
    window.removeEventListener("resize", this.onReflow)
  },

  trigger(node) {
    const el = node && node.closest ? node.closest("[data-lu-tip]") : null
    return el && this.el.contains(el) ? el : null
  },

  schedule(t) {
    clearTimeout(this.timer)
    if (this.cur && this.cur.trigger === t) return
    const ms = parseInt(t.getAttribute("data-lu-tip-delay") || "0", 10)
    ms > 0 ? (this.timer = setTimeout(() => this.show(t), ms)) : this.show(t)
  },

  hide(t) {
    clearTimeout(this.timer)
    if (this.cur && this.cur.trigger === t) this.hideNow()
  },

  hideNow() {
    clearTimeout(this.timer)
    const c = this.cur
    if (!c) return
    this.cur = null
    c.panel.remove()
    if (c.target.getAttribute("aria-describedby") !== c.had) {
      c.had == null ? c.target.removeAttribute("aria-describedby") : c.target.setAttribute("aria-describedby", c.had)
    }
  },

  show(t) {
    this.hideNow()
    const text = t.getAttribute("data-lu-tip")
    if (!text) return
    if (!this.classes) {
      try {
        this.classes = JSON.parse(this.el.getAttribute("data-lu-tip-classes") || "{}")
      } catch (_) {
        this.classes = {}
      }
    }
    const color = t.getAttribute("data-lu-tip-color") || "neutral"
    const place = t.getAttribute("data-lu-tip-placement") || "top"

    const panel = document.createElement("span")
    panel.id = this.el.id + "-tip-" + ++seq
    panel.setAttribute("data-part", "tooltip-float")
    panel.setAttribute("data-lu-fl", "")
    panel.setAttribute("data-lu-placement", place)
    panel.setAttribute("role", "tooltip")
    panel.className = this.el.getAttribute("data-lu-float-class") || ""
    const tip = document.createElement("span")
    tip.setAttribute("data-part", "tooltip-tip")
    tip.className = this.classes[color] || this.classes.neutral || ""
    tip.appendChild(document.createTextNode(text))
    panel.appendChild(tip)
    t.appendChild(panel)

    // the element the description belongs to: the focusable trigger inside the wrapper, if any
    const target = t.firstElementChild || t
    this.cur = {trigger: t, panel, target, had: target.getAttribute("aria-describedby")}
    target.setAttribute("aria-describedby", this.cur.had ? this.cur.had + " " + panel.id : panel.id)
    this.place(panel, place)
    if (t.getAttribute("data-lu-tip-arrow") !== "false") this.drawArrow(tip, this.cur.side || place)
    if (!reduced() && panel.animate) {
      const side = (this.cur.side || place).split("-")[0]
      panel.animate([{opacity: 0, translate: SHIFT[side] || "0 0"}, {opacity: 1, translate: "0 0"}], {
        duration: 150,
        easing: EASE_OUT,
      })
    }
  },

  // flips to the opposite side when the hint does not fit the viewport
  place(panel, pref) {
    const fits = () => {
      const r = panel.getBoundingClientRect()
      return r.left >= 0 && r.top >= 0 && r.right <= window.innerWidth && r.bottom <= window.innerHeight
    }
    this.cur.side = pref
    if (fits()) return
    const [side, align] = pref.split("-")
    const flipped = OPPOSITE[side] + (align ? "-" + align : "")
    panel.setAttribute("data-lu-placement", flipped)
    if (fits()) this.cur.side = flipped
    else panel.setAttribute("data-lu-placement", pref)
  },

  drawArrow(box, placement) {
    const arrow = document.createElement("i")
    arrow.setAttribute("data-lu-arrow-el", "")
    arrow.setAttribute("aria-hidden", "true")
    box.appendChild(arrow)
    if (getComputedStyle(box).position === "static") box.style.position = "relative"
    const [side, align] = placement.split("-")
    const st = arrow.style
    st.cssText = "position:absolute;width:8px;height:8px;background:inherit;transform:rotate(45deg);pointer-events:none"
    // the arrow sits on the edge of the bubble that faces the trigger: a hint above it has it at its bottom
    st[OPPOSITE[side]] = "-5px"
    const horizontal = side === "top" || side === "bottom"
    if (align === "start") st[horizontal ? "left" : "top"] = "14px"
    else if (align === "end") st[horizontal ? "right" : "bottom"] = "14px"
    else {
      st[horizontal ? "left" : "top"] = "50%"
      st[horizontal ? "marginLeft" : "marginTop"] = "-4px"
    }
  },
}
