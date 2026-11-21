// <.placement_stage>: an image with a dashed box. Press or drag on the image to put the centre of the box under the
// pointer (optimistic, limited to the edges); the corner handle resizes around the centre. The server hears about it
// at the end of the gesture: on_place %{"x","y"} (centre, fractions from the left / top) and on_resize %{"width"}.
// Keyboard: the arrow keys move the focused box by 1% (Shift: 10%) and push on_place on every press.

const MIN_WIDTH = 5
const clamp = (n, lo, hi) => Math.min(hi, Math.max(lo, n))
const round = (n) => Math.round(n * 10000) / 10000
const same = (a, b) => a.length === b.length && a.every((v, i) => Math.abs(v - b[i]) < 1e-6)
const KEYS = {ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1]}

export default {
  mounted() {
    this.gesture = null // null | {mode: "move" | "resize", id, start}
    this.pending = 0
    this.server = this.readServer()
    this.local = this.server
    this.onDown = (e) => this.down(e)
    this.onMove = (e) => this.gesture && this.moveTo(e)
    this.onUp = (e) => this.up(e)
    this.onCancel = () => this.cancel()
    this.onKey = (e) => this.key(e)
    this.el.addEventListener("pointerdown", this.onDown)
    this.el.addEventListener("pointermove", this.onMove)
    this.el.addEventListener("pointerup", this.onUp)
    this.el.addEventListener("pointercancel", this.onCancel)
    this.el.addEventListener("lostpointercapture", this.onCancel)
    this.el.addEventListener("keydown", this.onKey)
  },

  // A patch resets the style to what the server rendered: the server wins, except in the middle of a gesture
  // and while an event is on its way (an unchanged box is then not a "no").
  updated() {
    const next = this.readServer()
    const changed = !same(next, this.server)
    this.server = next
    if (this.gesture) return this.paint()
    if (changed || this.pending === 0) this.local = next
    this.paint()
  },

  destroyed() {
    this.el.removeEventListener("pointerdown", this.onDown)
    this.el.removeEventListener("pointermove", this.onMove)
    this.el.removeEventListener("pointerup", this.onUp)
    this.el.removeEventListener("pointercancel", this.onCancel)
    this.el.removeEventListener("lostpointercapture", this.onCancel)
    this.el.removeEventListener("keydown", this.onKey)
  },

  boxEl() { return this.el.querySelector('[data-part="placement-box"]') },
  imageEl() { return this.el.querySelector("img") || this.el },
  disabled() { return this.el.getAttribute("data-lu-disabled") === "true" },

  // [left, bottom, width, height], in % of the image
  readServer() {
    const raw = this.el.getAttribute("data-lu-box")
    return raw ? raw.split(",").map(Number) : [0, 0, 0, 0]
  },

  paint() {
    const box = this.boxEl()
    if (!box) return
    const [left, bottom, width, height] = this.local
    box.style.left = left + "%"
    box.style.bottom = bottom + "%"
    box.style.width = width + "%"
    box.style.height = height + "%"
  },

  // the pointer as % of the image, left -> right and top -> bottom
  point(e) {
    const r = this.imageEl().getBoundingClientRect()
    if (!r.width || !r.height) return null
    return {x: ((e.clientX - r.left) / r.width) * 100, y: ((e.clientY - r.top) / r.height) * 100}
  },

  // centre under (x, y), % from the left / top, kept inside the image
  place([, , w, h], x, y) {
    return [clamp(x - w / 2, 0, 100 - w), clamp(100 - y - h / 2, 0, 100 - h), w, h]
  },

  // width around the centre, same proportions as before, inside the image
  resize([left, bottom, w, h], x) {
    const cx = left + w / 2
    const cy = bottom + h / 2
    const k = w > 0 ? h / w : 0
    let room = 2 * Math.min(cx, 100 - cx)
    if (k > 0) room = Math.min(room, (2 * Math.min(cy, 100 - cy)) / k)
    const width = clamp(2 * Math.abs(x - cx), Math.min(MIN_WIDTH, room), Math.max(room, 0))
    const height = width * k
    return [cx - width / 2, cy - height / 2, width, height]
  },

  down(e) {
    if (this.disabled() || !this.boxEl() || (e.pointerType === "mouse" && e.button !== 0)) return
    const p = this.point(e)
    if (!p) return
    const resizing = !!(e.target.closest && e.target.closest("[data-handle]"))
    this.gesture = {mode: resizing ? "resize" : "move", start: this.local}
    try { this.el.setPointerCapture && this.el.setPointerCapture(e.pointerId) } catch (_) { /* no active pointer */ }
    this.boxEl().focus({preventScroll: true})
    if (e.cancelable) e.preventDefault()
    this.apply(p)
  },

  moveTo(e) {
    const p = this.point(e)
    if (p) this.apply(p)
  },

  apply(p) {
    this.local = this.gesture.mode === "resize" ? this.resize(this.gesture.start, p.x) : this.place(this.local, p.x, p.y)
    this.paint()
  },

  up(e) {
    if (!this.gesture) return
    const mode = this.gesture.mode
    const p = this.point(e)
    if (p) this.apply(p)
    this.gesture = null
    try { this.el.releasePointerCapture && this.el.releasePointerCapture(e.pointerId) } catch (_) { /* already released */ }
    if (mode === "resize") this.push("on-resize", {width: round(this.local[2] / 100)})
    else this.push("on-place", this.center())
  },

  // lost capture or a cancelled touch: back to where the box was, nothing is sent
  cancel() {
    if (!this.gesture) return
    this.local = this.gesture.start
    this.gesture = null
    this.paint()
  },

  center() {
    const [left, bottom, w, h] = this.local
    return {x: round((left + w / 2) / 100), y: round(1 - (bottom + h / 2) / 100)}
  },

  key(e) {
    const dir = KEYS[e.key]
    if (!dir || this.disabled() || e.target !== this.boxEl() || e.altKey || e.ctrlKey || e.metaKey) return
    e.preventDefault()
    const step = e.shiftKey ? 10 : 1
    const [left, bottom, w, h] = this.local
    this.local = [clamp(left + dir[0] * step, 0, 100 - w), clamp(bottom - dir[1] * step, 0, 100 - h), w, h]
    this.paint()
    this.push("on-place", this.center())
  },

  push(name, payload) {
    const event = this.el.getAttribute("data-lu-" + name)
    if (!event) return
    const target = this.el.getAttribute("phx-target")
    this.pending++
    const done = () => { this.pending = Math.max(0, this.pending - 1) }
    if (target) this.pushEventTo(/^\d+$/.test(target) ? `[data-phx-component="${target}"]` : target, event, payload, done)
    else this.pushEvent(event, payload, done)
  },
}
