// LedgerUI.Select: listbox of <.select> and <.pillbox>.
//
// Opening, keyboard, search, chips and the `+N` overflow never leave the browser. The choice is
// submitted through the hidden <select> inside the root, which fires a bubbling `input` event.
// A value rendered by the server wins over the one in the browser; a patch that does not change
// it leaves the person's choice alone.

const norm = (s) =>
  (s || "").normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase()

const PATHS = {
  x: '<path d="M19.0005 4.99988L5.00049 18.9999M5.00049 4.99988L19.0005 18.9999"/>',
  check: '<path d="M5 14L8.5 17.5L19 6.5"/>',
}
const icon = (name, cls = "") => {
  const t = document.createElement("template")
  t.innerHTML = `<svg class="lu-i sm ${cls}" viewBox="0 0 24 24" aria-hidden="true" data-icon="${name}">${PATHS[name]}</svg>`
  return t.content.firstElementChild
}

const RM_STYLE =
  "border:0;background:none;padding:0;display:inline-grid;cursor:pointer;color:inherit"

// `hidden` loses to any `display` the stylesheet sets (.lu-menu-item, .lu-chip...): set both.
const hide = (el, on, show = "") => {
  el.hidden = on
  el.style.display = on ? "none" : show
}

export default {
  mounted() {
    this.isOpen = false
    this.q = ""
    this.active = null
    this.dirty = false
    this.pending = false
    this.srv = JSON.stringify(this.readServer())
    this.sel = this.readServer()

    this.onClick = (e) => this.click(e)
    this.onKey = (e) => this.key(e)
    this.onInput = (e) => this.typed(e)
    this.onDoc = (e) => {
      if (this.isOpen && !this.el.contains(e.target)) this.setOpen(false)
    }
    this.onReflow = () => this.isOpen && this.position()
    this.onScroll = () => this.more()

    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("keydown", this.onKey)
    this.el.addEventListener("input", this.onInput)
    document.addEventListener("pointerdown", this.onDoc)
    this.pop().addEventListener("scroll", this.onScroll)
    this.ro = new ResizeObserver(() => this.fit())
    this.ro.observe(this.ctrl())

    this.render()
  },

  updated() {
    const sv = this.readServer()
    const json = JSON.stringify(sv)
    if (json !== this.srv) {
      this.srv = json
      this.sel = sv
      this.dirty = false
    }
    this.pending = false
    this.pop().removeEventListener("scroll", this.onScroll)
    this.pop().addEventListener("scroll", this.onScroll)
    hide(this.pop(), !this.isOpen)
    this.ctrl().setAttribute("aria-expanded", String(this.isOpen))
    this.render()
    if (this.isOpen) {
      this.position()
      this.more()
    }
  },

  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("keydown", this.onKey)
    this.el.removeEventListener("input", this.onInput)
    document.removeEventListener("pointerdown", this.onDoc)
    window.removeEventListener("resize", this.onReflow)
    window.removeEventListener("scroll", this.onReflow, true)
    clearTimeout(this.timer)
    this.ro && this.ro.disconnect()
  },

  // ---- parts -------------------------------------------------------------
  d() { return this.el.dataset },
  ctrl() { return this.el.querySelector('[data-part="control"]') },
  pop() { return this.el.querySelector('[data-part="panel"]') },
  list() { return this.pop().querySelector("[data-lu-list]") },
  items() { return [...this.list().querySelectorAll(".lu-menu-item[data-lu-value]")] },
  hidden() { return this.el.querySelector(":scope > select[hidden]") },
  qInput() { return this.el.querySelector("input[data-lu-q]") },
  multiple() { return "luMultiple" in this.d() },
  chips() { return this.multiple() || "luPillbox" in this.d() },
  locked() { return "luDisabled" in this.d() || "luReadonly" in this.d() },
  readServer() {
    const s = this.hidden()
    if (s) {
      return [...s.options]
        .filter((o) => o.value !== "")
        .map((o) => ({ value: o.value, label: o.textContent.trim() }))
    }
    return this.items()
      .filter((i) => i.classList.contains("sel"))
      .map((i) => ({ value: i.dataset.luValue, label: i.dataset.luLabel }))
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
      ctrl.querySelectorAll(".lu-chip, .more").forEach((n) => n.remove())
      ctrl.querySelectorAll(".val.ph").forEach((n) => n.remove())
      const ref = ctrl.querySelector(".val, input[data-lu-q], [data-lu-clear], :scope > svg")
      for (const o of this.sel) ctrl.insertBefore(this.chip(o), ref)
      if (!this.sel.length && this.qInput()) {
        const ph = this.d().luPlaceholder
        if (ph) {
          const s = document.createElement("span")
          s.className = "val ph"
          s.textContent = ph
          ctrl.insertBefore(s, this.qInput())
        }
      }
    } else {
      const val = ctrl.querySelector(".val")
      if (val) {
        val.textContent = this.sel.length ? this.sel[0].label : this.d().luPlaceholder || ""
        val.classList.toggle("ph", !this.sel.length)
      }
    }
    this.clearBtn()
  },

  clearBtn() {
    const ctrl = this.ctrl()
    const btn = ctrl.querySelector("[data-lu-clear]")
    if (btn) hide(btn, !this.sel.length, "inline-grid")
  },

  chip(o) {
    const c = document.createElement("span")
    c.className = "lu-chip"
    c.style.height = "24px"
    c.dataset.luValue = o.value
    const it = this.items().find((i) => i.dataset.luValue === o.value)
    const av = it && it.querySelector(".lu-av")
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
      b.setAttribute("style", RM_STYLE)
      b.setAttribute("aria-label", `${this.d().luRemoveLabel || "Remove"} ${o.label}`)
      b.appendChild(icon("x"))
      c.appendChild(b)
    }
    return c
  },

  syncItems() {
    const vals = new Set(this.sel.map((s) => s.value))
        const pillbox = "luPillbox" in this.d()
    for (const it of this.items()) {
      const on = vals.has(it.dataset.luValue)
      it.classList.toggle("sel", on)
      it.setAttribute("aria-selected", String(on))
      const box = it.querySelector(".lu-check input")
      if (box) box.checked = on
      if (!pillbox) {
        let r = it.querySelector(":scope > .r")
        let mark = r && r.querySelector(".ck")
        if (on && !mark) {
          if (!r) {
            r = document.createElement("span")
            r.className = "r"
            it.appendChild(r)
          }
          r.appendChild(icon("check", "ck"))
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
      .replace("%{total}", this.items().length)
  },

  // Folds the chips that do not fit into a `+N` chip (overflow "count" / "one").
  fit() {
    if (!this.chips() || this.d().luOverflow === "wrap") return
    const ctrl = this.ctrl()
    if (!ctrl.classList.contains("one")) return
    let more = ctrl.querySelector(".more")
    const chips = [...ctrl.querySelectorAll(".lu-chip")]
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
        more.className = "more"
        more.style.flex = "none"
        const ref = ctrl.querySelector(".val, input[data-lu-q], [data-lu-clear], :scope > svg")
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
    let shown = 0
    let group = null
    let groupShown = 0
    const flush = () => {
      if (group) hide(group, groupShown === 0)
    }
    for (const n of this.list().children) {
      if (n.classList.contains("lu-menu-label")) {
        flush()
        group = n
        groupShown = 0
      } else if (n.dataset.luValue !== undefined) {
        const ok = server || !q || norm(n.dataset.luLabel).includes(q)
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
      const exact = this.items().some((i) => norm(i.dataset.luLabel) === norm(this.q.trim()))
      showCreate = !exact
    }
    if (create) {
      hide(create, !showCreate)
      if (showCreate) {
        const hint = this.d().luCreateHint
        create.textContent = ""
        if (hint) {
          const k = document.createElement("span")
          k.className = "r"
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
      hide(empty, !(shown === 0 && !showCreate))
    }
    this.highlight(this.visible().find((i) => i.classList.contains("sel")) || this.visible()[0])
  },

  visible() {
    const rows = this.items().filter((i) => !i.hidden && i.getAttribute("aria-disabled") !== "true")
    const create = this.pop().querySelector("[data-lu-create-row]")
    if (create && !create.hidden) rows.push(create)
    return rows
  },

  highlight(item) {
    this.pop()
      .querySelectorAll(".hl")
      .forEach((n) => n.classList.remove("hl"))
    this.active = item || null
    if (item) {
      item.classList.add("hl")
      item.scrollIntoView({ block: "nearest" })
    }
  },

  // ---- open / close ---------------------------------------------------------
  setOpen(open) {
    if (open === this.isOpen) return
    if (open && this.locked()) return
    this.isOpen = open
    const pop = this.pop()
    hide(pop, !open)
    this.ctrl().setAttribute("aria-expanded", String(open))
    const qi = this.qInput()
    const control = qi && qi.closest('[data-part="control"]')
    if (open) {
      this.q = ""
      if (qi) qi.value = ""
      this.position()
      window.addEventListener("resize", this.onReflow)
      window.addEventListener("scroll", this.onReflow, true)
      this.filter()
      if (control) {
        hide(qi, false)
        const val = this.ctrl().querySelector(".val")
        if (val && !this.chips()) {
          const cur = this.sel[0] && this.sel[0].label
          qi.placeholder = cur || this.d().luPlaceholder || ""
          hide(val, true)
        }
      }
      if (qi) qi.focus()
      this.more()
    } else {
      window.removeEventListener("resize", this.onReflow)
      window.removeEventListener("scroll", this.onReflow, true)
      this.q = ""
      if (qi) {
        qi.value = ""
        if (control) hide(qi, true)
      }
      const val = this.ctrl().querySelector(".val")
      if (val) hide(val, false)
    }
  },

  position() {
    const pop = this.pop()
    const r = this.ctrl().getBoundingClientRect()
    const gap = 6
    pop.style.position = "fixed"
    pop.style.zIndex = "80"
    pop.style.margin = "0"
    pop.style.boxSizing = "border-box"
    pop.style.overflowY = "auto"
    pop.style.left = r.left + "px"
    pop.style.width = Math.max(r.width, 0) + "px"
    const room = window.innerHeight - r.bottom - gap - 8
    const above = r.top - gap - 8
    const h = pop.scrollHeight + 2
    if (h > room && above > room) {
      pop.style.top = ""
      pop.style.bottom = window.innerHeight - r.top + gap + "px"
      pop.style.maxHeight = Math.min(above, 320) + "px"
    } else {
      pop.style.bottom = ""
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
    const item = t.closest(".lu-menu-item[data-lu-value]")
    if (item && this.pop().contains(item)) return this.choose(item)
    if (t.closest('[data-part="control"]') && !t.closest("input")) {
      this.setOpen(!this.isOpen)
    } else if (t.closest('[data-part="control"]')) {
      this.setOpen(true)
    }
  },

  key(e) {
    const inPop = this.pop().contains(e.target)
    const q = e.target.matches && e.target.matches("input[data-lu-q]")
    if (!this.isOpen) {
      if (!e.target.closest('[data-part="control"]') || this.locked()) return
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
      this.timer = setTimeout(() => this.push(ev, { id: this.el.id, query: this.q }),
        parseInt(this.d().luDebounce || "300", 10))
    }
  },

  push(ev, payload) {
    let target = this.d().luTarget
    if (target && /^\d+$/.test(target)) target = parseInt(target, 10)
    target ? this.pushEventTo(target, ev, payload) : this.pushEvent(ev, payload)
  },

  more() {
    const ev = this.d().luOnLoadMore
    if (!ev || this.pending || !this.isOpen) return
    const pop = this.pop()
    if (pop.scrollHeight - pop.scrollTop - pop.clientHeight <= 48) {
      this.pending = true
      this.push(ev, { id: this.el.id, query: this.q, offset: this.items().length })
    }
  },

  // ---- choosing ---------------------------------------------------------------
  choose(item) {
    if (item.getAttribute("aria-disabled") === "true") return
    const o = { value: item.dataset.luValue, label: item.dataset.luLabel }
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
    let item = this.items().find((i) => norm(i.dataset.luLabel) === norm(label))
    if (!item) {
      item = document.createElement("button")
      item.type = "button"
      item.setAttribute("role", "menuitem")
      item.className = "lu-menu-item"
      item.dataset.luValue = label
      item.dataset.luLabel = label
      item.dataset.luCreated = ""
      item.textContent = label
      this.list().appendChild(item)
    }
    this.choose(item)
  },

  remove(value) {
    this.sel = this.sel.filter((s) => s.value !== value)
    if (this.d().luPersist === "false") {
      const it = this.items().find((i) => i.dataset.luValue === value && "luCreated" in i.dataset)
      if (it) it.remove()
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

  resetQuery() {
    this.q = ""
    const qi = this.qInput()
    if (qi) qi.value = ""
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
