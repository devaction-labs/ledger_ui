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

CSS: `ledger.css` (tokens e classes `lu-*`, o CSS do design, não editar) e `ledger_ui.css` (complemento, carregado DEPOIS: `[hidden]`, controles reais dentro dos wrappers do kit, estados de overlay, `--ledger-z-*` e as classes que os componentes/hooks adicionam). JS: módulo ES `priv/static/ledger_ui.esm.js` que exporta `{Hooks, DOM}`
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
@import "ledger_ui/css/ledger.css";    /* exports "./css" e "./css/ledger.css" */
@import "ledger_ui/css/ledger_ui.css"; /* depois do ledger.css */
/* ou <link> para /ledger_ui/ledger.css e depois /ledger_ui/ledger_ui.css */
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

## Templates

A página "16 · Templates" do canvas virou nove telas inteiras no showcase, montadas só com
componentes da biblioteca e funcionando de verdade (cada uma é uma LiveView, em tela cheia, sem o
chrome do showcase; `?theme=dark` escolhe o tema e o botão da lua alterna, com a mesma chave
`lu-theme` do localStorage). O índice é `/templates`.

| Rota | Tela | Comportamento |
|---|---|---|
| `/templates/auth-login` | Entrar | e-mail e senha validam no `phx-change`; senha errada mostra as tentativas que restam e bloqueia na terceira; `ana@bompreco.com.br` / `demo123456` entra |
| `/templates/auth-login-erro` | Entrar com erro | o mesmo login, já com o aviso de credencial incorreta |
| `/templates/auth-cadastro` | Criar conta | três passos; no passo 2 o CNPJ é consultado numa tabela de mentira (`12.345.678/0001-90` é encontrado e preenche a empresa) |
| `/templates/auth-codigo` | Código por e-mail | `otp_input` de seis dígitos (`482915` confirma), reenvio com contagem |
| `/templates/auth-senha` | Recuperar a senha | envia o link e mostra o aviso |
| `/templates/dashboard` | Painel | meta, KPIs, faturamento (linha, com Dia/Mês/Ano), vendas por canal (rosca), pedidos e atividade |
| `/templates/tabela` | Pedidos | busca e abas filtram; a seleção das linhas comanda a barra flutuante `bulk_bar variant="float"` |
| `/templates/tabela-gaveta` | Pedidos · gaveta | a tabela com o detalhe do pedido em `drawer layout="page"` (`/templates/tabela?pedido=2491`) |
| `/templates/tabela-modal` | Pedidos · novo pedido | a tabela com o formulário em `modal layout="page"` (`/templates/tabela?novo=1`) |

Cada tela abre no estado do seu quadro do canvas. O teste `test/templates_parity_test.exs` compara
o HTML renderizado de cada uma com o quadro Claro e confere que o quadro Escuro é o mesmo HTML com
`data-theme="dark"`; as exceções (controles reais no lugar dos mocks do quadro) estão documentadas
em `showcase/test/support/template_parity.ex`. O comportamento está em `test/templates_live_test.exs`.

Novidades de biblioteca que as telas usam: `auth_page/1` e `auth_art/1` (a tela `lu-auth`),
`bulk_bar variant="float"` (`lu-bulkfloat`), `drawer` e `modal` com `layout="page"` (`lu-overlay`,
estado no LiveView) e a linha de rótulo + ação (`label_aside`) dos campos.
