# Ledger UI

{{intro}}

## Instalação

O kit é um pacote Hex de function components HEEx estilizados **só com utilitários do Tailwind CSS v4**. Não há classes `.lu-*`, nem folha de CSS de componentes, nem `LedgerUI.hydrate()`: o pacote traz apenas o tema (tokens, `@theme`, base e `@keyframes`).

```elixir
# mix.exs
def deps do
  [{:ledger_ui, "~> 0.4.1"}]
end
```

O Tailwind v4 do app precisa rodar (no Phoenix 1.8 já roda). Importe o tema **depois** do Tailwind; ele já traz o `@source` da `lib/` do pacote, então o Tailwind gera só as utilitárias usadas:

```css
/* assets/css/app.css */
@import "tailwindcss";
@import "../../deps/ledger_ui/assets/css/ledger_ui.css";
```

```elixir
# em MyAppWeb.html_helpers/0 (ou onde importa componentes)
use LedgerUI
```

```heex
<.button color="primary" icon="huge-sparkles">Novo</.button>
```

Os componentes com comportamento no cliente usam hooks `LedgerUI.<Nome>`, que vêm do módulo ES do pacote (`priv/static/ledger_ui.esm.js`):

```js
import {Hooks as LedgerHooks, DOM as LedgerDOM} from "ledger_ui"

new LiveSocket("/live", Socket, {
  hooks: {...LedgerHooks},
  dom: {onBeforeElUpdated(from, to) { LedgerDOM.onBeforeElUpdated(from, to) }},
  params: {_csrf_token: csrfToken}
})
```

## Como ler este sistema

- **Cores**: tokens semânticos em `tokens.json`, temas **Claro** e **Escuro**. Componentes só usam tokens (no kit, as variáveis `--lu-*` e as utilitárias `bg-page`, `text-ink`, `border-line`…); o escuro vem de graça, por `data-theme="dark"` no `<html>`.
- **Componentes**: uma página por família (grupos numerados 01–15). Cada card tem preview ao vivo e guia (`README.md`) com uso em HEEx e regras. O preview é o HTML real que os componentes do kit geram. `PARIDADE.md` lista a API Phoenix coberta por cada card.
- **`components/bundle.css`**: o CSS compilado do kit, só para os previews desta página. É o tema `ledger_ui.css` mais as utilitárias Tailwind v4 que `lib/` e os previews usam, gerado com o binário do Tailwind. Não é API e não traz classes `.lu-*` para copiar: no seu app você importa o tema e o Tailwind do app gera o CSS.
- **`components/bundle.js`**: um script clássico que define `window.LedgerUI` (`version`, `Hooks`, `DOM`, `liveSocket`, `init(raiz?)`). Embute o runtime estático (phoenix, phoenix_live_view, os hooks do `ledger_ui.esm.js`) para os JS commands (`phx-click="[[...]]"`) e os hooks dos previews funcionarem sem servidor: um LiveSocket que nunca conecta executa os comandos, e `LedgerUI.init()` monta os hooks do que estiver na página. Também não é a forma de uso no app (lá valem os hooks acima).
- **Ícones**: **Hugeicons Stroke Rounded** (hugeicons.com/icons/stroke-rounded), desenhados no servidor: `<.icon name="huge-trend-up" />`, sem JavaScript. O dicionário embutido tem 141 ícones; `mix ledger_ui.icons` baixa qualquer outro do set gratuito. O `<i data-i="...">` com `hydrate()` não é mais o caminho no LiveView.

{{section:Grupos (uma página cada)}}

{{section:Fundamentos visuais}}

{{section:Interações (do vídeo de referência)}}

{{section:Conteúdo (voz)}}

## Uso no Phoenix

As APIs são function components HEEx (`<.button>`, `<.kpi_card>`, `<.segmented>`…), importados por `use LedgerUI`. Os nomes que o `CoreComponents` do Phoenix 1.8 também define (`button`, `input`, `table`, `header`, `icon`, `modal`, `label`, `error`) ficam ambíguos: escolha de quem é cada nome com `use LedgerUI, except: [...]` ou `use LedgerUI, only: [...]`.

**Temas.** Duas chaves independentes no `<html>`: `data-theme="light|dark"` (o modo; `<.theme_switch>` alterna e guarda) e `data-palette="crepusculo"` (a paleta; `<.theme_picker>` escolhe; sem o atributo vale o Ledger). `<.theme_script />` no `<head>` do layout raiz aplica o que foi guardado antes da primeira pintura.

**Tema próprio.** O kit lê só duas entradas: o accent (`--color-accent`, `--color-accent-content`, `--color-accent-foreground`) e a escala de cinza (`--color-gray-50…950`). Todo o resto deriva delas em oklch. Sobrescreva-as num `@theme` no `app.css`, depois dos dois `@import`s.

**Agentes.** `mix ledger_ui.install` gera a skill do Claude Code (`.claude/skills/ledger-ui/`) com atributos, valores e slots de cada function component.
