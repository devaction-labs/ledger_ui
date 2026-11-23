// Browser cache of server searches for the autocomplete and select hooks (#75).
//
// The cache keeps, per search text, a detached copy of the option rows the server rendered for it
// (a small LRU, alive while the hook is mounted). Showing a cached answer appends clones to the
// LiveView-owned list, marked `data-lu-cached`; the hook hides the server rows meanwhile, and removes
// the clones when the push reply arrives. A patch that lands in between may morph or drop the clones,
// which is harmless: the reply handler always removes what is left and the server rows are the truth.

export class Lru {
  constructor(max = 20) {
    this.max = max
    this.map = new Map()
  }

  get size() { return this.map.size }
  has(key) { return this.map.has(key) }

  get(key) {
    if (!this.map.has(key)) return undefined
    const v = this.map.get(key)
    this.map.delete(key)
    this.map.set(key, v)
    return v
  }

  set(key, value) {
    this.map.delete(key)
    this.map.set(key, value)
    if (this.map.size > this.max) this.map.delete(this.map.keys().next().value)
  }
}

export const isClone = (n) => !!n.dataset && "luCached" in n.dataset

const bare = (n) => {
  const c = n.cloneNode(true)
  for (const x of [c, ...c.querySelectorAll("[id],[data-hl]")]) {
    x.removeAttribute("id")
    x.removeAttribute("data-hl")
  }
  c.hidden = false
  c.style.display = ""
  return c
}

// The server rows of `list` (the clones are not the server's), as detached copies.
export const snapshot = (list) => [...list.children].filter((n) => !isClone(n)).map(bare)

export const dropClones = (list) => {
  for (const n of [...list.children]) if (isClone(n)) n.remove()
}

export const hasClones = (list) => [...list.children].some(isClone)

export const showClones = (list, snap) => {
  dropClones(list)
  for (const s of snap) {
    const c = s.cloneNode(true)
    c.dataset.luCached = ""
    list.appendChild(c)
  }
}
