// LedgerUI.Toaster: draws the toasts of `<.toaster>` (flash, `send_toast/3` pushes and the
// `show_toast/2` JS command), stacks them, counts their time and handles actions.
//
// Wire: the server pushes `ledger:toast` events (`{op: "show" | "update" | "dismiss" | "clear", ...}`),
// `show_toast/2` dispatches the same event on the toaster element, and the flash arrives as a JSON
// list in `data-flash`. Client-owned DOM: the stack (`[data-part=toast-stack]`) is `phx-update="ignore"`.
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
const STATUS_OF = {success: "ok", info: "ok", neutral: "ok", error: "err", warning: "err", loading: "run"}
const POSITIONS = {
  "left-top": "left:16px;right:auto;top:16px;bottom:auto;transform:none;align-items:flex-start;flex-direction:column",
  "center-top": "left:50%;right:auto;top:16px;bottom:auto;transform:translateX(-50%);align-items:center;flex-direction:column",
  "right-top": "right:16px;left:auto;top:16px;bottom:auto;transform:none;align-items:flex-end;flex-direction:column",
  "left-bottom": "left:16px;right:auto;bottom:16px;top:auto;transform:none;align-items:flex-start;flex-direction:column-reverse",
  "center-bottom": "left:50%;right:auto;bottom:16px;top:auto;transform:translateX(-50%);align-items:center;flex-direction:column-reverse",
  "right-bottom": "right:16px;left:auto;bottom:16px;top:auto;transform:none;align-items:flex-end;flex-direction:column-reverse",
}

const INF = Infinity

export default {
  mounted() {
    this.cls = this.loadClasses()
    this.toasts = new Map()
    this.seen = new Set()
    this.stacks = new Map()
    this.paused = false
    this.watched = new Set()
    this.onEvent = (e) => this.handle(e.detail || {})
    this.el.addEventListener("ledger:toast", this.onEvent)
    this.handleEvent("ledger:toast", (p) => this.handle(p))
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
      case "clear": return Array.from(this.toasts.keys()).forEach((id) => this.dismiss(id))
    }
  },

  show(data) {
    data = Object.assign({}, data)
    if (!data.id) data.id = "t" + Math.random().toString(36).slice(2, 9)
    if (data.title == null && data.message != null) data.title = data.message
    this.render(data)
    return data.id
  },

  update(id, changes) {
    const cur = this.toasts.get(id)
    if (!cur) return this.show(Object.assign({}, changes, {id}))
    const next = Object.assign({}, cur.data, changes)
    delete next.op
    if (changes.message != null && changes.title == null) next.title = changes.message
    this.render(next)
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

  durationOf(d, cfg) {
    const done = (d.value != null && d.value >= 100) || (d.steps && d.step >= d.steps)
    if (d.duration != null) return d.duration === "infinity" || d.duration === 0 || d.duration === "0" ? INF : Number(d.duration)
    if (done) return 1600
    const sticky =
      (d.actions && d.actions.length) || d.template || d.aura === "glow" || d.kind === "loading" ||
      (d.value != null && d.value < 100) || (d.steps && d.step < d.steps) || d.status === "run" || d.status === "queue" ||
      (d.kind === "error" && cfg.persistErrors)
    return sticky ? INF : cfg.duration
  },

  render(d) {
    const cfg = this.cfg()
    const prev = this.toasts.get(d.id)
    if (prev && prev.anim) prev.anim.cancel()

    const duration = this.durationOf(d, cfg)
    const inCourse = d.kind === "loading" || (d.value != null && d.value < 100) || (d.steps && d.step < d.steps)
    const status = d.status || (!d.description && !d.aura && d.value == null && !d.steps && !d.template && STATUS_OF[d.kind || "neutral"])
    const el = d.template ? this.fromTemplate(d) : status ? this.statusEl(d, status, cfg, inCourse) : this.cardEl(d, cfg, inCourse)
    el.dataset.toastId = d.id
    el.style.pointerEvents = "auto"
    if (!el.style.position) el.style.position = "relative"

    // Close buttons and actions.
    el.querySelectorAll("[data-toast-dismiss]").forEach((b) => b.addEventListener("click", () => this.dismiss(d.id)))
    ;(d.actions || []).forEach((a, i) => {
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

    const entry = {el, data: d, anim}
    if (prev && prev.el.isConnected) {
      prev.el.replaceWith(el)
    } else {
      const st = this.stackFor(d.position)
      if (!cfg.stack) st.style.gap = "8px"
      st.appendChild(el)
    }
    this.toasts.set(d.id, entry)
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

  statusEl(d, status, cfg, inCourse) {
    const C = this.cls
    const el = document.createElement("div")
    el.className = C.stoast
    el.dataset.part = "status-toast"
    el.setAttribute("role", "status")
    const lead = {
      run: `<span data-part="status-toast-lead" class="${d.value != null ? C.st_set : C.st_auto}"${d.value != null ? ` style="--lu-stp:${Math.max(0, Math.min(100, d.value))}%"` : ""}><i data-part="status-toast-liquid" class="${C.st_liquid}"></i></span>`,
      queue: `<span data-part="status-toast-lead" class="${C.st_queue}"><i data-part="status-toast-liquid" class="hidden"></i></span>`,
      ok: `<span data-part="status-toast-dot" class="${C.dot_ok}"></span>`,
      err: `<span data-part="status-toast-dot" class="${C.dot_err}"></span>`,
    }[status] || `<span data-part="status-toast-dot" class="${C.dot_ok}"></span>`
    const cls = (a) => (a.variant === "ghost" ? C.act_ghost : C.act)
    const showClose = d.close === true
    el.innerHTML = `${lead}<span data-part="status-toast-msg" class="${C.msg}">${rich(d.title)}</span>${this.actionsHtml(d, cls)}${showClose ? this.closeBtn(cfg.closeLabel) : ""}`
    return el
  },

  cardEl(d, cfg, inCourse) {
    const C = this.cls
    const [kname, kicon] = KINDS[d.kind || "neutral"] || KINDS.neutral
    const color = d.color && COLORS[d.color]
    const invert = d.invert ?? cfg.invert
    const failed = d.kind === "error" && d.value != null
    const done = (d.value != null && d.value >= 100 && !failed) || (d.steps && d.step >= d.steps)
    const dark = d.color === "dark"
    const inverse = dark || invert
    const surface = failed ? `${C.fail} ${inverse ? "text-white" : "text-ink"}` : inverse ? C.dark : C.light
    const cls = [C.card, C.colors[done ? "success" : color || kname], surface]

    const spinner = (extra) => `<span data-part="spinner" class="${extra ? C.spinner : C.spinner_tile}" role="status" aria-label="${esc(cfg.loadingLabel)}"></span>`
    const tile = d.value != null && !done && !failed ? icon(C, d.icon || "check-circle", "md")
      : d.kind === "loading" ? spinner(false)
      : icon(C, done ? "check" : kicon || "info", "md")
    const showSpinner = (d.value != null && !done && !failed) || (d.aura && inCourse && d.kind !== "loading" && d.aura !== "glow" && d.aura !== "dual")
    const pct = d.value != null && !d.bar && !failed ? `<span data-part="toast-pct" class="${C.pct}${done ? " text-pos" : ""}">${Math.round(d.value)}%</span>` : ""
    const fill = d.value != null && !d.bar ? `<span data-part="toast-fill" class="${C.fill} ${done ? C.fill_done : C.fill_run}" style="transform:scaleX(${Math.max(0, Math.min(1, d.value / 100))})"></span>` : ""
    const bar = d.value != null && d.bar ? `<span data-part="toast-bar" class="${C.bar}"><i class="${C.bar_fill}" style="width:${Math.max(0, Math.min(100, d.value))}%"></i></span>` : ""
    const segs = d.steps ? `<div data-part="toast-segs" class="${C.segs}">${Array.from({length: d.steps}, (_, i) => `<i data-part="toast-seg" class="${i < d.step ? C.seg_done : i === d.step ? C.seg_cur : C.seg}"></i>`).join("")}</div>` : ""
    const counter = d.steps ? ` <span class="${C.counter}">${Math.min(d.step, d.steps)}/${d.steps}</span>` : ""
    const abtn = (a) => C.buttons[`${a.color === "primary" ? "primary" : a.color === "error" ? "error" : "neutral"}:${a.variant || "outline"}`] || C.buttons["neutral:outline"]
    const closable = d.close != null ? d.close : !(inCourse || d.kind === "loading")
    const desc = inverse ? C.desc_dark : C.desc_light
    const html =
      `${fill}${bar}<span data-part="toast-tile" class="${C.tile} ${dark ? C.tile_dark : C.tile_light}">${tile}</span>` +
      `<div data-part="toast-body" class="${C.body}"><b data-part="toast-title">${esc(d.title)}${counter}</b>${d.description ? `<span data-part="toast-description" class="${desc}">${esc(d.description)}</span>` : ""}${segs}</div>` +
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
    const t = this.toasts.get(id)
    if (!t) return
    this.toasts.delete(id)
    if (t.anim) t.anim.cancel()
    const el = t.el
    const reduce = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches
    if (reduce) return el.remove()
    el.style.transition = "opacity .25s, transform .25s"
    el.style.opacity = "0"
    el.style.transform = "translateY(8px) scale(.97)"
    setTimeout(() => el.remove(), 250)
  },
}
