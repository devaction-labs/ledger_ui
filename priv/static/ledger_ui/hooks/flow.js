// LedgerUI.Flow: redraws the connections of `<.flow>` from the real node boxes and drags nodes.
//
// The server lays the board out and renders the connection paths (no JavaScript needed to see
// it); this hook corrects the paths with the measured node heights and, when the board has
// `data-move-event`, lets a node be dragged with the pointer. A drop pushes
// `{id, x, y}` (the stage position of the node) to that event (to `phx-target` when set); the
// connections follow the node while it moves. Pointer events, clean-up in `destroyed`.

const RADIUS = 16
const GAP = 72
const INTERACTIVE = "a,button,input,select,textarea,label,[contenteditable],[data-no-drag]"

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
    this.onDown = (e) => this.down(e)
    this.onMove = (e) => this.move(e)
    this.onUp = (e) => this.up(e)
    this.el.addEventListener("pointerdown", this.onDown)
    this.redraw()
  },

  updated() {
    this.redraw()
  },

  destroyed() {
    this.el.removeEventListener("pointerdown", this.onDown)
    this.stop()
  },

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
      if (!a || !b) return
      const sx = a.offsetLeft + a.offsetWidth / 2
      let sy = a.offsetTop + a.offsetHeight
      const ex = b.offsetLeft + b.offsetWidth / 2
      const ey = b.offsetTop
      if (ey - sy > GAP + 8) sy = ey - GAP
      p.setAttribute("d", path(sx, sy, ex, ey))
      const label = this.el.querySelector(`[data-edge-label][data-from="${p.dataset.from}"][data-to="${p.dataset.to}"]`)
      if (label) {
        label.style.left = (sx + ex) / 2 + "px"
        label.style.top = sy + Math.max(ey - sy, 2) / 2 + "px"
      }
    })
  },

  down(e) {
    const event = this.el.dataset.luMoveEvent
    if (!event || e.button > 0 || !e.isPrimary || this.drag) return
    const node = e.target.closest("[data-node]")
    if (!node || e.target.closest(INTERACTIVE)) return
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
      d.node.style.zIndex = "5"
      d.node.style.userSelect = "none"
    }
    d.x = Math.max(0, d.left + dx)
    d.y = Math.max(0, d.top + dy)
    d.node.style.left = d.x + "px"
    d.node.style.top = d.y + "px"
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
    const payload = {id: d.id, x: Math.round(d.x), y: Math.round(d.y)}
    const event = this.el.dataset.luMoveEvent
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
}
