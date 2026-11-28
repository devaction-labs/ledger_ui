// LedgerUI.Sidebar: collapse to icons, collapsible groups / items with children, persisted groups,
// Ctrl/Cmd+<shortcut>, the mobile top bar with a hamburger.
// Config travels in data-lu-* attributes: collapsed, persist, shortcut, on-collapse, target, groups.
// Anything with data-rail-toggle="<id of the menu>" collapses it from anywhere.
// The burger button is created here (as before) with the utilities the component sends in `data-lu-burger-class`;
// the framed menu renders its own (`data-lu-sb-burger` already in the markup).
// `format="aurora"` (data-lu-format): the state also goes to `data-collapsed` of <html> (the pre-paint script of
// `sidebar_script/1` writes it first), a pointer resting on the collapsed menu opens it over the page (`peek`),
// an item with children opens a floating submenu on hover or focus, and the arrows move between the items.
// Everything it listens to is on the menu element; the only listeners outside it are the two of every format.
import {stickAttr} from "../lib/keep.js"

const BURGER = '<svg viewBox="0 0 24 24" aria-hidden="true" class="size-[18px] flex-none fill-none stroke-current stroke-[1.75] [stroke-linecap:round] [stroke-linejoin:round]"><path d="M4 5L20 5"/><path d="M4 12L20 12"/><path d="M4 19L20 19"/></svg>'
const RAIL_KEY = "ledger-rail"
const MENU_GAP = 12
const MENU_MARGIN = 8
const MENU_ARROW = 6
const CLOSE_DELAY = 150


const editable = (t) => t && (/^(INPUT|TEXTAREA|SELECT)$/.test(t.tagName) || t.isContentEditable)
const read = (k) => { try { return localStorage.getItem(k) } catch (_) { return null } }
const write = (k, v) => { try { localStorage.setItem(k, v) } catch (_) {} }

export default {
  mounted() {
    const el = this.el
    const attr = (n) => el.getAttribute(`data-lu-${n}`)
    this.serverCollapsed = attr("collapsed") === "true"
    this.persist = attr("persist") !== "false"
    this.collapsed = this.serverCollapsed
    if (!this.serverCollapsed && this.persist) {
      const saved = read(RAIL_KEY)
      if (saved === "1") this.collapsed = true
    }
    this.groupsKey = attr("groups") === "true" ? `ledger-sidebar-groups:${el.id}` : null
    this.groupState = this.groupsKey ? JSON.parse(read(this.groupsKey) || "{}") : {}

    this.aurora = attr("format") === "aurora"
    this.peeking = false
    this.menu = null
    this.menuOwner = null
    this.ensureBurger()
    this.onClick = (e) => {
      const t = e.target
      if (t.closest("[data-lu-sb-toggle]")) return this.setCollapsed(!this.collapsed)
      if (t.closest("[data-lu-sb-burger]")) return this.toggleMobile()
      const head = t.closest("[data-lu-sb-group]")
      if (head && el.contains(head)) return this.toggleGroup(head)
      const parent = t.closest("[data-lu-sb-parent]")
      if (parent && el.contains(parent)) {
        const hasDest = parent.hasAttribute("data-lu-sb-dest")
        const caret = t.closest("[data-part=nav-caret]")
        // a collapsed parent has no children to show in place: a click shows its submenu
        if (this.aurora && this.visual()) { if (!hasDest) this.openMenu(parent, false); return }
        if (!hasDest || caret) { e.preventDefault(); this.toggleParent(parent) }
        else this.toggleParent(parent, true)
        return
      }
      if (this.collapsed && t.closest("[data-lu-sb-module]")) this.setCollapsed(false)
    }
    this.onDoc = (e) => {
      const b = e.target.closest && e.target.closest("[data-rail-toggle]")
      if (b && b.getAttribute("data-rail-toggle") === el.id && !el.contains(b)) this.setCollapsed(!this.collapsed)
    }
    this.onKey = (e) => {
      const key = attr("shortcut")
      if (!key || editable(e.target)) return
      if ((e.ctrlKey || e.metaKey) && !e.altKey && e.key.toLowerCase() === key.toLowerCase()) {
        e.preventDefault()
        if (window.matchMedia("(max-width: 767px)").matches) this.toggleMobile()
        else this.setCollapsed(!this.collapsed)
      }
    }
    el.addEventListener("click", this.onClick)
    document.addEventListener("click", this.onDoc)
    window.addEventListener("keydown", this.onKey)
    this.restoreGroups()
    if (this.aurora) this.mountAurora()
    this.apply()
  },
  updated() {
    this.ensureBurger()
    const now = this.el.getAttribute("data-lu-collapsed") === "true"
    if (now !== this.serverCollapsed) { this.serverCollapsed = now; this.collapsed = now }
    this.restoreGroups()
    this.apply()
    if (this.aurora && this.menu) {
      if (this.menu.isConnected && this.menuOwner && this.menuOwner.isConnected) {
        stickAttr(this, this.menu, "data-open", "")
        this.placeMenu(this.menuOwner, this.menu)
      } else this.closeMenu()
    }
  },
  destroyed() {
    document.removeEventListener("click", this.onDoc)
    window.removeEventListener("keydown", this.onKey)
    if (this.aurora) this.unmountAurora()
  },
  // The button is made here, not by the server: a patch of the <aside> removes it, so `updated` puts it back.
  ensureBurger() {
    const el = this.el
    let b = el.querySelector("[data-lu-sb-burger]")
    if (!b) {
      b = document.createElement("button")
      b.type = "button"
      b.className = el.getAttribute("data-lu-burger-class") || "hidden"
      b.setAttribute("data-lu-sb-burger", "")
      b.setAttribute("aria-label", el.getAttribute("data-lu-mobile-label") || "Menu")
      b.innerHTML = BURGER
      el.insertBefore(b, el.firstChild)
    }
    b.setAttribute("aria-expanded", String(el.hasAttribute("data-mobile-open")))
  },
  setCollapsed(v) {
    this.collapsed = v
    this.peeking = false
    if (this.persist) write(RAIL_KEY, v ? "1" : "0")
    this.apply()
    const evt = this.el.getAttribute("data-lu-on-collapse")
    if (evt) {
      const payload = {id: this.el.id, collapsed: v}
      const target = this.el.getAttribute("data-lu-target")
      target ? this.pushEventTo(target, evt, payload) : this.pushEvent(evt, payload)
    }
  },
  // drawn collapsed: collapsed and not showing the whole menu over the page
  visual() { return this.collapsed && !this.peeking },
  apply() {
    const el = this.el
    const visual = this.visual()
    stickAttr(this, el, "data-collapsed", visual ? "" : null)
    for (const b of document.querySelectorAll(`[data-rail-toggle="${CSS.escape(el.id)}"]`)) b.setAttribute("aria-pressed", String(this.collapsed))
    for (const b of el.querySelectorAll("[data-lu-sb-toggle]")) b.setAttribute("aria-pressed", String(this.collapsed))
    for (const a of el.querySelectorAll("[data-lu-sb-item]")) {
      if (this.collapsed) {
        if (!a.hasAttribute("title")) { a.setAttribute("title", a.textContent.trim()); a.setAttribute("data-lu-sb-t", "") }
      } else if (a.hasAttribute("data-lu-sb-t")) { a.removeAttribute("title"); a.removeAttribute("data-lu-sb-t") }
    }
    if (this.aurora) this.applyAurora(visual)
  },
  toggleMobile() {
    const open = !this.el.hasAttribute("data-mobile-open")
    stickAttr(this, this.el, "data-mobile-open", open ? "" : null)
    const b = this.el.querySelector("[data-lu-sb-burger]")
    if (b) b.setAttribute("aria-expanded", String(open))
  },
  toggleGroup(head, force) {
    const body = document.getElementById(head.getAttribute("aria-controls"))
    if (!body) return
    const open = force !== undefined ? force : head.getAttribute("aria-expanded") !== "true"
    // sticky: a patch gives the group back the state the person chose (the server draws its own)
    stickAttr(this, head, "aria-expanded", String(open))
    this.setBody(body, open)
    this.remember(head.getAttribute("data-lu-sb-group"), open)
  },
  // aurora: the body is closed by `data-closed` (a grid row that goes to 0), the others by `hidden`
  setBody(body, open) {
    if (body.hasAttribute("data-lu-au-body")) stickAttr(this, body, "data-closed", open ? null : "")
    else stickAttr(this, body, "hidden", !open)
  },
  toggleParent(parent, force) {
    const key = parent.getAttribute("data-lu-sb-parent")
    const kidsId = parent.getAttribute("data-lu-au-kids")
    if (kidsId) {
      // aurora: the truth is the `data-closed` of the children; `aria-expanded` is theirs only while expanded
      const kids = document.getElementById(kidsId)
      if (!kids) return
      const open = force !== undefined ? force : kids.hasAttribute("data-closed")
      this.setBody(kids, open)
      if (!this.visual()) stickAttr(this, parent, "aria-expanded", String(open))
      this.remember(key, open)
      return
    }
    const open = force !== undefined ? force : parent.getAttribute("aria-expanded") !== "true"
    stickAttr(this, parent, "aria-expanded", String(open))
    for (const c of this.el.querySelectorAll("[data-lu-sb-child]")) if (c.getAttribute("data-lu-sb-child") === key) stickAttr(this, c, "hidden", !open)
    this.remember(key, open)
  },
  remember(key, open) {
    if (!this.groupsKey) return
    this.groupState[key] = open
    write(this.groupsKey, JSON.stringify(this.groupState))
  },
  // ---- format="aurora" ------------------------------------------------------------------------------
  mountAurora() {
    const el = this.el
    this.peekOn = el.getAttribute("data-lu-peek") === "true"
    this.timers = {close: null, peek: null}
    this.onOver = (e) => {
      if (this.peekable()) this.armPeek()
      if (!this.visual()) return
      const box = e.target.closest && e.target.closest("[data-lu-au-menu-box]")
      if (box && el.contains(box)) return this.cancelClose()
      const parent = e.target.closest && e.target.closest("[data-lu-au-menu]")
      if (parent && el.contains(parent)) { this.dropPreview(); return this.openMenu(parent, false) }
      // a preview card is for an item with one: on any other target (an item with none) it closes
      const item = e.target.closest && e.target.closest("[data-lu-au-nav]")
      if (item && !item.hasAttribute("data-rail-item")) this.dropPreview()
      if (this.menu) this.scheduleClose()
    }
    this.onMove = () => { if (this.peekable()) this.armPeek() }
    this.onLeave = () => {
      this.clearTimer("peek")
      if (this.peeking) { this.peeking = false; this.suspendPreviews(); this.apply() }
      if (this.menu) this.scheduleClose()
    }
    this.onFocusIn = (e) => {
      if (!this.visual() || this.refocusing) return
      const t = e.target
      const parent = t.closest && t.closest("[data-lu-au-menu]")
      if (parent && el.contains(parent)) return this.openMenu(parent, false)
      const inMenu = t.closest && t.closest("[data-lu-au-menu-box]")
      if (!inMenu && this.menu) this.closeMenu()
    }
    this.onFocusOut = (e) => {
      if (!this.menu) return
      const to = e.relatedTarget
      if (to && (this.menu.contains(to) || (this.menuOwner && this.menuOwner.contains(to)))) return
      this.closeMenu()
    }
    this.onKeyDown = (e) => this.keydown(e)
    for (const [t, f] of this.auraEvents()) el.addEventListener(t, f)
  },
  auraEvents() {
    return [["mouseover", this.onOver], ["mousemove", this.onMove], ["mouseleave", this.onLeave],
      ["focusin", this.onFocusIn], ["focusout", this.onFocusOut], ["keydown", this.onKeyDown]]
  },
  unmountAurora() {
    for (const [t, f] of this.auraEvents()) this.el.removeEventListener(t, f)
    this.clearTimer("close")
    this.clearTimer("peek")
    this.closeMenu()
    document.documentElement.removeAttribute("data-collapsed")
  },
  clearTimer(name) {
    if (this.timers && this.timers[name]) clearTimeout(this.timers[name])
    if (this.timers) this.timers[name] = null
  },
  peekable() { return this.peekOn && this.collapsed && !this.peeking },
  armPeek() {
    this.clearTimer("peek")
    const n = parseInt(this.el.getAttribute("data-lu-peek-delay"), 10)
    this.timers.peek = setTimeout(() => {
      this.timers.peek = null
      if (!this.peekable()) return
      this.closeMenu()
      this.suspendPreviews()
      this.peeking = true
      this.apply()
    }, Number.isFinite(n) && n >= 0 ? n : 300)
  },
  dropPreview() {
    if (this.el.querySelector("[data-lu-rail-preview][data-open]")) this.suspendPreviews()
  },
  // the preview cards (`LedgerUI.RailPreview` on the nav) close when the menu changes how it is drawn
  suspendPreviews() {
    for (const nav of this.el.querySelectorAll("[phx-hook='LedgerUI.RailPreview']")) nav.dispatchEvent(new CustomEvent("ledger:preview-off"))
  },
  applyAurora(visual) {
    const root = document.documentElement
    if (visual) root.setAttribute("data-collapsed", "")
    else root.removeAttribute("data-collapsed")
    stickAttr(this, this.el, "data-peek", this.peeking ? "" : null)
    for (const a of this.el.querySelectorAll("[data-lu-au-item]:not([aria-describedby])")) {
      const lab = a.querySelector("[data-lu-au-label]")
      if (visual) {
        if (!a.hasAttribute("title")) { a.setAttribute("title", (lab || a).textContent.trim()); a.setAttribute("data-lu-sb-t", "") }
      } else if (a.hasAttribute("data-lu-sb-t")) { a.removeAttribute("title"); a.removeAttribute("data-lu-sb-t") }
    }
    // a parent is a disclosure of its children while expanded and the owner of a submenu while collapsed
    for (const p of this.el.querySelectorAll("[data-lu-au-menu]")) {
      if (visual) {
        stickAttr(this, p, "aria-haspopup", "menu")
        stickAttr(this, p, "aria-controls", p.getAttribute("data-lu-au-menu"))
        stickAttr(this, p, "aria-expanded", String(!!this.menu && this.menuOwner === p))
      } else {
        const kids = document.getElementById(p.getAttribute("data-lu-au-kids"))
        stickAttr(this, p, "aria-haspopup", null)
        stickAttr(this, p, "aria-controls", p.getAttribute("data-lu-au-kids"))
        if (kids) stickAttr(this, p, "aria-expanded", String(!kids.hasAttribute("data-closed")))
      }
    }
    if (!visual) this.closeMenu()
  },
  menuOf(parent) { return document.getElementById(parent.getAttribute("data-lu-au-menu")) },
  openMenu(parent, focusFirst) {
    this.cancelClose()
    const menu = this.menuOf(parent)
    if (!menu) return
    if (this.menu && this.menu !== menu) this.closeMenu()
    this.menu = menu
    this.menuOwner = parent
    stickAttr(this, menu, "data-open", "")
    stickAttr(this, parent, "aria-expanded", "true")
    this.placeMenu(parent, menu)
    if (focusFirst) { const first = menu.querySelector("[role=menuitem]"); if (first) first.focus() }
  },
  closeMenu(refocus) {
    this.cancelClose()
    const menu = this.menu
    const owner = this.menuOwner
    if (!menu) return
    this.menu = null
    this.menuOwner = null
    stickAttr(this, menu, "data-open", null)
    if (owner && owner.isConnected) {
      if (this.visual()) stickAttr(this, owner, "aria-expanded", "false")
      if (refocus) {
        // giving the focus back must not open the menu again (focus opens it)
        this.refocusing = true
        owner.focus()
        this.refocusing = false
      }
    }
  },
  cancelClose() { this.clearTimer("close") },
  scheduleClose() {
    this.cancelClose()
    this.timers.close = setTimeout(() => { this.timers.close = null; this.closeMenu() }, CLOSE_DELAY)
  },
  placeMenu(owner, menu) {
    const r = owner.getBoundingClientRect()
    const vw = document.documentElement.clientWidth || window.innerWidth
    const vh = document.documentElement.clientHeight || window.innerHeight
    const w = menu.offsetWidth || 240
    const h = menu.offsetHeight || 0
    const x = Math.min(r.right + MENU_GAP, Math.max(MENU_MARGIN, vw - w - MENU_MARGIN))
    const cy = r.top + r.height / 2
    let y = cy - 22
    y = Math.max(MENU_MARGIN, Math.min(y, vh - h - MENU_MARGIN))
    const ay = Math.max(10, Math.min(cy - y - MENU_ARROW, Math.max(10, h - 22)))
    menu.style.left = `${Math.round(x)}px`
    menu.style.top = `${Math.round(y)}px`
    menu.style.setProperty("--ay", `${Math.round(ay)}px`)
  },
  // the items the arrows walk: in the order of the page, the ones that are drawn
  navItems() {
    const visual = this.visual()
    return [...this.el.querySelectorAll("[data-lu-au-nav]")].filter((n) => {
      if (n.closest("[data-lu-au-menu-box]")) return false
      if (visual && (n.hasAttribute("data-lu-sb-group") || n.hasAttribute("data-lu-au-of"))) return false
      const closed = n.closest("[data-closed]")
      return !(closed && !visual)
    })
  },
  keydown(e) {
    if (e.ctrlKey || e.metaKey || e.altKey) return
    const t = e.target
    const k = e.key
    const box = t.closest && t.closest("[data-lu-au-menu-box]")
    if (k === "Escape") {
      const had = !!this.menu || this.peeking
      if (this.peeking) { this.peeking = false; this.suspendPreviews(); this.apply() }
      if (this.menu) this.closeMenu(!!box)
      this.suspendPreviews()
      if (had) e.stopPropagation()
      return
    }
    if (k !== "ArrowDown" && k !== "ArrowUp" && k !== "ArrowRight" && k !== "ArrowLeft") return
    const down = k === "ArrowDown"
    if (k === "ArrowDown" || k === "ArrowUp") {
      const list = box ? [...box.querySelectorAll("[role=menuitem]")] : this.navItems()
      if (!list.length) return
      const at = list.indexOf(t.closest ? (box ? t.closest("[role=menuitem]") : t.closest("[data-lu-au-nav]")) : t)
      let next
      if (at < 0) next = down ? 0 : list.length - 1
      else next = (at + (down ? 1 : -1) + list.length) % list.length
      e.preventDefault()
      list[next].focus()
      return
    }
    const right = k === "ArrowRight"
    if (box) {
      if (!right) { e.preventDefault(); this.closeMenu(true) }
      return
    }
    const node = t.closest && t.closest("[data-lu-au-nav]")
    if (!node) return
    const parent = node.hasAttribute("data-lu-au-menu") ? node : null
    const head = node.hasAttribute("data-lu-sb-group") ? node : null
    if (parent && this.visual()) {
      if (right) { e.preventDefault(); this.openMenu(parent, true) }
      return
    }
    if (parent || head) {
      const open = parent ? !document.getElementById(parent.getAttribute("data-lu-au-kids")).hasAttribute("data-closed") : head.getAttribute("aria-expanded") === "true"
      if (right === open) return
      e.preventDefault()
      parent ? this.toggleParent(parent, right) : this.toggleGroup(head, right)
      return
    }
    // a child: Left goes back to its parent
    if (!right && node.hasAttribute("data-lu-au-of")) {
      const key = node.getAttribute("data-lu-au-of")
      const owner = [...this.el.querySelectorAll("[data-lu-sb-parent]")].find((p) => p.getAttribute("data-lu-sb-parent") === key)
      if (owner) { e.preventDefault(); owner.focus() }
    }
  },
  restoreGroups() {
    if (!this.groupsKey) return
    for (const head of this.el.querySelectorAll("[data-lu-sb-group]")) {
      const k = head.getAttribute("data-lu-sb-group")
      if (k in this.groupState) this.toggleGroup(head, this.groupState[k])
    }
    for (const p of this.el.querySelectorAll("[data-lu-sb-parent]")) {
      const k = p.getAttribute("data-lu-sb-parent")
      if (k in this.groupState) this.toggleParent(p, this.groupState[k])
    }
  },
}
