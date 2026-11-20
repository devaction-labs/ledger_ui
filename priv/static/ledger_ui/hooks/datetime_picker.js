import {pad, iso, parse, fmt, addDays, addMonths, same, esc, gridDays, rotate, push, dismiss, emitInput} from "../lib/picker.js"

const hhmm = (m) => `${pad(Math.floor(m / 60))}:${pad(m % 60)}`
const toMin = (s) => { const m = /^(\d{2}):(\d{2})/.exec(s || ""); return m ? +m[1] * 60 + +m[2] : null }
// "2026-10-14T10:30" -> {d: Date, m: 630}
const moment = (s) => { const d = parse(s); return d ? {d, m: toMin((s || "").slice(11))} : null }
const stamp = (d, m) => `${iso(d)}T${hhmm(m)}`

// <.datetime_picker>: hidden inputs hold the value (wall-clock text, no time zone).
export default {
  mounted() {
    this.cfg = JSON.parse(this.el.dataset.luConfig)
    this.view = null
    this.draft = null
    this.onClick = (e) => this.click(e)
    this.onKey = (e) => this.key(e)
    this.onChange = (e) => this.change(e)
    this.onSync = () => this.refresh()
    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("keydown", this.onKey)
    this.el.addEventListener("change", this.onChange)
    this.el.addEventListener("lu:sync", this.onSync)
    this.undismiss = dismiss(this.el, () => !this.pop().hidden, (back) => this.close(back))
    this.refresh()
  },
  updated() { this.cfg = JSON.parse(this.el.dataset.luConfig); this.refresh() },
  destroyed() {
    this.el.removeEventListener("click", this.onClick)
    this.el.removeEventListener("keydown", this.onKey)
    this.el.removeEventListener("change", this.onChange)
    this.el.removeEventListener("lu:sync", this.onSync)
    this.undismiss && this.undismiss()
  },

  pop() { return this.el.querySelector("[role=dialog]") },
  vals() { return this.el.querySelector("[data-values]") },
  range() { return this.cfg.mode === "range" },
  value() {
    return [...this.vals().querySelectorAll("input")].map((i) => i.value).filter(Boolean).map(moment).filter(Boolean)
  },
  lbl(k) { return this.cfg.labels[k] || k },

  refresh() {
    const v = this.value()
    this.updateText(v)
    if (!this.pop().hidden) this.draw()
  },

  updateText(v) {
    const c = this.cfg
    const show = (x) => fmt(x.d, c.format, c.months, c.weekdays, {h: Math.floor((x.m || 0) / 60), m: (x.m || 0) % 60})
    const text = v.map(show).join(this.range() ? c.sep : "")
    const t = this.el.querySelector("[data-field=text]")
    if (t) t.value = text
    const d = this.el.querySelector("[data-field=date]"), tm = this.el.querySelector("[data-field=time]")
    if (d && v[0]) d.value = fmt(v[0].d, c.labels.datetime_title ? (c.format.split(",").slice(0, 2).join(",")) : "Y-m-d", c.months, c.weekdays)
    if (tm && v[0]) tm.value = this.timeText(v[0].m || 0)
    if (d && !v[0]) d.value = ""
    if (tm && !v[0]) tm.value = ""
  },
  timeText(m) {
    const h = Math.floor(m / 60), mi = m % 60
    return this.cfg.h24 ? hhmm(m) : `${h % 12 || 12}:${pad(mi)} ${h < 12 ? "AM" : "PM"}`
  },

  // ---- availability -------------------------------------------------------------------
  bound(b) {
    if (!b) return null
    if (b === "now") { const n = new Date(); return {d: parse(this.cfg.today) || n, m: n.getHours() * 60 + n.getMinutes()} }
    if (b === "today") return {d: parse(this.cfg.today), m: 0}
    return {d: parse(b), m: toMin(b.slice(11)) ?? 0}
  },
  // Slots of a day: [{m, off}]
  slots(d) {
    const c = this.cfg, u = c.unavailable, day = iso(d), lo = this.bound(c.min), hi = this.bound(c.max)
    const out = []
    for (let m = c.minTime - (c.minTime % c.interval) + (c.minTime % c.interval ? c.interval : 0); m <= c.maxTime; m += c.interval) {
      let off = u.days.includes(day) || u.moments.includes(`${day}T${hhmm(m)}`)
      for (const [a, b] of u.ranges) off = off || (a <= b ? m >= a && m < b : m >= a || m < b)
      if (lo && (day < iso(lo.d) || (day === iso(lo.d) && m < lo.m))) off = true
      if (hi && (day > iso(hi.d) || (day === iso(hi.d) && m > (hi.m || 24 * 60)))) off = true
      out.push({m, off})
    }
    return out
  },
  firstOpen(d) { const s = this.slots(d).find((x) => !x.off); return s ? s.m : null },
  dayOff(d) { return this.firstOpen(d) == null },

  // ---- drawing ------------------------------------------------------------------------
  cal(view, sel, opts = {}) {
    const c = this.cfg, today = parse(c.today)
    const [a, b] = opts.range || []
    const head = `<div class="hd"><b>${esc(c.labels.datetime_title.replace("%{month}", c.months[view.getMonth()]).replace("%{year}", view.getFullYear()))}</b>` +
      (opts.noPrev ? "" : `<button aria-label="${esc(this.lbl("datetime_previous"))}" class="lu-btn icon ghost sm" type="button" data-nav="-1"><svg class="lu-i" viewBox="0 0 24 24" aria-hidden="true"><path d="M15 6l-6 6l6 6" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg></button>`) +
      (opts.noNext ? "" : `<button aria-label="${esc(this.lbl("datetime_next"))}" class="lu-btn icon ghost sm" type="button" data-nav="1"><svg class="lu-i" viewBox="0 0 24 24" aria-hidden="true"><path d="M9 6l6 6l-6 6" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg></button>`) + `</div>`
    const letters = rotate(c.weekdays, c.weekStart).map((w) => `<span class="w">${esc(w.slice(0, 1))}</span>`).join("")
    const focus = this.focusDate ? iso(this.focusDate) : sel ? iso(sel) : a ? iso(a) : iso(view)
    const days = gridDays(view, c.weekStart).map(({d, out}) => {
      const cls = ["d"]
      if (out) cls.push("o")
      if (same(d, today)) cls.push("t")
      if (sel && same(d, sel)) cls.push("s")
      if (a && same(d, a)) cls.push(b && !same(a, b) ? "rs" : "s")
      else if (b && same(d, b)) cls.push("re")
      else if (a && b && d > a && d < b) cls.push("r")
      const label = c.labels.datetime_day.replace("%{weekday}", c.weekdays[d.getDay()]).replace("%{month}", c.months[d.getMonth()])
        .replace("%{day}", d.getDate()).replace("%{year}", d.getFullYear())
      const dis = this.dayOff(d) ? " disabled" : ""
      return `<button class="${cls.join(" ")}" type="button" data-d="${iso(d)}" aria-label="${esc(label)}"${dis} tabindex="${iso(d) === focus ? 0 : -1}">${d.getDate()}</button>`
    })
    return `<div class="lu-cal" role="group">${head}<div class="g" role="grid">${letters}${days.join("")}</div></div>`
  },

  draw() {
    const pop = this.pop(), c = this.cfg
    if (this.range()) return this.drawRange(pop)
    const v = this.value()[0]
    if (!this.view) this.view = v ? new Date(v.d.getFullYear(), v.d.getMonth(), 1) : new Date(parse(c.today).getFullYear(), parse(c.today).getMonth(), 1)
    const day = v ? v.d : null
    const slots = day ? this.slots(day) : []
    const q = (this.q || "").toLowerCase()
    const list = slots.filter((s) => !q || this.timeText(s.m).toLowerCase().startsWith(q))
    const times = day
      ? list.length
        ? list.map((s) => `<button type="button" class="${v && s.m === v.m ? "on" : ""}" data-t="${s.m}"${s.off ? ' disabled style="text-decoration:line-through;opacity:.45"' : ""}>${esc(this.timeText(s.m))}</button>`).join("")
        : `<div class="lu-xs lu-muted" style="padding:10px">${esc(this.lbl("datetime_no_times"))}</div>`
      : ""
    const input = c.time === "input"
      ? `<div style="padding:6px"><span class="lu-input sm"><input type="text" data-time-input placeholder="${esc(this.lbl("datetime_time_placeholder"))}" value="${esc(v ? this.timeText(v.m || 0) : "")}" aria-label="${esc(this.lbl("datetime_time"))}"></span></div>` : ""
    pop.innerHTML = `<div class="lu-pop" style="padding:0;display:inline-flex">${this.cal(this.view, day)}<div style="border-left:1px solid var(--line);width:130px;display:flex;flex-direction:column">${input}<div class="lu-times" role="listbox" aria-label="${esc(this.lbl("datetime_times"))}">${times}</div></div></div>`
    const on = pop.querySelector(".lu-times .on")
    if (on) pop.querySelector(".lu-times").scrollTop = on.offsetTop - 80
  },

  months() { return this.cfg.layout === "compact" || window.innerWidth < 640 ? 1 : 2 },
  drawRange(pop) {
    const c = this.cfg, v = this.value()
    if (!this.draft) this.draft = {a: v[0]?.d || null, b: v[1]?.d || null, ta: v[0]?.m ?? c.defaultStart ?? c.minTime, tb: v[1]?.m ?? c.defaultEnd ?? c.maxTime}
    const dr = this.draft
    if (!this.view) { const s = dr.a || parse(c.today); this.view = new Date(s.getFullYear(), s.getMonth(), 1) }
    const n = this.months()
    const cals = Array.from({length: n}, (_, i) => this.cal(addMonths(this.view, i), null, {range: [dr.a, dr.b], noPrev: i > 0, noNext: i < n - 1})).join("")
    const row = (key, label, day, t) =>
      `<div style="display:flex;align-items:center;gap:8px;padding:0 12px"><span class="lu-xs lu-muted" style="width:44px">${esc(label)}</span><span class="lu-xs mono" style="flex:1">${day ? esc(fmt(day, c.format.split(",").slice(0, 2).join(","), c.months, c.weekdays)) : "—"}</span><span class="lu-input sm" style="width:110px"><input type="time" data-range-time="${key}" value="${hhmm(t)}" aria-label="${esc(label)}"></span></div>`
    pop.innerHTML = `<div class="lu-pop" style="padding:0"><div style="display:flex">${cals}</div><div style="border-top:1px solid var(--line);padding:10px 0;display:flex;flex-direction:column;gap:8px">${row("a", this.lbl("datetime_start"), dr.a, dr.ta)}${row("b", this.lbl("datetime_end"), dr.b, dr.tb)}<div style="display:flex;gap:8px;justify-content:flex-end;padding:0 12px"><button type="button" class="lu-btn ghost sm" data-cancel>${esc(this.lbl("datetime_cancel"))}</button><button type="button" class="lu-btn primary sm" data-apply${dr.a && dr.b ? "" : " disabled"}>${esc(this.lbl("datetime_select_range"))}</button></div></div></div>`
  },

  // ---- writing ------------------------------------------------------------------------
  commit(list) {
    const c = this.cfg
    const hid = (n, v) => `<input type="hidden" name="${esc(n)}" value="${esc(v)}">`
    const texts = list.map((x) => stamp(x.d, x.m))
    let html
    if (!this.range()) html = hid(c.name, texts[0] || "")
    else if (c.startName) html = hid(c.startName, texts[0] || "") + hid(c.endName, texts[1] || "")
    else html = hid(`${c.name}[]`, "") + texts.map((t) => hid(`${c.name}[]`, t)).join("")
    this.vals().innerHTML = html
    this.updateText(list)
    emitInput(this.vals().querySelector("input"))
    const input = this.el.querySelector("input[type=text]")
    push(this, c.onChange, c.target, {id: input ? input.id : this.el.id, value: this.range() ? texts : texts[0] || ""})
  },

  pickDay(d) {
    const cur = this.value()[0]
    let m = cur && cur.m != null && !this.slots(d).find((s) => s.m === cur.m && s.off) && this.slots(d).some((s) => s.m === cur.m) ? cur.m : null
    if (m == null && this.cfg.defaultStart != null && this.slots(d).some((s) => s.m === this.cfg.defaultStart && !s.off)) m = this.cfg.defaultStart
    if (m == null) m = this.firstOpen(d)
    if (m == null) return
    this.q = ""
    this.commit([{d, m}])
    this.draw()
  },

  parseTyped(s) {
    const m = /^\s*(\d{1,2}):?(\d{2})?\s*([ap]m?)?\s*$/i.exec(s || "")
    if (!m) return null
    let h = +m[1]; const mi = +(m[2] || 0)
    if (m[3]) { h %= 12; if (m[3][0].toLowerCase() === "p") h += 12 }
    return h < 24 && mi < 60 ? h * 60 + mi : null
  },

  change(e) {
    const t = e.target
    if (t.matches && t.matches("[data-range-time]")) { this.draft[t.dataset.rangeTime === "a" ? "ta" : "tb"] = toMin(t.value) ?? 0 }
    else if (t.matches && t.matches("[data-time-input]")) {
      const cur = this.value()[0], m = this.parseTyped(t.value)
      if (cur && m != null && this.slots(cur.d).some((s) => s.m === m && !s.off)) { this.commit([{d: cur.d, m}]); this.close(true) }
      else this.draw()
    }
  },

  click(e) {
    const t = e.target, q = (s) => t.closest && t.closest(s)
    const day = q(".d")
    if (day && day.dataset.d) {
      const d = parse(day.dataset.d)
      if (this.range()) {
        const dr = this.draft
        if (!dr.a || (dr.a && dr.b)) { dr.a = d; dr.b = null }
        else if (d < dr.a) dr.a = d
        else dr.b = d
        return this.draw()
      }
      return this.pickDay(d)
    }
    const nav = q("[data-nav]")
    if (nav) { this.view = addMonths(this.view, +nav.dataset.nav); return this.draw() }
    const time = q("[data-t]")
    if (time && !time.disabled) {
      const cur = this.value()[0]
      if (cur) { this.commit([{d: cur.d, m: +time.dataset.t}]); this.close(true) }
      return
    }
    if (q("[data-cancel]")) { this.draft = null; return this.close(true) }
    if (q("[data-apply]")) {
      const dr = this.draft
      let tb = dr.tb
      if (same(dr.a, dr.b) && tb < dr.ta) tb = dr.ta
      this.commit([{d: dr.a, m: dr.ta}, {d: dr.b, m: tb}])
      this.draft = null
      return this.close(true)
    }
    if ((q(".lu-input") || q("[data-trigger]")) && !q(".lu-pop") && !q("[role=dialog]")) {
      const inp = this.el.querySelector("input[type=text]")
      if (inp && inp.disabled) return
      this.pop().hidden ? this.openPop() : this.close()
    }
  },

  key(e) {
    const inp = e.target.matches && e.target.matches("[data-field]")
    if (inp && (e.key === "ArrowDown" || e.key === "Enter")) { e.preventDefault(); return this.openPop(true) }
    const tin = e.target.matches && e.target.matches("[data-time-input]")
    if (tin && e.key === "ArrowDown") { e.preventDefault(); this.pop().querySelector("[data-t]:not([disabled])")?.focus(); return }
    if (tin) { this.q = tin.value; return }
    const t = e.target.closest && e.target.closest("[data-t]")
    if (t && ["ArrowDown", "ArrowUp", "Home", "End"].includes(e.key)) {
      e.preventDefault()
      const items = [...this.pop().querySelectorAll("[data-t]:not([disabled])")], i = items.indexOf(t)
      const n = {ArrowDown: i + 1, ArrowUp: i - 1, Home: 0, End: items.length - 1}[e.key]
      items[Math.max(0, Math.min(items.length - 1, n))].focus()
      return
    }
    const day = e.target.closest && e.target.closest(".d")
    if (!day || !day.dataset.d) return
    const d = parse(day.dataset.d), ws = this.cfg.weekStart, off = (d.getDay() - ws + 7) % 7
    const moves = {ArrowLeft: addDays(d, -1), ArrowRight: addDays(d, 1), ArrowUp: addDays(d, -7), ArrowDown: addDays(d, 7),
      Home: addDays(d, -off), End: addDays(d, 6 - off),
      PageUp: new Date(d.getFullYear() + (e.shiftKey ? -1 : 0), d.getMonth() - (e.shiftKey ? 0 : 1), d.getDate()),
      PageDown: new Date(d.getFullYear() + (e.shiftKey ? 1 : 0), d.getMonth() + (e.shiftKey ? 0 : 1), d.getDate())}
    if (moves[e.key]) {
      e.preventDefault()
      this.focusDate = moves[e.key]
      this.view = new Date(this.focusDate.getFullYear(), this.focusDate.getMonth(), 1)
      this.draw()
      this.pop().querySelector(`[data-d="${iso(this.focusDate)}"]`)?.focus()
    } else if (e.key === "Enter" || e.key === " ") { e.preventDefault(); day.click() }
  },

  openPop(focus) {
    this.view = null
    this.draft = null
    this.pop().hidden = false
    const inp = this.el.querySelector("input[type=text]")
    inp && inp.setAttribute("aria-expanded", "true")
    this.draw()
    if (focus) (this.pop().querySelector('.d[tabindex="0"]') || this.pop().querySelector(".d"))?.focus()
  },
  close(back) {
    this.pop().hidden = true
    this.focusDate = null
    const inp = this.el.querySelector("input[type=text]")
    inp && inp.setAttribute("aria-expanded", "false")
    if (back && inp) inp.focus()
  },
}
