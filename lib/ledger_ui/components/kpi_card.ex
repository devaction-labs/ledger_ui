defmodule LedgerUI.Components.KpiCard do
  @moduledoc """
  Indicator card: a big tabular figure, its unit in `subtle` and a coloured delta in the footer.

      <.kpi_card label="MRR" value="184,320" prefix="$" delta="8.8%" compare="vs $169,460 in Sep"
        live spark={@mrr_series} open_label="Open" on_open="open_report" />

      <.kpi_card label="Churn rate" value="2.1" unit="%" delta="0.4 pts" trend="up" delta_tone="error" />

  The colour of the delta follows the meaning, not the direction: churn going up is `error`
  (a red arrow pointing up). `trend` draws the arrow (`up`, `down`, `flat`), `delta_tone` colours it
  and defaults from `trend` (up `success`, down `error`, flat `neutral`).

  ## Variants

    * `canvas` (default): the reference card. The sparkline sits at the right (`spark`), the delta is
      a coloured figure with a small triangle and the arrow an icon.
    * `badge`: the compact card of the dashboards, with the delta in a badge and the arrow as a
      glyph (`↗`, `↘`, `→`); pair it with `count` for a figure that counts up (CSS only).

  With an `<:icon>`, `layout="stack"` puts the icon chip before the label and `"inline"` puts it
  beside the label and the figure.

  The sparkline is drawn on the server (see `LedgerUI.Components.Sparkline`). The gradient of its
  fill takes its id from `id` (derived from the card's content when not given). Styled only with
  Tailwind utilities; the figure fades in once on mount.

  `color` is kept for the API of the canvas; the card follows the accent (its arrow, sparkline and
  round button), as the design does.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Badge
  alias LedgerUI.Components.Sparkline

  @colors ~w(neutral primary secondary info success warning error)
  @arrows %{"up" => "↗", "down" => "↘", "flat" => "→"}
  @arrow_icons %{"up" => "arrow-up-right", "down" => "arrow-up-right", "flat" => "arrow-right"}
  # the canvas has no down-right icon: the up-right one turned a quarter
  @arrow_turn %{"up" => nil, "down" => "rotate-90", "flat" => nil}
  @badge_colors %{"success" => "success", "error" => "error", "neutral" => "neutral"}
  @tones [nil, "success", "error", "neutral"]

  @card "flex min-w-0 flex-col rounded-xl border border-line bg-tray p-1.5"
  @body "relative flex min-w-0 flex-1 flex-col gap-2.5 overflow-hidden rounded-lg border border-line bg-panel px-4 py-3.5"
  @footer "flex items-center gap-2 pt-2.5 pr-2.5 pb-1.5 pl-3 text-[13px] text-muted"
  @label "flex items-center gap-2 text-[12px] font-medium tracking-[.08em] text-ink-2 uppercase"
  @value "flex items-start gap-0.5 font-display font-semibold tracking-[-.035em] text-ink tabular-nums " <>
           "animate-[mo-kpi_7s_cubic-bezier(.2,.8,.2,1)] motion-reduce:animate-none"
  @affix "static mt-0.5 align-top text-xl leading-6 font-medium tracking-normal text-subtle"
  @chip "inline-grid size-8 flex-none place-items-center rounded-md"
  @chips %{
    "acc" => "bg-accent-soft text-accent-content",
    "pos" => "bg-pos-soft text-pos",
    "neg" => "bg-neg-soft text-neg",
    "warn" => "bg-warn-soft text-warn",
    "info" => "bg-info-soft text-info"
  }
  @delta "inline-flex items-center gap-[3px] text-[13px] font-semibold tabular-nums before:content-['']"
  # the triangle of the delta: an up (good or bad), a down, or an empty box when flat
  @tri_up "before:mb-px before:border-x-4 before:border-t-0 before:border-b-[6px] before:border-x-transparent before:border-b-current"
  @tri_down "before:border-x-4 before:border-t-[6px] before:border-b-0 before:border-x-transparent before:border-t-current"
  @tri_flat "before:border-4 before:border-transparent"
  @count "after:[counter-reset:n_var(--lu-n)] after:content-[var(--pre,'')_counter(n)_var(--suf,'')] " <>
           "animate-[mo-count_5s_cubic-bezier(.2,.8,.2,1)_infinite] motion-reduce:animate-none"
  @skel "h-3 rounded-sm bg-[linear-gradient(90deg,var(--lu-bg-sunken)_25%,var(--lu-bg-hover)_50%,var(--lu-bg-sunken)_75%)] " <>
          "bg-[length:200%_100%] animate-[lu-shim_1.4s_linear_infinite] motion-reduce:animate-none"
  @live "inline-flex h-[18px] items-center gap-[5px] rounded-sm bg-accent-soft px-1.5 text-[11px] leading-none " <>
          "font-semibold tracking-[.06em] whitespace-nowrap text-accent-content uppercase tabular-nums"
  @live_dot "inline-block size-[7px] flex-none rounded-full bg-accent-500 " <>
              "shadow-[0_0_0_3px_color-mix(in_oklab,var(--lu-accent-500)_22%,transparent)] " <>
              "animate-[mo-blink_1.4s_ease-in-out_infinite] motion-reduce:animate-none"
  @go "inline-grid size-[30px] cursor-pointer place-items-center rounded-full border-0 bg-accent-500 text-white " <>
        "shadow-[0_4px_10px_color-mix(in_oklab,var(--lu-accent-500)_45%,transparent),inset_0_1px_0_rgba(255,255,255,.3)]"

  attr :id, :string, default: nil
  attr :label, :string, default: nil
  attr :value, :string, default: nil, doc: "The figure, already formatted."
  attr :prefix, :string, default: nil, doc: "A small prefix before the figure (`$`, `R$`)."

  attr :unit, :string,
    default: nil,
    doc: "A smaller suffix beside the figure (`mil`, `%`, `dias`)."

  attr :delta, :string, default: nil, doc: "The change since the last period, already formatted."
  attr :compare, :string, default: nil, doc: "What the change is measured against (`vs Sep`)."
  attr :trend, :string, default: "up", values: ~w(up down flat)
  attr :delta_tone, :string, default: nil, values: @tones
  attr :spark, :list, default: [], doc: "Numbers for the sparkline."

  attr :color, :string,
    default: "primary",
    values: @colors,
    doc: "Kept for the canvas API; the card always follows the accent."

  attr :variant, :string, default: "canvas", values: ~w(canvas badge)
  attr :layout, :string, default: "inline", values: ~w(stack inline)

  attr :count, :integer,
    default: nil,
    doc: "`badge` variant: the figure counts up to this number, in CSS."

  attr :progress, :integer,
    default: nil,
    doc: "0 to 100: a meter under the figure, in place of the sparkline."

  attr :caption, :string, default: nil, doc: "A faint line under the figure or the meter."
  attr :icon_tone, :string, default: "acc", values: ~w(acc pos neg warn info)
  attr :value_id, :string, default: nil, doc: "The `id` of the figure element."
  attr :gap, :boolean, default: true
  attr :loading, :boolean, default: false
  attr :live, :boolean, default: false, doc: "A `Live` chip beside the label."
  attr :live_label, :string, default: "Live"

  attr :open_label, :string,
    default: nil,
    doc: "`aria-label` of the round button at the footer's right; no button without it."

  attr :on_open, :any, default: nil, doc: "Event name or `%JS{}` of the round button."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :icon, doc: "An icon shown in a tinted chip before the label."

  slot :footer,
    doc: "A link or caption in the card's footer, after the delta and the comparison."

  def kpi_card(%{loading: true} = assigns) do
    assigns = assign(assigns, card: @card, body: @body, skel: @skel)

    ~H"""
    <section
      data-part="kpi-card"
      class={cx([@card, @class])}
      aria-busy="true"
      {@rest}
    >
      <div data-part="kpi-body" class={@body}>
        <span data-part="kpi-skeleton" class={@skel} style="width:40%"></span>
        <span data-part="kpi-skeleton" class={@skel} style="width:60%;height:32px"></span>
      </div>
    </section>
    """
  end

  def kpi_card(assigns) do
    tone = assigns.delta_tone || default_tone(assigns.trend)
    badge? = assigns.variant == "badge"
    icon? = assigns.icon != []
    inline? = icon? and assigns.layout == "inline"

    assigns =
      assigns
      |> assign(:classes, cx([@card, assigns.class]))
      |> assign(:tone, tone)
      |> assign(:badge?, badge?)
      |> assign(:inline?, inline?)
      |> assign(:card, @card)
      |> assign(:body, @body)
      |> assign(:footer_class, @footer)
      |> assign(:label_class, @label)
      |> assign(
        :arr_class,
        cx(["mt-0.5 ml-1", if(tone == "error", do: "text-neg", else: "text-accent-500")])
      )
      |> assign(:arrow, @arrows[assigns.trend])
      |> assign(:arrow_icon, @arrow_icons[assigns.trend])
      |> assign(:arrow_turn, @arrow_turn[assigns.trend])
      |> assign(:badge_color, @badge_colors[tone])
      |> assign(:delta_class, delta_class(assigns.trend, tone))
      |> assign(:chip, @chip)
      |> assign(:chip_tone, @chips[assigns.icon_tone])
      |> assign(
        :v_class,
        cx([@value, if(badge?, do: value_size(inline?), else: "text-[40px] leading-[44px]")])
      )
      |> assign(:affix, @affix)
      |> assign(
        :footer?,
        assigns.delta != nil or assigns.compare != nil or assigns.open_label != nil or
          assigns.footer != []
      )
      |> assign(:spark_id, (assigns.id && assigns.id <> "-spark") || spark_id(assigns))
      |> assign(:spark?, assigns.spark != [] and assigns.progress == nil)
      |> assign(:progress_style, "width:#{assigns.progress || 0}%")
      |> assign(:count_class, @count)
      |> assign(:live_class, @live)
      |> assign(:live_dot, @live_dot)
      |> assign(:go, @go)

    ~H"""
    <section id={@id} data-part="kpi-card" class={@classes} {@rest}>
      <div data-part="kpi-body" class={@body}>
        <Sparkline.sparkline
          :if={@spark?}
          id={@spark_id}
          values={@spark}
          color="primary"
          variant="backdrop"
          data-spark=""
        />
        <div
          :if={@badge? and @inline?}
          data-part="kpi-inline"
          class="flex flex-wrap items-center gap-3"
        >
          <span data-part="kpi-icon" class={cx([@chip, @chip_tone])}>{render_slot(@icon)}</span>
          <div data-part="kpi-text" class="flex flex-col gap-1">
            <span data-part="kpi-label" class={@label_class}>{@label}</span>
            <.figure {assigns} />
          </div>
        </div>
        <%= if @badge? and not @inline? do %>
          <span data-part="kpi-label" class={@label_class}>
            <span :if={@icon != []} data-part="kpi-icon" class={cx([@chip, @chip_tone])}>{render_slot(@icon)}</span>{@label}
          </span>
          <.figure {assigns} />
        <% end %>
        <div
          :if={not @badge?}
          data-part="kpi-main"
          class={["relative flex flex-col", if(@gap, do: "gap-2.5", else: "gap-0")]}
        >
          <span data-part="kpi-label" class={@label_class}>
            <span :if={@icon != []} data-part="kpi-icon" class={cx([@chip, @chip_tone])}>{render_slot(@icon)}</span>{@label}<span
              :if={@live}
              data-part="kpi-live"
              class={@live_class}
            ><span data-part="kpi-live-dot" class={@live_dot}></span>{@live_label}</span>
          </span>
          <.figure {assigns} />
          <div
            :if={@progress}
            data-part="kpi-meter"
            class="h-2 overflow-hidden rounded-xs bg-sunken"
            role="progressbar"
            aria-valuemin="0"
            aria-valuemax="100"
            aria-valuenow={@progress}
          >
            <i
              data-part="kpi-meter-bar"
              class="block h-full rounded-xs bg-accent-500"
              style={@progress_style}
            ></i>
          </div>
          <span :if={@caption} data-part="kpi-caption" class="text-xs leading-4 text-muted">{@caption}</span>
        </div>
      </div>
      <div :if={@footer?} data-part="kpi-footer" class={@footer_class}>
        <%= if @badge? do %>
          <Badge.badge :if={@delta} canvas color={@badge_color}>{@delta}</Badge.badge>
        <% else %>
          <span :if={@delta} data-part="kpi-delta" class={@delta_class}>{@delta}</span>
        <% end %>
        <span :if={@compare} data-part="kpi-compare">{@compare}</span>
        {render_slot(@footer)}
        <span :if={@open_label} class="min-w-0 flex-1"></span>
        <button
          :if={@open_label}
          data-part="kpi-open"
          aria-label={@open_label}
          class={@go}
          type="button"
          phx-click={@on_open}
        >
          <.icon name="arrow-right" size="sm" />
        </button>
      </div>
    </section>
    """
  end

  # The big number with its prefix, unit and arrow.
  defp figure(assigns) do
    ~H"""
    <span data-part="kpi-value" id={if !@badge?, do: @value_id} class={@v_class}>
      <%= if @badge? do %>
        <sup data-part="kpi-prefix" class={@affix}>{@prefix}</sup><b
          :if={@count}
          data-part="kpi-count"
          class={["font-semibold", @count_class]}
          style={"--to:#{@count}"}
        ></b><b :if={!@count} data-part="kpi-number" id={@value_id} class="font-semibold">{@value}</b><span
          data-part="kpi-unit"
          class={@affix}
        >{@unit}</span><span data-part="kpi-arrow" class={[@arr_class, "text-[18px]"]}>{@arrow}</span>
      <% else %>
        <sup :if={@prefix} data-part="kpi-prefix" class={@affix}>{@prefix}</sup>{@value}<span
          :if={@unit}
          data-part="kpi-unit"
          class={@affix}
        >{@unit}</span><span :if={@delta != nil} data-part="kpi-arrow" class={@arr_class}><.icon
          name={@arrow_icon}
          size="md"
          class={@arrow_turn}
        /></span>
      <% end %>
    </span>
    """
  end

  defp value_size(true), do: "text-[30px] leading-[1.1]"
  defp value_size(false), do: "text-[36px] leading-[1.1]"

  defp default_tone("up"), do: "success"
  defp default_tone("down"), do: "error"
  defp default_tone(_), do: "neutral"

  # the colour and the triangle of the delta: good news is green (up) or red (down), bad news up is red
  defp delta_class("flat", _), do: cx([@delta, @tri_flat])
  defp delta_class(_, "neutral"), do: cx([@delta, @tri_flat])
  defp delta_class(_, "success"), do: cx([@delta, "text-pos", @tri_up])
  defp delta_class("down", "error"), do: cx([@delta, "text-neg", @tri_down])
  defp delta_class(_, "error"), do: cx([@delta, "text-neg", @tri_up])

  defp spark_id(a), do: "lu-kpi-" <> Integer.to_string(:erlang.phash2({a.label, a.value}))
end
