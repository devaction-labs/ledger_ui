// LedgerUI.Sortable: drag and drop of items between lists (kanban columns, to-do lists) on
// pointer events, no library. The server's render is the new order: nothing is moved in the
// browser; a drop pushes `{id, from, to, index}` to `data-event`.
//
// Markup: the hook element is either one list (`data-list`) or a board that holds lists
// (`[data-part=kanban-column]` columns or any `[data-list]`). Items are the children of a list that
// have `data-id` (or are `[data-part=kanban-card]`); ids fall back to the element ids.
//
// Attributes (on the hook element or a list; a list's own wins): data-event, data-target (or
// phx-target), data-group, data-list, data-handle, data-axis (x | y), data-disabled.
//
// While dragging: the original stays as a dimmed placeholder (`data-dragging`), a lifted copy
// follows the pointer (`data-drag-ghost`), the list under it is `data-over` (styled by the list's own
// `data-[over]:` utilities) and a dashed slot (`data-drop-slot`) shows where it lands. Escape cancels. A mouse or pen drags after a few
// pixels, a finger after holding the item for a moment. Respects `prefers-reduced-motion`.

const MOVE_THRESHOLD = 4
const HOLD_MS = 250
const EDGE = 48
const INTERACTIVE = "a,button,input,select,textarea,label,[contenteditable],[data-no-drag]"
const LIST_SELECTOR = "[data-list],[data-part=kanban-column]"
const ITEM_SELECTOR = "[data-id],[data-part=kanban-card]"

const reduced = () => window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches
const listId = (list) => list.dataset.list || list.id
const itemId = (item) => item.dataset.id || item.id
const flag = (v) => v != null && v !== "false"

export default {
  mounted() {
    this.drag = null
    this.onDown = (e) => this.down(e)
    this.el.addEventListener("pointerdown", this.onDown)
    this.onKey = (e) => { if (e.key === "Escape" && this.drag) this.finish(false) }
    this.onMove = (e) => this.move(e)
    this.onUp = (e) => this.up(e)
    this.onTouchMove = (e) => { if (this.drag && this.drag.active) e.preventDefault() }
  },

  destroyed() {
    this.el.removeEventListener("pointerdown", this.onDown)
    this.teardown()
  },

  // -- configuration ---------------------------------------------------------------------

  isList(el) { return el.matches && el.matches(LIST_SELECTOR) },

  // The list an element belongs to (the hook element itself when it is a list).
  listOf(el) {
    const list = el.closest(LIST_SELECTOR)
    return list && (this.el.contains(list) || list === this.el) ? list : null
  },

  rootOf(list) { return list.closest('[phx-hook="LedgerUI.Sortable"]') || list },

  config(list, key) {
    const root = this.rootOf(list)
    return list.dataset[key] != null ? list.dataset[key] : root.dataset[key]
  },

  groupOf(list) {
    const g = this.config(list, "group")
    if (g) return g
    // Lists of a board share the board; a lone list keeps its items.
    const root = this.rootOf(list)
    return root === list ? "__" + (list.id || listId(list)) : root.id
  },

  disabled(list) { return flag(this.config(list, "disabled")) },

  itemsOf(list) {
    return Array.from(list.children).filter((c) => c.matches(ITEM_SELECTOR) && !c.hasAttribute("data-drop-slot"))
  },

  targets(group) {
    return Array.from(document.querySelectorAll(LIST_SELECTOR)).filter((l) => this.groupOf(l) === group && !this.disabled(l))
  },

  // -- pointer flow -----------------------------------------------------------------------

  down(e) {
    if (this.drag || e.button > 0 || !e.isPrimary) return
    const item = e.target.closest(ITEM_SELECTOR)
    if (!item || !this.el.contains(item)) return
    const list = item.parentElement && item.parentElement.closest(LIST_SELECTOR)
    if (!list || this.disabled(list) || e.target.closest(INTERACTIVE)) return
    const handle = this.config(list, "handle")
    if (handle && !e.target.closest(handle)) return

    this.drag = {
      item, list, id: itemId(item), from: listId(list), group: this.groupOf(list),
      x0: e.clientX, y0: e.clientY, x: e.clientX, y: e.clientY, pointer: e.pointerId, type: e.pointerType,
      active: false, over: null, slot: null, axis: this.config(list, "axis") === "x" ? "x" : "y",
      index0: this.itemsOf(list).indexOf(item),
    }
    window.addEventListener("pointermove", this.onMove)
    window.addEventListener("pointerup", this.onUp)
    window.addEventListener("pointercancel", this.onUp)
    window.addEventListener("keydown", this.onKey)
    document.addEventListener("touchmove", this.onTouchMove, {passive: false})
    if (e.pointerType === "touch") this.drag.hold = setTimeout(() => this.begin(), HOLD_MS)
  },

  move(e) {
    const d = this.drag
    if (!d || e.pointerId !== d.pointer) return
    d.x = e.clientX
    d.y = e.clientY
    if (!d.active) {
      const dist = Math.hypot(d.x - d.x0, d.y - d.y0)
      // A finger that moves before the hold is a scroll, not a drag.
      if (d.type === "touch") { if (dist > 8) this.teardown() }
      else if (dist >= MOVE_THRESHOLD) this.begin()
      return
    }
    this.place()
  },

  up(e) {
    const d = this.drag
    if (!d || e.pointerId !== d.pointer) return
    this.finish(d.active && e.type !== "pointercancel")
  },

  // -- dragging ---------------------------------------------------------------------------

  begin() {
    const d = this.drag
    if (!d || d.active) return
    clearTimeout(d.hold)
    d.active = true
    const rect = d.item.getBoundingClientRect()
    d.dx = d.x0 - rect.left
    d.dy = d.y0 - rect.top
    d.rect = rect

    const ghost = d.item.cloneNode(true)
    ghost.removeAttribute("id")
    ghost.setAttribute("data-drag-ghost", "")
    ghost.setAttribute("aria-hidden", "true")
    Object.assign(ghost.style, {
      position: "fixed", left: "0", top: "0", width: rect.width + "px", height: rect.height + "px",
      margin: "0", zIndex: "9999", pointerEvents: "none", boxShadow: "0 24px 48px -12px rgba(15,15,20,.35)",
      transition: "none", willChange: "transform", cursor: "grabbing", opacity: ".92",
    })
    document.body.appendChild(ghost)
    d.ghost = ghost
    d.tilt = 0

    d.item.setAttribute("data-dragging", "")
    d.item.style.opacity = ".35"
    d.item.style.outline = "1.5px dashed var(--lu-line-strong, currentColor)"
    document.body.style.userSelect = "none"
    this.paint()
    this.place()
    this.scrollLoop()
  },

  paint() {
    const d = this.drag
    const tilt = Math.max(-6, Math.min(6, (d.x - (d.px == null ? d.x : d.px)) * 0.4))
    d.px = d.x
    d.tilt = d.tilt * 0.8 + tilt * 0.2
    d.ghost.style.transform = `translate(${d.x - d.dx}px, ${d.y - d.dy}px) rotate(${d.tilt}deg)`
  },

  // The list under the pointer and the index the card takes there.
  place() {
    const d = this.drag
    if (!d || !d.active) return
    this.paint()
    const lists = this.targets(d.group)
    const under = document.elementsFromPoint(d.x, d.y)
    let over = null
    for (const el of under) {
      const l = el.closest && el.closest(LIST_SELECTOR)
      if (l && lists.includes(l)) { over = l; break }
    }
    if (d.over && d.over !== over) d.over.removeAttribute("data-over")
    d.over = over
    if (!over) return this.dropSlot(null)
    over.setAttribute("data-over", "")

    const items = this.itemsOf(over).filter((i) => i !== d.item)
    const horizontal = d.axis === "x"
    let index = items.length
    for (let i = 0; i < items.length; i++) {
      const r = items[i].getBoundingClientRect()
      const mid = horizontal ? r.left + r.width / 2 : r.top + r.height / 2
      if ((horizontal ? d.x : d.y) < mid) { index = i; break }
    }
    d.index = index
    this.dropSlot(over, items, index)
  },

  dropSlot(list, items, index) {
    const d = this.drag
    if (!list) { if (d.slot) d.slot.remove(); d.slot = null; return }
    if (!d.slot) {
      d.slot = document.createElement("div")
      d.slot.setAttribute("data-drop-slot", "")
      d.slot.setAttribute("aria-hidden", "true")
      Object.assign(d.slot.style, {
        height: d.rect.height + "px", border: "1.5px dashed var(--lu-line-strong, currentColor)", borderRadius: "inherit",
        background: "var(--lu-bg-sunken, transparent)", minHeight: "36px",
        boxSizing: "border-box", flex: "none", opacity: ".7", pointerEvents: "none",
      })
      d.slot.style.borderRadius = getComputedStyle(d.item).borderRadius
    }
    const ref = items[index] || null
    const sameSpot = d.slot.parentElement === list && (ref ? d.slot.nextElementSibling === ref : this.isLast(d.slot, list))
    if (sameSpot) return
    if (ref) list.insertBefore(d.slot, ref)
    else {
      // After the last item, before a trailing footer/hint when there is one.
      const last = this.itemsOf(list).filter((i) => i !== d.item).pop()
      if (last && last.nextSibling) list.insertBefore(d.slot, last.nextSibling)
      else list.appendChild(d.slot)
    }
  },

  isLast(slot, list) {
    const last = this.itemsOf(list).filter((i) => i !== this.drag.item).pop()
    return !last || slot.previousElementSibling === last
  },

  scrollLoop() {
    const step = () => {
      const d = this.drag
      if (!d || !d.active) return
      const root = this.rootOf(d.list)
      const dir = (pos, a, b) => (pos < a + EDGE ? -1 : pos > b - EDGE ? 1 : 0)
      if (root.scrollWidth > root.clientWidth) {
        const r = root.getBoundingClientRect()
        root.scrollLeft += dir(d.x, r.left, r.right) * 14
      }
      if (d.over && d.over.scrollHeight > d.over.clientHeight) {
        const r = d.over.getBoundingClientRect()
        d.over.scrollTop += dir(d.y, r.top, r.bottom) * 14
      }
      d.raf = requestAnimationFrame(step)
    }
    this.drag.raf = requestAnimationFrame(step)
  },

  // -- end --------------------------------------------------------------------------------

  finish(commit) {
    const d = this.drag
    if (!d || d.landing) return
    if (!d.active) return this.teardown()
    cancelAnimationFrame(d.raf)

    const over = commit ? d.over : null
    let payload = null
    if (over) {
      const to = listId(over)
      const index = d.index == null ? 0 : d.index
      const unchanged = to === d.from && index === d.index0
      if (!unchanged) payload = {id: d.id, from: d.from, to, index}
    }

    // Glide into the slot on a drop, back to the origin when cancelled.
    d.landing = true
    const dest = over && d.slot ? d.slot.getBoundingClientRect() : d.item.getBoundingClientRect()
    const ghost = d.ghost
    const done = () => {
      // `data-local`: the board moves the card itself (a demo, or a board the server never re-renders)
      if (over && d.slot && d.slot.parentElement && flag(this.config(d.list, "luLocal"))) this.moveLocal(d, over)
      this.teardown()
      if (payload) this.push(d, payload)
    }
    if (reduced() || !ghost) return done()
    ghost.style.transition = "transform .18s cubic-bezier(.3,.7,.4,1)"
    ghost.style.transform = `translate(${dest.left}px, ${dest.top}px) rotate(0deg)`
    let called = false
    const once = () => { if (!called) { called = true; done() } }
    ghost.addEventListener("transitionend", once, {once: true})
    setTimeout(once, 260)
    window.removeEventListener("pointermove", this.onMove)
  },

  // Puts the card where the slot is and refreshes the counters of the two columns.
  moveLocal(d, over) {
    const from = d.list
    d.slot.parentElement.insertBefore(d.item, d.slot)
    for (const list of new Set([from, over])) {
      const count = list.querySelector("[data-part=kanban-column-count]")
      if (count) count.textContent = this.itemsOf(list).length
    }
  },

  push(d, payload) {
    const event = this.config(d.list, "event")
    if (!event) return
    const target = this.config(d.list, "target") || this.rootOf(d.list).getAttribute("phx-target")
    if (target) this.pushEventTo(target, event, payload)
    else this.pushEvent(event, payload)
  },

  teardown() {
    const d = this.drag
    window.removeEventListener("pointermove", this.onMove)
    window.removeEventListener("pointerup", this.onUp)
    window.removeEventListener("pointercancel", this.onUp)
    window.removeEventListener("keydown", this.onKey)
    document.removeEventListener("touchmove", this.onTouchMove)
    if (!d) return
    clearTimeout(d.hold)
    cancelAnimationFrame(d.raf)
    if (d.ghost) d.ghost.remove()
    if (d.slot) d.slot.remove()
    if (d.over) d.over.removeAttribute("data-over")
    if (d.item) {
      d.item.removeAttribute("data-dragging")
      d.item.style.opacity = ""
      d.item.style.outline = ""
    }
    document.body.style.userSelect = ""
    this.drag = null
  },
}
