defmodule LedgerUI.Components.Progress do
  @moduledoc """
  Progress bar (`progress/1`) and the stacked bar of parts of a total (`progress_stack/1`). Styled
  only with Tailwind utilities (the colour enters as `--c`/`--c-on`, see `LedgerUI.Color`).

      <.progress value={64} color="primary" />
      <.progress value={92} size="xl" label="92%" />
      <.progress indeterminate color="info" />
      <.progress_stack label="Sales by channel">
        <:segment value={46} label="Counter" />
        <:segment value={33} label="Online" />
      </.progress_stack>

  `variant` and `size` default to the solid, 8px bar. `label` is the accessible name
  (`role="progressbar"`, with `aria-valuenow`); with `size="xl"` it is drawn inside the bar
  instead. `active` runs stripes over the bar, `indeterminate` slides it, with `shine` it is a
  light that passes.
  """
  use LedgerUI.Component

  @colors ~w(neutral primary secondary info success warning error white)

  # the bar height is a variable: `height` (in Tailwind steps) wins over `size`
  @hgt %{
    4 => "[--hgt:4px]",
    6 => "[--hgt:6px]",
    8 => "[--hgt:8px]",
    12 => "[--hgt:12px]",
    16 => "[--hgt:16px]",
    18 => "[--hgt:18px]"
  }
  @size_px %{"sm" => 4, "md" => 8, "lg" => 12, "xl" => 18}

  # background colour of the bar by variant; the gradient is an image, so no colour under it
  @bar_bg %{
    nil => "bg-(--c)",
    "solid" => "bg-(--c)",
    "soft" => "bg-[color-mix(in_oklab,var(--c)_55%,var(--lu-bg-panel))]",
    "gradient" => "bg-transparent"
  }

  @bar_image %{
    "gradient" => "bg-[linear-gradient(90deg,var(--lu-accent-300),var(--c))]"
  }

  @stripes "bg-[repeating-linear-gradient(45deg,rgba(255,255,255,.22)_0_8px,transparent_8px_16px)] " <>
             "bg-[size:22px_22px] animate-[lu-stripes_.8s_linear_infinite]"
  @shine "bg-[linear-gradient(90deg,transparent,var(--c),transparent)] animate-[lu-ind_1.3s_ease-in-out_infinite]"
  @slide "animate-[lu-ind_1.3s_ease-in-out_infinite]"

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
          "overflow-hidden rounded-full h-(--hgt) bg-[color-mix(in_oklab,var(--c)_14%,var(--lu-bg-sunken))]",
          LedgerUI.Color.vars(assigns.color),
          @hgt[height_px(assigns)]
        ])
      )
      |> assign(:bar_classes, bar_classes(assigns, xl?))
      |> assign(:bar_style, bar_style(assigns, pct))
      |> assign(:attrs, root_attrs(assigns, aria?))
      |> assign(:inner_label, if(xl?, do: assigns.label))

    ~H"""
    <div data-part="progress" class={[@classes, @class]} {@attrs}>
      <i data-part="progress-bar" class={[@bar_classes, @bar_class]} style={@bar_style}>{@inner_label}</i>
    </div>
    """
  end

  defp height_px(%{height: h}) when h not in [nil, ""], do: round(parse_num(h) * 4)
  defp height_px(%{size: size}) when is_map_key(@size_px, size), do: @size_px[size]
  defp height_px(_), do: 8

  defp bar_classes(a, xl?) do
    [
      "block h-full rounded-[inherit] transition-[width] duration-500 ease-[cubic-bezier(.3,.7,.4,1)]",
      if(a.indeterminate and a.shine, do: "bg-transparent", else: @bar_bg[a.variant]),
      cond do
        a.indeterminate and a.shine -> @shine
        a.indeterminate -> @slide
        a.active -> @stripes
        true -> @bar_image[a.variant]
      end,
      xl? &&
        "flex items-center justify-end pr-2 text-[11px] font-semibold not-italic text-(--c-on)"
    ]
  end

  defp bar_style(%{indeterminate: true, shine: true}, _), do: "width:100%"
  defp bar_style(%{indeterminate: true}, _), do: "width:35%"
  defp bar_style(_, pct), do: "width:#{pct}%"

  # `style` and the aria attributes go in a map: a nil value would render an empty attribute.
  defp root_attrs(assigns, aria?) do
    if aria? do
      Map.merge(assigns.rest, %{
        :role => "progressbar",
        :"aria-label" => assigns.label,
        :"aria-valuemin" => "0",
        :"aria-valuemax" => to_string(assigns.max),
        :"aria-valuenow" => to_string(pct_value(assigns.value))
      })
    else
      assigns.rest
    end
  end

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

  # `--chart-N` of the series (the same five colours as the charts)
  @chart %{
    "1" => "bg-chart-1",
    "2" => "bg-chart-2",
    "3" => "bg-chart-3",
    "4" => "bg-chart-4",
    "5" => "bg-chart-5"
  }

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
          class: @chart[chart(seg[:color], i)] || @chart["1"],
          style: "width:#{percent(seg.value, assigns.max)}%"
        }
      end)

    assigns =
      assigns
      |> assign(:segments, segments)
      |> assign(:attrs, stack_attrs(assigns))

    ~H"""
    <div
      data-part="progress-stack"
      class={["flex h-2.5 gap-0.5 overflow-hidden rounded-full bg-sunken", @class]}
      {@attrs}
    >
      <i
        :for={seg <- @segments}
        data-part="progress-segment"
        class={["block h-full", seg.class]}
        title={seg.title}
        style={seg.style}
      ></i>
    </div>
    """
  end

  defp stack_attrs(%{label: nil, rest: rest}), do: rest

  defp stack_attrs(%{label: l, rest: rest}),
    do: Map.merge(rest, %{:role => "img", :"aria-label" => l})

  defp chart(nil, i), do: to_string(i)
  defp chart("c" <> n, _), do: n
  defp chart(n, _), do: to_string(n)

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
  @doc "Same as `progress/1` (same attributes and slots), under the name the design vitrine uses."
  def progress_bar(assigns), do: progress(assigns)
end
