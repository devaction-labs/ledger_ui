// Delegated listeners of `error_page/1`: they work on a plain page with no LiveSocket and no hook, and
// they need no inline handler (the page can have a CSP without `unsafe-inline`). Imported for its side
// effect by ledger_ui.esm.js, so loading the kit's module is enough.
//
//   [data-lu-back]       click goes back in the history when there is a page to go back to; else the
//                        element is a plain link (href), which is what it is without JS.
//   [data-lu-error-copy] click copies the attribute's value (the request id); for 2s the button has
//                        data-copied. Without JS it stays hidden: `<html>` gets data-lu-js here, and the
//                        button is hidden until it is there.
const COPIED_MS = 2000

async function writeText(text) {
  if (navigator.clipboard && window.isSecureContext) return navigator.clipboard.writeText(text)
  const area = document.createElement("textarea")
  area.value = text
  area.setAttribute("readonly", "")
  area.style.cssText = "position:fixed;top:0;left:0;opacity:0"
  document.body.appendChild(area)
  area.select()
  const ok = document.execCommand("copy")
  area.remove()
  if (!ok) throw new Error("copy failed")
}

export function onClick(e) {
  const t = e.target
  if (!t || !t.closest) return
  const back = t.closest("[data-lu-back]")
  if (back && history.length > 1) {
    e.preventDefault()
    history.back()
    return
  }
  const copy = t.closest("[data-lu-error-copy]")
  if (copy) {
    e.preventDefault()
    writeText(copy.getAttribute("data-lu-error-copy") || "").then(
      () => {
        copy.setAttribute("data-copied", "")
        setTimeout(() => copy.removeAttribute("data-copied"), COPIED_MS)
      },
      () => {},
    )
  }
}

if (typeof document !== "undefined" && !window.__luErrorPage) {
  window.__luErrorPage = true
  document.documentElement.setAttribute("data-lu-js", "")
  document.addEventListener("click", onClick)
}
