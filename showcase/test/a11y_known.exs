# a11y/structure problems (see `LedgerShowcase.ExampleChecks.a11y/1`) still present in an example: PENDING fixes,
# same ratchet as `lu_allowlist.exs` (fixed => the entry must be removed). Never add entries for new code.
%{
  {"dropdown", 3} => [
    "<button> without accessible name",
    "<button> without accessible name",
    "<button> without accessible name"
  ],
  {"pillbox", 2} => ["<button> without accessible name"],
  {"select", 2} => [
    "<button> without accessible name",
    "<button> without accessible name",
    "<button> without accessible name",
    "<button> without accessible name",
    "<button> without accessible name",
    "<button> without accessible name"
  ],
  {"select", 3} => ["<button> without accessible name"],
  {"select", 5} => ["<button> without accessible name", "<button> without accessible name"],
  {"tags-input", 2} => ["<button> without accessible name"]
}
