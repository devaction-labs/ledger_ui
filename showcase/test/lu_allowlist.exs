# `lu-*` class tokens still present in the RENDERED example (`examples/<id>/NN.heex`): PENDING rewrites.
# `LedgerShowcase.ExamplesTest` fails on any token not listed here AND on a listed token that is gone, so the
# list only shrinks. When you rewrite an example with real components, delete its line. NEVER add a line for new
# code; a genuinely permanent exception stays in the list with a `# permanent: <reason>` comment above its line
# (none today).
%{
  # pendente: color_picker lacks the bare canvas look: saturation/value area 220x120 + hue bar only, and the flex-wrap swatch row
  {"color-picker", 1} => ["lu-cpick", "lu-sw2"],
  # pendente: color_picker swatches: canvas sizes sm/md/lg = 20/26/34px in one wrapping flex row (lib: 26/30/34px in an 8-column grid)
  {"color-picker", 2} => ["lu-sw2"],
  {"select", 4} => ["lu-menu-item", "lu-menu-sep", "lu-pop"],
  # pendente: time_picker_panel has the popover box (border/shadow/padding, scrollable); the canvas list is bare: h-[180px] w-[110px] overflow-hidden, mono 13px, 32px rows, with the mo-scroll loop
  {"time-picker", 1} => ["lu-tlist"],
  # pendente: calendar variant="mini" lacks size sm/lg (cells 28/34/42px) and a single-week strip (letters + one row)
  {"calendar", 2} => ["lu-cal2"],
  # pendente: calendar variant="mini" lacks size sm/md/lg (cols 28/34/42px, rows 26/32/40px, font 12/13/14px)
  {"date-picker", 2} => ["lu-cal2"],
  # pendente: needs the bare mini calendar with size sm (no title/arrows) and the bare time list (see time-picker)
  {"date-time-picker", 1} => ["lu-cal2", "lu-tlist"],
  # pendente: same as time-picker 1 (the bare, animated time list)
  {"time-picker", 2} => ["lu-tlist"],
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
