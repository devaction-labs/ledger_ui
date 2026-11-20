defmodule LedgerUI.Components.MiniCard do
  @moduledoc """
  The canvas's mini card: a small card for a shortcut (an icon box over a bold label) or for a
  short figure (a faint label over a mono value).

      <.mini_card icon="huge-invoice-01" tone="accent" label="Novo pedido" navigate={~p"/pedidos/novo"} />
      <.mini_card label="A receber" value="R$ 41,2 mil" />

  With `href`, `navigate` or `patch` the card is a link and ends in an arrow. The inner block
  goes under the label. `surface="card"` draws it as a `lu-cv` card with a rounded icon avatar
  (a row of shortcuts) instead of the default panel.
  """
  use LedgerUI.Component
  import LedgerUI.Components.Avatar, only: [avatar: 1]

  @ic_tone %{
    "neutral" => nil,
    "accent" => "acc",
    "success" => "pos",
    "warning" => "warn",
    "error" => "neg",
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
  @panel_style "display:flex;gap:12px;align-items:center;padding:12px;color:inherit;text-decoration:none"
  @card_style "flex-direction:row;align-items:center;gap:10px;min-height:0"

  attr :label, :string, required: true
  attr :value, :string, default: nil, doc: "A short figure: the label becomes a caption over it."
  attr :icon, :string, default: nil
  attr :tone, :string, default: "neutral", values: Map.keys(@ic_tone)
  attr :surface, :string, default: "panel", values: ~w(panel card)
  attr :style, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method)
  slot :inner_block, doc: "Extra content under the label."

  def mini_card(assigns) do
    link? = Enum.any?([:href, :navigate, :patch], &Map.has_key?(assigns.rest, &1))
    card? = assigns.surface == "card"

    assigns =
      assigns
      |> assign(:link?, link?)
      |> assign(:card?, card?)
      |> assign(:classes, cx([if(card?, do: "lu-cv default", else: "lu-panel"), assigns.class]))
      |> assign(
        :root_style,
        Enum.join(
          Enum.filter([if(card?, do: @card_style, else: @panel_style), assigns.style], & &1),
          ";"
        )
      )
      |> assign(:ic_tone, @ic_tone[assigns.tone])
      |> assign(:av_tone, @av_tone[assigns.tone])

    ~H"""
    <.link :if={@link?} data-part="mini-card" class={@classes} style={@root_style} {@rest}>
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
    </.link>
    <div :if={!@link?} data-part="mini-card" class={@classes} style={@root_style} {@rest}>
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
    <span class="lu-col" style="gap:0">
      <span :if={@value}>{@label}</span><b>{if @value, do: @value, else: @label}</b>{render_slot(
        @inner_block
      )}
    </span>
    """
  end

  defp mini_body(assigns) do
    ~H"""
    <.icon :if={@icon} name={@icon} boxed tone={@ic_tone} />
    <span class="lu-col lu-grow" style="gap:0">
      <span :if={@value} class="lu-xs lu-muted">{@label}</span><b
        style="font-weight:600"
        class={@value && "mono"}
      >{if @value, do: @value, else: @label}</b>{render_slot(@inner_block)}
    </span>
    <.icon :if={@link?} name="arrow-up-right" size="md" class="lu-muted" />
    """
  end
end
