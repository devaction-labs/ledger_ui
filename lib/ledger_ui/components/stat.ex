defmodule LedgerUI.Components.Stat do
  @moduledoc """
  Lean figures for lists and headers, without the card tray.

      <.stat_item label="Estoque" value="1.284" unit="un" />

      <.stat_group columns={3}>
        <.stat_item cell label="Subtotal" value="R$ 3.240" />
        <.stat_item cell divider label="Desconto" value="− R$ 120" />
        <.stat_item cell divider label="Total" value="R$ 3.120" tone="accent" delta="3,1%" />
      </.stat_group>

  `stat_item/1` works on its own, inside any flex row (`lu-row`). Inside a `stat_group` (the
  `lu-panel` with a grid of columns) give each item `cell` (and `divider` on all but the first) to
  get the padded cell with the rule between them.
  """
  use LedgerUI.Component

  @sizes %{"default" => "24px", "sm" => "18px"}
  @tones %{"default" => "", "accent" => ";color:var(--accent-ink)"}
  @delta %{"up" => "up", "down" => "down", "bad-up" => "bad-up"}

  # `style={nil}` renders `style=""`, so an optional style goes through a spread.
  defp st(v) when v in [nil, false], do: []
  defp st(v), do: [style: v]

  attr :label, :string, required: true
  attr :value, :string, required: true, doc: "The figure, already formatted."
  attr :unit, :string, default: nil, doc: "A smaller faint suffix beside the figure."
  attr :tone, :string, default: "default", values: ~w(default accent)
  attr :size, :string, default: "default", values: ~w(default sm)

  attr :count, :integer,
    default: nil,
    doc:
      "Animates the figure from 0 to this number (CSS counter, `mo-count`); `value` is ignored."

  attr :prefix, :string, default: "", doc: "Written before an animated `count`."
  attr :sunken, :boolean, default: false, doc: "Fills the item with the sunken background."
  attr :cell, :boolean, default: false, doc: "The padded cell of a `stat_group`."
  attr :divider, :boolean, default: false, doc: "With `cell`: a rule at the left."
  attr :delta, :string, default: nil, doc: "The change, already formatted (`cell` only)."
  attr :trend, :string, default: "up", values: ~w(up down flat)
  attr :delta_tone, :string, default: nil, values: [nil, "success", "error", "neutral"]
  attr :class, :any, default: nil
  attr :rest, :global

  def stat_item(%{cell: true} = assigns) do
    assigns =
      assigns
      |> assign(:classes, cx([assigns.class]))
      |> assign(
        :box_style,
        "padding:16px;border-left:#{if assigns.divider, do: "1px solid var(--line)", else: "0"};display:flex;flex-direction:column;gap:6px"
      )
      |> assign(:fig_style, "font-size:26px;font-weight:600;letter-spacing:-.03em")
      |> assign(:delta_class, delta_class(assigns.trend, assigns.delta_tone))

    ~H"""
    <div data-part="stat" class={@classes} style={@box_style} {@rest}>
      <span class="lu-small lu-muted">{@label}</span>
      <span class="num" style={@fig_style}>{@value}<span :if={@unit} class="lu-muted">{@unit}</span></span>
      <span :if={@delta} class={cx(["lu-delta", @delta_class])}>{@delta}</span>
    </div>
    """
  end

  def stat_item(assigns) do
    box =
      if assigns.sunken,
        do: "gap:2px;background:var(--bg-sunken);padding:10px 14px;border-radius:12px",
        else: "gap:2px"

    fig =
      if assigns.count,
        do:
          "--to:#{assigns.count};--pre:'#{assigns.prefix}';font-size:26px;letter-spacing:-.02em",
        else: "font-size:#{@sizes[assigns.size]}#{@tones[assigns.tone]}"

    assigns =
      assigns
      |> assign(:classes, cx(["lu-col", assigns.class]))
      |> assign(:box_style, box)
      |> assign(:fig_class, assigns.count && "mo-count")
      |> assign(:fig_style, fig)

    ~H"""
    <div data-part="stat" class={@classes} style={@box_style} {@rest}>
      <span class="lu-xs lu-muted">{@label}</span>
      <b :if={@count} class="mo-count" style={@fig_style}></b>
      <b :if={!@count} style={@fig_style}>{@value}<span
        :if={@unit}
        class="lu-muted"
        style="font-size:.6em;font-weight:500"
      >{@unit}</span></b>
    </div>
    """
  end

  attr :card, :boolean, default: true, doc: "Draws the card (`lu-panel`) around the row."
  attr :variant, :string, default: "default", values: ~w(default sunken)

  attr :columns, :integer,
    default: 4,
    doc: "Grid columns of the card (one per item)."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def stat_group(assigns) do
    {class, style} =
      cond do
        assigns.card ->
          {"lu-panel", "display:grid;grid-template-columns:repeat(#{assigns.columns},1fr)"}

        true ->
          {"lu-row", nil}
      end

    style =
      if assigns.variant == "sunken",
        do: [style, "background:var(--bg-sunken)"] |> Enum.reject(&is_nil/1) |> Enum.join(";"),
        else: style

    assigns =
      assigns
      |> assign(:classes, cx([class, assigns.class]))
      |> assign(:style, style)

    ~H"""
    <div data-part="stat-group" class={@classes} {st(@style)} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp delta_class(trend, tone) do
    tone = tone || if trend == "down", do: "error", else: "success"

    cond do
      trend == "flat" or tone == "neutral" -> nil
      tone == "success" -> @delta["up"]
      trend == "down" -> @delta["down"]
      true -> @delta["bad-up"]
    end
  end
end
