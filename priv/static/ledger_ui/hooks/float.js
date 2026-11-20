// LedgerUI.Float: tooltip, popover and the notification center's panel.
//
// Root: an element with `data-lu-kind` ("tooltip" | "popover"), a trigger (its first child) and the
// floating `[data-lu-fl]` element, placed by its `data-lu-placement` (utilities, see Support.float_class/0). The state is the class `open` on the root (what
// LedgerUI.open/close/toggle change); the hook shows/hides `.fl`, places it (flipping to the
// fallbacks when there is no room), draws the arrow and runs on_open / on_close.

const OPPOSITE = {top: "bottom", bottom: "top", left: "right", right: "left"}
const EASE_OUT = "cubic-bezier(.2,.8,.2,1)"
// A few px toward the trigger: the floating box slides away from it as it appears.
const SHIFT = {top: "0 4px", bottom: "0 -4px", left: "4px 0", right: "-4px 0"}
const reduced = () => window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches

export default {
  mounted() {
    this.isOpen = false
    this.timer = null
    this.pointer = null
    this.readConfig()
    this.observer = new MutationObserver(() => this.sync())
    this.observer.observe(this.el, {attributes: true, attributeFilter: ["class"]})
    this.bind()
    // The server renders role="tooltip", the ids and the trigger's ARIA (the component passes them
    // to the trigger slot); fall back to setting them on a trigger that does not spread them.
    if (this.kind === "tooltip" && this.fl && this.trigger.setAttribute && this.fl.id &&
        !this.trigger.hasAttribute("aria-describedby")) {
      this.trigger.setAttribute("aria-describedby", this.fl.id)
    }
    if (this.kind === "popover" && this.fl && this.trigger.setAttribute) {
      if (!this.trigger.hasAttribute("aria-haspopup")) this.trigger.setAttribute("aria-haspopup", "dialog")
      if (this.fl.id && !this.trigger.hasAttribute("aria-controls")) this.trigger.setAttribute("aria-controls", this.fl.id)
    }
    this.serverOpen = this.attr("open")
    if (this.fl && !this.fl.hidden) {
      this.el.classList.add("open")
      this.sync(true)
    }
    if (this.attr("notifications")) this.ncInit()
  },

  updated() {
    this.readConfig()
    const s = this.attr("open")
    if (s !== this.serverOpen) {
      this.serverOpen = s
      this.el.classList.toggle("open", s === "true")
      this.sync()
    }
    if (this.fl && !this.leaving) this.fl.hidden = !this.isOpen
    if (this.isOpen) this.place()
    if (this.attr("notifications")) this.ncApply()
  },

  destroyed() {
    this.cancelLeave()
    this.observer && this.observer.disconnect()
    clearTimeout(this.timer)
    this.unbind()
    this.stopOpenListeners()
    this.ncDestroy && this.ncDestroy()
  },

  attr(name) {
    return this.el.getAttribute("data-lu-" + name)
  },

  readConfig() {
    this.kind = this.attr("kind")
    this.mode = this.attr("trigger") || "click"
    this.delay = parseInt(this.attr("delay") || "0", 10)
    this.follow = this.attr("follow")
    this.fl = this.el.querySelector(":scope > [data-lu-fl]")
    this.trigger = Array.from(this.el.children).find((c) => c !== this.fl && !c.classList.contains("lu-cur2")) || this.el
  },

  fire(name, payload = {}) {
    const v = this.attr(name)
    if (v == null || v === "") return
    if (v.startsWith("[")) {
      const ls = this.liveSocket || window.liveSocket
      ls && ls.execJS(this.el, v)
    } else {
      const data = {id: this.el.id, ...payload}
      const target = this.attr("target")
      if (target) this.pushEventTo(target, v, data)
      else this.pushEvent(v, data)
    }
  },

  // ---------------------------------------------------------------- triggers

  bind() {
    const hover = this.mode === "hover"
    const focus = this.mode === "hover" || this.mode === "focus"
    this.handlers = []
    const on = (target, type, fn) => {
      target.addEventListener(type, fn)
      this.handlers.push([target, type, fn])
    }
    if (hover) {
      on(this.el, "mouseenter", (e) => {
        this.pointer = e
        this.schedule(true)
      })
      on(this.el, "mouseleave", () => this.schedule(false))
    }
    if (focus) {
      on(this.el, "focusin", () => this.schedule(true))
      on(this.el, "focusout", (e) => {
        if (!this.el.contains(e.relatedTarget)) this.schedule(false)
      })
    }
    if (this.mode === "click") {
      on(this.el, "click", (e) => {
        if (this.fl && this.fl.contains(e.target)) return
        if (this.trigger.contains(e.target)) this.toggle()
      })
    }
    on(this.el, "pointermove", (e) => {
      this.pointer = e
      if (this.isOpen && this.follow && this.follow !== "initial") this.followCursor()
    })
  },

  unbind() {
    for (const [t, type, fn] of this.handlers || []) t.removeEventListener(type, fn)
    this.handlers = []
  },

  schedule(open) {
    clearTimeout(this.timer)
    const ms = this.kind === "tooltip" ? this.delay : open ? 0 : 80
    const run = () => this.setOpen(open)
    ms > 0 ? (this.timer = setTimeout(run, ms)) : run()
  },

  toggle() {
    this.setOpen(!this.isOpen)
  },

  setOpen(open) {
    this.el.classList.toggle("open", open)
    this.sync()
  },

  // ---------------------------------------------------------------- state

  sync(initial = false) {
    const open = this.el.classList.contains("open")
    if (open === this.isOpen) return
    this.isOpen = open
    open ? this.opened(initial) : this.closed()
  },

  opened(initial) {
    if (!this.fl) return
    this.cancelLeave()
    this.fl.hidden = false
    if (this.kind !== "tooltip") this.trigger.setAttribute && this.trigger.setAttribute("aria-expanded", "true")
    if (this.attr("interactive") === "false") this.fl.style.pointerEvents = "none"
    this.place()
    if (!initial && !reduced() && this.fl.animate) {
      const from = this.shift()
      this.fl.animate([{opacity: 0, ...from}, {opacity: 1, ...this.restFrame()}], {
        duration: this.enterMs(),
        easing: EASE_OUT,
      })
    }
    this.startOpenListeners()
    if (!initial) this.fire("on-open")
  },

  closed() {
    if (this.fl) this.leave()
    if (this.kind !== "tooltip") this.trigger.setAttribute && this.trigger.setAttribute("aria-expanded", "false")
    this.stopOpenListeners()
    this.fire("on-close")
  },

  // Offset of the start frame, by the side it opens on. Skipped when the box follows the cursor
  // (it owns the `translate` property then).
  shift() {
    if (this.follow) return {}
    const side = (this.current || "top").split("-")[0]
    return {translate: SHIFT[side] || "0 0"}
  },

  // `duration` is the tooltip's API attr; its default (300) is the component default, not a choice,
  // so it maps to the short 150ms; any other value is honored as given.
  enterMs() {
    const d = parseInt(this.attr("duration") || "150", 10)
    return d === 300 ? 150 : d
  },

  restFrame() {
    return this.follow ? {} : {translate: "0 0"}
  },

  // Leaving: a short fade-out + offset, then `hidden`. No animation under reduced motion.
  leave() {
    const fl = this.fl
    this.cancelLeave()
    if (reduced() || !fl.animate || fl.hidden || !fl.isConnected) {
      fl.hidden = true
      return
    }
    const a = fl.animate([{opacity: 1, ...this.restFrame()}, {opacity: 0, ...this.shift()}], {duration: 120, easing: "ease-in"})
    this.leaving = a
    a.finished.then(
      () => {
        if (this.leaving === a) {
          this.leaving = null
          if (!this.isOpen) fl.hidden = true
        }
      },
      () => {},
    )
  },

  cancelLeave() {
    if (!this.leaving) return
    const a = this.leaving
    this.leaving = null
    a.cancel()
  },

  startOpenListeners() {
    this.onKey = (e) => {
      if (e.key === "Escape") this.setOpen(false)
    }
    this.onOutside = (e) => {
      if (this.mode === "click" && !this.el.contains(e.target)) this.setOpen(false)
    }
    this.onReflow = () => {
      if (!this.isOpen) return
      const r = this.trigger.getBoundingClientRect()
      if (r.bottom < 0 || r.top > window.innerHeight || r.right < 0 || r.left > window.innerWidth) this.setOpen(false)
      else this.place()
    }
    document.addEventListener("keydown", this.onKey)
    document.addEventListener("pointerdown", this.onOutside, true)
    window.addEventListener("scroll", this.onReflow, true)
    window.addEventListener("resize", this.onReflow)
  },

  stopOpenListeners() {
    if (!this.onKey) return
    document.removeEventListener("keydown", this.onKey)
    document.removeEventListener("pointerdown", this.onOutside, true)
    window.removeEventListener("scroll", this.onReflow, true)
    window.removeEventListener("resize", this.onReflow)
    this.onKey = null
  },

  // ---------------------------------------------------------------- placement

  place() {
    const fl = this.fl
    if (!fl) return
    const pref = this.attr("placement") || "top"
    const fallbacks = (this.attr("fallbacks") || "").split(",").filter(Boolean)
    const fits = () => {
      const r = fl.getBoundingClientRect()
      return r.left >= 0 && r.top >= 0 && r.right <= window.innerWidth && r.bottom <= window.innerHeight
    }
    let chosen = pref
    this.setPlacement(pref)
    if (!fits()) {
      for (const p of fallbacks) {
        this.setPlacement(p)
        if (fits()) {
          chosen = p
          break
        }
        chosen = null
      }
      if (chosen === null) this.setPlacement(pref)
    }
    if (this.attr("arrow") === "true") this.drawArrow()
    if (this.follow === "initial" && this.pointer) this.followCursor()
    else if (this.follow) this.followCursor()
  },

  setPlacement(p) {
    this.current = p
    this.fl.setAttribute("data-lu-placement", p)
    const side = p.split("-")[0]
    const offset = parseInt(this.attr("offset") || "8", 10)
    for (const m of ["Top", "Bottom", "Left", "Right"]) this.fl.style["margin" + m] = ""
    if (offset !== 8) {
      const prop = "margin" + OPPOSITE[side][0].toUpperCase() + OPPOSITE[side].slice(1)
      this.fl.style[prop] = offset - 8 + "px"
    }
  },

  followCursor() {
    if (!this.pointer || !this.fl) return
    const r = this.trigger.getBoundingClientRect()
    const x = this.pointer.clientX - (r.left + r.width / 2)
    const y = this.pointer.clientY - (r.top + r.height / 2)
    const f = this.follow
    const dx = f === "both" || f === "horizontal" || f === "initial" ? x : 0
    const dy = f === "both" || f === "vertical" || f === "initial" ? y : 0
    this.fl.style.translate = `${dx}px ${dy}px`
  },

  drawArrow() {
    const box = this.fl.firstElementChild
    if (!box) return
    let arrow = box.querySelector(":scope > [data-lu-arrow-el]")
    if (!arrow) {
      arrow = document.createElement("i")
      arrow.setAttribute("data-lu-arrow-el", "")
      arrow.setAttribute("aria-hidden", "true")
      box.appendChild(arrow)
    }
    if (getComputedStyle(box).position === "static") box.style.position = "relative"
    const [side, align] = this.current.split("-")
    const cs = getComputedStyle(box)
    const bw = parseFloat(cs.borderTopWidth) || 0
    const line = bw ? `${bw}px solid ${cs.borderTopColor}` : "0"
    const st = arrow.style
    st.cssText = "position:absolute;width:8px;height:8px;background:inherit;transform:rotate(45deg);pointer-events:none"
    const edge = OPPOSITE[side]
    st[edge === "top" ? "bottom" : edge === "bottom" ? "top" : edge === "left" ? "right" : "left"] = "-5px"
    const horizontal = side === "top" || side === "bottom"
    if (align === "start") st[horizontal ? "left" : "top"] = "14px"
    else if (align === "end") st[horizontal ? "right" : "bottom"] = "14px"
    else {
      st[horizontal ? "left" : "top"] = "50%"
      st[horizontal ? "marginLeft" : "marginTop"] = "-4px"
    }
    const borders = {top: ["Right", "Bottom"], bottom: ["Left", "Top"], left: ["Top", "Right"], right: ["Bottom", "Left"]}[side]
    for (const b of borders) st["border" + b] = line
  },

  // ---------------------------------------------------------------- notification center

  ncInit() {
    this.onNcClick = (e) => {
      const tab = e.target.closest("[data-lu-tab]")
      if (tab && this.el.contains(tab)) {
        this.ncTab = tab.getAttribute("data-lu-tab")
        this.ncApply()
        this.fire("on-change", {tab: this.ncTab})
        return
      }
      if (e.target.closest("[data-lu-read-all]")) {
        this.fire("on-read-all")
        return
      }
      const row = e.target.closest("[data-lu-read]")
      if (row && this.el.contains(row)) this.fire("on-read", {item: row.getAttribute("data-lu-item")})
    }
    this.el.addEventListener("click", this.onNcClick)
    this.ncDestroy = () => this.el.removeEventListener("click", this.onNcClick)
    this.ncTab = null
    this.ncApply()
  },

  ncApply() {
    const tabs = Array.from(this.el.querySelectorAll("[data-lu-tab]"))
    if (this.ncTab == null && tabs[0]) this.ncTab = tabs[0].getAttribute("data-lu-tab")
    for (const t of tabs) {
      const on = t.getAttribute("data-lu-tab") === this.ncTab
      t.classList.toggle("on", on)
      t.setAttribute("aria-selected", String(on))
    }
    if (!tabs.length) return
    const rows = Array.from(this.el.querySelectorAll("[data-lu-read]"))
    let any = false
    for (const r of rows) {
      const show =
        this.ncTab === "all" ||
        (this.ncTab === "unread" && r.getAttribute("data-lu-read") !== "true") ||
        r.getAttribute("data-lu-cat") === this.ncTab
      r.hidden = !show
      any = any || show
    }
    const panel = rows[0] && rows[0].parentElement
    if (!panel) return
    let empty = panel.querySelector(":scope > [data-lu-empty-el]")
    if (!empty) {
      empty = document.createElement("div")
      empty.setAttribute("data-lu-empty-el", "")
      empty.style.cssText = "padding:24px 14px;text-align:center;font-size:13px;color:var(--lu-muted)"
      panel.insertBefore(empty, rows[rows.length - 1].nextSibling)
    }
    const active = tabs.find((t) => t.getAttribute("data-lu-tab") === this.ncTab)
    empty.textContent = (active && active.getAttribute("data-lu-empty")) || this.attr("empty") || ""
    empty.hidden = !!any
  },
}
