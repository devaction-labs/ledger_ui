defmodule LedgerUI.Components.EmptyState do
  @moduledoc """
  Empty state: what the area is, why it is empty and the one next step. Styled only with Tailwind
  utilities.

      <.empty_state icon="inbox" title="No orders yet">
        Orders from the counter and the site show up here.
        <:action><.button size="sm">New order</.button></:action>
      </.empty_state>

      <.empty_state variant="inline" icon="inbox" title="No comments yet.">
        <a href="#">Write the first</a>
      </.empty_state>

  Variants:

    * `canvas` (default) - icon tile with two dashed frames, title, reason, actions;
    * `card` - centered block for a whole area, icon with pulsing rings (`tone` default,
      `gradient` or `positive`) and an optional `kicker`;
    * `inline` - compact dashed notice for lists and results (`color` neutral/success/error);
    * `table` - centered notice for the body of an empty table (a disc tinted by `color`);
    * `plain` - the faint one-line notice inside a card.

  `level` (2, 3 or 4) marks the title of a `card` as a heading (`aria-level`); without it the
  title is a plain bold line.
  """
  use LedgerUI.Component

  @tones %{"default" => nil, "gradient" => "accent", "positive" => "success"}

  # the ring of the `card` icon: two dashed frames that grow and fade, the second half a cycle later
  @ring "relative inline-grid " <>
          "before:pointer-events-none before:absolute before:-inset-2.5 before:rounded-[18px] before:border before:border-dashed before:border-line-strong before:content-[''] before:animate-[mo-ring_3s_ease-out_infinite] " <>
          "after:pointer-events-none after:absolute after:-inset-2.5 after:rounded-[18px] after:border after:border-dashed after:border-line-strong after:content-[''] after:animate-[mo-ring_3s_ease-out_1.5s_infinite]"

  # the tile of the `canvas` variant has two dashed frames around it
  @art "relative mb-2 grid size-14 place-items-center rounded-[16px] border border-line bg-sunken text-muted " <>
         "before:absolute before:-inset-2 before:rounded-[22px] before:border before:border-dashed before:border-line-strong before:content-[''] " <>
         "after:absolute after:-inset-[18px] after:rounded-[30px] after:border after:border-dashed after:border-line-strong after:opacity-55 after:content-['']"

  @inline_ink %{"neutral" => "text-muted", "success" => "text-pos", "error" => "text-neg"}

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
    assigns =
      assigns
      |> assign(:art, @art)
      |> assign(
        :classes,
        cx([
          "flex flex-col items-center gap-1.5 px-6 py-8 text-center",
          # the positive tone paints the muted ink (the tile and the reason) green
          assigns.tone == "positive" && "[--lu-muted:var(--lu-pos)]"
        ])
      )

    ~H"""
    <div data-part="empty-state" class={[@classes, @class]} {@rest}>
      <span :if={@icon || @illustration != []} data-part="empty-state-art" class={@art}>
        {if @illustration == [], do: icon_for(@icon, "lg"), else: render_slot(@illustration)}
      </span>
      <b data-part="empty-state-title" class="text-[16px] font-semibold">{@title}</b>
      <p
        :if={!blank?(@inner_block)}
        data-part="empty-state-text"
        class="m-0 mb-2.5 max-w-[340px] text-muted"
      >
        {render_slot(@inner_block)}
      </p>
      {render_slot(@action)}
    </div>
    """
  end

  def empty_state(%{variant: "card"} = assigns) do
    assigns = assigns |> assign(:ring, @ring) |> assign(:tile_tone, @tones[assigns.tone])

    ~H"""
    <div
      data-part="empty-state"
      class={["flex flex-col items-center gap-2.5 p-[26px] text-center", @class]}
      {@rest}
    >
      <span :if={@icon || @illustration != []} data-part="empty-state-ring" class={@ring}>
        <.icon boxed box_size={52} tone={@tile_tone}>
          {if @illustration == [], do: icon_for(@icon, "lg"), else: render_slot(@illustration)}
        </.icon>
      </span>
      <span
        :if={@kicker}
        data-part="empty-state-kicker"
        class="text-xs uppercase tracking-[.06em] text-muted"
      >{@kicker}</span>
      <b data-part="empty-state-title" role={@level && "heading"} aria-level={@level}>{@title}</b>
      <span
        :if={!blank?(@inner_block)}
        data-part="empty-state-text"
        class="text-[13px] leading-[18px] text-muted"
      >{render_slot(@inner_block)}</span>
      {render_slot(@action)}
    </div>
    """
  end

  def empty_state(%{variant: "inline"} = assigns) do
    assigns = assign(assigns, :ink, @inline_ink[assigns.color])

    ~H"""
    <div
      data-part="empty-state"
      class={[
        "flex flex-wrap items-center gap-2.5 rounded-lg border border-dashed border-line bg-panel px-3.5 py-3",
        @ink,
        @class
      ]}
      {@rest}
    >
      {icon_for(@icon, "md")}{@title}{render_slot(@inner_block)}{render_slot(@action)}
    </div>
    """
  end

  def empty_state(%{variant: "plain"} = assigns) do
    ~H"""
    <div
      data-part="empty-state"
      class={[
        "flex flex-wrap items-center gap-2.5 px-1 py-2.5 text-[13px] leading-[18px] text-muted",
        @class
      ]}
      {@rest}
    >
      {icon_for(@icon, "md")}{@title}{render_slot(@inner_block)}{render_slot(@action)}
    </div>
    """
  end

  def empty_state(%{variant: "table"} = assigns) do
    assigns = assign(assigns, :disc, LedgerUI.Color.vars(assigns.color))

    ~H"""
    <div
      data-part="empty-state"
      class={["flex flex-col items-center gap-2 px-4 py-8 text-center", @class]}
      {@rest}
    >
      <span
        :if={@icon || @illustration != []}
        data-part="empty-state-disc"
        class={[
          "relative inline-grid size-12 flex-none place-items-center rounded-[28%] bg-(--c-soft) text-(--c-ink)",
          @disc
        ]}
      >
        {if @illustration == [], do: icon_for(@icon, "md"), else: render_slot(@illustration)}
      </span>
      <b data-part="empty-state-title">{@title}</b>
      <span
        :if={!blank?(@inner_block)}
        data-part="empty-state-text"
        class="text-[13px] leading-[18px] text-muted"
      >{render_slot(@inner_block)}</span>
      {render_slot(@action)}
    </div>
    """
  end

  defp blank?(slot), do: LedgerUI.Components.Modal.Support.blank?(slot)

  defp icon_for(nil, _size), do: nil

  defp icon_for(name, size) do
    assigns = %{name: name, size: size}
    ~H"<.icon name={@name} size={@size} />"
  end

  attr :variant, :string,
    default: "canvas",
    values: ["canvas", "card", "inline", "table", "plain"]

  attr :title, :string, required: true
  attr :kicker, :string, default: nil
  attr :icon, :string, default: nil
  attr :tone, :string, default: "default", values: ["default", "gradient", "positive"]
  attr :color, :string, default: "neutral", values: ["neutral", "success", "error"]
  attr :level, :integer, default: nil, values: [nil, 2, 3, 4]
  attr :class, :any, default: nil
  attr :rest, :global
  slot :action, doc: "The next step."
  slot :illustration, doc: "Replaces the icon."
  slot :inner_block, doc: "The reason it is empty."

  @doc "Same as `empty_state/1` (same attributes and slots), under the name the design vitrine uses."
  def empty_state_card(assigns), do: empty_state(assigns)

  attr :text, :string, required: true
  attr :icon, :string, default: nil
  attr :color, :string, default: "neutral", values: ~w(neutral success error)
  attr :class, :any, default: nil
  attr :rest, :global
  slot :action, doc: "The next step."

  @doc """
  The one-line empty state inside a panel or a table cell: an icon and a sentence.

      <.inline_empty icon="inbox" text="No comments yet" />
  """
  def inline_empty(assigns) do
    ~H"""
    <.empty_state
      variant="inline"
      title={@text}
      icon={@icon}
      color={@color}
      class={@class}
      {@rest}
    >
      <:action :if={@action != []}>{render_slot(@action)}</:action>
    </.empty_state>
    """
  end
end
