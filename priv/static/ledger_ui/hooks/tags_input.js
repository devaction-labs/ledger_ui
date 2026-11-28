// LedgerUI.TagsInput: typed text becomes a tag on Enter, Tab or a comma; Backspace and the
// remove button take it back. Tags are submitted through the hidden <select multiple>, which
// fires a bubbling `input` event. A value sent by the server wins over the one in the browser.

const PATHS = {
  x: '<path d="M19.0005 4.99988L5.00049 18.9999M5.00049 4.99988L19.0005 18.9999"/>',
  check: '<path d="M5 14L8.5 17.5L19 6.5"/>',
}
// The utilities of the nodes drawn here come from the server (`data-lu-cls`, a JSON map).
const icon = (cls, name) => {
  const t = document.createElement("template")
  t.innerHTML = `<svg class="${cls.icon}" viewBox="0 0 24 24" aria-hidden="true" data-icon="${name}">${PATHS[name]}</svg>`
  return t.content.firstElementChild
}

const POPOVER = typeof HTMLElement !== "undefined" && "showPopover" in HTMLElement.prototype

// The panel goes in the top layer (popover="manual"), like the Dropdown menu: `position: fixed` then
// counts from the viewport even inside a modal, drawer or sheet (an ancestor with `transform` would
// otherwise become its containing block and shift it). The `popover` attribute is set here, so the
// server HTML stays as it was; a LiveView patch that drops it is repaired by the next `layer(pop, open)`.
const layer = (pop, on) => {
  if (!POPOVER || !pop) return
  if (on) {
    if (pop.getAttribute("popover") !== "manual") pop.setAttribute("popover", "manual")
    if (pop.isConnected && !pop.matches(":popover-open")) pop.showPopover()
  } else if (pop.matches(":popover-open")) pop.hidePopover()
}

// Opened during the entry animation of a modal/drawer/sheet, the field is still moving: follow it
// frame by frame (and only while an animation of an ancestor runs), so the panel ends up on the field.
const follow = (el, again) => {
  const live = () =>
    (document.getAnimations ? document.getAnimations() : []).some((a) => a.playState === "running" && a.effect && a.effect.target && a.effect.target.contains(el))
  if (!live()) return
  const tick = () => {
    again()
    if (live()) requestAnimationFrame(tick)
  }
  requestAnimationFrame(tick)
}

const norm = (s) =>
  (s || "").normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase()

// `hidden` loses to any `display` the stylesheet sets (the option rows, the tags...): set both.
const hide = (el, on, show = "") => {
  el.hidden = on
  el.style.display = on ? "none" : show
}

export default {
  cls() { return (this._cls = this._cls || JSON.parse(this.el.dataset.luCls || "{}")) },

  mounted() {
    this.isOpen = false
    this.active = null
    this.idSeq = 0
    this.q = ""
    this.dirty = false
    this.removable()
    this.srv = JSON.stringify(this.readServer())
    this.tags = this.readServer()
    this.onClick = (e) => this.click(e)
    this.onKey = (e) => this.key(e)
    this.onInput = (e) => this.typed(e)
    this.onPaste = (e) => this.paste(e)
    this.onDoc = (e) => {
      if (this.isOpen && !this.el.contains(e.target)) this.setOpen(false)
    }
    this.onReflow = () => this.isOpen && this.position()
    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("keydown", this.onKey)
    this.el.addEventListener("input", this.onInput)
    this.el.addEventListener("paste", this.onPaste)
    // `pointerdown` on `document` (to close the list) is added while the list is open, not per instance.
    this.render()
  },

  updated() {
    const sv = this.readServer()
    const json = JSON.stringify(sv)
    if (json !== this.srv) {
      this.srv = json
      this.tags = sv
      this.dirty = false
    }
    layer(this.pop(), this.isOpen)
    hide(this.pop(), !this.isOpen)
    this.render()
    if (this.isOpen) this.position()
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("keydown", this.onKey)
    this.el.removeEventListener("input", this.onInput)
    this.el.removeEventListener("paste", this.onPaste)
    document.removeEventListener("pointerdown", this.onDoc)
    window.removeEventListener("resize", this.onReflow)
    window.removeEventListener("scroll", this.onReflow, true)
    clearTimeout(this.timer)
  },

  d() { return this.el.dataset },
  input() { return this.el.querySelector(":scope > input:not([type=hidden])") },
  // Without suggestions the server renders no panel: a detached stand-in keeps the code simple.
  pop() {
    const p = this.el.querySelector('[data-part="tags-input-panel"]')
    if (p) return p
    if (!this.dummy) {
      this.dummy = document.createElement("div")
      this.dummy.innerHTML = "<div data-lu-list></div>"
    }
    return this.dummy
  },
  list() { return this.pop().querySelector("[data-lu-list]") },
  items() { return [...this.list().querySelectorAll('[data-part="listbox-option"][data-lu-value]')] },
  hidden() { return this.el.querySelector(":scope > select[hidden]") },
  // Removable when the server drew a remove button (or said so, when it had no tag to draw).
  removable() {
    const b = this.el.querySelector(':scope > [data-part="tags-input-tag"] [data-lu-remove]')
    if (b) {
      this.rm = { on: true, label: b.getAttribute("aria-label") }
    } else if ("luRemovable" in this.d()) {
      this.rm = { on: true, label: this.d().luRemoveLabel }
    }
    return !!(this.rm && this.rm.on)
  },
  removeLabel() {
    return (this.rm && this.rm.label) || this.d().luRemoveLabel || "Remove"
  },
  locked() { return "luDisabled" in this.d() },
  max() { return parseInt(this.d().luMax || "0", 10) },
  free() { return this.d().luCreate !== "false" },

  readServer() {
    const s = this.hidden()
    if (s) {
      return [...s.options]
        .filter((o) => o.value !== "")
        .map((o) => ({ value: o.value, label: o.textContent.trim() }))
    }
    return [...this.el.querySelectorAll(':scope > [data-part="tags-input-tag"]')].map((t) => ({
      value: t.dataset.luValue || t.firstChild.textContent.trim(),
      label: t.firstChild.textContent.trim(),
    }))
  },

  // ---- rendering ------------------------------------------------------------------
  render() {
    if (this.dirty) this.renderTags()
    const input = this.input()
    const max = this.max()
    const full = max && this.tags.length >= max
    input.disabled = this.locked() || !!full
    if (max) {
      input.placeholder = full ? this.d().luLimitPlaceholder || "Limit reached" : this.d().luPlaceholder || ""
      const c = this.el.querySelector("[data-lu-counter]") || (this.el.nextElementSibling && this.el.nextElementSibling.matches("[data-lu-counter]") ? this.el.nextElementSibling : null)
      if (c) {
        c.textContent = `${this.tags.length} / ${max}`
        hide(c, !full)
      }
    }
    this.syncSelect()
    this.filter()
  },

  renderTags() {
    this.removable()
    this.el.querySelectorAll(':scope > [data-part="tags-input-tag"]').forEach((n) => n.remove())
    const input = this.input()
    for (const t of this.tags) {
      const tag = document.createElement("span")
      tag.className = this.cls().tag
      tag.dataset.part = "tags-input-tag"
      tag.dataset.luValue = t.value
      tag.appendChild(document.createTextNode(t.label))
      if (this.removable() && !this.locked()) {
        const b = document.createElement("button")
        b.type = "button"
        b.setAttribute("data-lu-remove", "")
        b.dataset.part = "tags-input-tag-remove"
        b.className = this.cls().remove
        b.setAttribute("aria-label", this.removeLabel())
        b.appendChild(icon(this.cls(), "x"))
        tag.appendChild(b)
      }
      this.el.insertBefore(tag, input)
    }
    const clear = this.el.querySelector("[data-lu-clear]")
    if (clear) hide(clear, !this.tags.length, "inline-grid")
  },

  syncSelect() {
    const s = this.hidden()
    if (!s) return
    const cur = [...s.options].filter((o) => o.value !== "").map((o) => o.value)
    if (JSON.stringify(cur) === JSON.stringify(this.tags.map((t) => t.value))) return
    s.querySelectorAll("option").forEach((o) => o.value !== "" && o.remove())
    for (const t of this.tags) {
      const o = document.createElement("option")
      o.value = t.value
      o.textContent = t.label
      o.selected = true
      s.appendChild(o)
    }
  },

  filter() {
    const q = norm(this.q.trim())
    const server = !!this.d().luOnSearch
    const chosen = new Set(this.tags.map((t) => t.value))
    let shown = 0
    for (const it of this.items()) {
      const ok = !chosen.has(it.dataset.luValue) && (server || !q || norm(it.dataset.luLabel).includes(q))
      hide(it, !ok)
      if (ok) shown++
    }
    const create = this.pop().querySelector("[data-lu-create-row]")
    const text = this.q.trim()
    const dup = this.tags.some((t) => norm(t.value) === norm(text))
    const exact = this.items().some((i) => norm(i.dataset.luLabel) === norm(text))
    const show = this.free() && !!text && !dup && !exact
    if (create) {
      hide(create, !show)
      if (show) {
        create.textContent = ""
        const hint = this.d().luCreateHint === undefined ? "Enter" : this.d().luCreateHint
        if (hint) {
          const k = document.createElement("span")
          k.className = this.cls().right
          k.style.marginLeft = "0"
          k.textContent = hint
          create.appendChild(k)
        }
        create.appendChild(document.createTextNode(`${this.d().luCreateLabel || "Add"} “${text}”`))
      }
      // create_position: "top" keeps the row before the suggestions, "bottom" after them.
      if (this.d().luCreatePosition === "bottom") this.pop().insertBefore(create, this.pop().querySelector("[data-lu-empty]"))
      else this.pop().insertBefore(create, this.list())
    }
    const empty = this.pop().querySelector("[data-lu-empty]")
    if (empty) {
      empty.textContent = (this.d().luNoResults || "No results found").replace("%{query}", this.q)
      hide(empty, !(shown === 0 && !show && !!text))
    }
    this.highlight(show && this.d().luCreatePosition !== "bottom" ? create : this.visible()[0])
  },

  visible() {
    const rows = this.items().filter((i) => !i.hidden && i.getAttribute("aria-disabled") !== "true")
    const c = this.pop().querySelector("[data-lu-create-row]")
    if (c && !c.hidden) this.d().luCreatePosition === "bottom" ? rows.push(c) : rows.unshift(c)
    return rows
  },

  highlight(item) {
    this.pop().querySelectorAll("[data-hl]").forEach((n) => n.removeAttribute("data-hl"))
    this.active = item || null
    if (item) item.setAttribute("data-hl", "")
    this.describe()
  },

  // `aria-expanded` and `aria-activedescendant` of the field (`role="combobox"`, drawn when there is a
  // panel): the lit row is named while the list is open.
  describe() {
    const input = this.input()
    if (!input || input.getAttribute("role") !== "combobox") return
    input.setAttribute("aria-expanded", String(this.isOpen))
    if (this.isOpen && this.active) {
      if (!this.active.id) this.active.id = `${this.pop().id || this.el.id + "-pop"}-x${++this.idSeq}`
      input.setAttribute("aria-activedescendant", this.active.id)
    } else {
      input.removeAttribute("aria-activedescendant")
    }
  },

  setOpen(open) {
    if (open === this.isOpen) return
    if (open && (!this.el.querySelector('[data-part="tags-input-panel"]') || this.locked())) return
    this.isOpen = open
    if (open) hide(this.pop(), false)
    layer(this.pop(), open)
    if (!open) hide(this.pop(), true)
    this.describe()
    if (open) {
      this.position()
      follow(this.el, this.onReflow)
      window.addEventListener("resize", this.onReflow)
      window.addEventListener("scroll", this.onReflow, true)
      document.addEventListener("pointerdown", this.onDoc)
    } else {
      window.removeEventListener("resize", this.onReflow)
      window.removeEventListener("scroll", this.onReflow, true)
      document.removeEventListener("pointerdown", this.onDoc)
    }
  },

  position() {
    const pop = this.pop()
    const r = this.el.getBoundingClientRect()
    pop.style.position = "fixed"
    pop.style.zIndex = "80"
    pop.style.margin = "0"
    pop.style.right = "auto"
    pop.style.color = "inherit" // the UA popover style sets CanvasText
    pop.style.bottom = "auto"
    pop.style.boxSizing = "border-box"
    pop.style.overflowY = "auto"
    pop.style.left = r.left + "px"
    pop.style.width = r.width + "px"
    const room = window.innerHeight - r.bottom - 14
    pop.style.top = r.bottom + 6 + "px"
    pop.style.maxHeight = Math.min(Math.max(room, 120), 280) + "px"
  },

  // ---- events -----------------------------------------------------------------------
  click(e) {
    const t = e.target
    const rm = t.closest("[data-lu-remove]")
    if (rm && this.el.contains(rm)) {
      e.preventDefault()
      const tag = rm.closest('[data-part="tags-input-tag"]')
      this.removeTag(tag.dataset.luValue)
      return
    }
    if (t.closest("[data-lu-clear]")) {
      e.preventDefault()
      this.tags = []
      this.commit()
      return
    }
    const create = t.closest("[data-lu-create-row]")
    if (create) return this.addText(this.q)
    const item = t.closest('[data-part="listbox-option"][data-lu-value]')
    if (item && this.pop().contains(item)) {
      this.add({ value: item.dataset.luValue, label: item.dataset.luLabel })
      return
    }
    if (!this.pop().contains(t)) {
      this.input().focus()
      this.setOpen(true)
    }
  },

  key(e) {
    const input = this.input()
    if (e.target !== input) return
    const rows = this.visible()
    const i = rows.indexOf(this.active)
    switch (e.key) {
      case "Enter":
        e.preventDefault()
        if (this.isOpen && this.active && this.active.matches('[data-part="listbox-option"][data-lu-value]')) {
          this.add({ value: this.active.dataset.luValue, label: this.active.dataset.luLabel })
        } else {
          this.addText(input.value)
        }
        break
      case "Tab":
        if (input.value.trim() && this.free()) {
          e.preventDefault()
          this.addText(input.value)
        } else {
          this.setOpen(false)
        }
        break
      case ",":
        if (this.free()) {
          e.preventDefault()
          this.addText(input.value)
        }
        break
      case "Backspace":
        if (input.value === "" && this.tags.length && !this.locked()) {
          e.preventDefault()
          const last = this.tags[this.tags.length - 1]
          this.removeTag(last.value)
          if ("luRestore" in this.d()) {
            input.value = last.label
            this.q = last.label
            this.filter()
          }
        }
        break
      case "ArrowDown":
        e.preventDefault()
        this.setOpen(true)
        this.highlight(rows[Math.min(i + 1, rows.length - 1)] || rows[0])
        break
      case "ArrowUp":
        e.preventDefault()
        this.highlight(rows[Math.max(i - 1, 0)])
        break
      case "Escape":
        if (this.isOpen) {
          e.preventDefault()
          e.stopPropagation()
          this.setOpen(false)
        }
        break
    }
  },

  typed(e) {
    if (e.target !== this.input()) return
    e.stopPropagation()
    this.q = e.target.value
    this.setOpen(true)
    this.filter()
    const ev = this.d().luOnSearch
    if (ev) {
      clearTimeout(this.timer)
      this.timer = setTimeout(() => {
        let target = this.d().luTarget
        if (target && /^\d+$/.test(target)) target = parseInt(target, 10)
        const payload = { id: this.el.id, query: this.q }
        target ? this.pushEventTo(target, ev, payload) : this.pushEvent(ev, payload)
      }, parseInt(this.d().luDebounce || "300", 10))
    }
  },

  paste(e) {
    if (e.target !== this.input() || !this.free()) return
    const text = (e.clipboardData || window.clipboardData).getData("text")
    if (!text.includes(",")) return
    e.preventDefault()
    this.addText(text)
  },

  // ---- changes ------------------------------------------------------------------------
  addText(text) {
    const parts = text.split(",").map((s) => s.trim()).filter(Boolean)
    if (!this.free()) return
    for (const p of parts) {
      const known = this.items().find((i) => norm(i.dataset.luLabel) === norm(p))
      this.add(known ? { value: known.dataset.luValue, label: known.dataset.luLabel } : { value: p, label: p }, true)
    }
    this.resetInput()
    this.commit()
  },

  add(tag, batch = false) {
    const max = this.max()
    if (this.tags.some((t) => t.value === tag.value)) return
    if (max && this.tags.length >= max) return
    this.tags = [...this.tags, tag]
    if (!batch) {
      this.resetInput()
      this.commit()
    }
  },

  removeTag(value) {
    this.tags = this.tags.filter((t) => t.value !== value)
    this.commit()
  },

  resetInput() {
    this.q = ""
    this.input().value = ""
  },

  commit() {
    this.dirty = true
    this.render()
    const s = this.hidden()
    ;(s || this.el).dispatchEvent(new Event("input", { bubbles: true }))
    if (!this.input().disabled) this.input().focus()
  },
}
