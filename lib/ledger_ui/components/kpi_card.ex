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
      a `lu-delta` and the arrow an icon.
    * `badge`: the compact card of the dashboards, with the delta in a `lu-badge` and the arrow as a
      glyph (`↗`, `↘`, `→`); pair it with `count` for a figure that counts up (CSS only).

  With an `<:icon>`, `layout="stack"` puts the icon chip before the label and `"inline"` puts it
  beside the label and the figure.

  The sparkline is drawn on the server (see `LedgerUI.Components.Sparkline`). The gradient of its
  fill takes its id from `id` (derived from the card's content when not given).
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Sparkline

  @colors %{
    "neutral" => "c-neutral",
    "primary" => nil,
    "secondary" => "c-secondary",
    "info" => "c-info",
    "success" => "c-success",
    "warning" => "c-warning",
    "error" => "c-error"
  }
  @arrows %{"up" => "↗", "down" => "↘", "flat" => "→"}
  @arrow_icons %{"up" => "arrow-up-right", "down" => "arrow-down-right", "flat" => "arrow-right"}
  @tone_pos %{"success" => "pos", "error" => "neg", "neutral" => nil}
  @tones [nil, "success", "error", "neutral"]

  # `style={nil}` renders `style=""`, so an optional style goes through a spread.
  defp st(v) when v in [nil, false], do: []
  defp st(v), do: [style: v]

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
    values: ~w(neutral primary secondary info success warning error)

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

  def kpi_card(%{loading: true} = assigns) do
    ~H"""
    <section class={cx(["lu-card lu-kpi", @class])} aria-busy="true" {@rest}>
      <div class="lu-card-b">
        <span class="lu-skel" style="width:40%"></span>
        <span class="lu-skel" style="width:60%;height:32px"></span>
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
      |> assign(:classes, cx(["lu-card lu-kpi", @colors[assigns.color], assigns.class]))
      |> assign(:tone, tone)
      |> assign(:badge?, badge?)
      |> assign(:inline?, inline?)
      |> assign(:arr_class, cx(["arr", tone == "error" && "neg"]))
      |> assign(:arrow, @arrows[assigns.trend])
      |> assign(:arrow_icon, @arrow_icons[assigns.trend])
      |> assign(:badge_class, cx(["lu-badge", @tone_pos[tone]]))
      |> assign(:delta_class, cx(["lu-delta", delta_class(assigns.trend, tone)]))
      |> assign(
        :v_style,
        if(badge?, do: "font-size:#{if(inline?, do: 30, else: 36)}px;line-height:1.1")
      )
      |> assign(
        :footer?,
        assigns.delta != nil or assigns.compare != nil or assigns.open_label != nil
      )
      |> assign(:spark_id, (assigns.id && assigns.id <> "-spark") || spark_id(assigns))
      |> assign(:spark?, assigns.spark != [] and assigns.progress == nil)
      |> assign(:progress_style, "width:#{assigns.progress || 0}%")

    ~H"""
    <section id={@id} data-part="kpi-card" class={@classes} {@rest}>
      <div class="lu-card-b">
        <Sparkline.sparkline
          :if={@spark?}
          id={@spark_id}
          values={@spark}
          color="primary"
          class="lu-kpi-spark"
          data-spark=""
        />
        <div :if={@badge? and @inline?} class="lu-row" style="gap:12px;align-items:center">
          <span class={cx(["lu-ic", @icon_tone])}>{render_slot(@icon)}</span>
          <div class="lu-col" style="gap:4px">
            <span class="lu-kpi-l">{@label}</span>
            <.figure {assigns} />
          </div>
        </div>
        <%= if @badge? and not @inline? do %>
          <span class="lu-kpi-l">
            <span :if={@icon != []} class={cx(["lu-ic", @icon_tone])}>{render_slot(@icon)}</span>{@label}
          </span>
          <.figure {assigns} />
        <% end %>
        <div
          :if={not @badge?}
          style={"position:relative;display:flex;flex-direction:column;gap:#{if @gap, do: 10, else: 0}px"}
        >
          <span class="lu-kpi-l">
            <span :if={@icon != []} class={cx(["lu-ic", @icon_tone])}>{render_slot(@icon)}</span>{@label}<span
              :if={@live}
              class="lu-badge acc caps sm"
            ><span class="lu-dot live"></span>{@live_label}</span>
          </span>
          <.figure {assigns} />
          <div
            :if={@progress}
            class="lu-progress"
            role="progressbar"
            aria-valuemin="0"
            aria-valuemax="100"
            aria-valuenow={@progress}
          >
            <i style={@progress_style}></i>
          </div>
          <span :if={@caption} class="lu-xs lu-muted">{@caption}</span>
        </div>
      </div>
      <div :if={@footer?} class="lu-card-f">
        <%= if @badge? do %>
          <span :if={@delta} class={@badge_class}>{@delta}</span>
        <% else %>
          <span :if={@delta} class={@delta_class}>{@delta}</span>
        <% end %>
        <span :if={@compare}>{@compare}</span>
        <span :if={@open_label} class="lu-grow"></span>
        <button
          :if={@open_label}
          aria-label={@open_label}
          class="lu-round-go"
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
    <span class="lu-kpi-v" {st(@v_style)}>
      <%= if @badge? do %>
        <sup>{@prefix}</sup><b :if={@count} class="mo-count" style={"--to:#{@count};font-weight:600"}></b><b
          :if={!@count}
          id={@value_id}
          style="font-weight:600"
        >{@value}</b><span class="u">{@unit}</span><span class={@arr_class} style="font-size:18px">{@arrow}</span>
      <% else %>
        <sup :if={@prefix}>{@prefix}</sup>{@value}<span :if={@unit} class="u">{@unit}</span><span
          :if={@delta != nil}
          class={@arr_class}
        ><.icon name={@arrow_icon} size="md" /></span>
      <% end %>
    </span>
    """
  end

  defp default_tone("up"), do: "success"
  defp default_tone("down"), do: "error"
  defp default_tone(_), do: "neutral"

  defp delta_class("flat", _), do: nil
  defp delta_class(_, "neutral"), do: nil
  defp delta_class(_, "success"), do: "up"
  defp delta_class("down", "error"), do: "down"
  defp delta_class(_, "error"), do: "bad-up"

  defp spark_id(a), do: "lu-kpi-" <> Integer.to_string(:erlang.phash2({a.label, a.value}))
end
