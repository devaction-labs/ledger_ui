// LedgerUI.Autocomplete: text input with suggestions (client filtering or server search).
//
// The choice is submitted through the hidden input (`[data-lu-v]`), which fires a bubbling `input`
// event. Leaving the field with text that is not an option puts the chosen label back; leaving
// it empty clears the value. With `data-lu-free` the typed text is the value.
//
// Server search (`data-lu-on-search`): the "searching" state ends on the reply of the push (only the
// latest search counts), never on a patch. The answers are cached per text (20, LRU; off with
// `data-lu-cache="false"`): a text already searched shows its cached rows at once and is still sent
// (the reply wins); a text that extends the last answered one filters the rows on screen meanwhile.
import {Lru, isClone, snapshot, dropClones, hasClones, showClones} from "../lib/search_cache.js"

const norm = (s) =>
  (s || "").normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase()

// `hidden` loses to any `display` the stylesheet sets (the option rows, the chips...): set both.
const hide = (el, on, show = "") => {
  el.hidden = on
  el.style.display = on ? "none" : show
}

export default {
  mounted() {
    this.isOpen = false
    this.active = null
    this.waiting = false
    this.soft = false
    this.view = false
    this.seq = 0
    this.cache = new Lru(20)
    this.lastKey = null
    this.q = ""
    this.onClick = (e) => this.click(e)
    this.onKey = (e) => this.key(e)
    this.onInput = (e) => this.typed(e)
    this.onFocusIn = (e) => this.focused(e)
    this.onFocusOut = (e) => this.blurred(e)
    this.onDoc = (e) => {
      if (this.isOpen && !this.el.contains(e.target)) this.close()
    }
    this.onReflow = () => this.isOpen && this.position()

    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("keydown", this.onKey)
    this.el.addEventListener("input", this.onInput)
    this.el.addEventListener("focusin", this.onFocusIn)
    this.el.addEventListener("focusout", this.onFocusOut)
    document.addEventListener("pointerdown", this.onDoc)
    this.label = this.input().value
    this.filter()
  },

  updated() {
    // The server answered a search (or re-rendered): adopt its value, keep what is typed.
    const v = this.hid()
    if (v && !("luFree" in this.d())) {
      const sel = this.items().find((i) => i.getAttribute("aria-selected") === "true")
      if (sel && document.activeElement !== this.input()) this.label = sel.dataset.luLabel
    }
    // The patch may have morphed the cached rows into the server's: nothing left to show then.
    if (this.view && !hasClones(this.list())) this.view = false
    hide(this.pop(), !this.isOpen)
    this.filter()
    if (this.isOpen) this.position()
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("keydown", this.onKey)
    this.el.removeEventListener("input", this.onInput)
    this.el.removeEventListener("focusin", this.onFocusIn)
    this.el.removeEventListener("focusout", this.onFocusOut)
    document.removeEventListener("pointerdown", this.onDoc)
    window.removeEventListener("resize", this.onReflow)
    window.removeEventListener("scroll", this.onReflow, true)
    clearTimeout(this.timer)
  },

  d() { return this.el.dataset },
  input() { return this.el.querySelector("input[data-lu-q]") },
  hid() { return this.el.querySelector("input[data-lu-v]") },
  pop() { return this.el.querySelector('[data-part="autocomplete-panel"]') },
  list() { return this.pop().querySelector("[data-lu-list]") },
  items() { return [...this.list().querySelectorAll('[data-part="listbox-option"][data-lu-value]')] },
  clearBtn() { return this.el.querySelector("[data-lu-clear]") },
  locked() { return "luDisabled" in this.d() },
  cacheOn() { return this.d().luCache !== "false" },

  // ---- open / close -----------------------------------------------------------
  open() {
    if (this.isOpen || this.locked()) return
    this.isOpen = true
    hide(this.pop(), false)
    this.input().setAttribute("aria-expanded", "true")
    this.position()
    window.addEventListener("resize", this.onReflow)
    window.addEventListener("scroll", this.onReflow, true)
    this.filter()
  },

  close() {
    if (!this.isOpen) return
    this.isOpen = false
    hide(this.pop(), true)
    this.input().setAttribute("aria-expanded", "false")
    window.removeEventListener("resize", this.onReflow)
    window.removeEventListener("scroll", this.onReflow, true)
  },

  position() {
    const pop = this.pop()
    const r = this.el.querySelector('[data-part="autocomplete-control"]').getBoundingClientRect()
    pop.style.position = "fixed"
    pop.style.zIndex = "80"
    pop.style.margin = "0"
    pop.style.boxSizing = "border-box"
    pop.style.overflowY = "auto"
    pop.style.left = r.left + "px"
    pop.style.width = r.width + "px"
    const room = window.innerHeight - r.bottom - 14
    const above = r.top - 14
    if (pop.scrollHeight > room && above > room) {
      pop.style.top = ""
      pop.style.bottom = window.innerHeight - r.top + 6 + "px"
      pop.style.maxHeight = Math.min(above, 320) + "px"
    } else {
      pop.style.bottom = ""
      pop.style.top = r.bottom + 6 + "px"
      pop.style.maxHeight = Math.min(Math.max(room, 120), 320) + "px"
    }
  },

  // ---- filtering ---------------------------------------------------------------
  filter() {
    const typed = this.input().value
    const q = norm(typed.trim())
    const server = !!this.d().luOnSearch
    // Showing the chosen label is not a query: show everything.
    const query = typed === this.label ? "" : q
    const busy = server && this.waiting
    // Waiting without a local filter hides the rows (and shows "Searching..."); `soft` (the text
    // extends the last answer) filters the rows on screen instead.
    const blocked = busy && !this.soft
    const local = !server || this.soft
    let shown = 0
    for (const it of this.items()) {
      const ok = !local || !query || norm(it.dataset.luLabel).includes(query)
      const off = this.view !== isClone(it)
      hide(it, !ok || blocked || off)
      if (ok && !blocked && !off) shown++
      this.mark(it, ok ? typed.trim() : "")
    }
    this.el.setAttribute("aria-busy", String(busy))
    const loading = this.pop().querySelector("[data-lu-loading]")
    if (loading) hide(loading, !blocked)
    const empty = this.pop().querySelector("[data-lu-empty]")
    const create = this.pop().querySelector("[data-lu-create-row]")
    const sep = this.pop().querySelector("[data-lu-create-sep]")
    const showCreate = !!(create && this.d().luCreate && typed.trim() && !busy)
    if (create) {
      hide(create, !showCreate)
      if (showCreate) create.textContent = this.d().luCreate.replace("%{query}", typed.trim())
    }
    if (sep) hide(sep, !showCreate)
    if (empty) {
      empty.textContent = (this.d().luNoResults || "No results found").replace("%{query}", typed)
      hide(empty, !(shown === 0 && !busy && !showCreate))
    }
    this.highlight(this.visible()[0])
  },

  // Bold the typed text in the label (plain labels only: a custom :option slot is left alone).
  mark(item, q) {
    const span = item.querySelector("[data-lu-lbl]")
    if (!span) return
    const label = item.dataset.luLabel
    const i = q ? norm(label).indexOf(norm(q)) : -1
    if (span.dataset.luM === `${i}:${q}`) return
    span.dataset.luM = `${i}:${q}`
    span.textContent = ""
    if (i < 0) return void span.appendChild(document.createTextNode(label))
    const b = document.createElement("b")
    b.textContent = label.slice(i, i + q.length)
    span.append(document.createTextNode(label.slice(0, i)), b, document.createTextNode(label.slice(i + q.length)))
  },

  visible() {
    const rows = this.items().filter((i) => !i.hidden && i.getAttribute("aria-disabled") !== "true")
    const create = this.pop().querySelector("[data-lu-create-row]")
    if (create && !create.hidden) rows.push(create)
    return rows
  },

  highlight(item) {
    this.pop().querySelectorAll("[data-hl]").forEach((n) => n.removeAttribute("data-hl"))
    this.active = item || null
    if (item) {
      item.setAttribute("data-hl", "")
      item.scrollIntoView({ block: "nearest" })
      this.input().setAttribute("aria-activedescendant", item.id || "")
    }
  },

  // ---- events ---------------------------------------------------------------------
  focused(e) {
    if (e.target === this.input() && "luOpenOnFocus" in this.d()) this.open()
  },

  blurred(e) {
    if (this.el.contains(e.relatedTarget)) return
    this.close()
    this.restore()
  },

  // Text that is not an option goes back to the chosen label; empty clears the value.
  restore() {
    if ("luFree" in this.d()) return
    const input = this.input()
    if (input.value.trim() === "" && this.hid() && this.hid().luValue !== "") {
      this.setValue("", "")
    } else if (input.value !== this.label) {
      input.value = this.label
    }
    this.filter()
  },

  click(e) {
    const t = e.target
    if (t.closest("[data-lu-clear]")) {
      e.preventDefault()
      this.setValue("", "")
      this.input().focus()
      return
    }
    const row = t.closest("[data-lu-create-row]")
    if (row && !row.hidden) return this.createRow()
    const item = t.closest('[data-part="listbox-option"][data-lu-value]')
    if (item && this.pop().contains(item)) return this.choose(item)
    if (t.closest('[data-part="autocomplete-control"]') && !this.locked()) {
      this.input().focus()
      this.open()
    }
  },

  key(e) {
    const rows = this.visible()
    const i = rows.indexOf(this.active)
    switch (e.key) {
      case "ArrowDown":
        e.preventDefault()
        this.open()
        this.highlight(rows[Math.min(i + 1, rows.length - 1)] || rows[0])
        break
      case "ArrowUp":
        e.preventDefault()
        this.open()
        this.highlight(rows[Math.max(i - 1, 0)])
        break
      case "Enter":
        if (this.isOpen && this.active) {
          e.preventDefault()
          this.active.matches("[data-lu-create-row]") ? this.createRow() : this.choose(this.active)
        }
        break
      case "Escape":
        if (this.isOpen) {
          e.preventDefault()
          e.stopPropagation()
          this.close()
          this.restore()
        }
        break
      case "Tab":
        this.close()
        break
    }
  },

  typed(e) {
    if (e.target !== this.input()) return
    e.stopPropagation()
    const text = e.target.value
    this.q = text
    if ("luFree" in this.d()) this.setValue(text, text, false)
    this.open()
    const ev = this.d().luOnSearch
    if (ev && text.trim().length >= parseInt(this.d().luThreshold || "0", 10)) {
      const key = text.trim()
      const seq = ++this.seq
      const hit = this.cacheOn() && this.cache.get(key)
      if (hit) {
        // Already searched: show that answer now and revalidate (the server's reply wins).
        showClones(this.list(), hit)
        this.view = true
        this.soft = false
        this.waiting = false
        this.lastKey = key
      } else {
        this.waiting = true
        this.soft = this.cacheOn() && !!this.lastKey && key.startsWith(this.lastKey)
      }
      // The push reply ends the searching state even when the DOM does not change
      // (same options, or an error); only the latest search may clear it.
      const done = () => {
        if (seq !== this.seq) return
        this.waiting = false
        this.soft = false
        this.view = false
        dropClones(this.list())
        if (this.cacheOn()) {
          this.cache.set(key, snapshot(this.list()))
          this.lastKey = key
        }
        this.filter()
      }
      clearTimeout(this.timer)
      this.timer = setTimeout(
        () => this.push(ev, { id: this.el.id, query: text }, done),
        parseInt(this.d().luDebounce || "300", 10)
      )
    }
    this.filter()
    const c = this.clearBtn()
    if (c) hide(c, text === "", "inline-grid")
  },

  push(ev, payload, done) {
    let target = this.d().luTarget
    if (target && /^\d+$/.test(target)) target = parseInt(target, 10)
    target ? this.pushEventTo(target, ev, payload, done) : this.pushEvent(ev, payload, done)
  },

  choose(item) {
    if (item.getAttribute("aria-disabled") === "true") return
    this.setValue(item.dataset.luValue, item.dataset.luLabel)
    this.close()
    this.input().focus()
  },

  createRow() {
    const query = this.input().value.trim()
    const on = this.d().luOnCreate
    this.close()
    if (!on) return
    if (on.startsWith("[")) {
      this.js ? this.js().exec(on) : this.liveSocket.execJS(this.el, on)
    } else {
      this.push(on, { id: this.el.id, query })
    }
  },

  setValue(value, label, setText = true) {
    this.label = label
    if (setText) this.input().value = label
    const h = this.hid()
    this.items().forEach((i) => i.setAttribute("aria-selected", String(i.dataset.luValue === value)))
    const c = this.clearBtn()
    if (c) hide(c, label === "", "inline-grid")
    if (h) {
      if (h.value === value) return
      h.value = value
      h.dispatchEvent(new Event("input", { bubbles: true }))
    } else {
      this.el.dispatchEvent(new Event("input", { bubbles: true }))
    }
  },
}
