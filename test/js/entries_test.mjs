// The package entries: "." (every hook), "ledger_ui/core" (without the heavy ones) and "hooks/*".
//   node --test test/js/entries_test.mjs
import {test} from "node:test"
import assert from "node:assert/strict"
import {readdirSync} from "node:fs"
import {dirname, join} from "node:path"
import {fileURLToPath, pathToFileURL} from "node:url"

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..")
const entry = (rel) => import(pathToFileURL(join(root, rel)).href)
const camel = (base) => base.split(/[_-]/).filter(Boolean).map((w) => w[0].toUpperCase() + w.slice(1)).join("")
const files = readdirSync(join(root, "priv/static/ledger_ui/hooks")).filter((f) => f.endsWith(".js")).map((f) => f.slice(0, -3))
const HEAVY = ["chart", "donut_chart", "text_editor", "flow", "signature_pad", "phone_input", "color_picker", "code_block", "calendar"]

test("package.json exports the entries", async () => {
  const pkg = JSON.parse(await import("node:fs").then((fs) => fs.readFileSync(join(root, "package.json"), "utf8")))
  assert.equal(pkg.exports["."].import, "./priv/static/ledger_ui.esm.js")
  assert.equal(pkg.exports["./core"].import, "./priv/static/ledger_ui_core.esm.js")
  assert.equal(pkg.exports["./hooks/*"].import, "./priv/static/ledger_ui/hooks/*.js")
})

test(`"." registers one hook per file in hooks/`, async () => {
  const {Hooks, DOM, default: def} = await entry("priv/static/ledger_ui.esm.js")
  assert.deepEqual(Object.keys(Hooks).sort(), files.map((f) => `LedgerUI.${camel(f)}`).sort())
  assert.equal(typeof DOM.onBeforeElUpdated, "function")
  assert.equal(def.Hooks, Hooks)
})

test(`"core" is a subset of "." without the heavy hooks, same DOM`, async () => {
  const all = await entry("priv/static/ledger_ui.esm.js")
  const core = await entry("priv/static/ledger_ui_core.esm.js")
  assert.equal(core.DOM, all.DOM)
  const names = Object.keys(core.Hooks)
  assert.ok(names.length > 30 && names.length < Object.keys(all.Hooks).length)
  for (const n of names) assert.equal(core.Hooks[n], all.Hooks[n], n)
  for (const h of HEAVY) assert.ok(!(`LedgerUI.${camel(h)}` in core.Hooks), h)
  for (const h of ["dropdown", "select", "toaster", "shell", "sidebar"]) assert.ok(`LedgerUI.${camel(h)}` in core.Hooks, h)
})

test("hooks/* are importable alone and are the same objects as in Hooks", async () => {
  const {Hooks} = await entry("priv/static/ledger_ui.esm.js")
  for (const h of ["chart", "phone_input", "text_editor", "dropdown"]) {
    const mod = await entry(`priv/static/ledger_ui/hooks/${h}.js`)
    assert.equal(mod.default, Hooks[`LedgerUI.${camel(h)}`], h)
  }
})

test("lazyHook mounts the real hook once loaded and replays disconnected", async () => {
  const {lazyHook} = await entry("priv/static/ledger_ui_core.esm.js")
  const calls = []
  let resolve
  const real = {mounted() { calls.push("mounted") }, destroyed() { calls.push("destroyed") }, disconnected() { calls.push("disconnected") }, extra() { return 1 }}
  const hook = lazyHook(() => new Promise((r) => (resolve = r)))
  const inst = Object.assign(Object.create(null), hook)
  inst.mounted()
  inst.updated()
  inst.disconnected()
  await new Promise((r) => setTimeout(r, 1))
  resolve({default: real})
  await new Promise((r) => setTimeout(r, 5))
  assert.deepEqual(calls, ["mounted", "disconnected"])
  assert.equal(inst.extra(), 1)
  inst.destroyed()
  assert.deepEqual(calls, ["mounted", "disconnected", "destroyed"])

  const early = Object.assign({}, lazyHook(() => Promise.resolve({default: real})))
  calls.length = 0
  early.mounted()
  early.destroyed()
  await new Promise((r) => setTimeout(r, 5))
  assert.deepEqual(calls, [])
})

test(`"ledger_ui/hooks/upload" still resolves through package.json exports (no-op kept for compatibility)`, async () => {
  const resolved = import.meta.resolve("ledger_ui/hooks/upload")
  assert.ok(resolved.endsWith("/priv/static/ledger_ui/hooks/upload.js"), resolved)
  const mod = await import("ledger_ui/hooks/upload")
  const {Hooks} = await entry("priv/static/ledger_ui.esm.js")
  assert.equal(mod.default, Hooks["LedgerUI.Upload"])
  const hook = Object.create(mod.default)
  assert.doesNotThrow(() => hook.mounted())
  assert.equal(Object.keys(mod.default).join(), "mounted")
})
