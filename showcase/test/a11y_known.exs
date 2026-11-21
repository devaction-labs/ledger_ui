# a11y/structure problems (see `LedgerShowcase.ExampleChecks.a11y/1`) still present in an example: PENDING fixes,
# same ratchet as `lu_allowlist.exs` (fixed => the entry must be removed). Never add entries for new code.
%{
  {"dropdown", 3} => [
    "<button> without accessible name",
    "<button> without accessible name",
    "<button> without accessible name"
  ],
  # component: the select/pillbox panel always renders `<button data-lu-create-row hidden>` with no text (hidden, so not exposed; ExampleChecks does not skip `hidden`)
  {"pillbox", 1} => ["<button> without accessible name"],
  {"pillbox", 2} => [
    "<button> without accessible name",
    "<button> without accessible name",
    "<button> without accessible name",
    "<button> without accessible name"
  ],
  {"select", 2} => [
    "<button> without accessible name",
    "<button> without accessible name",
    "<button> without accessible name",
    "<button> without accessible name",
    "<button> without accessible name",
    "<button> without accessible name"
  ],
  {"select", 1} => ["<button> without accessible name"],
  {"select", 3} => ["<button> without accessible name", "<button> without accessible name"],
  {"select", 5} => ["<button> without accessible name"]
}
