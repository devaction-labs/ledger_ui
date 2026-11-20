defmodule LedgerUI.Components.HeroCard do
  @moduledoc """
  The hero card: the welcome or the insight at the top of a page. The text on the left (an
  eyebrow in mono caps with an optional icon, the title, the description and the actions) and a
  picture on the right, as tall as the card, fading into it from the left.

      <.hero_card eyebrow="Bem-vindo de volta" title="Metas do ano" description="Alinhamento e metas do trimestre.">
        <:actions>...</:actions>
        <:art>...</:art>
      </.hero_card>

  The picture is `src` (an `<img>`) or the `:art` slot (inline SVG). `position` moves the crop
  (`object-position`). `size="lg"` makes the title and the card taller; `variant="panel"` puts it
  on the panel colour instead of the soft tint.
  """
  use LedgerUI.Component

  @paddings %{"md" => 16, "lg" => 24}
  @title_sizes %{"md" => 20, "lg" => 28}

  attr :eyebrow, :string, default: nil, doc: "The small mono caps line above the title."
  attr :title, :string, required: true
  attr :description, :string, default: nil
  attr :src, :string, default: nil, doc: "The picture on the right."
  attr :alt, :string, default: ""
  attr :position, :string, default: "center", doc: "The crop of the picture (`object-position`)."
  attr :size, :string, default: "md", values: ~w(md lg)
  attr :variant, :string, default: "soft", values: ~w(soft panel)
  attr :heading, :string, default: "h2", values: ~w(h1 h2 h3)
  attr :class, :any, default: nil
  attr :rest, :global

  slot :actions
  slot :art, doc: "The picture as markup (an SVG), instead of `src`."
  slot :icon, doc: "An icon before the eyebrow."
  slot :inner_block, doc: "Under the description: a progress bar, a note."

  def hero_card(assigns) do
    pad = @paddings[assigns.size]

    assigns =
      assigns
      |> assign(
        :classes,
        cx([
          "lu-cv",
          if(assigns.variant == "soft", do: "soft c-primary", else: "default"),
          "lu-hero",
          assigns.size == "lg" && "lg",
          assigns.class
        ])
      )
      |> assign(
        :root_style,
        "padding:#{pad}px;flex-direction:row;align-items:stretch;gap:16px;position:relative;overflow:hidden"
      )
      |> assign(
        :title_style,
        "margin:0;font-size:#{@title_sizes[assigns.size]}px;font-weight:600"
      )
      |> assign(
        :img_style,
        "width:100%;height:100%;object-fit:cover;object-position:#{assigns.position}"
      )
      |> assign(:has_art, assigns.src != nil or assigns.art != [])

    ~H"""
    <div data-part="hero-card" class={@classes} style={@root_style} {@rest}>
      <div class="lu-col" style="gap:8px;flex:1;min-width:0;position:relative;z-index:1">
        <span
          :if={@eyebrow}
          class="mono lu-xs lu-muted"
          style="display:inline-flex;align-items:center;gap:6px;text-transform:uppercase;letter-spacing:.08em"
        >{render_slot(@icon)}{@eyebrow}</span>
        <.dynamic_tag tag_name={@heading} style={@title_style}>{@title}</.dynamic_tag>
        <p :if={@description} class="lu-muted" style="margin:0">{@description}</p>
        {render_slot(@inner_block)}
        <div :if={@actions != []} class="lu-row" style="margin-top:6px">
          {render_slot(@actions)}
        </div>
      </div>
      <div
        :if={@has_art}
        data-part="hero-art"
        style="flex:0 0 40%;min-height:100%;margin:-16px -16px -16px 0;-webkit-mask-image:linear-gradient(to right,transparent,#000 45%);mask-image:linear-gradient(to right,transparent,#000 45%)"
      >
        <img :if={@src} src={@src} alt={@alt} style={@img_style} />
        {render_slot(@art)}
      </div>
    </div>
    """
  end
end
