// LedgerUI.Persist: keeps a value in sessionStorage/localStorage and gives it back on mount.
//   data-lu-key         storage key
//   data-lu-storage     "session" (default) or "local"
//   data-lu-value       the current value, JSON
//   data-lu-on-restore  LiveView event pushed with {value: saved}; data-lu-target its target
// On mount a saved value that differs from the current one is pushed BEFORE anything is written,
// and the current value is not written over it. Invalid JSON and blocked storage are ignored.
function store(el) {
  try {
    return el.getAttribute("data-lu-storage") === "local" ? window.localStorage : window.sessionStorage
  } catch (_e) {
    return null // access to the storage itself can throw (blocked cookies)
  }
}

export default {
  mounted() {
    this.written = null
    const el = this.el
    const key = el.getAttribute("data-lu-key")
    const current = el.getAttribute("data-lu-value")
    const event = el.getAttribute("data-lu-on-restore")
    let restored = false

    if (event && key) {
      const saved = this.read(key)
      if (saved && saved.raw !== current) {
        const target = el.getAttribute("data-lu-target")
        if (target) this.pushEventTo(/^\d+$/.test(target) ? `[data-phx-component="${target}"]` : target, event, {value: saved.value})
        else this.pushEvent(event, {value: saved.value})
        restored = true
        this.written = saved.raw
      }
    }
    if (!restored) this.write()
  },

  updated() {
    this.write()
  },

  // {raw, value} of a valid saved JSON, else null.
  read(key) {
    try {
      const raw = store(this.el)?.getItem(key)
      if (raw == null) return null
      return {raw, value: JSON.parse(raw)}
    } catch (_e) {
      return null
    }
  },

  write() {
    const el = this.el
    const key = el.getAttribute("data-lu-key")
    const value = el.getAttribute("data-lu-value")
    if (!key || value == null || value === this.written) return
    try {
      store(el)?.setItem(key, value)
      this.written = value
    } catch (_e) { /* blocked or full: the state just is not kept */ }
  },
}
