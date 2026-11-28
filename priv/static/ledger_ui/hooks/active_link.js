// LedgerUI.ActiveLink: marks the active item of a menu on the client, so that a menu living in a
// sticky LiveView (or any menu that should not be re-sent on a route change) follows the URL
// without the server touching it.
//   data-lu-active-class    classes the active item gets (space separated)
//   data-lu-inactive-class  classes of the other items that the active one drops (optional)
//   items: [data-lu-match="/path"] inside the element; the longest match of location.pathname wins.
// A match is the path itself or a prefix on a segment boundary ("/items" matches "/items/3", not
// "/items-2"); "/" matches only the root. The active item gets aria-current="page"; the others lose it.
// Runs on mount, after every server update of the element, on `phx:page-loading-stop` (LiveView
// navigation) and on `popstate`.
const tokens = (el, name) => (el.getAttribute(name) || "").split(/\s+/).filter(Boolean)

export const matchLength = (path, match) => {
  if (!match) return -1
  if (match === "/") return path === "/" ? 1 : -1
  const m = match.length > 1 && match.endsWith("/") ? match.slice(0, -1) : match
  return path === m || path.startsWith(m + "/") ? m.length : -1
}

export default {
  mounted() {
    this.onNav = () => this.mark()
    window.addEventListener("phx:page-loading-stop", this.onNav)
    window.addEventListener("popstate", this.onNav)
    this.mark()
  },

  updated() {
    this.mark()
  },

  destroyed() {
    window.removeEventListener("phx:page-loading-stop", this.onNav)
    window.removeEventListener("popstate", this.onNav)
  },

  mark() {
    const el = this.el
    const path = window.location.pathname
    const on = tokens(el, "data-lu-active-class")
    const off = tokens(el, "data-lu-inactive-class")
    const items = [...el.querySelectorAll("[data-lu-match]")]
    let best = null
    let bestLen = -1
    for (const item of items) {
      const len = matchLength(path, item.getAttribute("data-lu-match"))
      if (len > bestLen) { best = item; bestLen = len }
    }
    for (const item of items) {
      if (item === best) {
        item.setAttribute("aria-current", "page")
        item.classList.remove(...off)
        item.classList.add(...on)
      } else {
        item.removeAttribute("aria-current")
        item.classList.remove(...on)
        item.classList.add(...off)
      }
    }
  },
}
