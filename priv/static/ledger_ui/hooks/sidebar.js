// LedgerUI.Sidebar: collapse to icons, collapsible groups / items with children, persisted groups,
// Ctrl/Cmd+<shortcut>, the mobile top bar with a hamburger.
// Config travels in data-lu-* attributes: collapsed, persist, shortcut, on-collapse, target, groups.
// Anything with data-rail-toggle="<id of the menu>" collapses it from anywhere.
// The burger button is created here (as before) with the utilities the component sends in `data-lu-burger-class`;
// the framed menu renders its own (`data-lu-sb-burger` already in the markup).
import {stickAttr} from "../lib/keep.js"

const BURGER = '<svg viewBox="0 0 24 24" aria-hidden="true" class="size-[18px] flex-none fill-none stroke-current stroke-[1.75] [stroke-linecap:round] [stroke-linejoin:round]"><path d="M4 5L20 5"/><path d="M4 12L20 12"/><path d="M4 19L20 19"/></svg>'
const RAIL_KEY = "ledger-rail"


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
    this.apply()
  },
  updated() {
    this.ensureBurger()
    const now = this.el.getAttribute("data-lu-collapsed") === "true"
    if (now !== this.serverCollapsed) { this.serverCollapsed = now; this.collapsed = now }
    this.restoreGroups()
    this.apply()
  },
  destroyed() {
    document.removeEventListener("click", this.onDoc)
    window.removeEventListener("keydown", this.onKey)
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
    if (this.persist) write(RAIL_KEY, v ? "1" : "0")
    this.apply()
    const evt = this.el.getAttribute("data-lu-on-collapse")
    if (evt) {
      const payload = {id: this.el.id, collapsed: v}
      const target = this.el.getAttribute("data-lu-target")
      target ? this.pushEventTo(target, evt, payload) : this.pushEvent(evt, payload)
    }
  },
  apply() {
    const el = this.el
    stickAttr(this, el, "data-collapsed", this.collapsed ? "" : null)
    for (const b of document.querySelectorAll(`[data-rail-toggle="${CSS.escape(el.id)}"]`)) b.setAttribute("aria-pressed", String(this.collapsed))
    for (const b of el.querySelectorAll("[data-lu-sb-toggle]")) b.setAttribute("aria-pressed", String(this.collapsed))
    for (const a of el.querySelectorAll("[data-lu-sb-item]")) {
      if (this.collapsed) {
        if (!a.hasAttribute("title")) { a.setAttribute("title", a.textContent.trim()); a.setAttribute("data-lu-sb-t", "") }
      } else if (a.hasAttribute("data-lu-sb-t")) { a.removeAttribute("title"); a.removeAttribute("data-lu-sb-t") }
    }
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
    stickAttr(this, body, "hidden", !open)
    this.remember(head.getAttribute("data-lu-sb-group"), open)
  },
  toggleParent(parent, force) {
    const key = parent.getAttribute("data-lu-sb-parent")
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
