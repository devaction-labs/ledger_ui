defmodule LedgerUI.Components.GlowText do
  @moduledoc """
  Text with a living gradient: the colors drift across the letters. Styled only with Tailwind
  utilities (a gradient clipped to the text, moved by the `mo-glowtx` keyframes).

      <.glow_text as="h1">Signetum</.glow_text>
      <.glow_text tone="warm">New</.glow_text>

  `default` runs from the ink through the accent and the assistant violet; `warm` through amber and
  rose. Size it with `style` or a `text-*` class on the call.
  """
  use LedgerUI.Component

  @base "bg-[length:250%_100%] bg-clip-text font-semibold tracking-[-.03em] text-transparent " <>
          "animate-[mo-glowtx_4s_linear_infinite]"

  @tones %{
    "default" =>
      "bg-[linear-gradient(90deg,var(--lu-ink)_0%,var(--lu-accent-500)_30%,var(--lu-aura-2)_50%,var(--lu-accent-500)_70%,var(--lu-ink)_100%)]",
    "warm" =>
      "bg-[linear-gradient(90deg,var(--lu-ink)_0%,#e8b04a_30%,#e57487_50%,#e8b04a_70%,var(--lu-ink)_100%)]"
  }

  attr :tone, :string, default: "default", values: ~w(default warm)
  attr :as, :string, default: "span", values: ~w(span h1 h2 h3 p div)
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "Renders the gradient text. `as` is the HTML tag."
  def glow_text(assigns) do
    assigns = assign(assigns, :classes, [@base, @tones[assigns.tone], assigns.class])

    ~H"""
    <.dynamic_tag tag_name={@as} data-part="glow-text" class={@classes} {@rest}>
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end
end
