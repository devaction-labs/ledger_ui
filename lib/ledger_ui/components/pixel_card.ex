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

  The pixel matrix is drawn by the `LedgerUI.PixelCard` hook (three random patterns that swap
  every 0.3s, from `lu-px` in the stylesheet). The hook needs a DOM id: pass `id`, or it is
  derived from the title.
  """
  use LedgerUI.Component

  @colors ~w(red rose green teal blue violet amber ink)

  attr :id, :string, default: nil, doc: "The hook's DOM id; derived from the title when omitted."
  attr :title, :string, required: true, doc: "The bold name of the option."
  attr :description, :string, default: nil, doc: "The muted line under the name."
  attr :icon, :string, default: nil, doc: "An icon, drawn white in a round chip of the colour."
  attr :color, :string, default: nil, values: [nil | @colors]
  attr :arrow, :boolean, default: true
  attr :class, :any, default: nil

  attr :rest, :global, include: ~w(href navigate patch method disabled)

  slot :inner_block, doc: "Extra content under the description."

  def pixel_card(assigns) do
    link? = Enum.any?([:href, :navigate, :patch], &Map.has_key?(assigns.rest, &1))

    assigns =
      assigns
      |> assign(:classes, cx(["lu-px", assigns.color && "px-#{assigns.color}", assigns.class]))
      |> assign(:dom_id, assigns.id || "px-" <> slug(assigns.title))
      |> assign(:link?, link?)

    ~H"""
    <.link
      :if={@link?}
      id={@dom_id}
      data-part="pixel-card"
      class={@classes}
      phx-hook="LedgerUI.PixelCard"
      {@rest}
    >
      <.px_body icon={@icon} title={@title} description={@description} arrow={@arrow}>
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
      {@rest}
    >
      <.px_body icon={@icon} title={@title} description={@description} arrow={@arrow}>
        {render_slot(@inner_block)}
      </.px_body>
    </button>
    """
  end

  attr :icon, :string, default: nil
  attr :title, :string, required: true
  attr :description, :string, default: nil
  attr :arrow, :boolean, required: true
  slot :inner_block

  defp px_body(assigns) do
    ~H"""
    <span :if={@icon} class="ico"><.icon name={@icon} size="md" /></span><b>{@title}</b><span
      :if={@description}
      class="d"
    >{@description}</span>{render_slot(@inner_block)}<span :if={@arrow} class="arr"><.icon
      name="arrow-right"
      size="md"
    /></span>
    """
  end

  defp slug(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
  end
end
