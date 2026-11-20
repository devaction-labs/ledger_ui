defmodule LedgerShowcaseWeb.Layouts do
  @moduledoc false
  use Phoenix.Component

  @search_json LedgerShowcase.Vitrine.search_json()

  def root(assigns) do
    assigns = assign(assigns, :search_json, @search_json)

    ~H"""
    <!DOCTYPE html>
    <html lang="pt-BR" data-theme="light">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
        <.live_title default="Ledger UI · Componentes">{assigns[:page_title]}</.live_title>
        <script>
          (function () {
            var t = null;
            try { t = new URLSearchParams(location.search).get("theme") || localStorage.getItem("lu-theme"); } catch (e) {}
            if (!t) t = matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
            document.documentElement.setAttribute("data-theme", t);
            var h = location.hash.slice(1);
            if (h && !/^(x-|full)/.test(h) && location.pathname === "/") {
              var map = {inicio: "/", instalacao: "/instalacao", cores: "/cores", temas: "/temas", novidades: "/novidades"};
              location.replace(map[h] || "/c/" + encodeURIComponent(h));
            }
          })()
        </script>
        <link rel="icon" href="data:," />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
        <link
          rel="stylesheet"
          href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Geist+Mono:wght@400;500&display=swap"
        />
        <link rel="stylesheet" href="/ledger_ui/ledger.css" />
        <link rel="stylesheet" href="/ledger_ui/ledger_ui.css" />
        <link rel="stylesheet" href="/assets/live.css" />
        <link rel="stylesheet" href="/assets/showcase.css" />
        <script src="/ledger_ui/ledger.js">
        </script>
        <script src="/phoenix/phoenix.js">
        </script>
        <script src="/phoenix_live_view/phoenix_live_view.js">
        </script>
        <script src="/assets/live.js">
        </script>
        <script src="/assets/act.js">
        </script>
        <script src="/assets/act2.js">
        </script>
        <script src="/assets/flow.js">
        </script>
        <script src="/assets/showcase.js">
        </script>
        <script type="module">
          import {Hooks, DOM} from "/ledger_ui/ledger_ui.esm.js"
          const csrf = document.querySelector("meta[name='csrf-token']").getAttribute("content")
          const liveSocket = new window.LiveView.LiveSocket("/live", window.Phoenix.Socket, {
            params: {_csrf_token: csrf},
            hooks: {...Hooks, ...window.ShowcaseHooks},
            dom: {onBeforeElUpdated(from, to) { DOM.onBeforeElUpdated(from, to) }}
          })
          liveSocket.connect()
          window.liveSocket = liveSocket
        </script>
        <script type="application/json" id="d-search">
          {Phoenix.HTML.raw(@search_json)}
        </script>
      </head>
      <body>
        {@inner_content}
      </body>
    </html>
    """
  end
end
