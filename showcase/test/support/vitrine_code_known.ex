defmodule LedgerShowcase.VitrineCodeKnown do
  @moduledoc """
  Vitrine sections whose HEEx `code` (design/vitrine/sec/<id>.json) does not compile cleanly against
  the library, with the first diagnostic. `test/vitrine_code_test.exs` fails when a section outside
  this list breaks AND when a listed one starts to compile (so the list can only shrink).

  The categories before the colon:

    * function: the snippet calls `<.id>` (the vitrine id) where the library API function has the
      README name (`progress_bar` -> `progress`, `number_stepper` -> `number_input`, ...) or none
    * attr / slot: an attribute or slot the component does not declare
    * value: a `variant="sm"`-style modifier of a canvas demo written as an attribute value, or an
      attr of another type

  "missing required ..." (a snippet without its `id`/label/slot) is not an API gap and is ignored.
  """

  @known %{
    {"accordion", 1} => "slot: undefined slot \"item\" for component Accordion.accordion/1",
    {"accordion", 2} => "slot: undefined slot \"item\" for component Accordion.accordion/1",
    {"action-button", 2} =>
      "attr+value: attribute \"variant\" in component Button.icon_button/1 must be one of [\"accent\", \"danger-soft\", \"default\", \"ghost\", \"primary\", \"soft\", \"topbar\", \"go\"],",
    {"action-button", 3} =>
      "attr+value: attribute \"size\" in component Button.icon_button/1 must be one of [\"sm\", \"md\", \"lg\"], got: \"xs\"",
    {"action-button", 4} =>
      "attr: undefined attribute \"color\" for component Button.icon_button/1",
    {"action-menu", 1} =>
      "slot: undefined slot \"trigger\" for component ActionMenu.action_menu/1",
    {"action-menu", 2} =>
      "attr+value: attribute \"variant\" in component Button.icon_button/1 must be one of [\"accent\", \"danger-soft\", \"default\", \"ghost\", \"primary\", \"soft\", \"topbar\", \"go\"],",
    {"ai-chat", 1} =>
      "value: attribute \"variant\" in component Ai.ai_chat/1 must be one of [\"card\", \"bare\", \"page\"], got: \"me\"",
    {"ai-chat", 2} =>
      "value: attribute \"variant\" in component Card.card/1 must be one of [\"default\", \"flat\", \"bordered\", \"outline\", \"muted\", \"soft\", \"filled\", \"solid\", \"glow\", \"gr",
    {"ai-message", 2} =>
      "value: attribute \"variant\" in component Ai.ai_message/1 must be one of [\"card\", \"plain\"], got: \"me\"",
    {"ai-tool-trace", 1} =>
      "attr: undefined attribute \"steps\" for component Ai.ai_tool_trace/1",
    {"alert", 2} => "attr: undefined attribute \"description\" for component Alert.alert/1",
    {"alert", 3} => "attr: undefined attribute \"description\" for component Alert.alert/1",
    {"alert", 4} =>
      "attr+value: attribute \"accent\" in component Alert.alert/1 must be one of [nil, \"\", \"top\", \"left\", \"right\"], got: true",
    {"badge", 6} =>
      "value: attribute \"variant\" in component Badge.badge/1 must be one of [\"solid\", \"glow\", \"soft\", \"outline\", \"flat\"], got: \"warn\"",
    {"bar-chart", 1} => "attr: undefined attribute \"data\" for component Chart.bar_chart/1",
    {"button", 4} =>
      "attr+value: attribute \"variant\" in component Button.icon_button/1 must be one of [\"accent\", \"danger-soft\", \"default\", \"ghost\", \"primary\", \"soft\", \"topbar\", \"go\"],",
    {"button", 5} =>
      "attr+value: attribute \"variant\" in component Button.icon_button/1 must be one of [\"accent\", \"danger-soft\", \"default\", \"ghost\", \"primary\", \"soft\", \"topbar\", \"go\"],",
    {"button", 6} =>
      "attr+value: attribute \"variant\" in component Button.icon_button/1 must be one of [\"accent\", \"danger-soft\", \"default\", \"ghost\", \"primary\", \"soft\", \"topbar\", \"go\"],",
    {"calendar", 1} => "attr: undefined attribute \"month\" for component Calendar.calendar/1",
    {"calendar", 2} =>
      "value: attribute \"variant\" in component Calendar.calendar/1 must be one of [\"full\", \"mini\"], got: \"sm\"",
    {"card-table", 4} => "attr: undefined attribute \"sort_dir\" for component Chip.chip/1",
    {"card", 5} => "attr+value: undefined attribute \"align\" for component Card.card/1",
    {"carousel", 1} =>
      "value: attribute \"variant\" in component Carousel.carousel/1 must be one of [\"canvas\", \"classic\"], got: \"fade\"",
    {"carousel", 3} => "attr: undefined attribute \"navigation\" for component Chip.chip/1",
    {"cash-timer", 1} =>
      "attr: undefined attribute \"variant\" for component CashTimer.cash_timer/1",
    {"cash-timer", 2} =>
      "attr: undefined attribute \"variant\" for component CashTimer.cash_timer/1",
    {"checkbox", 5} =>
      "value: attribute \"variant\" in component Checkbox.checkbox/1 must be one of [\"basic\", \"outline\"], got: \"card\"",
    {"clipboard", 4} => "attr: undefined attribute \"color\" for component Button.icon_button/1",
    {"collapse", 1} => "slot: undefined slot \"item\" for component Accordion.accordion/1",
    {"color-picker", 1} =>
      "attr: undefined attribute \"swatches\" for component ColorPicker.color_picker/1",
    {"color-picker", 2} =>
      "value: attribute \"variant\" in component ColorPicker.color_picker/1 must be one of [\"full\", \"swatches\"], got: \"sm\"",
    {"command-palette-dialog", 1} => "function: undefined function command_palette_dialog/1",
    {"command-palette-dialog", 2} => "function: undefined function command_palette_dialog/1",
    {"command-palette-dialog", 3} => "function: undefined function command_palette_dialog/1",
    {"comment-editor", 1} => "function: undefined function comment_editor/1",
    {"container", 1} => "function: undefined function container/1",
    {"container", 2} => "function: undefined function container/1",
    {"context-menu", 1} =>
      "attr+slot: undefined attribute \"placement\" for component ContextMenu.context_menu/1",
    {"context-menu", 2} =>
      "attr: undefined attribute \"variant\" for component ContextMenu.context_menu/1",
    {"conversation-list", 1} =>
      "attr: undefined attribute \"current\" for component Ai.conversation_list/1",
    {"cover-card", 1} => "function: undefined function cover_card/1",
    {"data-table", 3} =>
      "attr+value: attribute \"variant\" in component DataTable.data_table/1 must be one of [\"advanced\", \"grid\"], got: \"rounded\"",
    {"data-table", 4} => "attr: undefined attribute \"sort_dir\" for component Chip.chip/1",
    {"date-picker", 1} =>
      "attr: undefined attribute \"range\" for component DatePicker.date_picker/1",
    {"date-picker", 2} =>
      "attr: undefined attribute \"variant\" for component DatePicker.date_picker/1",
    {"date-picker", 3} => "attr: undefined attribute \"skin\" for component Chip.chip/1",
    {"date-time-picker", 1} => "function: undefined function date_time_picker/1",
    {"description-list", 1} => "function: undefined function list/1",
    {"description-list", 2} =>
      "attr: undefined attribute \"variant\" for component DescriptionList.description_list/1",
    {"divider", 1} => "attr: undefined attribute \"label\" for component Divider.divider/1",
    {"divider", 2} => "attr: undefined attribute \"label\" for component Divider.divider/1",
    {"drawer", 1} => "slot: undefined slot \"title\" for component Drawer.drawer/1",
    {"drawer", 2} => "slot: undefined slot \"title\" for component Drawer.drawer/1",
    {"drawer", 3} => "attr: undefined attribute \"floating\" for component Drawer.drawer/1",
    {"dropdown", 1} => "slot: undefined slot \"trigger\" for component Dropdown.dropdown/1",
    {"dropdown", 3} =>
      "attr+value: attribute \"variant\" in component Button.icon_button/1 must be one of [\"accent\", \"danger-soft\", \"default\", \"ghost\", \"primary\", \"soft\", \"topbar\", \"go\"],",
    {"dropdown", 4} => "attr: undefined attribute \"variant\" for component Dropdown.dropdown/1",
    {"dropdown", 5} => "slot: undefined slot \"trigger\" for component Dropdown.dropdown/1",
    {"dropdown", 6} => "attr: undefined attribute \"variant\" for component Dropdown.dropdown/1",
    {"empty-state-card", 1} => "function: undefined function empty_state_card/1",
    {"empty-state-card", 2} => "function: undefined function empty_state_card/1",
    {"error-page", 2} =>
      "attr: undefined attribute \"variant\" for component ErrorPage.error_page/1",
    {"fab", 1} =>
      "value: attribute \"variant\" in component Fab.fab/1 must be one of [\"canvas\", \"pill\"], got: \"k-assistant\"",
    {"fab", 2} =>
      "value: attribute \"variant\" in component Fab.fab/1 must be one of [\"canvas\", \"pill\"], got: \"k-assistant\"",
    {"fab", 3} =>
      "value: attribute \"variant\" in component Fab.fab/1 must be one of [\"canvas\", \"pill\"], got: \"k-assistant\"",
    {"fab", 4} =>
      "value: attribute \"variant\" in component Fab.fab/1 must be one of [\"canvas\", \"pill\"], got: \"k-primary\"",
    {"fab", 5} =>
      "value: attribute \"variant\" in component Fab.fab/1 must be one of [\"canvas\", \"pill\"], got: \"k-light\"",
    {"fab", 6} =>
      "value: attribute \"variant\" in component Fab.fab/1 must be one of [\"canvas\", \"pill\"], got: \"k-assistant\"",
    {"fab", 7} =>
      "value: attribute \"variant\" in component Fab.fab/1 must be one of [\"canvas\", \"pill\"], got: \"k-dark\"",
    {"filter-menu", 1} =>
      "slot: undefined slot \"trigger\" for component FilterMenu.filter_menu/1",
    {"flow", 1} => "attr: undefined attribute \"variant\" for component Flow.flow/1",
    {"form-section", 2} =>
      "attr: undefined attribute \"variant\" for component FormSection.form_section/1",
    {"glow-text", 2} =>
      "attr: undefined attribute \"variant\" for component GlowText.glow_text/1",
    {"hero-card", 1} => "function: undefined function progress_bar/1",
    {"hero-card", 4} =>
      "attr: undefined attribute \"current\" for component StepGroup.step_group/1",
    {"icon-rail", 1} => "function: undefined function icon_rail/1",
    {"icon", 2} => "attr: undefined attribute \"variant\" for component Icon.icon/1",
    {"icon", 5} => "attr: undefined attribute \"variant\" for component Icon.icon/1",
    {"illustration", 1} =>
      "attr: undefined attribute \"color\" for component Illustration.illustration/1",
    {"illustration", 2} =>
      "attr: undefined attribute \"color\" for component Illustration.illustration/1",
    {"inline-empty", 1} => "function: undefined function inline_empty/1",
    {"input-group", 1} => "attr: undefined attribute \"…\" for component Select.select/1",
    {"input-group", 2} =>
      "value: attribute \"variant\" in component InputGroup.input_group/1 must be one of [\"outlined\", \"filled\"], got: \"sm\"",
    {"kanban", 1} => "attr: undefined attribute \"variant\" for component Kanban.kanban/1",
    {"kanban", 2} => "attr: undefined attribute \"variant\" for component Kanban.kanban/1",
    {"kpi-card", 3} => "attr: undefined attribute \"delta_tone\" for component Badge.badge/1",
    {"landing-nav", 1} =>
      "value: attribute \"variant\" in component LandingNav.landing_nav/1 must be one of [\"default\", \"float\", \"clear\", \"tint\", \"dark\", \"mobile\"], got: \"acc\"",
    {"landing-nav", 3} =>
      "value: attribute \"variant\" in component Card.card/1 must be one of [\"default\", \"flat\", \"bordered\", \"outline\", \"muted\", \"soft\", \"filled\", \"solid\", \"glow\", \"gr",
    {"logo", 1} => "attr: undefined attribute \"name\" for component Logo.logo/1",
    {"logo", 2} => "attr: undefined attribute \"name\" for component Logo.logo/1",
    {"logo", 3} => "attr: undefined attribute \"name\" for component Logo.logo/1",
    {"logo", 4} => "attr: undefined attribute \"name\" for component Logo.logo/1",
    {"logo", 5} => "attr: undefined attribute \"name\" for component Logo.logo/1",
    {"menu", 1} => "function: undefined function menu/1",
    {"modal", 1} => "slot: undefined slot \"title\" for component Modal.modal/1",
    {"modal", 2} => "attr+slot: undefined attribute \"show\" for component Modal.modal/1",
    {"modal", 3} => "slot: undefined slot \"title\" for component Modal.modal/1",
    {"navbar", 1} =>
      "value: attribute \"variant\" in component Navbar.navbar/1 must be one of [\"default\", \"float\", \"clear\", \"dense\", \"mobile\"], got: \"canvas\"",
    {"navbar", 2} =>
      "value: attribute \"variant\" in component Navbar.navbar/1 must be one of [\"default\", \"float\", \"clear\", \"dense\", \"mobile\"], got: \"canvas\"",
    {"navbar", 3} =>
      "value: attribute \"variant\" in component Navbar.navbar/1 must be one of [\"default\", \"float\", \"clear\", \"dense\", \"mobile\"], got: \"sm\"",
    {"notification-center", 1} =>
      "value: attribute \"variant\" in component NotificationCenter.notification_center/1 must be one of [\"canvas\", \"classic\"], got: \"unread\"",
    {"notification-center", 2} =>
      "attr+value: attribute \"variant\" in component NotificationCenter.notification_center/1 must be one of [\"canvas\", \"classic\"], got: \"pad\"",
    {"number-stepper", 1} => "function: undefined function number_stepper/1",
    {"number-stepper", 2} => "function: undefined function number_stepper/1",
    {"number-stepper", 3} => "function: undefined function number_stepper/1",
    {"number-stepper", 4} => "function: undefined function number_stepper/1",
    {"number-stepper", 5} => "function: undefined function number_stepper/1",
    {"page-header", 2} =>
      "attr: undefined attribute \"active\" in slot \"tab\" for component Tabs.tabs/1",
    {"pagination", 2} =>
      "attr: undefined attribute \"variant\" for component Pagination.pagination/1",
    {"password-input", 3} =>
      "attr: undefined attribute \"strength\" for component PasswordInput.password_input/1",
    {"pillbox", 2} => "attr: undefined attribute \"variant\" for component Pillbox.pillbox/1",
    {"pixel-card", 1} =>
      "attr: undefined attribute \"variant\" for component PixelCard.pixel_card/1",
    {"pixel-card", 2} =>
      "attr: undefined attribute \"variant\" for component PixelCard.pixel_card/1",
    {"pixel-card", 3} =>
      "attr: undefined attribute \"variant\" for component PixelCard.pixel_card/1",
    {"progress-bar", 2} => "function: undefined function progress_bar/1",
    {"progress-bar", 3} => "function: undefined function progress_bar/1",
    {"progress-bar", 4} => "function: undefined function progress_bar/1",
    {"progress-bar", 5} => "function: undefined function progress_bar/1",
    {"progress-bar", 8} => "function: undefined function progress_bar/1",
    {"prompt-suggestions", 1} =>
      "value: attribute \"variant\" in component Ai.prompt_suggestions/1 must be one of [\"card\", \"pill\", \"grid\"], got: \"neg\"",
    {"radio-choice", 1} => "slot: undefined slot \"option\" for component Segmented.segmented/1",
    {"radio-choice", 2} => "function: undefined function radio/1",
    {"radio-choice", 3} => "function: undefined function radio/1",
    {"radio-choice", 4} => "function: undefined function radio/1",
    {"radio-choice", 5} => "function: undefined function radio_choice/1",
    {"radio-choice", 6} => "function: undefined function radio_choice/1",
    {"radio-choice", 7} => "function: undefined function radio_choice/1",
    {"range-slider", 1} => "function: undefined function range_slider/1",
    {"range-slider", 2} => "function: undefined function range_slider/1",
    {"range-slider", 3} => "function: undefined function range_slider/1",
    {"range-slider", 4} => "function: undefined function range_slider/1",
    {"range-slider", 5} => "function: undefined function range_slider/1",
    {"rich-text-editor", 1} => "function: undefined function rich_text_editor/1",
    {"scrollspy", 1} =>
      "attr: undefined attribute \"target\" for component Scrollspy.scrollspy/1",
    {"segmented", 1} => "slot: undefined slot \"option\" for component Segmented.segmented/1",
    {"segmented", 2} => "slot: undefined slot \"option\" for component Segmented.segmented/1",
    {"select", 4} =>
      "value: attribute \"variant\" in component Select.select/1 must be one of [\"outline\", \"filled\"], got: \"sel\"",
    {"sheet", 1} => "function: undefined function sheet/1",
    {"shell-floating", 1} => "function: undefined function shell_floating/1",
    {"shell", 1} =>
      "value: attribute \"variant\" in component Shell.shell/1 must be one of [\"app\", \"preview\"], got: \"sidebar\"",
    {"shell", 2} =>
      "value: attribute \"variant\" in component Shell.shell/1 must be one of [\"app\", \"preview\"], got: \"sidebar\"",
    {"shell", 3} => "attr+value: undefined attribute \"status\" for component Badge.badge/1",
    {"sidebar", 1} =>
      "attr+slot+value: attribute \"current\" in component Sidebar.sidebar/1 must be a :string, got: :overview",
    {"sidebar", 2} =>
      "value: attribute \"variant\" in component Sidebar.sidebar/1 must be one of [\"floating\", \"sidebar\", \"inset\"], got: \"sub\"",
    {"status-toast", 1} =>
      "attr: undefined attribute \"status\" for component Toast.status_toast/1",
    {"step-group", 1} =>
      "attr: undefined attribute \"steps\" for component StepGroup.step_group/1",
    {"step-group", 2} =>
      "attr: undefined attribute \"steps\" for component StepGroup.step_group/1",
    {"stepper", 4} =>
      "value: attribute \"variant\" in component Steps.stepper/1 must be one of [\"canvas\", \"classic\"], got: \"vert\"",
    {"stepper", 5} =>
      "attr+value: attribute \"color\" in component Badge.badge/1 must be one of [\"neutral\", \"primary\", \"secondary\", \"info\", \"success\", \"warning\", \"error\", \"dark\", \"light\"",
    {"sub-nav", 1} => "function: undefined function sub_nav/1",
    {"table", 3} =>
      "value: attribute \"variant\" in component Table.table/1 must be one of [nil, \"basic\", \"bordered\", \"hoverable\", \"zebra\", \"grid\", \"data\", \"data-grid\", \"flat\"], g",
    {"tabs", 2} =>
      "attr: undefined attribute \"active\" in slot \"tab\" for component Tabs.tabs/1",
    {"tabs", 3} =>
      "attr: undefined attribute \"active\" in slot \"tab\" for component Tabs.tabs/1",
    {"tabs", 4} =>
      "attr: undefined attribute \"active\" in slot \"tab\" for component Tabs.tabs/1",
    {"textarea", 3} =>
      "value: attribute \"variant\" in component Textarea.textarea/1 must be one of [\"outlined\", \"filled\", \"plain\"], got: \"warn\"",
    {"textarea", 6} =>
      "value: attribute \"variant\" in component Textarea.textarea/1 must be one of [\"outlined\", \"filled\", \"plain\"], got: \"start\"",
    {"theme-picker", 1} =>
      "attr: undefined attribute \"current\" for component ThemePicker.theme_picker/1",
    {"theme-picker", 2} =>
      "value: attribute \"variant\" in component ThemePicker.theme_picker/1 must be one of [\"menu\", \"grid\"], got: \"sel\"",
    {"theme-switch", 2} =>
      "value: attribute \"variant\" in component ThemeSwitch.theme_switch/1 must be one of [\"segmented\", \"icons\", \"switch\"], got: \"sm\"",
    {"time-picker", 1} =>
      "attr: undefined attribute \"step\" for component TimePicker.time_picker/1",
    {"timeline", 1} =>
      "value: attribute \"variant\" in component Timeline.timeline/1 must be one of [\"line\", \"canvas\"], got: \"icon\"",
    {"timeline", 2} =>
      "value: attribute \"variant\" in component Timeline.timeline/1 must be one of [\"line\", \"canvas\"], got: \"outline\"",
    {"timeline", 3} =>
      "value: attribute \"variant\" in component Timeline.timeline/1 must be one of [\"line\", \"canvas\"], got: \"compact\"",
    {"timeline", 4} => "attr: undefined attribute \"items\" for component Timeline.timeline/1",
    {"timeline", 5} => "attr: undefined attribute \"density\" for component Chip.chip/1",
    {"timer", 3} => "attr: undefined attribute \"seconds\" for component Timer.timer/1",
    {"toast-card", 2} =>
      "attr: undefined attribute \"status\" for component Toast.status_toast/1",
    {"toast-card", 4} =>
      "attr: undefined attribute \"status\" for component Toast.status_toast/1",
    {"toast-card", 5} =>
      "attr: undefined attribute \"status\" for component Toast.status_toast/1",
    {"toaster", 1} => "slot: undefined slot \"option\" for component Segmented.segmented/1",
    {"toaster", 2} => "attr: undefined attribute \"status\" for component Toast.status_toast/1",
    {"toaster", 6} => "attr: undefined attribute \"status\" for component Toast.status_toast/1",
    {"tool", 1} =>
      "value: attribute \"variant\" in component Tool.tool/1 must be one of [\"line\", \"panel\"], got: \"acc\"",
    {"tool", 2} =>
      "value: attribute \"variant\" in component Tool.tool/1 must be one of [\"line\", \"panel\"], got: \"acc\"",
    {"tooltip", 1} => "slot: undefined slot \"trigger\" for component Tooltip.tooltip/1",
    {"tooltip", 2} => "slot: undefined slot \"trigger\" for component Tooltip.tooltip/1",
    {"tooltip", 3} => "slot: undefined slot \"trigger\" for component Tooltip.tooltip/1",
    {"tooltip", 4} => "attr: undefined attribute \"content\" for component Tooltip.tooltip/1",
    {"trace", 1} => "attr: undefined attribute \"spans\" for component Trace.trace/1",
    {"treeview", 1} => "attr: undefined attribute \"icon\" for component Treeview.tree_item/1",
    {"treeview", 2} => "attr: undefined attribute \"icon\" for component Treeview.tree_item/1",
    {"treeview", 3} => "function: undefined function tree/1",
    {"typography", 9} => "function: undefined function typography/1",
    {"upload", 2} =>
      "value: attribute \"variant\" in component Upload.upload/1 must be one of [\"canvas\", \"pond\", \"solid\", \"glow\", \"outline\", \"soft\", \"bordered\", \"flat\", \"glass\", \"d",
    {"upload", 3} =>
      "value: attribute \"variant\" in component Upload.upload/1 must be one of [\"canvas\", \"pond\", \"solid\", \"glow\", \"outline\", \"soft\", \"bordered\", \"flat\", \"glass\", \"d",
    {"view-switcher", 1} => "slot: undefined slot \"option\" for component Segmented.segmented/1"
  }

  @doc "`%{{id, n} => reason}`."
  def known, do: @known
end
