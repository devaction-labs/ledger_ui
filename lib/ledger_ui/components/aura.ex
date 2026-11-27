defmodule LedgerUI.Components.Aura do
  @moduledoc """
  Ring of light that runs along the border of any element while something works in the background.
  Styled only with Tailwind utilities; the light is a `::before` cone that turns (`lu-aura-spin`).

      <.aura tone="ai"><.toast_card title="Reading the invoice" /></.aura>
      <.aura tone="ai" radius="pill" width="sm"><button>Summarize</button></.aura>
      <.aura mode="glow" tone="warn" shadow>…needs you…</.aura>

  `mode` is `spin` (a light turns while it works), `dual` (two colours, a result is ready) or
  `glow` (pulses when it needs the person). `tone` picks the light (`ai` is the assistant's teal
  and violet).
  """
  use LedgerUI.Component

  @base "relative isolate inline-flex max-w-full flex-col self-start " <>
          "p-(--w) " <>
          "rounded-[calc(var(--r)+var(--w))] " <>
          "[&>*]:relative [&>*]:rounded-[var(--r)]! [&>*]:shadow-none! " <>
          "before:pointer-events-none before:absolute before:top-1/2 before:left-1/2 before:-z-10 " <>
          "before:aspect-square before:w-[max(220%,560px)] before:content-[''] " <>
          "before:[transform:translate(-50%,-50%)] before:animate-[lu-aura-spin_2.6s_linear_infinite]"

  # the ring: a cone of light over the border colour
  @modes %{
    "spin" =>
      "overflow-hidden bg-[color-mix(in_srgb,var(--t1)_14%,var(--lu-line))] " <>
        "before:bg-[conic-gradient(from_0deg,transparent_0_58%,var(--t1)_76%,color-mix(in_srgb,var(--t1)_35%,#fff)_81%,transparent_92%)]",
    "dual" =>
      "overflow-hidden bg-[color-mix(in_srgb,var(--a2)_14%,color-mix(in_srgb,var(--t1)_14%,var(--lu-line)))] " <>
        "before:bg-[conic-gradient(from_0deg,transparent_0_8%,var(--t1)_22%,transparent_36%_58%,var(--a2)_72%,transparent_86%)]",
    "glow" =>
      "overflow-visible bg-(--t1) animate-[lu-aura-glow_1.8s_ease-in-out_infinite] before:hidden"
  }

  @tones %{
    "accent" => "[--t1:var(--lu-accent-500)] [--a2:var(--lu-aura-2)]",
    "ai" => "[--t1:var(--lu-ai-1)] [--a2:var(--lu-ai-2)]",
    "info" => "[--t1:var(--lu-info)] [--a2:var(--lu-aura-2)]",
    "pos" => "[--t1:var(--lu-pos)] [--a2:var(--lu-aura-2)]",
    "warn" => "[--t1:var(--lu-warn)] [--a2:var(--lu-aura-2)]",
    "neg" => "[--t1:var(--lu-neg)] [--a2:var(--lu-aura-2)]",
    "violet" => "[--t1:var(--lu-violet)] [--a2:var(--lu-aura-2)]"
  }

  @widths %{
    "xs" => "[--w:.75px]",
    "sm" => "[--w:1px]",
    "default" => "[--w:1.25px]",
    "lg" => "[--w:2px]"
  }

  @radius %{"default" => "[--r:16px]", "pill" => "[--r:999px]", "r12" => "[--r:12px]"}

  @shadow "shadow-[0_10px_30px_-10px_color-mix(in_oklab,var(--t1)_55%,transparent)] [filter:drop-shadow(0_10px_22px_rgb(15_15_20_/_.10))_drop-shadow(0_1px_2px_rgb(15_15_20_/_.06))]"

  @doc false
  # The class pieces, shared with `LedgerUI.Components.Toast` (its toasts are built by a hook).
  def parts, do: %{base: @base, modes: @modes, tones: @tones, widths: @widths, shadow: @shadow}

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
    changed0 = assigns.__changed__
    mode = assigns.motion || assigns.mode

    assigns =
      assign(
        assigns,
        :classes,
        cx([
          @base,
          "w-max [&>*]:block",
          @modes[mode],
          @tones[assigns.tone],
          @widths[assigns.width],
          @radius[assigns.radius],
          assigns.shadow && @shadow
        ])
      )

    assigns =
      settle(assigns, changed0, classes: [:motion, :mode, :tone, :width, :radius, :shadow])

    ~H"""
    <span data-part="aura" class={[@classes, @class]} {@rest}>{render_slot(@inner_block)}</span>
    """
  end
end
