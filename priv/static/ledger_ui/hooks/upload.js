// LedgerUI.Upload: kept ONLY for compatibility. It does nothing.
// The drag-over state of <.upload> now comes from LiveView's own `phx-drop-target-active` class
// (the component styles it with `[&.phx-drop-target-active]`), so no hook is needed. Apps that still
// `import Upload from "ledger_ui/hooks/upload"` or read `Hooks["LedgerUI.Upload"]` keep working.
export default {
  mounted() {},
}
