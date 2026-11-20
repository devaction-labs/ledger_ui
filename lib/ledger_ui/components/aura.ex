defmodule LedgerUI.Components.Aura do
  @moduledoc """
  Ring of light that runs along the border of any element while something works in the background.

      <.aura tone="ai"><div class="lu-tcard">…</div></.aura>
      <.aura tone="ai" radius="pill" width="sm"><button>Summarize</button></.aura>
      <.aura mode="glow" tone="warn" shadow>…needs you…</.aura>

  `mode` is `spin` (a light turns while it works), `dual` (two colours, a result is ready) or
  `glow` (pulses when it needs the person). The ring stops for `prefers-reduced-motion`.
  """
  use LedgerUI.Component

  @radius %{"default" => "r-default", "pill" => "r-pill", "r12" => "r-r12"}

  attr :mode, :string, default: "spin", values: ~w(spin dual glow)
  attr :motion, :string, default: nil, values: [nil | ~w(spin dual glow)], doc: "Alias of `mode`."
  attr :tone, :string, default: "accent", values: ~w(accent ai info pos warn neg violet)
  attr :width, :string, default: "default", values: ~w(xs sm default lg)
  attr :radius, :string, default: "default", values: ~w(default pill r12)
  attr :shadow, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def aura(assigns) do
    mode = assigns.motion || assigns.mode

    assigns =
      assign(
        assigns,
        :classes,
        cx([
          "lu-aura",
          "m-" <> mode,
          "t-" <> assigns.tone,
          "w-" <> assigns.width,
          @radius[assigns.radius],
          assigns.shadow && "shadow",
          assigns.class
        ])
      )

    ~H"""
    <span data-part="aura" class={@classes} {@rest}>{render_slot(@inner_block)}</span>
    """
  end
end
