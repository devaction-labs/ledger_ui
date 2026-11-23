defmodule LedgerUI.Components.Card do
  @moduledoc """
  The card of the system, styled only with Tailwind utilities: one single surface (`bg-panel`,
  `rounded-lg` = 12px, 1px `border-line`, `shadow-xs`), no tray around it. The header (title in
  `text-sm font-semibold text-ink`, never upper-case) is separated from the body by a `border-b`,
  the footer by a `border-t`; the body has no border of its own. The surface clips its content
  (`overflow-hidden`), so a table in a `body_padded={false}` body touches the card and its bottom
  corners are cut by the card. `variant="tray"` (the default) and `variant="panel"` render the same
  surface (the tray of the older design is gone; both values are kept for compatibility). Other variants (`default`, `flat`, `bordered`, `outline`, `muted`, `soft`, `filled`, `solid`,
  `glow`, `gradient`, `gradient_outline`, plus the aliases `canvas` = `flat` and `page` = `default`)
  are plain surfaces; the surface `flat` is the sunken, borderless one (title in a `<b>`, content as given), tinted by
  `color` or `gradient`.

      <.card title="Revenue by plan">
        <:actions><.button size="sm" variant="outline" trailing_icon="huge-arrow-up-right">Plans</.button></:actions>
        ...
        <:footer>trailing 12 mo</:footer>
      </.card>

      <.card variant="solid" color="primary"><:title>Primary</:title>Faturamento</.card>
      <.card variant="gradient" gradient="sky-blue">...</.card>

  The title is `title="text"` or the `<:title>` slot (markup, `class` allowed); `<:title_extra>` goes
  beside it (a badge, a counter). With `canvas` the card is the bare surface and its content is the
  parts `card_header/1`, `card_body/1` and `card_footer/1`:

      <.card canvas>
        <.card_header>
          <.card_heading level={3}>Profile</.card_heading>
          <.card_actions>...</.card_actions>
        </.card_header>
        <.card_body>...</.card_body>
        <.card_footer>All changes saved</.card_footer>
      </.card>

  **Table flush with the card (body `p-0`):** on the default card (no `canvas`) pass
  `body_padded={false}`; the surface clips (`overflow-hidden`) so the table touches the card and the
  bottom corners are cut by it. No `canvas` is needed.

      <.card title="Orders" body_padded={false}>
        <.table id="orders" rows={@orders}>...</.table>
      </.card>

  `navigate`, `patch` or `href` make the whole card a link (a surface), a row that ends in an arrow.
  `size` (`xs`/`sm`/`lg`) and `padded={false}` act on the plain surfaces (`padded` is a no-op on the
  default card, which has no tray to drop: use `body_padded={false}` for an edge-to-edge body);
  `shape="xl"` raises the radius to `rounded-xl` (16px).

  ## Composed cards (`body`)

  `body` turns the card into a header / body / footer composition that is sized, tinted and
  rounded by the card itself. Without `body` nothing below applies and the markup is the one above.

      <.card variant="default" body="inset" size="md">
        <:title>Profile</:title>
        <:description>Manage your public details.</:description>
        <:actions><.button size="sm" variant="outline">Edit</.button></:actions>
        <.input name="name" />
        <:footer>All changes saved <.button size="sm">Save</.button></:footer>
      </.card>

    * `variant`: `default` (panel + hairline + shadow, a lighter panel with an inner highlight in dark),
      `muted`, `soft` and `filled` (translucent ink tints, so they adapt to the background under the
      card in light and dark), `outline` (border only, transparent). Any other variant renders as `default`.
    * `variant="flat"`: the panel as the card background, no visible border or shadow: a short list in
      a dashboard, only the panel. Before 0.8 a flat composed card rendered as `default`.
    * `<:meta>` is a secondary text in the title (13px, regular, muted), beside the heading text.
    * `body`: `seamless` (one surface, no divider), `divided` (hairline under a lightly tinted header),
      `separated` (tinted header and footer bands, body on the panel, dividers), and `inset` and
      `flush`, which since the refinement are the standard surface: header with `border-b`, footer with
      `border-t`, a body without border (the inner-panel "tray" look is gone; `flush` is kept as an
      alias of `inset`). `divided` no longer tints the header.
    * `size` (`xs`, `sm`, `md`, `lg`) sets, through the variables `--card-p` (horizontal padding),
      `--card-py`, `--card-r` (8/12/12/16px: the radius tokens md/lg/lg/xl), `--card-gap` and the type
      scale, the padding, radius, gap and typography.
      `card_bleed/1` and `card_table`-like content read `--card-p`.
    * `<:description>` goes under the title. `<:actions>` hang into the header padding: the buttons
      are vertically centred on the first line of the heading without making the header taller and
      their distance to the top and to the side edge is the same. Use `size="xs"` buttons in `xs`/`sm`
      cards and `size="sm"` buttons in `md`/`lg` cards (the sizes the hang is computed for);
      `<:actions placement="start">` puts them before the heading.
    * `<:bleed>` is content that fills the body edge to edge (an image) up to the rounded corners
      up to the card's rounded corners; the footer keeps its padding.
      `<.table bleed wrapper={false}>` inside a `card_body padded={false}` bleeds a table.
    * `canvas` with `body` keeps the parts (`card_header/1`, `card_body/1`, `card_footer/1`) as the content:
      the card applies the same treatments to them. `card_header` and `card_footer` take `padded={false}` to be
      sub-sections inside a body.

  The storage stat is plain composition (the figure and the bar are ordinary markup and `progress/1`):

      <.card body="seamless">
        <:title>Storage</:title>
        <:actions><.button size="sm" variant="ghost" icon="more-h" aria-label="More" /></:actions>
        <p class="m-0 font-display text-3xl font-semibold">32 GB <span class="text-sm font-normal text-muted">of 100 GB</span></p>
        <.progress value={32} class="mt-3" />
      </.card>
  """
  use LedgerUI.Component
  import LedgerUI.Components.Skeleton, only: [skeleton: 1, skeleton_group: 1]

  @composed_variants ~w(default flat muted soft outline filled)
  @tray_variants ~w(tray panel)
  @surface_variants ~w(default flat canvas page bordered outline muted soft filled solid glow gradient gradient_outline)
  @colors ~w(primary secondary info success warning error)

  @gradients %{
    "purple-indigo" => "[--g1:#8b5cf6] [--g2:#4f46e5]",
    "fuchsia-pink" => "[--g1:#d946ef] [--g2:#ec4899]",
    "amber-orange" => "[--g1:#f59e0b] [--g2:#f97316]",
    "sky-blue" => "[--g1:#0ea5e9] [--g2:#2563eb]",
    "green-fuchsia" => "[--g1:#22c55e] [--g2:#d946ef]"
  }

  @surface_base "flex gap-1.5 text-[13px] [&_b]:text-[14px]"

  # {background/box look, colour of the <span>s inside}
  @surfaces %{
    "default" => {"bg-panel border border-line shadow-xs", "[&_span]:text-muted"},
    "flat" => {"bg-sunken", "[&_span]:text-muted"},
    "canvas" => {"bg-sunken", "[&_span]:text-muted"},
    "page" => {"bg-panel border border-line shadow-xs", "[&_span]:text-muted"},
    "bordered" => {"bg-panel border border-line-strong", "[&_span]:text-muted"},
    "outline" => {"bg-transparent border border-line-strong", "[&_span]:text-muted"},
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

  attr :loading, :boolean,
    default: false,
    doc:
      "Swaps the body (the content, or the `canvas` parts) for skeleton lines while the data " <>
        "has not arrived (a first result, an `assign_async`). Header and footer stay. " <>
        "Not applied to link cards and plain surfaces."

  attr :loading_rows, :integer, default: 3, doc: "Skeleton lines shown by `loading`."

  attr :canvas, :boolean,
    default: false,
    doc: "The bare tray: the content is `card_header/1`, `card_body/1`, `card_footer/1`."

  attr :body, :string,
    default: nil,
    values: [nil | ~w(seamless divided separated inset flush)],
    doc:
      "Turns on the composed card (see the moduledoc): how header, body and footer relate. `nil` is the card of old."

  attr :divider, :string, default: "full", values: ~w(full inset), doc: "Reserved (see `body`)."
  attr :highlight, :boolean, default: true, doc: "Reserved (see `body`)."
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :href, :string, default: nil
  attr :arrow, :boolean, default: true, doc: "The chevron of a link card."
  attr :body_padded, :boolean, default: true, doc: "`false` drops the body panel's 16px padding."
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

  slot :meta,
    doc: "Composed cards (`body`): muted secondary text in the title (13px, regular)."

  slot :actions,
    doc: "At the end of the header (`placement=\"start\"`: before the heading, composed only)." do
    attr :placement, :string, values: ~w(start end)
  end

  slot :description, doc: "Composed cards (`body`): muted text under the title."

  slot :bleed,
    doc: "Composed cards (`body`): content that fills the body edge to edge (an image)."

  slot :footer

  def card(%{body: body, navigate: nil, patch: nil, href: nil} = assigns) when is_binary(body) do
    {from_rest, rest} = Map.pop(assigns.rest, :title)

    {text, title} =
      if is_binary(assigns.title), do: {assigns.title, []}, else: {from_rest, assigns.title}

    {lead, trail} = Enum.split_with(assigns.actions, &(&1[:placement] == "start"))
    variant = if assigns.variant in @composed_variants, do: assigns.variant, else: "default"

    assigns =
      assigns
      |> assign(:rest, rest)
      |> assign(:title, title)
      |> assign(:text, text)
      |> assign(:lead, lead)
      |> assign(:trail, trail)
      |> assign(:cv, variant)
      |> assign(:cls, composed_classes(assigns, variant))
      |> assign(:header?, text != nil or title != [] or assigns.actions != [])
      |> assign(:body?, not assigns.canvas and body_content?(assigns))

    ~H"""
    <section
      data-part="card"
      data-lu-variant={@cv}
      data-lu-body={@body}
      class={[@cls, @class]}
      {@rest}
    >
      <header
        :if={@header?}
        data-part="card-header"
        class="flex min-h-11 items-start gap-3 px-4 py-3"
      >
        <div
          :if={@lead != []}
          data-part="card-actions"
          class="flex shrink-0 items-center gap-1.5 [margin-block:calc((var(--card-line)-var(--card-btn))/2)] [margin-inline-start:calc(var(--card-py)-var(--card-p)-(var(--card-btn)-var(--card-line))/2)]"
        >
          {render_slot(@lead)}
        </div>
        <div :if={@text || @title != [] || @description != []} class="min-w-0 flex-1">
          <h3
            :if={@text || @title != []}
            data-part="card-heading"
            class="m-0 inline-flex items-center gap-2 font-display text-[length:var(--card-fs)] leading-(--card-line) font-semibold tracking-[-.01em] text-ink"
          >
            <span :for={t <- @title} data-part="card-title" class={t[:class]}>{render_slot(t)}</span>{@text}<span
              :if={@meta != []}
              data-part="card-meta"
              class="text-[13px] leading-none font-normal tracking-normal text-muted"
            >{render_slot(@meta)}</span>{render_slot(@title_extra)}
          </h3>
          <p
            :if={@description != []}
            data-part="card-subheading"
            class="m-0 text-[length:var(--card-dfs)] leading-[1.45] text-muted"
          >
            {render_slot(@description)}
          </p>
        </div>
        <div
          :if={@trail != []}
          data-part="card-actions"
          class="ml-auto flex shrink-0 items-center gap-1.5 [margin-block:calc((var(--card-line)-var(--card-btn))/2)] [margin-inline-end:calc(var(--card-py)-var(--card-p)-(var(--card-btn)-var(--card-line))/2)]"
        >
          {render_slot(@trail)}
        </div>
      </header>
      <div
        :if={@bleed != []}
        data-part="card-bleed"
        class="overflow-hidden [&_img]:block [&_img]:w-full"
      >
        {render_slot(@bleed)}
      </div>
      <div
        :if={@body?}
        data-part="card-body"
        class={[
          "relative min-w-0 flex-1 bg-panel",
          if(@body_padded, do: "p-4", else: "p-0"),
          @body_class
        ]}
      >
        <.card_content loading={@loading} rows={@loading_rows}>
          {render_slot(@inner_block)}
        </.card_content>
      </div>
      <%= if @canvas do %>
        <.card_content loading={@loading} rows={@loading_rows}>
          {render_slot(@inner_block)}
        </.card_content>
      <% end %>
      <footer
        :if={@footer != []}
        data-part="card-footer"
        class="flex items-center justify-between gap-2 px-4 py-3 text-[13px] text-muted"
      >
        {render_slot(@footer)}
      </footer>
    </section>
    """
  end

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
      |> assign(:tray_variant, if(assigns.variant == "panel", do: "panel", else: "tray"))
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
        class={[
          "flex min-h-12 items-center gap-2.5 px-4 py-3",
          !@raw? && "border-b border-line"
        ]}
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
          "relative min-w-0 flex-1 bg-panel",
          if(@body_padded, do: "p-4", else: "p-0"),
          @body_class
        ]}
      >
        <.card_content loading={@loading} rows={@loading_rows}>
          {render_slot(@inner_block)}
        </.card_content>
      </div>
      <%= if @raw? do %>
        <.card_content loading={@loading} rows={@loading_rows}>
          {render_slot(@inner_block)}
        </.card_content>
      <% end %>
      <footer
        :if={@footer != []}
        data-part="card-footer"
        class="flex items-center gap-2 border-t border-line px-4 py-3 text-[13px] text-muted"
      >
        {render_slot(@footer)}
      </footer>
    </section>
    """
  end

  attr :loading, :boolean, required: true
  attr :rows, :integer, required: true
  slot :inner_block

  # the body of the card: its content, or skeleton lines while `loading`
  defp card_content(%{loading: true} = assigns) do
    ~H"""
    <.skeleton_group class="flex flex-col gap-2.5">
      <.skeleton :for={i <- 1..max(@rows, 1)//1} class={["h-3", skeleton_width(i)]} />
    </.skeleton_group>
    """
  end

  defp card_content(assigns), do: ~H"{render_slot(@inner_block)}"

  defp skeleton_width(i), do: Enum.at(~w(w-full w-5/6 w-2/3 w-3/4), rem(i - 1, 4))

  # -- the composed card (`body`) -------------------------------------------------------------------
  # Everything is a Tailwind class written out in full (the scanner reads this file). The card sets
  # the variables of its size; the treatments are descendant selectors of the root, so the parts
  # (`card_header/1`, `card_body/1`, `card_footer/1`) and the slots look the same, and the parts keep
  # their own classes when there is no `body`.
  @composed_base "group/card relative flex min-w-0 flex-col rounded-(--card-r) text-ink [--card-band:color-mix(in_oklab,var(--lu-ink)_4%,transparent)] dark:[--card-band:color-mix(in_oklab,var(--lu-ink)_6.5%,transparent)] [--card-panel:var(--lu-bg-panel)] dark:[--card-panel:color-mix(in_oklab,var(--lu-bg-panel),white_3.5%)]"

  @composed_sizes %{
    "xs" =>
      "[--card-p:12px] [--card-py:10px] [--card-r:8px] [--card-gap:3px] [--card-line:16px] [--card-btn:26px] [--card-fs:13px] [--card-dfs:12px] text-xs",
    "sm" =>
      "[--card-p:14px] [--card-py:12px] [--card-r:12px] [--card-gap:4px] [--card-line:18px] [--card-btn:26px] [--card-fs:14px] [--card-dfs:12.5px] text-[13px]",
    "md" =>
      "[--card-p:16px] [--card-py:14px] [--card-r:12px] [--card-gap:6px] [--card-line:20px] [--card-btn:30px] [--card-fs:15px] [--card-dfs:13px] text-sm",
    "lg" =>
      "[--card-p:24px] [--card-py:20px] [--card-r:16px] [--card-gap:8px] [--card-line:24px] [--card-btn:30px] [--card-fs:17px] [--card-dfs:14px] text-sm"
  }

  @composed_variant_classes %{
    "default" => "border border-line bg-(--card-panel) shadow-xs",
    "muted" => "border border-line bg-(--card-band)",
    "soft" =>
      "border border-[color-mix(in_oklab,var(--lu-ink)_6%,transparent)] bg-[color-mix(in_oklab,var(--card-band)_55%,transparent)]",
    "outline" => "border border-line-strong bg-transparent",
    "flat" => "border border-transparent bg-(--card-panel) shadow-none",
    "filled" =>
      "border border-transparent bg-[color-mix(in_oklab,var(--lu-ink)_7%,transparent)] dark:bg-[color-mix(in_oklab,var(--lu-ink)_9.5%,transparent)]"
  }

  # what every body mode shares: the paddings follow the size
  @composed_common "[&>[data-part=card-header]]:min-h-0 [&>[data-part=card-body].p-4]:p-(--card-p) [&>[data-part=card-bleed]]:overflow-hidden"

  # the paddings of header and footer follow the size
  @composed_pad "[&>[data-part=card-header]]:px-(--card-p) [&>[data-part=card-header]]:py-(--card-py) [&>[data-part=card-footer]]:px-(--card-p) [&>[data-part=card-footer]]:py-(--card-py) [&>[data-part=card-footer]]:text-[length:var(--card-dfs)]"

  # the standard surface (`inset`/`flush`): header border-b, footer border-t, a bare body
  @composed_surface "[&>[data-part=card-header]]:border-b [&>[data-part=card-header]]:border-line [&>[data-part=card-footer]]:border-t [&>[data-part=card-footer]]:border-line [&>[data-part=card-body]]:rounded-none [&>[data-part=card-body]]:border-0 [&>[data-part=card-body]]:bg-(--card-panel) [&>[data-part=card-body]:last-child]:rounded-b-[calc(var(--card-r)-1px)] [&>[data-part=card-header]:first-child]:rounded-t-[calc(var(--card-r)-1px)] [&>[data-part=card-bleed]:first-child]:rounded-t-[calc(var(--card-r)-1px)] [&>[data-part=card-bleed]:last-child]:rounded-b-[calc(var(--card-r)-1px)]"

  @composed_bodies %{
    "seamless" =>
      "[&>[data-part=card-header]]:pb-0 [&>[data-part=card-body]]:rounded-none [&>[data-part=card-body]]:border-0 [&>[data-part=card-body]]:bg-transparent [&>[data-part=card-body].p-4]:pt-(--card-py) [&>[data-part=card-header]+[data-part=card-bleed]]:mt-(--card-py) [&>[data-part=card-bleed]:first-child]:rounded-t-[calc(var(--card-r)-1px)] [&>[data-part=card-bleed]:last-child]:rounded-b-[calc(var(--card-r)-1px)]",
    "divided" =>
      "[&>[data-part=card-header]]:rounded-t-[calc(var(--card-r)-1px)] [&>[data-part=card-header]]:border-b [&>[data-part=card-header]]:border-line [&>[data-part=card-footer]]:border-t [&>[data-part=card-footer]]:border-line [&>[data-part=card-body]]:rounded-none [&>[data-part=card-body]]:border-0 [&>[data-part=card-body]]:bg-transparent [&>[data-part=card-bleed]:first-child]:rounded-t-[calc(var(--card-r)-1px)] [&>[data-part=card-bleed]:last-child]:rounded-b-[calc(var(--card-r)-1px)]",
    "separated" =>
      "[&>[data-part=card-header]]:rounded-t-[calc(var(--card-r)-1px)] [&>[data-part=card-header]]:border-b [&>[data-part=card-header]]:border-line [&>[data-part=card-header]]:bg-(--card-band) [&>[data-part=card-footer]]:rounded-b-[calc(var(--card-r)-1px)] [&>[data-part=card-footer]]:border-t [&>[data-part=card-footer]]:border-line [&>[data-part=card-footer]]:bg-(--card-band) [&>[data-part=card-body]]:rounded-none [&>[data-part=card-body]]:border-0 [&>[data-part=card-body]]:bg-(--card-panel) [&>[data-part=card-bleed]:first-child]:rounded-t-[calc(var(--card-r)-1px)] [&>[data-part=card-bleed]:last-child]:rounded-b-[calc(var(--card-r)-1px)]",
    "inset" => @composed_surface,
    "flush" => @composed_surface
  }

  defp composed_classes(a, variant) do
    [
      @composed_base,
      @composed_sizes[a.size],
      @composed_variant_classes[variant],
      @composed_common,
      @composed_pad,
      @composed_bodies[a.body]
    ]
  end

  # the implicit inner block is never `[]`: a card with only a `:bleed` has a whitespace body
  defp body_content?(%{inner_block: []}), do: false
  defp body_content?(%{bleed: []}), do: true
  defp body_content?(assigns), do: render_inner(assigns) != ""

  defp render_inner(assigns) do
    assigns.__changed__
    |> Phoenix.Component.__render_slot__(assigns.inner_block, nil)
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> String.trim()
  end

  defp surface?(variant), do: variant in @surface_variants

  defp tray_classes(a) do
    [
      "flex min-w-0 flex-col overflow-hidden border border-line bg-panel shadow-xs",
      if(a.shape == "xl", do: "rounded-xl", else: "rounded-lg")
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
      if(a.shape == "xl", do: "rounded-xl", else: "rounded-lg"),
      if(a.padded, do: @sizes[a.size], else: "p-0"),
      if(a.size == "md", do: "min-h-[92px]", else: "min-h-0")
    ]
  end

  defp heading_classes("base"),
    do: "m-0 inline-flex items-center gap-2 font-display text-sm leading-5 font-semibold text-ink"

  defp heading_classes("lg"),
    do:
      "m-0 inline-flex items-center gap-2 font-display text-[15px] leading-[22px] font-semibold tracking-[-.01em] text-ink"

  defp heading_classes("xl"),
    do:
      "m-0 inline-flex items-center gap-2 font-display text-[18px] leading-[26px] font-semibold tracking-[-.015em] text-ink"

  # ---------------------------------------------------------------------------
  # parts, for `<.card canvas>`

  attr :size, :string, default: "md", values: ~w(xs sm md lg xl), doc: "`lg` and `xl` are taller."

  attr :padded, :boolean,
    default: true,
    doc: "`false` drops the padding (a sub-section inside a body)."

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def card_header(assigns) do
    ~H"""
    <header
      data-part="card-header"
      class={[
        "flex items-center gap-2.5",
        !@padded && "p-0",
        @padded && @size in ~w(lg) && "min-h-[52px] py-3 pr-3.5 pl-[18px]",
        @padded && @size == "xl" && "min-h-[60px] py-4 pr-[18px] pl-[22px]",
        @padded && @size not in ~w(lg xl) && "min-h-12 px-4 py-3",
        @padded &&
          "group-data-[lu-variant=tray]/card:border-b group-data-[lu-variant=tray]/card:border-line group-data-[lu-variant=panel]/card:border-b group-data-[lu-variant=panel]/card:border-line",
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

  attr :padded, :boolean, default: true, doc: "`false` drops the 16px padding (tables, media)."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def card_body(assigns) do
    ~H"""
    <div
      data-part="card-body"
      class={[
        "relative min-w-0 flex-1 bg-panel",
        if(@padded, do: "p-4", else: "p-0"),
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

  attr :padded, :boolean,
    default: true,
    doc: "`false` drops the padding (a sub-section inside a body)."

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
        "flex items-center gap-2",
        if(@padded,
          do:
            "px-4 py-3 group-data-[lu-variant=tray]/card:border-t group-data-[lu-variant=tray]/card:border-line group-data-[lu-variant=panel]/card:border-t group-data-[lu-variant=panel]/card:border-line",
          else: "p-0"
        ),
        "text-[13px] text-muted",
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
