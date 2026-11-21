defmodule LedgerShowcaseWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :ledger_showcase

  @session_options [
    store: :cookie,
    key: "_ledger_showcase",
    signing_salt: "ledger-sess",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  plug Plug.Static, at: "/ledger_ui", from: {:ledger_ui, "priv/static"}, gzip: false
  plug Plug.Static, at: "/phoenix", from: {:phoenix, "priv/static"}, gzip: false

  plug Plug.Static,
    at: "/phoenix_live_view",
    from: {:phoenix_live_view, "priv/static"},
    gzip: false

  plug Plug.Static, at: "/", from: :ledger_showcase, gzip: false, only: ~w(assets)

  # dev: recompiles on each request when examples/*.heex, lib/ or the ledger_ui path dep change (config/dev.exs: code_reloader)
  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Parsers, parsers: [:urlencoded, :multipart, :json], pass: ["*/*"], json_decoder: Jason
  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug LedgerShowcaseWeb.Router
end
