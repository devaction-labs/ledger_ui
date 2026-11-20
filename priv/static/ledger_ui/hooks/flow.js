// LedgerUI.Flow: redraws the connections of `<.flow>` from the real node boxes and drags nodes.
// With `data-branch` (the `steps` attr) it also branches in the browser: the `+` handles of a card
// open a menu, the chosen kind becomes a new card (cloned from the `<template data-flow-template>`s
// the component renders, so the hook holds no class names) joined by a connection; a condition
// also opens its "Sim"/"Não" ghost cards. It reads `data-part`/`data-*` only.
//
// The server lays the board out and renders the connection paths (no JavaScript needed to see
// it); this hook corrects the paths with the measured node heights and, when the board has
// `data-move-event`, lets a node be dragged with the pointer. A drop pushes
// `{id, x, y}` (the stage position of the node) to that event (to `phx-target` when set); the
// connections follow the node while it moves. Pointer events, clean-up in `destroyed`.

const RADIUS = 16
const GAP = 72
const INTERACTIVE = "a,button,input,select,textarea,label,[contenteditable],[data-no-drag]"
const SVGNS = "http://www.w3.org/2000/svg"

// The route of a connection added in the browser, from the box `a` to the box `b` on side `side`
// (`b` below, `r` right, `l` left); boxes are {x, y, w, h} in stage pixels.
const route = (a, b, side) => {
  if (side === "r" || side === "l") {
    const R = side === "r"
    const x1 = R ? a.x + a.w : a.x
    const y1 = a.y + a.h / 2
    let x2 = R ? b.x : b.x + b.w
    let y2 = b.y + b.h / 2
    if (R ? x2 < x1 + 12 : x2 > x1 - 12) {
      x2 = b.x + b.w / 2
      y2 = b.y
      return `M${x1} ${y1} C${x1 + (R ? 40 : -40)} ${y1} ${x2} ${y2 - 40} ${x2} ${y2}`
    }
    const k = Math.max(30, Math.abs(x2 - x1) / 2) * (R ? 1 : -1)
    return `M${x1} ${y1} C${x1 + k} ${y1} ${x2 - k} ${y2} ${x2} ${y2}`
  }
  const sx = a.x + a.w / 2
  const sy = a.y + a.h
  const tx = b.x + b.w / 2
  const ty = b.y
  if (ty - sy > 16) {
    if (Math.abs(tx - sx) < 3) return `M${sx} ${sy} V${ty}`
    const mid = sy + Math.min(28, (ty - sy) / 2)
    const r = Math.min(12, Math.abs(tx - sx) / 2, (ty - sy) / 2)
    const dir = tx > sx ? 1 : -1
    return `M${sx} ${sy} V${mid - r} Q${sx} ${mid} ${sx + dir * r} ${mid} H${tx - dir * r} Q${tx} ${mid} ${tx} ${mid + r} V${ty}`
  }
  const right = b.x > a.x + a.w / 2
  const x1 = right ? a.x + a.w : a.x
  const y1 = a.y + a.h / 2
  const x2 = right ? b.x : b.x + b.w
  const y2 = b.y + b.h / 2
  const k = Math.max(40, Math.abs(x2 - x1) / 2) * (right ? 1 : -1)
  return `M${x1} ${y1} C${x1 + k} ${y1} ${x2 - k} ${y2} ${x2} ${y2}`
}

const box = (n) => ({x: n.offsetLeft, y: n.offsetTop, w: n.offsetWidth, h: n.offsetHeight})

const path = (sx, sy, ex, ey) => {
  const dx = ex - sx
  if (Math.abs(dx) < 1) return `M${sx} ${sy} V${ey}`
  const mid = sy + Math.max(ey - sy, 2) / 2
  const r = Math.max(0, Math.min(RADIUS, Math.abs(dx) / 2, mid - sy, ey - mid))
  const dir = dx > 0 ? 1 : -1
  return `M${sx} ${sy} V${mid - r} Q${sx} ${mid} ${sx + dir * r} ${mid} H${ex - dir * r} Q${ex} ${mid} ${ex} ${mid + r} V${ey}`
}

export default {
  mounted() {
    this.drag = null
    this.count = 0
    this.menuCtx = null
    this.onDown = (e) => this.down(e)
    this.onMove = (e) => this.move(e)
    this.onUp = (e) => this.up(e)
    this.el.addEventListener("pointerdown", this.onDown)
    if (this.branching()) {
      this.onClick = (e) => this.click(e)
      this.onKey = (e) => this.key(e)
      this.onOutside = (e) => { if (this.menu() && !this.menu().contains(e.target) && !e.target.closest("[data-part=flow-handle],[data-ghost]")) this.closeMenu() }
      this.el.addEventListener("click", this.onClick)
      document.addEventListener("click", this.onOutside)
      document.addEventListener("keydown", this.onKey)
    }
    this.redraw()
  },

  updated() {
    this.redraw()
  },

  destroyed() {
    this.el.removeEventListener("pointerdown", this.onDown)
    if (this.onClick) {
      this.el.removeEventListener("click", this.onClick)
      document.removeEventListener("click", this.onOutside)
      document.removeEventListener("keydown", this.onKey)
    }
    this.stop()
  },

  branching() { return this.el.hasAttribute("data-branch") },
  stage() { return this.el.querySelector("[data-flow-stage]") },
  menu() { return this.el.querySelector("[data-part=flow-menu]") },

  nodes() {
    const map = new Map()
    this.el.querySelectorAll("[data-node]").forEach((n) => map.set(n.dataset.node, n))
    return map
  },

  // Paths and labels from the real boxes (offsets are relative to the stage).
  redraw() {
    const nodes = this.nodes()
    this.el.querySelectorAll("path[data-edge]").forEach((p) => {
      const a = nodes.get(p.dataset.from)
      const b = nodes.get(p.dataset.to)
      const label = this.el.querySelector(`[data-edge-label][data-from="${p.dataset.from}"][data-to="${p.dataset.to}"]`)
      if (!a || !b) {
        // a connection added in the browser leaves with its card
        if (p.dataset.side) { p.remove(); if (label) label.remove() }
        return
      }
      if (p.dataset.side) {
        p.setAttribute("d", route(box(a), box(b), p.dataset.side))
        if (label) {
          const len = p.getTotalLength()
          const m = p.getPointAtLength(len * 0.55)
          label.style.left = m.x + "px"
          label.style.top = m.y + "px"
        }
        return
      }
      const sx = a.offsetLeft + a.offsetWidth / 2
      let sy = a.offsetTop + a.offsetHeight
      const ex = b.offsetLeft + b.offsetWidth / 2
      const ey = b.offsetTop
      if (ey - sy > GAP + 8) sy = ey - GAP
      p.setAttribute("d", path(sx, sy, ex, ey))
      if (label) {
        label.style.left = (sx + ex) / 2 + "px"
        label.style.top = sy + Math.max(ey - sy, 2) / 2 + "px"
      }
    })
  },

  // The stage grows with the cards so none is cut off.
  grow() {
    const stage = this.stage()
    let w = 0
    let h = 0
    this.nodes().forEach((n) => { w = Math.max(w, n.offsetLeft + n.offsetWidth + 24); h = Math.max(h, n.offsetTop + n.offsetHeight + 40) })
    if (w > stage.offsetWidth) stage.style.width = w + "px"
    if (h > stage.offsetHeight) stage.style.height = h + "px"
  },

  down(e) {
    const event = this.el.dataset.luMoveEvent
    if ((!event && !this.branching()) || e.button > 0 || !e.isPrimary || this.drag) return
    const node = e.target.closest("[data-node]")
    if (!node || node.hasAttribute("data-ghost") || e.target.closest(INTERACTIVE)) return
    if (this.branching()) this.select(node)
    this.drag = {
      node, id: node.dataset.node, x0: e.clientX, y0: e.clientY, left: node.offsetLeft, top: node.offsetTop,
      pointer: e.pointerId, active: false,
    }
    window.addEventListener("pointermove", this.onMove)
    window.addEventListener("pointerup", this.onUp)
    window.addEventListener("pointercancel", this.onUp)
  },

  move(e) {
    const d = this.drag
    if (!d || e.pointerId !== d.pointer) return
    const dx = e.clientX - d.x0
    const dy = e.clientY - d.y0
    if (!d.active) {
      if (Math.hypot(dx, dy) < 4) return
      d.active = true
      d.node.style.cursor = "grabbing"
      d.node.setAttribute("data-grab", "")
      d.node.style.zIndex = "5"
      d.node.style.userSelect = "none"
    }
    d.x = Math.max(0, d.left + dx)
    d.y = Math.max(0, d.top + dy)
    d.node.style.left = d.x + "px"
    d.node.style.top = d.y + "px"
    if (this.branching()) this.grow()
    this.redraw()
  },

  up(e) {
    const d = this.drag
    if (!d || e.pointerId !== d.pointer) return
    this.stop()
    if (!d.active) return
    d.node.style.cursor = ""
    d.node.style.zIndex = ""
    d.node.style.userSelect = ""
    d.node.removeAttribute("data-grab")
    const payload = {id: d.id, x: Math.round(d.x), y: Math.round(d.y)}
    const event = this.el.dataset.luMoveEvent
    if (!event) return
    const target = this.el.getAttribute("phx-target")
    if (target) this.pushEventTo(target, event, payload)
    else this.pushEvent(event, payload)
  },

  stop() {
    window.removeEventListener("pointermove", this.onMove)
    window.removeEventListener("pointerup", this.onUp)
    window.removeEventListener("pointercancel", this.onUp)
    this.drag = null
  },

  // ---- branching in the browser ----------------------------------------------------------

  select(node) {
    this.nodes().forEach((n) => { if (n !== node) n.removeAttribute("data-selected") })
    if (node) node.setAttribute("data-selected", "")
  },

  click(e) {
    const item = e.target.closest("[data-flow-type]")
    if (item && this.menu().contains(item)) return this.choose(item.dataset.flowType)
    const handle = e.target.closest("[data-part=flow-handle]")
    if (handle) {
      const node = handle.closest("[data-node]")
      this.select(node)
      return this.openMenu(handle, {from: node, side: handle.dataset.side})
    }
    const node = e.target.closest("[data-node]")
    if (node && node.hasAttribute("data-ghost")) return this.openMenu(node, {ghost: node})
    if (node) return this.select(node)
    if (e.target.closest("[data-flow-stage]")) this.select(null)
  },

  key(e) {
    if (e.key === "Escape") return this.closeMenu()
    if ((e.key !== "Delete" && e.key !== "Backspace") || e.target.closest("input,textarea,[contenteditable=true]")) return
    const node = this.el.querySelector("[data-node][data-selected]")
    if (!node || this.nodes().size <= 1) return
    e.preventDefault()
    node.remove()
    this.redraw()
  },

  openMenu(anchor, ctx) {
    const menu = this.menu()
    this.menuCtx = ctx
    menu.hidden = false
    const r = anchor.getBoundingClientRect()
    menu.style.left = Math.min(window.innerWidth - 252, Math.max(8, r.left + r.width / 2 - 120)) + "px"
    let top = r.bottom + 8
    if (top + menu.offsetHeight > window.innerHeight) top = Math.max(8, r.top - 8 - menu.offsetHeight)
    menu.style.top = top + "px"
  },

  closeMenu() {
    const menu = this.menu()
    if (menu) menu.hidden = true
    this.menuCtx = null
  },

  template(kind, key) {
    const sel = key === undefined ? `template[data-flow-template=${kind}]` : `template[data-flow-template=${kind}][data-type="${key}"]`
    return this.el.querySelector(sel)
  },

  clone(kind, key) {
    const t = this.template(kind, key)
    return t && t.content.firstElementChild.cloneNode(true)
  },

  nextId() {
    let id
    do { id = `n-${++this.count}` } while (this.nodes().has(id))
    return id
  },

  // Puts `n` next to `from` on `side`, on a free spot (the stage width is the limit).
  place(from, n, side, index, pair) {
    const a = box(from)
    const w = n.offsetWidth
    const h = n.offsetHeight
    const stage = this.stage()
    const gap = 64
    const kids = [...this.el.querySelectorAll(`path[data-side="${side}"][data-from="${from.dataset.node}"]`)].length + (index || 0)
    let x, y
    if (side === "b") { y = a.y + a.h + gap; x = a.x + (pair ? (index === 0 ? -(w / 2 + 14) : w / 2 + 14) : kids * (w + 24)) }
    else if (side === "r") { x = a.x + a.w + gap; y = a.y + kids * (h + 28) }
    else { x = a.x - w - gap; y = a.y + kids * (h + 28) }
    x = Math.max(8, Math.min(stage.offsetWidth - w - 8, x))
    y = Math.max(8, y)
    const free = () => ![...this.nodes().values()].some((o) => {
      if (o === n) return false
      const b = box(o)
      return x < b.x + b.w + 16 && x + w + 16 > b.x && y < b.y + b.h + 16 && y + h + 16 > b.y
    })
    for (let tries = 0; !free() && tries < 12; tries++) {
      if (side === "b") { x += w + 24; if (x > stage.offsetWidth - w - 8) { x = 8; y += h + 40 } }
      else y += h + 28
    }
    n.style.left = Math.round(x) + "px"
    n.style.top = Math.round(y) + "px"
    n.dataset.x = Math.round(x)
    n.dataset.y = Math.round(y)
  },

  edge(from, to, side, label) {
    const svg = this.stage().querySelector("svg")
    const p = document.createElementNS(SVGNS, "path")
    p.setAttribute("data-edge", "")
    p.setAttribute("data-from", from.dataset.node)
    p.setAttribute("data-to", to.dataset.node)
    p.setAttribute("data-side", side)
    p.setAttribute("fill", "none")
    p.setAttribute("stroke", "var(--lu-line-strong)")
    p.setAttribute("stroke-width", "1.5")
    svg.appendChild(p)
    if (label) {
      const el = this.clone("label", label.tone)
      if (el) {
        el.textContent = label.label
        el.dataset.from = from.dataset.node
        el.dataset.to = to.dataset.node
        this.stage().appendChild(el)
      }
    }
    return p
  },

  mount(node) {
    node.dataset.node = this.nextId()
    this.stage().appendChild(node)
    node.animate([{transform: "scale(.92)", opacity: 0}, {transform: "none", opacity: 1}], {duration: 220, easing: "cubic-bezier(.3,.7,.3,1.2)"})
    return node
  },

  choose(key) {
    const ctx = this.menuCtx
    this.closeMenu()
    if (!ctx) return
    const node = this.clone("node", key)
    if (!node) return
    const kind = this.template("node", key)
    const branches = kind.dataset.branches ? JSON.parse(kind.dataset.branches) : []
    let from, side
    if (ctx.ghost) {
      // the ghost card becomes the chosen one, in its place and on its connection
      const ghost = ctx.ghost
      this.mount(node)
      node.style.left = ghost.style.left
      node.style.top = ghost.style.top
      node.dataset.x = ghost.dataset.x
      node.dataset.y = ghost.dataset.y
      this.el.querySelectorAll(`[data-to="${ghost.dataset.node}"]`).forEach((el) => { el.dataset.to = node.dataset.node })
      ghost.remove()
      from = null
    } else {
      from = ctx.from
      side = ctx.side
      this.mount(node)
      this.place(from, node, side)
      const p = this.edge(from, node, side)
      this.drawIn(p)
    }
    branches.forEach((br, i) => {
      const ghost = this.clone("ghost")
      ghost.querySelector("[data-slot=sub]").textContent = `${this.el.dataset.luBranchLabel || "Path"} ${br.label}`
      this.mount(ghost)
      ghost.setAttribute("data-ghost", "")
      this.place(node, ghost, "b", i, true)
      this.drawIn(this.edge(node, ghost, "b", br))
    })
    this.grow()
    this.redraw()
    this.select(node)
    this.el.dispatchEvent(new CustomEvent("ledger-ui:flow-add", {bubbles: true, detail: {id: node.dataset.node, kind: key, from: from && from.dataset.node, side}}))
    const event = this.el.dataset.luBranchEvent
    if (event) {
      const payload = {id: node.dataset.node, kind: key, from: from ? from.dataset.node : null, side: side || null}
      const target = this.el.getAttribute("phx-target")
      if (target) this.pushEventTo(target, event, payload)
      else this.pushEvent(event, payload)
    }
  },

  drawIn(p) {
    p.setAttribute("pathLength", "1")
    p.style.strokeDasharray = "1"
    const done = () => { p.style.strokeDasharray = ""; p.removeAttribute("pathLength") }
    const anim = p.animate([{strokeDashoffset: 1}, {strokeDashoffset: 0}], {duration: 500, easing: "ease-out"})
    anim.onfinish = done
  },
}
