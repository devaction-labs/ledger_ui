# Ledger UI

Componentes Phoenix LiveView com o design Ledger UI.

## Instalação

```elixir
def deps do
  [{:ledger_ui, "~> 0.1.0"}]
end
```

## Uso

```elixir
# em MyAppWeb.html_helpers/0 (ou onde importa componentes)
use LedgerUI
```

```heex
<.icon name="download" />
```

## Stylesheet e JS

CSS: `ledger.css` (tokens e classes `lu-*`). JS: módulo ES `priv/static/ledger_ui.esm.js` que exporta `{Hooks, DOM}`
(as chaves de `Hooks` são `"LedgerUI.<Nome>"`).

Com esbuild (o `package.json` do pacote aponta para o módulo; adicione `deps` ao `NODE_PATH`):

```js
import {Hooks as LedgerHooks, DOM as LedgerDOM} from "ledger_ui"

new LiveSocket("/live", Socket, {
  hooks: {...LedgerHooks},
  dom: {onBeforeElUpdated(from, to) { LedgerDOM.onBeforeElUpdated(from, to) }},
  params: {_csrf_token: csrfToken}
})
```

```css
@import "ledger_ui/css"; /* ou <link> para /ledger_ui/ledger.css */
```

Sem bundler, sirva `priv/static` (ex.: `Plug.Static at: "/ledger_ui", from: {:ledger_ui, "priv/static"}`) e use
`<script type="module">` com `import {Hooks, DOM} from "/ledger_ui/ledger_ui.esm.js"`.
`ledger.js` é só a biblioteca de gráficos/runtime (`window.LedgerUI`); os ícones são renderizados no servidor.

`LedgerUI.open/2`, `close/2` e `toggle/2` abrem/fecham elementos (classe `open`) via `Phoenix.LiveView.JS`;
no servidor use `LedgerUI.open(socket, id)`.


## Showcase

```sh
cd showcase
mix deps.get
mix phx.server   # http://localhost:4100
```

Veja `CONVENTIONS.md` para contribuir com componentes.
