defmodule LedgerUI.Components.Skeleton do
  @moduledoc """
  Loading placeholder that mirrors the final layout. Styled only with Tailwind utilities; the
  size comes from `class` (a block is 12px high until a `h-*` class says otherwise).

      <.skeleton class="h-3 w-40" animation="wave" />
      <.skeleton shape="circle" class="size-10" />

      <.skeleton_group label="Loading orders">
        <.skeleton class="w-3/5" />
      </.skeleton_group>

  `animation={nil}` (or `"none"`) draws a still block; `tag="span"` draws a span (inside a flex
  column). `shape` is the corner: the base block has the small radius, so `"rounded"` (or `nil`)
  keeps it.
  """
  use LedgerUI.Component

  @animations %{
    "wave" =>
      "after:absolute after:inset-0 after:content-[''] after:[transform:translateX(-100%)] " <>
        "after:bg-[linear-gradient(90deg,transparent,color-mix(in_oklab,var(--lu-bg-panel)_70%,transparent),transparent)] " <>
        "after:animate-[lu-wave_1.4s_ease-in-out_infinite]",
    "pulse" => "animate-[lu-pulse_1.4s_ease-in-out_infinite]",
    "none" => nil
  }

  @shapes %{
    "pill" => "rounded-full",
    "circle" => "rounded-[50%]",
    "square" => "rounded-none",
    "lg" => "rounded-lg"
  }

  attr :animation, :string, default: "wave", values: [nil | ~w(wave pulse none)]
  attr :variant, :string, default: "canvas", values: ~w(canvas lineone)
  attr :shape, :string, default: nil, values: [nil | ~w(rounded pill circle square lg)]
  attr :tag, :string, default: "div", values: ~w(div span), doc: "The element drawn."
  attr :class, :any, default: nil
  attr :rest, :global

  def skeleton(assigns) do
    assigns =
      assign(
        assigns,
        :classes,
        cx([
          "relative overflow-hidden bg-sunken",
          # the corner: the old slate block (`lineone`) has 3px; the shape decides otherwise
          cond do
            assigns.variant == "lineone" -> "rounded-[3px]"
            assigns.shape in ~w(pill circle square lg) -> @shapes[assigns.shape]
            true -> "rounded-sm"
          end,
          # a `h-*` in `class` is the caller's height
          !height?(assigns.class) && "h-3",
          assigns.animation && @animations[assigns.animation]
        ])
      )

    ~H"""
    <.dynamic_tag tag_name={@tag} data-part="skeleton" class={[@classes, @class]} {@rest}>
    </.dynamic_tag>
    """
  end

  defp height?(class) do
    class |> cx() |> String.split() |> Enum.any?(&Regex.match?(~r/^(h|size|min-h)-/, &1))
  end

  attr :label, :string, default: "Loading…", doc: "Read by screen readers; not drawn."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def skeleton_group(assigns) do
    ~H"""
    <div data-part="skeleton-group" role="status" aria-busy="true" class={@class} {@rest}>
      <span data-part="skeleton-label" class="sr-only">{@label}</span>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
