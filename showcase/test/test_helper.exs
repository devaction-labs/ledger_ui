LedgerShowcase.Canvas.load!()
LedgerShowcase.Parity.init_results()

# `mix test test/parity_test.exs` prints a per-id summary: passing/total and reference source.
ExUnit.after_suite(fn _ -> LedgerShowcase.ParityReport.print_summary() end)

ExUnit.start(exclude: [parity_status: true])
