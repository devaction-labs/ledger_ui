// LedgerUI.Sidebar: collapse to icons, collapsible groups / items with children, persisted groups,
// Ctrl/Cmd+<shortcut>, the mobile top bar with a hamburger.
// Config travels in phx-value-* attributes: collapsed, persist, shortcut, on-collapse, target, groups.
// Anything with data-rail-toggle="<id of the menu>" collapses it from anywhere.
const RAIL_KEY = "linea-rail"
const CSS_ID = "ledger-sidebar-css"
const CSS = `
.lu-side [hidden]{display:none!important}
.lu-side[data-collapsed],.lu-side-framed[data-collapsed]{width:60px;padding:12px 8px;overflow:visible}
.lu-side-rail[data-collapsed] .lu-subnav{display:none}
.lu-side[data-collapsed] .lu-nav-item{font-size:0;gap:0;justify-content:center;padding:0}
.lu-side[data-collapsed] .lu-nav-item .r,.lu-side[data-collapsed] .lu-nav-item .caret,.lu-side[data-collapsed] .lu-nav-item.sub,
.lu-side[data-collapsed] .lu-nav-h,.lu-side[data-collapsed] .lu-ws .t,.lu-side[data-collapsed] .lu-ws>.lu-i,
.lu-side[data-collapsed] .lu-promo,.lu-side[data-collapsed] .lu-person,.lu-side[data-collapsed] .lu-user>.lu-i,
.lu-side[data-collapsed] .lu-sb-vtext,.lu-side[data-collapsed] .rail-label{display:none}
.lu-side[data-collapsed] .lu-nav-item{position:relative}
.lu-side[data-collapsed] .lu-nav-item .lu-sb-badge{display:block;font-size:0;width:8px;height:8px;padding:0;border-radius:50%;background:var(--neg);position:absolute;top:6px;right:8px}
.lu-side[data-collapsed] .lu-side-framed{width:60px}
.lu-side[data-collapsed] .lu-ws,.lu-side[data-collapsed] .lu-user,.lu-side[data-collapsed] .lu-sb-version{justify-content:center;padding:4px}
.lu-side[data-collapsed] .lu-nav-item .r.alert{display:inline-flex;position:absolute;margin:0}
[aria-expanded="false"]>.lu-i.sm,[aria-expanded="false"]>.lu-i.caret{transform:rotate(-90deg)}
.lu-nav-h[data-sb-group] .lu-i,.lu-nav-item .caret{transition:transform .15s}
@media (min-width:768px){.lu-tabbar-slot{display:none}}
@media (max-width:767px){
.lu-tabbar-slot{position:fixed;left:0;right:0;bottom:0;z-index:40;padding-bottom:env(safe-area-inset-bottom)}
.lu-side[data-part="sidebar"]{width:auto!important;min-height:0!important;flex-direction:column;margin:0;border-radius:0;box-shadow:none}
.lu-side[data-part="sidebar"] .lu-sb-burger{display:inline-grid!important;position:absolute;right:12px;top:10px}
.lu-side[data-part="sidebar"]:not([data-mobile-open])>*:not(.lu-sb-burger):not(.lu-ws):not(:first-child){display:none}
.lu-side[data-part="sidebar"][data-mobile-open] .lu-sb-drawer{display:block!important}
.lu-side-rail[data-part="sidebar"]:not([data-mobile-open]) .lu-rail{flex-direction:row;width:auto;overflow:auto}
}`

function ensureCss() {
  if (document.getElementById(CSS_ID)) return
  const el = document.createElement("style")
  el.id = CSS_ID
  el.textContent = CSS
  document.head.appendChild(el)
}

const editable = (t) => t && (/^(INPUT|TEXTAREA|SELECT)$/.test(t.tagName) || t.isContentEditable)
const read = (k) => { try { return localStorage.getItem(k) } catch (_) { return null } }
const write = (k, v) => { try { localStorage.setItem(k, v) } catch (_) {} }

export default {
  mounted() {
    ensureCss()
    const el = this.el
    const attr = (n) => el.getAttribute(`phx-value-${n}`)
    this.serverCollapsed = attr("collapsed") === "true"
    this.persist = attr("persist") !== "false"
    this.collapsed = this.serverCollapsed
    if (!this.serverCollapsed && this.persist) {
      const saved = read(RAIL_KEY)
      if (saved === "1") this.collapsed = true
    }
    this.groupsKey = attr("groups") === "true" ? `linea-sidebar-groups:${el.id}` : null
    this.groupState = this.groupsKey ? JSON.parse(read(this.groupsKey) || "{}") : {}

    this.onClick = (e) => {
      const t = e.target
      if (t.closest("[data-sb-toggle]")) return this.setCollapsed(!this.collapsed)
      if (t.closest("[data-sb-burger]")) return this.toggleMobile()
      const head = t.closest("[data-sb-group]")
      if (head && el.contains(head)) return this.toggleGroup(head)
      const parent = t.closest("[data-sb-parent]")
      if (parent && el.contains(parent)) {
        const hasDest = parent.hasAttribute("data-sb-dest")
        const caret = t.closest(".caret")
        if (!hasDest || caret) { e.preventDefault(); this.toggleParent(parent) }
        else this.toggleParent(parent, true)
        return
      }
      if (this.collapsed && t.closest("[data-sb-module]")) this.setCollapsed(false)
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
    const now = this.el.getAttribute("phx-value-collapsed") === "true"
    if (now !== this.serverCollapsed) { this.serverCollapsed = now; this.collapsed = now }
    this.restoreGroups()
    this.apply()
  },
  destroyed() {
    document.removeEventListener("click", this.onDoc)
    window.removeEventListener("keydown", this.onKey)
  },
  setCollapsed(v) {
    this.collapsed = v
    if (this.persist) write(RAIL_KEY, v ? "1" : "0")
    this.apply()
    const evt = this.el.getAttribute("phx-value-on-collapse")
    if (evt) {
      const payload = {id: this.el.id, collapsed: v}
      const target = this.el.getAttribute("phx-value-target")
      target ? this.pushEventTo(target, evt, payload) : this.pushEvent(evt, payload)
    }
  },
  apply() {
    const el = this.el
    if (this.collapsed) el.setAttribute("data-collapsed", ""); else el.removeAttribute("data-collapsed")
    for (const b of document.querySelectorAll(`[data-rail-toggle="${CSS.escape(el.id)}"]`)) b.setAttribute("aria-pressed", String(this.collapsed))
    for (const b of el.querySelectorAll("[data-sb-toggle]")) b.setAttribute("aria-pressed", String(this.collapsed))
    for (const a of el.querySelectorAll(".lu-nav-item:not(.sub)")) {
      if (this.collapsed) {
        if (!a.hasAttribute("title")) { a.setAttribute("title", a.textContent.trim()); a.setAttribute("data-sb-t", "") }
      } else if (a.hasAttribute("data-sb-t")) { a.removeAttribute("title"); a.removeAttribute("data-sb-t") }
    }
  },
  toggleMobile() {
    const open = !this.el.hasAttribute("data-mobile-open")
    if (open) this.el.setAttribute("data-mobile-open", ""); else this.el.removeAttribute("data-mobile-open")
    const b = this.el.querySelector("[data-sb-burger]")
    if (b) b.setAttribute("aria-expanded", String(open))
  },
  toggleGroup(head, force) {
    const body = document.getElementById(head.getAttribute("aria-controls"))
    if (!body) return
    const open = force !== undefined ? force : head.getAttribute("aria-expanded") !== "true"
    head.setAttribute("aria-expanded", String(open))
    body.hidden = !open
    this.remember(head.getAttribute("data-sb-group"), open)
  },
  toggleParent(parent, force) {
    const key = parent.getAttribute("data-sb-parent")
    const open = force !== undefined ? force : parent.getAttribute("aria-expanded") !== "true"
    parent.setAttribute("aria-expanded", String(open))
    for (const c of this.el.querySelectorAll("[data-sb-child]")) if (c.getAttribute("data-sb-child") === key) c.hidden = !open
    this.remember(key, open)
  },
  remember(key, open) {
    if (!this.groupsKey) return
    this.groupState[key] = open
    write(this.groupsKey, JSON.stringify(this.groupState))
  },
  restoreGroups() {
    if (!this.groupsKey) return
    for (const head of this.el.querySelectorAll("[data-sb-group]")) {
      const k = head.getAttribute("data-sb-group")
      if (k in this.groupState) this.toggleGroup(head, this.groupState[k])
    }
    for (const p of this.el.querySelectorAll("[data-sb-parent]")) {
      const k = p.getAttribute("data-sb-parent")
      if (k in this.groupState) this.toggleParent(p, this.groupState[k])
    }
  },
}
