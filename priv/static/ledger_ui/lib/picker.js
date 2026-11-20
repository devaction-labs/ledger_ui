// Shared helpers of the date/time pickers (not a hook: lives outside hooks/).
export const pad = (n) => String(n).padStart(2, "0")
export const iso = (d) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
export const parse = (s) => {
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(s || "")
  return m ? new Date(+m[1], +m[2] - 1, +m[3]) : null
}
export const addDays = (d, n) => new Date(d.getFullYear(), d.getMonth(), d.getDate() + n)
export const addMonths = (d, n) => new Date(d.getFullYear(), d.getMonth() + n, 1)
export const same = (a, b) => !!a && !!b && iso(a) === iso(b)
export const esc = (s) =>
  String(s ?? "").replace(/[&<>"']/g, (c) => ({"&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"}[c]))

// flatpickr-like tokens: Y y m n d j F M l D H G h i K
export function fmt(d, f, months, weekdays, time) {
  if (!d) return ""
  const h = time ? time.h : 0
  const mi = time ? time.m : 0
  return f
    .split("")
    .map((c) => {
      switch (c) {
        case "Y": return d.getFullYear()
        case "y": return pad(d.getFullYear() % 100)
        case "m": return pad(d.getMonth() + 1)
        case "n": return d.getMonth() + 1
        case "d": return pad(d.getDate())
        case "j": return d.getDate()
        case "F": return months[d.getMonth()]
        case "M": return months[d.getMonth()].slice(0, 3)
        case "l": return weekdays[d.getDay()]
        case "D": return weekdays[d.getDay()].slice(0, 3)
        case "H": return pad(h)
        case "G": return h
        case "h": return pad(h % 12 || 12)
        case "i": return pad(mi)
        case "K": return h < 12 ? "AM" : "PM"
        default: return c
      }
    })
    .join("")
}

// Whole weeks of a month: [{d: Date, out: bool}]
export function gridDays(view, weekStart) {
  const first = new Date(view.getFullYear(), view.getMonth(), 1)
  const last = new Date(view.getFullYear(), view.getMonth() + 1, 0)
  const lead = (first.getDay() - weekStart + 7) % 7
  const trail = (weekStart - 1 - last.getDay() + 14) % 7
  const out = []
  for (let d = addDays(first, -lead); d <= addDays(last, trail); d = addDays(d, 1))
    out.push({d, out: d.getMonth() !== view.getMonth()})
  return out
}

export const rotate = (list, n) => list.slice(n).concat(list.slice(0, n))

// Pushes to the LiveView (or `target`) when `event` is set.
export function push(hook, event, target, payload) {
  if (!event) return
  if (target) hook.pushEventTo(target, event, payload)
  else hook.pushEvent(event, payload)
}

// Closes `close()` on Escape/outside click; returns a cleanup function.
export function dismiss(root, isOpen, close) {
  const onDoc = (e) => { if (isOpen() && !root.contains(e.target)) close() }
  const onKey = (e) => { if (e.key === "Escape" && isOpen() && root.contains(document.activeElement)) { close(true); e.stopPropagation() } }
  document.addEventListener("mousedown", onDoc)
  root.addEventListener("keydown", onKey)
  return () => { document.removeEventListener("mousedown", onDoc); root.removeEventListener("keydown", onKey) }
}

export function emitInput(el) {
  if (el) el.dispatchEvent(new Event("input", {bubbles: true}))
}
