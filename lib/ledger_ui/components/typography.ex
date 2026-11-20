defmodule LedgerUI.Components.Typography do
  @moduledoc """
  Ledger UI's type scale: headings, running text, text links, inline code and keyboard keys.

      <.heading level={1}>Heading H1</.heading>
      <.heading level={1} size="title">Financeiro</.heading>
      <.heading display={2}>Display 2</.heading>

      <.text size="lg" color="subtle">Contas a pagar e a receber.</.text>
      <.text as="span" mono color="ink">R$ 3.120,50</.text>
      <.text as="span" size="lg" weight="semibold" gradient="sky-blue">Gradient</.text>
      <.text_link href="#" decoration_color="info" decoration_style="wavy">Tattooine</.text_link>

      Press <.kbd>Ctrl</.kbd> + <.kbd>K</.kbd>, or run <.inline_code>mix test</.inline_code>.

  Sizes, weights and colours are emitted as inline `font-*`/`color` declarations that read the
  design tokens (`var(--ink)`, `var(--muted)`...), so they follow the theme. Every attr left at
  `nil` emits nothing and the text inherits.

  Colours: `default` inherits, `ink`/`fg` are the primary text, `neutral` is `ink-2`, `muted`,
  `subtle`/`faint` the secondary and meta greys, `primary` the accent ink, and
  `success`/`warning`/`error`/`info`/`secondary` the signal colours.

  `text` defaults `weight` to `nil` (inherit); an explicit `"normal"` sets `font-weight:400`.
  """
  use LedgerUI.Component

  @colors %{
    "default" => nil,
    "ink" => "var(--ink)",
    "fg" => "var(--ink)",
    "neutral" => "var(--ink-2)",
    "muted" => "var(--muted)",
    "subtle" => "var(--subtle)",
    "faint" => "var(--subtle)",
    "primary" => "var(--accent-ink)",
    "secondary" => "var(--violet)",
    "success" => "var(--pos)",
    "warning" => "var(--warn)",
    "error" => "var(--neg)",
    "info" => "var(--info)"
  }
  @color_values Map.keys(@colors)

  @weights %{
    "light" => "300",
    "normal" => "400",
    "medium" => "500",
    "semibold" => "600",
    "bold" => "700"
  }

  @level_sizes %{1 => "40px", 2 => "32px", 3 => "26px", 4 => "20px", 5 => "17px", 6 => "15px"}
  @heading_sizes %{
    "sm" => "14px",
    "base" => "16px",
    "lg" => "18px",
    "xl" => "20px",
    "2xl" => "24px",
    "3xl" => "30px"
  }
  @display_sizes %{1 => "56px", 2 => "48px", 3 => "40px", 4 => "34px", 5 => "28px"}

  @text_sizes %{
    "inherit" => nil,
    "xs" => "12px",
    "xs-plus" => "13px",
    "sm" => "14px",
    "base" => "16px",
    "lg" => "18px",
    "xl" => "20px",
    "meta" => "12.5px",
    "lead" => "18px"
  }

  @decorations %{
    "underline" => "underline",
    "overline" => "overline",
    "line-through" => "line-through",
    "none" => "none"
  }

  @link_colors %{
    "current" => "currentColor",
    "primary" => "var(--accent-ink)",
    "secondary" => "var(--violet)",
    "info" => "var(--info)",
    "success" => "var(--pos)",
    "warning" => "var(--warn)",
    "error" => "var(--neg)"
  }

  @kbd_flat "box-shadow:none;background:var(--bg-sunken);border-color:transparent"

  defp decl(_prop, nil), do: nil
  defp decl(prop, value), do: prop <> ":" <> value

  # Joins declarations and the caller's own `style`; `nil` when empty.
  defp style(decls, extra) do
    case [decls, extra] |> List.flatten() |> Enum.reject(&(&1 in [nil, ""])) |> Enum.join(";") do
      "" -> nil
      s -> s
    end
  end

  defp classes(list) do
    case cx(list) do
      "" -> nil
      s -> s
    end
  end

  # `style={nil}` would render `style=""`: the style goes in the attribute map instead.
  defp with_style(rest, nil), do: rest
  defp with_style(rest, style), do: Map.put(rest, :style, style)

  attr :level, :integer, default: nil, values: [nil, 1, 2, 3, 4, 5, 6]

  attr :size, :string,
    default: nil,
    values: [nil, "2xl", "3xl", "base", "lg", "sm", "title", "xl"]

  attr :display, :integer, default: nil, values: [nil, 1, 2, 3, 4, 5]

  attr :weight, :string,
    default: nil,
    values: [nil, "normal", "light", "medium", "semibold", "bold"]

  attr :color, :string, default: "default", values: @color_values
  attr :class, :any, default: nil
  attr :style, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc """
  A heading, `<h1>` to `<h6>`. `display` renders the display headings (an `<h1>` unless `level`
  says otherwise); `size` sets the type size apart from the level; `size="title"` is the page
  title (34/40, semibold, ink).
  """
  def heading(assigns) do
    level = assigns.level || if(assigns.display, do: 1, else: 2)
    title? = assigns.size == "title"
    display? = assigns.display != nil

    font_size =
      cond do
        title? -> "34px"
        assigns.size -> @heading_sizes[assigns.size]
        display? -> @display_sizes[assigns.display]
        true -> @level_sizes[level]
      end

    weight = assigns.weight || if(title? or display?, do: "semibold")

    color =
      if assigns.color == "default" and title?,
        do: "var(--ink)",
        else: @colors[assigns.color]

    decls = [
      "margin:0",
      decl("font-size", font_size),
      if(title?, do: "line-height:40px"),
      decl("letter-spacing", if(title? or display?, do: "-.03em", else: "-.02em")),
      decl("font-weight", @weights[weight]),
      decl("color", color)
    ]

    assigns =
      assigns
      |> assign(:tag, "h#{level}")
      |> assign(:rest, with_style(assigns.rest, style(decls, assigns.style)))
      |> assign(:class_s, classes([assigns.class]))

    ~H"""
    <.dynamic_tag tag_name={@tag} data-part="heading" class={@class_s} {@rest}>
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :as, :string, default: "p", values: ~w(p span div strong em small)

  attr :size, :string,
    default: "inherit",
    values: ~w(inherit xs xs-plus sm base lg xl meta lead)

  attr :weight, :string,
    default: nil,
    values: [nil, "normal", "light", "medium", "semibold", "bold"]

  attr :color, :string, default: "default", values: @color_values
  attr :mono, :boolean, default: false

  attr :gradient, :string,
    default: nil,
    values: [nil, "sky-blue", "green-fuchsia", "fuchsia-pink", "amber-orange", "purple-indigo"]

  attr :decoration, :string,
    default: nil,
    values: [nil, "underline", "overline", "line-through", "none"]

  attr :class, :any, default: nil
  attr :style, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc """
  A run of text, a paragraph unless `as` says otherwise.

  `meta` is the 12.5px meta/help line, `lead` the line under a page title.
  """
  def text(assigns) do
    decls = [
      decl("font-size", @text_sizes[assigns.size]),
      decl("font-weight", @weights[assigns.weight]),
      decl("color", @colors[assigns.color]),
      decl("text-decoration", @decorations[assigns.decoration])
    ]

    assigns =
      assigns
      |> assign(:rest, with_style(assigns.rest, style(decls, assigns.style)))
      |> assign(
        :class_s,
        classes([
          {"mono", assigns.mono},
          assigns.gradient && "lu-ty-grad g-#{assigns.gradient}",
          assigns.class
        ])
      )

    ~H"""
    <.dynamic_tag tag_name={@as} data-part="text" class={@class_s} {@rest}>
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :decoration_color, :string,
    default: "current",
    values: ~w(current primary secondary info success warning error)

  attr :decoration_style, :string, default: "solid", values: ~w(solid wavy double dotted dashed)
  attr :class, :any, default: nil
  attr :style, :string, default: nil

  attr :rest, :global, include: ~w(href navigate patch method download target rel replace)

  slot :inner_block, required: true

  @doc """
  A link inside running text, underlined (1px) in a theme colour and style. It keeps the weight
  of the text around it. With `href`, `navigate` or `patch`.
  """
  def text_link(assigns) do
    decls = [
      "text-decoration:underline #{assigns.decoration_style}",
      decl("text-decoration-color", @link_colors[assigns.decoration_color]),
      "text-decoration-thickness:1px",
      "text-underline-offset:3px"
    ]

    assigns =
      assigns
      |> assign(:rest, with_style(assigns.rest, style(decls, assigns.style)))
      |> assign(:class_s, classes([assigns.class]))

    ~H"""
    <.link data-part="text-link" class={@class_s} {@rest}>
      {render_slot(@inner_block)}
    </.link>
    """
  end

  attr :class, :any, default: nil
  attr :style, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "Code inside running text: mono 12.5px on the fill colour, in the primary text colour."
  def inline_code(assigns) do
    assigns =
      assigns
      |> assign(:class_s, classes(["mono", assigns.class]))
      |> assign(
        :rest,
        with_style(
          assigns.rest,
          style(
            [
              "font-size:12.5px",
              "background:var(--bg-sunken)",
              "color:var(--ink)",
              "padding:1px 5px",
              "border-radius:5px"
            ],
            assigns.style
          )
        )
      )

    ~H"""
    <code data-part="inline-code" class={@class_s} {@rest}>
      {render_slot(@inner_block)}
    </code>
    """
  end

  attr :variant, :string,
    default: "raised",
    values: ~w(raised flat dark),
    doc: "`flat` has no shadow, on the sunken fill; `dark` is for dark surfaces (tooltip, toast)."

  attr :class, :any, default: nil
  attr :style, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "A keyboard key (`lu-kbd`)."
  def kbd(assigns) do
    assigns =
      assigns
      |> assign(:class_s, classes(["lu-kbd", {"dark", assigns.variant == "dark"}, assigns.class]))
      |> assign(
        :rest,
        with_style(
          assigns.rest,
          style(if(assigns.variant == "flat", do: [@kbd_flat], else: []), assigns.style)
        )
      )

    ~H"""
    <kbd data-part="kbd" class={@class_s} {@rest}>{render_slot(@inner_block)}</kbd>
    """
  end

  attr :as, :string, default: "p", values: ["p", "span", "div", "strong", "em", "small"]

  attr :size, :string,
    default: "inherit",
    values: ["inherit", "xs", "xs-plus", "sm", "base", "lg", "xl", "meta", "lead"]

  attr :weight, :string,
    default: nil,
    values: [nil, "normal", "light", "medium", "semibold", "bold"]

  attr :color, :string,
    default: "default",
    values: [
      "default",
      "error",
      "faint",
      "fg",
      "info",
      "ink",
      "muted",
      "neutral",
      "primary",
      "secondary",
      "subtle",
      "success",
      "warning"
    ]

  attr :mono, :boolean, default: false

  attr :gradient, :string,
    default: nil,
    values: [nil, "sky-blue", "green-fuchsia", "fuchsia-pink", "amber-orange", "purple-indigo"]

  attr :decoration, :string,
    default: nil,
    values: [nil, "underline", "overline", "line-through", "none"]

  attr :class, :any, default: nil
  attr :style, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  @doc "Same as `text/1` (same attributes and slots), under the name the design vitrine uses."
  def typography(assigns), do: text(assigns)
end
