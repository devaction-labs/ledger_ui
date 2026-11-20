defmodule LedgerUI.Components.Card do
  @moduledoc """
  The card of the system, styled only with Tailwind utilities: a tray (`bg-tray`, radius 20, 6px
  border) whose upper-case title hugs a panel (`bg-panel`, radius 14). `variant="flat"` drops the
  tray. Other variants (`default`, `bordered`, `outline`, `muted`, `soft`, `filled`, `solid`, `glow`,
  `gradient`, `gradient_outline`) are plain surfaces (title in a `<b>`, content as given), tinted by
  `color` or `gradient`.

      <.card title="Revenue by plan">
        <:actions><.button size="sm" variant="outline" trailing_icon="huge-arrow-up-right">Plans</.button></:actions>
        ...
        <:footer>trailing 12 mo</:footer>
      </.card>

      <.card variant="solid" color="primary"><:title>Primary</:title>Faturamento</.card>
      <.card variant="gradient" gradient="sky-blue">...</.card>

  The title is `title="text"` or the `<:title>` slot (markup, `class` allowed); `<:title_extra>` goes
  beside it (a badge, a counter). With `canvas` the card is the bare tray and its content is the
  parts `card_header/1`, `card_body/1` and `card_footer/1`:

      <.card canvas>
        <.card_header>
          <.card_heading level={3}>Profile</.card_heading>
          <.card_actions>...</.card_actions>
        </.card_header>
        <.card_body>...</.card_body>
        <.card_footer>All changes saved</.card_footer>
      </.card>

  `navigate`, `patch` or `href` make the whole card a link (a surface), a row that ends in an arrow.
  `size` (`xs`/`sm`/`lg`), `shape="xl"` and `padded={false}` act on the surfaces and the tray root.
  """
  use LedgerUI.Component

  @tray_variants ~w(tray flat)
  @surface_variants ~w(default bordered outline muted soft filled solid glow gradient gradient_outline)
  @colors ~w(primary secondary info success warning error)

  @gradients %{
    "purple-indigo" => "[--g1:#8b5cf6] [--g2:#4f46e5]",
    "fuchsia-pink" => "[--g1:#d946ef] [--g2:#ec4899]",
    "amber-orange" => "[--g1:#f59e0b] [--g2:#f97316]",
    "sky-blue" => "[--g1:#0ea5e9] [--g2:#2563eb]",
    "green-fuchsia" => "[--g1:#22c55e] [--g2:#d946ef]"
  }

  @surface_base "flex gap-1.5 text-[13px] [&_b]:text-sm"

  # {background/box look, colour of the <span>s inside}
  @surfaces %{
    "default" =>
      {"bg-panel shadow-[0_0_0_1px_var(--lu-line),var(--lu-shadow-sm)]", "[&_span]:text-muted"},
    "bordered" => {"bg-panel shadow-[0_0_0_1px_var(--lu-line-strong)]", "[&_span]:text-muted"},
    "outline" =>
      {"bg-transparent shadow-[0_0_0_1px_var(--lu-line-strong)]", "[&_span]:text-muted"},
    "muted" => {"bg-tray", "[&_span]:text-muted"},
    "soft" => {"bg-(--c-soft)", "[&_span]:text-(--c-ink)"},
    "filled" =>
      {"bg-(--c-soft) shadow-[inset_0_0_0_1px_color-mix(in_oklab,var(--c)_30%,transparent)]",
       "[&_span]:text-muted"},
    "solid" =>
      {"bg-(--c) text-(--c-on)", "[&_span]:text-[color-mix(in_srgb,var(--c-on)_75%,transparent)]"},
    "glow" =>
      {"bg-panel shadow-[0_0_0_1px_color-mix(in_oklab,var(--c)_40%,transparent),0_10px_30px_-10px_var(--c)]",
       "[&_span]:text-muted"},
    "gradient" =>
      {"bg-[linear-gradient(135deg,var(--g1),var(--g2))] text-white", "[&_span]:text-white/80"},
    "gradient_outline" =>
      {"border-[1.5px] border-transparent [background:linear-gradient(var(--lu-bg-panel),var(--lu-bg-panel))_padding-box,linear-gradient(135deg,var(--g1),var(--g2))_border-box]",
       "[&_span]:text-muted"}
  }

  @sizes %{"xs" => "p-2", "sm" => "p-[11px]", "md" => "p-3.5", "lg" => "p-5"}

  attr :variant, :string, default: "tray", values: @tray_variants ++ @surface_variants
  attr :size, :string, default: "md", values: ~w(xs sm md lg), doc: "Padding of a surface."

  attr :color, :string,
    default: "primary",
    values: [nil | @colors],
    doc: "Tint of `soft`, `filled`, `solid`, `glow`."

  attr :gradient, :string, default: "purple-indigo", values: [nil | Map.keys(@gradients)]
  attr :shape, :string, default: "rounded", values: ~w(rounded xl)
  attr :padded, :boolean, default: true

  attr :canvas, :boolean,
    default: false,
    doc: "The bare tray: the content is `card_header/1`, `card_body/1`, `card_footer/1`."

  attr :body, :string,
    default: "seamless",
    values: ~w(seamless divided separated inset flush),
    doc: "Reserved: the design has no styles for the body modes yet."

  attr :divider, :string, default: "full", values: ~w(full inset), doc: "Reserved (see `body`)."
  attr :highlight, :boolean, default: true, doc: "Reserved (see `body`)."
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :href, :string, default: nil
  attr :arrow, :boolean, default: true, doc: "The chevron of a link card."
  attr :body_class, :any, default: nil, doc: "Classes of the body panel (the tray)."
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(target rel download replace method)

  slot :inner_block

  # `title="text"` is the global HTML attribute `title`: it cannot be declared as an attr next to the
  # `title` slot, so it is read from `rest` (and not rendered as a tooltip).
  slot :title, doc: "The heading as markup (`title=\"text\"` is the same as text)." do
    attr :class, :any
  end

  slot :title_extra, doc: "Beside the title (a badge, a counter)."
  slot :actions, doc: "At the end of the header."
  slot :footer

  def card(assigns) do
    # `title="text"` is left in the assigns (and in `rest`) as a string; the slot is a list
    {from_rest, rest} = Map.pop(assigns.rest, :title)

    {text, title} =
      if is_binary(assigns.title), do: {assigns.title, []}, else: {from_rest, assigns.title}

    link? = Enum.any?([assigns.navigate, assigns.patch, assigns.href])
    surface? = link? or assigns.variant in @surface_variants

    assigns =
      assigns
      |> assign(:rest, rest)
      |> assign(:title, title)
      |> assign(:text, text)
      |> assign(:link?, link?)
      |> assign(:tray_variant, if(assigns.variant == "flat", do: "flat", else: "tray"))
      |> assign(
        :cls,
        if(surface?, do: surface_classes(assigns, link?), else: tray_classes(assigns))
      )

    assigns =
      assign(
        assigns,
        :header?,
        assigns.text != nil or assigns.title != [] or assigns.actions != []
      )

    assigns = assign(assigns, :raw?, assigns.canvas and not assigns.header?)

    ~H"""
    <.link
      :if={@link?}
      data-part="card"
      class={[@cls, @class]}
      navigate={@navigate}
      patch={@patch}
      href={@href}
      {@rest}
    >
      <b :for={t <- @title} data-part="card-title" class={t[:class]}>{render_slot(t)}</b>{@text &&
        @text}{render_slot(@inner_block)}<.icon
        :if={@arrow}
        name="chevron-right"
        size="md"
        class="text-muted"
      />
    </.link>
    <div :if={!@link? and surface?(@variant)} data-part="card" class={[@cls, @class]} {@rest}>
      <b :for={t <- @title} data-part="card-title" class={t[:class]}>{render_slot(t)}</b><b
        :if={@text}
        data-part="card-title"
      >{@text}</b>{render_slot(@inner_block)}
    </div>
    <section
      :if={!@link? and !surface?(@variant)}
      data-part="card"
      data-lu-variant={@tray_variant}
      class={["group/card", @cls, @class]}
      {@rest}
    >
      <header
        :if={@header?}
        data-part="card-header"
        class="flex min-h-11 items-center gap-2.5 pt-2 pr-2.5 pb-2.5 pl-3.5"
      >
        <h3 data-part="card-heading" class={heading_classes("base")}>
          <span :for={t <- @title} data-part="card-title" class={t[:class]}>{render_slot(t)}</span>{@text}{render_slot(
            @title_extra
          )}
        </h3>
        <div :if={@actions != []} data-part="card-actions" class="ml-auto flex items-center gap-1.5">
          {render_slot(@actions)}
        </div>
      </header>
      <div
        :if={!@raw?}
        data-part="card-body"
        class={[
          "relative min-w-0 flex-1 bg-panel p-4",
          @variant == "flat" && "rounded-xl",
          @variant != "flat" && "rounded-lg border border-line",
          @body_class
        ]}
      >
        {render_slot(@inner_block)}
      </div>
      <%= if @raw? do %>
        {render_slot(@inner_block)}
      <% end %>
      <footer
        :if={@footer != []}
        data-part="card-footer"
        class="flex items-center gap-2 pt-2.5 pr-3 pb-1.5 pl-3.5 text-[13px] text-muted"
      >
        {render_slot(@footer)}
      </footer>
    </section>
    """
  end

  defp surface?(variant), do: variant in @surface_variants

  defp tray_classes(a) do
    [
      "flex min-w-0 flex-col border border-line",
      a.variant == "flat" && "bg-panel",
      a.variant != "flat" && "bg-tray",
      if(a.shape == "xl", do: "rounded-[22px]", else: "rounded-xl"),
      if(a.padded, do: (a.variant == "flat" && "p-0") || "p-1.5", else: "p-0")
    ]
  end

  defp surface_classes(a, link?) do
    variant = if a.variant in @surface_variants, do: a.variant, else: "default"
    {look, spans} = @surfaces[variant]

    [
      @surface_base,
      if(link?, do: "flex-row items-center gap-2.5", else: "flex-col"),
      look,
      spans,
      a.color && LedgerUI.Color.vars(a.color),
      a.gradient && @gradients[a.gradient],
      if(a.shape == "xl", do: "rounded-[22px]", else: "rounded-[16px]"),
      if(a.padded, do: @sizes[a.size], else: "p-0"),
      if(a.size == "md", do: "min-h-[92px]", else: "min-h-0")
    ]
  end

  defp heading_classes("base"),
    do:
      "m-0 inline-flex items-center gap-2 font-display text-xs leading-4 font-medium tracking-[.08em] text-ink-2 uppercase"

  defp heading_classes("lg"),
    do:
      "m-0 inline-flex items-center gap-2 font-display text-[15px] leading-[22px] font-semibold tracking-[-.01em] text-ink"

  defp heading_classes("xl"),
    do:
      "m-0 inline-flex items-center gap-2 font-display text-[18px] leading-[26px] font-semibold tracking-[-.015em] text-ink"

  # ---------------------------------------------------------------------------
  # parts, for `<.card canvas>`

  attr :size, :string, default: "md", values: ~w(xs sm md lg xl), doc: "`lg` and `xl` are taller."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def card_header(assigns) do
    ~H"""
    <header
      data-part="card-header"
      class={[
        "flex items-center gap-2.5",
        @size in ~w(lg) && "min-h-[52px] py-3 pr-3.5 pl-[18px]",
        @size == "xl" && "min-h-[60px] py-4 pr-[18px] pl-[22px]",
        @size not in ~w(lg xl) && "min-h-11 pt-2 pr-2.5 pb-2.5 pl-3.5",
        @class
      ]}
      {@rest}
    >
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
    assigns = assign(assigns, :cls, heading_classes(assigns.size))

    ~H"""
    <.dynamic_tag tag_name={"h#{@level}"} data-part="card-heading" class={[@cls, @class]} {@rest}>
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def card_subheading(assigns) do
    ~H"""
    <p
      data-part="card-subheading"
      class={["m-0 text-[13px] leading-[18px] text-muted", @class]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </p>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def card_actions(assigns) do
    ~H"""
    <div data-part="card-actions" class={["ml-auto flex items-center gap-1.5", @class]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def card_body(assigns) do
    ~H"""
    <div
      data-part="card-body"
      class={[
        "relative min-w-0 flex-1 bg-panel p-4",
        "group-data-[lu-variant=tray]/card:rounded-lg group-data-[lu-variant=tray]/card:border group-data-[lu-variant=tray]/card:border-line",
        "group-data-[lu-variant=flat]/card:rounded-xl",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @aligns %{
    "start" => "justify-start",
    "center" => "justify-center",
    "end" => "justify-end",
    "between" => "justify-between"
  }

  attr :align, :string, default: nil, values: [nil, "start", "center", "end", "between"]

  attr :size, :string,
    default: nil,
    values: [nil, "xs", "sm", "md", "lg"],
    doc: "Reserved: no styles in the design."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def card_footer(assigns) do
    assigns = assign(assigns, :align_cls, @aligns[assigns.align])

    ~H"""
    <div
      data-part="card-footer"
      class={[
        "flex items-center gap-2 pt-2.5 pr-3 pb-1.5 pl-3.5 text-[13px] text-muted",
        @align_cls,
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "Content that bleeds to the card's edges (negative margin of the padding `--card-p`, 16px)."
  def card_bleed(assigns) do
    ~H"""
    <div
      data-part="card-bleed"
      class={["m-[calc(var(--card-p,16px)*-1)] overflow-hidden rounded-[inherit]", @class]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
