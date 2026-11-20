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
  (give `on_remove` to make it act). With `canvas` the tag is the canvas `lu-tag`: an optional
  colour `swatch` and a remove button.
  """
  use LedgerUI.Component

  @shape %{"rounded" => nil, "pill" => "sh-pill", "square" => "sh-square"}

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
    assigns = assign(assigns, :classes, cx(["lu-tag", assigns.class]))

    ~H"""
    <span data-part="tag" class={@classes} {@rest}>
      <span :if={@swatch} class="sw" style={"background:#{@swatch}"}></span>{render_slot(@inner_block)}
      <button
        :if={@removable || @on_remove}
        aria-label={@remove_label}
        data-lu-remove=""
        type="button"
        phx-click={@on_remove || JS.hide(to: {:closest, ".lu-tag"})}
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
          "lu-tg",
          !assigns.tint && "c-#{assigns.color}",
          "v-#{assigns.variant}",
          @shape[assigns.shape],
          assigns.active && "active",
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
    ~H"""
    {render_slot(@inner_block)}<span :if={@count} class="lu-count">{@count}</span><span
      :if={@removable and !@on_remove}
      class="x"
    ><.icon name="x" size="sm" /></span><span
      :if={@on_remove}
      class="x"
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
    assigns = assign(assigns, :classes, cx(["lu-tg-grp", assigns.class]))

    ~H"""
    <span data-part="tag-group" class={@classes} {@rest}>{render_slot(@inner_block)}</span>
    """
  end
end
