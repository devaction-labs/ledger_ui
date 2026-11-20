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

### Junto com o CoreComponents do Phoenix

O `use LedgerUI` importa todos os componentes. Os nomes que o `CoreComponents` gerado pelo Phoenix 1.8 também define
(`button`, `input`, `table`, `header`, `icon`, `modal`, `label`, `error`...) ficam ambíguos onde são chamados: o
compilador recusa `<.button>` se dois módulos importados têm `button/1`. Escolha de quem é cada nome com `except:`
(todos menos estes) ou `only:` (só estes); o nome vale para qualquer aridade, `nome: 1` para uma só:

```elixir
# em MyAppWeb.html_helpers/0
import MyAppWeb.CoreComponents
use LedgerUI, except: [:button, :input, :table, :header, :icon, :modal, :label, :error]

# ou só o que interessa
use LedgerUI, only: [:card, :badge, :progress, :sidebar, :tabs]
```

O que ficou de fora continua à mão pelo módulo (`<LedgerUI.Components.Button.button>`), ou por um `import` seu com
prefixo. Um nome que não é componente do Ledger UI derruba a compilação.

Nomes da vitrine: onde o README de um componente usa um nome (`progress`, `number_input`, `range`, `radio_group`,
`cover`, `drawer`, `menu_list`, `text`, `datetime_picker`, `empty_state`, `text_editor`, `main_sidebar`) a vitrine usa
outro; os dois existem (`progress_bar`, `number_stepper`, `range_slider`, `radio`/`radio_choice`, `cover_card`,
`sheet`, `menu`, `typography`, `date_time_picker`, `empty_state_card`/`inline_empty`, `rich_text_editor`/
`comment_editor`, `icon_rail`, `sub_nav`, `shell_floating`, `container`, `tree`). Não existe `list/1`: é o nome do
`list` do CoreComponents (use `description_list`, cujo `<:item title="...">` tem o mesmo formato).

## Tailwind CSS v4 (componentes migrados)

Os componentes migrados (Icon, Button, Badge, Input + `field`, Card, Stat; o restante em andamento, ver `MIGRATION.md`) usam só
utilitários do Tailwind v4. Instale e importe o tema depois do Tailwind:

```css
/* assets/css/app.css */
@import "tailwindcss";
@import "../../deps/ledger_ui/assets/css/ledger_ui.css";   /* já inclui @source na lib */
```

`<html data-theme="light|dark" data-palette="crepusculo">` troca modo e paleta. **Importante:** o corpo recebe `font-size: 14px`
(no `body`, nunca no `html`).

### Tema próprio

O kit lê só duas entradas, como no Flux: o **accent** (3 variáveis) e a **escala de cinza** (`--color-gray-50…950`). Todo o resto
(tons 50–900 do accent, fundo suave, foco, fundos, bordas e textos) é derivado em oklch; o padrão reproduz o Ledger.

```css
@theme {                                   /* cinza: troque a escala inteira */
  --color-gray-50: var(--color-slate-50);  /* … até 950 */
}
@theme {                                   /* accent */
  --color-accent: var(--color-fuchsia-600);
  --color-accent-content: var(--color-fuchsia-600);
  --color-accent-foreground: var(--color-white);
}
@layer theme {
  [data-theme=dark] {
    --color-accent: var(--color-fuchsia-500);
    --color-accent-content: var(--color-fuchsia-400);
    --color-accent-foreground: var(--color-white);
  }
}
```

Utilitários do kit: `bg-accent`, `text-accent-content`, `text-accent-foreground`, `bg-accent-50…900`, `bg-accent-soft`, `bg-panel`, `text-ink`,
`border-line`, `shadow-btn`… Paletas prontas continuam por `data-palette` (ex.: `crepusculo`). Veja `parity/theme_demo.css` e `parity/tema-comparacao.png`.

### Componentes migrados

```heex
<.button color="primary" variant="soft" icon="huge-sparkles">Novo</.button>   <!-- cor x variante x tamanho x forma -->
<.badge color="success" variant="outline" icon="huge-check">Pago</.badge>
<.input field={@form[:email]} label="E-mail" icon="huge-mail" />               <!-- erros do changeset via <.field> -->
<.card title="Receita por plano"><:actions><.button size="sm">Planos</.button></:actions>…</.card>
<.stat_group><.stat_item label="Total" value="R$ 3.120" delta="12,4%" tone="accent" /></.stat_group>
<.icon name="huge-download" size="lg" />
```

Cores (`color=`): neutral, primary, secondary, info, success, warning, error, dark, white, mono. O pacote Hex inclui `assets/`.

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

## Ícones

`<.icon>` desenha no servidor os 141 ícones do dicionário embutido (`LedgerUI.Components.Icon.names/0`).
Qualquer outro ícone do [Hugeicons Stroke Rounded](https://hugeicons.com/icons/stroke-rounded) (set gratuito, MIT)
vem para a sua app com `mix ledger_ui.icons`, sem dependência extra:

```elixir
# config/config.exs (numa release: {:minha_app, "priv/hugeicons"})
config :ledger_ui, :icons_path, "priv/hugeicons"
```

```sh
mix ledger_ui.icons get search-01 tick-02   # baixa esses (aceita huge-search-01)
mix ledger_ui.icons sync                    # baixa o que <.icon name="huge-..."> usa em lib/, assets/js e priv/templates
mix ledger_ui.icons sync --prune            # ...e remove os que ninguém usa
mix ledger_ui.icons search invoice          # procura nomes no repositório
mix ledger_ui.icons update                  # sobe para o commit mais novo de main (ou --ref TAG)
```

```heex
<.icon name="huge-invoice-01" size="sm" />
```

Os SVGs são convertidos para o formato do kit (traço `currentColor`, 1.5, pontas redondas vêm da regra `.lu-i`;
sem cor fixa) e gravados em `priv/hugeicons/` junto com `.hugeicons.json` (commit, nomes) e `LICENSE.md`. A pasta é
lida uma vez para o `:persistent_term`; o markup é o mesmo dos embutidos (`svg.lu-i ... data-icon`). Ordem de busca:
nome embutido exato, arquivo vendorizado, nome embutido sem o sufixo `-NN`; nome desconhecido não renderiza e avisa
no log. Ícones baixados depois do boot são achados sem reiniciar. O download usa o commit fixado na task (ou o do manifesto).

## Skill do Claude Code

Gera `.claude/skills/ledger-ui/` na sua app a partir do pacote instalado (atributos, valores, slots e docs de cada
function component), para um agente escrever HEEx certo sem adivinhar:

```sh
mix ledger_ui.install       # escreve a skill, aponta AGENTS.md/CLAUDE.md para ela e imprime as linhas de setup
mix ledger_ui.gen.skill     # só (re)gera a skill; --path muda a pasta
```

```
.claude/skills/ledger-ui/
  SKILL.md                  # nome, versão, regras e a tabela de componentes
  references/<componente>.md
```

Para renovar a cada atualização do pacote, ligue o compilador no `mix.exs` da app:

```elixir
def project do
  [compilers: [:ledger_ui_skill] ++ Mix.compilers(), ...]
end
```

Ele regenera a skill quando a versão do `ledger_ui` instalada difere da registrada no `SKILL.md`; não faz nada se a
skill ainda não existe, se já está na versão e em `:prod`.


## Showcase

```sh
cd showcase
mix deps.get
mix phx.server   # http://localhost:4100
```

Veja `CONVENTIONS.md` para contribuir com componentes.

## Templates

A página "16 · Templates" do canvas virou dez telas inteiras no showcase (as de `design/vitrine/t/index.json`, na mesma ordem e com os mesmos títulos), montadas só com
componentes da biblioteca e funcionando de verdade (cada uma é uma LiveView, em tela cheia, sem o
chrome do showcase; `?theme=dark` escolhe o tema e o botão da lua alterna, com a mesma chave
`lu-theme` do localStorage; `?palette=crepusculo` escolhe a paleta, chave `lu-palette`). O índice é `/templates`.

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
| `/templates/tabela-app` | Pedidos · interativa | a tabela sem seleção: a linha abre o detalhe, as caixas levantam a barra, "Novo pedido" abre o modal e "Emitir NF-e" mostra a transmissão e a autorização (comparada com `t/tabela-app.html`) |
| `/templates/auth-login?palette=crepusculo`, `/templates/dashboard?palette=crepusculo` | Crepúsculo | as mesmas telas na paleta Crepúsculo (quadros `TCrepAuthLogin`, `TCrepDashboard`) |
| `/templates/paleta` | Paleta Crepúsculo | os tokens por papel, os gradientes e os componentes na paleta (quadro `TCrepPaleta`) |

Cada tela abre no estado do seu quadro do canvas. O teste `test/templates_parity_test.exs` compara
o HTML renderizado de cada uma com o quadro Claro e com a página da vitrine (`design/vitrine/t/<slug>.html`) e confere que o quadro Escuro é o mesmo HTML com
`data-theme="dark"`; as exceções (controles reais no lugar dos mocks do quadro) estão documentadas
em `showcase/test/support/template_parity.ex`. O comportamento está em `test/templates_live_test.exs`.

Novidades de biblioteca que as telas usam: `auth_page/1` e `auth_art/1` (a tela `lu-auth`),
`bulk_bar variant="float"` (`lu-bulkfloat`), `drawer` e `modal` com `layout="page"` (`lu-overlay`,
estado no LiveView) e a linha de rótulo + ação (`label_aside`) dos campos.
