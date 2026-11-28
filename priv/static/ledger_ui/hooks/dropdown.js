// LedgerUI.Dropdown: positioning, flip, keyboard, click outside, submenus and checkable items.
//
// Markup (see LedgerUI.Components.Dropdown; the parts are found by `data-part`):
//   <span data-part="dropdown" id phx-hook="LedgerUI.Dropdown">
//     <button>trigger</button>
//     <span data-part="dropdown-menu" data-lu-placement="bottom-start" popover="manual" hidden>
//       <div data-part="pop" role="menu">...</div>
//     </span>
//   </span>
//
// The menu goes in the top layer (popover="manual", position: fixed), placed from the trigger's
// rectangle. Without the Popover API it is a fixed box. Open state is the class `open` on the
// root, so `LedgerUI.open/close/toggle` work with the id.
//
// Row marking: with `data-row-mark` on the root (or `rowMark: true` on the hook) the nearest [data-am-row], tr or .ledger-ctable-row gets `data-am-open` and a tint while open.
// A `part` prefix other than "dropdown" names the panel `<part>-panel` (e.g. "action-menu-panel").

import {keep, stickAttr, stickClass} from "../lib/keep.js"

const POPOVER = typeof HTMLElement !== "undefined" && "showPopover" in HTMLElement.prototype
const REDUCED = () => window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches
const ITEM = '[role="menuitem"],[role="menuitemcheckbox"],[role="menuitemradio"]'
const MARGIN = 8
const ROW = "[data-am-row],tr,.ledger-ctable-row"
const ROW_TINT = "color-mix(in srgb, var(--accent) 6%, var(--panel, var(--bg-panel)))"

// ---- positioning (exported for the context menu) ----------------------------------------

export function clamp(v, min, max) {
  return Math.max(min, Math.min(v, max))
}

// Places the fixed element `floating` next to `rect` (placement "bottom-start", "top-end"...),
// flipping to the opposite side when it does not fit and keeping it inside the window.
export function place(floating, rect, placement, offset) {
  const [side0, align = "center"] = placement.split("-")
  const vw = document.documentElement.clientWidth
  const vh = document.documentElement.clientHeight
  floating.style.transform = "none"
  floating.style.right = "auto"
  floating.style.bottom = "auto"
  const w = floating.offsetWidth
  const h = floating.offsetHeight
  const fits = {
    bottom: rect.bottom + offset + h <= vh - MARGIN,
    top: rect.top - offset - h >= MARGIN,
    right: rect.right + offset + w <= vw - MARGIN,
    left: rect.left - offset - w >= MARGIN,
  }
  const opposite = {bottom: "top", top: "bottom", left: "right", right: "left"}
  let side = side0
  if (!fits[side] && fits[opposite[side]]) side = opposite[side]
  let top, left
  if (side === "bottom" || side === "top") {
    top = side === "bottom" ? rect.bottom + offset : rect.top - offset - h
    left = align === "start" ? rect.left : align === "end" ? rect.right - w : rect.left + rect.width / 2 - w / 2
  } else {
    left = side === "right" ? rect.right + offset : rect.left - offset - w
    top = align === "start" ? rect.top : align === "end" ? rect.bottom - h : rect.top + rect.height / 2 - h / 2
  }
  floating.style.left = clamp(left, MARGIN, Math.max(MARGIN, vw - w - MARGIN)) + "px"
  floating.style.top = clamp(top, MARGIN, Math.max(MARGIN, vh - h - MARGIN)) + "px"
  floating.dataset.side = side
}

export function items(menu) {
  return Array.from(menu.querySelectorAll(ITEM)).filter(
    (el) =>
      el.closest('[role="menu"]') === menu &&
      el.getAttribute("aria-disabled") !== "true" &&
      !el.disabled &&
      el.offsetParent !== null,
  )
}

export function typeahead(state, menu, key, current) {
  clearTimeout(state.taTimer)
  state.ta = (state.ta || "") + key.toLowerCase()
  state.taTimer = setTimeout(() => (state.ta = ""), 500)
  const list = items(menu)
  const start = list.indexOf(current) + 1
  const ordered = list.slice(start).concat(list.slice(0, start))
  const hit = ordered.find((el) => el.textContent.trim().toLowerCase().startsWith(state.ta))
  if (hit) hit.focus()
}

// Fallback for hand-written menu content: roles the components already render are kept.
export function decorateMenu(menu) {
  if (!menu) return
  if (!menu.hasAttribute("role")) menu.setAttribute("role", "menu")
  for (const el of menu.querySelectorAll('[data-part="pop-item"]:not([role])')) el.setAttribute("role", "menuitem")
  for (const el of menu.querySelectorAll('[data-part="pop-separator"]:not([role])')) el.setAttribute("role", "separator")
  for (const el of menu.querySelectorAll('[data-part="pop-label"]:not([role])')) el.setAttribute("role", "presentation")
}

export function runJS(hook, attr) {
  const code = hook.el.getAttribute(attr)
  if (code) hook.liveSocket.execJS(hook.el, code)
}

// ---- the hook ---------------------------------------------------------------------------

export default {
  mounted() {
    this.isOpen = false
    this.state = {}
    this.srv = new Map()
    this.cur = new Map()
    this.setup()
    this.onClick = (e) => this.click(e)
    this.onKey = (e) => this.key(e)
    this.onDown = (e) => {
      if (this.isOpen && !this.el.contains(e.target)) this.close(false)
    }
    this.onScroll = () => this.follow()
    this.onEnter = () => this.hoverIn()
    this.onLeave = () => this.hoverOut()
    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("keydown", this.onKey)
    this.onOver = (e) => this.over(e)
    this.el.addEventListener("pointerover", this.onOver)
    this.restoreChecks()
    if (this.el.hasAttribute("data-hover")) {
      this.el.addEventListener("pointerenter", this.onEnter)
      this.el.addEventListener("pointerleave", this.onLeave)
    }
    this.observer = new MutationObserver(() => {
      const want = this.el.classList.contains("open")
      if (want !== this.isOpen) want ? this.open(false) : this.close(false)
    })
    this.observer.observe(this.el, {attributes: true, attributeFilter: ["class"]})
    if (this.el.classList.contains("open")) this.open(false)
  },

  updated() {
    this.setup()
    this.restoreChecks()
    // `open` (class) and aria-expanded are sticky, the panel's attributes are kept: a patch leaves them.
    if (this.isOpen) {
      this.show()
      this.reposition()
    }
  },

  destroyed() {
    this.close(false, true)
    this.observer && this.observer.disconnect()
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("keydown", this.onKey)
    this.el.removeEventListener("pointerover", this.onOver)
    this.el.removeEventListener("pointerenter", this.onEnter)
    this.el.removeEventListener("pointerleave", this.onLeave)
    clearTimeout(this.hoverTimer)
  },

  // Finds the parts and positions the menu. The server renders the ARIA (aria-haspopup,
  // aria-expanded, aria-controls, roles) and `popover="manual"`; only a custom :toggle that does
  // not spread the trigger attributes gets the fallbacks below.
  setup() {
    const el = this.el
    this.panel = el.querySelector(':scope > [data-part="dropdown-menu"], :scope > [data-part$="-panel"]')
    this.pop = this.panel && this.panel.querySelector(':scope > [data-part="pop"]')
    this.trigger =
      el.querySelector(':scope > [data-part="dropdown-split"] > button:last-child') ||
      Array.from(el.children).find((c) => c !== this.panel && c.getAttribute("aria-hidden") !== "true")
    // Animated demos (data-lu-demo) draw the menu themselves.
    this.demo = el.hasAttribute("data-lu-demo")
    if (!this.panel || !this.trigger || this.demo) return
    // The menu is the client's: open/closed (`hidden`), its position (`style`), top layer (`popover`).
    keep(this, this.panel, ["popover", "style", "hidden"])
    const t = this.trigger
    if (!t.hasAttribute("aria-haspopup")) t.setAttribute("aria-haspopup", "menu")
    if (!t.hasAttribute("aria-controls") && this.panel.id) t.setAttribute("aria-controls", this.panel.id)
    t.setAttribute("aria-expanded", String(this.isOpen))
    decorateMenu(this.pop)
    for (const sub of this.pop.querySelectorAll('[role="menu"]')) decorateMenu(sub)
    const s = this.panel.style
    s.position = "fixed"
    s.margin = "0"
    s.border = "0"
    s.padding = "0"
    s.background = "transparent"
    s.overflow = "visible"
    s.zIndex = "var(--ledger-z-popover, 60)"
    if (this.leaving) return
    if (POPOVER) {
      if (!this.isOpen && this.panel.matches(":popover-open")) this.panel.hidePopover()
    } else {
      this.panel.hidden = !this.isOpen
    }
  },

  show() {
    this.cancelLeave()
    if (POPOVER) {
      if (!this.panel.matches(":popover-open")) this.panel.showPopover()
    } else this.panel.hidden = false
  },

  hide(animated) {
    const done = () => {
      if (POPOVER) {
        if (this.panel.matches(":popover-open")) this.panel.hidePopover()
      } else this.panel.hidden = true
    }
    this.cancelLeave()
    if (!animated || !this.panel.animate || REDUCED() || this.panel.hidden || !this.panel.isConnected) return done()
    const a = this.panel.animate([{opacity: 1, translate: "0 0"}, {opacity: 0, translate: this.shift()}], {
      duration: 120,
      easing: "ease-in",
    })
    this.leaving = a
    this.panel.style.pointerEvents = "none"
    a.finished.then(
      () => {
        if (this.leaving !== a) return
        this.leaving = null
        this.panel.style.pointerEvents = ""
        if (!this.isOpen) done()
      },
      () => {},
    )
  },

  cancelLeave() {
    if (!this.leaving) return
    const a = this.leaving
    this.leaving = null
    a.cancel()
    this.panel.style.pointerEvents = ""
  },

  // The start frame offset: a few px toward the trigger, so the menu slides away from it.
  shift() {
    const side = (this.panel.dataset.side || "bottom").split("-")[0]
    return {top: "0 4px", bottom: "0 -4px", left: "4px 0", right: "-4px 0"}[side] || "0 0"
  },

  enter() {
    if (!this.panel.animate || REDUCED()) return
    this.panel.animate([{opacity: 0, translate: this.shift()}, {opacity: 1, translate: "0 0"}], {
      duration: 140,
      easing: "cubic-bezier(.2,.8,.2,1)",
    })
  },

  placement() {
    return this.panel.getAttribute("data-lu-placement") || "bottom-start"
  },

  reposition() {
    if (!this.panel || this.demo) return
    const anchor = this.el.querySelector(':scope > [data-part="dropdown-split"]') || this.trigger
    const offset = Number(this.el.getAttribute("data-offset") || 4)
    place(this.panel, anchor.getBoundingClientRect(), this.placement(), offset)
  },

  // Follows the page while scrolling; closes when the trigger scrolls out of sight.
  follow() {
    if (!this.isOpen) return
    cancelAnimationFrame(this.raf)
    this.raf = requestAnimationFrame(() => {
      const r = this.trigger.getBoundingClientRect()
      const vh = document.documentElement.clientHeight
      if (r.bottom < 0 || r.top > vh) return this.close(false)
      this.reposition()
    })
  },

  open(focus) {
    if (this.demo || !this.panel || this.isOpen) return
    this.isOpen = true
    stickClass(this, this.el, "open", true)
    this.show()
    this.reposition()
    this.enter()
    stickAttr(this, this.trigger, "aria-expanded", "true")
    document.addEventListener("pointerdown", this.onDown, true)
    window.addEventListener("scroll", this.onScroll, true)
    window.addEventListener("resize", this.onScroll)
    runJS(this, "data-on-open")
    this.markRow(true)
    if (focus === "last") this.focusItem(this.pop, -1)
    else if (focus) this.focusItem(this.pop, 0)
  },

  // `instant`: skip the leave animation (the panel is gone at once, so its items are not focusable any more).
  close(returnFocus, silent, instant) {
    if (!this.isOpen) return
    this.isOpen = false
    this.closeSubs()
    document.removeEventListener("pointerdown", this.onDown, true)
    window.removeEventListener("scroll", this.onScroll, true)
    window.removeEventListener("resize", this.onScroll)
    cancelAnimationFrame(this.raf)
    if (this.panel) this.hide(!silent && !instant)
    stickClass(this, this.el, "open", false)
    if (this.trigger) stickAttr(this, this.trigger, "aria-expanded", "false")
    this.markRow(false)
    if (!silent) runJS(this, "data-on-close")
    if (returnFocus && this.trigger) this.trigger.focus()
  },

  // Tints the table row (or card) the menu belongs to while it is open.
  markRow(on) {
    if (on) {
      if (!(this.rowMark || this.el.hasAttribute("data-row-mark"))) return
      this.row = this.el.closest(ROW)
      if (!this.row) return
      this.row.setAttribute("data-am-open", "")
      this.rowBg = this.row.style.background
      this.row.style.background = ROW_TINT
    } else if (this.row) {
      this.row.removeAttribute("data-am-open")
      this.row.style.background = this.rowBg || ""
      this.row = null
    }
  },

  toggle(focus) {
    this.isOpen ? this.close(false) : this.open(focus)
  },

  focusItem(menu, index) {
    const list = items(menu)
    if (!list.length) return
    const el = index < 0 ? list[list.length + index] : list[index]
    if (el) el.focus()
  },

  hoverIn() {
    clearTimeout(this.hoverTimer)
    this.open(false)
  },

  hoverOut() {
    clearTimeout(this.hoverTimer)
    this.hoverTimer = setTimeout(() => this.close(false), 150)
  },

  // ---- events ---------------------------------------------------------------------------

  click(e) {
    if (this.demo || !this.panel) return
    const t = e.target
    if (this.trigger.contains(t)) {
      // e.detail === 0: keyboard-generated click, so focus the first item.
      this.toggle(e.detail === 0)
      return
    }
    const item = t.closest(ITEM)
    if (!item || !this.panel.contains(item)) return
    if (item.getAttribute("aria-disabled") === "true") {
      e.preventDefault()
      e.stopPropagation()
      return
    }
    const role = item.getAttribute("role")
    if (item.matches('[data-dd="sub"] > [role="menuitem"]')) return this.toggleSub(item.parentElement, true)
    if (role === "menuitemcheckbox") return this.toggleCheck(item)
    if (role === "menuitemradio") return this.pickRadio(item)
    if (item.matches('[data-dd="clear"]')) return this.clearChecks()
    if (item.matches('[data-dd="apply"]')) {
      if (item.getAttribute("data-close") !== "false") this.close(true)
      return
    }
    if (this.el.getAttribute("data-close-on-select") !== "false") this.close(true)
  },

  key(e) {
    if (this.demo || !this.panel) return
    const inTrigger = this.trigger.contains(e.target)
    if (!this.isOpen) {
      if (inTrigger && (e.key === "ArrowDown" || e.key === "ArrowUp")) {
        e.preventDefault()
        this.open(e.key === "ArrowUp" ? "last" : true)
      }
      return
    }
    const target = e.target
    const typing = target.matches("input,textarea")
    const menu = target.closest('[role="menu"]') || this.pop
    const sub = target.closest('[data-dd="sub"]')
    switch (e.key) {
      case "Escape":
        e.preventDefault()
        e.stopPropagation()
        if (sub && menu !== this.pop) {
          this.toggleSub(sub, false)
          sub.querySelector(':scope > [role="menuitem"]').focus()
        } else this.close(true)
        return
      case "Tab":
        // Closes at once (no leave animation: the items of a menu that is still fading out would take the focus) and
        // puts focus back on the trigger WITHOUT cancelling the key: the browser then moves on from the trigger
        // (next focusable after it, or the previous one with Shift), instead of dropping focus on <body>.
        this.close(true, false, true)
        return
      case "ArrowDown":
      case "ArrowUp": {
        e.preventDefault()
        const list = items(menu)
        const i = list.indexOf(target)
        const next = e.key === "ArrowDown" ? i + 1 : i - 1
        const el = list[(next + list.length) % list.length]
        if (el) el.focus()
        return
      }
      case "Home":
      case "End":
        if (typing) return
        e.preventDefault()
        this.focusItem(menu, e.key === "Home" ? 0 : -1)
        return
      case "ArrowRight": {
        const subTrigger = target.closest('[data-dd="sub"] > [role="menuitem"]')
        if (subTrigger) {
          e.preventDefault()
          this.toggleSub(subTrigger.parentElement, true, true)
        }
        return
      }
      case "ArrowLeft":
        if (sub && menu !== this.pop) {
          e.preventDefault()
          this.toggleSub(sub, false)
          sub.querySelector(':scope > [role="menuitem"]').focus()
        }
        return
      default:
        if (!typing && e.key.length === 1 && !e.ctrlKey && !e.metaKey && !e.altKey && e.key !== " ") {
          typeahead(this.state, menu, e.key, target)
        }
    }
  },

  // Submenus open when the pointer rests on their item; hovering another item closes them
  // (unless `keep_submenus`).
  over(e) {
    if (!this.isOpen || !this.pop) return
    const trigger = e.target.closest('[data-dd="sub"] > [role="menuitem"]')
    clearTimeout(this.subTimer)
    if (trigger) {
      if (trigger.getAttribute("aria-disabled") === "true") return
      const sub = trigger.parentElement
      this.subTimer = setTimeout(() => this.toggleSub(sub, true), 120)
    } else if (e.target.closest(ITEM) && !this.el.hasAttribute("data-keep-submenus")) {
      const menu = e.target.closest('[role="menu"]')
      if (menu === this.pop) this.closeSubs()
    }
  },

  // ---- submenus -------------------------------------------------------------------------

  toggleSub(sub, on, focus) {
    const pop = sub.querySelector(':scope > [data-dd="subpop"]')
    const trigger = sub.querySelector(':scope > [role="menuitem"]')
    if (on === undefined) on = pop.hidden
    if (on) {
      if (this.el.getAttribute("data-keep-submenus") === null) {
        for (const other of this.pop.querySelectorAll('[data-dd="sub"]')) {
          if (other !== sub && !other.contains(sub)) this.toggleSub(other, false)
        }
      }
      pop.hidden = false
      const left = sub.getAttribute("data-placement") === "left"
      pop.style.left = left ? "auto" : "100%"
      pop.style.right = left ? "100%" : "auto"
      const r = pop.getBoundingClientRect()
      const vw = document.documentElement.clientWidth
      if (!left && r.right > vw - MARGIN) {
        pop.style.left = "auto"
        pop.style.right = "100%"
      } else if (left && r.left < MARGIN) {
        pop.style.right = "auto"
        pop.style.left = "100%"
      }
      trigger.setAttribute("aria-expanded", "true")
      if (focus) this.focusItem(pop, 0)
    } else {
      pop.hidden = true
      trigger.setAttribute("aria-expanded", "false")
    }
  },

  closeSubs() {
    if (!this.pop) return
    for (const sub of this.pop.querySelectorAll('[data-dd="sub"]')) this.toggleSub(sub, false)
  },

  // ---- checkable items ------------------------------------------------------------------

  paint(item, checked) {
    item.setAttribute("aria-checked", String(checked))
    const ck = item.querySelector('[data-part="pop-check"]')
    if (ck) ck.style.visibility = checked ? "" : "hidden"
  },

  fire(input) {
    input.dispatchEvent(new Event("input", {bubbles: true}))
    input.dispatchEvent(new Event("change", {bubbles: true}))
  },

  toggleCheck(item) {
    const input = item.querySelector("input")
    const checked = item.getAttribute("aria-checked") !== "true"
    this.paint(item, checked)
    if (input) {
      input.checked = checked
      this.fire(input)
    }
    this.remember(item, checked)
    this.updateCounts()
  },

  pickRadio(item) {
    const input = item.querySelector("input")
    const name = input && input.name
    const group = Array.from(this.pop.querySelectorAll('[role="menuitemradio"]')).filter((el) => {
      const i = el.querySelector("input")
      return name ? i && i.name === name : el === item
    })
    for (const el of group) {
      this.paint(el, el === item)
      this.remember(el, el === item)
    }
    if (input) {
      input.checked = true
      this.fire(input)
    }
  },

  clearChecks() {
    for (const item of this.pop.querySelectorAll('[role="menuitemcheckbox"][aria-checked="true"]')) {
      this.paint(item, false)
      const input = item.querySelector("input")
      if (input) {
        input.checked = false
        this.fire(input)
      }
      this.remember(item, false)
    }
    this.updateCounts()
  },

  updateCounts() {
    for (const sub of this.pop.querySelectorAll('[data-dd="sub"]')) {
      const badge = sub.querySelector(':scope > [role="menuitem"] [data-dd="count"]')
      if (!badge) continue
      const n = sub.querySelectorAll('[role="menuitemcheckbox"][aria-checked="true"]').length
      badge.textContent = String(n)
      badge.hidden = n === 0
    }
  },

  remember(item, checked) {
    if (item.id) this.cur.set(item.id, checked)
  },

  // After a patch the DOM has the server's `checked`: if the server did not change it, keep what
  // was ticked in the browser; if it did, the server wins.
  restoreChecks() {
    if (!this.pop) return
    for (const item of this.pop.querySelectorAll('[role="menuitemcheckbox"][id],[role="menuitemradio"][id]')) {
      const serverVal = item.getAttribute("aria-checked") === "true"
      const before = this.srv.get(item.id)
      if (before === serverVal && this.cur.has(item.id)) {
        const mine = this.cur.get(item.id)
        this.paint(item, mine)
        const input = item.querySelector("input")
        if (input) input.checked = mine
      } else {
        this.cur.set(item.id, serverVal)
      }
      this.srv.set(item.id, serverVal)
    }
    this.updateCounts()
  },
}
