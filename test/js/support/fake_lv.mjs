// A stand-in for the part of the LiveView 1.2 client the hooks rely on to survive a patch, so the
// jsdom tests can say "the server re-rendered this" without a LiveSocket. It follows
// deps/phoenix_live_view/assets/js/phoenix_live_view/{js.js,dom.ts,js_commands.ts}:
//   - `ignoreAttributes(el, attrs)`: on a patch the old element's attributes named in `attrs`
//     (curinga `*` included) are copied to the new one, and the ones it does not have are removed;
//   - `setAttribute`/`removeAttribute`: sticky, applied now and again to the new element;
//   - `addClass`/`removeClass`: sticky (LiveView runs them in a requestAnimationFrame; here they
//     run at once, the tests that care use `rafClasses`).
// `patch(from, to)` morphs `from` into `to` the way morphdom does (attributes, children by index),
// running those rules for every element pair, and returns `from`.
export function fakeLV() {
  const priv = new WeakMap()
  const get = (el) => {
    let p = priv.get(el)
    if (!p) priv.set(el, (p = {ignore: null, sets: [], removes: [], adds: [], rms: []}))
    return p
  }
  const ignored = (name, attrs) => attrs.some((a) => name === a || a === "*" || (a.includes("*") && name.match(a) != null))

  // two separate sticky operations, like LiveView's "attrs" and "classes"
  const applyAttrs = (el, p) => {
    for (const n of p.removes) el.removeAttribute(n)
    for (const [n, v] of p.sets) el.setAttribute(n, v)
  }
  const applyClasses = (el, p) => {
    el.classList.remove(...p.rms)
    el.classList.add(...p.adds)
  }
  const applySticky = (el, p) => {
    applyAttrs(el, p)
    applyClasses(el, p)
  }

  const api = {
    ignoreAttributes(el, attrs) {
      get(el).ignore = Array.isArray(attrs) ? attrs : [attrs]
    },
    setAttribute(el, name, val) {
      const p = get(el)
      p.sets = p.sets.filter(([n]) => n !== name).concat([[name, val]])
      p.removes = p.removes.filter((n) => n !== name)
      applyAttrs(el, p)
    },
    removeAttribute(el, name) {
      const p = get(el)
      p.sets = p.sets.filter(([n]) => n !== name)
      p.removes = p.removes.filter((n) => n !== name).concat([name])
      applyAttrs(el, p)
    },
    addClass(el, names) {
      const list = Array.isArray(names) ? names : names.split(" ")
      const p = get(el)
      p.rms = p.rms.filter((n) => !list.includes(n))
      p.adds = p.adds.filter((n) => !list.includes(n)).concat(list)
      applyClasses(el, p)
    },
    removeClass(el, names) {
      const list = Array.isArray(names) ? names : names.split(" ")
      const p = get(el)
      p.adds = p.adds.filter((n) => !list.includes(n))
      p.rms = p.rms.filter((n) => !list.includes(n)).concat(list)
      applyClasses(el, p)
    },
  }

  function morphEl(from, to) {
    const p = priv.get(from)
    if (p) {
      if (p.ignore) {
        const fromNames = Array.from(from.attributes).map((a) => a.name)
        for (const a of Array.from(to.attributes)) if (!fromNames.includes(a.name) && ignored(a.name, p.ignore)) to.removeAttribute(a.name)
        for (const a of Array.from(from.attributes)) if (ignored(a.name, p.ignore)) to.setAttribute(a.name, a.value)
      }
      applySticky(to, p)
    }
    for (const a of Array.from(from.attributes)) if (!to.hasAttribute(a.name)) from.removeAttribute(a.name)
    for (const a of Array.from(to.attributes)) if (from.getAttribute(a.name) !== a.value) from.setAttribute(a.name, a.value)
    const fc = Array.from(from.children)
    const tc = Array.from(to.children)
    tc.forEach((t, i) => (fc[i] ? morphEl(fc[i], t) : from.appendChild(t)))
    fc.slice(tc.length).forEach((c) => c.remove())
  }

  return {
    // what `this.js()` returns inside a hook
    js: () => api,
    // a hook instance with `js()` wired to this LiveView
    hook: (hook, el, extra = {}) => Object.assign(Object.create(hook), {el, pushEvent() {}, pushEventTo() {}, js: () => api, ...extra}),
    // the server re-rendered `from` as `to` (an element): morph, then the caller runs `hook.updated()`
    patch(from, to) {
      morphEl(from, to)
      return from
    },
  }
}
