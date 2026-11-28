// LedgerUI.Select: listbox of <.select> and <.pillbox>.
//
// Opening, keyboard, search, chips and the `+N` overflow never leave the browser. The choice is
// submitted through the hidden <select> inside the root, which fires a bubbling `input` event.
//
// One rule for what is chosen (chip, `+N`, hidden <select>, `aria-selected`, the text of a single select):
//   * the `value` the server drew (`data-lu-value` on the root, which this hook never edits) changed since
//     the last patch: the server wins, and the browser draws what it drew;
//   * it did not change: the person's choice stays, whatever the patch redrew (a tick, a stream insert).
// A form reset gives back the value the server drew last.
//
// Server search (`data-lu-on-search`): the replies end the load-more wait (never a patch; only the latest
// push counts) and feed a per-text cache (20, LRU; off with `data-lu-cache="false"`): a text already
// searched shows its cached rows at once and is still sent (the reply wins); a text that extends the
// last answered one filters the rows on screen until the reply.
import {Lru, isClone, snapshot, dropClones, hasClones, showClones} from "../lib/search_cache.js"

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

const PATHS = {
  x: '<path d="M19.0005 4.99988L5.00049 18.9999M5.00049 4.99988L19.0005 18.9999"/>',
  check: '<path d="M5 14L8.5 17.5L19 6.5"/>',
}
// The utilities of the nodes drawn here come from the server (`data-lu-cls`, a JSON map).
const icon = (cls, name, extra = "") => {
  const t = document.createElement("template")
  t.innerHTML = `<svg class="${cls.icon} ${extra}" viewBox="0 0 24 24" aria-hidden="true" data-icon="${name}">${PATHS[name]}</svg>`
  return t.content.firstElementChild
}

const ITEM = '[data-part="listbox-option"][data-lu-value]'

// `hidden` loses to any `display` the stylesheet sets (the option rows, the chips...): set both.
// Only writes when the value changes: a pass over thousands of options must not touch the DOM for nothing.
const hide = (el, on, show = "") => {
  if (el.hidden !== on) el.hidden = on
  const d = on ? "none" : show
  if (el.style.display !== d) el.style.display = d
}

// The label of an option row: `data-lu-label` when the row has a custom `:option` slot (its text is more
// than the label), otherwise the row's own text nodes (the avatar, the count/hint and the check are elements).
const labelOf = (n) => {
  const l = n.dataset.luLabel
  if (l !== undefined) return l
  let t = ""
  for (const c of n.childNodes) if (c.nodeType === 3) t += c.data
  return t.trim()
}

// The normalised label of an option, kept per node (it only changes when the node's label does).
const NORMS = new WeakMap()
const normLabel = (n) => {
  const label = labelOf(n)
  const hit = NORMS.get(n)
  if (hit && hit.label === label) return hit.norm
  const norm_ = norm(label)
  NORMS.set(n, { label, norm: norm_ })
  return norm_
}

// A form reset reaches every select through one listener on `document` (not one per select), kept only
// while some select is mounted. The `pointerdown` that closes a list is added while that list is open.
const resetters = new Set()
const onResetAny = (e) => {
  for (const h of resetters) h.onReset(e)
}
const watchReset = (h) => {
  if (!resetters.size) document.addEventListener("reset", onResetAny)
  resetters.add(h)
}
const unwatchReset = (h) => {
  resetters.delete(h)
  if (!resetters.size) document.removeEventListener("reset", onResetAny)
}

export default {
  mounted() {
    this.isOpen = false
    this.q = ""
    this.active = null
    this.dirty = false
    this.pending = false
    this.moreSeq = 0
    this.seq = 0
    this.idSeq = 0
    this.soft = false
    this.view = false
    this.cache = new Lru(20)
    this.lastKey = null
    this.srv = this.serverKey()
    this.sel = this.readServer()

    this.onClick = (e) => this.click(e)
    this.onKey = (e) => this.key(e)
    this.onInput = (e) => this.typed(e)
    this.onDoc = (e) => {
      if (this.isOpen && !this.el.contains(e.target)) this.setOpen(false)
    }
    this.onReset = (e) => {
      if (e.target.contains && e.target.contains(this.el)) setTimeout(() => this.reset(), 0)
    }
    this.onReflow = () => this.isOpen && this.position()
    this.onScroll = () => this.more()

    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("keydown", this.onKey)
    this.el.addEventListener("input", this.onInput)
    watchReset(this)
    this.bound = this.pop()
    this.bound.addEventListener("scroll", this.onScroll)
    this.ro = new ResizeObserver(() => this.fit())
    this.boundCtrl = this.ctrl()
    this.ro.observe(this.boundCtrl)

    this.render()
  },

  updated() {
    this.invalidate()
    const key = this.serverKey()
    if (key !== this.srv) {
      // The server changed the value: it wins. `dirty` makes this render check the chips, the options
      // and the hidden <select> against it, since the patch may have left the browser's marks on them.
      this.srv = key
      this.sel = this.readServer()
      this.dirty = true
    }
    // The patch may have morphed the cached rows into the server's: nothing left to show then.
    if (this.view && !hasClones(this.list())) this.view = false
    // The listeners and the observer stay where `mounted` put them; they move only if a patch
    // replaced the panel or the control.
    const pop = this.pop()
    if (pop !== this.bound) {
      this.bound.removeEventListener("scroll", this.onScroll)
      pop.addEventListener("scroll", this.onScroll)
      this.bound = pop
    }
    const ctrl = this.ctrl()
    if (ctrl !== this.boundCtrl) {
      this.ro.unobserve(this.boundCtrl)
      this.ro.observe(ctrl)
      this.boundCtrl = ctrl
    }
    layer(this.pop(), this.isOpen)
    hide(this.pop(), !this.isOpen)
    this.expanded()
    // Open: a patch must not take the search box from the person (it came back `hidden`, and a hidden
    // field loses the focus). The focus is only given back when it was lost, not taken from another field.
    if (this.isOpen) this.showSearch()
    this.render()
    if (this.isOpen) {
      const qi = this.qInput()
      const a = document.activeElement
      if (qi && qi !== a && (!a || a === document.body || this.el.contains(a))) qi.focus()
      this.position()
      this.more()
    }
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("keydown", this.onKey)
    this.el.removeEventListener("input", this.onInput)
    document.removeEventListener("pointerdown", this.onDoc)
    unwatchReset(this)
    if (this.bound) this.bound.removeEventListener("scroll", this.onScroll)
    window.removeEventListener("resize", this.onReflow)
    window.removeEventListener("scroll", this.onReflow, true)
    clearTimeout(this.timer)
    this.ro && this.ro.disconnect()
  },

  // ---- parts -------------------------------------------------------------
  d() { return this.el.dataset },
  cls() { return (this._cls = this._cls || JSON.parse(this.d().luCls || "{}")) },
  ctrl() { return this.el.querySelector('[data-part="select-control"]') },
  pop() { return this.el.querySelector('[data-part="select-panel"]') },
  list() { return this.pop().querySelector("[data-lu-list]") },
  // The options, kept until a patch (or a created option) changes them: asking for them is free.
  items() {
    const list = this.list()
    if (!this._items || this._itemsList !== list) {
      this._items = [...list.querySelectorAll(ITEM)]
      this._itemsList = list
      this._byValue = null
    }
    return this._items
  },
  itemFor(value) {
    const items = this.items() // first: it drops the map when the list changed
    if (!this._byValue) {
      this._byValue = new Map()
      for (const i of items) if (!this._byValue.has(i.dataset.luValue)) this._byValue.set(i.dataset.luValue, i)
    }
    return this._byValue.get(value)
  },
  invalidate() {
    this._items = null
    this._byValue = null
    this._vis = null
  },
  hidden() { return this.el.querySelector(":scope > select[hidden]") },
  qInput() { return this.el.querySelector("input[data-lu-q]") },
  multiple() { return "luMultiple" in this.d() },
  chips() { return this.multiple() || "luPillbox" in this.d() },
  locked() { return "luDisabled" in this.d() || "luReadonly" in this.d() },
  // What the server drew as chosen, as a string to compare between patches: the root's `data-lu-value`.
  // A root without it (hand-written markup) is read from the nodes, as `readServer` does.
  serverKey() {
    const v = this.d().luValue
    return v !== undefined ? v : JSON.stringify(this.readServer())
  },
  readServer() {
    const v = this.d().luValue
    if (v !== undefined) {
      try { return JSON.parse(v) } catch (_) { /* fall back to the nodes */ }
    }
    const s = this.hidden()
    if (s) {
      return [...s.options]
        .filter((o) => o.value !== "")
        .map((o) => ({ value: o.value, label: o.textContent.trim() }))
    }
    return this.items()
      .filter((i) => i.getAttribute("aria-selected") === "true")
      .map((i) => ({ value: i.dataset.luValue, label: labelOf(i) }))
  },

  // A form reset puts the hidden <select> back to what the server rendered: so does the rest.
  reset() {
    this.sel = this.readServer()
    this.dirty = true
    this.render()
  },

  // ---- rendering -----------------------------------------------------------
  render() {
    this.renderControl()
    this.syncItems()
    this.syncSelect()
    this.filter()
    this.renderFooter()
    this.fit()
  },

  renderControl() {
    const ctrl = this.ctrl()
    if (!this.dirty) return
    if (this.chips()) {
      if (this.chipsMatch(ctrl)) return this.clearBtn()
      ctrl.querySelectorAll('[data-part="select-chip"], [data-part="select-more"]').forEach((n) => n.remove())
      ctrl.querySelectorAll('[data-part="select-value"][data-ph]').forEach((n) => n.remove())
      const ref = ctrl.querySelector('[data-part="select-value"], input[data-lu-q], [data-lu-clear], :scope > svg')
      for (const o of this.sel) ctrl.insertBefore(this.chip(o), ref)
      if (!this.sel.length && this.qInput()) {
        const ph = this.d().luPlaceholder
        if (ph) {
          const s = document.createElement("span")
          s.className = "min-w-0 flex-1 truncate text-sm text-muted"
          s.dataset.part = "select-value"
          s.setAttribute("data-ph", "")
          s.textContent = ph
          ctrl.insertBefore(s, this.qInput())
        }
      }
    } else {
      const val = ctrl.querySelector('[data-part="select-value"]')
      if (val) {
        val.textContent = this.sel.length ? this.sel[0].label : this.d().luPlaceholder || ""
        val.toggleAttribute("data-ph", !this.sel.length)
      }
    }
    this.clearBtn()
  },

  // Are the chips (and the placeholder) in the control already what `sel` asks for? Then they are kept:
  // taking them out and putting them back on every patch would cost a reflow for nothing.
  chipsMatch(ctrl) {
    const chips = ctrl.querySelectorAll('[data-part="select-chip"]')
    if (chips.length !== this.sel.length) return false
    for (let i = 0; i < chips.length; i++) {
      const c = chips[i]
      if (!c.isConnected || c.dataset.luValue !== this.sel[i].value) return false
      if (c.dataset.luLabel !== this.sel[i].label) return false
    }
    const ph = ctrl.querySelector('[data-part="select-value"][data-ph]')
    const wantPh = !this.sel.length && this.qInput() && this.d().luPlaceholder
    return !!ph === !!wantPh
  },

  clearBtn() {
    const ctrl = this.ctrl()
    const btn = ctrl.querySelector("[data-lu-clear]")
    if (btn) hide(btn, !this.sel.length, "inline-grid")
  },

  chip(o) {
    const c = document.createElement("span")
    c.className = this.cls().chip
    c.dataset.part = "select-chip"
    c.dataset.luValue = o.value
    c.dataset.luLabel = o.label
    const it = this.itemFor(o.value)
    const av = it && it.querySelector('[data-part="person-avatar"]')
    if (av) {
      const a = av.cloneNode(true)
      a.style.setProperty("--s", "22px")
      c.appendChild(a)
    }
    c.appendChild(document.createTextNode(o.label))
    if ("luRemovable" in this.d() && !this.locked()) {
      const b = document.createElement("button")
      b.type = "button"
      b.dataset.luRemove = o.value
      b.dataset.part = "select-chip-remove"
      b.className = this.cls().remove
      b.setAttribute("aria-label", `${this.d().luRemoveLabel || "Remove"} ${o.label}`)
      b.appendChild(icon(this.cls(), "x"))
      c.appendChild(b)
    }
    return c
  },

  syncItems() {
    const vals = new Set(this.sel.map((s) => s.value))
    const pillbox = "luPillbox" in this.d()
    for (const it of this.items()) {
      const on = vals.has(it.dataset.luValue)
      const cur = it.getAttribute("aria-selected") === "true"
      // An option that is not selected and was not drawn selected has nothing to draw (almost all of
      // them): no query, no write. The rest (the selected ones, the ones that changed) is drawn below.
      if (!on && !cur) {
        if (!it.hasAttribute("aria-selected")) it.setAttribute("aria-selected", "false")
        continue
      }
      if (cur !== on) it.setAttribute("aria-selected", String(on))
      if (!pillbox) {
        let r = it.querySelector(':scope > [data-part="listbox-option-right"]')
        let mark = r && r.querySelector("svg")
        if (on && !mark) {
          if (!r) {
            r = document.createElement("span")
            r.className = this.cls().right
            r.dataset.part = "listbox-option-right"
            it.appendChild(r)
          }
          r.appendChild(icon(this.cls(), "check", this.cls().ck))
        } else if (!on && mark) {
          mark.remove()
          if (r && !r.textContent.trim() && !r.children.length) r.remove()
        }
      }
    }
  },

  syncSelect() {
    const s = this.hidden()
    if (!s) return
    const same =
      JSON.stringify(
        [...s.options].filter((o) => o.value !== "").map((o) => o.value)
      ) === JSON.stringify(this.sel.map((x) => x.value))
    if (same) return
    s.querySelectorAll("option").forEach((o) => {
      if (o.value !== "") o.remove()
    })
    for (const o of this.sel) {
      const opt = document.createElement("option")
      opt.value = o.value
      opt.textContent = o.label
      opt.selected = true
      s.appendChild(opt)
    }
  },

  renderFooter() {
    const f = this.pop().querySelector("[data-lu-footer-count]")
    const tmpl = this.d().luFooterCount
    if (!f || !tmpl) return
    f.textContent = tmpl
      .replace("%{count}", this.sel.length)
      .replace("%{total}", this.items().length) // the cached list: no scan
  },

  // Folds the chips that do not fit into a `+N` chip (overflow "count" / "one").
  fit() {
    if (!this.chips() || this.d().luOverflow === "wrap") return
    const ctrl = this.ctrl()
    if (!ctrl.hasAttribute("data-one")) return
    let more = ctrl.querySelector('[data-part="select-more"]')
    const chips = [...ctrl.querySelectorAll('[data-part="select-chip"]')]
    chips.forEach((c) => {
      hide(c, false)
      c.style.flex = "none"
    })
    if (more) hide(more, true)
    const hid = []
    const over = () => ctrl.scrollWidth > ctrl.clientWidth + 1
    const vis = chips.slice()
    while (vis.length && over()) {
      if (!more) {
        more = document.createElement("span")
        more.className = this.cls().more
        more.dataset.part = "select-more"
        more.style.flex = "none"
        const ref = ctrl.querySelector('[data-part="select-value"], input[data-lu-q], [data-lu-clear], :scope > svg')
        ctrl.insertBefore(more, ref)
      }
      const c = vis.pop()
      hide(c, true)
      hid.unshift(c)
      hide(more, false)
      more.textContent = `+${hid.length}`
    }
    if (more && hid.length) {
      const names = hid.map((c) => c.textContent.trim()).join(", ")
      const t = this.d().luMoreLabel || "more"
      more.title = names
      more.setAttribute(
        "aria-label",
        t.includes("%{count}")
          ? t.replace("%{count}", hid.length)
          : `${hid.length} ${t}: ${names}`
      )
    } else if (more) {
      hide(more, true)
    }
  },

  // ---- filtering ------------------------------------------------------------
  filter() {
    const q = norm(this.q)
    const server = !!this.d().luOnSearch
    // Server rows are not filtered here, except while a text that extends the last answer waits for its reply.
    const local = !server || this.soft
    let shown = 0
    let group = null
    let groupShown = 0
    const flush = () => {
      if (group) hide(group, groupShown === 0)
    }
    for (const n of this.list().children) {
      // Cached rows and server rows never show together.
      const off = this.view !== isClone(n)
      if (n.dataset.part === "listbox-group") {
        flush()
        group = n
        groupShown = 0
        if (off) {
          hide(n, true)
          group = null
        }
      } else if (n.dataset.luValue !== undefined) {
        if (off) {
          hide(n, true)
          continue
        }
        const ok = !local || !q || normLabel(n).includes(q)
        hide(n, !ok)
        if (ok) {
          shown++
          groupShown++
        }
      }
    }
    flush()

    const create = this.pop().querySelector("[data-lu-create-row]")
    let showCreate = false
    if ("luCreate" in this.d() && this.q.trim()) {
      const want = norm(this.q.trim())
      const exact = this.items().some((i) => normLabel(i) === want)
      showCreate = !exact
    }
    if (create) {
      hide(create, !showCreate)
      if (showCreate) {
        const hint = this.d().luCreateHint
        create.textContent = ""
        if (hint) {
          const k = document.createElement("span")
          k.className = this.cls().right
          k.style.marginLeft = "0"
          k.textContent = hint
          create.appendChild(k)
        }
        create.appendChild(
          document.createTextNode(`${this.d().luCreateLabel || "Add"} “${this.q.trim()}”`)
        )
      }
    }
    const empty = this.pop().querySelector("[data-lu-empty]")
    if (empty) {
      const tmpl = this.d().luNoResults || "No results found"
      empty.textContent = tmpl.replace("%{query}", this.q)
      hide(empty, !(shown === 0 && !showCreate && !this.soft))
    }
    this._vis = null
    this.highlight(this.visible().find((i) => i.getAttribute("aria-selected") === "true") || this.visible()[0])
  },

  // The rows the arrows walk; kept until the next filter pass or patch (the only places that change it).
  visible() {
    if (this._vis) return this._vis
    const rows = this.items().filter((i) => !i.hidden && i.getAttribute("aria-disabled") !== "true")
    const create = this.pop().querySelector("[data-lu-create-row]")
    if (create && !create.hidden) rows.push(create)
    return (this._vis = rows)
  },

  highlight(item) {
    // The one that is lit is the one we lit (the server never draws `data-hl`).
    if (this.lit && this.lit !== item) this.lit.removeAttribute("data-hl")
    this.active = item || null
    this.lit = item || null
    if (item) {
      item.setAttribute("data-hl", "")
      item.scrollIntoView({ block: "nearest" })
    }
    this.describe()
  },

  // The id of a row (the server draws one on each; the cached copies and the created row have none yet),
  // what `aria-activedescendant` points at.
  idOf(item) {
    if (!item.id) item.id = `${this.pop().id || this.el.id + "-pop"}-x${++this.idSeq}`
    return item.id
  },

  // The field that has the focus while the list is open (the search box, or the control when there is
  // none) names the lit row with `aria-activedescendant`; the others, and the closed field, name none.
  describe() {
    const qi = this.qInput()
    const ctrl = this.ctrl()
    const focus = qi || ctrl
    for (const n of [qi, ctrl]) {
      if (!n) continue
      if (n === focus && this.isOpen && this.active) n.setAttribute("aria-activedescendant", this.idOf(this.active))
      else n.removeAttribute("aria-activedescendant")
    }
  },

  // `aria-expanded` on the control and on the search box (`role="combobox"`).
  expanded() {
    const v = String(this.isOpen)
    this.ctrl().setAttribute("aria-expanded", v)
    const qi = this.qInput()
    if (qi) qi.setAttribute("aria-expanded", v)
  },

  // ---- open / close ---------------------------------------------------------
  setOpen(open) {
    if (open === this.isOpen) return
    if (open && this.locked()) return
    this.isOpen = open
    const pop = this.pop()
    if (open) hide(pop, false)
    layer(pop, open)
    if (!open) hide(pop, true)
    this.expanded()
    const qi = this.qInput()
    const control = qi && qi.closest('[data-part="select-control"]')
    if (open) {
      this.clearQuery()
      this.position()
      follow(this.el, this.onReflow)
      window.addEventListener("resize", this.onReflow)
      window.addEventListener("scroll", this.onReflow, true)
      document.addEventListener("pointerdown", this.onDoc)
      this.filter()
      this.showSearch()
      if (qi) qi.focus()
      this.describe()
      this.more()
    } else {
      window.removeEventListener("resize", this.onReflow)
      window.removeEventListener("scroll", this.onReflow, true)
      document.removeEventListener("pointerdown", this.onDoc)
      this.clearQuery()
      this.describe()
      if (qi && control) hide(qi, true)
      const val = this.ctrl().querySelector('[data-part="select-value"]')
      if (val) hide(val, false)
    }
  },

  // The search box that lives in the control (a single select) takes the place of the value while the
  // list is open. A patch gives the server's `hidden` back to it: this is drawn again after one.
  showSearch() {
    const qi = this.qInput()
    if (!qi || !qi.closest('[data-part="select-control"]')) return
    hide(qi, false)
    const val = this.ctrl().querySelector('[data-part="select-value"]')
    if (val && !this.chips()) {
      const cur = this.sel[0] && this.sel[0].label
      qi.placeholder = cur || this.d().luPlaceholder || ""
      hide(val, true)
    }
  },

  position() {
    const pop = this.pop()
    const r = this.ctrl().getBoundingClientRect()
    const gap = 6
    pop.style.position = "fixed"
    pop.style.zIndex = "80"
    pop.style.margin = "0"
    pop.style.right = "auto"
    pop.style.color = "inherit" // the UA popover style sets CanvasText
    pop.style.boxSizing = "border-box"
    pop.style.overflowY = "auto"
    pop.style.left = r.left + "px"
    pop.style.width = Math.max(r.width, 0) + "px"
    const room = window.innerHeight - r.bottom - gap - 8
    const above = r.top - gap - 8
    const h = pop.scrollHeight + 2
    if (h > room && above > room) {
      pop.style.top = "auto"
      pop.style.bottom = window.innerHeight - r.top + gap + "px"
      pop.style.maxHeight = Math.min(above, 320) + "px"
    } else {
      pop.style.bottom = "auto"
      pop.style.top = r.bottom + gap + "px"
      pop.style.maxHeight = Math.min(Math.max(room, 120), 320) + "px"
    }
  },

  // ---- events ---------------------------------------------------------------
  click(e) {
    const t = e.target
    const rm = t.closest("[data-lu-remove]")
    if (rm && this.el.contains(rm)) {
      e.preventDefault()
      e.stopPropagation()
      this.remove(rm.dataset.luRemove)
      return
    }
    if (t.closest("[data-lu-clear]")) {
      e.preventDefault()
      e.stopPropagation()
      this.sel = []
      this.commit()
      return
    }
    const row = t.closest("[data-lu-create-row]")
    if (row && !row.hidden) return this.create()
    const item = t.closest(ITEM)
    if (item && this.pop().contains(item)) return this.choose(item)
    if (t.closest('[data-part="select-control"]') && !t.closest("input")) {
      this.setOpen(!this.isOpen)
    } else if (t.closest('[data-part="select-control"]')) {
      this.setOpen(true)
    }
  },

  key(e) {
    const inPop = this.pop().contains(e.target)
    const q = e.target.matches && e.target.matches("input[data-lu-q]")
    if (!this.isOpen) {
      if (!e.target.closest('[data-part="select-control"]') || this.locked()) return
      if (["ArrowDown", "ArrowUp", "Enter", " "].includes(e.key) && !q) {
        e.preventDefault()
        this.setOpen(true)
      } else if (e.key.length === 1 && !e.ctrlKey && !e.metaKey && this.qInput() && !this.chips()) {
        this.setOpen(true)
      } else if (e.key === "Backspace" && this.chips() && this.sel.length && !q) {
        this.removeLast()
      }
      return
    }
    const rows = this.visible()
    const i = rows.indexOf(this.active)
    switch (e.key) {
      case "ArrowDown":
        e.preventDefault()
        this.highlight(rows[Math.min(i + 1, rows.length - 1)] || rows[0])
        break
      case "ArrowUp":
        e.preventDefault()
        this.highlight(rows[Math.max(i - 1, 0)])
        break
      case "Home":
        if (!q || !this.q) {
          e.preventDefault()
          this.highlight(rows[0])
        }
        break
      case "End":
        if (!q || !this.q) {
          e.preventDefault()
          this.highlight(rows[rows.length - 1])
        }
        break
      case "Enter":
        e.preventDefault()
        if (this.active) {
          this.active.matches("[data-lu-create-row]") ? this.create() : this.choose(this.active)
        }
        break
      case " ":
        if (!q && !this.q) {
          e.preventDefault()
          if (this.active) this.choose(this.active)
        }
        break
      case "Escape":
        e.preventDefault()
        e.stopPropagation()
        this.setOpen(false)
        this.ctrl().focus()
        break
      case "Tab":
        this.setOpen(false)
        break
      case "Backspace":
        if (this.chips() && !this.q && this.sel.length) {
          e.preventDefault()
          this.removeLast()
        }
        break
    }
    void inPop
  },

  typed(e) {
    if (!e.target.matches || !e.target.matches("input[data-lu-q]")) return
    e.stopPropagation()
    this.q = e.target.value
    this.filter()
    const ev = this.d().luOnSearch
    if (ev) {
      clearTimeout(this.timer)
      this.search(ev, this.q, parseInt(this.d().luDebounce || "300", 10))
    }
  },

  cacheOn() { return this.d().luCache !== "false" },

  // Sends the search (after `wait` ms), with the cache around it. The reply callback is what ends the
  // local filter and stores the answer; only the latest search may do it.
  search(ev, text, wait) {
    const key = text.trim()
    const seq = ++this.seq
    // A new list is coming: a load-more still in flight is obsolete.
    this.moreSeq++
    this.pending = false
    const hit = this.cacheOn() && this.cache.get(key)
    if (hit) {
      showClones(this.list(), hit)
      this.view = true
      this.soft = false
      this.lastKey = key
      this.invalidate()
    } else {
      this.soft = this.cacheOn() && !!this.lastKey && key.startsWith(this.lastKey)
    }
    this.filter()
    const done = () => {
      if (seq !== this.seq) return
      this.soft = false
      this.view = false
      dropClones(this.list())
      this.invalidate()
      if (this.cacheOn()) {
        this.cache.set(key, snapshot(this.list()))
        this.lastKey = key
      }
      this.filter()
    }
    const send = () => this.push(ev, { id: this.el.id, query: text }, done)
    if (wait > 0) this.timer = setTimeout(send, wait)
    else send()
  },

  push(ev, payload, done) {
    let target = this.d().luTarget
    if (target && /^\d+$/.test(target)) target = parseInt(target, 10)
    target ? this.pushEventTo(target, ev, payload, done) : this.pushEvent(ev, payload, done)
  },

  more() {
    const ev = this.d().luOnLoadMore
    if (!ev || this.pending || this.view || !this.isOpen) return
    const pop = this.pop()
    if (pop.scrollHeight - pop.scrollTop - pop.clientHeight <= 48) {
      this.pending = true
      const seq = ++this.moreSeq
      // The reply (not a patch) ends the wait, even when the server changed nothing; then look again.
      this.push(ev, { id: this.el.id, query: this.q, offset: this.items().length }, () => {
        if (seq !== this.moreSeq) return
        this.pending = false
        this.more()
      })
    }
  },

  // ---- choosing ---------------------------------------------------------------
  choose(item) {
    if (item.getAttribute("aria-disabled") === "true") return
    const o = { value: item.dataset.luValue, label: labelOf(item) }
    const has = this.sel.some((s) => s.value === o.value)
    if (this.multiple()) {
      const max = parseInt(this.d().luMax || "0", 10)
      if (has) this.sel = this.sel.filter((s) => s.value !== o.value)
      else if (!max || this.sel.length < max) this.sel = [...this.sel, o]
      else return
      this.resetQuery()
    } else {
      this.sel = has && !("luPillbox" in this.d()) ? this.sel : [o]
      this.commit()
      this.setOpen(false)
      this.ctrl().focus()
      return
    }
    this.commit()
  },

  create() {
    const label = this.q.trim()
    if (!label) return
    const max = parseInt(this.d().luMax || "0", 10)
    if (this.multiple() && max && this.sel.length >= max) return
    let item = this.items().find((i) => normLabel(i) === norm(label))
    if (!item) {
      item = document.createElement("button")
      item.type = "button"
      item.setAttribute("role", "option")
      item.setAttribute("aria-selected", "false")
      item.dataset.part = "listbox-option"
      item.dataset.luValue = label
      item.dataset.luLabel = label
      item.dataset.luCreated = ""
      item.textContent = label
      this.list().appendChild(item)
      this.invalidate()
    }
    this.choose(item)
  },

  remove(value) {
    this.sel = this.sel.filter((s) => s.value !== value)
    if (this.d().luPersist === "false") {
      const it = this.items().find((i) => i.dataset.luValue === value && "luCreated" in i.dataset)
      if (it) {
        it.remove()
        this.invalidate()
      }
    }
    this.commit()
  },

  removeLast() {
    const last = this.sel[this.sel.length - 1]
    if (!last) return
    this.remove(last.value)
    if ("luRestore" in this.d() && this.qInput()) {
      this.q = last.label
      hide(this.qInput(), false)
      this.qInput().value = last.label
      this.filter()
    }
  },

  // Empties the search text. If there was text and the field has `on_search`, the server is told too
  // (`query: ""`, same payload and target as `typed`): otherwise the LiveView keeps the last search and
  // the next opening shows its results (#51). A debounced search still waiting is cancelled so its
  // answer cannot overwrite the default list.
  clearQuery() {
    const had = this.q !== ""
    this.q = ""
    const qi = this.qInput()
    if (qi) qi.value = ""
    if (!had) return
    clearTimeout(this.timer)
    const ev = this.d().luOnSearch
    if (ev) this.search(ev, "", 0)
  },

  resetQuery() {
    this.clearQuery()
    this.filter()
  },

  commit() {
    this.dirty = true
    this.render()
    const s = this.hidden()
    ;(s || this.el).dispatchEvent(new Event("input", { bubbles: true }))
    if (this.isOpen) this.position()
  },
}
