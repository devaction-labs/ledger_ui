defmodule LedgerUI.Components.Tag do
  @moduledoc """
  Tags: clickable badges that represent an attribute, a filter or an action.

      <.tag href="#">Default</.tag>
      <.tag navigate={~p"/tags/elixir"} color="primary" shape="pill">Elixir</.tag>
      <.tag color="info" variant="bordered" shape="pill" phx-click="filter">Info</.tag>
      <.tag variant="soft" active={tag in @selected} phx-click="toggle" phx-value-tag={tag}>{tag}</.tag>

      <.tag_group>
        <.tag color="neutral">Primary</.tag>
        <.tag color="primary">55</.tag>
      </.tag_group>

  With `href`, `navigate` or `patch` a tag is a link; otherwise a button. `as="span"` (or
  `static`) renders a non-interactive `<span>`. `removable` draws the `x` of a removable tag
  (give `on_remove` to make it act). With `canvas` the tag is the canvas tag: an optional
  colour `swatch` and a remove button. Styled only with Tailwind utilities (the colour enters as
  `--c`/`--c-on`/`--c-soft`/`--c-ink`, see `LedgerUI.Color`).
  """
  use LedgerUI.Component

  alias LedgerUI.Color

  @base "inline-flex h-[26px] items-center gap-1.5 border border-solid px-[9px] text-[12.5px] font-medium"
  @shape %{"rounded" => "rounded-[7px]", "pill" => "rounded-full", "square" => "rounded-[3px]"}

  @variants %{
    "solid" => "border-transparent bg-(--c) text-(--c-on)",
    "soft" => "border-transparent bg-(--c-soft) text-(--c-ink)",
    "bordered" =>
      "border-[color-mix(in_oklab,var(--c)_35%,transparent)] bg-(--c-soft) text-(--c-ink)",
    "outline" => "border-[color-mix(in_oklab,var(--c)_55%,transparent)] text-(--c-ink)",
    "flat" => "border-transparent bg-sunken text-(--c-ink)"
  }

  # The canvas tag, and the tag the person presses (`aria-pressed`).
  @canvas "inline-flex h-[26px] items-center gap-1.5 rounded-sm border border-line-strong bg-panel pr-1.5 pl-[9px] text-[13px] text-ink-2 aria-pressed:cursor-pointer aria-pressed:border-accent-500 aria-pressed:bg-accent-soft aria-pressed:text-accent-content"
  @canvas_remove "grid size-[18px] cursor-pointer place-items-center rounded-[4px] border-0 bg-none p-0 text-muted hover:bg-hover hover:text-ink"
  @count "inline-grid h-[18px] min-w-[18px] place-items-center rounded-[5px] bg-neg px-[5px] text-[11px] font-semibold text-white tabular-nums"

  attr :color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary info success warning error light)

  attr :variant, :string, default: "solid", values: ~w(solid soft bordered outline flat)
  attr :tint, :string, default: nil, doc: "A CSS colour of its own; overrides `color`."
  attr :active, :boolean, default: false, doc: "Selected state of a filter chip."
  attr :count, :integer, default: nil, doc: "A small pill with this number after the label."
  attr :shape, :string, default: "rounded", values: ~w(rounded pill square)
  attr :as, :string, default: nil, values: [nil, "span"]
  attr :static, :boolean, default: false
  attr :type, :string, default: "button"
  attr :removable, :boolean, default: false, doc: "Draws the `x` of a removable tag."
  attr :on_remove, :any, default: nil, doc: "An event name or `JS` command for the `x`."
  attr :remove_label, :string, default: "Remover"
  attr :canvas, :boolean, default: false, doc: "The canvas `lu-tag` (swatch + remove button)."
  attr :swatch, :string, default: nil, doc: "A CSS colour for the canvas tag's square."
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  slot :inner_block, required: true

  def tag(%{canvas: true} = assigns) do
    assigns =
      assigns
      |> assign(:classes, cx([@canvas, assigns.class]))
      |> assign(:remove_class, @canvas_remove)

    ~H"""
    <span data-part="tag" class={@classes} {@rest}>
      <span
        :if={@swatch}
        data-part="tag-swatch"
        class="size-2 rounded-[2px]"
        style={"background:#{@swatch}"}
      ></span>{render_slot(@inner_block)}
      <button
        :if={@removable || @on_remove}
        data-part="tag-remove"
        class={@remove_class}
        aria-label={@remove_label}
        data-lu-remove=""
        type="button"
        phx-click={@on_remove || JS.hide(to: {:closest, "[data-part=tag]"})}
      >
        <.icon name="x" size="sm" />
      </button>
    </span>
    """
  end

  def tag(assigns) do
    assigns =
      assigns
      |> assign(
        :classes,
        cx([
          @base,
          !assigns.tint && Color.vars(assigns.color),
          !assigns.tint && @variants[assigns.variant],
          assigns.tint && "border-transparent",
          @shape[assigns.shape],
          assigns.class
        ])
      )
      |> assign(:attrs, tag_attrs(assigns))
      |> assign(:link?, link?(assigns.rest))
      |> assign(:span?, assigns.as == "span" or assigns.static)

    ~H"""
    <span :if={@span?} data-part="tag" class={@classes} {@attrs}>
      <.tag_body {assigns} />
    </span>
    <.link
      :if={!@span? and @link?}
      data-part="tag"
      class={@classes}
      aria-pressed={@active && "true"}
      {@attrs}
    >
      <.tag_body {assigns} />
    </.link>
    <button
      :if={!@span? and !@link?}
      data-part="tag"
      type={@type}
      class={@classes}
      aria-pressed={@active && "true"}
      {@attrs}
    >
      <.tag_body {assigns} />
    </button>
    """
  end

  defp link?(rest), do: Enum.any?([:href, :navigate, :patch], &Map.has_key?(rest, &1))

  # `style` goes in a map: `style={nil}` would render `style=""`.
  defp tag_attrs(%{tint: tint, rest: rest}) when is_binary(tint),
    do:
      Map.put(
        rest,
        :style,
        "color:#{tint};background:color-mix(in oklab, #{tint} 14%, transparent)"
      )

  defp tag_attrs(%{rest: rest}), do: rest

  defp tag_body(assigns) do
    assigns = assign(assigns, :count_class, @count)

    ~H"""
    {render_slot(@inner_block)}<span :if={@count} data-part="tag-count" class={@count_class}>{@count}</span><span
      :if={@removable and !@on_remove}
      data-part="tag-remove"
      class="inline-grid opacity-60"
    ><.icon name="x" size="sm" /></span><span
      :if={@on_remove}
      data-part="tag-remove"
      class="inline-grid opacity-60"
      role="button"
      tabindex="0"
      aria-label={@remove_label}
      phx-click={@on_remove}
    ><.icon name="x" size="sm" /></span>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def tag_group(assigns) do
    assigns =
      assign(assigns, :classes, cx(["inline-flex flex-wrap items-center gap-1.5", assigns.class]))

    ~H"""
    <span data-part="tag-group" class={@classes} {@rest}>{render_slot(@inner_block)}</span>
    """
  end
end
