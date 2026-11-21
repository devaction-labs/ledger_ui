# Changelog

## Não lançado

### Correções

- `breadcrumb`: o conteúdo dinâmico dos `<:item>` volta a acompanhar os assigns no LiveView. O slot era desenhado dentro dos
  componentes internos a partir de um mapa derivado, e o rastreamento de mudanças não via a troca (#2).
- `avatar`: foto em retrato ou paisagem não sai mais do círculo (`absolute inset-0` na `<img>`). O mesmo vale para as fotos do
  cartão de usuário e dos logos do `app_shell`/`sidebar` e para o avatar de pessoa do `select` (#1).

### Atributos novos

- `chip`: `size="sm|md|lg"` (24, 30 e 32px; o padrão `md` não muda) (#5).
- `navbar_search`: `size="sm"`, compacto com 32px, raio de 8px e `px-2.5` (#3).
- `page_header`: `show_heading={false}` omite o `<h1>`; `density="compact"` usa 24px de padding no topo, em vez de 26px (#4).
- `sidebar`/`framed_sidebar`: a largura recolhida vem de `--lu-rail-collapsed` (padrão 60px) e pode ser definida com
  `collapsed_width={72}` (#9). A classe muda de `data-[collapsed]:w-[60px]` para `data-[collapsed]:w-(--lu-rail-collapsed,60px)`,
  sem mudança visual.
- `insight_button`: com `navigate`, `patch` ou `href`, gera um `<.link>`; `icon="..."` mostra um ícone no lugar do contador e
  vence o `count` (#7).
- `stat_item`: `value_id` (vira o `id` do valor), slots `:inner_block` e `:footer`. `kpi_card`: slot `:footer` no rodapé e
  `value_id` também na variante canvas (#10).
- `rail_link`: slot `<:trailing>` (ex.: `<.kbd>⌘K</.kbd>`) e `variant="sub"` (sub-link de 32px). `rail_module`: `badge` nos `:item`
  filhos. `rail_heading`: `variant="sans"` (11.5px, maiúsculas, peso 500) (#6).
- `notification_center` (variante `classic`): slot `:actions` e `closable` no cabeçalho; `size="sm"` no sino (32px);
  `count_tone` (attr ou por aba) deixa o contador neutro e aplica o tom só na aba selecionada, que acompanha a troca de aba
  via `group-aria-selected:*`, sem JS novo (#8).

## 0.3.0 — 2026-11-21

Os componentes são HEEx estilizado **só com utilitários do Tailwind CSS v4**; o pacote deixa de trazer folhas de estilo de componente.

### Quebra de compatibilidade

- **Sem `ledger.css` nem `ledger_ui.css` de componentes, sem classes `lu-*`.** `priv/static/ledger.css` e `priv/static/ledger_ui.css`
  foram removidos, assim como os exports de CSS do `package.json`. O app hospedeiro roda o Tailwind v4 e importa o tema do pacote
  (`assets/css/ledger_ui.css`: tokens, `@theme`, base e `@keyframes`, com o `@source` da `lib/` do pacote):

  ```css
  @import "tailwindcss";
  @import "../../deps/ledger_ui/assets/css/ledger_ui.css";
  ```

  Quem estilizava com `lu-*` ou com `var(--ink)`/`var(--accent)` passa a usar os utilitários do kit (`bg-panel`, `text-ink`,
  `border-line`, `bg-accent`...) ou as variáveis `--lu-*`. O `package.json` exporta `./ledger_ui.css`, `./css` e `./css/ledger_ui.css`
  (todos para `assets/css/ledger_ui.css`) e o módulo ES continua em `import {Hooks, DOM} from "ledger_ui"`.
- Os hooks não consultam mais classes `lu-*`: usam `data-part`, `data-state` e `aria-*` (os nós criados pelo JS recebem classes por
  `data-lu-cls`/`data-lu-config`, gerados no Elixir). Quem sobrescrevia seletores `.lu-*` precisa trocá-los por `[data-part=...]`.
- `card`: a superfície `flat` agora é o cinza (`bg-sunken`); o antigo `flat` da bandeja é `panel`; `canvas` e `page` são variantes
  novas. `table`: tamanho, cor e família do texto das células com especificidade zero (a classe da célula vence), seta de ordenação
  ao passar o mouse nas colunas inativas.
- `mix ledger_ui.install` e a skill passam a descrever o setup com o Tailwind v4.

### Tema como no Flux

- Duas entradas: o accent (`--color-accent`, `--color-accent-content`, `--color-accent-foreground`) e a escala de cinza
  (`--color-gray-50…950`). Tons 50–900 do accent, fundo suave, foco, fundos, bordas, textos e as cores do gráfico derivam delas em
  oklch; o padrão reproduz o Ledger. O snippet "Tema próprio" do README muda accent e cinza em **todos** os componentes.
- Utilitários do kit: `bg-accent`, `text-accent-content`, `bg-accent-50…900`, `bg-accent-soft`, `bg-page|shell|tray|panel|sunken|hover|selected`,
  `border-line`, `text-ink|ink-2|muted|subtle`, `bg-pos|neg|warn|info|lime|violet`, `shadow-xs…lg|btn`, `rounded-xs…2xl`, `font-sans|display|mono`.
- `LedgerUI.Color`: as cores semânticas (`color=`) em quatro variáveis locais (`--c`, `--c-on`, `--c-soft`, `--c-ink`).
- A paleta `crepusculo` (`data-palette`) alimenta o accent pelas mesmas entradas; modo (`data-theme`) e paleta continuam independentes.
- Vitrine: gerador de tema em `/temas` (accent + cinza), com o CSS pronto para colar.

### Componentes e atributos novos (rodadas de correção)

- `progress_ring/1`, `tooltip_tip/1` (só o balão), `count/1` e `delta/1` (em `badge`; `dot="live"` pisca por opacidade),
  `select` `listbox/1` público (painel estático), `dropdown` `menu_panel/1` público.
- `card variant="panel|canvas|page"`, `card_body` com padding; `pagination arrows_at="sides"`; `view_switcher` `stretch`;
  `calendar` mini `sm|md|lg`, faixa de uma semana e demo de escolha/intervalo; `time_picker_panel` na variante lista;
  `color_picker` `compact`/`row` (amostras 20/26/34px); `signature_pad name_input`; `text_editor` densidade compacta e barra animada.
- Atributos `loop`/`demo` (movimento do canvas feito pelo próprio componente, sem mock): `number_input`, `switch`, `checkbox`,
  `otp_input`, `textarea`, `tags_input`, `password_input`, `upload`, `breadcrumb`, `tabs`, `range`, `carousel`, `timer`, `cash_timer`,
  `avatar` (`speak`), `bar_chart`/`donut_chart`, `pixel_card` (`lit`), `sub_nav`, `connection_banner` (`state=off|re|on|cycle`),
  `command_palette` (`state="no_match"`), `toast_card` (`steps`), `navbar` (busca digitando, sino).
- `app_shell`/`sidebar`: cor e contador no link, título de navegação, contador no trilho, `min_height`; `theme_picker open`, `theme_switch`
  com `value` e slot de ícone; `ai_tool_trace` bare, `ai_chat` `default`/`canvas` e compacto; `kanban` local; `flow` com ramificação;
  `empty_state`/`error_state` compactos e flutuantes, `logo` com tom/glifo, `fab` estático.
- `pillbox`/`tags_input`: as etiquetas são os chips do design, `removable`/`chevron`; a linha "criar" só aparece com `create`.
- Senha: id seguro para nomes com colchetes, bolinhas de 18px e olho de 16px; `phone_input` com o prefixo discreto, sem seta.
- `Form.field` renderiza `inner_block`, `below` e `aside` no lugar (slots não passam como atributo: mantêm o change tracking);
  `Icon.svg_class/1` devolve as classes do `<svg>` para os hooks; `modal placement="top|bottom"` e o alinhamento mantém o centro.
- Vitrine: os exemplos são componentes reais (sem marcação crua) e os dez templates de tela usam só componentes da biblioteca.

### Correções

- `range`: o valor inferior do par é `--lu-rlo` (não colide com o ângulo `--lu-a` do aura).
- `steps`: os conectores têm 2px e ficam alinhados ao pixel; `code_block` mantém a família `monospace` do navegador.
- `theme_toggle`/`theme_switch`: o sol aparece no escuro (o original só trocava o atributo `data-icon`, nunca o desenho).
- `small` volta ao `smaller` do navegador (o preflight do Tailwind põe 80%), pela camada `base` do tema.

### Ferramentas

- Paridade de pixels `parity/run.py` (original `lu-*` x HEEx, em claro, escuro, crepúsculo e crepúsculo escuro; `--theme` com accent fúcsia + cinza slate),
  comparação visual canvas x vitrine `scripts/visual/` e `MIGRATION_REPORT.md` com os números finais. Nada disso vai no pacote Hex.
- README: instalação, temas, paletas, "Tema próprio" e um exemplo por componente (`mix run scripts/gen_readme_components.exs`),
  compilados por `test/readme_examples_test.exs`.

## 0.2.0 — 2026-11-21

Design v3 (paleta Crepúsculo, app em tela cheia, templates de página), API da vitrine completa, ícones Hugeicons sob demanda (`mix ledger_ui.icons`), skill do Claude Code (`mix ledger_ui.gen.skill`), movimento dos overlays e gráficos responsivos.

### A API da vitrine vira real

- Os nomes que a vitrine usa e faltavam são componentes de verdade (mesmos attrs e slots do componente de que
  são apelido, então `__components__/0`, os avisos de compilação e a skill os enxergam): `progress_bar`,
  `number_stepper`, `range_slider`, `radio` (um radio ou um grupo) e `radio_choice`, `cover_card`, `sheet`, `menu`,
  `typography`, `command_palette_dialog`, `date_time_picker`, `empty_state_card`, `rich_text_editor`,
  `comment_editor`, `icon_rail`, `shell_floating`; e `container`, `inline_empty`, `tree` (a árvore como dado) e
  `sub_nav`, novos. `list/1` não existe de propósito (é o do CoreComponents); a vitrine fica com `description_list`.
- `use LedgerUI, only: [...]` e `except: [...]` (nomes ou `nome: aridade`), para quem tem um CoreComponents com
  `button`, `input`, `table`, `header`, `icon`, `modal`...; um nome desconhecido derruba a compilação. README e
  moduledoc explicam.
- Slots que faltavam: `:trigger` em `dropdown`, `action_menu`, `filter_menu`, `context_menu` e `tooltip` (neste, o
  `trigger="click"` e o `content="..."` em forma de texto passam por `rest`), `:title` em `modal` e `drawer` (o
  `title="..."` continua valendo), `:actions` em `modal`, `:item` em `accordion`, `:option` em `segmented`, `:item` e
  `:view` em `sidebar`.
- Attrs que faltavam: `logo` `name`/`context`; `alert` `title`/`description` e `accent` sem valor; `status_toast`
  `status`/`title`/`action`; `divider` `label`; `tabs` `:tab active`; `modal` `show`; `drawer` `floating`;
  `icon_button` `color`/`shape` e as variantes do `button`; `bar_chart` `data`; `calendar` `month`; `color_picker`
  `swatches`; `date_picker` `range`; `password_input` `strength`; `scrollspy` `target`; `theme_picker` `current`;
  `time_picker` `step`; `timer` `seconds`; `step_group` `steps`/`current`; `trace` `spans`; `timeline` `items`;
  `ai_tool_trace` `steps`; `conversation_list` `current`; `sidebar` `workspace`; `tree_item` `icon="nome"`;
  `context_menu` `placement`; `illustration` `color`; `variant` como apelido do `layout`/`shape` em
  `description_list`, `form_section` e `pagination`; `navbar variant="canvas"`.
- `test/support/vitrine_code_known.ex` só guarda artefatos do gerador (modificadores do canvas escritos como
  `variant=`, `<.chip>` com prop de outro componente) e a decisão do `list`, cada um com o motivo.

### Design v3: paleta Crepúsculo, app em tela cheia e vitrine v2

- Paleta `crepusculo` (`<html data-palette="crepusculo">`, tokens claro/escuro no `ledger.css`): `theme_picker` a lista
  (`themes/0` ganha "Crepúsculo"), o hook guarda a escolha em `localStorage["ledger-palette"]` (lê a chave antiga
  `ledger-theme`) e `theme_script/1` a aplica antes da primeira pintura. `LedgerUI` e `theme_switch` documentam
  modo e paleta como duas chaves independentes.
- `app_shell full` (`lu-app full`: tela cheia, sem moldura); o `app/1` dos templates usa `lu-app full`.
- `button icon="nome"`: o ícone antes do rótulo (`icon` continua aceitando `true` para o botão quadrado só de ícone);
  `stat_item` aceita `delta`, `hint`, `goal`, `spark` e `delta_tone`; `aura motion` é apelido de `mode`.
- Showcase: seletor de paleta no topo e página "Temas" como na vitrine v2 (`data-palette` no `<html>`, `lu-palette`),
  os templates aceitam `?palette=crepusculo`, `/templates/paleta` (quadro `TCrepPaleta`) e `/templates/tabela-app`
  ("Pedidos · interativa"); o índice `/templates` lista os da `t/index.json` na mesma ordem e com os mesmos títulos,
  mais o grupo Crepúsculo. Paridade com os quadros `TCrep*` e com `design/vitrine/t/*.html`; o painel agora é
  comparado fora do gráfico de linha.
- Vitrine v2: as seções "Referência visual" saíram (os exemplos foram renumerados), `retired.json` deixou de existir
  e os demos "Referência visual" do canvas não viram extras. `test/vitrine_code_test.exs` compila o HEEx de cada
  seção contra a biblioteca; as que ainda não compilam estão em `test/support/vitrine_code_known.ex`, com o motivo.

### Gaveta e modal: movimento e dados do exemplo

- Gaveta/modal (`layout="page"` e hook `LedgerUI.Overlay`) com o movimento da vitrine: fundo .22s, gaveta .32s,
  modal opacidade .2s + transform .28s, curva `cubic-bezier(.2,.8,.2,1)` nos dois sentidos. A gaveta da página
  não deslizava porque o foco rolava o `.lu-app` (`overflow: hidden`); agora é `overflow: clip`.
- Showcase `/templates/tabela`: cada pedido tem seus itens, desconto, histórico e passos coerentes com a linha da
  tabela; `?pedido=` e `tabela-gaveta` começam sem seleção.

### Ícones e skill

- `mix ledger_ui.icons` (`get`, `sync`, `search`, `update`): baixa os ícones Hugeicons Stroke Rounded que a app usa
  para `config :ledger_ui, :icons_path` (commit fixado, `.hugeicons.json`, `LICENSE.md`), convertidos para o formato do kit.
  `<.icon>` os lê de `LedgerUI.Icons` (`:persistent_term`, recarrega ao achar a pasta alterada); embutidos vencem.
- Skill do Claude Code: `mix ledger_ui.gen.skill` e `mix ledger_ui.install` escrevem `.claude/skills/ledger-ui/`
  (`SKILL.md` + `references/<componente>.md`) a partir do pacote instalado; o compilador opt-in `:ledger_ui_skill`
  a regenera quando a versão muda (não faz nada em `:prod`).

### Integração

- `use LedgerUI` importa só function components e os helpers documentados (`show_toast/2`, `dismiss_alert/0`...);
  os helpers internos (`Chart.num/1`, `money/1`...) não vazam mais. Teste: `use_imports_test.exs`.
- Uma só paisagem: `Illustration.summit/1` (`svg.lu-summit`, tokens `--hero-*`, attr `tone`); `hero_summit/1` e
  `auth_art/1` delegam a ela.
- Novos: `button canvas` (`lu-btn`), `number_input canvas`, `segmented stretch`/`role`, `checkbox style` (vai no `label`).
- Showcase: as seções do vitrine que o canvas aposentou saem da página; as demais são renumeradas a partir de 01.

### Templates

- Showcase: seção "16 · Templates" (`/templates`) com nove telas LiveView do canvas (auth, painel,
  tabela de pedidos com gaveta e modal) e teste de paridade contra os quadros.
- `auth_page/1` e `auth_art/1` (tela `lu-auth`); `bulk_bar variant="float"` (`lu-bulkfloat`);
  `drawer` e `modal` com `layout="page"` (sobreposição controlada pelo LiveView; o modal vira
  `<form>` com `phx-submit`/`phx-change`).
- `line_chart sub_delta`; `alert` com `color`/`variant` nulos; `checkbox size={nil}`; `otp_input
  autofocus` marca a primeira caixa vazia (`on`); a rosca mostra `45%` em vez de `45.0%`;
  `label_aside` dos campos fica numa linha com o rótulo (`lu-row`).

## 0.1.0 — 2026-11-20

Primeira versão do Ledger UI: function components para Phoenix LiveView com o visual do canvas
"Ledger UI · Componentes" (claro e escuro).

### Componentes

- 140 componentes em 15 grupos, 110 módulos (`use LedgerUI` importa todos): fundamentos, ações,
  formulários (texto, seleção, datas e valores), exibição, métricas e gráficos, tabelas, fluxo de
  trabalho, feedback, navegação, sobreposições, estrutura e shell, temas e marca, IA.
- API dos function components conforme os guias do design system (`design/system/components`).
- Formulários aceitam `field={@form[:x]}`; listas e tabelas aceitam `@streams`.

### Arquitetura

- Classes resolvidas em compilação (`@styles` por módulo), `data-part`, prefixo global `keep-`.
- CSS do canvas sem alterações (`ledger.css`) e complemento `ledger_ui.css` para controles reais,
  estados de overlay e classes extras. Sem Tailwind.
- JS como módulo ES (`ledger_ui.esm.js`) exportando `{Hooks, DOM}`: 58 hooks `LedgerUI.*` e
  `DOM.onBeforeElUpdated` para preservar estado do cliente entre patches.
- Ícones Hugeicons renderizados no servidor; gráficos em SVG no servidor; ARIA no HTML do servidor.
- Abrir/fechar overlays com `Phoenix.LiveView.JS` (`LedgerUI.open/close/toggle`), sem ida ao servidor.

### Vitrine

- `showcase/`: app LiveView que replica a vitrine do kit (`mix phx.server`, porta 4100), com
  exemplos em HEEx e teste de paridade contra o canvas (`mix test test/parity_test.exs`).
