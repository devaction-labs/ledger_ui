defmodule LedgerUI.Components.Stat do
  @moduledoc """
  Short figures side by side: the label over the number, a divider between them, inside a card, a
  sunken strip or a bare row.

      <.stat_group>
        <.stat_item label="Subtotal" value="R$ 3.240" />
        <.stat_item label="Desconto" value="− R$ 120" />
        <.stat_item label="Total" value="R$ 3.120" tone="accent" />
      </.stat_group>

      <.stat_group animated>
        <.stat_item
          icon="wallet"
          label="Faturamento"
          value="R$ 184.320"
          change="12,4%"
          note="vs. outubro"
          sparkline={[0, 3.5, 2.3, 6.1, 5.2, 8.7, 11, 9.8, 13.3, 15.1, 17.7, 22]}
        />
      </.stat_group>

  The vitrine names work as aliases: `delta` (`change`), `hint` (`note`), `goal` (`meter`), `spark`
  (`sparkline`) and `delta_tone` (`change_tone`, with `good`/`bad`).

  `stat_item/1` carries everything a figure can say: a `unit` (`dias`, `un`), a `change` with its
  direction (`trend`) and tone (good or bad news), a `note` under the figure, a goal `meter` and a
  `sparkline` (a list of numbers). `tone="accent"` highlights the total of a strip and `size="sm"`
  sets a word (`Boleto`) instead of a number. `stat_group` draws the `lu-stats` strip: `card` (the
  default) frames it, `card={false}` leaves a bare row, `variant="sunken"` fills it with the
  sunken background, and `animated` adds the canvas loop (`mo-stats`): the figures rise, the lines
  draw and the changes pop in.
  """
  use LedgerUI.Component

  @styles %{
    "tone" => %{"default" => nil, "accent" => "accent"},
    "size" => %{"default" => nil, "sm" => "sm"},
    "variant" => %{"default" => nil, "sunken" => "sunken"},
    "spark" => %{"acc" => "acc", "pos" => "pos", "mut" => "mut"},
    "change_tone" => %{"pos" => "pos", "neg" => "neg", "flat" => "flat"}
  }

  # The arrow inside `lu-chg` (12x12 viewBox).
  @arrows %{
    "up" => "M6 9.5V2.5M2.8 5.6 6 2.5l3.2 3.1",
    "down" => "M6 2.5v7M2.8 6.4 6 9.5l3.2-3.1",
    "flat" => "M2.5 6h7"
  }

  # The sparkline box: 120 x 30, the line kept 5 units from the top and 3 from the bottom.
  @spk_w 120
  @spk_top 5
  @spk_bottom 27

  attr :label, :string, required: true
  attr :value, :string, required: true, doc: "The figure, already formatted."
  attr :unit, :string, default: nil, doc: "A smaller faint suffix beside the figure."
  attr :icon, :string, default: nil, doc: "An icon name before the label."
  attr :tone, :string, default: "default", values: ~w(default accent)
  attr :size, :string, default: "default", values: ~w(default sm)
  attr :change, :string, default: nil, doc: "The variation, already formatted (`12,4%`)."
  attr :trend, :string, default: "up", values: ~w(up down flat), doc: "The arrow of `change`."

  attr :change_tone, :string,
    default: nil,
    values: [nil, "pos", "neg", "flat"],
    doc: "Good (`pos`) or bad (`neg`) news; by default `pos`, or `flat` when `trend` is flat."

  attr :note, :string, default: nil, doc: "The faint line under the figure (`vs. outubro`)."
  attr :meter, :integer, default: nil, doc: "Goal progress, 0 to 100: draws the bar."

  attr :sparkline, :list,
    default: nil,
    doc: "Numbers of a trend (at least two); the last one is the dot."

  attr :sparkline_tone, :string, default: "acc", values: ~w(acc pos mut)
  attr :delta, :string, default: nil, doc: "Alias of `change`."
  attr :hint, :string, default: nil, doc: "Alias of `note`."
  attr :goal, :integer, default: nil, doc: "Alias of `meter`."
  attr :spark, :list, default: nil, doc: "Alias of `sparkline`."

  attr :delta_tone, :string,
    default: nil,
    values: [nil, "pos", "neg", "flat", "good", "bad"],
    doc: "Alias of `change_tone`; `good` is `pos` and `bad` is `neg`."

  attr :class, :any, default: nil
  attr :rest, :global

  def stat_item(assigns) do
    assigns =
      assigns
      |> assign(:change, assigns.change || assigns.delta)
      |> assign(:note, assigns.note || assigns.hint)
      |> assign(:meter, assigns.meter || assigns.goal)
      |> assign(:sparkline, assigns.sparkline || assigns.spark)
      |> assign(:change_tone, tone_alias(assigns.change_tone || assigns.delta_tone))

    assigns =
      assigns
      |> assign(
        :classes,
        cx([
          "lu-stat",
          @styles["tone"][assigns.tone],
          @styles["size"][assigns.size],
          assigns.class
        ])
      )
      |> assign(:show_f, assigns.change != nil or assigns.note != nil)
      |> assign(:arrow, @arrows[assigns.trend])
      |> assign(
        :chg_classes,
        cx([
          "lu-chg",
          @styles["change_tone"][
            assigns.change_tone || if(assigns.trend == "flat", do: "flat", else: "pos")
          ]
        ])
      )
      |> assign(:spk, spark(assigns.sparkline))
      |> assign(:spk_class, cx(["lu-spk", @styles["spark"][assigns.sparkline_tone]]))

    ~H"""
    <div data-part="stat" class={@classes} {@rest}>
      <span class="l"><.icon :if={@icon} name={@icon} size="sm" />{@label}</span>
      <span class="v">{@value}<small :if={@unit}>{@unit}</small></span>
      <span
        :if={@meter}
        class="lu-smeter"
        role="progressbar"
        aria-label={@label}
        aria-valuemin="0"
        aria-valuemax="100"
        aria-valuenow={@meter}
      ><i style={"--sp:#{@meter}%"}></i></span>
      <span :if={@show_f} class="f">
        <span :if={@change} class={@chg_classes}>
          <svg viewBox="0 0 12 12" aria-hidden="true"><path d={@arrow} /></svg>{@change}
        </span>
        <span :if={@note}>{@note}</span>
      </span>
      <span :if={@spk} class="sp">
        <svg class={@spk_class} viewBox="0 0 120 30" preserveAspectRatio="none" aria-hidden="true">
          <path class="a" d={@spk.area} />
          <path class="l" pathLength="1" d={@spk.line} />
          <circle cx={@spk.x} cy={@spk.y} r="2.6" />
        </svg>
      </span>
    </div>
    """
  end

  defp tone_alias("good"), do: "pos"
  defp tone_alias("bad"), do: "neg"
  defp tone_alias(tone), do: tone

  attr :card, :boolean, default: true, doc: "Frames the strip; `false` leaves a bare row."
  attr :variant, :string, default: "default", values: ~w(default sunken)
  attr :animated, :boolean, default: false, doc: "The canvas loop (`mo-stats`)."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def stat_group(assigns) do
    assigns =
      assign(
        assigns,
        :classes,
        cx([
          "lu-stats",
          @styles["variant"][assigns.variant],
          !assigns.card && "bare",
          assigns.animated && "mo-stats",
          assigns.class
        ])
      )

    ~H"""
    <div data-part="stat-group" class={@classes} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # nil when there is nothing to draw; otherwise the area, the line and the last point.
  defp spark(values) when is_list(values) and length(values) > 1 do
    {min, max} = Enum.min_max(values)
    span = if max == min, do: 1, else: max - min
    step = @spk_w / (length(values) - 1)

    points =
      values
      |> Enum.with_index()
      |> Enum.map(fn {v, i} ->
        y =
          if max == min,
            do: @spk_bottom,
            else: @spk_bottom - (v - min) / span * (@spk_bottom - @spk_top)

        {i * step, y}
      end)

    line = "M" <> Enum.map_join(points, " L", fn {x, y} -> "#{f1(x)} #{f1(y)}" end)
    {x, y} = List.last(points)

    %{
      line: line,
      area: line <> " L#{@spk_w} 30 L0 30 Z",
      x: f1(x),
      y: f1(y)
    }
  end

  defp spark(_), do: nil

  defp f1(n), do: :erlang.float_to_binary(n * 1.0, decimals: 1)
end
