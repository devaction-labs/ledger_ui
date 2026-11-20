defmodule LedgerShowcaseWeb.Layouts do
  @moduledoc false
  use Phoenix.Component

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="pt-BR" data-theme="light">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
        <title>Ledger UI showcase</title>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
        <link
          rel="stylesheet"
          href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Geist+Mono:wght@400;500&display=swap"
        />
        <link rel="stylesheet" href="/ledger_ui/ledger.css" />
        <link rel="stylesheet" href="/assets/live.css" />
        <script src="/ledger_ui/ledger.js">
        </script>
        <script src="/phoenix/phoenix.js">
        </script>
        <script src="/phoenix_live_view/phoenix_live_view.js">
        </script>
        <script type="module">
          import {Hooks, DOM} from "/ledger_ui/ledger_ui.esm.js"
          const csrf = document.querySelector("meta[name='csrf-token']").getAttribute("content")
          const liveSocket = new window.LiveView.LiveSocket("/live", window.Phoenix.Socket, {
            params: {_csrf_token: csrf},
            hooks: {...Hooks},
            dom: {onBeforeElUpdated(from, to) { DOM.onBeforeElUpdated(from, to) }}
          })
          liveSocket.connect()
          window.liveSocket = liveSocket
        </script>
      </head>
      <body>
        {@inner_content}
      </body>
    </html>
    """
  end
end
