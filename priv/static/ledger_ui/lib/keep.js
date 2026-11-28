// What the client decided survives a LiveView patch, with no `dom: {onBeforeElUpdated}` in the
// LiveSocket: thin wrappers over the LiveView 1.2 hook API (`this.js()`).
//
// - `keep(hook, els, attrs)`: `ignoreAttributes`. The patch leaves these attributes of `els` as the
//   client has them (a `*` matches any, like `JS.ignore_attributes`). For state the hook writes with
//   plain DOM calls (a position in `style`, `hidden`, `popover`).
// - `stickAttr(hook, el, name, value)`: `setAttribute`/`removeAttribute` of `js()`: applied now and
//   again after every patch ("sticky"). `null`/`false`/`undefined` removes the attribute, `true` sets "".
// - `stickClass(hook, el, name, on)`: `addClass`/`removeClass` of `js()`: sticky too, but LiveView applies
//   it in the next animation frame, so a hook that reads the class back (a MutationObserver) sees it then.
//
// Everything that changes an attribute or class a `LedgerUI.open/close` or a `JS.*` command also
// changes has to go through the same API, or the sticky list of the element still holds the old value
// and the next patch undoes the change. A hook with no `js()` (tests, previews, an old LiveView) gets
// the plain DOM call.
const jsOf = (hook) => (hook && typeof hook.js === "function" ? hook.js() : null)

export function keep(hook, target, attrs) {
  const js = jsOf(hook)
  if (!js || !target) return
  if (target.nodeType) js.ignoreAttributes(target, attrs)
  else for (const el of target) js.ignoreAttributes(el, attrs)
}

export function stickAttr(hook, el, name, value) {
  if (!el) return
  const js = jsOf(hook)
  const off = value == null || value === false
  if (js) off ? js.removeAttribute(el, name) : js.setAttribute(el, name, value === true ? "" : String(value))
  else if (off) el.removeAttribute(name)
  else el.setAttribute(name, value === true ? "" : String(value))
}

// What stickClass asked for and LiveView has not applied yet (it waits for the next frame): a second
// call in between compares with that, not with the class the element still has.
const pending = new WeakMap()

function classWanted(el, name) {
  const m = pending.get(el)
  return m && m.has(name) ? m.get(name) : el.classList.contains(name)
}

// Does nothing when the element already is (or is about to be) as asked: a hook that calls this from a
// MutationObserver on `class` must not start over each time LiveView rewrites the class.
export function stickClass(hook, el, name, on) {
  if (!el) return
  if (classWanted(el, name) === on) return
  const js = jsOf(hook)
  if (!js) return void el.classList.toggle(name, on)
  let m = pending.get(el)
  if (!m) pending.set(el, (m = new Map()))
  m.set(name, on)
  const done = () => {
    if (m.get(name) === on) m.delete(name)
  }
  on ? js.addClass(el, name) : js.removeClass(el, name)
  // registered after LiveView's own frame callback, so it runs once the class is applied
  typeof requestAnimationFrame === "function" ? requestAnimationFrame(done) : done()
}
