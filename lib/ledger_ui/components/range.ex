defmodule LedgerUI.Components.Range do
  @moduledoc """
  Range slider: a rounded track with a round thumb, one value or a range of two.

      <.range name="volume" value={50} color="primary" />
      <.range field={@form[:level]} label="Level" min={0} max={10} size="lg" show_value />
      <.range name="discount" label="Desconto" value={12} max={30} show_value value_format="%{value}%" />
      <.range start_name="from" end_name="to" value={{40, 280}} min={0} max={500} />
      <.range name="weight" orientation="vertical" value={40} />

  The slider is a track, a fill and one or two thumbs, positioned by the custom properties
  `--lu-sp` (the value, in %) and `--lu-rlo` (the lower value of a pair). The
  `LedgerUI.Range` hook (`priv/static/ledger_ui/hooks/range.js`) drags the thumbs, takes the
  arrow keys, Home, End and Page Up/Down (it adds `role="slider"` and the ARIA values to the
  thumbs), keeps the value text, the fill and the marks in step, and writes the value to hidden
  inputs named like the field, firing a bubbling `input` event so `phx-change` runs.

  Deviations from the README: `color` has no default (no `c-*` class, the neutral look) and
  `filled` defaults to `true` (`filled={false}` is the design's "sem filled"); the value is not a
  native `<input type="range">` but hidden inputs.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Form
  import LedgerUI.Components.DatePicker, only: [field_assigns: 1]
  import LedgerUI.Components.NumberInput, only: [machine: 1]

  @colors ~w(neutral primary secondary info success warning error)

  # {track + fill height, thumb} per size; `classic` has 6px bars and square-ish 18px thumbs
  # (a size other than `md` wins on the measures, `classic` keeps its radius)
  @bars %{"sm" => "h-[3px]", "md" => "h-1", "lg" => "h-1.5"}
  @classic_bars %{"sm" => "h-[3px]", "md" => "h-1.5", "lg" => "h-1.5"}
  @thumbs %{
    "sm" => {"size-3", "-ml-1.5"},
    "md" => {"size-4", "-ml-2"},
    "lg" => {"size-5", "-ml-2.5"}
  }
  @classic_thumbs %{
    "sm" => {"size-3", "-ml-1.5"},
    "md" => {"size-[18px]", "-ml-[9px]"},
    "lg" => {"size-5", "-ml-2.5"}
  }

  @grab "animate-[lu-grab_5s_infinite]"
  @thumb "absolute focus-visible:outline-3 focus-visible:outline-(--lu-focus) bg-white shadow-[0_0_0_1px_var(--lu-line-strong),0_1px_3px_rgba(0,0,0,.18)]"

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :min, :any, default: 0
  attr :max, :any, default: 100
  attr :step, :any, default: 1
  attr :color, :string, default: nil, values: [nil | @colors]
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :fill, :string, default: nil
  attr :variant, :string, default: "canvas", values: ~w(canvas classic)
  attr :start_field, Phoenix.HTML.FormField, default: nil
  attr :end_field, Phoenix.HTML.FormField, default: nil
  attr :start_name, :string, default: nil
  attr :end_name, :string, default: nil
  attr :orientation, :string, default: "horizontal", values: ~w(horizontal vertical)

  attr :height, :string,
    default: nil,
    doc: "Height of a vertical slider (112px, the design's 8rem, by default)."

  attr :filled, :boolean, default: true

  attr :loop, :boolean,
    default: false,
    doc:
      "The canvas demo animation: the value runs along the track (`--lu-sp` over 5s) and the thumb \"grabs\" it. The value in the hidden input stays."

  attr :show_value, :boolean, default: false
  attr :value_format, :string, default: "%{value}"
  attr :marks, :list, default: []
  attr :steppers, :boolean, default: false
  attr :decrease_label, :string, default: nil
  attr :increase_label, :string, default: nil
  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :disabled, :boolean, default: false
  attr :wrapper_class, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "Renders a range slider."
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def range(assigns) do
    changed0 = assigns.__changed__

    assigns =
      I18n.texts(assigns, decrease_label: "range.decrease", increase_label: "range.increase")

    assigns =
      assigns
      |> assign(:min_word, I18n.t("range.min", assigns.locale))
      |> assign(:max_word, I18n.t("range.max", assigns.locale))

    assigns = assigns |> Map.new() |> field_assigns() |> ends()
    min = num(assigns.min, 0)
    max = num(assigns.max, 100)
    pair? = assigns.start_name != nil or match?({_, _}, assigns[:value])
    values = values(assigns.value, pair?, min)
    id = assigns.id || assigns.name || assigns.start_name || "range"
    vertical? = assigns.orientation == "vertical"

    marks =
      for m <- assigns.marks do
        case m do
          {v, l} -> %{v: num(v, 0), l: to_string(l)}
          v -> %{v: num(v, 0), l: fmt(num(v, 0))}
        end
      end

    {rest_style, rest} = Map.pop(assigns.rest, :style)

    style =
      [
        "--lu-sp:#{pct(List.last(values), min, max)}",
        pair? && "--lu-rlo:#{pct(List.first(values), min, max)}",
        assigns.fill && "--c:#{assigns.fill}",
        (vertical? and assigns.height) && "height:#{assigns.height}",
        rest_style
      ]
      |> Enum.filter(& &1)
      |> Enum.join(";")

    config = %{
      min: min,
      max: max,
      step: num(assigns.step, 1),
      pair: pair?,
      vertical: vertical?,
      format: assigns.value_format,
      marks: marks,
      names: if(pair?, do: [assigns.start_name, assigns.end_name], else: [assigns.name]),
      disabled: assigns.disabled,
      decrease: assigns.decrease_label,
      increase: assigns.increase_label,
      label: assigns.label
    }

    # the words the hook adds to the label of the two thumbs of a pair (English in the hook)
    config =
      if pair? and assigns.min_word != "min",
        do: Map.merge(config, %{minWord: assigns.min_word, maxWord: assigns.max_word}),
        else: config

    wrapped? =
      assigns.label != nil or assigns.show_value or marks != [] or assigns.help != nil or
        assigns.errors != [] or assigns.steppers

    assigns =
      assigns
      |> assign(:id, id)
      |> assign(:rest, rest)
      |> assign(:config, Jason.encode!(config))
      |> assign(:style, style)
      |> assign(:values, values)
      |> assign(:min_n, min)
      |> assign(:max_n, max)
      |> assign(:pair?, pair?)
      |> assign(:marks, marks)
      |> assign(:wrapped, wrapped?)
      |> assign(
        :vv,
        String.replace(assigns.value_format, "%{value}", Enum.map_join(values, " – ", &fmt/1))
      )
      |> assign(
        :sl_class,
        [
          "relative flex items-center",
          if(vertical?,
            do: ["w-[18px] flex-col justify-center", !assigns.height && "h-28"],
            else: "h-[18px] w-full"
          ),
          assigns.color && LedgerUI.Color.vars(assigns.color),
          assigns.loop && "animate-[lu-slloop_5s_cubic-bezier(.45,0,.25,1)_infinite]",
          assigns.class
        ]
      )
      |> assign(
        :parts,
        parts(assigns.variant, assigns.size, vertical?, assigns.filled, assigns.loop)
      )
      |> assign(:thumb, @thumb)

    # `min_word`/`max_word` also read the process locale when `locale` is nil: like
    # `I18n.texts/3`, they follow the `locale` attr.
    fields = [:field, :start_field, :end_field]

    assigns =
      settle(assigns, changed0,
        min_word: [:locale],
        max_word: [:locale],
        id: [:id, :name, :start_name | fields],
        rest: [:rest],
        style: [:value, :start_name, :min, :max, :fill, :orientation, :height, :rest | fields],
        values: [:value, :start_name, :min | fields],
        min_n: [:min],
        max_n: [:max],
        pair?: [:start_name, :value | fields],
        marks: [:marks],
        config: [
          :min,
          :max,
          :step,
          :pair?,
          :orientation,
          :value_format,
          :marks,
          :name,
          :start_name,
          :end_name,
          :disabled,
          :decrease_label,
          :increase_label,
          :label,
          :min_word,
          :max_word | fields
        ],
        wrapped: [:label, :show_value, :marks, :help, :errors, :steppers | fields],
        vv: [:value_format, :values],
        sl_class: [:orientation, :height, :color, :loop, :class],
        parts: [:variant, :size, :orientation, :filled, :loop],
        thumb: []
      )

    ~H"""
    <div :if={@wrapped} data-part="range-wrap" class={["flex w-full flex-col gap-2", @wrapper_class]}>
      <div
        :if={@label || @show_value}
        data-part="range-head"
        class="flex justify-between text-[13px] font-medium"
      >
        <span data-part="range-label" class={@label_class}>{@label}</span>
        <span :if={@show_value} data-part="range-value" class="font-normal text-muted tabular-nums">
          {@vv}
        </span>
      </div>
      <%= if @steppers do %>
        <div data-part="range-steppers" class="flex items-center gap-2.5">
          <.step label={@decrease_label} icon="minus" />
          <.slider
            config={@config}
            disabled={@disabled}
            end_name={@end_name}
            id={@id}
            label={@label}
            max_n={@max_n}
            max_word={@max_word}
            min_n={@min_n}
            min_word={@min_word}
            name={@name}
            orientation={@orientation}
            pair?={@pair?}
            parts={@parts}
            rest={@rest}
            sl_class={@sl_class}
            start_name={@start_name}
            style={@style}
            values={@values}
          />
          <.step label={@increase_label} icon="plus" />
        </div>
      <% else %>
        <.slider
          config={@config}
          disabled={@disabled}
          end_name={@end_name}
          id={@id}
          label={@label}
          max_n={@max_n}
          max_word={@max_word}
          min_n={@min_n}
          min_word={@min_word}
          name={@name}
          orientation={@orientation}
          pair?={@pair?}
          parts={@parts}
          rest={@rest}
          sl_class={@sl_class}
          start_name={@start_name}
          style={@style}
          values={@values}
        />
      <% end %>
      <div
        :if={@marks != []}
        data-part="range-marks"
        class="flex justify-between text-[11.5px] text-muted tabular-nums"
      >
        <span :for={m <- @marks} data-part="range-mark">{m.l}</span>
      </div>
      <Form.error :for={e <- @errors}>{e}</Form.error>
      <Form.help_text :if={@help}>{@help}</Form.help_text>
    </div>
    <.slider
      :if={!@wrapped}
      config={@config}
      disabled={@disabled}
      end_name={@end_name}
      id={@id}
      label={@label}
      max_n={@max_n}
      max_word={@max_word}
      min_n={@min_n}
      min_word={@min_word}
      name={@name}
      orientation={@orientation}
      pair?={@pair?}
      parts={@parts}
      rest={@rest}
      sl_class={@sl_class}
      start_name={@start_name}
      style={@style}
      values={@values}
    />
    """
  end

  # Classes of the track, the fill and the thumbs for a variant, size and direction.
  defp parts(variant, size, vertical?, filled?, loop?) do
    bar = if(variant == "classic", do: @classic_bars, else: @bars)[size]
    {thumb, ml} = if(variant == "classic", do: @classic_thumbs, else: @thumbs)[size]
    radius = if(variant == "classic", do: "rounded-[6px]", else: "rounded-full")

    if vertical? do
      %{
        track: "absolute inset-y-0 left-[7px] w-1 rounded-[3px] bg-selected",
        fill: [
          "absolute bottom-[var(--lu-rlo,0%)] left-[7px] h-[calc(var(--lu-sp)-var(--lu-rlo,0%))] w-1 rounded-[3px] bg-[var(--c,var(--lu-accent-600))]",
          !filled? && "hidden"
        ],
        thumb: [@thumb, radius, thumb, "left-px bottom-(--lu-sp) -mb-2", loop? && @grab],
        thumb_a: [@thumb, radius, thumb, "left-px bottom-(--lu-rlo) -mb-2"]
      }
    else
      %{
        track: ["absolute inset-x-0 rounded-[3px] bg-selected", bar],
        fill: [
          "absolute left-[var(--lu-rlo,0%)] w-[calc(var(--lu-sp)-var(--lu-rlo,0%))] rounded-[3px] bg-[var(--c,var(--lu-accent-600))]",
          bar,
          !filled? && "hidden"
        ],
        thumb: [@thumb, radius, thumb, ml, "left-(--lu-sp)", loop? && @grab],
        thumb_a: [@thumb, radius, thumb, ml, "left-(--lu-rlo)"]
      }
    end
  end

  attr :label, :string, required: true
  attr :icon, :string, required: true

  defp step(assigns) do
    ~H"""
    <button
      type="button"
      data-part="range-step"
      aria-label={@label}
      class="grid size-7 flex-none cursor-pointer place-items-center rounded-[8px] border border-line-strong bg-panel text-ink-2 disabled:cursor-not-allowed disabled:opacity-45"
    >
      <.icon name={@icon} />
    </button>
    """
  end

  defp slider(assigns) do
    ~H"""
    <div
      id={@id}
      data-part="range"
      phx-hook="LedgerUI.Range"
      data-lu-config={@config}
      class={@sl_class}
      style={@style}
      {@rest}
    >
      <%= if @pair? do %>
        <input
          :if={@start_name}
          type="hidden"
          name={@start_name}
          value={fmt(List.first(@values))}
          disabled={@disabled}
          data-range-value
        />
        <input
          :if={@end_name}
          type="hidden"
          name={@end_name}
          value={fmt(List.last(@values))}
          disabled={@disabled}
          data-range-value
        />
      <% else %>
        <input
          :if={@name}
          type="hidden"
          name={@name}
          value={fmt(List.first(@values))}
          disabled={@disabled}
          data-range-value
        />
      <% end %>
      <span data-part="range-track" class={@parts.track}></span>
      <span data-part="range-fill" class={@parts.fill}></span>
      <span
        :if={@pair?}
        data-part="range-thumb"
        class={@parts.thumb_a}
        role="slider"
        tabindex={if @disabled, do: "-1", else: "0"}
        aria-valuemin={@min_n}
        aria-valuemax={@max_n}
        aria-valuenow={List.first(@values)}
        aria-orientation={@orientation}
        aria-label={@label && @label <> " " <> @min_word}
        aria-disabled={@disabled && "true"}
      ></span>
      <span
        data-part="range-thumb"
        class={@parts.thumb}
        role="slider"
        tabindex={if @disabled, do: "-1", else: "0"}
        aria-valuemin={@min_n}
        aria-valuemax={@max_n}
        aria-valuenow={List.last(@values)}
        aria-orientation={@orientation}
        aria-label={@label && if(@pair?, do: @label <> " " <> @max_word, else: @label)}
        aria-disabled={@disabled && "true"}
      ></span>
    </div>
    """
  end

  defp ends(
         %{start_field: %Phoenix.HTML.FormField{} = s, end_field: %Phoenix.HTML.FormField{} = e} =
           a
       ),
       do:
         Map.merge(a, %{
           start_name: s.name,
           end_name: e.name,
           id: a[:id] || s.id,
           value: {s.value, e.value}
         })

  defp ends(a), do: a

  defp num(nil, d), do: d
  defp num(v, d), do: v |> machine() |> parse_num(d)

  defp parse_num(nil, d), do: d

  defp parse_num(m, _d) do
    if String.contains?(m, "."), do: String.to_float(m), else: String.to_integer(m)
  end

  defp values(v, true, min) do
    case v do
      {a, b} -> [num(a, min), num(b, min)]
      [a, b] -> [num(a, min), num(b, min)]
      _ -> [min, min]
    end
  end

  defp values(v, false, min), do: [num(v, min)]

  defp pct(_v, min, max) when max == min, do: "0%"

  defp pct(v, min, max) do
    p = (v - min) / (max - min) * 100
    p = p |> max(0) |> min(100)
    fmt(Float.round(p * 1.0, 2)) <> "%"
  end

  defp fmt(v) when is_integer(v), do: Integer.to_string(v)

  defp fmt(v) when is_float(v) do
    if v == Float.round(v), do: v |> trunc() |> Integer.to_string(), else: Float.to_string(v)
  end

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :min, :any, default: 0
  attr :max, :any, default: 100
  attr :step, :any, default: 1

  attr :color, :string,
    default: nil,
    values: [nil, "neutral", "primary", "secondary", "info", "success", "warning", "error"]

  attr :size, :string, default: "md", values: ["sm", "md", "lg"]
  attr :fill, :string, default: nil
  attr :variant, :string, default: "canvas", values: ["canvas", "classic"]
  attr :start_field, Phoenix.HTML.FormField, default: nil
  attr :end_field, Phoenix.HTML.FormField, default: nil
  attr :start_name, :string, default: nil
  attr :end_name, :string, default: nil
  attr :orientation, :string, default: "horizontal", values: ["horizontal", "vertical"]
  attr :height, :string, default: nil
  attr :filled, :boolean, default: true
  attr :loop, :boolean, default: false
  attr :show_value, :boolean, default: false
  attr :value_format, :string, default: "%{value}"
  attr :marks, :list, default: []
  attr :steppers, :boolean, default: false
  attr :decrease_label, :string, default: nil
  attr :increase_label, :string, default: nil
  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :disabled, :boolean, default: false
  attr :wrapper_class, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  @doc "Same as `range/1` (same attributes and slots), under the name the design vitrine uses."
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def range_slider(assigns), do: range(assigns)
end
