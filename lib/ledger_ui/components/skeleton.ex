defmodule LedgerUI.Components.Skeleton do
  @moduledoc """
  Loading placeholder that mirrors the final layout. The size comes from `class`.

      <.skeleton class="h-3 w-40" animation="wave" />
      <.skeleton shape="circle" style="width:40px;height:40px" />

      <.skeleton_group label="Loading orders">
        <.skeleton style="width:60%" />
      </.skeleton_group>

  `animation={nil}` emits no animation class (`"none"` emits `a-none`); `tag="span"` draws a span (inside a flex column).
  `shape` emits no class by default (the base block already has the small radius); an explicit
  `"rounded"` adds `sh-rounded`. The wave and the pulse stop for `prefers-reduced-motion`.
  """
  use LedgerUI.Component

  attr :animation, :string, default: "wave", values: [nil | ~w(wave pulse none)]
  attr :variant, :string, default: "canvas", values: ~w(canvas lineone)
  attr :shape, :string, default: nil, values: [nil | ~w(rounded pill circle square lg)]
  attr :tag, :string, default: "div", values: ~w(div span), doc: "The element drawn."
  attr :class, :any, default: nil
  attr :rest, :global

  def skeleton(assigns) do
    assigns =
      assigns
      |> assign(
        :classes,
        cx([
          "lu-sk",
          assigns.animation && "a-" <> assigns.animation,
          assigns.shape && "sh-" <> assigns.shape,
          assigns.class
        ])
      )
      |> assign(:attrs, attrs(assigns))

    ~H"""
    <.dynamic_tag tag_name={@tag} data-part="skeleton" class={@classes} {@attrs}></.dynamic_tag>
    """
  end

  # The old slate block (`lineone`) has a 3px corner.
  defp attrs(%{variant: "lineone", rest: rest}),
    do: Map.update(rest, :style, "border-radius:3px", &(&1 <> ";border-radius:3px"))

  defp attrs(%{rest: rest}), do: rest

  attr :label, :string, default: "Loading…", doc: "Read by screen readers; not drawn."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @sr "position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0 0 0 0);white-space:nowrap"

  def skeleton_group(assigns) do
    assigns = assign(assigns, :sr, @sr)

    ~H"""
    <div data-part="skeleton-group" role="status" aria-busy="true" class={@class} {@rest}>
      <span style={@sr}>{@label}</span>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
