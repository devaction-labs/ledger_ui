import Config

config :ledger_showcase, LedgerShowcaseWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4101],
  server: false,
  secret_key_base:
    "ledger-showcase-test-secret-key-base-ledger-showcase-test-secret-key-base-0123456789"

config :logger, level: :warning
