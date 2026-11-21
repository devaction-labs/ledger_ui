import Config

config :ledger_showcase, LedgerShowcaseWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "4100"))],
  check_origin: false,
  debug_errors: true,
  code_reloader: true,
  reloadable_apps: [:ledger_showcase, :ledger_ui],
  watchers: [tailwind: {Tailwind, :install_and_run, [:ledger_showcase, ~w(--watch)]}],
  secret_key_base:
    "ledger-showcase-dev-secret-key-base-ledger-showcase-dev-secret-key-base-0123456789"

config :phoenix, :stacktrace_depth, 20
config :phoenix_live_view, debug_heex_annotations: false
