// LedgerUI.Timer: a clock that ticks in the browser (`<.timer>`, the clock of `<.cash_timer>`).
//
// The server owns the time: `data-elapsed` (seconds counted so far), `data-running`,
// `data-total` and `data-direction` are read on mount and again whenever one of them changes on
// the server (a patch that changes none leaves the count alone). From there the browser counts
// from a monotonic clock (`performance.now`), so a background tab never loses a second.
//
// Commands (browser, via `LedgerUI.Timer.pause/resume/toggle/add(id)`): a `ledger:timer` event
// on the element with `detail.op`; from the server a pushed `ledger:timer` event with `id`.
// Events pushed: `data-on-toggle` ({id, running, elapsed}), `data-on-tick` ({id, elapsed,
// remaining}, every second) and `data-on-finish` ({id, elapsed}, once at the end of a countdown
// or, with `data-stop-at-total`, a count up). `data-on-*-js` hold a JS command instead.

const pad = (n) => String(n).padStart(2, "0")

export function format(seconds, fmt) {
  const s = Math.max(0, Math.floor(seconds))
  const h = Math.floor(s / 3600)
  const m = Math.floor((s % 3600) / 60)
  const sec = s % 60
  if (fmt === "hm") return `${h}h${pad(m)}`
  if (fmt === "hh:mm") return `${pad(h)}:${pad(m)}`
  return `${pad(h)}:${pad(m)}:${pad(sec)}`
}

export default {
  mounted() {
    this.onCommand = (e) => this.command(e.detail || {})
    this.el.addEventListener("ledger:timer", this.onCommand)
    this.handleEvent("ledger:timer", (p) => { if (p.id === this.el.id) this.command(p) })
    this.sync()
    this.timer = setInterval(() => this.tick(), 250)
  },

  updated() {
    const sig = this.signature()
    if (sig !== this.sig) this.sync()
  },

  destroyed() {
    clearInterval(this.timer)
    this.el.removeEventListener("ledger:timer", this.onCommand)
  },

  signature() {
    const d = this.el.dataset
    return [d.luElapsed, d.luTotal, d.luRunning, d.luDirection].join("|")
  },

  // Takes the server's numbers as the new starting point.
  sync() {
    const d = this.el.dataset
    this.sig = this.signature()
    this.base = Number(d.luElapsed || 0)
    this.total = Number(d.luTotal || 28800)
    this.running = d.luRunning !== "false"
    this.dir = d.luDirection === "down" ? "down" : "up"
    this.stopAtTotal = d.luStopAtTotal === "true"
    this.fmt = d.luFormat || "hms"
    this.t0 = performance.now()
    this.finished = false
    this.lastShown = null
    this.render(true)
  },

  elapsed() {
    return this.running ? this.base + (performance.now() - this.t0) / 1000 : this.base
  },

  out() {
    return this.el.hasAttribute("data-lu-time-self") ? this.el : this.el.querySelector("[data-lu-time]")
  },

  tick() {
    const e = this.elapsed()
    const finishing =
      !this.finished && this.running && ((this.dir === "down" && e >= this.total) || (this.dir === "up" && this.stopAtTotal && e >= this.total))
    if (finishing) {
      this.base = this.total
      this.running = false
      this.finished = true
      this.render(true)
      this.emit("finish", {elapsed: Math.floor(this.total)})
      return
    }
    this.render(false)
  },

  render(force) {
    const e = Math.min(this.elapsed(), this.dir === "down" || this.stopAtTotal ? this.total : Infinity)
    const shown = this.dir === "down" ? Math.max(0, this.total - e) : e
    const secs = Math.floor(shown)
    if (!force && secs === this.lastShown) return
    const second = this.lastShown !== null && secs !== this.lastShown
    this.lastShown = secs
    const out = this.out()
    if (out) out.textContent = format(shown, this.fmt)
    const ring = this.el.matches(".lu-timer") ? this.el : this.el.querySelector(".lu-timer")
    if (ring) {
      const frac = this.total > 0 ? Math.min(1, Math.max(0, (this.dir === "down" ? this.total - e : e) / this.total)) : 0
      ring.style.setProperty("--sp", (frac * 100).toFixed(1) + "%")
      this.paint(ring)
    }
    const kicker = this.el.querySelector("[data-lu-kicker]")
    if (kicker) kicker.textContent = this.running ? this.el.dataset.luKicker || "" : this.el.dataset.luKickerPaused || this.el.dataset.luKicker || ""
    const dot = this.el.querySelector(".lu-dot.live")
    if (dot) dot.style.animationPlayState = this.running ? "running" : "paused"
    if (second && this.el.dataset.luOnTick !== undefined) {
      this.emit("tick", {elapsed: Math.floor(e), remaining: Math.max(0, Math.floor(this.total - e))})
    }
  },

  // The ring is drawn in its colour while it runs and in warning when paused.
  paint(ring) {
    const color = ring.dataset.luColor || ""
    ring.classList.forEach((c) => { if (c.startsWith("c-")) ring.classList.remove(c) })
    const use = this.running ? color : "warning"
    if (use) ring.classList.add("c-" + use)
  },

  command(c) {
    const e = this.elapsed()
    switch (c.op) {
      case "pause": return this.setRunning(false)
      case "resume": return this.setRunning(true)
      case "toggle": return this.setRunning(!this.running)
      case "add":
        this.base = Math.max(0, e + Number(c.seconds || 0))
        this.t0 = performance.now()
        this.finished = false
        return this.render(true)
    }
  },

  setRunning(on) {
    if (on === this.running) return
    this.base = this.elapsed()
    this.t0 = performance.now()
    this.running = on
    this.render(true)
    this.emit("toggle", {running: on, elapsed: Math.floor(this.base)})
  },

  emit(kind, payload) {
    const d = this.el.dataset
    const name = kind[0].toUpperCase() + kind.slice(1)
    const event = d["luOn" + name]
    const js = d["luOn" + name + "Js"]
    if (js) this.js().exec(js)
    if (event) {
      const body = Object.assign({id: this.el.id}, payload)
      const target = this.el.getAttribute("phx-target")
      if (target) this.pushEventTo(target, event, body)
      else this.pushEvent(event, body)
    }
  },
}
