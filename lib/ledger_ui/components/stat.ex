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
          icon="huge-wallet"
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
  sets a word (`Boleto`) instead of a number. `stat_group` draws the strip: `card` (the default) frames it,
  `card={false}` leaves a bare row, `variant="sunken"` fills it with the sunken background, and
  `animated` adds the canvas loop: the figures rise, the lines draw and the changes pop in. Styled
  only with Tailwind utilities; the group exposes `data-variant`, `data-card` and `data-animated`,
  which the items read with `group-data-[...]/stats:` variants.
  """
  use LedgerUI.Component

  @arrows %{
    "up" => "M6 9.5V2.5M2.8 5.6 6 2.5l3.2 3.1",
    "down" => "M6 2.5v7M2.8 6.4 6 9.5l3.2-3.1",
    "flat" => "M2.5 6h7"
  }

  @chg_tones %{
    "pos" => "bg-pos-soft text-pos",
    "neg" => "bg-neg-soft text-neg",
    "flat" => "bg-sunken text-muted"
  }

  @spark_tones %{
    "acc" => "[--s:var(--lu-accent-500)]",
    "accent" => "[--s:var(--lu-accent-500)]",
    "pos" => "[--s:var(--lu-pos)]",
    "mut" => "[--s:var(--lu-subtle)]",
    "muted" => "[--s:var(--lu-subtle)]"
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

  attr :size, :string,
    default: "md",
    values: ~w(default md sm),
    doc: "`sm` sets a word instead of a number."

  attr :delta, :string, default: nil, doc: "The variation, already formatted (`12,4%`)."
  attr :change, :string, default: nil, doc: "Alias of `delta`."
  attr :trend, :string, default: "up", values: ~w(up down flat), doc: "The arrow of `delta`."

  attr :delta_tone, :string,
    default: nil,
    values: [nil, "good", "bad", "pos", "neg", "flat"],
    doc:
      "Good (`good`/`pos`) or bad (`bad`/`neg`) news; by default good, or flat when `trend` is flat."

  attr :change_tone, :string,
    default: nil,
    values: [nil, "pos", "neg", "flat"],
    doc: "Alias of `delta_tone`."

  attr :hint, :string, default: nil, doc: "The faint line under the figure (`vs. outubro`)."
  attr :note, :string, default: nil, doc: "Alias of `hint`."
  attr :goal, :integer, default: nil, doc: "Goal progress, 0..100: draws the bar."
  attr :meter, :integer, default: nil, doc: "Alias of `goal`."
  attr :goal_label, :string, default: nil, doc: "The line under the goal bar."

  attr :spark, :list,
    default: nil,
    doc: "Numbers of a trend (at least two); the last one is the dot."

  attr :sparkline, :list, default: nil, doc: "Alias of `spark`."
  attr :spark_tone, :string, default: "accent", values: ~w(accent acc pos muted mut)

  attr :sparkline_tone, :string,
    default: nil,
    values: [nil | ~w(accent acc pos muted mut)],
    doc: "Alias of `spark_tone`."

  attr :class, :any, default: nil
  attr :rest, :global

  def stat_item(assigns) do
    delta = assigns.delta || assigns.change
    tone = tone_alias(assigns.delta_tone || assigns.change_tone)
    goal = assigns.goal || assigns.meter

    assigns =
      assign(assigns,
        delta: delta,
        hint: assigns.hint || assigns.note,
        goal: goal,
        arrow: @arrows[assigns.trend],
        chg_tone: @chg_tones[tone || if(assigns.trend == "flat", do: "flat", else: "pos")],
        spk: spark(assigns.spark || assigns.sparkline),
        spk_tone: @spark_tones[assigns.sparkline_tone || assigns.spark_tone],
        sm?: assigns.size == "sm"
      )

    ~H"""
    <div
      data-part="stat"
      class={[
        "relative flex min-w-0 flex-col gap-1.5 [--d:0s] nth-2:[--d:.15s] nth-3:[--d:.3s] nth-4:[--d:.45s]",
        "group-data-[lu-card=true]/stats:px-5 group-data-[lu-card=true]/stats:pt-4 group-data-[lu-card=true]/stats:pb-[18px]",
        "border-line not-first:border-l",
        "group-data-[lu-variant=sunken]/stats:border-[color-mix(in_srgb,var(--lu-line-strong)_70%,transparent)]",
        "group-data-[lu-card=false]/stats:px-6 group-data-[lu-card=false]/stats:py-0.5 group-data-[lu-card=false]/stats:first:pl-0",
        @tone == "accent" &&
          "group-data-[lu-card=true]/stats:before:absolute group-data-[lu-card=true]/stats:before:inset-x-0 group-data-[lu-card=true]/stats:before:top-0 group-data-[lu-card=true]/stats:before:h-0.5 group-data-[lu-card=true]/stats:before:bg-accent-500 group-data-[lu-card=true]/stats:before:opacity-90 group-data-[lu-card=true]/stats:before:content-['']",
        @class
      ]}
      {@rest}
    >
      <span
        data-part="stat-label"
        class="flex items-center gap-[7px] overflow-hidden text-[12.5px] font-medium text-ellipsis whitespace-nowrap text-muted"
      >
        <.icon :if={@icon} name={@icon} size="sm" />{@label}
      </span>
      <span
        data-part="stat-value"
        class={[
          "flex items-baseline gap-[5px] font-display leading-[1.1] font-semibold whitespace-nowrap tabular-nums",
          "[animation-delay:var(--d)] group-data-[lu-animated=true]/stats:animate-[lu-st-up_6s_cubic-bezier(.2,.8,.2,1)_infinite]",
          !@sm? && "text-[28px] tracking-[-.035em]",
          @sm? && "text-lg tracking-[-.02em]",
          @tone == "accent" && "text-accent-content",
          @tone != "accent" && "text-ink"
        ]}
      >
        {@value}<small
          :if={@unit}
          data-part="stat-unit"
          class="text-[13px] font-medium tracking-normal text-muted"
        >{@unit}</small>
      </span>
      <span
        :if={@delta || @hint}
        data-part="stat-foot"
        class="flex items-center gap-2 text-[12.5px] whitespace-nowrap text-muted"
      >
        <span
          :if={@delta}
          data-part="stat-delta"
          class={[
            "inline-flex h-5 items-center gap-[3px] rounded-sm pr-1.5 pl-1 text-xs font-semibold tabular-nums",
            "[animation-delay:var(--d)] group-data-[lu-animated=true]/stats:animate-[lu-st-pop_6s_ease-out_infinite]",
            @chg_tone
          ]}
        >
          <svg
            data-part="stat-arrow"
            viewBox="0 0 12 12"
            aria-hidden="true"
            class="size-3 fill-none stroke-current stroke-[1.8] [stroke-linecap:round] [stroke-linejoin:round]"
          ><path d={@arrow} /></svg>{@delta}
        </span>
        <span :if={@hint} data-part="stat-hint">{@hint}</span>
      </span>
      <span
        :if={@goal}
        data-part="stat-meter"
        class="mt-0.5 block h-1.5 overflow-hidden rounded-xs bg-sunken"
        role="progressbar"
        aria-label={@label}
        aria-valuemin="0"
        aria-valuemax="100"
        aria-valuenow={@goal}
      >
        <i
          data-part="stat-meter-bar"
          class="block h-full rounded-xs bg-linear-90 from-accent-600 to-accent-400"
          style={"width:#{@goal}%"}
        />
      </span>
      <span
        :if={@goal && @goal_label}
        data-part="stat-foot"
        class="flex items-center gap-2 text-[12.5px] whitespace-nowrap text-muted"
      >
        {@goal_label}
      </span>
      <span :if={@spk} data-part="stat-spark" class="mt-0.5 block h-[30px]">
        <svg
          data-part="stat-spark-svg"
          viewBox="0 0 120 30"
          preserveAspectRatio="none"
          aria-hidden="true"
          class={["block h-[30px] w-full overflow-visible", @spk_tone]}
        >
          <path
            data-part="stat-spark-area"
            d={@spk.area}
            class="fill-[color-mix(in_srgb,var(--s)_14%,transparent)] stroke-none group-data-[lu-animated=true]/stats:animate-[lu-st-fade_6s_ease-out_infinite]"
          />
          <path
            data-part="stat-spark-line"
            d={@spk.line}
            pathLength="1"
            class="fill-none stroke-(--s) stroke-[1.6] [animation-delay:var(--d)] [stroke-linecap:round] [stroke-linejoin:round] [vector-effect:non-scaling-stroke] group-data-[lu-animated=true]/stats:animate-[lu-st-draw_6s_ease-out_infinite] group-data-[lu-animated=true]/stats:[stroke-dasharray:1] group-data-[lu-animated=true]/stats:[stroke-dashoffset:1]"
          />
          <circle
            data-part="stat-spark-dot"
            cx={@spk.x}
            cy={@spk.y}
            r="2.6"
            class="fill-(--s) stroke-panel stroke-[1.5] [vector-effect:non-scaling-stroke] group-data-[lu-animated=true]/stats:animate-[lu-st-fade_6s_ease-out_infinite]"
          />
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

  attr :animated, :boolean,
    default: false,
    doc: "The canvas loop: figures rise, lines draw, changes pop in."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def stat_group(assigns) do
    ~H"""
    <div
      data-part="stat-group"
      data-lu-variant={@variant}
      data-lu-card={to_string(@card)}
      data-lu-animated={to_string(@animated)}
      class={[
        "group/stats grid w-full auto-cols-fr grid-flow-col",
        @card && "overflow-hidden rounded-[16px] border",
        @card && @variant == "default" && "border-line bg-panel shadow-[0_1px_2px_rgba(0,0,0,.04)]",
        @card && @variant == "sunken" && "border-transparent bg-sunken",
        @class
      ]}
      {@rest}
    >
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

    %{line: line, area: line <> " L#{@spk_w} 30 L0 30 Z", x: f1(x), y: f1(y)}
  end

  defp spark(_), do: nil

  defp f1(n), do: :erlang.float_to_binary(n * 1.0, decimals: 1)
end
