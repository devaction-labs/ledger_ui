defmodule LedgerUI.Components.DatetimePicker do
  @moduledoc """
  A date and a time chosen in one panel: a calendar with a list of times beside it or, for a
  range, two months side by side with a start and an end time.

      <.datetime_picker field={@form[:starts_at]} label="Starts at" />
      <.datetime_picker name="meeting" interval={15} min="now" min_time="08:00" max_time="18:00" />
      <.datetime_picker name="slot" time="input" unavailable="12:00-13:00, 2026-10-14, 2026-10-15T10:00" />
      <.datetime_picker name="shift" mode="range" default_time="09:00/17:00" locale="pt_BR" />

  The value is wall-clock text like a native `datetime-local` input (`2026-10-14T10:30`, no time
  zone, no conversion), sent through a hidden input named like the field (a range sends `name[]`
  with an empty first one, or two fields with `start_field`/`end_field` or
  `start_name`/`end_name`). A bubbling `input` event fires on every change.

  The behaviour lives in the `LedgerUI.DatetimePicker` hook
  (`priv/static/ledger_ui/hooks/datetime_picker.js`). `datetime_picker_panel/1` renders just the
  static panel surface.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.{Button, Form, Input}
  import LedgerUI.Components.Input, only: [input: 1]

  import LedgerUI.Components.DatePicker,
    only: [
      pop_class: 0,
      cal_nav_class: 0,
      day_config_full: 0,
      field_assigns: 1,
      ends_errors: 3,
      to_date: 1,
      iso: 1,
      locale_data: 1,
      date_picker_calendar: 1,
      format: 4,
      format: 5,
      pad2: 1
    ]

  import LedgerUI.Components.TimePicker,
    only: [minutes: 1, hhmm: 1, display: 2, list_class: 0, slot_class: 0]

  @time_col "flex w-[130px] flex-col border-l border-line"

  # What the time buttons of the panel the server draws share, written once on the list as descendant
  # selectors (a button carries no class; the string is written out because Tailwind reads the source
  # text): the same look as `TimePicker.slot_class/0` plus the look of a time that is off. The panel the
  # hook draws when it opens gives every button its class (`slot` in the config).
  @slot_dt "[&_[data-part=datetime-picker-slot]]:h-8 [&_[data-part=datetime-picker-slot]]:cursor-pointer [&_[data-part=datetime-picker-slot]]:rounded-md [&_[data-part=datetime-picker-slot]]:border-0 [&_[data-part=datetime-picker-slot]]:bg-transparent [&_[data-part=datetime-picker-slot]]:font-mono [&_[data-part=datetime-picker-slot]]:text-[13.5px] [&_[data-part=datetime-picker-slot]]:text-ink-2 [&_[data-part=datetime-picker-slot]]:hover:bg-hover [&_[data-part=datetime-picker-slot]]:aria-checked:bg-inverse [&_[data-part=datetime-picker-slot]]:aria-checked:text-on-inverse [&_[data-part=datetime-picker-slot]]:focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] [&_[data-part=datetime-picker-slot]]:focus-visible:outline-none [&_[data-part=datetime-picker-slot]]:disabled:line-through [&_[data-part=datetime-picker-slot]]:disabled:opacity-45"

  defp list_dt_class, do: list_class() <> " " <> @slot_dt

  @input_inner "h-full min-w-0 flex-1 appearance-none border-0 bg-transparent p-0 text-sm outline-0"

  # What the hook needs to draw the panel (the classes live here, where Tailwind sees them)
  defp hook_classes do
    %{
      day: day_config_full(),
      pop: pop_class(),
      nav: cal_nav_class(),
      cal: "w-[280px] p-3",
      head: "mb-2 flex items-center gap-1.5",
      title: "flex-1 pl-1 text-[14.5px] font-semibold",
      grid: "grid grid-cols-[repeat(7,1fr)] gap-0.5 text-center",
      time_col: @time_col,
      list: list_class(),
      slot: slot_class() <> " disabled:line-through disabled:opacity-45",
      empty: "p-2.5 text-xs text-muted",
      time_wrap: "p-1.5",
      box: LedgerUI.Helpers.cx(Input.box_classes("outlined", "sm", "rounded", nil, false)),
      input: @input_inner,
      range_row: "flex items-center gap-2 px-3",
      range_label: "w-11 text-xs text-muted",
      range_day: "flex-1 font-mono text-xs",
      range_foot: "flex flex-col gap-2 border-t border-line py-2.5",
      range_actions: "flex justify-end gap-2 px-3",
      btn_ghost: LedgerUI.Helpers.cx(Button.canvas_classes("sm", "ghost")),
      btn_primary: LedgerUI.Helpers.cx(Button.canvas_classes("sm", "primary"))
    }
  end

  @doc false
  # `{Date, minutes}` out of a NaiveDateTime, DateTime or "2026-10-14T10:30" / "2026-10-14 10:30".
  def moment(%NaiveDateTime{} = n), do: {NaiveDateTime.to_date(n), n.hour * 60 + n.minute}
  def moment(%DateTime{} = n), do: {DateTime.to_date(n), n.hour * 60 + n.minute}

  def moment(<<date::binary-size(10), sep, time::binary>>) when sep in [?T, ?\s] do
    with %Date{} = d <- to_date(date), m when is_integer(m) <- minutes(time) do
      {d, m}
    else
      _ -> moment(date)
    end
  end

  def moment(<<_::binary-size(10)>> = date), do: with(%Date{} = d <- to_date(date), do: {d, nil})
  def moment(%Date{} = d), do: {d, nil}
  def moment(_), do: nil

  @doc false
  def moment_text(nil, _), do: ""
  def moment_text({d, nil}, default), do: moment_text({d, default}, default)
  def moment_text({d, m}, _), do: "#{iso(d)}T#{hhmm(m)}"

  defp moments(nil), do: []
  defp moments({a, b}), do: Enum.reject([moment(a), moment(b)], &is_nil/1)

  defp moments(list) when is_list(list),
    do: list |> Enum.map(&moment/1) |> Enum.reject(&is_nil/1)

  defp moments(other), do: if(m = moment(other), do: [m], else: [])

  # "now" | "today" | Date | NaiveDateTime | ISO text -> config text.
  defp bound(nil, _today), do: nil
  defp bound(v, _today) when v in ["now", "today"], do: v
  defp bound(v, _today), do: moment_text(moment(v), 0) |> String.replace_suffix("T00:00", "")

  # What cannot be picked: days, daily time ranges, date-times.
  defp unavailable(v) do
    items =
      case v do
        s when is_binary(s) -> s |> String.split(",", trim: true) |> Enum.map(&String.trim/1)
        l when is_list(l) -> l
        _ -> []
      end

    Enum.reduce(items, %{days: [], ranges: [], moments: []}, fn item, acc ->
      case item do
        %Date{} = d ->
          %{acc | days: [iso(d) | acc.days]}

        %NaiveDateTime{} = n ->
          %{acc | moments: [moment_text(moment(n), 0) | acc.moments]}

        <<_::binary-size(5), "-", _::binary-size(5)>> = s ->
          [a, b] = String.split(s, "-", parts: 2)
          %{acc | ranges: [[minutes(a), minutes(b)] | acc.ranges]}

        <<_::binary-size(10)>> = s ->
          %{acc | days: [s | acc.days]}

        <<_::binary-size(10), _, _::binary>> = s ->
          %{acc | moments: [moment_text(moment(s), 0) | acc.moments]}

        s when is_binary(s) ->
          case String.split(s, "-", parts: 2) do
            [a, b] -> %{acc | ranges: [[minutes(a), minutes(b)] | acc.ranges]}
            _ -> acc
          end

        _ ->
          acc
      end
    end)
  end

  # ---------------------------------------------------------------------------------------
  # <.datetime_picker_panel>
  # ---------------------------------------------------------------------------------------

  attr :month, :any, default: nil
  attr :selected, :any, default: nil
  attr :today, :any, default: nil
  attr :week_start, :integer, default: 0

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  attr :times, :list, default: [], doc: "The `\"HH:MM\"` texts of the time buttons."
  attr :time, :string, default: nil, doc: "The chosen `\"HH:MM\"`."
  attr :timezone, :string, default: nil, doc: "A time zone caption over the list of times."
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The static panel: a calendar with the list of times beside it."
  def datetime_picker_panel(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:pop, pop_class())
      |> assign(:time_col, @time_col)
      |> assign(:list, list_dt_class())

    assigns =
      assigns
      |> assign(:times_label, I18n.labels("datetime", I18n.locale(assigns.locale)).datetime_times)

    assigns = settle(assigns, changed0, pop: [], time_col: [], list: [], times_label: [:locale])

    ~H"""
    <div data-part="datetime-picker-panel" class={[@pop, "inline-flex", @class]} {@rest}>
      <.date_picker_calendar
        month={@month}
        selected={@selected}
        today={@today}
        week_start={@week_start}
        locale={@locale}
      />
      <div class={@time_col}>
        <div
          :if={@timezone}
          class="px-2.5 pt-2 pb-1 text-[11.5px] font-medium text-muted"
        >
          {@timezone}
        </div>
        <div
          data-part="datetime-picker-times"
          class={@list}
          role="radiogroup"
          aria-label={@times_label}
        >
          <button
            :for={t <- @times}
            data-part="datetime-picker-slot"
            role="radio"
            aria-checked={to_string(t == @time)}
            type="button"
          >
            {t}
          </button>
        </div>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------------------
  # <.datetime_picker>
  # ---------------------------------------------------------------------------------------

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :timezone, :string, default: nil
  attr :errors, :list, default: []
  attr :placeholder, :string, default: nil
  attr :mode, :string, default: "single", values: ~w(single range)
  attr :start_field, Phoenix.HTML.FormField, default: nil
  attr :end_field, Phoenix.HTML.FormField, default: nil
  attr :start_name, :string, default: nil
  attr :end_name, :string, default: nil
  attr :interval, :integer, default: 30
  attr :time, :string, default: "list", values: ~w(list input)
  attr :default_time, :string, default: nil
  attr :time_format, :string, default: "auto", values: ~w(auto 12 24)
  attr :time_24hr, :boolean, default: nil
  attr :minute_step, :integer, default: nil
  attr :default_hour, :integer, default: nil

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  attr :display_format, :string, default: nil
  attr :range_separator, :string, default: " – "
  attr :min, :any, default: nil
  attr :max, :any, default: nil
  attr :min_time, :string, default: nil
  attr :max_time, :string, default: nil
  attr :unavailable, :any, default: []
  attr :week_start, :integer, default: 0
  attr :months, :list, default: nil
  attr :weekdays, :list, default: nil
  attr :today, :any, default: nil
  attr :labels, :map, default: %{}
  attr :layout, :string, default: "auto", values: ~w(auto compact)
  attr :variant, :string, default: "outlined", values: ~w(outlined filled)
  attr :split, :boolean, default: false
  attr :date_label, :string, default: nil
  attr :time_label, :string, default: nil
  attr :size, :string, default: "md", values: ~w(sm md lg)

  attr :placement, :string,
    default: "bottom-start",
    values:
      ~w(top bottom left right top-start top-end bottom-start bottom-end left-start left-end right-start right-end)

  attr :show_icon, :boolean, default: true
  attr :disabled, :boolean, default: false

  attr :on_change, :any,
    default: nil,
    doc:
      "An event name (pushed with `%{\"id\", \"value\"}`, to `target` when given) or a `%JS{}` (run in the browser)."

  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :icon, doc: "Replaces the calendar icon."
  slot :trigger, doc: "Replaces the input: any button inside opens the panel."

  @doc "Renders the date and time input with its panel."
  def datetime_picker(assigns) do
    changed0 = assigns.__changed__
    assigns = assigns |> Map.new() |> field_assigns() |> ends()
    lang = I18n.locale(assigns.locale)
    data = locale_data(lang)
    labels = Map.merge(I18n.labels("datetime", lang), assigns.labels)
    months = assigns.months || data.months
    weekdays = assigns.weekdays || data.weekdays
    range? = assigns.mode == "range"
    today = to_date(assigns.today) || Date.utc_today()

    h24? =
      case {assigns.time_format, assigns.time_24hr} do
        {"24", _} -> true
        {"12", _} -> false
        {_, true} -> true
        _ -> lang == "pt_BR"
      end

    interval = max(assigns.minute_step || assigns.interval, 1)

    default_time =
      assigns.default_time ||
        if(assigns.default_hour, do: "#{pad2(assigns.default_hour)}:00")

    [default_start, default_end] =
      case String.split(default_time || "", "/") do
        [a, b] -> [minutes(a), minutes(b)]
        [a] -> [minutes(a), minutes(a)]
      end

    picked = picked(assigns, range?)
    fmt = assigns.display_format || if(lang == "pt_BR", do: "d/m/Y H:i", else: "M j, Y, h:i K")

    show = fn {d, m} -> format(d, fmt, months, weekdays, m || 0) end

    text =
      picked |> Enum.map(show) |> Enum.join(if(range?, do: assigns.range_separator, else: ""))

    lo = minutes(assigns.min_time) || 0
    hi = minutes(assigns.max_time) || 24 * 60 - 1

    config = %{
      mode: assigns.mode,
      months: months,
      weekdays: weekdays,
      weekStart: assigns.week_start,
      today: iso(today),
      h24: h24?,
      format: fmt,
      sep: assigns.range_separator,
      interval: interval,
      time: assigns.time,
      defaultStart: default_start,
      defaultEnd: default_end,
      min: bound(assigns.min, today),
      max: bound(assigns.max, today),
      minTime: lo,
      maxTime: hi,
      unavailable: unavailable(assigns.unavailable),
      layout: assigns.layout,
      placement: assigns.placement,
      startName: assigns.start_name,
      endName: assigns.end_name,
      labels: Map.new(labels, fn {k, v} -> {to_string(k), v} end),
      onChange: event_attr(assigns.on_change, "on_change"),
      target: if(assigns.target, do: to_string(assigns.target)),
      classes: hook_classes()
    }

    {sel_date, sel_time} = List.first(picked) || {nil, nil}
    id = field_id(assigns, "datetime-picker")

    placeholder =
      assigns.placeholder ||
        if(range?, do: labels.datetime_placeholder_range, else: labels.datetime_placeholder)

    assigns =
      assigns
      |> assign(:id, id)
      |> assign(:config, config_json(config))
      |> assign(:text, text)
      |> assign(:placeholder, placeholder)
      |> assign(:state, if(assigns.errors != [], do: "error"))
      |> assign(:hidden, hidden(assigns, range?, picked))
      |> assign(:month, sel_date || today)
      |> assign(:sel_date, sel_date)
      |> assign(:sel_time, sel_time)
      |> assign(:today_d, today)
      |> assign(:times, for(m <- lo..hi//interval, do: {hhmm(m), display(m, h24?)}))
      |> assign(:range?, range?)
      |> assign(:h24, h24?)
      |> assign(
        :dialog_label,
        if(range?, do: labels.datetime_dialog_range, else: labels.datetime_dialog)
      )
      |> assign(
        :date_text,
        if(sel_date, do: format(sel_date, split_date(lang), months, weekdays), else: "")
      )
      |> assign(:time_text, if(sel_time, do: display(sel_time, h24?), else: ""))
      |> assign(:pos, placement_attr(assigns.placement))

    # The texts, the times and `h24` read the locale; the config and `month` also today's date.
    # Without the `locale` (or `today`) attr that is the locale of the process (or
    # `Date.utc_today/0`): they are not listed then and go every time.
    # The config holds the names of a range (`start_name`/`end_name`), not `name`: that one is the
    # `data-lu-name` attribute, so a `field` that moves with every keystroke does not send the config.
    cfg_ends = [:start_field, :end_field, :start_name, :end_name]
    ends = [:field | cfg_ends]
    by_locale = if assigns.locale, do: [:locale], else: nil
    by_today = if assigns.today, do: [:today], else: nil
    picked_src = [:value, :mode | ends]

    derived =
      [
        id: [:name | ends],
        state: [:errors | ends],
        range?: [:mode | ends],
        pos: [:placement],
        hidden: [:name | picked_src],
        sel_date: picked_src,
        sel_time: picked_src
      ] ++
        if(by_locale,
          do: [
            h24: [:time_format, :time_24hr | by_locale],
            times: [:min_time, :max_time, :minute_step, :interval, :h24],
            text:
              [:display_format, :range_separator, :months, :weekdays, :h24, :range?] ++
                picked_src ++ by_locale,
            placeholder: [:range?, :labels | by_locale],
            dialog_label: [:range?, :labels | by_locale],
            date_text: [:sel_date, :months, :weekdays | by_locale],
            time_text: [:sel_time, :h24]
          ],
          else: []
        ) ++
        if(by_locale && by_today,
          do: [
            config:
              [
                :mode,
                :months,
                :weekdays,
                :week_start,
                :today,
                :h24,
                :display_format,
                :range_separator,
                :minute_step,
                :interval,
                :time,
                :default_time,
                :default_hour,
                :min,
                :max,
                :min_time,
                :max_time,
                :unavailable,
                :layout,
                :placement,
                :labels,
                :on_change,
                :target,
                :mode
              ] ++ cfg_ends ++ by_locale
          ],
          else: []
        ) ++
        if(by_today, do: [month: [:sel_date, :today], today_d: [:today]], else: [])

    assigns = settle(assigns, changed0, derived)

    ~H"""
    <div
      id={@id <> "-picker"}
      data-part="datetime-picker"
      phx-hook="LedgerUI.DatetimePicker"
      data-lu-config={@config}
      data-lu-name={@name}
      class="relative flex min-w-0 flex-col gap-1.5"
      {@rest}
    >
      <Form.label :if={@label} id={@id <> "-label"} for={@trigger == [] && @id}>{@label}</Form.label>
      <span data-values>
        <input :for={{n, v} <- @hidden} type="hidden" name={n} value={v} disabled={@disabled} />
      </span>
      <%= cond do %>
        <% @trigger != [] -> %>
          <span
            data-trigger
            role={@label && "group"}
            aria-labelledby={@label && @id <> "-label"}
          >{render_slot(@trigger)}</span>
        <% @split and not @range? -> %>
          <span class="flex gap-2">
            <span class="flex min-w-0 flex-1 flex-col gap-1.5">
              <Form.label :if={@date_label} for={@id}>{@date_label}</Form.label>
              <.input
                id={@id}
                readonly
                autocomplete="off"
                placeholder={@placeholder}
                value={@date_text}
                disabled={@disabled}
                size={@size}
                variant={@variant}
                class={@class}
                icon={@show_icon && "calendar"}
                data-field="date"
              />
            </span>
            <span class="flex min-w-0 flex-1 flex-col gap-1.5">
              <Form.label :if={@time_label} for={@id <> "-time"}>{@time_label}</Form.label>
              <.input
                id={@id <> "-time"}
                readonly
                autocomplete="off"
                value={@time_text}
                disabled={@disabled}
                size={@size}
                variant={@variant}
                class={@class}
                icon={@show_icon && "clock"}
                data-field="time"
              />
            </span>
          </span>
        <% true -> %>
          <.input
            id={@id}
            readonly
            autocomplete="off"
            placeholder={@placeholder}
            value={@text}
            disabled={@disabled}
            size={@size}
            variant={@variant}
            state={@state}
            class={@class}
            icon={(@show_icon and @icon == []) && "calendar"}
            role="combobox"
            aria-haspopup="dialog"
            aria-expanded="false"
            aria-controls={@id <> "-pop"}
            data-field="text"
          >
            <:leading :if={@show_icon and @icon != []}>{render_slot(@icon)}</:leading>
          </.input>
      <% end %>
      <Form.error :for={e <- @errors}>{e}</Form.error>
      <Form.help_text :if={@help || @timezone}>
        {Enum.join(Enum.reject([@help, @timezone], &is_nil/1), " · ")}
      </Form.help_text>
      <div
        id={@id <> "-pop"}
        role="dialog"
        aria-label={@dialog_label}
        hidden
        popover="manual"
        data-lu-placement={@pos}
        class="fixed m-0 overflow-visible border-0 bg-transparent p-0"
      >
        <.datetime_picker_panel
          :if={not @range?}
          month={@month}
          selected={@sel_date}
          today={@today_d}
          week_start={@week_start}
          locale={@locale}
          times={Enum.map(@times, &elem(&1, 1))}
          time={@sel_time && display(@sel_time, @h24)}
        />
      </div>
    </div>
    """
  end

  defp ends(
         %{start_field: %Phoenix.HTML.FormField{} = s, end_field: %Phoenix.HTML.FormField{} = e} =
           a
       ),
       do:
         Map.merge(a, %{
           mode: "range",
           start_name: s.name,
           end_name: e.name,
           id: a[:id] || s.id,
           value: {s.value, e.value},
           errors: ends_errors(a, s, e)
         })

  defp ends(%{start_name: s, end_name: e} = a) when is_binary(s) and is_binary(e),
    do: Map.put(a, :mode, "range")

  defp ends(a), do: a

  defp picked(a, true), do: a.value |> moments() |> Enum.take(2)
  defp picked(a, false), do: a.value |> moments() |> Enum.take(1)

  defp hidden(a, false, picked), do: [{a.name, moment_text(List.first(picked), 0)}]

  defp hidden(%{start_name: s, end_name: e}, true, picked) when is_binary(s) and is_binary(e),
    do: [{s, moment_text(Enum.at(picked, 0), 0)}, {e, moment_text(Enum.at(picked, 1), 0)}]

  defp hidden(a, true, picked),
    do: [{"#{a.name}[]", ""} | Enum.map(picked, &{"#{a.name}[]", moment_text(&1, 0)})]

  defp split_date("pt_BR"), do: "d/m/Y"
  defp split_date(_), do: "M j, Y"

  # "bottom" (no alignment) aligns to the start, as before.
  defp placement_attr(p), do: if(String.contains?(p, "-"), do: p, else: p <> "-start")

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :label, :string, default: nil
  attr :help, :string, default: nil
  attr :timezone, :string, default: nil
  attr :errors, :list, default: []
  attr :placeholder, :string, default: nil
  attr :mode, :string, default: "single", values: ["single", "range"]
  attr :start_field, Phoenix.HTML.FormField, default: nil
  attr :end_field, Phoenix.HTML.FormField, default: nil
  attr :start_name, :string, default: nil
  attr :end_name, :string, default: nil
  attr :interval, :integer, default: 30
  attr :time, :string, default: "list", values: ["list", "input"]
  attr :default_time, :string, default: nil
  attr :time_format, :string, default: "auto", values: ["auto", "12", "24"]
  attr :time_24hr, :boolean, default: nil
  attr :minute_step, :integer, default: nil
  attr :default_hour, :integer, default: nil

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  attr :display_format, :string, default: nil
  attr :range_separator, :string, default: " – "
  attr :min, :any, default: nil
  attr :max, :any, default: nil
  attr :min_time, :string, default: nil
  attr :max_time, :string, default: nil
  attr :unavailable, :any, default: []
  attr :week_start, :integer, default: 0
  attr :months, :list, default: nil
  attr :weekdays, :list, default: nil
  attr :today, :any, default: nil
  attr :labels, :map, default: %{}
  attr :layout, :string, default: "auto", values: ["auto", "compact"]
  attr :variant, :string, default: "outlined", values: ["outlined", "filled"]
  attr :split, :boolean, default: false
  attr :date_label, :string, default: nil
  attr :time_label, :string, default: nil
  attr :size, :string, default: "md", values: ["sm", "md", "lg"]

  attr :placement, :string,
    default: "bottom-start",
    values: [
      "top",
      "bottom",
      "left",
      "right",
      "top-start",
      "top-end",
      "bottom-start",
      "bottom-end",
      "left-start",
      "left-end",
      "right-start",
      "right-end"
    ]

  attr :show_icon, :boolean, default: true
  attr :disabled, :boolean, default: false

  attr :on_change, :any,
    default: nil,
    doc:
      "An event name (pushed with `%{\"id\", \"value\"}`, to `target` when given) or a `%JS{}` (run in the browser)."

  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :icon, doc: "Replaces the calendar icon."
  slot :trigger, doc: "Replaces the input: any button inside opens the panel."

  @doc "Same as `datetime_picker/1` (same attributes and slots), under the name the design vitrine uses."
  def date_time_picker(assigns), do: datetime_picker(assigns)
end
