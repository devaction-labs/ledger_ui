# `lu-*` class tokens still present in the RENDERED example (`examples/<id>/NN.heex`): PENDING rewrites.
# `LedgerShowcase.ExamplesTest` fails on any token not listed here AND on a listed token that is gone, so the
# list only shrinks. When you rewrite an example with real components, delete its line. NEVER add a line for new
# code; a genuinely permanent exception stays in the list with a `# permanent: <reason>` comment above its line
# (none today).
%{
  {"select", 4} => ["lu-menu-item", "lu-menu-sep", "lu-pop"],
  # pendente: o item de navegação da sidebar (`sidebar_nav_link`) não tem atributo `color` (fundo --c-soft + texto --c-ink do canvas); as 6 células "color=…" ficam em marcação crua
  {"shell", 3} => ["lu-nav-item"],
  # pendente: command_palette (inline/bare) nao renderiza o estado "sem resultado" (mensagem + linha do assistente); so o hook mostra
  {"command-palette-dialog", 3} => [
    "lu-cap",
    "lu-cell",
    "lu-grid",
    "lu-menu-item",
    "lu-muted",
    "lu-pop",
    "lu-small"
  ],
  # pendente: connection_banner nao desenha nada (so o toast do hook ao cair o socket); o canvas desenha a faixa lu-conn (wifi + texto)
  {"connection-banner", 1} => ["lu-conn"],
  {"connection-banner", 2} => ["lu-col", "lu-conn", "lu-ring2"],
  # pendente: a lib nao tem anel de progresso (conic-gradient + valor no centro); falta progress_ring/1
  {"progress-bar", 7} => ["lu-ring", "lu-row"],
  # pendente: toast_card nao tem steps/step (segmentos de etapas); o hook do toaster tem, o componente de pagina nao
  {"toaster", 5} => ["lu-tcard", "lu-tloop"],
  # pendente: sem componente de contador (lu-count) nem de delta isolado (lu-delta); hoje só existem dentro de stat/kpi_card
  {"badge", 6} => ["lu-count", "lu-delta"],
  # pendente: sem tooltip estático (o <.tooltip> exige gatilho e flutua); falta expor o balão (tooltip_tip/1 ou tooltip static)
  {"kbd", 4} => ["lu-tooltip"]
}
