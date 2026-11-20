# Changelog

## Não lançado

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
- Showcase: seções do vitrine que o canvas aposentou (`design/canvas/retired.json`: `hero-card` e `stat` 01–03) saem
  da página; as demais são renumeradas a partir de 01.

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
