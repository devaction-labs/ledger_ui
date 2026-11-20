// LedgerUI.InputMask: input masks (blocks, credit_card, date, time, phone, numeral, cpf_cnpj),
// `mask_submit="raw"` (a hidden input carries the unmasked value) and `clear_on_submit`.
//
// Attributes on the <input> (set by LedgerUI.Components.Input):
//   data-lu-mask, data-lu-mask-options (JSON), data-lu-mask-raw="true", data-lu-clear-on-submit="true"


// `data-lu-*` attributes through the camelCase `dataset` API: ds(el).onChange <-> data-lu-on-change.
const ds = (el) =>
  new Proxy(el.dataset, {
    get: (t, k) => (typeof k === "string" ? t["lu" + k[0].toUpperCase() + k.slice(1)] : t[k]),
    set: (t, k, v) => { t["lu" + k[0].toUpperCase() + k.slice(1)] = v; return true },
    has: (t, k) => ("lu" + k[0].toUpperCase() + k.slice(1)) in t,
  })

const onlyDigits = (s) => (s || "").replace(/\D/g, "")
const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")

// Joins `chars` in `blocks`, putting delimiters between full blocks when more chars follow.
function joinBlocks(chars, blocks, delimiter, delimiters) {
  let out = ""
  let pos = 0
  for (let i = 0; i < blocks.length && pos < chars.length; i++) {
    out += chars.slice(pos, pos + blocks[i])
    pos += blocks[i]
    if (pos < chars.length) out += delimiters && delimiters[i] != null ? delimiters[i] : delimiter
  }
  if (pos < chars.length) out += chars.slice(pos)
  return out
}

const MASKS = {
  blocks(text, o) {
    const delimiter = o.delimiter == null ? " " : o.delimiter
    const prefix = o.prefix || ""
    let body = prefix && text.startsWith(prefix) ? text.slice(prefix.length) : text
    const dels = new Set([delimiter, ...(o.delimiters || [])].filter(Boolean))
    for (const d of dels) body = body.split(d).join("")
    if (o.numeric) body = onlyDigits(body)
    if (o.uppercase) body = body.toUpperCase()
    else if (o.lowercase) body = body.toLowerCase()
    const out = joinBlocks(body, o.blocks || [body.length], delimiter, o.delimiters)
    return { text: body ? prefix + out : "", raw: body }
  },

  credit_card(text, o) {
    const d = onlyDigits(text).slice(0, 19)
    let blocks = [4, 4, 4, 4, 3]
    if (/^3[47]/.test(d)) blocks = [4, 6, 5]
    else if (/^3(?:0[0-5]|[689])/.test(d)) blocks = [4, 6, 4]
    return { text: joinBlocks(d, blocks, o.delimiter == null ? " " : o.delimiter), raw: d }
  },

  date(text, o) {
    const pattern = o.pattern || ["d", "m", "Y"]
    return fixedParts(text, pattern, o.delimiter == null ? "/" : o.delimiter, {
      d: [2, 31], m: [2, 12], y: [2, 99], Y: [4, 9999],
    })
  },

  time(text, o) {
    const pattern = o.pattern || ["h", "m", "s"]
    return fixedParts(text, pattern, o.delimiter == null ? ":" : o.delimiter, {
      h: [2, 23], m: [2, 59], s: [2, 59],
    })
  },

  phone(text, o) {
    const d = onlyDigits(text)
    return {
      text: joinBlocks(d, o.blocks || [3, 3, 4], o.delimiter == null ? " " : o.delimiter),
      raw: d,
    }
  },

  cpf_cnpj(text) {
    const d = onlyDigits(text).slice(0, 14)
    let out = ""
    if (d.length <= 11) {
      for (let i = 0; i < d.length; i++) {
        out += d[i]
        if ((i === 2 || i === 5) && i < d.length - 1) out += "."
        if (i === 8 && i < d.length - 1) out += "-"
      }
    } else {
      for (let i = 0; i < d.length; i++) {
        out += d[i]
        if ((i === 1 || i === 4) && i < d.length - 1) out += "."
        if (i === 7 && i < d.length - 1) out += "/"
        if (i === 11 && i < d.length - 1) out += "-"
      }
    }
    return { text: out, raw: d }
  },

  numeral(text, o) {
    const delimiter = o.delimiter == null ? "," : o.delimiter
    const mark = o.decimal_mark == null ? "." : o.decimal_mark
    const decimals = o.decimals == null ? 2 : o.decimals
    const prefix = o.prefix || ""
    let body = prefix && text.startsWith(prefix) ? text.slice(prefix.length) : text
    const neg = !o.positive && body.trim().startsWith("-")
    const at = decimals > 0 ? body.indexOf(mark) : -1
    let int = onlyDigits(at >= 0 ? body.slice(0, at) : body)
    let dec = at >= 0 ? onlyDigits(body.slice(at + mark.length)).slice(0, decimals) : null
    int = int.replace(/^0+(?=\d)/, "")
    if (!int && dec === null && !neg) return { text: "", raw: "" }
    const grouped = group(int || (dec !== null ? "0" : ""), o.thousands || "thousand", delimiter)
    const text2 = (neg ? "-" : "") + prefix + grouped + (dec !== null ? mark + dec : "")
    const raw = (neg ? "-" : "") + (int || "0") + (dec ? "." + dec : "")
    return { text: int || dec !== null ? text2 : neg ? "-" : "", raw: int || dec ? raw : "" }
  },
}

function group(int, style, delimiter) {
  if (style === "none") return int
  if (style === "lakh") return int.replace(/(\d)(?=(\d\d)+\d$)/g, "$1" + delimiter)
  if (style === "wan") return int.replace(/(\d)(?=(\d{4})+$)/g, "$1" + delimiter)
  return int.replace(/\B(?=(\d{3})+(?!\d))/g, delimiter)
}

// Fixed-width numeric parts (date, time) with a per-part maximum.
function fixedParts(text, pattern, delimiter, spec) {
  const total = pattern.reduce((n, p) => n + spec[p][0], 0)
  const d = onlyDigits(text).slice(0, total)
  let pos = 0
  let out = ""
  let raw = ""
  for (let i = 0; i < pattern.length && pos < d.length; i++) {
    const [len, max] = spec[pattern[i]]
    let part = d.slice(pos, pos + len)
    if (part.length === len && Number(part) > max) part = String(max).padStart(len, "0")
    out += part
    raw += part
    pos += len
    if (pos < d.length) out += delimiter
  }
  return { text: out, raw }
}

export default {
  mounted() {
    this.type = ds(this.el).mask
    this.opts = this.parse(ds(this.el).mask)
    this.rawMode = ds(this.el).maskRaw === "true"
    this.prev = this.el.value
    this.hidden = this.rawMode ? this.findHidden() : null
    this.lastRaw = this.hidden ? this.hidden.value : null

    this.onInput = (e) => this.handleInput(e)
    this.el.addEventListener("input", this.onInput)

    if (ds(this.el).clearOnSubmit === "true" && this.el.form) {
      this.form = this.el.form
      this.onSubmit = () => { this.cleared = true }
      this.form.addEventListener("submit", this.onSubmit, true)
    }

    if (this.type) this.reformat(false)
  },

  updated() {
    this.type = ds(this.el).mask
    this.opts = this.parse(ds(this.el).mask)
    if (this.cleared) {
      // The first render after the form's submit: the server's value wins, even while focused.
      this.cleared = false
      this.el.value = this.el.getAttribute("value") || ""
    }
    if (this.rawMode) this.hidden = this.findHidden()
    if (this.type && document.activeElement !== this.el) this.reformat(false)
    else if (this.hidden) this.syncHidden(this.type ? MASKS[this.type]?.(this.el.value, this.opts)?.raw : this.el.value, false)
    this.prev = this.el.value
  },

  destroyed() {
    this.el.removeEventListener("input", this.onInput)
    if (this.form) this.form.removeEventListener("submit", this.onSubmit, true)
  },

  parse() {
    try { return JSON.parse(ds(this.el).maskOptions || "{}") } catch (_e) { return {} }
  },

  findHidden() {
    const box = this.el.parentElement
    return box ? box.querySelector('input[type="hidden"]') : null
  },

  handleInput(e) {
    if (this.type && MASKS[this.type]) {
      const deleting = e.inputType === "deleteContentBackward"
      this.reformat(true, deleting)
    } else if (this.hidden) {
      this.syncHidden(this.el.value, true)
    }
    // With a hidden input the hidden one announces the change; the masked text stays silent.
    if (this.rawMode) e.stopPropagation()
    this.prev = this.el.value
  },

  reformat(keepCaret, deleting = false) {
    const mask = MASKS[this.type]
    if (!mask) return
    const el = this.el
    const sig = (s) => (this.type === "numeral" ? s.replace(/[^\d]/g, "") : s.replace(/[^0-9a-z]/gi, ""))
    const caret = el.selectionStart
    const hadFocus = document.activeElement === el
    let before = keepCaret && caret != null ? sig(el.value.slice(0, caret)).length : null

    let { text, raw } = mask(el.value, this.opts)

    // Backspace over a delimiter changes nothing; remove the character before it instead.
    if (deleting && text === this.prev && before) {
      before -= 1
      const chars = el.value.replace(/[^0-9a-z]/gi, "")
      ;({ text, raw } = mask(chars.slice(0, before) + chars.slice(before + 1), this.opts))
    }

    if (el.value !== text) el.value = text
    if (before !== null && hadFocus) {
      let pos = 0
      let seen = 0
      while (pos < text.length && seen < before) {
        if (sig(text[pos]).length) seen++
        pos++
      }
      el.setSelectionRange(pos, pos)
    }
    if (this.hidden) this.syncHidden(raw, true)
  },

  syncHidden(raw, announce) {
    if (!this.hidden) return
    raw = raw == null ? "" : raw
    if (this.hidden.value !== raw) this.hidden.value = raw
    if (announce && this.lastRaw !== raw) {
      this.lastRaw = raw
      this.hidden.dispatchEvent(new Event("input", { bubbles: true }))
    }
    this.lastRaw = raw
  },
}
