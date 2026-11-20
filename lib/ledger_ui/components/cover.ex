defmodule LedgerUI.Components.Cover do
  @moduledoc """
  The canvas cover: a wide band in the accent gradient (or a quiet surface) that heads a profile
  or a page, with a title on it, or a record's avatar overlapping its lower edge.

      <.cover title="Distribuidora Sertão" />

      <.cover height={110} title="Distribuidora Sertão" subtitle="Cliente desde 2021">
        <:avatar><.avatar name="Distribuidora Sertão" tint="#1a7f4b" size="64" shape="rounded" /></:avatar>
      </.cover>

      <.cover tone="neutral" height={120} />

  `tone` is `accent` (the teal gradient, white text) or `neutral` (the sunken surface). `src`
  lays a picture over the band. Without `:avatar` the `title` is written on the band, at the
  bottom; with it, the avatar overlaps the band's lower edge with the `title` and `subtitle`
  beside it. The inner block goes on the band (actions, a badge).
  """
  use LedgerUI.Component

  @bg %{
    "accent" => "linear-gradient(135deg,var(--teal-300),var(--teal-700))",
    "neutral" => "linear-gradient(135deg,var(--bg-selected),var(--line-strong))"
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
    assigns =
      assigns
      |> assign(:band_style, band_style(assigns))
      |> assign(:on_band_title, assigns.title != nil and assigns.avatar == [])
      |> assign(:text_color, if(assigns.tone == "accent", do: "#fff", else: "var(--ink)"))

    ~H"""
    <div :if={@avatar == []} data-part="cover" class={@class} style={@band_style} {@rest}>
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
      <div data-part="cover-band" style={@band_style}>
        <.cover_content src={@src} on_band_title={false} text_color={@text_color}>
          {render_slot(@inner_block)}
        </.cover_content>
      </div>
      <div style="display:flex;align-items:flex-end;gap:14px;padding:0 16px">
        <span style="margin-top:-32px;display:inline-flex;border-radius:30%;box-shadow:0 0 0 4px var(--bg-panel)">
          {render_slot(@avatar)}
        </span>
        <span :if={@title} class="lu-col" style="gap:0;padding:10px 0">
          <b>{@title}</b><span :if={@subtitle} class="lu-small lu-muted">{@subtitle}</span>
        </span>
      </div>
    </div>
    """
  end

  defp band_style(a) do
    base = "height:#{a.height}px;background:#{@bg[a.tone]}"

    if a.src || a.title || a.avatar != [],
      do: base <> ";position:relative;overflow:hidden",
      else: base
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
      src={@src}
      alt=""
      style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover"
    />{render_slot(@inner_block)}<b
      :if={@on_band_title}
      style={"position:absolute;left:16px;bottom:12px;font-size:18px;color:#{@text_color}"}
    >{@title}</b>
    """
  end
end
