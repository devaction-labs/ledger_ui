import Config

config :ledger_showcase, LedgerShowcaseWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  render_errors: [formats: [html: LedgerShowcaseWeb.ErrorHTML], layout: false],
  pubsub_server: LedgerShowcase.PubSub,
  live_view: [signing_salt: "ledger-showcase-salt"]

config :phoenix, :json_library, Jason
config :logger, :default_formatter, format: "$time $metadata[$level] $message\n"

# Tailwind v4 (standalone binary). `mix assets.build` once, or let the dev watcher do it.
config :tailwind,
  version: "4.1.7",
  ledger_showcase: [
    args: ~w(--input=assets/css/app.css --output=priv/static/assets/app.css),
    cd: Path.expand("..", __DIR__)
  ]

import_config "#{config_env()}.exs"
