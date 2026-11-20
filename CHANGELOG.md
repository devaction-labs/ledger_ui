# Changelog

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
