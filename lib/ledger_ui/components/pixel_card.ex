defmodule LedgerUI.Components.PixelCard do
  @moduledoc """
  The pixel card: a card to choose from (a model, a module, an integration) that, on hover or
  keyboard focus, lights up a matrix of pixels in its top right corner, in the card's colour.

      <.pixel_card navigate={~p"/novo/loja"} color="red" icon="huge-shopping-cart-01"
        title="Loja" description="PDV, estoque, NFC-e" />
      <.pixel_card phx-click="pick" phx-value-id="agenda" color="ink" icon="huge-calendar-03"
        title="Agenda" description="Horários e lembretes" />

  With `href`, `navigate` or `patch` the card is a link; with none it is a
  `<button type="button">` that takes `phx-click` and the other events through `rest`. The
  keyboard focus does what the hover does: the pixels, the stronger outline and the arrow
  (`arrow={false}` leaves the arrow out).

  `color` takes a palette name (`red`, `rose`, `green`, `teal`, `blue`, `violet`, `amber`,
  `ink`); without it the card takes the accent. Any other colour goes through the `--px`
  custom property (`style="--px: #f97316"`).

  The pixel matrix is drawn by the `LedgerUI.PixelCard` hook (three random opacity patterns that
  swap in steps); its classes come from the server (`data-lu-grid-class`, `data-lu-cell-class`), since
  the stylesheet only knows the utilities written in this module. The hook needs a DOM id: pass `id`,
  or it is derived from the title. Styled only with Tailwind utilities.
  """
  use LedgerUI.Component

  @colors ~w(red rose green teal blue violet amber ink)

  # `--px` is the colour of the card.
  @color_vars %{
    "red" => "[--px:#e5484d]",
    "rose" => "[--px:#e5578a]",
    "green" => "[--px:#2f9e5a]",
    "teal" => "[--px:var(--lu-accent-500)]",
    "blue" => "[--px:#3b6fe0]",
    "violet" => "[--px:var(--lu-violet)]",
    "amber" => "[--px:#e0a12f]",
    "ink" => "[--px:var(--lu-ink)]"
  }

  # `group` carries the hover and the keyboard focus to the matrix and to the arrow.
  @base "group relative flex min-h-[120px] cursor-pointer flex-col gap-1 overflow-hidden rounded-[16px] border border-line bg-panel p-4 text-left font-[inherit] text-ink no-underline transition-[border-color,box-shadow] duration-200 hover:border-[color-mix(in_oklab,var(--px)_55%,var(--lu-line))] hover:shadow-[0_0_0_1px_color-mix(in_oklab,var(--px)_30%,transparent)] focus-visible:border-[color-mix(in_oklab,var(--px)_55%,var(--lu-line))] focus-visible:shadow-[0_0_0_1px_color-mix(in_oklab,var(--px)_30%,transparent)] focus-visible:outline-none"

  @grid "pointer-events-none absolute top-0 right-0 grid h-[120px] w-[168px] grid-cols-[repeat(28,6px)] auto-rows-[6px] opacity-0 transition-opacity duration-[250ms] [mask:radial-gradient(circle_at_100%_0,#000_10%,transparent_75%)] group-hover:opacity-100 group-focus-visible:opacity-100"
  @cell "size-[2.6px] rounded-[.6px] bg-(--px) animate-[lu-tw_.9s_steps(1)_infinite]"

  attr :id, :string, default: nil, doc: "The hook's DOM id; derived from the title when omitted."
  attr :title, :string, required: true, doc: "The bold name of the option."
  attr :description, :string, default: nil, doc: "The muted line under the name."
  attr :icon, :string, default: nil, doc: "An icon, drawn white in a round chip of the colour."
  attr :color, :string, default: nil, values: [nil | @colors]
  attr :arrow, :boolean, default: true

  attr :loop, :boolean,
    default: false,
    doc: "Plays the hover (border, pixels, arrow) in a loop, as the canvas demo does."

  attr :class, :any, default: nil

  attr :rest, :global, include: ~w(href navigate patch method disabled)

  slot :inner_block, doc: "Extra content under the description."

  def pixel_card(assigns) do
    link? = Enum.any?([:href, :navigate, :patch], &Map.has_key?(assigns.rest, &1))

    assigns =
      assigns
      |> assign(
        :classes,
        cx([
          @base,
          @color_vars[assigns.color || "teal"],
          assigns.loop && "animate-[lu-pxbd_4s_ease_infinite]",
          assigns.class
        ])
      )
      |> assign(:grid_class, cx([@grid, assigns.loop && "animate-[lu-pxon_4s_ease_infinite]"]))
      |> assign(:cell_class, @cell)
      |> assign(:dom_id, assigns.id || "px-" <> slug(assigns.title))
      |> assign(:link?, link?)

    ~H"""
    <.link
      :if={@link?}
      id={@dom_id}
      data-part="pixel-card"
      class={@classes}
      phx-hook="LedgerUI.PixelCard"
      data-lu-grid-class={@grid_class}
      data-lu-cell-class={@cell_class}
      {@rest}
    >
      <.px_body
        icon={@icon}
        title={@title}
        description={@description}
        arrow={@arrow}
        ink={@color == "ink"}
        loop={@loop}
      >
        {render_slot(@inner_block)}
      </.px_body>
    </.link>
    <button
      :if={!@link?}
      id={@dom_id}
      data-part="pixel-card"
      type="button"
      class={@classes}
      phx-hook="LedgerUI.PixelCard"
      data-lu-grid-class={@grid_class}
      data-lu-cell-class={@cell_class}
      {@rest}
    >
      <.px_body
        icon={@icon}
        title={@title}
        description={@description}
        arrow={@arrow}
        ink={@color == "ink"}
        loop={@loop}
      >
        {render_slot(@inner_block)}
      </.px_body>
    </button>
    """
  end

  attr :icon, :string, default: nil
  attr :title, :string, required: true
  attr :description, :string, default: nil
  attr :arrow, :boolean, required: true
  attr :ink, :boolean, default: false
  attr :loop, :boolean, default: false
  slot :inner_block

  defp px_body(assigns) do
    ~H"""
    <span
      :if={@icon}
      data-part="pixel-card-icon"
      class={[
        "relative mb-2.5 grid size-[34px] place-items-center rounded-full bg-(--px)",
        if(@ink, do: "text-page", else: "text-white")
      ]}
    ><.icon name={@icon} size="md" /></span><b
      data-part="pixel-card-title"
      class="relative text-[15px] font-semibold"
    >{@title}</b><span
      :if={@description}
      data-part="pixel-card-description"
      class="relative text-[13px] text-muted"
    >{@description}</span>{render_slot(@inner_block)}<span
      :if={@arrow}
      data-part="pixel-card-arrow"
      class={[
        "absolute right-3.5 bottom-3.5 -translate-x-1 text-(--px) opacity-0 transition-all duration-200 ease-[ease] group-hover:translate-x-0 group-hover:opacity-100 group-focus-visible:translate-x-0 group-focus-visible:opacity-100",
        @loop && "animate-[lu-pxarr_4s_ease_infinite]"
      ]}
    ><.icon name="arrow-right" size="md" /></span>
    """
  end

  defp slug(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
  end
end
