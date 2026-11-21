// LedgerUI.Toaster: draws the toasts of `<.toaster>` (flash, `send_toast/3` pushes and the
// `show_toast/2` JS command), stacks them, counts their time and handles actions.
//
// Wire: the server pushes `ledger:toast` events (`{op: "show" | "update" | "dismiss" | "clear", ...}`),
// `show_toast/2` dispatches the same event on the toaster element, and the flash arrives as a JSON
// list in `data-lu-flash`. `toast:show`, `toast:update` and `toast:dismiss` (push_event or DOM event)
// are the same ops under the names an app may already push. Client-owned DOM: the stack
// (`[data-part=toast-stack]`) is `phx-update="ignore"`.
//
// Two formats: the status pill (compact, one action, `**object**` in bold, progress in %, 5 s, 8 s
// with an action) and the card (description, actions, progress, steps; an error or a warning stays
// with `persist_errors`). `kind: "status" | "card"` picks one; otherwise a description, an aura,
// steps or more than one action make a card. Per stack, `max_visible` toasts are in view and the
// rest wait in a queue; the same `id` updates the toast instead of adding another.
//
// Styling: the toasts are drawn with Tailwind utilities. The class strings come from the server
// (`LedgerUI.Components.Toast.hook_classes/0`, JSON in `data-lu-cls`), so the cards drawn here and the
// ones `toast_card/1` renders in the page are the same, and the stylesheet generator sees every class.

const ICONS = {
  "check-circle": "<path d=\"M22 12C22 6.47715 17.5228 2 12 2C6.47715 2 2 6.47715 2 12C2 17.5228 6.47715 22 12 22C17.5228 22 22 17.5228 22 12Z\"/><path d=\"M8 12.5L10.5 15L16 9\"/>",
  "x-circle": "<path d=\"M14.9994 15L9 9M9.00064 15L15 9\"/><path d=\"M22 12C22 6.47715 17.5228 2 12 2C6.47715 2 2 6.47715 2 12C2 17.5228 6.47715 22 12 22C17.5228 22 22 17.5228 22 12Z\"/>",
  "alert": "<path d=\"M5.32171 9.6829C7.73539 5.41196 8.94222 3.27648 10.5983 2.72678C11.5093 2.42437 12.4907 2.42437 13.4017 2.72678C15.0578 3.27648 16.2646 5.41196 18.6783 9.6829C21.092 13.9538 22.2988 16.0893 21.9368 17.8293C21.7376 18.7866 21.2469 19.6548 20.535 20.3097C19.241 21.5 16.8274 21.5 12 21.5C7.17265 21.5 4.75897 21.5 3.46496 20.3097C2.75308 19.6548 2.26239 18.7866 2.06322 17.8293C1.70119 16.0893 2.90803 13.9538 5.32171 9.6829Z\"/><path d=\"M11.992 16H12.001\"/><path d=\"M12 13L12 8.99997\"/>",
  "info": "<path d=\"M22 12C22 6.47715 17.5228 2 12 2C6.47715 2 2 6.47715 2 12C2 17.5228 6.47715 22 12 22C17.5228 22 22 17.5228 22 12Z\"/><path d=\"M12.2422 17V12C12.2422 11.5286 12.2422 11.2929 12.0957 11.1464C11.9493 11 11.7136 11 11.2422 11\"/><path d=\"M11.992 8H12.001\"/>",
  "x": "<path d=\"M19.0005 4.99988L5.00049 18.9999M5.00049 4.99988L19.0005 18.9999\"/>",
  "check": "<path d=\"M5 14L8.5 17.5L19 6.5\"/>"
}

const icon = (C, name, size) =>
  `<svg class="${C.icon} ${size === "sm" ? C.icon_sm : C.icon_md}" viewBox="0 0 24 24" aria-hidden="true" data-icon="${name}">${ICONS[name] || ""}</svg>`

const esc = (s) =>
  String(s == null ? "" : s).replace(/[&<>"']/g, (c) => ({"&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"})[c])

// `**name**` highlights a name; everything else is escaped.
const rich = (s) => esc(s).replace(/\*\*(.+?)\*\*/g, "<b>$1</b>")

// kind => [colour name (a key of `cls.colors`), icon]
const KINDS = {
  neutral: ["neutral", "info"],
  info: ["info", "info"],
  success: ["success", "check-circle"],
  warning: ["warning", "alert"],
  error: ["error", "x-circle"],
  loading: ["primary", null],
}
const COLORS = {primary: "primary", secondary: "secondary", info: "info", success: "success", warning: "warning", error: "error", neutral: "neutral", light: "neutral", dark: "neutral"}
const AURA_TONES = {assistant: "ai", primary: "accent", secondary: "violet", info: "info", success: "pos", warning: "warn", error: "neg"}
const AURA_MODES = {true: "spin", default: "spin", spin: "spin", dual: "dual", glow: "glow"}
const STATUS_OF = {success: "ok", info: "ok", neutral: "ok", error: "err", warning: "warn", loading: "run"}
const POSITIONS = {
  "left-top": "left:16px;right:auto;top:16px;bottom:auto;transform:none;align-items:flex-start;flex-direction:column",
  "center-top": "left:50%;right:auto;top:16px;bottom:auto;transform:translateX(-50%);align-items:center;flex-direction:column",
  "right-top": "right:16px;left:auto;top:16px;bottom:auto;transform:none;align-items:flex-end;flex-direction:column",
  "left-bottom": "left:16px;right:auto;bottom:16px;top:auto;transform:none;align-items:flex-start;flex-direction:column-reverse",
  "center-bottom": "left:50%;right:auto;bottom:16px;top:auto;transform:translateX(-50%);align-items:center;flex-direction:column-reverse",
  "right-bottom": "right:16px;left:auto;bottom:16px;top:auto;transform:none;align-items:flex-end;flex-direction:column-reverse",
}

const INF = Infinity
const FORMATS = {status: true, card: true}
const MAX_STACKED = 3 // the blades of a stack: the CSS shows three
const ACTION_MS = 8000
const LIVE = ["show", "update", "dismiss"]

// The kind that names a colour: `kind` is a format ("status", "card") or a colour kind; `color` then names it.
const colorKind = (d) => (FORMATS[d.kind] ? (d.color && KINDS[d.color] ? d.color : "neutral") : d.kind || "neutral")
const actionsOf = (d) => d.actions || []
const busy = (d) => d.kind === "loading" || d.status === "run" || d.status === "queue"
const inCourse = (d) => busy(d) || (d.value != null && d.value < 100) || !!(d.steps && d.step < d.steps)
const clamp = (v) => Math.max(0, Math.min(100, Number(v)))

export default {
  mounted() {
    this.cls = this.loadClasses()
    this.toasts = new Map()
    this.seen = new Set()
    this.stacks = new Map()
    this.pending = new Map()
    this.paused = false
    this.watched = new Set()
    this.onEvent = (e) => this.handle(e.detail || {})
    this.el.addEventListener("ledger:toast", this.onEvent)
    this.handleEvent("ledger:toast", (p) => this.handle(p))
    this.aliases = LIVE.map((op) => [`toast:${op}`, (e) => this.handle(Object.assign({}, e.detail, {op}))])
    this.aliases.forEach(([name, fn]) => this.el.addEventListener(name, fn))
    LIVE.forEach((op) => this.handleEvent(`toast:${op}`, (p) => this.handle(Object.assign({}, p, {op}))))
    this.onEnter = () => this.pause(true)
    this.onLeave = () => this.pause(false)
    this.watch(this.stack())
    this.flash()
  },

  updated() {
    this.cls = this.loadClasses()
    this.flash()
  },

  loadClasses() {
    try { return JSON.parse(this.el.dataset.luCls || "{}") } catch (_) { return {} }
  },

  stack() {
    return this.el.querySelector(":scope > [data-part=toast-stack]")
  },

  destroyed() {
    this.el.removeEventListener("ledger:toast", this.onEvent)
    this.aliases.forEach(([name, fn]) => this.el.removeEventListener(name, fn))
    this.pending.clear()
    this.watched.forEach((st) => {
      st.removeEventListener("mouseenter", this.onEnter)
      st.removeEventListener("mouseleave", this.onLeave)
    })
    this.toasts.forEach((t) => t.anim && t.anim.cancel())
    this.toasts.clear()
  },

  // The pointer over a stack holds the timers of every toast.
  watch(st) {
    if (!st || this.watched.has(st)) return
    this.watched.add(st)
    st.addEventListener("mouseenter", this.onEnter)
    st.addEventListener("mouseleave", this.onLeave)
  },

  cfg() {
    const d = this.el.dataset
    return {
      duration: d.luDuration ? Number(d.luDuration) : 5000,
      stack: d.luStack !== "false",
      timer: d.luTimer !== "false",
      invert: d.luInvert === "true",
      persistErrors: d.luPersistErrors === "true",
      closeLabel: d.luCloseLabel || "Close",
      loadingLabel: d.luLoadingLabel || "Loading",
      position: d.pos || "center-bottom",
      statusPosition: d.luStatusPosition || null,
      cardPosition: d.luCardPosition || null,
      maxVisible: d.luMaxVisible ? Number(d.luMaxVisible) : MAX_STACKED,
    }
  },

  // Flash toasts: `data-flash` is a JSON list; each key is shown once while it stays in the flash.
  flash() {
    let list = []
    try { list = JSON.parse(this.el.dataset.luFlash || "[]") } catch (_) { list = [] }
    const keys = new Set()
    list.forEach((t) => {
      const key = t._k || t.id || t.title
      keys.add(key)
      if (!this.seen.has(key)) this.show(t)
    })
    this.seen = keys
  },

  handle(p) {
    switch (p.op || "show") {
      case "show": return this.show(p)
      case "update": return this.update(p.id, p)
      case "dismiss": return this.dismiss(p.id)
      case "clear":
        this.pending.clear()
        return Array.from(this.toasts.keys()).forEach((id) => this.dismiss(id))
    }
  },

  // `progress` is `value` under the name apps use; `message` is the title.
  prep(d) {
    if (d.value == null && d.progress != null) d.value = d.progress
    delete d.progress
    delete d.op
    delete d.replace
    if (d.title == null && d.message != null) d.title = d.message
    return d
  },

  show(data) {
    data = this.prep(Object.assign({}, data))
    if (!data.id) data.id = "t" + Math.random().toString(36).slice(2, 9)
    this.render(data)
    return data.id
  },

  // `replace: true` swaps the whole toast (its timer starts again); otherwise only the given options change.
  update(id, changes) {
    const cur = this.toasts.get(id)
    const wait = this.pending.get(id)
    const base = cur ? cur.data : wait ? wait.data : null
    if (!base) return this.show(Object.assign({}, changes, {id}))
    const next = this.prep(changes.replace ? Object.assign({}, changes, {id}) : Object.assign({}, base, changes))
    if (!changes.replace && changes.message != null && changes.title == null) next.title = changes.message
    if (wait) wait.data = next
    else this.render(next)
  },

  // Where a toast goes: its own `position`, else the one of its format, else the toaster's.
  positionOf(d, fmt, cfg) {
    return d.position || (fmt === "card" ? cfg.cardPosition : fmt === "status" ? cfg.statusPosition : null) || cfg.position
  },

  limit(cfg) {
    return Math.max(1, cfg.stack ? Math.min(cfg.maxVisible, MAX_STACKED) : cfg.maxVisible)
  },

  inView(st) {
    let n = 0
    this.toasts.forEach((t) => { if (t.stack === st) n++ })
    return n
  },

  // A place frees up: the first of the queue that goes to this stack comes in.
  drain(st) {
    const cfg = this.cfg()
    for (const [id, w] of Array.from(this.pending)) {
      if (this.inView(st) >= this.limit(cfg)) return
      if (w.stack !== st) continue
      this.pending.delete(id)
      this.render(w.data)
    }
  },

  stackFor(pos) {
    const base = this.stack()
    const cfg = this.cfg()
    if (!pos || pos === cfg.position || !POSITIONS[pos]) return base
    let st = this.stacks.get(pos)
    if (!st || !st.isConnected) {
      const S = this.cls.stack || {}
      st = document.createElement("div")
      st.dataset.part = "toast-stack"
      st.className = [S.kids, pos.endsWith("top") ? S.top : S.bottom].join(" ")
      st.dataset.pos = pos
      st.style.cssText = "position:absolute;display:flex;gap:8px;" + POSITIONS[pos] + (this.fixed() ? ";pointer-events:none" : "")
      this.el.appendChild(st)
      this.stacks.set(pos, st)
      this.watch(st)
    }
    return st
  },

  fixed() { return getComputedStyle(this.el).position === "fixed" },

  format(d) {
    if (d.template) return "template"
    if (FORMATS[d.kind]) return d.kind
    if (d.status) return "status"
    const plain = !d.description && !d.aura && d.value == null && !d.steps && actionsOf(d).length < 2
    return plain && STATUS_OF[colorKind(d)] ? "status" : "card"
  },

  // How the pill reads: filling or queue ring while it works, then a dot.
  pillStatus(d) {
    if (d.status) return d.status
    const k = STATUS_OF[colorKind(d)]
    if (k === "err" || k === "warn") return k
    return inCourse(d) ? "run" : k || "ok"
  },

  durationOf(d, cfg, fmt) {
    const done = (d.value != null && d.value >= 100) || (d.steps && d.step >= d.steps)
    if (d.duration != null) return d.duration === "infinity" || d.duration === 0 || d.duration === "0" ? INF : Number(d.duration)
    if (done) return 1600
    const k = colorKind(d)
    const sticky =
      d.template || d.aura === "glow" || inCourse(d) ||
      (fmt === "card" && actionsOf(d).length > 0) ||
      (cfg.persistErrors && (fmt === "card" ? k === "error" || k === "warning" : d.kind === "error"))
    if (sticky) return INF
    return fmt === "status" && actionsOf(d).length > 0 ? ACTION_MS : cfg.duration
  },

  render(d) {
    const cfg = this.cfg()
    const prev = this.toasts.get(d.id)
    const fmt = this.format(d)
    const st = this.stackFor(this.positionOf(d, fmt, cfg))

    // A full stack keeps the toast in the queue (a new one with the id of a queued one replaces it).
    if (!prev && this.inView(st) >= this.limit(cfg)) {
      this.pending.delete(d.id)
      this.pending.set(d.id, {data: d, stack: st})
      return
    }
    this.pending.delete(d.id)
    if (prev && prev.anim) prev.anim.cancel()

    const duration = this.durationOf(d, cfg, fmt)
    const course = inCourse(d)
    const el = fmt === "template" ? this.fromTemplate(d) : fmt === "status" ? this.statusEl(d, cfg) : this.cardEl(d, cfg, course)
    el.dataset.toastId = d.id
    el.dataset.format = fmt
    el.style.pointerEvents = "auto"
    if (!el.style.position) el.style.position = "relative"
    if (fmt !== "template") this.announce(el, d, fmt)
    if (prev && fmt !== "template") this.carry(prev.el, el)

    // Close buttons and actions.
    el.querySelectorAll("[data-toast-dismiss]").forEach((b) => b.addEventListener("click", () => this.dismiss(d.id)))
    ;(fmt === "status" ? actionsOf(d).slice(0, 1) : actionsOf(d)).forEach((a, i) => {
      const b = el.querySelector(`[data-action="${i}"]`)
      if (b) b.addEventListener("click", () => this.act(d, a))
    })

    // Count down: a thin line whose animation is the clock (pausable, resumes with the time left).
    let anim = null
    if (duration !== INF) {
      const line = document.createElement("i")
      line.setAttribute("aria-hidden", "true")
      const show = d.timer == null ? cfg.timer : d.timer
      line.style.cssText = `position:absolute;left:12px;right:12px;bottom:0;height:2px;border-radius:2px;background:currentColor;transform-origin:left;pointer-events:none;opacity:${show ? 0.3 : 0}`
      el.appendChild(line)
      anim = line.animate([{transform: "scaleX(1)"}, {transform: "scaleX(0)"}], {duration, fill: "forwards", easing: "linear"})
      anim.onfinish = () => this.dismiss(d.id)
      if (this.paused) anim.pause()
    }

    if (!cfg.stack) el.style.cssText += ";margin:0;transform:none;opacity:1;display:flex"

    if (prev && prev.el.isConnected) {
      if (prev.el.parentNode === st) prev.el.replaceWith(el)
      else { prev.el.remove(); st.appendChild(el) }
    } else {
      if (!cfg.stack) st.style.gap = "8px"
      st.appendChild(el)
    }
    this.toasts.set(d.id, {el, data: d, anim, stack: st})
    if (prev && prev.stack !== st) this.drain(prev.stack)
  },

  // What a screen reader gets: an error or a warning interrupts (alert), the rest waits its turn (status).
  announce(el, d, fmt) {
    const k = colorKind(d)
    const urgent = fmt === "status" ? ["err", "warn"].includes(this.pillStatus(d)) : k === "error" || k === "warning"
    el.setAttribute("role", urgent ? "alert" : "status")
    el.setAttribute("aria-live", urgent ? "assertive" : "polite")
    el.setAttribute("aria-atomic", "true")
  },

  // The progress moves from where it was instead of jumping: the new element starts at the old level.
  carry(old, el) {
    const from = old.querySelector("[data-part=toast-fill]")
    const to = el.querySelector("[data-part=toast-fill]")
    if (from && to) {
      const next = to.style.transform
      to.style.transform = from.style.transform
      requestAnimationFrame(() => requestAnimationFrame(() => { to.style.transform = next }))
    }
    const lead = old.querySelector("[data-part=status-toast-lead]")
    const now = el.querySelector("[data-part=status-toast-lead]")
    const was = lead && lead.style.getPropertyValue("--lu-stp")
    const level = now && now.style.getPropertyValue("--lu-stp")
    if (was && level) {
      now.style.setProperty("--lu-stp", was)
      requestAnimationFrame(() => requestAnimationFrame(() => now.style.setProperty("--lu-stp", level)))
    }
  },

  closeBtn(label) {
    const C = this.cls
    return `<button class="${C.close}" type="button" aria-label="${esc(label)}" data-part="toast-close" data-toast-dismiss>${icon(C, "x", "sm")}</button>`
  },

  actionsHtml(d, cls, ghostCls) {
    return (d.actions || []).map((a, i) => {
      if (a.dismiss === true && !a.event && !a.js && !a.href) return `<button class="${cls(a)}" type="button" data-part="toast-action" data-toast-dismiss>${esc(a.label)}</button>`
      if (a.href) return `<a class="${cls(a)}" href="${esc(a.href)}" data-part="toast-action" data-action="${i}">${esc(a.label)}</a>`
      return `<button class="${cls(a)}" type="button" data-part="toast-action" data-action="${i}">${esc(a.label)}</button>`
    }).join("")
  },

  act(d, a) {
    const payload = Object.assign({}, a.value || {}, {toast_id: d.id})
    if (a.event) a.target ? this.pushEventTo(a.target, a.event, payload) : this.pushEvent(a.event, payload)
    if (a.js) this.js().exec(typeof a.js === "string" ? a.js : JSON.stringify(a.js))
    if (a.dismiss !== false) this.dismiss(d.id)
  },

  statusEl(d, cfg) {
    const C = this.cls
    const status = this.pillStatus(d)
    const el = document.createElement("div")
    el.className = C.stoast
    el.dataset.part = "status-toast"
    const level = d.value != null ? clamp(d.value) : null
    const lead = {
      run: `<span data-part="status-toast-lead" class="${level != null ? C.st_set : C.st_auto}"${level != null ? ` style="--lu-stp:${level}%"` : ""}><i data-part="status-toast-liquid" class="${C.st_liquid}"></i></span>`,
      queue: `<span data-part="status-toast-lead" class="${C.st_queue}"><i data-part="status-toast-liquid" class="hidden"></i></span>`,
      ok: `<span data-part="status-toast-dot" class="${C.dot_ok}"></span>`,
      err: `<span data-part="status-toast-dot" class="${C.dot_err}"></span>`,
      warn: `<span data-part="status-toast-dot" class="${C.dot_warn}"></span>`,
    }[status] || `<span data-part="status-toast-dot" class="${C.dot_ok}"></span>`
    const working = status === "run" || status === "queue"
    const cls = (a) => (a.variant === "ghost" || (working && !a.variant) ? C.act_ghost : C.act)
    const pct = level != null && status === "run" ? `<span data-part="status-toast-pct" class="${C.st_pct}">${Math.round(level)}%</span>` : ""
    const showClose = d.close === true
    el.innerHTML = `${lead}<span data-part="status-toast-msg" class="${C.msg}">${rich(d.title)}</span>${pct}${this.actionsHtml({actions: actionsOf(d).slice(0, 1)}, cls)}${showClose ? this.closeBtn(cfg.closeLabel) : ""}`
    return el
  },

  cardEl(d, cfg, course) {
    const C = this.cls
    const ck = colorKind(d)
    const [kname, kicon] = KINDS[ck] || KINDS.neutral
    const color = d.color && COLORS[d.color]
    const invert = d.invert ?? cfg.invert
    const failed = ck === "error" && d.value != null
    const done = (d.value != null && d.value >= 100 && !failed) || (d.steps && d.step >= d.steps)
    const dark = d.color === "dark"
    const inverse = dark || invert
    const surface = failed ? `${C.fail} ${inverse ? "text-white" : "text-ink"}` : inverse ? C.dark : C.light
    const cls = [C.card, C.colors[done ? "success" : color || kname], surface]

    const spinner = (extra) => `<span data-part="spinner" class="${extra ? C.spinner : C.spinner_tile}" role="status" aria-label="${esc(cfg.loadingLabel)}"></span>`
    const tile = d.value != null && !done && !failed ? icon(C, d.icon || "check-circle", "md")
      : busy(d) && d.value == null ? spinner(false)
      : icon(C, done ? "check" : kicon || "info", "md")
    const showSpinner = (d.value != null && !done && !failed) || (d.aura && course && !busy(d) && d.aura !== "glow" && d.aura !== "dual")
    const pct = d.value != null && !d.bar && !failed ? `<span data-part="toast-pct" class="${C.pct}${done ? " text-pos" : ""}">${Math.round(d.value)}%</span>` : ""
    const fill = d.value != null && !d.bar ? `<span data-part="toast-fill" class="${C.fill} ${done ? C.fill_done : C.fill_run}" style="transform:scaleX(${Math.max(0, Math.min(1, d.value / 100))})"></span>` : ""
    const bar = d.value != null && d.bar ? `<span data-part="toast-bar" class="${C.bar}"><i class="${C.bar_fill}" style="width:${Math.max(0, Math.min(100, d.value))}%"></i></span>` : ""
    const segs = d.steps ? `<div data-part="toast-segs" class="${C.segs}">${Array.from({length: d.steps}, (_, i) => `<i data-part="toast-seg" class="${i < d.step ? C.seg_done : i === d.step ? C.seg_cur : C.seg}"></i>`).join("")}</div>` : ""
    const counter = d.steps ? ` <span class="${C.counter}">${Math.min(d.step, d.steps)}/${d.steps}</span>` : ""
    const abtn = (a) => C.buttons[`${a.color === "primary" ? "primary" : a.color === "error" ? "error" : "neutral"}:${a.variant || "outline"}`] || C.buttons["neutral:outline"]
    const closable = d.close != null ? d.close : !course
    const desc = inverse ? C.desc_dark : C.desc_light
    const html =
      `${fill}${bar}<span data-part="toast-tile" class="${C.tile} ${dark ? C.tile_dark : C.tile_light}">${tile}</span>` +
      `<div data-part="toast-body" class="${C.body}"><b data-part="toast-title">${esc(String(d.title == null ? "" : d.title).replace(/\*\*/g, ""))}${counter}</b>${d.description ? `<span data-part="toast-description" class="${desc}">${esc(d.description)}</span>` : ""}${segs}</div>` +
      `${this.actionsHtml(d, abtn)}${showSpinner ? spinner(true) : ""}${pct}` +
      `${closable ? this.closeBtn(cfg.closeLabel) : ""}`

    const card = document.createElement("div")
    card.className = cls.join(" ")
    card.dataset.part = "toast-card"
    card.innerHTML = html
    if (!d.aura) {
      const wrap = document.createElement("div")
      wrap.className = C.wrap
      wrap.appendChild(card)
      return wrap
    }
    const A = C.aura
    const mode = AURA_MODES[String(d.aura)] || "spin"
    const tone = AURA_TONES[d.aura_color || "assistant"] || "ai"
    const size = d.aura_size || "default"
    const aura = document.createElement("span")
    aura.dataset.part = "toast-aura"
    aura.className = [A.base, A.modes[mode], A.tones[tone], A.widths[size], A.shadow].join(" ")
    aura.appendChild(card)
    return aura
  },

  fromTemplate(d) {
    const tpl = document.getElementById(d.template)
    const src = tpl && tpl.content && tpl.content.firstElementChild
    const el = src ? src.cloneNode(true) : document.createElement("div")
    return el
  },

  pause(on) {
    if (this.paused === on) return
    this.paused = on
    this.toasts.forEach((t) => t.anim && (on ? t.anim.pause() : t.anim.play()))
  },

  dismiss(id) {
    if (this.pending.delete(id)) return
    const t = this.toasts.get(id)
    if (!t) return
    this.toasts.delete(id)
    if (t.anim) t.anim.cancel()
    const el = t.el
    const reduce = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches
    if (reduce) el.remove()
    else {
      el.style.transition = "opacity .25s, transform .25s"
      el.style.opacity = "0"
      el.style.transform = "translateY(8px) scale(.97)"
      setTimeout(() => el.remove(), 250)
    }
    this.drain(t.stack)
  },
}
