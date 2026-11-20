defmodule LedgerUI.Components.GlowText do
  @moduledoc """
  Text with a living gradient: the colors drift across the letters (`lu-glowtx`).

      <.glow_text as="h1">Signetum</.glow_text>
      <.glow_text tone="warm">New</.glow_text>
  """
  use LedgerUI.Component

  @styles %{
    "base" => "lu-glowtx",
    "tone" => %{"default" => nil, "warm" => "warm"}
  }

  attr :tone, :string, default: "default", values: ~w(default warm)
  attr :as, :string, default: "span", values: ~w(span h1 h2 h3 p div)
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "Renders the gradient text. `as` is the HTML tag."
  def glow_text(assigns) do
    assigns =
      assign(
        assigns,
        :classes,
        cx([@styles["base"], @styles["tone"][assigns.tone], assigns.class])
      )

    ~H"""
    <.dynamic_tag tag_name={@as} data-part="glow-text" class={@classes} {@rest}>
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end
end
