// lazyHook(() => import("ledger_ui/hooks/chart")): a LiveView hook that loads the real hook on mount.
//
//   import {Hooks, lazyHook} from "ledger_ui/core"
//   const hooks = {...Hooks, "LedgerUI.Chart": lazyHook(() => import("ledger_ui/hooks/chart"))}
//
// With esbuild `splitting: true, format: "esm"` the hook becomes its own chunk, fetched on first use. With the
// default Phoenix setup (iife, no splitting) esbuild inlines the import(): it works the same, there is just no
// saving. Until the import resolves the hook queues `disconnected`/`reconnected`/`destroyed`; `updated` needs no
// replay (the real `mounted` reads the current DOM). If the element is destroyed first, the hook never mounts.
export default function lazyHook(load) {
  return {
    mounted() {
      const state = (this.__lazy = {dead: false, offline: false})
      Promise.resolve()
        .then(load)
        .then((mod) => {
          if (state.dead) return
          const real = mod && mod.default !== undefined ? mod.default : mod
          for (const key of Object.keys(real)) this[key] = real[key]
          this.__lazy = null
          if (this.mounted) this.mounted()
          if (state.offline && this.disconnected) this.disconnected()
        })
        .catch((err) => console.error("[ledger_ui] lazyHook: failed to load the hook", err))
    },
    updated() {},
    disconnected() { if (this.__lazy) this.__lazy.offline = true },
    reconnected() { if (this.__lazy) this.__lazy.offline = false },
    destroyed() { if (this.__lazy) this.__lazy.dead = true },
  }
}
