defmodule LedgerUI.Components.MiniCard do
  @moduledoc """
  The canvas's mini card: a small card for a shortcut (an icon box over a bold label) or for a
  short figure (a faint label over a mono value).

      <.mini_card icon="huge-invoice-01" tone="accent" label="Novo pedido" navigate={~p"/pedidos/novo"} />
      <.mini_card label="A receber" value="R$ 41,2 mil" />

  With `href`, `navigate` or `patch` the card is a link and ends in an arrow. The inner block
  goes under the label. `surface="card"` draws it as a card (rounded 16px, a hairline and a soft
  shadow) with a rounded icon avatar (a row of shortcuts) instead of the default panel. Styled only
  with Tailwind utilities.
  """
  use LedgerUI.Component
  import LedgerUI.Components.Avatar, only: [avatar: 1]

  @ic_tone %{
    "neutral" => nil,
    "accent" => "accent",
    "success" => "success",
    "warning" => "warning",
    "error" => "error",
    "info" => "info"
  }
  @av_tone %{
    "neutral" => "neutral",
    "accent" => "primary",
    "success" => "success",
    "warning" => "warning",
    "error" => "error",
    "info" => "info"
  }
  @panel "flex items-center gap-3 rounded-[18px] border border-line bg-panel p-3 text-inherit no-underline"
  @card "flex flex-row items-center gap-2.5 rounded-[18px] border border-line bg-panel p-3.5 text-[13px] text-inherit no-underline shadow-xs"

  attr :label, :string, required: true
  attr :value, :string, default: nil, doc: "A short figure: the label becomes a caption over it."
  attr :icon, :string, default: nil
  attr :tone, :string, default: "neutral", values: Map.keys(@ic_tone)
  attr :surface, :string, default: "panel", values: ~w(panel card)
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method)
  slot :inner_block, doc: "Extra content under the label."

  def mini_card(assigns) do
    changed0 = assigns.__changed__
    link? = Enum.any?([:href, :navigate, :patch], &Map.has_key?(assigns.rest, &1))
    card? = assigns.surface == "card"

    assigns =
      assigns
      |> assign(:link?, link?)
      |> assign(:card?, card?)
      |> assign(:classes, cx([if(card?, do: @card, else: @panel), assigns.class]))
      |> assign(:ic_tone, @ic_tone[assigns.tone])
      |> assign(:av_tone, @av_tone[assigns.tone])
      |> assign(
        :link_attrs,
        link? && LedgerUI.LinkAttrs.resolve(assigns.rest, ["data-part", "class"])
      )

    assigns =
      settle(assigns, changed0,
        link?: [:rest],
        link_attrs: [:rest],
        card?: [:surface],
        classes: [:card?, :class],
        ic_tone: [:tone],
        av_tone: [:tone]
      )

    ~H"""
    <a :if={@link?} data-part="mini-card" class={@classes} {@link_attrs}>
      <.mini_body
        card?={@card?}
        link?={true}
        icon={@icon}
        label={@label}
        value={@value}
        ic_tone={@ic_tone}
        av_tone={@av_tone}
      >
        {render_slot(@inner_block)}
      </.mini_body>
    </a>
    <div :if={!@link?} data-part="mini-card" class={@classes} {@rest}>
      <.mini_body
        card?={@card?}
        link?={false}
        icon={@icon}
        label={@label}
        value={@value}
        ic_tone={@ic_tone}
        av_tone={@av_tone}
      >
        {render_slot(@inner_block)}
      </.mini_body>
    </div>
    """
  end

  attr :card?, :boolean, required: true
  attr :link?, :boolean, required: true
  attr :icon, :string, default: nil
  attr :label, :string, required: true
  attr :value, :string, default: nil
  attr :ic_tone, :string, default: nil
  attr :av_tone, :string, required: true
  slot :inner_block

  defp mini_body(%{card?: true} = assigns) do
    ~H"""
    <.avatar :if={@icon} color={@av_tone} variant="soft" shape="rounded" size="34">
      <.icon name={@icon} size="md" />
    </.avatar>
    <span data-part="mini-card-text" class="flex flex-col text-muted">
      <span :if={@value} data-part="mini-card-label">{@label}</span><b
        data-part="mini-card-title"
        class="text-sm"
      >{if @value, do: @value, else: @label}</b>{render_slot(@inner_block)}
    </span>
    """
  end

  defp mini_body(assigns) do
    ~H"""
    <.icon :if={@icon} name={@icon} boxed tone={@ic_tone} />
    <span data-part="mini-card-text" class="flex min-w-0 flex-1 flex-col">
      <span :if={@value} data-part="mini-card-label" class="text-xs/4 text-muted">{@label}</span><b
        data-part="mini-card-title"
        class={["font-semibold", @value && "font-mono"]}
      >{if @value, do: @value, else: @label}</b>{render_slot(@inner_block)}
    </span>
    <.icon :if={@link?} name="arrow-up-right" size="md" class="text-ink" />
    """
  end
end
