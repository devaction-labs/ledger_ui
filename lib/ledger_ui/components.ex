defmodule LedgerUI.Components do
  @moduledoc """
  Registry of every component module of Ledger UI.

  `use LedgerUI` imports each module listed in `__modules__/0`. Add a module here
  only when creating a new one (the foundation already lists all of them).
  """

  @modules [
    LedgerUI.Components.Accordion,
    LedgerUI.Components.Ai,
    LedgerUI.Components.Alert,
    LedgerUI.Components.Aura,
    LedgerUI.Components.AuthSplit,
    LedgerUI.Components.Autocomplete,
    LedgerUI.Components.Avatar,
    LedgerUI.Components.Badge,
    LedgerUI.Components.Breadcrumb,
    LedgerUI.Components.BulkBar,
    LedgerUI.Components.Button,
    LedgerUI.Components.Calendar,
    LedgerUI.Components.Card,
    LedgerUI.Components.CardTable,
    LedgerUI.Components.Carousel,
    LedgerUI.Components.CashTimer,
    LedgerUI.Components.Chart,
    LedgerUI.Components.Checkbox,
    LedgerUI.Components.Chip,
    LedgerUI.Components.Clipboard,
    LedgerUI.Components.CodeBlock,
    LedgerUI.Components.Collapse,
    LedgerUI.Components.ColorPicker,
    LedgerUI.Components.CommandPalette,
    LedgerUI.Components.ConnectionBanner,
    LedgerUI.Components.Container,
    LedgerUI.Components.ContextMenu,
    LedgerUI.Components.Cover,
    LedgerUI.Components.DataTable,
    LedgerUI.Components.DatePicker,
    LedgerUI.Components.DatetimePicker,
    LedgerUI.Components.DescriptionList,
    LedgerUI.Components.Divider,
    LedgerUI.Components.Drawer,
    LedgerUI.Components.Dropdown,
    LedgerUI.Components.Email,
    LedgerUI.Components.EmptyState,
    LedgerUI.Components.ErrorPage,
    LedgerUI.Components.Fab,
    LedgerUI.Components.FilterMenu,
    LedgerUI.Components.Flow,
    LedgerUI.Components.FolderTabs,
    LedgerUI.Components.Form,
    LedgerUI.Components.FormSection,
    LedgerUI.Components.GlowText,
    LedgerUI.Components.HeroCard,
    LedgerUI.Components.Hotkey,
    LedgerUI.Components.Icon,
    LedgerUI.Components.Illustration,
    LedgerUI.Components.ImageInput,
    LedgerUI.Components.Input,
    LedgerUI.Components.InputGroup,
    LedgerUI.Components.Kanban,
    LedgerUI.Components.KpiCard,
    LedgerUI.Components.LandingNav,
    LedgerUI.Components.Logo,
    LedgerUI.Components.Mask,
    LedgerUI.Components.MenuList,
    LedgerUI.Components.MiniCard,
    LedgerUI.Components.Modal,
    LedgerUI.Components.Navbar,
    LedgerUI.Components.NotificationCenter,
    LedgerUI.Components.NumberInput,
    LedgerUI.Components.OtpInput,
    LedgerUI.Components.PageTrail,
    LedgerUI.Components.Pagination,
    LedgerUI.Components.Palette,
    LedgerUI.Components.PasswordInput,
    LedgerUI.Components.Persist,
    LedgerUI.Components.PhoneInput,
    LedgerUI.Components.PillSelect,
    LedgerUI.Components.Pillbox,
    LedgerUI.Components.PixelCard,
    LedgerUI.Components.PlacementStage,
    LedgerUI.Components.Popover,
    LedgerUI.Components.Progress,
    LedgerUI.Components.Radio,
    LedgerUI.Components.Range,
    LedgerUI.Components.Rating,
    LedgerUI.Components.ScrollArea,
    LedgerUI.Components.ScrollTarget,
    LedgerUI.Components.Scrollspy,
    LedgerUI.Components.Segmented,
    LedgerUI.Components.Select,
    LedgerUI.Components.Shell,
    LedgerUI.Components.Sidebar,
    LedgerUI.Components.SignaturePad,
    LedgerUI.Components.Skeleton,
    LedgerUI.Components.Sparkline,
    LedgerUI.Components.Spinner,
    LedgerUI.Components.Stat,
    LedgerUI.Components.StepGroup,
    LedgerUI.Components.Steps,
    LedgerUI.Components.Sticky,
    LedgerUI.Components.Switch,
    LedgerUI.Components.Table,
    LedgerUI.Components.Tabs,
    LedgerUI.Components.Tag,
    LedgerUI.Components.TagsInput,
    LedgerUI.Components.TextEditor,
    LedgerUI.Components.Textarea,
    LedgerUI.Components.ThemePicker,
    LedgerUI.Components.ThemeSwitch,
    LedgerUI.Components.TimePicker,
    LedgerUI.Components.Timeline,
    LedgerUI.Components.Timer,
    LedgerUI.Components.Toast,
    LedgerUI.Components.Tool,
    LedgerUI.Components.Tooltip,
    LedgerUI.Components.Trace,
    LedgerUI.Components.Treeview,
    LedgerUI.Components.Typography,
    LedgerUI.Components.Upload,
    LedgerUI.Components.ViewSwitcher
  ]

  @doc "All component modules, imported by `use LedgerUI`."
  @spec __modules__() :: [module()]
  def __modules__, do: @modules

  # Documented non-component API (JS commands / socket helpers) that `use LedgerUI` imports
  # besides the function components. Everything else public in a component module is an
  # implementation helper, called by its full module name and never imported.
  @api %{
    LedgerUI.Components.Alert => [dismiss_alert: 0, dismiss_alert: 1],
    LedgerUI.Components.Calendar => [calendar_range: 2, calendar_range: 3],
    LedgerUI.Components.DatePicker => [date_picker_clear: 1, date_picker_clear: 2],
    LedgerUI.Components.Table => [table_toggle_row: 1, table_toggle_row: 2],
    LedgerUI.Components.TextEditor => [
      insert_html: 3,
      insert_image: 3,
      insert_image: 4,
      insert_image: 5,
      sanitize: 1,
      sanitize: 2
    ],
    LedgerUI.Components.Toast => [
      show_toast: 1,
      show_toast: 2,
      show_toast: 3,
      put_toast: 2,
      put_toast: 3,
      send_toast: 2,
      send_toast: 3,
      update_toast: 3,
      dismiss_toast: 1,
      dismiss_toast: 2,
      clear_toasts: 1
    ]
  }

  @doc """
  The `only:` list `use LedgerUI` passes to `import` for `module`: its function components
  (`name/1`) plus the documented JS/socket helpers. Never other public helpers.
  """
  @spec __imports__(module()) :: [{atom(), arity()}]
  def __imports__(module) do
    Code.ensure_loaded(module)

    components =
      if function_exported?(module, :__components__, 0),
        do:
          for(
            {name, _} <- module.__components__(),
            function_exported?(module, name, 1),
            do: {name, 1}
          ),
        else: []

    Enum.sort(components ++ Map.get(@api, module, []))
  end
end
