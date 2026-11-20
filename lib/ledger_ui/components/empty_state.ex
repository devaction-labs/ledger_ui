defmodule LedgerUI.Components.EmptyState do
  @moduledoc """
  Empty state: what the area is, why it is empty and the one next step.

      <.empty_state icon="inbox" title="No orders yet">
        Orders from the counter and the site show up here.
        <:action><button class="lu-b c-mono v-solid s-sm sh-rounded">New order</button></:action>
      </.empty_state>

      <.empty_state variant="inline" icon="inbox" title="No comments yet.">
        <a href="#">Write the first</a>
      </.empty_state>

  Variants:

    * `canvas` (default) - the canvas `lu-empty`: icon tile, title, reason, actions;
    * `card` - centered block for a whole area, icon with pulsing rings (`tone` default,
      `gradient` or `positive`) and an optional `kicker`;
    * `inline` - compact dashed notice for lists and results (`color` neutral/success/error);
    * `table` - centered notice for the body of an empty table (a disc tinted by `color`);
    * `plain` - the faint one-line notice inside a card.

  `level` (2, 3 or 4) marks the title of a `card` as a heading (`aria-level`); without it the
  title is a plain bold line.
  """
  use LedgerUI.Component

  @tone_class %{"default" => nil, "gradient" => "acc", "positive" => "pos"}
  @color_var %{"neutral" => "var(--muted)", "success" => "var(--pos)", "error" => "var(--neg)"}

  attr :variant, :string, default: "canvas", values: ~w(canvas card inline table plain)
  attr :title, :string, required: true
  attr :kicker, :string, default: nil
  attr :icon, :string, default: nil
  attr :tone, :string, default: "default", values: ~w(default gradient positive)
  attr :color, :string, default: "neutral", values: ~w(neutral success error)
  attr :level, :integer, default: nil, values: [nil, 2, 3, 4]
  attr :class, :any, default: nil
  attr :rest, :global

  slot :action, doc: "The next step."
  slot :illustration, doc: "Replaces the icon."
  slot :inner_block, doc: "The reason it is empty."

  def empty_state(%{variant: "canvas"} = assigns) do
    assigns = assign(assigns, :classes, cx(["lu-empty", assigns.class]))

    ~H"""
    <div data-part="empty-state" class={@classes} style={if @tone == "positive", do: "--muted:var(--pos)"} {@rest}>
      <span :if={@icon || @illustration != []} class="art">
        {if @illustration == [], do: icon_for(@icon, "lg"), else: render_slot(@illustration)}
      </span>
      <b>{@title}</b>
      <p :if={@inner_block != []}>{render_slot(@inner_block)}</p>
      {render_slot(@action)}
    </div>
    """
  end

  def empty_state(%{variant: "card"} = assigns) do
    assigns =
      assigns
      |> assign(:classes, cx(["lu-col", assigns.class]))
      |> assign(:tile, cx(["lu-ic", @tone_class[assigns.tone]]))

    ~H"""
    <div
      data-part="empty-state"
      class={@classes}
      style="align-items:center;gap:10px;text-align:center;padding:26px"
      {@rest}
    >
      <span :if={@icon || @illustration != []} class="lu-empty-ring" style="display:inline-grid">
        <span class={@tile} style="width:52px;height:52px">
          {if @illustration == [], do: icon_for(@icon, "lg"), else: render_slot(@illustration)}
        </span>
      </span>
      <span :if={@kicker} class="lu-xs lu-muted" style="text-transform:uppercase;letter-spacing:.06em">
        {@kicker}
      </span>
      <b role={@level && "heading"} aria-level={@level}>{@title}</b>
      <span :if={@inner_block != []} class="lu-small lu-muted">{render_slot(@inner_block)}</span>
      {render_slot(@action)}
    </div>
    """
  end

  def empty_state(%{variant: "inline"} = assigns) do
    assigns =
      assigns
      |> assign(:classes, cx(["lu-row lu-panel", assigns.class]))
      |> assign(:style, "padding:12px 14px;color:#{@color_var[assigns.color]};border-style:dashed")

    ~H"""
    <div data-part="empty-state" class={@classes} style={@style} {@rest}>
      {icon_for(@icon, "md")}{@title}{render_slot(@inner_block)}{render_slot(@action)}
    </div>
    """
  end

  def empty_state(%{variant: "plain"} = assigns) do
    assigns = assign(assigns, :classes, cx(["lu-row lu-small lu-muted", assigns.class]))

    ~H"""
    <div data-part="empty-state" class={@classes} style="padding:10px 4px" {@rest}>
      {icon_for(@icon, "md")}{@title}{render_slot(@inner_block)}{render_slot(@action)}
    </div>
    """
  end

  def empty_state(%{variant: "table"} = assigns) do
    assigns =
      assigns
      |> assign(:classes, cx(["lu-col", assigns.class]))
      |> assign(:disc, "lu-av c-#{assigns.color} v-soft sh-rounded")

    ~H"""
    <div
      data-part="empty-state"
      class={@classes}
      style="align-items:center;gap:8px;text-align:center;padding:32px 16px"
      {@rest}
    >
      <span :if={@icon || @illustration != []} class={@disc} style="--s:48px">
        {if @illustration == [], do: icon_for(@icon, "md"), else: render_slot(@illustration)}
      </span>
      <b>{@title}</b>
      <span :if={@inner_block != []} class="lu-small lu-muted">{render_slot(@inner_block)}</span>
      {render_slot(@action)}
    </div>
    """
  end

  defp icon_for(nil, _size), do: nil

  defp icon_for(name, size) do
    assigns = %{name: name, size: size}
    ~H"<.icon name={@name} size={@size} />"
  end
end
