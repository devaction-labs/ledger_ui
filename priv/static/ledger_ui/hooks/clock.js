// LedgerUI.Clock: the date and time at the end of the page header's top row, kept current.
// Locale from data-lu-locale (the browser's when absent).
export default {
  mounted() { this.tick(); this.timer = setInterval(() => this.tick(), 15000) },
  updated() { this.tick() },
  destroyed() { clearInterval(this.timer) },
  tick() {
    const locale = this.el.getAttribute("data-lu-locale") || undefined
    const now = new Date()
    const d = now.toLocaleDateString(locale, {weekday: "short", day: "numeric", month: "short"})
    const t = now.toLocaleTimeString(locale, {hour: "2-digit", minute: "2-digit"})
    this.el.textContent = `${d} · ${t}`
  },
}
