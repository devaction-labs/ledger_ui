defmodule LedgerUI.Components.Button do
  @moduledoc """
  Buttons, styled only with Tailwind utilities: `button/1`, `button_group/1`, `icon_button/1`
  (square icon-only buttons, the top bar button and the round "go" button) and `insight_button/1`.

      <.button>Export report</.button>
      <.button color="primary" variant="soft" size="sm">Save</.button>
      <.button color="error" variant="outline" shape="pill">Delete</.button>
      <.button color="primary" variant="soft" icon="huge-sparkles" aria-label="IA" />
      <.button navigate={~p"/orders"} variant="ghost">Orders</.button>
      <.button color="primary" loading={@saving}>Saving</.button>
      <.button variant="outline" icon="huge-bell" pip aria-label="Notifications" />

      <.button_group shape="pill">
        <.button variant="outline" size="sm">Day</.button>
        <.button variant="outline" size="sm">Week</.button>
      </.button_group>

      <.icon_button icon="plus" label="Add" variant="primary" />
      <.icon_button icon="notification-03" label="Notifications" variant="topbar" dot />

  The colour enters as four local variables (`--c`, `--c-on`, `--c-soft`, `--c-ink`, see
  `LedgerUI.Color`) and each variant only reads those: 10 colours x 9 variants without a
  combinatorics of classes. The default `color="neutral" variant="solid"` is the black button of the
  system. `color="current"` follows the text colour of the parent.

  With `href`, `navigate` or `patch` a link is rendered that looks the same. Without content and with
  `icon`, the button is icon-only (`shape="square"`); `icon` also accepts `true` (square button whose
  content is the slot, e.g. an inline SVG).

  `loading` blocks the button (no double submit) with `disabled` (links: `aria-disabled`) plus
  `aria-busy`, hides the label keeping the width and shows a spinner on top. It is not `inert`, so the
  spinner's `role="status"` is announced. `pip` puts the notification dot on the corner.

  To change a measure pick the matching attr (`size`, `shape`): two utilities of one property in a
  class list are resolved by the stylesheet, never by their order, so `class` is for layout
  (`w-full`, `ml-auto`), not for overriding the component's own look.
  """
  use LedgerUI.Component

  @colors LedgerUI.Color.names()

  # a variant only reads --c, --c-on, --c-soft and --c-ink
  @variants %{
    "solid" => "border-transparent bg-(--c) text-(--c-on) not-disabled:hover:brightness-108",
    "glow" =>
      "border-transparent bg-(--c) text-(--c-on) shadow-[0_6px_18px_-4px_color-mix(in_oklab,var(--c)_60%,transparent)]",
    "outline" =>
      "bg-transparent text-(--c-ink) border-[color-mix(in_oklab,var(--c)_55%,transparent)] hover:bg-(--c-soft)",
    "soft" =>
      "border-transparent bg-(--c-soft) text-(--c-ink) hover:bg-[color-mix(in_oklab,var(--c)_18%,var(--lu-bg-panel))]",
    "bordered" =>
      "bg-(--c-soft) text-(--c-ink) border-[color-mix(in_oklab,var(--c)_35%,transparent)]",
    "flat" =>
      "border-transparent bg-[color-mix(in_oklab,var(--c)_9%,transparent)] text-(--c-ink)",
    "glass" =>
      "bg-[color-mix(in_oklab,var(--c)_14%,rgba(255,255,255,.35))] text-(--c-ink) border-white/45 backdrop-blur-[10px] shadow-[inset_0_1px_0_rgba(255,255,255,.5),var(--lu-shadow-xs)]",
    "ghost" => "border-transparent bg-transparent text-(--c-ink) hover:bg-(--c-soft)",
    "dim" =>
      "border-transparent bg-[color-mix(in_oklab,var(--c)_82%,var(--lu-bg-page))] text-(--c-on) opacity-90"
  }

  # height, padding, width of the square button, font and gap, radius
  @sizes %{
    "xs" => {"h-[26px]", "px-2", "w-[26px]", "text-xs gap-1", "rounded-[7px]"},
    "sm" => {"h-[30px]", "px-2.5", "w-[30px]", "text-[13px] gap-1.5", "rounded-[8px]"},
    "md" => {"h-9", "px-3.5", "w-9", "text-sm gap-2", "rounded-md"},
    "lg" => {"h-11", "px-[18px]", "w-11", "text-[15px] gap-2", "rounded-[12px]"},
    "xl" => {"h-[52px]", "px-[22px]", "w-[52px]", "text-base gap-2", "rounded-[14px]"}
  }

  @base "relative inline-flex items-center justify-center border font-medium leading-none whitespace-nowrap no-underline " <>
          "transition-[background,box-shadow,transform,filter] duration-150 not-disabled:active:translate-y-[.5px] " <>
          "focus-visible:outline-none focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] [&_svg]:size-4"

  @spinner_tone %{"solid" => "text-(--c-on)", "glow" => "text-(--c-on)", "dim" => "text-(--c-on)"}

  @link_attrs ~w(href navigate patch)a

  def colors, do: @colors
  def variants, do: Map.keys(@variants)
  def sizes, do: Map.keys(@sizes)

  @doc false
  # The class list of a button.
  def classes(color, variant, size, shape, opts \\ []) do
    {h, px, w, text, r} = @sizes[size]

    [
      @base,
      LedgerUI.Color.vars(color),
      @variants[variant],
      h,
      text,
      if(shape == "square", do: [w, "px-0"], else: px),
      if(shape == "pill", do: "rounded-full", else: r),
      (color == "neutral" and variant == "solid") && "shadow-btn",
      if(opts[:loading],
        do: "cursor-progress",
        else:
          "disabled:opacity-45 disabled:cursor-not-allowed aria-disabled:opacity-45 aria-disabled:cursor-not-allowed cursor-pointer"
      )
    ]
  end

  attr :color, :string,
    default: "neutral",
    values: @colors,
    doc: "`current` takes the parent's text colour."

  attr :variant, :string, default: "solid", values: Map.keys(@variants)
  attr :size, :string, default: "md", values: Map.keys(@sizes)

  attr :shape, :string,
    default: nil,
    values: [nil, "rounded", "pill", "square"],
    doc:
      "`square` is the icon-only button; without `shape` it is chosen from `icon` and the content."

  attr :icon, :any,
    default: nil,
    doc:
      "An icon name (`\"huge-plus\"`, `\"plus\"`): that icon before the label; without content the " <>
        "button is icon-only. `true`: a square button holding only the slot (pass `aria-label`)."

  attr :trailing_icon, :string, default: nil, doc: "An icon name after the label."

  attr :canvas, :boolean,
    default: false,
    doc:
      "The compact toolbar button of the canvas: `size` (`sm`/`lg`) applies, `color`, `variant` and `shape` do not."

  attr :type, :string, default: "button"
  attr :disabled, :boolean, default: false

  attr :loading, :boolean,
    default: false,
    doc:
      "Disables the button (no clicks), marks it `aria-busy`, shows a spinner (announced: not `inert`)."

  attr :pip, :boolean, default: false, doc: "The notification dot on the corner."
  attr :loading_label, :string, default: "Loading", doc: "Read by screen readers for the spinner."
  attr :class, :any, default: nil

  attr :rest, :global,
    include: ~w(href navigate patch method download target rel replace form name value)

  slot :inner_block

  def button(assigns) do
    shape =
      assigns.shape ||
        if(assigns.icon == true or (is_binary(assigns.icon) and assigns.inner_block == []),
          do: "square",
          else: "rounded"
        )

    assigns =
      assigns
      |> assign(:cls, button_classes(assigns, shape))
      |> assign(:link?, Enum.any?(@link_attrs, &Map.has_key?(assigns.rest, &1)))
      |> assign(:spinner_tone, @spinner_tone[assigns.variant] || "text-(--c-ink)")

    ~H"""
    <.link
      :if={@link?}
      data-part="button"
      class={[@cls, @loading && "text-transparent! pointer-events-none", @class]}
      aria-disabled={(@disabled || @loading) && "true"}
      aria-busy={@loading && "true"}
      {@rest}
    ><.button_content {assigns} /></.link>
    <button
      :if={!@link?}
      data-part="button"
      type={@type}
      class={[@cls, @loading && "text-transparent!", @class]}
      disabled={@disabled || @loading}
      aria-busy={@loading && "true"}
      {@rest}
    ><.button_content {assigns} /></button>
    """
  end

  defp button_classes(%{canvas: true} = a, _shape),
    do: canvas_classes(a.size, "default", a.icon == true)

  defp button_classes(a, shape),
    do: classes(a.color, a.variant, a.size, shape, loading: a.loading)

  # no whitespace around the content: a flex container would see it as an item and add a gap
  defp button_content(assigns) do
    ~H"""
    <.icon :if={is_binary(@icon)} name={@icon} />{render_slot(@inner_block)}<.icon
      :if={@trailing_icon}
      name={@trailing_icon}
    /><span
      :if={@loading}
      data-part="button-spinner"
      role="status"
      aria-label={@loading_label}
      class={[
        "absolute size-4 rounded-full border-[2.4px] border-[color-mix(in_oklab,currentColor_18%,transparent)] border-t-current animate-[lu-spin_.7s_linear_infinite]",
        @spinner_tone
      ]}
    ></span><span
      :if={@pip}
      data-part="button-pip"
      class="absolute top-1.5 right-[7px] size-[7px] rounded-full bg-neg shadow-[0_0_0_2px_var(--lu-bg-panel)]"
    ></span>
    """
  end

  # ---------------------------------------------------------------------------
  # canvas toolbar button (`lu-btn`) and the icon_button family

  @canvas_looks %{
    "default" =>
      "border-line-strong bg-panel text-ink shadow-xs hover:bg-hover disabled:shadow-none",
    "primary" =>
      "border-inverse bg-inverse text-on-inverse shadow-btn hover:bg-[color-mix(in_oklab,var(--lu-inverse)_86%,var(--lu-bg-page))] disabled:shadow-none",
    "accent" =>
      "border-accent-600 bg-accent-600 text-accent-foreground shadow-none hover:border-accent-700 hover:bg-accent-700",
    "soft" => "border-transparent bg-sunken shadow-none text-ink hover:bg-selected",
    "ghost" =>
      "border-transparent bg-transparent shadow-none text-ink-2 hover:bg-hover hover:text-ink",
    "danger-soft" => "border-transparent bg-neg-soft text-neg shadow-none hover:bg-neg-soft"
  }

  # height, width of the icon-only button, horizontal padding, font + gap + radius
  @canvas_sizes %{
    "sm" => {"h-[30px]", "w-[30px]", "px-2.5", "text-[13px] gap-1.5 rounded-[8px]"},
    "md" => {"h-9", "w-9", "px-3.5", "text-sm gap-2 rounded-md"},
    "lg" => {"h-11", "w-11", "px-[18px]", "text-[15px] gap-2 rounded-[12px]"}
  }

  @canvas_base "inline-flex items-center justify-center border font-medium leading-none whitespace-nowrap no-underline cursor-pointer " <>
                 "transition-[background,border-color,box-shadow,transform] duration-150 not-disabled:active:translate-y-[.5px] " <>
                 "focus-visible:outline-none focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] [&_svg]:size-4 " <>
                 "disabled:opacity-45 disabled:cursor-not-allowed disabled:translate-y-0"

  defp canvas_classes(size, look, icon?) do
    {h, w, px, rest} = @canvas_sizes[size] || @canvas_sizes["md"]
    [@canvas_base, @canvas_looks[look], h, rest, if(icon?, do: [w, "px-0"], else: px)]
  end

  @icon_variants %{
    "default" => "default",
    "primary" => "primary",
    "soft" => "soft",
    "ghost" => "ghost",
    "danger-soft" => "danger-soft",
    "accent" => "accent"
  }

  @kit_variants ~w(solid glow outline soft bordered flat glass ghost dim)

  attr :icon, :string, required: true, doc: "Icon name."
  attr :label, :string, required: true, doc: "The `aria-label` (and the only text of the button)."

  attr :variant, :string,
    default: "default",
    values: Map.keys(@icon_variants) ++ ["topbar", "go"] ++ @kit_variants,
    doc:
      "`topbar` is the 40x40 top bar button, `go` the round accent arrow button; `solid`, `glow`, " <>
        "`outline`, `bordered`, `flat`, `glass`, `dim` (and `soft`, `ghost`) with a `color` are the variants of `button/1`."

  attr :color, :string,
    default: nil,
    values: [nil | @colors],
    doc:
      "Given (or with `shape`, a `button/1` variant or size `xs`/`xl`), the button is `button/1`'s, icon only."

  attr :shape, :string,
    default: nil,
    values: [nil, "rounded", "pill", "square"],
    doc: "`rounded`, `pill` or `square` (the default of the `button/1` form)."

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "`xs` and `xl` are those of `button/1`."

  attr :dot, :boolean, default: false, doc: "A red dot for something new (`topbar` only)."
  attr :type, :string, default: "button"
  attr :class, :any, default: nil
  attr :rest, :global

  @doc """
  A button that holds only an icon. Always labelled with `aria-label`.

      <.icon_button icon="download" label="Baixar" />
      <.icon_button icon="trash" label="Excluir" variant="danger-soft" size="sm" />
      <.icon_button icon="bell" label="Notificações" variant="topbar" dot />
  """
  def icon_button(assigns) do
    if assigns.color != nil or assigns.shape != nil or assigns.size in ~w(xs xl) or
         assigns.variant in ~w(solid glow outline bordered flat glass dim),
       do: kit_icon_button(assigns),
       else: render_icon_button(assigns)
  end

  defp kit_icon_button(assigns) do
    assigns =
      assign(assigns,
        variant: if(assigns.variant in @kit_variants, do: assigns.variant, else: "solid")
      )

    ~H"""
    <.button
      icon={@icon}
      color={@color || "neutral"}
      variant={@variant}
      size={@size}
      shape={@shape || "square"}
      type={@type}
      class={@class}
      aria-label={@label}
      {@rest}
    />
    """
  end

  defp render_icon_button(%{variant: "topbar"} = assigns) do
    ~H"""
    <button
      data-part="icon-button"
      type={@type}
      class={[
        "relative grid size-10 cursor-pointer place-items-center rounded-[12px] border border-line bg-panel text-ink-2 hover:bg-hover",
        @dot &&
          "after:absolute after:top-2 after:right-[9px] after:size-[7px] after:rounded-full after:bg-neg after:shadow-[0_0_0_2px_var(--lu-bg-panel)] after:content-['']",
        @class
      ]}
      aria-label={@label}
      {@rest}
    ><.icon name={@icon} /></button>
    """
  end

  defp render_icon_button(%{variant: "go"} = assigns) do
    ~H"""
    <button
      data-part="icon-button"
      type={@type}
      class={[
        "inline-grid size-[30px] cursor-pointer place-items-center rounded-full border-0 bg-accent-500 text-white",
        "shadow-[0_4px_10px_color-mix(in_oklab,var(--lu-accent-500)_45%,transparent),inset_0_1px_0_rgba(255,255,255,.3)]",
        @class
      ]}
      aria-label={@label}
      {@rest}
    ><.icon name={@icon} size="md" /></button>
    """
  end

  defp render_icon_button(assigns) do
    assigns =
      assign(assigns, :cls, canvas_classes(assigns.size, @icon_variants[assigns.variant], true))

    ~H"""
    <button data-part="icon-button" type={@type} class={[@cls, @class]} aria-label={@label} {@rest}><.icon name={
      @icon
    } /></button>
    """
  end

  @doc """
  Joins buttons side by side into one segmented control (corners only at the ends).

      <.button_group>
        <.button variant="outline" size="sm">Day</.button>
        <.button variant="soft" size="sm">Month</.button>
      </.button_group>
  """
  attr :shape, :string, default: "rounded", values: ["rounded", "pill"]
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def button_group(assigns) do
    ~H"""
    <div
      data-part="button-group"
      role="group"
      class={[
        "inline-flex *:rounded-none [&>*+*]:-ml-px",
        @shape == "pill" && "*:first:rounded-l-full *:last:rounded-r-full",
        @shape != "pill" && "*:first:rounded-l-md *:last:rounded-r-md",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :count, :any, default: nil, doc: "The number in the square badge."
  attr :type, :string, default: "button"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "The top bar pill with a count badge (`New AI insights`)."
  def insight_button(assigns) do
    ~H"""
    <button
      data-part="insight-button"
      type={@type}
      class={[
        "inline-flex h-10 cursor-pointer items-center gap-2.5 rounded-[12px] border border-line bg-panel pr-3.5 pl-1.5 text-sm text-ink-2",
        @class
      ]}
      {@rest}
    ><span
      :if={@count}
      data-part="insight-button-count"
      class="grid size-7 place-items-center rounded-[8px] bg-sunken font-semibold text-ink"
    >{@count}</span>{render_slot(@inner_block)}</button>
    """
  end
end
