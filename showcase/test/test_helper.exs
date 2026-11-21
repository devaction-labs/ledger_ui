# Tests tagged `:design` read the design data (private repo `ledger_ui_design`, see
# `LedgerShowcase.Design`): they are excluded when it is not there.
if LedgerShowcase.Design.available?() do
  ExUnit.start()
else
  IO.puts(:stderr, "warning: " <> LedgerShowcase.Design.missing_message())
  ExUnit.start(exclude: [:design])
end
