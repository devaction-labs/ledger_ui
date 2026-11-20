// LedgerUI.Clipboard: copy buttons.
//   data-lu-copy         text to copy
//   data-lu-copy-from    selector: a field gives its value, any other element its text
//   data-lu-toast        message shown (window event "ledger:toast") after a copy
//   data-lu-error        message when the copy fails
//   data-lu-copied-label text shown in place of .lu-copy-label for 2s
//   data-lu-on-copy      LiveView event name pushed with {id}; data-lu-target its target
//   data-lu-on-copy-js   encoded %JS{} executed after a copy
// For 2s the button is in the copied state: classes c-success v-soft and data-copied.
const COPIED_MS = 2000

async function writeText(text) {
  if (navigator.clipboard && window.isSecureContext) {
    await navigator.clipboard.writeText(text)
    return
  }
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

export default {
  mounted() {
    this.timer = null
    this.onClick = async () => {
      const el = this.el
      let text = el.getAttribute("data-lu-copy")
      const from = el.getAttribute("data-lu-copy-from")
      if (from) {
        const src = document.querySelector(from)
        if (src) text = "value" in src ? src.value : src.textContent.trim()
      }
      if (text == null) return

      try {
        await writeText(text)
      } catch (_e) {
        this.toast(el.getAttribute("data-lu-error"), "error")
        return
      }
      this.markCopied()
      this.toast(el.getAttribute("data-lu-toast"), "success")
      this.notify()
    }
    this.el.addEventListener("click", this.onClick)
  },

  toast(message, kind) {
    if (message) window.dispatchEvent(new CustomEvent("ledger:toast", {detail: {message, kind}}))
  },

  notify() {
    const el = this.el
    const event = el.getAttribute("data-lu-on-copy")
    const js = el.getAttribute("data-lu-on-copy-js")
    if (event) {
      const target = el.getAttribute("data-lu-target")
      const payload = {id: el.id}
      if (target) this.pushEventTo(/^\d+$/.test(target) ? `[data-phx-component="${target}"]` : target, event, payload)
      else this.pushEvent(event, payload)
    }
    if (js) this.liveSocket.execJS(el, js)
  },

  markCopied() {
    const el = this.el
    clearTimeout(this.timer)
    if (!el.hasAttribute("data-copied")) {
      this.saved = {
        cls: el.className,
        label: el.querySelector(".lu-copy-label")?.textContent,
      }
    }
    el.setAttribute("data-copied", "")
    el.className = el.className.replace(/\b(c|v)-\w+/g, "").trim() + " c-success v-soft"
    const label = el.querySelector(".lu-copy-label")
    const copiedLabel = el.getAttribute("data-lu-copied-label")
    if (label && copiedLabel) label.textContent = copiedLabel
    this.timer = setTimeout(() => this.reset(), COPIED_MS)
  },

  reset() {
    const el = this.el
    if (!this.saved) return
    el.removeAttribute("data-copied")
    el.className = this.saved.cls
    const label = el.querySelector(".lu-copy-label")
    if (label && this.saved.label != null) label.textContent = this.saved.label
    this.saved = null
  },

  destroyed() {
    clearTimeout(this.timer)
    this.el.removeEventListener("click", this.onClick)
  },
}
