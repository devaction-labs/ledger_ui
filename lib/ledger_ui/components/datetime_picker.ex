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

  import LedgerUI.Components.DatePicker,
    only: [
      field_assigns: 1,
      to_date: 1,
      iso: 1,
      locale_data: 1,
      date_picker_calendar: 1,
      format: 4,
      format: 5,
      pad2: 1
    ]

  import LedgerUI.Components.TimePicker, only: [minutes: 1, hhmm: 1, display: 2]

  @labels %{
    "en" => %{
      datetime_select: "Select",
      datetime_select_range: "Select range",
      datetime_cancel: "Cancel",
      datetime_start: "Start",
      datetime_end: "End",
      datetime_time: "Time",
      datetime_times: "Times",
      datetime_no_times: "No times available",
      datetime_time_placeholder: "e.g. 9:30 AM",
      datetime_previous: "Previous month",
      datetime_next: "Next month",
      datetime_choose_month: "Choose month",
      datetime_choose_year: "Choose year",
      datetime_day: "%{weekday}, %{month} %{day}, %{year}",
      datetime_title: "%{month} %{year}",
      datetime_dialog: "Choose date and time",
      datetime_dialog_range: "Choose date range and times",
      datetime_placeholder: "Select date and time",
      datetime_placeholder_range: "Select date range"
    },
    "pt_BR" => %{
      datetime_select: "Selecionar",
      datetime_select_range: "Selecionar período",
      datetime_cancel: "Cancelar",
      datetime_start: "Início",
      datetime_end: "Fim",
      datetime_time: "Hora",
      datetime_times: "Horários",
      datetime_no_times: "Sem horários disponíveis",
      datetime_time_placeholder: "ex.: 09:30",
      datetime_previous: "Mês anterior",
      datetime_next: "Próximo mês",
      datetime_choose_month: "Escolher mês",
      datetime_choose_year: "Escolher ano",
      datetime_day: "%{weekday}, %{day} de %{month} de %{year}",
      datetime_title: "%{month} %{year}",
      datetime_dialog: "Escolher data e hora",
      datetime_dialog_range: "Escolher período e horários",
      datetime_placeholder: "Selecionar data e hora",
      datetime_placeholder_range: "Selecionar período"
    }
  }

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
  defp bound(v, _today), do: moment_text(moment(v), 0) |> String.replace(~r/T00:00$/, "")

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
  attr :locale, :string, default: "en"
  attr :times, :list, default: [], doc: "The `\"HH:MM\"` texts of the time buttons."
  attr :time, :string, default: nil, doc: "The chosen `\"HH:MM\"`."
  attr :timezone, :string, default: nil, doc: "A time zone caption over the list of times."
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The static panel: a calendar with the list of times beside it."
  def datetime_picker_panel(assigns) do
    ~H"""
    <div
      data-part="datetime-picker-panel"
      class={cx(["lu-pop", @class])}
      style="padding:0;display:inline-flex"
      {@rest}
    >
      <.date_picker_calendar
        month={@month}
        selected={@selected}
        today={@today}
        week_start={@week_start}
        locale={@locale}
      />
      <div style="border-left:1px solid var(--line);width:130px;display:flex;flex-direction:column">
        <div :if={@timezone} class="lu-menu-label">{@timezone}</div>
        <div class="lu-times">
          <button :for={t <- @times} class={if t == @time, do: "on", else: ""} type="button">
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
  attr :locale, :string, default: "en", values: ~w(en pt_BR)
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
  attr :on_change, :string, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :icon, doc: "Replaces the calendar icon."
  slot :trigger, doc: "Replaces the input: any button inside opens the panel."

  @doc "Renders the date and time input with its panel."
  def datetime_picker(assigns) do
    assigns = assigns |> Map.new() |> field_assigns() |> ends()
    lang = if assigns.locale == "pt_BR", do: "pt_BR", else: "en"
    data = locale_data(lang)
    labels = Map.merge(@labels[lang], assigns.labels)
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
      name: assigns.name,
      startName: assigns.start_name,
      endName: assigns.end_name,
      labels: Map.new(labels, fn {k, v} -> {to_string(k), v} end),
      onChange: assigns.on_change,
      target: if(assigns.target, do: to_string(assigns.target))
    }

    {sel_date, sel_time} = List.first(picked) || {nil, nil}
    id = assigns.id || assigns.name || "datetime-picker"

    placeholder =
      assigns.placeholder ||
        if(range?, do: labels.datetime_placeholder_range, else: labels.datetime_placeholder)

    assigns =
      assigns
      |> assign(:id, id)
      |> assign(:config, Jason.encode!(config))
      |> assign(:text, text)
      |> assign(:placeholder, placeholder)
      |> assign(:size_class, if(assigns.size == "md", do: nil, else: assigns.size))
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
      |> assign(:pos, placement_style(assigns.placement))

    ~H"""
    <div
      id={@id <> "-picker"}
      data-part="datetime-picker"
      phx-hook="LedgerUI.DatetimePicker"
      data-lu-config={@config}
      class="lu-field"
      style="position:relative"
      {@rest}
    >
      <span :if={@label} class="lu-label">{@label}</span>
      <span data-values>
        <input :for={{n, v} <- @hidden} type="hidden" name={n} value={v} disabled={@disabled} />
      </span>
      <%= cond do %>
        <% @trigger != [] -> %>
          <span data-trigger>{render_slot(@trigger)}</span>
        <% @split and not @range? -> %>
          <span style="display:flex;gap:8px">
            <span class="lu-field" style="flex:1">
              <span :if={@date_label} class="lu-label">{@date_label}</span>
              <span class={cx(["lu-input", @size_class, @variant == "filled" && "filled", @class])}>
                <.icon :if={@show_icon} name="calendar" />
                <input
                  id={@id}
                  type="text"
                  readonly
                  autocomplete="off"
                  placeholder={@placeholder}
                  value={@date_text}
                  disabled={@disabled}
                  data-field="date"
                />
              </span>
            </span>
            <span class="lu-field" style="flex:1">
              <span :if={@time_label} class="lu-label">{@time_label}</span>
              <span class={cx(["lu-input", @size_class, @variant == "filled" && "filled", @class])}>
                <.icon :if={@show_icon} name="clock" />
                <input
                  type="text"
                  readonly
                  autocomplete="off"
                  value={@time_text}
                  disabled={@disabled}
                  data-field="time"
                />
              </span>
            </span>
          </span>
        <% true -> %>
          <span class={
            cx([
              "lu-input",
              @size_class,
              @variant == "filled" && "filled",
              @class,
              {"disabled", @disabled},
              {"err", @errors != []}
            ])
          }>
            <%= if @show_icon do %>
              <%= if @icon != [] do %>
                {render_slot(@icon)}
              <% else %>
                <.icon name="calendar" />
              <% end %>
            <% end %>
            <input
              id={@id}
              type="text"
              readonly
              autocomplete="off"
              placeholder={@placeholder}
              value={@text}
              disabled={@disabled}
              aria-haspopup="dialog"
              aria-expanded="false"
              aria-controls={@id <> "-pop"}
              data-field="text"
            />
          </span>
      <% end %>
      <span :for={e <- @errors} class="lu-help err">{e}</span>
      <span :if={@help || @timezone} class="lu-help">
        {Enum.join(Enum.reject([@help, @timezone], &is_nil/1), " · ")}
      </span>
      <div
        id={@id <> "-pop"}
        role="dialog"
        aria-label={@dialog_label}
        hidden
        keep-hidden
        style={"position:absolute;z-index:50;" <> @pos}
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
           value: {s.value, e.value}
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

  defp placement_style(p) do
    {side, align} =
      case String.split(p, "-") do
        [s, a] -> {s, a}
        [s] -> {s, "start"}
      end

    case side do
      "top" -> "bottom:100%;margin-bottom:4px;" <> h_align(align)
      "bottom" -> "top:100%;margin-top:4px;" <> h_align(align)
      "left" -> "right:100%;margin-right:4px;top:0"
      "right" -> "left:100%;margin-left:4px;top:0"
    end
  end

  defp h_align("end"), do: "right:0"
  defp h_align(_), do: "left:0"

  component_alias(:date_time_picker, :datetime_picker)
end
