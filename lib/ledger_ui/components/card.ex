defmodule LedgerUI.Components.Card do
  @moduledoc """
  The panel: surfaces (`variant`), colour (`color`, `gradient`), optional `:title` and composable
  parts (header, body, footer).

      <.card>
        <:title>Simple Card</:title>
        <span>Lorem ipsum dolor sit amet.</span>
      </.card>
      <.card variant="solid" color="primary"><:title>Primary Card</:title>...</.card>
      <.card variant="gradient" gradient="purple-indigo">...</.card>

      <.card canvas>
        <.card_header>
          <.card_heading level={3}>Profile</.card_heading>
          <.card_actions>...</.card_actions>
        </.card_header>
        <.card_body>...</.card_body>
        <.card_footer>All changes saved</.card_footer>
      </.card>

  By default the card is a `lu-cv` surface (title in a `<b>`, content as given). With `canvas`
  it is the canvas `lu-card` tray, made for `card_header/1`, `card_body/1` and `card_footer/1`.
  `navigate`, `patch` or `href` make the whole card a link, a row that ends in an arrow.

  `size` `xs`/`sm`/`lg` and `shape="xl"` set the padding/corners inline; `md`/`rounded` are the
  defaults. The part elements (`card_body`, ...) render an empty `style` unless `style={false}`.
  """
  use LedgerUI.Component

  @variants ~w(default flat bordered outline muted soft filled solid glow gradient gradient_outline)
  @colors ~w(primary secondary info success warning error)
  @gradients ~w(purple-indigo fuchsia-pink amber-orange sky-blue green-fuchsia)
  @size_style %{"xs" => "padding:8px", "sm" => "padding:11px", "lg" => "padding:20px"}
  @shape_style %{"xl" => "border-radius:22px"}
  @link_style "flex-direction:row;align-items:center;gap:10px"

  attr :variant, :string, default: "default", values: @variants
  attr :size, :string, default: "md", values: ~w(xs sm md lg)

  attr :body, :string,
    default: "seamless",
    values: ~w(seamless divided separated inset flush)

  attr :divider, :string, default: "full", values: ~w(full inset)
  attr :highlight, :boolean, default: true
  attr :color, :string, default: "primary", values: [nil | @colors]
  attr :gradient, :string, default: "purple-indigo", values: [nil | @gradients]
  attr :shape, :string, default: "rounded", values: ~w(rounded xl)
  attr :padded, :boolean, default: true
  attr :canvas, :boolean, default: false, doc: "The canvas `lu-card` tray for the parts."
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :href, :string, default: nil
  attr :arrow, :boolean, default: true
  attr :style, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(target rel download replace method)

  slot :inner_block

  slot :title, doc: "The card's heading, followed by the content." do
    attr :class, :any
  end

  def card(assigns) do
    link? = Enum.any?([assigns.navigate, assigns.patch, assigns.href])

    assigns =
      assigns
      |> assign(:link?, link?)
      |> assign(:classes, classes(assigns))
      |> assign(:attrs, attrs(assigns, link?))

    ~H"""
    <.link
      :if={@link?}
      data-part="card"
      class={@classes}
      navigate={@navigate}
      patch={@patch}
      href={@href}
      {@attrs}
    >
      <b :for={t <- @title} class={t[:class]}>{render_slot(t)}</b>{render_slot(@inner_block)}<.icon
        :if={@arrow}
        name="chevron-right"
        size="md"
        class="lu-muted"
      />
    </.link>
    <section :if={!@link? and @canvas} data-part="card" class={@classes} {@attrs}>
      <header :for={t <- @title} class="lu-card-h">
        <h3 class={cx(["lu-card-t", t[:class]])} style="margin:0">{render_slot(t)}</h3>
      </header>
      <div :if={@title != []} class="lu-card-b">{render_slot(@inner_block)}</div>
      <%= if @title == [] do %>
        {render_slot(@inner_block)}
      <% end %>
    </section>
    <div :if={!@link? and !@canvas} data-part="card" class={@classes} {@attrs}>
      <b :for={t <- @title} class={t[:class]}>{render_slot(t)}</b>{render_slot(@inner_block)}
    </div>
    """
  end

  defp classes(%{canvas: true} = a) do
    cx([
      "lu-card",
      a.variant == "flat" && "flat",
      a.body != "seamless" && "b-#{a.body}",
      a.body == "divided" && a.divider == "inset" && "div-inset",
      !a.highlight && "no-hl",
      a.class
    ])
  end

  defp classes(a) do
    cx([
      "lu-cv",
      a.variant,
      a.color && "c-#{a.color}",
      a.gradient && "g-#{a.gradient}",
      a.body != "seamless" && "b-#{a.body}",
      a.body == "divided" && a.divider == "inset" && "div-inset",
      !a.highlight && "no-hl",
      a.class
    ])
  end

  # `style` goes in a map: `style={nil}` would render `style=""`.
  defp attrs(a, link?) do
    style =
      [
        link? && @link_style,
        !a.padded && "padding:0",
        @size_style[a.size] && !a.canvas && "#{@size_style[a.size]};min-height:0",
        @shape_style[a.shape],
        a.style
      ]
      |> Enum.filter(& &1)
      |> Enum.join(";")

    if style == "", do: a.rest, else: Map.put(a.rest, :style, style)
  end

  attr :size, :string, default: nil, values: [nil, "xs", "sm", "md", "lg"]
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def card_header(assigns) do
    ~H"""
    <header data-part="card-header" class={cx(["lu-card-h", @size && "s-#{@size}", @class])} {@rest}>
      {render_slot(@inner_block)}
    </header>
    """
  end

  attr :size, :string, default: "base", values: ~w(base lg xl)
  attr :level, :integer, default: 2, values: [1, 2, 3, 4, 5, 6]
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def card_heading(assigns) do
    assigns =
      assign(
        assigns,
        :classes,
        cx(["lu-card-t", assigns.size != "base" && "t-#{assigns.size}", assigns.class])
      )

    ~H"""
    <.dynamic_tag
      tag_name={"h#{@level}"}
      data-part="card-heading"
      class={@classes}
      style="margin:0"
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def card_subheading(assigns) do
    ~H"""
    <p data-part="card-subheading" class={cx(["lu-card-s lu-muted", @class])} style="margin:0" {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def card_actions(assigns) do
    ~H"""
    <div data-part="card-actions" class={cx(["act", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :style, :any, default: nil, doc: "Inline style (`false` omits the attribute)."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def card_body(assigns) do
    assigns = assign(assigns, :attrs, style_attrs(assigns))

    ~H"""
    <div data-part="card-body" class={cx(["lu-card-b", @class])} {@attrs}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @align_style %{
    "start" => "justify-content:flex-start",
    "center" => "justify-content:center",
    "end" => "justify-content:flex-end",
    "between" => "justify-content:space-between"
  }

  attr :align, :string, default: nil, values: [nil, "start", "center", "end", "between"]
  attr :size, :string, default: nil, values: [nil, "xs", "sm", "md", "lg"]
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def card_footer(assigns) do
    assigns =
      assign(assigns, :attrs, align_attrs(assigns))

    ~H"""
    <div data-part="card-footer" class={cx(["lu-card-f", @size && "s-#{@size}", @class])} {@attrs}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp align_attrs(%{align: nil, rest: rest}), do: rest
  defp align_attrs(%{align: a, rest: rest}), do: Map.put(rest, :style, @align_style[a])

  # `style=""` unless the caller asks for no attribute at all (`style={false}`).
  defp style_attrs(%{style: false, rest: rest}), do: rest
  defp style_attrs(%{style: style, rest: rest}), do: Map.put(rest, :style, style || "")

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def card_bleed(assigns) do
    ~H"""
    <div
      data-part="card-bleed"
      class={cx(["lu-card-bleed", @class])}
      style="margin:calc(var(--card-p, 16px) * -1);overflow:hidden;border-radius:inherit"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
