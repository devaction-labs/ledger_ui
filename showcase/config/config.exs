import Config

config :ledger_showcase, LedgerShowcaseWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  render_errors: [formats: [html: LedgerShowcaseWeb.ErrorHTML], layout: false],
  pubsub_server: LedgerShowcase.PubSub,
  live_view: [signing_salt: "ledger-showcase-salt"]

config :phoenix, :json_library, Jason
config :logger, :default_formatter, format: "$time $metadata[$level] $message\n"

import_config "#{config_env()}.exs"
