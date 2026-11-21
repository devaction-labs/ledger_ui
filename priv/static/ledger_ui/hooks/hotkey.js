// LedgerUI.Hotkey: a global keyboard shortcut.
//   data-lu-keys         combinations separated by commas: "Mod+j, Mod+Shift+k"
//   data-lu-on-press     LiveView event name pushed with {key}; data-lu-target its target
//   data-lu-on-press-js  encoded %JS{} executed on the element
//   data-lu-in-inputs    "true": also fires while the focus is in a field
// `Mod` is Cmd on macOS and Ctrl elsewhere. Modifiers must match exactly.
const ALIASES = {esc: "escape", space: " ", spacebar: " ", del: "delete", up: "arrowup", down: "arrowdown", left: "arrowleft", right: "arrowright", plus: "+", return: "enter"}
export const FIELD = "input, textarea, select, [contenteditable]:not([contenteditable=false])"

function isMac() {
  const p = (typeof navigator !== "undefined" && (navigator.userAgentData?.platform || navigator.platform || navigator.userAgent)) || ""
  return /mac|iphone|ipad|ipod/i.test(p)
}

export function parseKeys(spec, mac = isMac()) {
  const combos = []
  for (const raw of String(spec || "").split(",")) {
    const text = raw.trim()
    if (!text) continue
    const combo = {ctrl: false, meta: false, alt: false, shift: false, key: "", text}
    const plus = text.endsWith("++") || text === "+"
    const parts = (plus ? text.slice(0, -1) : text).split("+").map((p) => p.trim()).filter(Boolean)
    const key = plus ? "+" : parts.pop()
    if (!key) continue
    for (const m of parts.map((p) => p.toLowerCase())) {
      if (m === "mod") combo[mac ? "meta" : "ctrl"] = true
      else if (m === "ctrl" || m === "control") combo.ctrl = true
      else if (m === "cmd" || m === "meta" || m === "command") combo.meta = true
      else if (m === "alt" || m === "option") combo.alt = true
      else if (m === "shift") combo.shift = true
    }
    const k = key.toLowerCase()
    combo.key = ALIASES[k] || k
    combos.push(combo)
  }
  return combos
}

// With Alt (and Shift on some layouts) `e.key` is another character: fall back to the physical key.
function keyOf(e) {
  const k = (e.key || "").toLowerCase()
  const m = /^(?:Key|Digit)(.)$/.exec(e.code || "")
  return m && (e.altKey || e.key === "Dead") ? m[1].toLowerCase() : k
}

export function matches(combo, e) {
  return e.ctrlKey === combo.ctrl && e.metaKey === combo.meta && e.altKey === combo.alt &&
    e.shiftKey === combo.shift && keyOf(e) === combo.key
}

export default {
  mounted() {
    this.parsed = null
    this.parsedFrom = null
    this.onKey = (e) => {
      const el = this.el
      const spec = el.getAttribute("data-lu-keys")
      if (spec !== this.parsedFrom) { this.parsed = parseKeys(spec); this.parsedFrom = spec }
      const combo = this.parsed.find((c) => matches(c, e))
      if (!combo) return
      if (el.getAttribute("data-lu-in-inputs") !== "true" && e.target?.closest?.(FIELD)) return
      e.preventDefault()
      this.fire(combo.text)
    }
    document.addEventListener("keydown", this.onKey)
  },

  fire(key) {
    const el = this.el
    const event = el.getAttribute("data-lu-on-press")
    const js = el.getAttribute("data-lu-on-press-js")
    if (event) {
      const target = el.getAttribute("data-lu-target")
      if (target) this.pushEventTo(/^\d+$/.test(target) ? `[data-phx-component="${target}"]` : target, event, {key})
      else this.pushEvent(event, {key})
    }
    if (js) this.liveSocket.execJS(el, js)
  },

  destroyed() {
    document.removeEventListener("keydown", this.onKey)
  },
}
