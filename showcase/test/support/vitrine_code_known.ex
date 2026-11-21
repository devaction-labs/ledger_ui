defmodule LedgerShowcase.VitrineCodeKnown do
  @moduledoc """
  Vitrine sections whose HEEx `code` (design/vitrine/sec/<id>.json) does not compile against the
  library, with the reason. Every entry is a generator artifact or a naming decision, never a gap
  of the API: `test/vitrine_code_test.exs` fails when a section outside this list breaks AND when
  a listed one starts to compile (so the list can only shrink).

  The reasons come in a few kinds:

    * a canvas demo modifier (a state, tone, size or layout class such as `acc`, `k-primary`, `sm`)
      that the generator wrote as `variant="..."`; the component has the real attr under another
      name or value, named in the reason
    * a placeholder `<.chip>` or `<.badge>` that carries a prop of another component
    * the literal `...` of the generator
    * `list`, which LedgerUI does not define because Phoenix's generated CoreComponents do

  "missing required ..." (a snippet without its `id`/label/slot) is not an API gap and is ignored.
  """

  @known %{
    {"ai-chat", 1} =>
      "artifact: a canvas demo modifier written as `variant=` (`me`, `m2`, `m3` are the message classes of the demo; a message is `<.ai_message role=\"user\">`)",
    {"ai-message", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`me` is the user message class; the attr is `role=\"user\"`)",
    {"badge", 6} =>
      "artifact: a canvas demo modifier written as `variant=` (`warn`, `up`, `down` are tone classes; the attrs are `color` and `variant`)",
    {"calendar", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`sm` is a size class; `variant` is `full|mini`)",
    {"card-table", 4} =>
      "artifact: a placeholder `<.chip>` carrying `sort_dir`, an attr of another component (the sorted column of the table)",
    {"card", 5} =>
      "artifact: `align`, `level` and `size=\"base|xl\"` are attrs of `card_actions`/`card_heading`, written on `<.card>`",
    {"carousel", 1} =>
      "artifact: a canvas demo modifier written as `variant=` (`fade` is the `effect`: `<.carousel effect=\"fade\">`)",
    {"carousel", 3} =>
      "artifact: a placeholder `<.chip>` carrying `navigation`, an attr of `carousel`",
    {"cash-timer", 1} =>
      "artifact: a canvas demo modifier written as `variant=` (`open|closed|alert` is the `state` attr)",
    {"cash-timer", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`open|closed|alert` is the `state` attr)",
    {"checkbox", 5} =>
      "artifact: a canvas demo modifier written as `variant=` (`card`, `chip` are variants of `checkbox_group`, not of one `checkbox`)",
    {"color-picker", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`sm`, `lg` are the `swatch_size`; `variant` is `full|swatches`)",
    {"command-palette-dialog", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`hl` is the highlighted row class; `highlight` is `always|typed`)",
    {"command-palette-dialog", 3} =>
      "artifact: a canvas demo modifier written as `variant=` (`pad` is a layout class of the demo)",
    {"comment-editor", 1} =>
      "artifact: `user` is the app's current user, which the editor never reads (the vitrine shows no author)",
    {"context-menu", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`danger` is an item tone: `<:item tone=\"danger\">`)",
    {"data-table", 3} =>
      "artifact: a canvas demo modifier written as `variant=` (`rounded|pill` are the pager `shape`; `size` is not an attr of `data_table`)",
    {"data-table", 4} =>
      "artifact: a placeholder `<.chip>` carrying `sort_dir`, an attr of another component (the sorted column header)",
    {"date-picker", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`sm|lg` are the `size`)",
    {"date-picker", 3} =>
      "artifact: a placeholder `<.chip>` carrying `skin`, an attr of `date_picker`",
    {"date-time-picker", 1} =>
      "artifact: a canvas demo modifier written as `variant=` (`sm` is the `size`)",
    {"description-list", 1} =>
      "naming decision: `list` is the name Phoenix's generated CoreComponents give their own `list/1`, so LedgerUI does not define it; use `description_list` (its `<:item title=\"...\">` is the same shape)",
    {"dropdown", 4} =>
      "artifact: a canvas demo modifier written as `variant=` (`media` is the variant of a `dropdown_item`, `color` is that of an item)",
    {"dropdown", 6} =>
      "artifact: a canvas demo modifier written as `variant=` (`default` is the variant of a `dropdown_item`)",
    {"empty-state-card", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`acc`, `pos` are the `tone` classes)",
    {"error-page", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`neg|warn|acc` are the `tone`: `error|warning|accent`)",
    {"fab", 1} =>
      "artifact: a canvas demo modifier written as `variant=` (`k-assistant`, `k-primary`, ... are the `color`)",
    {"fab", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`k-assistant` is the `color`)",
    {"fab", 3} =>
      "artifact: a canvas demo modifier written as `variant=` (`k-assistant` is the `color`)",
    {"fab", 4} =>
      "artifact: a canvas demo modifier written as `variant=` (`k-primary` is the `color`)",
    {"fab", 5} =>
      "artifact: a canvas demo modifier written as `variant=` (`k-light` is the `color`)",
    {"fab", 6} =>
      "artifact: a canvas demo modifier written as `variant=` (`k-*` are the `color`)",
    {"fab", 7} =>
      "artifact: a canvas demo modifier written as `variant=` (`k-*` are the `color`)",
    {"flow", 1} =>
      "artifact: a canvas demo modifier written as `variant=` (`acc|lime|info|warn` are the tones of the nodes)",
    {"glow-text", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`warm` is the `tone`)",
    {"icon", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`acc|pos|neg|warn|info` are the `tone`)",
    {"icon", 5} =>
      "artifact: a canvas demo modifier written as `variant=` (`acc|pos|neg|warn|info|lime` are the `tone`)",
    {"input-group", 1} =>
      "artifact: the literal `…` of the generator in `<.select … />` and `<.input … />`",
    {"input-group", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`sm|lg|pill|ok|err` are size, shape and state)",
    {"kanban", 1} =>
      "artifact: a canvas demo modifier written as `variant=` (`k-*` are the `color` of a column)",
    {"kanban", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`k-*` are the `color` of a column)",
    {"kpi-card", 3} =>
      "artifact: a placeholder `<.badge>` carrying `delta_tone`, an attr of `kpi_card`",
    {"landing-nav", 1} =>
      "artifact: a canvas demo modifier written as `variant=` (`acc` is a class of the demo; `variant` is `default|float|clear|tint|dark|mobile`)",
    {"landing-nav", 3} =>
      "artifact: `<.card variant=\"cards\">`; `cards` is the layout of `landing_mega`",
    {"menu", 1} =>
      "artifact: a canvas demo modifier written as `variant=` (`danger` is the tone of an item)",
    {"navbar", 3} =>
      "artifact: a canvas demo modifier written as `variant=` (`sm` is the `size`)",
    {"notification-center", 1} =>
      "artifact: a canvas demo modifier written as `variant=` (`unread` is the state of an item)",
    {"notification-center", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`pad` is a layout class; `color` is the tone of the empty state, not an attr)",
    {"pillbox", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`sm|lg|one` are the size and the overflow)",
    {"pixel-card", 1} =>
      "artifact: a canvas demo modifier written as `variant=` (`px-*` are the `color`)",
    {"pixel-card", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`px-*` are the `color`)",
    {"pixel-card", 3} =>
      "artifact: a canvas demo modifier written as `variant=` (`px-*` are the `color`)",
    {"prompt-suggestions", 1} =>
      "artifact: a canvas demo modifier written as `variant=` (`neg|pos|acc|lime` are the `tone` of the chips)",
    {"radio-choice", 5} =>
      "artifact: a canvas demo modifier written as `variant=` (`end` is the `control`: `<.radio_choice control=\"end\">`)",
    {"radio-choice", 6} =>
      "artifact: a canvas demo modifier written as `variant=` (`pill` is the `shape`)",
    {"select", 4} =>
      "artifact: a canvas demo modifier written as `variant=` (`sel` is the open state)",
    {"shell-floating", 1} =>
      "artifact: a canvas demo modifier written as `variant=` (`float` is the layout: `shell_floating` is that layout already)",
    {"shell", 1} =>
      "artifact: a canvas demo modifier written as `variant=` (`sidebar|framed` are the `layout`)",
    {"shell", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`sidebar|col|sideblock|framed` are the `layout`)",
    {"shell", 3} =>
      "artifact: placeholders carrying attrs of other components (`<.badge status>`, `<.chip variant>`, `<.switch variant=\"switch\">`, `<.shell color>`)",
    {"sidebar", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`sub` is a class of the demo; `variant` is `floating|sidebar|inset`)",
    {"stepper", 4} =>
      "artifact: a canvas demo modifier written as `variant=` (`vert` is the vertical `orientation`)",
    {"stepper", 5} =>
      "artifact: placeholders carrying attrs of other components (`<.badge color=\"accent\">`, `<.chip size>`)",
    {"table", 3} =>
      "artifact: a canvas demo modifier written as `variant=` (`r-row`, `r-top` are row classes)",
    {"tabs", 4} => "artifact: a placeholder `<.chip>` carrying `transition`, an attr of `tabs`",
    {"textarea", 3} =>
      "artifact: a canvas demo modifier written as `variant=` (`warn|over` are the counter states)",
    {"textarea", 6} =>
      "artifact: a canvas demo modifier written as `variant=` (`start` is the `counter_align`)",
    {"theme-picker", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`sel` is the selected state)",
    {"theme-switch", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`sm` is the `size`)",
    {"timeline", 1} =>
      "artifact: a canvas demo modifier written as `variant=` (`icon` is the marker `variant` of a `timeline_item`)",
    {"timeline", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`outline|icon|avatar|dot` are the marker variants of a `timeline_item`)",
    {"timeline", 3} =>
      "artifact: a canvas demo modifier written as `variant=` (`compact` is the `density`)",
    {"timeline", 5} =>
      "artifact: placeholders carrying attrs of other components (`<.chip density|variant>`, `<.badge tone>`)",
    {"tool", 1} =>
      "artifact: a canvas demo modifier written as `variant=` (`acc` is the running state)",
    {"tool", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`acc|warn|pos|neg` are the states)",
    {"typography", 9} =>
      "artifact: a canvas demo modifier written as `variant=` (`g-*` are the gradient classes; `gradient=\"amber-orange\"` is the attr)",
    {"upload", 2} =>
      "artifact: a canvas demo modifier written as `variant=` (`over` is the drag-over state: `over` attr)",
    {"upload", 3} =>
      "artifact: a canvas demo modifier written as `variant=` (`done|err` are file states: `state` of `upload_file`)"
  }

  @doc "`%{{id, n} => reason}`."
  def known, do: @known
end
