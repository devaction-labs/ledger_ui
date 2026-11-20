defmodule LedgerUI.Components.Progress do
  @moduledoc """
  Progress bar (`progress/1`) and the stacked bar of parts of a total (`progress_stack/1`).

      <.progress value={64} color="primary" />
      <.progress value={92} size="xl" label="92%" />
      <.progress indeterminate color="info" />
      <.progress_stack label="Sales by channel">
        <:segment value={46} label="Counter" />
        <:segment value={33} label="Online" />
      </.progress_stack>

  `variant` and `size` default to the solid, medium bar without emitting a class (`nil`), so only
  an explicit value adds `v-*`/`s-*`. `label` is the accessible name (`role="progressbar"`, with
  `aria-valuenow`); with `size="xl"` it is drawn inside the bar instead.
  """
  use LedgerUI.Component

  @colors ~w(neutral primary secondary info success warning error white)

  @ind "animation:lu-ind 1.3s ease-in-out infinite"
  @stripes "background-image:repeating-linear-gradient(45deg,rgba(255,255,255,.22) 0 8px,transparent 8px 16px);background-size:22px 22px;animation:lu-stripes .8s linear infinite"
  @shine "background:linear-gradient(90deg,transparent,var(--c),transparent);" <> @ind

  attr :value, :any, default: 0, doc: "A number between 0 and `max`."
  attr :max, :any, default: 100
  attr :color, :string, default: "neutral", values: @colors
  attr :variant, :string, default: nil, values: [nil, "solid", "soft", "gradient"]
  attr :size, :string, default: nil, values: [nil, "sm", "md", "lg", "xl"]
  attr :height, :string, default: nil, values: [nil, "", "1", "1.5", "2", "3", "4"]
  attr :active, :boolean, default: false
  attr :indeterminate, :boolean, default: false
  attr :shine, :boolean, default: false
  attr :label, :string, default: nil
  attr :class, :any, default: nil
  attr :bar_class, :any, default: nil
  attr :rest, :global

  def progress(assigns) do
    pct = percent(assigns.value, assigns.max)
    xl? = assigns.size == "xl"
    aria? = assigns.label != nil and not xl? and not assigns.indeterminate

    assigns =
      assigns
      |> assign(
        :classes,
        cx([
          "lu-pg",
          "c-" <> assigns.color,
          assigns.variant && "v-" <> assigns.variant,
          assigns.size && "s-" <> assigns.size,
          assigns.class
        ])
      )
      |> assign(:bar_style, bar_style(assigns, pct))
      |> assign(:attrs, root_attrs(assigns, aria?))
      |> assign(:inner_label, if(xl?, do: assigns.label))

    ~H"""
    <div data-part="progress" class={@classes} {@attrs}>
      <i class={@bar_class} style={@bar_style}>{@inner_label}</i>
    </div>
    """
  end

  defp bar_style(%{indeterminate: true, shine: true}, _), do: "width:100%;" <> @shine
  defp bar_style(%{indeterminate: true}, _), do: "width:35%;" <> @ind
  defp bar_style(%{active: true}, pct), do: "width:#{pct}%;" <> @stripes
  defp bar_style(_, pct), do: "width:#{pct}%"

  # `style` and the aria attributes go in a map: a nil value would render an empty attribute.
  defp root_attrs(assigns, aria?) do
    rest = assigns.rest

    rest =
      case height_style(assigns.height) do
        nil -> rest
        h -> Map.update(rest, :style, h, &(h <> ";" <> &1))
      end

    if aria? do
      Map.merge(rest, %{
        :role => "progressbar",
        :"aria-label" => assigns.label,
        :"aria-valuemin" => "0",
        :"aria-valuemax" => to_string(assigns.max),
        :"aria-valuenow" => to_string(pct_value(assigns.value))
      })
    else
      rest
    end
  end

  # Tailwind steps (h-1 = 4px): `--hgt` is the bar's height variable.
  defp height_style(h) when h in [nil, ""], do: nil
  defp height_style(h), do: "--hgt:#{fmt(parse_num(h) * 4)}px"

  defp parse_num(s) do
    {n, _} = Float.parse(s)
    n
  end

  defp pct_value(v) when is_number(v), do: v
  defp pct_value(_), do: 0

  @doc false
  def percent(value, max) when is_number(value) and is_number(max) and max > 0 do
    value |> Kernel./(max) |> Kernel.*(100) |> min(100) |> max(0) |> fmt()
  end

  def percent(_, _), do: "0"

  defp fmt(n) when is_integer(n), do: Integer.to_string(n)

  defp fmt(n) when is_float(n) do
    r = Float.round(n, 1)
    if r == Float.round(r), do: r |> round() |> Integer.to_string(), else: Float.to_string(r)
  end

  attr :max, :any, default: 100
  attr :label, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :segment, required: true do
    attr :value, :any
    attr :color, :string
    attr :label, :string
  end

  def progress_stack(assigns) do
    segments =
      assigns.segment
      |> Enum.with_index(1)
      |> Enum.map(fn {seg, i} ->
        %{
          title: seg[:label],
          style:
            "width:#{percent(seg.value, assigns.max)}%;background:var(--chart-#{chart(seg[:color], i)})"
        }
      end)

    assigns =
      assigns
      |> assign(:segments, segments)
      |> assign(:classes, cx(["lu-pgstack", assigns.class]))
      |> assign(:attrs, stack_attrs(assigns))

    ~H"""
    <div data-part="progress-stack" class={@classes} {@attrs}>
      <i :for={seg <- @segments} title={seg.title} style={seg.style}></i>
    </div>
    """
  end

  defp stack_attrs(%{label: nil, rest: rest}), do: rest

  defp stack_attrs(%{label: l, rest: rest}),
    do: Map.merge(rest, %{:role => "img", :"aria-label" => l})

  defp chart(nil, i), do: i
  defp chart("c" <> n, _), do: n
  defp chart(n, _), do: n

  attr :value, :any, default: 0, doc: "A number between 0 and `max`."
  attr :max, :any, default: 100

  attr :color, :string,
    default: "neutral",
    values: ["neutral", "primary", "secondary", "info", "success", "warning", "error", "white"]

  attr :variant, :string, default: nil, values: [nil, "solid", "soft", "gradient"]
  attr :size, :string, default: nil, values: [nil, "sm", "md", "lg", "xl"]
  attr :height, :string, default: nil, values: [nil, "", "1", "1.5", "2", "3", "4"]
  attr :active, :boolean, default: false
  attr :indeterminate, :boolean, default: false
  attr :shine, :boolean, default: false
  attr :label, :string, default: nil
  attr :class, :any, default: nil
  attr :bar_class, :any, default: nil
  attr :rest, :global
  @doc "Same as `progress/1` (same attributes and slots), under the name the design vitrine uses."
  def progress_bar(assigns), do: progress(assigns)
end
