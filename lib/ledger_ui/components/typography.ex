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

  Sizes, weights and colours are Tailwind utilities that read the design tokens (`text-ink`,
  `text-muted`...), so they follow the theme. Every attr left at `nil` emits nothing and the text
  inherits.

  Colours: `default` inherits, `ink`/`fg` are the primary text, `neutral` is `ink-2`, `muted`,
  `subtle`/`faint` the secondary and meta greys, `primary` the accent text, and
  `success`/`warning`/`error`/`info`/`secondary` the signal colours.

  `text` defaults `weight` to `nil` (inherit); an explicit `"normal"` sets `font-weight:400`.
  A `gradient` paints the glyphs with the named gradient (bold unless `weight` says otherwise) and
  makes `color` moot. `style` and `class` are for layout and one-off tweaks (a `style` always wins).
  """
  use LedgerUI.Component

  @colors %{
    "default" => nil,
    "ink" => "text-ink",
    "fg" => "text-ink",
    "neutral" => "text-ink-2",
    "muted" => "text-muted",
    "subtle" => "text-subtle",
    "faint" => "text-subtle",
    "primary" => "text-accent-content",
    "secondary" => "text-violet",
    "success" => "text-pos",
    "warning" => "text-warn",
    "error" => "text-neg",
    "info" => "text-info"
  }
  @color_values Map.keys(@colors)

  @weights %{
    "light" => "font-light",
    "normal" => "font-normal",
    "medium" => "font-medium",
    "semibold" => "font-semibold",
    "bold" => "font-bold"
  }

  # A `text-[Npx]` sets the size only: the line height stays the one the text inherits.
  @level_sizes %{
    1 => "text-[40px]",
    2 => "text-[32px]",
    3 => "text-[26px]",
    4 => "text-[20px]",
    5 => "text-[17px]",
    6 => "text-[15px]"
  }
  @heading_sizes %{
    "sm" => "text-[14px]",
    "base" => "text-[16px]",
    "lg" => "text-[18px]",
    "xl" => "text-[20px]",
    "2xl" => "text-[24px]",
    "3xl" => "text-[30px]"
  }
  @display_sizes %{
    1 => "text-[56px]",
    2 => "text-[48px]",
    3 => "text-[40px]",
    4 => "text-[34px]",
    5 => "text-[28px]"
  }

  @text_sizes %{
    "inherit" => nil,
    "xs" => "text-[12px]",
    "xs-plus" => "text-[13px]",
    "sm" => "text-[14px]",
    "base" => "text-[16px]",
    "lg" => "text-[18px]",
    "xl" => "text-[20px]",
    "meta" => "text-[12.5px]",
    "lead" => "text-[18px]"
  }

  @decorations %{
    "underline" => "underline",
    "overline" => "overline",
    "line-through" => "line-through",
    "none" => "no-underline"
  }

  @gradients %{
    "sky-blue" => "bg-[linear-gradient(90deg,#0ea5e9,#2563eb)]",
    "green-fuchsia" => "bg-[linear-gradient(90deg,#22c55e,#d946ef)]",
    "fuchsia-pink" => "bg-[linear-gradient(90deg,#d946ef,#ec4899)]",
    "amber-orange" => "bg-[linear-gradient(90deg,#f59e0b,#f97316)]",
    "purple-indigo" => "bg-[linear-gradient(90deg,#8b5cf6,#4f46e5)]"
  }

  @link_colors %{
    "current" => "decoration-current",
    "primary" => "decoration-accent-content",
    "secondary" => "decoration-violet",
    "info" => "decoration-info",
    "success" => "decoration-pos",
    "warning" => "decoration-warn",
    "error" => "decoration-neg"
  }

  @link_styles %{
    "solid" => "decoration-solid",
    "wavy" => "decoration-wavy",
    "double" => "decoration-double",
    "dotted" => "decoration-dotted",
    "dashed" => "decoration-dashed"
  }

  # `class=""` would render an empty attribute: nothing at all when no utility applies.
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
    changed0 = assigns.__changed__
    level = assigns.level || if(assigns.display, do: 1, else: 2)
    title? = assigns.size == "title"
    display? = assigns.display != nil

    size =
      cond do
        title? -> "text-[34px] leading-10"
        assigns.size -> @heading_sizes[assigns.size]
        display? -> @display_sizes[assigns.display]
        true -> @level_sizes[level]
      end

    color =
      if assigns.color == "default" and title?, do: "text-ink", else: @colors[assigns.color]

    assigns =
      assigns
      |> assign(:tag, "h#{level}")
      |> assign(:rest, with_style(assigns.rest, assigns.style))
      |> assign(:utilities, [
        "m-0",
        size,
        if(title? or display?, do: "tracking-[-.03em]", else: "tracking-[-.02em]"),
        @weights[assigns.weight || "semibold"],
        color
      ])

    assigns =
      settle(assigns, changed0,
        tag: [:level, :display],
        rest: [:rest, :style],
        utilities: [:level, :display, :size, :color, :weight]
      )

    ~H"""
    <.dynamic_tag
      phx-no-format
      tag_name={@tag}
      data-part="heading"
      class={[@utilities, @class]}
      {@rest}
    >{render_slot(@inner_block)}</.dynamic_tag>
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
    changed0 = assigns.__changed__
    gradient = assigns.gradient && @gradients[assigns.gradient]

    utilities = [
      @text_sizes[assigns.size],
      @weights[assigns.weight || (gradient && "bold")],
      if(gradient,
        do: [gradient, "bg-clip-text [-webkit-background-clip:text] text-transparent"],
        else: @colors[assigns.color]
      ),
      assigns.mono && "font-mono",
      @decorations[assigns.decoration]
    ]

    assigns =
      assigns
      |> assign(:rest, with_style(assigns.rest, assigns.style))
      |> assign(:class_s, classes([utilities, assigns.class]))

    assigns =
      settle(assigns, changed0,
        rest: [:rest, :style],
        class_s: [:gradient, :size, :weight, :color, :mono, :decoration, :class]
      )

    ~H"""
    <.dynamic_tag
      phx-no-format
      tag_name={@as}
      data-part="text"
      class={@class_s}
      {@rest}
    >{render_slot(@inner_block)}</.dynamic_tag>
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
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:rest, with_style(assigns.rest, assigns.style))
      |> assign(:utilities, [
        "underline decoration-1 underline-offset-[3px]",
        @link_styles[assigns.decoration_style],
        @link_colors[assigns.decoration_color]
      ])

    assigns =
      settle(assigns, changed0,
        rest: [:rest, :style],
        utilities: [:decoration_style, :decoration_color]
      )

    ~H"""
    <.link data-part="text-link" class={[@utilities, @class]} {@rest}>{render_slot(@inner_block)}</.link>
    """
  end

  attr :class, :any, default: nil
  attr :style, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "Code inside running text: mono 12.5px on the fill colour, in the primary text colour."
  def inline_code(assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :rest, with_style(assigns.rest, assigns.style))
    assigns = settle(assigns, changed0, rest: [:rest, :style])

    ~H"""
    <code
      data-part="inline-code"
      class={[
        "rounded-[5px] bg-sunken px-[5px] py-px font-mono text-[12.5px] text-ink",
        @class
      ]}
      {@rest}
    >{render_slot(@inner_block)}</code>
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

  @kbd_base "inline-flex h-[22px] min-w-[22px] items-center justify-center rounded-sm border px-1.5 font-mono text-[11.5px] leading-none"
  @kbd_variants %{
    "raised" => "border-line-strong bg-panel text-ink-2 shadow-[inset_0_-1px_0_var(--lu-line)]",
    "flat" => "border-transparent bg-sunken text-ink-2 shadow-none",
    "dark" => "border-[rgba(255,255,255,.16)] bg-[rgba(255,255,255,.12)] text-inherit shadow-none"
  }

  @doc "A keyboard key."
  def kbd(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:rest, with_style(assigns.rest, assigns.style))
      |> assign(:utilities, [@kbd_base, @kbd_variants[assigns.variant]])

    assigns = settle(assigns, changed0, rest: [:rest, :style], utilities: [:variant])

    ~H"""
    <kbd data-part="kbd" class={[@utilities, @class]} {@rest}>{render_slot(@inner_block)}</kbd>
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
