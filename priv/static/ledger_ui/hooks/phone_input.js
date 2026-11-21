// LedgerUI.PhoneInput: country picker, national formatting while typing, E.164 in a hidden input.
//
// Root attributes (LedgerUI.Components.PhoneInput): data-lu-country, data-lu-flags, data-lu-value (E.164),
// data-lu-on-country-change, data-lu-target, data-lu-no-results. The picker rows carry data-lu-iso, data-lu-dial,
// data-lu-areas, data-lu-main, data-lu-trunk, data-lu-formats ("|"-separated), data-lu-flag, data-lu-search.


// `data-lu-*` attributes through the camelCase `dataset` API: ds(el).onChange <-> data-lu-on-change.
const ds = (el) =>
  new Proxy(el.dataset, {
    get: (t, k) => (typeof k === "string" ? t["lu" + k[0].toUpperCase() + k.slice(1)] : t[k]),
    set: (t, k, v) => { t["lu" + k[0].toUpperCase() + k.slice(1)] = v; return true },
    has: (t, k) => ("lu" + k[0].toUpperCase() + k.slice(1)) in t,
  })

const digitsOf = (s) => (s || "").replace(/\D/g, "")
const fold = (s) => (s || "").normalize("NFD").replace(/\p{Mn}/gu, "").toLowerCase()

function format(digits, country) {
  const formats = country.formats
  const pattern = formats.find((p) => (p.match(/#/g) || []).length >= digits.length) || formats[formats.length - 1]
  let out = ""
  let lits = ""
  let di = 0
  for (const ch of pattern) {
    if (di >= digits.length) break
    if (ch === "#") { out += lits + digits[di++]; lits = "" } else lits += ch
  }
  return out + digits.slice(di)
}

export default {
  mounted() {
    this.q = (s) => this.el.querySelector(s)
    this.number = this.q("[data-lu-phone-number]")
    this.hidden = this.q("[data-lu-phone-value]")
    this.picker = this.q("[data-lu-phone-picker]")
    this.pop = this.q("[data-lu-phone-pop]")
    this.search = this.q("[data-lu-phone-search]")
    this.clearBtn = this.q("[data-lu-phone-clear]")
    this.readCountries()
    this.iso = ds(this.el).country
    this.serverValue = ds(this.el).value || ""
    this.digits = digitsOf(this.number.value)
    this.digits = this.strip(this.digits, this.country())
    this.lastE164 = this.hidden.value
    this.hl = -1

    this.on(this.number, "input", (e) => this.onNumber(e))
    this.on(this.picker, "click", () => this.toggle())
    this.on(this.picker, "keydown", (e) => {
      if (["Enter", " ", "ArrowDown"].includes(e.key)) { e.preventDefault(); this.open() }
    })
    this.on(this.search, "input", (e) => { e.stopPropagation(); this.filter() })
    this.on(this.search, "keydown", (e) => this.onSearchKey(e))
    this.on(this.pop, "click", (e) => {
      const row = e.target.closest("[data-lu-iso]")
      if (row) this.choose(ds(row).iso)
    })
    this.on(document, "mousedown", (e) => { if (!this.el.contains(e.target)) this.close(false) })
    if (this.clearBtn) this.on(this.clearBtn, "click", () => this.clear())
    this.renderCountry()
    this.renderNumber()
  },

  updated() {
    const server = ds(this.el).value || ""
    if (server !== this.serverValue) {
      // A new value from the server wins over the browser's.
      this.serverValue = server
      this.iso = ds(this.el).country
      const found = server ? this.detect(digitsOf(server)) : null
      if (found) { this.iso = found.c.iso; this.digits = found.national } else this.digits = server ? digitsOf(server) : ""
      this.lastE164 = this.e164()
    }
    this.renderCountry()
    this.renderNumber()
    this.hidden.value = this.e164()
  },

  destroyed() {
    for (const [el, ev, fn] of this.handlers || []) el.removeEventListener(ev, fn)
  },

  on(el, ev, fn) {
    el.addEventListener(ev, fn)
    ;(this.handlers = this.handlers || []).push([el, ev, fn])
  },

  readCountries() {
    this.rows = Array.from(this.pop.querySelectorAll("[data-lu-iso]"))
    this.countries = this.rows.map((el) => ({
      el,
      iso: ds(el).iso,
      dial: ds(el).dial,
      areas: ds(el).areas ? ds(el).areas.split(",") : [],
      main: ds(el).main === "true",
      trunk: ds(el).trunk || "",
      formats: (ds(el).formats || "###").split("|"),
      flag: ds(el).flag,
      search: ds(el).search || "",
    }))
  },

  country() { return this.countries.find((c) => c.iso === this.iso) || this.countries[0] },
  strip(d, c) { return c.trunk && d.startsWith(c.trunk) ? d.slice(c.trunk.length) : d },
  e164() { return this.digits ? "+" + this.country().dial + this.digits : "" },

  // Country of `digits` (calling code + number): the longest code wins, shared codes are told
  // apart by area code, then by the main country of the code.
  detect(digits) {
    const cands = this.countries.filter((c) => digits.startsWith(c.dial))
    if (!cands.length) return null
    const longest = Math.max(...cands.map((c) => c.dial.length))
    const same = cands.filter((c) => c.dial.length === longest)
    const national = digits.slice(longest)
    const c = same.find((x) => x.areas.some((a) => national.startsWith(a))) || same.find((x) => x.main) || same[0]
    return { c, national: this.strip(national, c) }
  },

  onNumber(e) {
    e.stopPropagation() // the hidden input announces the change, not the formatted text
    const el = this.number
    const caret = el.selectionStart
    const sigBefore = digitsOf(el.value.slice(0, caret)).length
    const raw = el.value.trim()

    if (raw.startsWith("+") || raw.startsWith("00")) {
      const all = digitsOf(raw)
      const found = this.detect(raw.startsWith("00") ? all.slice(2) : all)
      if (found) {
        if (found.c.iso !== this.iso) this.setCountry(found.c.iso, false)
        this.digits = found.national
      } else {
        this.digits = all
      }
    } else {
      this.digits = this.strip(digitsOf(raw), this.country())
    }
    this.renderNumber(sigBefore)
    this.commit()
  },

  renderNumber(sigBefore) {
    const text = this.digits ? format(this.digits, this.country()) : ""
    const el = this.number
    if (el.value !== text) el.value = text
    if (sigBefore != null && document.activeElement === el) {
      let pos = 0
      let seen = 0
      while (pos < text.length && seen < sigBefore) { if (/\d/.test(text[pos])) seen++; pos++ }
      el.setSelectionRange(pos, pos)
    }
    if (this.clearBtn) this.clearBtn.hidden = !this.digits
  },

  renderCountry() {
    const c = this.country()
    ds(this.el).country = c.iso
    const iso = this.picker.querySelector("[data-lu-phone-iso]")
    const dial = this.picker.querySelector("[data-lu-phone-dial]")
    const flags = ds(this.el).flags === "true"
    if (iso) iso.textContent = flags ? c.flag : c.iso
    if (dial) dial.textContent = "+" + c.dial
    for (const row of this.countries) {
      const sel = row.iso === c.iso
      row.el.setAttribute("aria-selected", String(sel))
    }
  },

  commit() {
    const value = this.e164()
    this.hidden.value = value
    if (value !== this.lastE164) {
      this.lastE164 = value
      this.hidden.dispatchEvent(new Event("input", { bubbles: true }))
    }
  },

  setCountry(iso, reformat = true) {
    if (iso === this.iso) return
    this.iso = iso
    this.renderCountry()
    if (reformat) { this.renderNumber(); this.commit() }
    const d = ds(this.el)
    if (d.onCountryChange) {
      const c = this.country()
      const payload = { id: this.number.id, country: c.iso, code: c.dial }
      if (d.target) this.pushEventTo(d.target, d.onCountryChange, payload)
      else this.pushEvent(d.onCountryChange, payload)
    }
  },

  clear() {
    this.digits = ""
    this.renderNumber()
    this.commit()
    this.number.focus()
  },

  // -- picker ------------------------------------------------------------------------------
  toggle() { this.pop.hidden ? this.open() : this.close(true) },

  open() {
    if (this.number.disabled) return
    this.pop.hidden = false
    this.picker.setAttribute("aria-expanded", "true")
    this.search.value = ""
    this.filter()
    this.search.focus()
  },

  close(refocus) {
    if (this.pop.hidden) return
    this.pop.hidden = true
    this.picker.setAttribute("aria-expanded", "false")
    if (refocus) this.picker.focus()
  },

  visible() { return this.rows.filter((r) => !r.hidden) },

  filter() {
    const q = fold(this.search.value).trim().replace(/^\+/, "")
    for (const c of this.countries) c.el.hidden = q !== "" && !c.search.includes(q)
    const vis = this.visible()
    const empty = this.q("[data-lu-phone-empty]")
    if (empty) {
      empty.hidden = vis.length > 0
      const tpl = ds(this.el).noResults || ""
      empty.textContent = tpl.replace("%{query}", this.search.value)
    }
    const sel = vis.findIndex((r) => r.getAttribute("aria-selected") === "true")
    this.highlight(sel >= 0 ? sel : 0)
  },

  highlight(i) {
    const vis = this.visible()
    vis.forEach((r) => r.removeAttribute("data-hl"))
    if (!vis.length) { this.hl = -1; return }
    this.hl = Math.max(0, Math.min(vis.length - 1, i))
    vis[this.hl].setAttribute("data-hl", "")
    vis[this.hl].scrollIntoView({ block: "nearest" })
  },

  onSearchKey(e) {
    if (e.key === "ArrowDown") { e.preventDefault(); this.highlight(this.hl + 1) }
    else if (e.key === "ArrowUp") { e.preventDefault(); this.highlight(this.hl - 1) }
    else if (e.key === "Enter") {
      e.preventDefault()
      const row = this.visible()[this.hl]
      if (row) this.choose(ds(row).iso)
    } else if (e.key === "Escape") { e.preventDefault(); e.stopPropagation(); this.close(true) }
  },

  choose(iso) {
    this.setCountry(iso)
    this.close(false)
    this.number.focus()
  },
}
