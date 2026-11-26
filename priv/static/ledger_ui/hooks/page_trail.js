// LedgerUI.PageTrail: keeps the page trail, a per-screen snapshot and the scroll position in the browser.
//   data-lu-key              localStorage key of the trail ("lu:trail")
//   data-lu-trail            the trail as the server renders it, JSON {pinned, recent}
//   data-lu-path             base path of the current screen
//   data-lu-state            snapshot of the current screen, JSON (only when the LiveView opted in)
//   data-lu-state-storage    "session" (default) or "local": where snapshot and scroll go
//   data-lu-scroll           "false" turns the scroll position off
//   data-lu-scroll-container CSS selector of the scrolling element (default: the window)
//   data-lu-on-change        LiveView event pushed with {trail} when the trail changes
// On mount a saved trail that differs from the rendered one is pushed ("lu:trail:restore") BEFORE
// anything is written; the server validates it. The same goes for the snapshot ("lu:trail:state",
// with {path, state}) of a screen that opted in. Invalid JSON and blocked storage are ignored.
const STATE = "lu:trail:state:"
const SCROLL = "lu:trail:scroll:"

function store(kind) {
  try {
    return kind === "local" ? window.localStorage : window.sessionStorage
  } catch (_e) {
    return null // access to the storage itself can throw (blocked cookies)
  }
}

function read(s, key) {
  try {
    return s ? s.getItem(key) : null
  } catch (_e) {
    return null
  }
}

function write(s, key, value) {
  try {
    if (!s) return false
    s.setItem(key, value)
    return true
  } catch (_e) {
    return false // blocked or full: it just is not kept
  }
}

function parse(raw) {
  try {
    const v = JSON.parse(raw)
    return v && typeof v === "object" ? v : null
  } catch (_e) {
    return null
  }
}

export default {
  mounted() {
    this.trailSeen = null // last trail written (or restored over)
    this.trailLast = this.attr("trail") // baseline of on_change
    this.stateSeen = null
    this.path = null
    this.timer = null
    this.onNav = () => this.snapshotScroll()
    window.addEventListener("phx:page-loading-start", this.onNav)
    window.addEventListener("pagehide", this.onNav)
    this.restoreTrail()
    this.enter()
  },

  updated() {
    this.writeTrail()
    if (this.attr("path") !== this.path) this.enter()
    else this.writeState()
  },

  destroyed() {
    window.removeEventListener("phx:page-loading-start", this.onNav)
    window.removeEventListener("pagehide", this.onNav)
    clearTimeout(this.timer)
  },

  attr(name) {
    return this.el.getAttribute(`data-lu-${name}`)
  },

  // snapshot and scroll: the tab by default
  area() {
    return store(this.attr("state-storage") === "local" ? "local" : "session")
  },

  // ---- the trail -------------------------------------------------------------------------

  restoreTrail() {
    const key = this.attr("key") || "lu:trail"
    const current = this.attr("trail")
    const raw = read(store("local"), key)
    const saved = raw != null && raw !== current ? parse(raw) : null
    if (!saved) return this.writeTrail()
    this.trailSeen = raw // do not write the rendered trail over it; the reply writes the merged one
    this.pushEvent("lu:trail:restore", {trail: saved}, () => {
      this.timer = setTimeout(() => this.writeTrail(), 0)
    })
  },

  writeTrail() {
    const raw = this.attr("trail")
    if (raw == null) return
    if (raw !== this.trailSeen && write(store("local"), this.attr("key") || "lu:trail", raw)) this.trailSeen = raw
    if (raw !== this.trailLast) {
      this.trailLast = raw
      const event = this.attr("on-change")
      const trail = parse(raw)
      if (event && trail) this.pushEvent(event, {trail})
    }
  },

  // ---- a screen (mount, or a patch to another path) ---------------------------------------

  enter() {
    clearTimeout(this.scrollTimer)
    this.path = this.attr("path")
    this.stateSeen = null
    if (!this.path) return
    this.restoreState()
    this.restoreScroll()
  },

  restoreState() {
    const current = this.attr("state")
    if (current == null) return // the LiveView did not opt in
    const raw = read(this.area(), STATE + this.path)
    const saved = raw != null && raw !== current ? parse(raw) : null
    if (!saved) return this.writeState()
    this.stateSeen = raw
    this.pushEvent("lu:trail:state", {path: this.path, state: saved}, () => {
      this.timer = setTimeout(() => this.writeState(), 0)
    })
  },

  writeState() {
    const raw = this.attr("state")
    if (raw == null || !this.path || raw === this.stateSeen) return
    if (write(this.area(), STATE + this.path, raw)) this.stateSeen = raw
  },

  // ---- scroll ----------------------------------------------------------------------------

  container() {
    const selector = this.attr("scroll-container")
    if (!selector) return null
    try {
      return document.querySelector(selector)
    } catch (_e) {
      return null
    }
  },

  snapshotScroll() {
    if (!this.path || this.attr("scroll") === "false") return
    const box = this.container()
    const y = Math.round(box ? box.scrollTop : window.scrollY)
    write(this.area(), SCROLL + this.path, String(y))
  },

  restoreScroll() {
    if (this.attr("scroll") === "false") return
    const y = parseInt(read(this.area(), SCROLL + this.path), 10)
    if (!(y > 0)) return
    let tries = 0
    // the page may still be filling up (async content): try a few times
    const step = () => {
      const box = this.container()
      if (box) box.scrollTop = y
      else window.scrollTo({top: y, left: 0, behavior: "instant"})
      const now = box ? box.scrollTop : window.scrollY
      if (Math.abs(now - y) <= 1 || ++tries >= 8) return
      this.scrollTimer = setTimeout(step, 100)
    }
    this.scrollTimer = setTimeout(step, 0)
  },
}
