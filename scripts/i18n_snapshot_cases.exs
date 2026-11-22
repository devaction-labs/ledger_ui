# Hand-picked renders of the text-heavy components, in the states that show their default texts.
# Evaluated by `scripts/i18n_snapshot.exs` (extra argument): returns a list of strings.
#
alias LedgerUI.Components, as: C

slot = fn name, text, attrs ->
  Map.merge(%{__slot__: name, inner_block: fn _, _ -> text end}, attrs)
end

s = fn name, text -> slot.(name, text, %{}) end
rows = [%{id: 1, name: "Ana", qty: 3}, %{id: 2, name: "Bia", qty: 5}]

col = fn label, key, extra ->
  slot.(:col, "cell", Map.merge(%{label: label, key: key}, extra))
end

opts = [{"Ana", "a"}, {"Bia", "b"}, {"Caio", "c"}]
today = ~D[2026-11-19]

cases = [
  {"bulk_bar", C.BulkBar, :bulk_bar,
   %{id: "bb", count: 3, total: 10, on_clear: "clear", on_select_all: "all", show_esc: true}},
  {"bulk_bar one", C.BulkBar, :bulk_bar, %{id: "bb1", count: 1, on_clear: "clear"}},
  {"bulk_bar inline", C.BulkBar, :bulk_bar,
   %{id: "bb2", count: 2, total: 9, on_clear: "clear", on_select_all: "all", variant: "inline"}},
  {"bulk_bar float", C.BulkBar, :bulk_bar,
   %{id: "bb3", count: 2, on_clear: "clear", variant: "float", progress: 3, progress_max: 9}},
  {"bulk_bar action", C.BulkBar, :bulk_bar,
   %{
     id: "bb4",
     count: 2,
     on_clear: "clear",
     action: [slot.(:action, "Go", %{confirm: "do", confirm_text: "Sure?"})]
   }},
  {"pagination", C.Pagination, :pagination,
   %{
     page: 3,
     total_pages: 10,
     page_sizes: [10, 25],
     page_size: 10,
     total_entries: 95,
     on_change: "pg",
     on_page_size: "ps"
   }},
  {"pagination sides", C.Pagination, :pagination,
   %{page: 1, total_pages: 3, arrows_at: "sides", variant: "canvas", on_change: "pg"}},
  {"select", C.Select, :select,
   %{
     id: "sel",
     name: "s",
     options: opts,
     multiple: true,
     footer: true,
     create: true,
     clearable: true,
     removable: true,
     value: ["a"],
     search: "panel"
   }},
  {"select single", C.Select, :select,
   %{id: "sel2", name: "s2", options: opts, clearable: true, value: "a"}},
  {"select native", C.Select, :select,
   %{id: "sel3", name: "s3", options: opts, native: true, prompt: "Pick"}},
  {"autocomplete", C.Autocomplete, :autocomplete,
   %{id: "ac", name: "ac", options: opts, clearable: true, create: true, on_search: "q"}},
  {"tags_input", C.TagsInput, :tags_input,
   %{
     id: "ti",
     name: "ti",
     value: ["a", "b"],
     removable: true,
     clearable: true,
     max: 3,
     suggestions: opts,
     create: true
   }},
  {"pillbox", C.Pillbox, :pillbox,
   %{id: "pb", name: "pb", options: opts, value: ["a", "b"], clearable: true, create: true}},
  {"phone_input", C.PhoneInput, :phone_input,
   %{id: "ph", name: "ph", clearable: true, value: "+5511987654321"}},
  {"phone_input en", C.PhoneInput, :phone_input, %{id: "ph2", name: "ph2", locale: "en"}},
  {"number_input", C.NumberInput, :number_input,
   %{id: "ni", name: "ni", steppers: true, value: 3}},
  {"number_input en", C.NumberInput, :number_input,
   %{id: "ni2", name: "ni2", steppers: true, value: 3, locale: "en"}},
  {"rating", C.Rating, :rating, %{id: "r", name: "r", value: 3.5}},
  {"rating_distribution", C.Rating, :rating_distribution,
   %{average: 4.5, counts: [800, 310, 110, 40, 24]}},
  {"otp", C.OtpInput, :otp_input, %{id: "otp", name: "otp"}},
  {"password", C.PasswordInput, :password_input, %{id: "pw", name: "pw"}},
  {"range", C.Range, :range, %{id: "rg", name: "rg", label: "L", value: 3}},
  {"range pair", C.Range, :range,
   %{id: "rg2", start_name: "a", end_name: "b", label: "L", value: [2, 4]}},
  {"toaster", C.Toast, :toaster, %{id: "t"}},
  {"toast_card", C.Toast, :toast_card,
   %{id: "tc", title: "Saved", busy: true, dismissible: true}},
  {"notification_center", C.NotificationCenter, :notification_center,
   %{id: "nc", items: [], unread: 2}},
  {"notification_center open", C.NotificationCenter, :notification_center,
   %{
     id: "nc2",
     items: [%{id: 1, text: "A", unread: true, time: "now"}],
     unread: 1,
     open: true,
     on_read_all: "ra",
     all_href: "/n",
     preferences_href: "/p"
   }},
  {"upload_drop", C.Upload, :upload_drop, %{}},
  {"upload_file", C.Upload, :upload_file,
   %{name: "a.pdf", status: "x", progress: 40, on_remove: "rm"}},
  {"upload_file error", C.Upload, :upload_file,
   %{name: "a.pdf", state: "error", on_remove: "rm", on_retry: "rt"}},
  {"drawer", C.Drawer, :drawer, %{id: "dr", title: "T", inner_block: [s.(:inner_block, "body")]}},
  {"modal", C.Modal, :modal, %{id: "md", title: "T", inner_block: [s.(:inner_block, "body")]}},
  {"table", C.Table, :table,
   %{
     id: "tb",
     rows: rows,
     selected: [],
     on_select: "sel",
     on_select_all: "sela",
     col: [col.("Name", :name, %{}), col.("Qty", :qty, %{copy: fn r -> r.name end})],
     expand: [],
     on_sort: "sort"
   }},
  {"data_table", C.DataTable, :data_table,
   %{
     id: "dt",
     rows: rows,
     total: 25,
     page: 2,
     page_size: 10,
     on_search: "s",
     search: "",
     on_page: "p",
     col: [col.("Name", :name, %{})],
     page_sizes: [10, 25],
     on_page_size: "ps"
   }},
  {"data_table grid", C.DataTable, :data_table,
   %{
     id: "dt2",
     rows: rows,
     total: 25,
     page: 2,
     page_size: 10,
     variant: "grid",
     pager: "pages",
     col: [col.("Name", :name, %{})]
   }},
  {"data_table loading", C.DataTable, :data_table,
   %{id: "dt3", rows: [], loading: true, col: [col.("Name", :name, %{})]}},
  {"table_toolbar", C.DataTable, :table_toolbar,
   %{
     id: "tt",
     search: "",
     on_search: "s",
     filters: [%{id: "f1", label: "Status: Open"}],
     on_clear: "c"
   }},
  {"card_table", C.CardTable, :card_table,
   %{
     id: "ct",
     rows: rows,
     col: [col.("Name", :name, %{})],
     selection: [s.(:selection, "sel")],
     selected: [1, 2],
     error: "boom",
     on_retry: "retry"
   }},
  {"card_table sel", C.CardTable, :card_table,
   %{
     id: "ct2",
     rows: rows,
     col: [col.("Name", :name, %{})],
     selection: [s.(:selection, "sel")],
     selected: [1],
     on_select: "s"
   }},
  {"calendar", C.Calendar, :calendar,
   %{
     id: "cal",
     view: "month",
     date: today,
     events: [
       %{date: today, title: "E1"},
       %{date: today, title: "E2"},
       %{date: today, title: "E3"},
       %{date: today, title: "E4"},
       %{date: today, title: "E5"}
     ]
   }},
  {"calendar week", C.Calendar, :calendar,
   %{id: "cal2", view: "week", date: today, events: [%{date: today, title: "E1", all_day: true}]}},
  {"due_calendar", C.Calendar, :due_calendar,
   %{
     items: [
       %{date: today, title: "A", amount: 10},
       %{date: ~D[2026-11-10], title: "B", amount: 1234.5},
       %{date: ~D[2026-11-30], title: "C"}
     ],
     today: today
   }},
  {"date_picker", C.DatePicker, :date_picker,
   %{id: "dp", name: "dp", value: "2026-11-05", today: today}},
  {"date_picker range", C.DatePicker, :date_picker,
   %{id: "dp2", start_name: "a", end_name: "b", mode: "range", today: today}},
  {"date_picker inline", C.DatePicker, :date_picker,
   %{id: "dp3", name: "dp3", inline: true, today: today}},
  {"datetime_picker", C.DatetimePicker, :datetime_picker,
   %{id: "dtp", name: "dtp", today: today}},
  {"datetime_picker range", C.DatetimePicker, :datetime_picker,
   %{id: "dtp2", name: "dtp2", mode: "range", today: today}},
  {"time_picker", C.TimePicker, :time_picker, %{id: "tp", name: "tp"}},
  {"color_picker", C.ColorPicker, :color_picker,
   %{id: "cp", name: "cp", value: "#4C3FE0", alpha: true, inline: true}},
  {"signature_pad", C.SignaturePad, :signature_pad, %{id: "sp", name: "sp"}},
  {"error_page 404", C.ErrorPage, :error_page, %{code: 404, request_id: "r-1"}},
  {"error_page 500", C.ErrorPage, :error_page, %{code: "500"}},
  {"error_page xx", C.ErrorPage, :error_page, %{code: "999"}},
  {"error_state", C.ErrorPage, :error_state, %{code: 429}},
  {"steps", C.Steps, :steps,
   %{step: [%{label: "A", state: "done"}, %{label: "B", state: "current"}, %{label: "C"}]}},
  {"stepper", C.Steps, :stepper,
   %{step: [%{label: "A", state: "done"}, %{label: "B", state: "error"}, %{label: "C"}]}},
  {"tool", C.Tool, :tool, %{id: "to", state: "running", title: "x"}},
  {"tool error", C.Tool, :tool, %{id: "to2", state: "error", title: "x"}},
  {"tool_approval", C.Tool, :tool_approval, %{id: "ta", subject: "ls"}},
  {"tabs soon", C.Tabs, :tabs,
   %{
     id: "tabs",
     tab: [slot.(:tab, "A", %{name: "a", soon: true}), slot.(:tab, "B", %{name: "b"})]
   }},
  {"text_editor", C.TextEditor, :text_editor,
   %{id: "te", name: "te", slash: true, footer: true, mentions: [%{id: "1", name: "Ana"}]}},
  {"comment_editor", C.TextEditor, :comment_editor, %{id: "ce", name: "ce", on_submit: "send"}},
  {"dropdown_footer", C.Dropdown, :dropdown_footer, %{apply_count: 3}},
  {"dropdown", C.Dropdown, :dropdown,
   %{id: "dd", label: nil, trigger: [s.(:trigger, "x")], inner_block: [s.(:inner_block, "i")]}},
  {"filter_menu", C.FilterMenu, :filter_menu,
   %{
     id: "fm",
     groups: [
       %{name: "f[a]", label: "A", options: [{"One", "1"}, {"Two", "2"}], display: :submenu}
     ],
     results: 4
   }},
  {"filter_menu empty", C.FilterMenu, :filter_menu, %{id: "fm2", groups: []}},
  {"command_palette", C.CommandPalette, :command_palette,
   %{id: "cmd", items: [%{group: "G", label: "L", value: "v"}], inline: true}},
  {"command_palette empty", C.CommandPalette, :command_palette,
   %{id: "cmd2", items: [], query: "zzz", inline: true}},
  {"email", C.Email, :email_layout,
   %{
     subject: "S",
     title: "T",
     body: [s.(:body, "b")],
     action: [slot.(:action, "Go", %{href: "https://x.y"})]
   }},
  {"skeleton_group", C.Skeleton, :skeleton_group, %{inner_block: [s.(:inner_block, "x")]}},
  {"spinner", C.Spinner, :spinner, %{}},
  {"spinner nil", C.Spinner, :spinner, %{label: nil}},
  {"timer", C.Timer, :timer, %{id: "tm", total: 60}},
  {"theme_switch", C.ThemeSwitch, :theme_switch, %{id: "ts", system: true}},
  {"theme_switch cards", C.ThemeSwitch, :theme_switch,
   %{id: "ts2", variant: "cards", system: true}},
  {"theme_switch switch", C.ThemeSwitch, :theme_switch, %{id: "ts3", variant: "switch"}},
  {"theme_toggle", C.ThemeSwitch, :theme_toggle, %{}},
  {"theme_picker", C.ThemePicker, :theme_picker, %{id: "tpk"}},
  {"navbar_search", C.Navbar, :navbar_search, %{}},
  {"navbar_bell", C.Navbar, :navbar_bell, %{count: 2}},
  {"navbar_lang", C.Navbar, :navbar_lang, %{locales: ["PT", "EN"]}},
  {"navbar_crumbs", C.Navbar, :navbar_crumbs,
   %{items: [%{label: "A", href: "/a"}, %{label: "B"}]}},
  {"navbar_user", C.Navbar, :navbar_user, %{user: %{name: "Ana", email: "a@b.c"}}},
  {"breadcrumb", C.Breadcrumb, :breadcrumb,
   %{
     id: "bc",
     item: [s.(:item, "A"), s.(:item, "B"), s.(:item, "C"), s.(:item, "D"), s.(:item, "E")],
     max: 3
   }},
  {"alert", C.Alert, :alert, %{dismissible: true, title: "T"}},
  {"badge", C.Badge, :badge, %{on_remove: "rm", id: "bd", inner_block: [s.(:inner_block, "B")]}},
  {"chip", C.Chip, :chip, %{on_remove: "rm", label: "Chip", id: "ch"}},
  {"tag", C.Tag, :tag, %{on_remove: "rm", id: "tg", inner_block: [s.(:inner_block, "T")]}},
  {"button loading", C.Button, :button,
   %{loading: true, inner_block: [s.(:inner_block, "Save")]}},
  {"accordion_item", C.Accordion, :accordion_item,
   %{id: "ai", header: [s.(:header, "H")], inner_block: [s.(:inner_block, "b")]}},
  {"carousel", C.Carousel, :carousel,
   %{id: "car", slides: 3, inner_block: [s.(:inner_block, "x")], thumb: [s.(:thumb, "t")]}},
  {"clipboard", C.Clipboard, :clipboard, %{id: "cb", value: "x"}},
  {"clipboard_input", C.Clipboard, :clipboard_input, %{id: "cbi", value: "x"}},
  {"code_block", C.CodeBlock, :code_block, %{id: "cdb", code: "a = 1"}},
  {"collapse_text", C.Collapse, :collapse_text,
   %{id: "col", inner_block: [s.(:inner_block, "long")]}},
  {"connection_banner", C.ConnectionBanner, :connection_banner, %{}},
  {"connection_banner preview", C.ConnectionBanner, :connection_banner,
   %{preview: true, state: "re"}},
  {"connection_banner cycle", C.ConnectionBanner, :connection_banner,
   %{preview: true, state: "cycle"}},
  {"flow_panel_head", C.Flow, :flow_panel_head, %{title: "T"}},
  {"empty_box", C.Illustration, :empty_box, %{}},
  {"image_input", C.ImageInput, :image_input, %{id: "ii", name: "ii"}},
  {"kpi_card live", C.KpiCard, :kpi_card, %{label: "L", value: "1", live: true}},
  {"landing_nav", C.LandingNav, :landing_nav,
   %{id: "ln", link: [slot.(:link, "A", %{href: "#"})]}},
  {"landing_announcement", C.LandingNav, :landing_announcement,
   %{id: "la", link_label: "More", inner_block: [s.(:inner_block, "x")]}},
  {"menu_row", C.MenuList, :menu_row, %{unread: true, title: "T"}},
  {"placement_stage", C.PlacementStage, :placement_stage, %{id: "ps", src: "/x.png"}},
  {"progress_ring", C.Progress, :progress_ring, %{value: 40}},
  {"scrollspy", C.Scrollspy, :scrollspy, %{id: "sc", item: [slot.(:item, "A", %{href: "#a"})]}},
  {"scrollspy nil", C.Scrollspy, :scrollspy,
   %{id: "sc2", label: nil, item: [slot.(:item, "A", %{href: "#a"})]}},
  {"step_group", C.StepGroup, :step_group,
   %{id: "sg", panel_id: "p", step: [slot.(:step, "x", %{title: "S"})]}},
  {"textarea", C.Textarea, :textarea, %{id: "ta1", name: "ta1", counter: true, min_length: 5}},
  {"textarea max", C.Textarea, :textarea,
   %{id: "ta2", name: "ta2", counter: true, maxlength: 20}},
  {"view_switcher", C.ViewSwitcher, :view_switcher,
   %{
     id: "vs",
     options: [%{label: "T", value: "t", icon: "table"}],
     saved: [%{label: "S", value: "s"}],
     on_add: "add"
   }},
  {"context_menu", C.ContextMenu, :context_menu,
   %{id: "cm", inner_block: [s.(:inner_block, "x")], item: [slot.(:item, "I", %{})]}},
  {"ai_chat", C.Ai, :ai_chat, %{id: "chat", messages: [], on_send: "s"}},
  {"ai_chat msgs", C.Ai, :ai_chat,
   %{
     id: "chat2",
     on_send: "s",
     messages: [
       %{id: 1, role: "user", content: "hi", name: "Ana"},
       %{id: 2, role: "assistant", content: "hello", actions: ["copy", "useful"]},
       %{
         id: 3,
         proposal: %{
           id: "p",
           title: "Do it",
           status: "pending",
           change: [%{label: "A", from: "1", to: "2"}]
         }
       }
     ]
   }},
  {"ai_insights", C.Ai, :ai_insights,
   %{count: 3, on_chat: "chat", insights: [%{title: "T", text: "x"}]}},
  {"ai_promo", C.Ai, :ai_promo, %{count: 2}},
  {"ai_promo rail", C.Ai, :ai_promo, %{count: 2, variant: "rail"}},
  {"ai_greeting", C.Ai, :ai_greeting, %{name: "Ana"}},
  {"ai_tool_trace", C.Ai, :ai_tool_trace,
   %{tools: [%{label: "q", title: "t", ms: "3ms"}], expanded: true}},
  {"ai_tool_trace running", C.Ai, :ai_tool_trace,
   %{tools: [%{label: "q", title: "t", running: true}], running: true}},
  {"ai_proposal", C.Ai, :ai_proposal,
   %{
     id: "pr",
     inner_block: [s.(:inner_block, "x")],
     title: "Do it",
     change: [%{label: "A", from: "1", to: "2"}],
     on_approve: "a",
     on_reject: "r",
     editable: true,
     on_edit: "e",
     preview: [slot.(:preview, "x", %{})],
     impact: [slot.(:impact, "v", %{})]
   }},
  {"ai_proposal table", C.Ai, :ai_proposal,
   %{
     id: "pr2",
     inner_block: [s.(:inner_block, "x")],
     title: "Do it",
     layout: "table",
     status: "approved",
     on_undo: "u",
     change: [%{label: "A", from: "1", to: "2"}]
   }},
  {"ai_message", C.Ai, :ai_message,
   %{
     role: "assistant",
     actions: ["copy", "useful", "useless", "regenerate"],
     inner_block: [s.(:inner_block, "x")]
   }},
  {"ai_composer", C.Ai, :ai_composer, %{id: "comp", on_send: "s", mention: true}},
  {"conversation_list", C.Ai, :conversation_list,
   %{id: "cl", on_new: "n", on_search: "q", conversations: [%{id: 1, title: "C", pending: true}]}},
  {"prompt_suggestions", C.Ai, :prompt_suggestions, %{id: "psg", items: [%{title: "x"}]}},
  {"shell", C.Shell, :shell,
   %{id: "sh", nav: [%{label: "A", href: "#"}], inner_block: [s.(:inner_block, "x")]}}
]

for {name, mod, fun, assigns} <- cases do
  html = I18nSnapshot.render_case(mod, fun, assigns)
  "<!-- CASE #{name} -->\n#{html}\n"
end
