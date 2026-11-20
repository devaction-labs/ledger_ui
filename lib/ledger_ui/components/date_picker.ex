defmodule LedgerUI.Components.DatePicker do
  @moduledoc """
  Date picker: one date, several dates or a range, with limits, disabled days, a custom
  text format and presets. The calendar pops under the input or stays inline.

      <.date_picker field={@form[:due_on]} placeholder="Choose date..." />
      <.date_picker name="trip" mode="range" value={{~D[2026-10-10], ~D[2026-10-20]}} />
      <.date_picker name="days" mode="multiple" disabled_weekdays={[0, 6]} week_start={1} />
      <.date_picker start_field={@form[:from]} end_field={@form[:to]} locale="pt_BR"
        presets={[{"Este mês", "this_month"}, {"Mês passado", "last_month"}]} />

  The input shows the date in `display_format` (flatpickr tokens `Y y m n d j F M l D`); the
  form gets ISO text through hidden inputs named like the field (`name` for one date,
  `name[]` for `multiple` and `range`, with an empty `name[]` first). A pick fires a
  bubbling `input` event, so `phx-change` runs.

  The behaviour lives in the `LedgerUI.DatePicker` hook (`priv/static/ledger_ui/hooks/date_picker.js`).
  The popup is an overlay: `LedgerUI.open/close/toggle("id-pop")` is not needed, the hook
  opens it; `date_picker_clear/1` empties the picker.

  `date_picker_panel/1` renders just the calendar surface (a popover with the month), the markup
  the popup is made of.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Form
  import LedgerUI.Components.Input, only: [input: 1]

  @en_months ~w(January February March April May June July August September October November December)
  @en_weekdays ~w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)
  @pt_months ~w(Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro)
  @pt_weekdays ~w(Domingo Segunda Terça Quarta Quinta Sexta Sábado)

  @labels %{
    "en" => %{
      picker_date_dialog: "Choose date",
      picker_period_dialog: "Choose period",
      picker_previous: "Previous",
      picker_next: "Next",
      picker_day: "%{weekday}, %{month} %{day}, %{year}",
      picker_month: "Month",
      picker_year: "Year",
      picker_year_up: "Next year",
      picker_year_down: "Previous year"
    },
    "pt_BR" => %{
      picker_date_dialog: "Escolher data",
      picker_period_dialog: "Escolher período",
      picker_previous: "Anterior",
      picker_next: "Próximo",
      picker_day: "%{weekday}, %{day} de %{month} de %{year}",
      picker_month: "Mês",
      picker_year: "Ano",
      picker_year_up: "Próximo ano",
      picker_year_down: "Ano anterior"
    }
  }

  @doc false
  def locale_data(locale) do
    locale = if locale in ["pt_BR", "pt-BR", "pt"], do: "pt_BR", else: "en"

    case locale do
      "pt_BR" ->
        %{
          months: @pt_months,
          weekdays: @pt_weekdays,
          format: "d/m/Y",
          sep: " até ",
          placeholder: "dd/mm/aaaa",
          labels: @labels["pt_BR"]
        }

      _ ->
        %{
          months: @en_months,
          weekdays: @en_weekdays,
          format: "Y-m-d",
          sep: " to ",
          placeholder: "yyyy-mm-dd",
          labels: @labels["en"]
        }
    end
  end

  @doc false
  def labels(locale, overrides) when is_map(overrides),
    do: Map.merge(locale_data(locale).labels, overrides)

  # ---------------------------------------------------------------------------------------
  # Shared helpers (also used by `time_picker`, `datetime_picker` and `calendar`)
  # ---------------------------------------------------------------------------------------

  @doc false
  # Fills id/name/value/errors from a `Phoenix.HTML.FormField` when given.
  def field_assigns(%{field: %Phoenix.HTML.FormField{} = f} = a) do
    a
    |> Map.put(:id, a[:id] || f.id)
    |> Map.put(:name, a[:name] || f.name)
    |> Map.put(:value, if(Map.has_key?(a, :value), do: a.value, else: f.value))
    |> Map.put(:errors, if(a[:errors] in [nil, []], do: field_errors(f), else: a.errors))
  end

  def field_assigns(a), do: Map.put_new(a, :value, nil)

  defp field_errors(%Phoenix.HTML.FormField{} = f) do
    if Phoenix.Component.used_input?(f), do: Enum.map(f.errors, &translate_error/1), else: []
  end

  @doc false
  def translate_error({msg, opts}) when is_binary(msg) do
    Enum.reduce(opts, msg, fn {k, v}, acc ->
      String.replace(acc, "%{#{k}}", to_string(v))
    end)
  end

  def translate_error(msg) when is_binary(msg), do: msg

  @doc false
  def to_date(%Date{} = d), do: d
  def to_date(%NaiveDateTime{} = d), do: NaiveDateTime.to_date(d)
  def to_date(%DateTime{} = d), do: DateTime.to_date(d)

  def to_date(<<_::binary-size(10), _::binary>> = s) do
    case Date.from_iso8601(binary_part(s, 0, 10)) do
      {:ok, d} -> d
      _ -> nil
    end
  end

  def to_date(_), do: nil

  @doc false
  def iso(nil), do: ""
  def iso(%Date{} = d), do: Date.to_iso8601(d)

  # A list of dates out of whatever `value` is.
  @doc false
  def value_dates(nil), do: []
  def value_dates(%Date{} = d), do: [d]
  def value_dates(%Date.Range{first: a, last: b}), do: [a, b]
  def value_dates({a, b}), do: Enum.reject([to_date(a), to_date(b)], &is_nil/1)

  def value_dates(list) when is_list(list),
    do: list |> Enum.map(&to_date/1) |> Enum.reject(&is_nil/1)

  def value_dates(other), do: value_dates(List.wrap(to_date(other)))

  @doc false
  # flatpickr-like tokens.
  def format(date, fmt, months, weekdays, minutes \\ 0)

  def format(nil, _fmt, _months, _weekdays, _minutes), do: ""

  def format(%Date{} = d, fmt, months, weekdays, minutes) do
    h = div(minutes, 60)

    fmt
    |> String.graphemes()
    |> Enum.map_join(fn
      "Y" -> Integer.to_string(d.year)
      "y" -> d.year |> rem(100) |> pad2()
      "m" -> pad2(d.month)
      "n" -> Integer.to_string(d.month)
      "d" -> pad2(d.day)
      "j" -> Integer.to_string(d.day)
      "F" -> Enum.at(months, d.month - 1)
      "M" -> months |> Enum.at(d.month - 1) |> String.slice(0, 3)
      "l" -> Enum.at(weekdays, rem(Date.day_of_week(d), 7))
      "D" -> weekdays |> Enum.at(rem(Date.day_of_week(d), 7)) |> String.slice(0, 3)
      "H" -> pad2(h)
      "G" -> Integer.to_string(h)
      "h" -> pad2(if rem(h, 12) == 0, do: 12, else: rem(h, 12))
      "i" -> pad2(rem(minutes, 60))
      "K" -> if h < 12, do: "AM", else: "PM"
      other -> other
    end)
  end

  @doc false
  def pad2(n), do: n |> Integer.to_string() |> String.pad_leading(2, "0")

  @doc false
  # Weeks of a month grid: list of `{date, in_month?}` padded to whole weeks.
  def grid_days(%Date{} = month, week_start) do
    first = Date.beginning_of_month(month)
    last = Date.end_of_month(month)
    lead = Integer.mod(rem(Date.day_of_week(first), 7) - week_start, 7)
    trail = Integer.mod(week_start - 1 - rem(Date.day_of_week(last), 7), 7)
    start = Date.add(first, -lead)
    stop = Date.add(last, trail)

    for d <- Date.range(start, stop), do: {d, d.year == month.year and d.month == month.month}
  end

  @doc false
  def preset_range(key, %Date{} = today) do
    case key do
      "today" -> {today, today}
      "yesterday" -> {Date.add(today, -1), Date.add(today, -1)}
      "last_7_days" -> {Date.add(today, -6), today}
      "last_30_days" -> {Date.add(today, -29), today}
      "this_week" -> week(today)
      "last_week" -> today |> Date.add(-7) |> week()
      "this_month" -> {Date.beginning_of_month(today), Date.end_of_month(today)}
      "last_month" -> last_month(today)
      "this_year" -> {Date.new!(today.year, 1, 1), Date.new!(today.year, 12, 31)}
      "last_year" -> {Date.new!(today.year - 1, 1, 1), Date.new!(today.year - 1, 12, 31)}
      "qtd" -> {Date.new!(today.year, div(today.month - 1, 3) * 3 + 1, 1), today}
      "ytd" -> {Date.new!(today.year, 1, 1), today}
      _ -> nil
    end
  end

  defp week(date) do
    start = Date.add(date, -rem(Date.day_of_week(date), 7))
    {start, Date.add(start, 6)}
  end

  defp last_month(today) do
    prev = today |> Date.beginning_of_month() |> Date.add(-1)
    {Date.beginning_of_month(prev), Date.end_of_month(prev)}
  end

  # [%{label:, from: Date, to: Date}] out of the `presets` attr.
  defp normalize_presets(presets, today) do
    Enum.flat_map(presets, fn
      {label, key} when is_binary(key) ->
        case preset_range(key, today) do
          {from, to} -> [%{label: label, from: from, to: to}]
          nil -> [%{label: label, from: nil, to: nil}]
        end

      {label, {from, to}} ->
        [%{label: label, from: to_date(from), to: to_date(to)}]

      %{label: label, from: from, to: to} ->
        [%{label: label, from: to_date(from), to: to_date(to)}]

      _ ->
        []
    end)
  end

  defp today_of(nil), do: Date.utc_today()
  defp today_of(v), do: to_date(v) || Date.utc_today()

  # ---------------------------------------------------------------------------------------
  # <.date_picker_panel>
  # ---------------------------------------------------------------------------------------

  # --- the look of the month (shared with `datetime_picker`, and sent to the hooks that redraw the
  # days): one tone per day (the properties it sets never overlap), plus the "today" mark.
  @day_base "relative grid h-[34px] cursor-pointer place-items-center border-0 text-[13.5px] tabular-nums"
  @day_tones %{
    "normal" => "rounded-[8px] bg-transparent text-ink hover:bg-hover",
    "out" => "rounded-[8px] bg-transparent text-subtle hover:bg-hover",
    "s" => "rounded-[8px] bg-inverse font-semibold text-on-inverse",
    "r" => "rounded-none bg-accent-soft text-accent-content",
    "rs" => "rounded-l-[8px] rounded-r-none bg-accent-600 text-accent-foreground",
    "re" => "rounded-r-[8px] rounded-l-none bg-accent-600 text-accent-foreground"
  }
  @day_today "font-semibold after:absolute after:bottom-[5px] after:size-1 after:rounded-full after:bg-accent-500 after:content-['']"

  @cal_nav "inline-flex size-[30px] cursor-pointer items-center justify-center rounded-[8px] border border-transparent bg-transparent leading-none text-ink-2 transition-[background,border-color,box-shadow] duration-150 " <>
             "hover:bg-hover hover:text-ink focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] focus-visible:outline-none [&_svg]:size-4"
  @cal_letter "grid h-[26px] place-items-center text-[11.5px] font-medium text-muted"

  @pop "min-w-[220px] rounded-lg border border-line bg-panel shadow-md"

  @preset "flex h-[34px] w-full cursor-pointer items-center gap-2.5 rounded-[8px] border-0 bg-transparent px-2.5 text-left text-sm text-ink-2 hover:bg-hover hover:text-ink aria-pressed:bg-hover aria-pressed:text-ink focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] focus-visible:outline-none"

  @doc false
  # Class strings of the popover pieces (used by `datetime_picker`, which draws its own month).
  def pop_class, do: @pop
  @doc false
  def cal_nav_class, do: @cal_nav
  @doc false
  def cal_letter_class, do: @cal_letter
  @doc false
  def preset_class, do: @preset
  @doc false
  def day_base_class, do: @day_base
  @doc false
  def day_tones, do: @day_tones
  @doc false
  def day_today_class, do: @day_today

  @doc false
  # The classes the redrawing hooks need, to be sent in their config.
  def day_config,
    do: %{base: @day_base, tones: @day_tones, today: @day_today, letter: @cal_letter}

  attr :month, :any,
    default: nil,
    doc: "A `Date` of the month to show (today's month by default)."

  attr :selected, :any, default: nil, doc: "A date or a list of dates drawn as selected."
  attr :range, :any, default: nil, doc: "`{from, to}`: painted as a continuous band."
  attr :today, :any, default: nil
  attr :min, :any, default: nil
  attr :max, :any, default: nil
  attr :disabled_dates, :list, default: []
  attr :disabled_weekdays, :list, default: []
  attr :week_start, :integer, default: 0
  attr :locale, :string, default: "en"
  attr :months, :list, default: nil
  attr :weekdays, :list, default: nil
  attr :labels, :map, default: %{}
  attr :presets, :list, default: []
  attr :class, :any, default: nil
  attr :rest, :global

  @doc """
  The calendar surface of the picker: month title with arrows, weekday letters and the days,
  optionally with a column of `presets` on the left.
  """
  def date_picker_panel(assigns) do
    today = today_of(assigns.today)
    range = range_of(assigns.range)
    presets = normalize_presets(assigns.presets, today)

    assigns =
      assigns
      |> assign(:preset_list, presets)
      |> assign(:current, range)
      |> assign(:pop_cls, [@pop, presets != [] && "flex"])
      |> assign(:preset_cls, @preset)

    ~H"""
    <div data-part="date-picker-panel" class={[@pop_cls, @class]} {@rest}>
      <div
        :if={@preset_list != []}
        data-part="date-picker-presets"
        class="flex w-[150px] flex-col gap-0.5 border-r border-line p-2"
      >
        <button
          :for={p <- @preset_list}
          data-part="date-picker-preset"
          class={@preset_cls}
          aria-pressed={to_string(@current == {p.from, p.to} and p.from != nil)}
          role="menuitem"
          type="button"
        >
          {p.label}
        </button>
      </div>
      <.date_picker_calendar
        month={@month}
        selected={@selected}
        range={@range}
        today={@today}
        min={@min}
        max={@max}
        disabled_dates={@disabled_dates}
        disabled_weekdays={@disabled_weekdays}
        week_start={@week_start}
        locale={@locale}
        months={@months}
        weekdays={@weekdays}
        labels={@labels}
      />
    </div>
    """
  end

  attr :month, :any, default: nil
  attr :selected, :any, default: nil
  attr :range, :any, default: nil
  attr :today, :any, default: nil
  attr :min, :any, default: nil
  attr :max, :any, default: nil
  attr :disabled_dates, :list, default: []
  attr :disabled_weekdays, :list, default: []
  attr :week_start, :integer, default: 0
  attr :locale, :string, default: "en"
  attr :months, :list, default: nil
  attr :weekdays, :list, default: nil
  attr :labels, :map, default: %{}
  attr :rest, :global

  @doc "The month: title, arrows, weekday letters and day buttons."
  def date_picker_calendar(assigns) do
    data = locale_data(assigns.locale)
    months = assigns.months || data.months
    weekdays = assigns.weekdays || data.weekdays
    labels = labels(assigns.locale, assigns.labels)
    today = today_of(assigns.today)
    month = to_date(assigns.month) || today
    range = range_of(assigns.range)
    selected = value_dates(assigns.selected)

    min = to_date(assigns.min)
    max = to_date(assigns.max)
    disabled = MapSet.new(value_dates(assigns.disabled_dates))

    days =
      for {d, in_month?} <- grid_days(month, assigns.week_start) do
        tone =
          range_class(range, d) || if(d in selected, do: "s") || if(!in_month?, do: "out") ||
            "normal"

        classes = [@day_base, @day_tones[tone], d == today && @day_today]

        off? =
          (min != nil and Date.compare(d, min) == :lt) or
            (max != nil and Date.compare(d, max) == :gt) or
            MapSet.member?(disabled, d) or
            rem(Date.day_of_week(d), 7) in assigns.disabled_weekdays

        %{day: d.day, classes: classes, disabled: off?}
      end

    assigns =
      assigns
      |> assign(:title, "#{Enum.at(months, month.month - 1)} #{month.year}")
      |> assign(:letters, weekdays |> Enum.map(&String.first/1) |> rotate(assigns.week_start))
      |> assign(:days, days)
      |> assign(:labels, labels)
      |> assign(:nav_cls, @cal_nav)
      |> assign(:letter_cls, @cal_letter)

    ~H"""
    <div data-part="date-picker-calendar" class="w-[280px] p-3" {@rest}>
      <div class="mb-2 flex items-center gap-1.5">
        <b data-part="date-picker-title" class="flex-1 pl-1 text-[14.5px] font-semibold">{@title}</b>
        <button
          data-part="date-picker-nav"
          aria-label={@labels.picker_previous}
          class={@nav_cls}
          type="button"
        >
          <.icon name="chevron-left" size="md" />
        </button>
        <button
          data-part="date-picker-nav"
          aria-label={@labels.picker_next}
          class={@nav_cls}
          type="button"
        >
          <.icon name="chevron-right" size="md" />
        </button>
      </div>
      <div data-part="date-picker-grid" class="grid grid-cols-[repeat(7,1fr)] gap-0.5 text-center">
        <span :for={l <- @letters} class={@letter_cls}>{l}</span>
        <button
          :for={c <- @days}
          data-part="date-picker-day"
          class={c.classes}
          disabled={c.disabled}
          type="button"
        >
          {c.day}
        </button>
      </div>
    </div>
    """
  end

  defp rotate(list, n), do: Enum.drop(list, n) ++ Enum.take(list, n)

  defp range_of(nil), do: nil

  defp range_of(v) do
    case value_dates(v) do
      [a, b] -> {a, b}
      [a] -> {a, nil}
      _ -> nil
    end
  end

  defp range_class({a, b}, d) when not is_nil(a) and not is_nil(b) do
    cond do
      a == b -> nil
      d == a -> "rs"
      d == b -> "re"
      Date.compare(d, a) == :gt and Date.compare(d, b) == :lt -> "r"
      true -> nil
    end
  end

  defp range_class(_, _), do: nil

  # ---------------------------------------------------------------------------------------
  # <.date_picker>
  # ---------------------------------------------------------------------------------------

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :placeholder, :string, default: nil
  attr :mode, :string, default: "single", values: ~w(single multiple range)
  attr :range, :boolean, default: false, doc: "The same as `mode=\"range\"`."
  attr :start_field, Phoenix.HTML.FormField, default: nil
  attr :end_field, Phoenix.HTML.FormField, default: nil
  attr :start_name, :string, default: nil
  attr :end_name, :string, default: nil
  attr :presets, :list, default: []
  attr :locale, :string, default: "en", values: ~w(en pt_BR)
  attr :range_separator, :string, default: nil
  attr :labels, :map, default: %{}
  attr :min, :any, default: nil
  attr :max, :any, default: nil
  attr :disabled_dates, :list, default: []
  attr :disabled_weekdays, :list, default: []
  attr :week_start, :integer, default: 0
  attr :display_format, :string, default: nil
  attr :months, :list, default: nil
  attr :weekdays, :list, default: nil
  attr :today, :any, default: nil
  attr :inline, :boolean, default: false
  attr :show_icon, :boolean, default: true
  attr :skin, :string, default: nil, values: [nil, "", "linea"]
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :disabled, :boolean, default: false
  attr :on_change, :string, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :icon, doc: "Replaces the calendar icon."
  slot :trailing, doc: "Buttons joined to the right of the input."

  @doc "Renders a date input with its calendar."
  def date_picker(assigns) do
    assigns = assigns |> Map.new() |> field_assigns() |> normalize_ends()
    assigns = if assigns.range, do: %{assigns | mode: "range"}, else: assigns

    data = locale_data(assigns.locale)
    months = assigns.months || data.months
    weekdays = assigns.weekdays || data.weekdays
    today = today_of(assigns.today)
    mode = assigns.mode
    two_fields? = assigns.start_name != nil and assigns.end_name != nil

    dates = picked_dates(assigns, mode, two_fields?)
    fmt = assigns.display_format || data.format
    sep = assigns.range_separator || data.sep

    text =
      dates
      |> Enum.map(&format(&1, fmt, months, weekdays))
      |> Enum.join(if mode == "range", do: sep, else: ", ")

    month = List.first(dates) || today
    id = assigns.id || assigns.name || "date-picker"
    labels = labels(assigns.locale, assigns.labels)

    presets =
      for p <- normalize_presets(assigns.presets, today),
          do: %{label: p.label, from: iso(p.from), to: iso(p.to)}

    config = %{
      mode: mode,
      months: months,
      weekdays: weekdays,
      format: fmt,
      sep: sep,
      weekStart: assigns.week_start,
      today: iso(today),
      min: iso(to_date(assigns.min)),
      max: iso(to_date(assigns.max)),
      disabledDates: assigns.disabled_dates |> value_dates() |> Enum.map(&iso/1),
      disabledWeekdays: assigns.disabled_weekdays,
      presets: presets,
      labels: Map.new(labels, fn {k, v} -> {Atom.to_string(k), v} end),
      name: assigns.name,
      startName: assigns.start_name,
      endName: assigns.end_name,
      inline: assigns.inline,
      onChange: assigns.on_change,
      target: target(assigns.target),
      classes: day_config()
    }

    assigns =
      assigns
      |> assign(:id, id)
      |> assign(:text, text)
      |> assign(:config, Jason.encode!(config))
      |> assign(:placeholder, assigns.placeholder || data.placeholder)
      |> assign(:state, if(assigns.errors != [], do: "error"))
      |> assign(:dates, dates)
      |> assign(:two_fields?, two_fields?)
      |> assign(:hidden_inputs, hidden_inputs(assigns, mode, two_fields?, dates))
      |> assign(
        :dialog_label,
        if(mode == "range", do: labels.picker_period_dialog, else: labels.picker_date_dialog)
      )
      |> assign(:panel_month, month)
      |> assign(:has_trailing, assigns.trailing != [])
      |> assign(:presets_in, assigns.presets)

    ~H"""
    <div
      id={@id <> "-picker"}
      data-part="date-picker"
      phx-hook="LedgerUI.DatePicker"
      data-lu-config={@config}
      class="relative flex min-w-0 flex-col gap-1.5"
      {@rest}
    >
      <Form.label :if={@label} for={@id}>{@label}</Form.label>
      <%= if @has_trailing do %>
        <.input
          id={@id}
          readonly
          autocomplete="off"
          placeholder={@placeholder}
          value={@text}
          disabled={@disabled}
          size={@size}
          state={@state}
          class={@class}
          aria-haspopup="dialog"
          aria-expanded="false"
          aria-controls={@id <> "-pop"}
        >
          <:trailing>{render_slot(@trailing)}</:trailing>
        </.input>
      <% else %>
        <.input
          id={@id}
          readonly
          autocomplete="off"
          placeholder={@placeholder}
          value={@text}
          disabled={@disabled}
          icon={@show_icon and @icon == [] && "calendar"}
          size={@size}
          state={@state}
          class={@class}
          aria-haspopup="dialog"
          aria-expanded="false"
          aria-controls={@id <> "-pop"}
        >
          <:leading :if={@show_icon and @icon != []}>{render_slot(@icon)}</:leading>
        </.input>
      <% end %>
      <span data-values>
        <input :for={{n, v} <- @hidden_inputs} type="hidden" name={n} value={v} disabled={@disabled} />
      </span>
      <Form.error :for={e <- @errors}>{e}</Form.error>
      <Form.help_text :if={@help}>{@help}</Form.help_text>
      <div
        id={@id <> "-pop"}
        role="dialog"
        aria-label={@dialog_label}
        hidden={!@inline}
        keep-hidden
        class="absolute top-full left-0 z-50 mt-1"
      >
        <.date_picker_panel
          month={@panel_month}
          selected={if @mode == "range", do: nil, else: @dates}
          range={if @mode == "range", do: @dates, else: nil}
          today={@today}
          min={@min}
          max={@max}
          disabled_dates={@disabled_dates}
          disabled_weekdays={@disabled_weekdays}
          week_start={@week_start}
          locale={@locale}
          months={@months}
          weekdays={@weekdays}
          labels={@labels}
          presets={@presets_in}
        />
      </div>
    </div>
    """
  end

  @doc """
  A `Phoenix.LiveView.JS` command that empties the date picker `id` (the one given to `id`).

      <button phx-click={date_picker_clear("due")}>×</button>
  """
  def date_picker_clear(id) when is_binary(id), do: JS.dispatch("lu:clear", to: "##{id}-picker")

  def date_picker_clear(%JS{} = js, id) when is_binary(id),
    do: JS.dispatch(js, "lu:clear", to: "##{id}-picker")

  defp target(nil), do: nil
  defp target(t) when is_binary(t), do: t
  defp target(t), do: to_string(t)

  # start_field/end_field => start_name/end_name + the two values.
  defp normalize_ends(
         %{start_field: %Phoenix.HTML.FormField{} = s, end_field: %Phoenix.HTML.FormField{} = e} =
           a
       ) do
    a
    |> Map.merge(%{
      mode: "range",
      start_name: s.name,
      end_name: e.name,
      id: a[:id] || s.id,
      value: {s.value, e.value}
    })
  end

  defp normalize_ends(%{start_name: s, end_name: e} = a) when is_binary(s) and is_binary(e),
    do: Map.put(a, :mode, "range")

  defp normalize_ends(a), do: a

  defp picked_dates(a, "single", _), do: a.value |> value_dates() |> Enum.take(1)

  defp picked_dates(a, "range", _),
    do: a.value |> value_dates() |> Enum.sort(Date) |> Enum.take(2)

  defp picked_dates(a, _multiple, _), do: a.value |> value_dates() |> Enum.sort(Date)

  defp hidden_inputs(a, "single", _, dates), do: [{a.name, iso(List.first(dates))}]

  defp hidden_inputs(a, "range", true, dates),
    do: [{a.start_name, iso(Enum.at(dates, 0))}, {a.end_name, iso(Enum.at(dates, 1))}]

  defp hidden_inputs(a, _mode, _, dates),
    do: [{"#{a.name}[]", ""} | Enum.map(dates, &{"#{a.name}[]", iso(&1)})]
end
