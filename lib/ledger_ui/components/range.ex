defmodule LedgerUI.Components.Range do
  @moduledoc """
  Range slider: a rounded track with a round thumb, one value or a range of two.

      <.range name="volume" value={50} color="primary" />
      <.range field={@form[:level]} label="Level" min={0} max={10} size="lg" show_value />
      <.range name="discount" label="Desconto" value={12} max={30} show_value value_format="%{value}%" />
      <.range start_name="from" end_name="to" value={{40, 280}} min={0} max={500} />
      <.range name="weight" orientation="vertical" value={40} />

  The slider is the design's `lu-sl` (`.tr` track, `.fl` fill, `.th` thumbs). The
  `LedgerUI.Range` hook (`priv/static/ledger_ui/hooks/range.js`) drags the thumbs, takes the
  arrow keys, Home, End and Page Up/Down (it adds `role="slider"` and the ARIA values to the
  thumbs), keeps the value text, the fill and the marks in step, and writes the value to hidden
  inputs named like the field, firing a bubbling `input` event so `phx-change` runs.

  Deviations from the README: `color` has no default (no `c-*` class, the neutral look) and
  `filled` defaults to `true` (`filled={false}` is the design's "sem filled"); the value is not a
  native `<input type="range">` but hidden inputs.
  """
  use LedgerUI.Component

  import LedgerUI.Components.DatePicker, only: [field_assigns: 1]
  import LedgerUI.Components.NumberInput, only: [machine: 1]

  @styles %{
    "color" => ~w(neutral primary secondary info success warning error),
    "size" => %{"sm" => "s-sm", "md" => nil, "lg" => "s-lg"}
  }

  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :value, :any
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :min, :any, default: 0
  attr :max, :any, default: 100
  attr :step, :any, default: 1
  attr :color, :string, default: nil, values: [nil | @styles["color"]]
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :fill, :string, default: nil
  attr :variant, :string, default: "canvas", values: ~w(canvas classic)
  attr :start_field, Phoenix.HTML.FormField, default: nil
  attr :end_field, Phoenix.HTML.FormField, default: nil
  attr :start_name, :string, default: nil
  attr :end_name, :string, default: nil
  attr :orientation, :string, default: "horizontal", values: ~w(horizontal vertical)
  attr :height, :string, default: "8rem"
  attr :filled, :boolean, default: true
  attr :show_value, :boolean, default: false
  attr :value_format, :string, default: "%{value}"
  attr :marks, :list, default: []
  attr :steppers, :boolean, default: false
  attr :decrease_label, :string, default: "Decrease"
  attr :increase_label, :string, default: "Increase"
  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :disabled, :boolean, default: false
  attr :wrapper_class, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "Renders a range slider."
  def range(assigns) do
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
        "--sp:#{pct(List.last(values), min, max)}",
        pair? && "--a:#{pct(List.first(values), min, max)}",
        assigns.fill && "--c:#{assigns.fill}",
        (vertical? and assigns.height != "8rem") && "height:#{assigns.height}",
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
        cx([
          "lu-sl",
          assigns.color && "c-#{assigns.color}",
          assigns.variant == "classic" && "classic",
          @styles["size"][assigns.size],
          !assigns.filled && "nofill",
          vertical? && "vert",
          assigns.class
        ])
      )

    ~H"""
    <div :if={@wrapped} class={cx(["lu-slw", @wrapper_class])}>
      <div :if={@label || @show_value} class="hd">
        <span class={@label_class}>{@label}</span>
        <span :if={@show_value} class="vv">{@vv}</span>
      </div>
      <%= if @steppers do %>
        <div class="stp">
          <button type="button" aria-label={@decrease_label}><.icon name="minus" /></button>
          <.slider {assigns} />
          <button type="button" aria-label={@increase_label}><.icon name="plus" /></button>
        </div>
      <% else %>
        <.slider {assigns} />
      <% end %>
      <div :if={@marks != []} class="marks">
        <span :for={m <- @marks}>{m.l}</span>
      </div>
      <span :for={e <- @errors} class="lu-help err">{e}</span>
      <span :if={@help} class="lu-help">{@help}</span>
    </div>
    <.slider :if={!@wrapped} {assigns} />
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
      <span class="tr"></span>
      <span class="fl"></span>
      <span
        :if={@pair?}
        class="th a"
        role="slider"
        tabindex={if @disabled, do: "-1", else: "0"}
        aria-valuemin={@min_n}
        aria-valuemax={@max_n}
        aria-valuenow={List.first(@values)}
        aria-orientation={@orientation}
        aria-label={@label && @label <> " min"}
        aria-disabled={@disabled && "true"}
      ></span>
      <span
        class="th"
        role="slider"
        tabindex={if @disabled, do: "-1", else: "0"}
        aria-valuemin={@min_n}
        aria-valuemax={@max_n}
        aria-valuenow={List.last(@values)}
        aria-orientation={@orientation}
        aria-label={@label && if(@pair?, do: @label <> " max", else: @label)}
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
  attr :height, :string, default: "8rem"
  attr :filled, :boolean, default: true
  attr :show_value, :boolean, default: false
  attr :value_format, :string, default: "%{value}"
  attr :marks, :list, default: []
  attr :steppers, :boolean, default: false
  attr :decrease_label, :string, default: "Decrease"
  attr :increase_label, :string, default: "Increase"
  attr :label, :string, default: nil
  attr :label_class, :any, default: nil
  attr :help, :string, default: nil
  attr :errors, :list, default: []
  attr :disabled, :boolean, default: false
  attr :wrapper_class, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  @doc "Same as `range/1` (same attributes and slots), under the name the design vitrine uses."
  def range_slider(assigns), do: range(assigns)
end
