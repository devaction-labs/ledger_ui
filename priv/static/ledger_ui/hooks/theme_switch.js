// LedgerUI.ThemeSwitch: light / dark / system.
// Reads localStorage["theme"], puts the resolved mode on <html data-theme="light|dark"> (the choice on
// data-theme-choice), keeps `on` / aria state in step and follows the `ledger:theme` window event.
// Variants (data-lu-variant): segmented | icons | cards (role=radio spans), switch (.lu-sw), toggle (a button).
const KEY = "theme"
const mq = () => window.matchMedia("(prefers-color-scheme: dark)")

// the choice kept by the page: localStorage, then <html data-theme-choice>; null when nothing was chosen yet
const kept = () => {
  try { return localStorage.getItem(KEY) || document.documentElement.getAttribute("data-theme-choice") || null }
  catch (_) { return null }
}
const stored = () => kept() || "system"

// `record: false` is the fallback of a page that chose nothing: the mode follows the system, but the
// choice is not written (so `kept()` still tells "chosen" from "nothing yet")
function apply(choice, record = true) {
  const dark = choice === "dark" || (choice === "system" && mq().matches)
  const root = document.documentElement
  root.setAttribute("data-theme", dark ? "dark" : "light")
  if (record) root.setAttribute("data-theme-choice", choice)
  return dark
}

function save(choice) {
  try {
    localStorage.setItem(KEY, choice)
    localStorage.setItem("dark-mode", apply(choice) ? "true" : "false")
  } catch (_) { apply(choice) }
  window.dispatchEvent(new CustomEvent("ledger:theme", {detail: {choice}}))
}

export default {
  mounted() {
    this.variant = this.el.getAttribute("data-lu-variant") || "segmented"
    this.onClick = (e) => {
      if (this.variant === "switch") return save(this.isDark() ? "light" : "dark")
      if (this.variant === "toggle") return save(document.documentElement.getAttribute("data-theme") === "dark" ? "light" : "dark")
      const i = this.items().indexOf(e.target.closest("[role=radio]"))
      if (i >= 0) save(this.choices()[i])
    }
    this.onKey = (e) => {
      if (this.variant === "switch" && (e.key === " " || e.key === "Enter")) { e.preventDefault(); return this.onClick(e) }
      if (this.variant === "switch" || this.variant === "toggle") return
      if (this.variant === "cards" && (e.key === " " || e.key === "Enter") && e.target.closest("[role=radio]")) { e.preventDefault(); return this.onClick(e) }
      const keys = {ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1}
      if (!(e.key in keys)) return
      e.preventDefault()
      const ch = this.choices()
      const next = (ch.indexOf(this.current()) + keys[e.key] + ch.length) % ch.length
      save(ch[next])
      this.items()[next].focus()
    }
    this.onTheme = () => this.sync()
    this.onMq = () => { if (this.current() === "system") { if (kept() || !this.initial()) apply("system", !!kept()); this.sync() } }
    this.el.addEventListener("click", this.onClick)
    this.el.addEventListener("keydown", this.onKey)
    window.addEventListener("ledger:theme", this.onTheme)
    mq().addEventListener("change", this.onMq)
    // `data-lu-default` (the `value` attr) is only the initial look: with nothing stored the page mode is left alone
    const chosen = kept()
    if (chosen) apply(chosen)
    else if (!this.initial()) apply("system", false)
    this.sync()
  },
  updated() { this.sync() },
  destroyed() {
    window.removeEventListener("ledger:theme", this.onTheme)
    mq().removeEventListener("change", this.onMq)
  },
  items() { return Array.from(this.el.querySelectorAll(":scope > span")) },
  choices() { return this.items().length === 3 ? ["light", "dark", "system"] : ["light", "dark"] },
  initial() { return this.el.getAttribute("data-lu-default") },
  current() { return kept() || this.initial() || "system" },
  isDark() {
    const initial = !kept() && this.initial()
    if (!initial) return document.documentElement.getAttribute("data-theme") === "dark"
    return initial === "dark" || (initial === "system" && mq().matches)
  },
  label(name, fallback) { return this.el.getAttribute(`data-lu-${name}`) || fallback },
  sync() {
    const choice = this.current()
    const dark = this.isDark()
    const el = this.el
    if (this.variant === "switch") {
      el.setAttribute("role", "switch")
      el.setAttribute("aria-checked", String(dark))
      el.setAttribute("aria-label", this.label("label", "Dark mode"))
      el.setAttribute("tabindex", "0")
      return
    }
    if (this.variant === "toggle") {
      el.setAttribute("aria-pressed", String(dark))
      return
    }
    el.setAttribute("role", "radiogroup")
    el.setAttribute("aria-label", this.label("label", "Theme"))
    const names = ["light", "dark", "system"]
    const items = this.items()
    const ch = this.choices()
    items.forEach((item, i) => {
      const on = ch[i] === choice
      item.setAttribute("role", "radio")
      item.setAttribute("aria-checked", String(on))
      item.setAttribute("aria-label", this.label(names[i], names[i]))
      item.setAttribute("tabindex", on ? "0" : "-1")
    })
  },
}
