defmodule LedgerUI.Components.Cover do
  @moduledoc """
  The canvas cover: a wide band in the accent gradient (or a quiet surface) that heads a profile
  or a page, with a title on it, or a record's avatar overlapping its lower edge.

      <.cover title="Distribuidora Sertão" />

      <.cover height={110} title="Distribuidora Sertão" subtitle="Cliente desde 2021">
        <:avatar><.avatar name="Distribuidora Sertão" tint="#1a7f4b" size="64" shape="rounded" /></:avatar>
      </.cover>

      <.cover tone="neutral" height={120} />

  `tone` is `accent` (the accent gradient, white text) or `neutral` (the sunken surface). `src`
  lays a picture over the band. Without `:avatar` the `title` is written on the band, at the
  bottom; with it, the avatar overlaps the band's lower edge with the `title` and `subtitle`
  beside it. The inner block goes on the band (actions, a badge). Styled only with Tailwind utilities.
  """
  use LedgerUI.Component

  @bg %{
    "accent" => "bg-[linear-gradient(135deg,var(--lu-accent-300),var(--lu-accent-700))]",
    "neutral" => "bg-[linear-gradient(135deg,var(--lu-bg-selected),var(--lu-line-strong))]"
  }

  attr :tone, :string, default: "accent", values: ~w(accent neutral)
  attr :height, :integer, default: 180, doc: "The band's height in pixels."
  attr :src, :string, default: nil, doc: "A picture that covers the band."
  attr :title, :string, default: nil
  attr :subtitle, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :avatar, doc: "An avatar that overlaps the band's lower edge."
  slot :inner_block, doc: "Content on the band."

  def cover(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:band_class, band_class(assigns))
      |> assign(:band_style, "height:#{assigns.height}px")
      |> assign(:on_band_title, assigns.title != nil and assigns.avatar == [])
      |> assign(:text_color, if(assigns.tone == "accent", do: "text-white", else: "text-ink"))
      |> then(
        &settle(&1, changed0,
          band_class: [:tone, :src, :title, :avatar],
          band_style: [:height],
          on_band_title: [:title, :avatar],
          text_color: [:tone]
        )
      )

    ~H"""
    <div
      :if={@avatar == []}
      data-part="cover"
      class={[@band_class, @class]}
      style={@band_style}
      {@rest}
    >
      <.cover_content
        src={@src}
        title={@title}
        on_band_title={@on_band_title}
        text_color={@text_color}
      >
        {render_slot(@inner_block)}
      </.cover_content>
    </div>
    <div :if={@avatar != []} data-part="cover" class={@class} {@rest}>
      <div data-part="cover-band" class={@band_class} style={@band_style}>
        <.cover_content src={@src} on_band_title={false} text_color={@text_color}>
          {render_slot(@inner_block)}
        </.cover_content>
      </div>
      <div data-part="cover-head" class="flex items-end gap-3.5 px-4">
        <span
          data-part="cover-avatar"
          class="-mt-8 inline-flex rounded-[30%] shadow-[0_0_0_4px_var(--lu-bg-panel)]"
        >
          {render_slot(@avatar)}
        </span>
        <span :if={@title} data-part="cover-text" class="flex flex-col py-2.5">
          <b data-part="cover-title">{@title}</b><span
            :if={@subtitle}
            data-part="cover-subtitle"
            class="text-[13px] leading-[18px] text-muted"
          >{@subtitle}</span>
        </span>
      </div>
    </div>
    """
  end

  attr :tone, :string, default: "accent", values: ["accent", "neutral"]
  attr :height, :integer, default: 180, doc: "The band's height in pixels."
  attr :src, :string, default: nil, doc: "A picture that covers the band."
  attr :title, :string, default: nil
  attr :subtitle, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :avatar, doc: "An avatar that overlaps the band's lower edge."
  slot :inner_block, doc: "Content on the band."
  @doc "Same as `cover/1` (same attributes and slots), under the name the design vitrine uses."
  def cover_card(assigns), do: cover(assigns)

  defp band_class(a) do
    cx([
      @bg[a.tone],
      (a.src || a.title || a.avatar != []) && "relative overflow-hidden"
    ])
  end

  attr :src, :string, default: nil
  attr :title, :string, default: nil
  attr :on_band_title, :boolean, default: false
  attr :text_color, :string, required: true
  slot :inner_block

  defp cover_content(assigns) do
    ~H"""
    <img
      :if={@src}
      data-part="cover-image"
      src={@src}
      alt=""
      class="absolute inset-0 size-full object-cover"
    />{render_slot(@inner_block)}<b
      :if={@on_band_title}
      data-part="cover-title"
      class={["absolute bottom-3 left-4 text-[18px]", @text_color]}
    >{@title}</b>
    """
  end
end
