defmodule LedgerUI.Components.Mask do
  @moduledoc """
  Crops its content to one of nine mask shapes: `squircle`, `reuleaux-triangle`, `diamond`,
  `hexagon`, `hexagon-2`, `octagon`, `star`, `star-2` and `heart`.

      <.mask shape="heart" src="/images/avatar.jpg" alt="Jane" size="64" />
      <.mask shape="hexagon" size="56"><span>JD</span></.mask>
      <.mask shape="star" label="Favorite" size="32" />

  With `src` it renders the masked image; otherwise a block holding the inner content. The block
  keeps its inner content readable by screen readers; give it a `label` when the shape itself
  carries the meaning (`role="img"` and `aria-label`). The size is `size` (pixels, or an
  `LedgerUI.Components.Avatar` size name); paint it with `style="background: ..."`.

  It is drawn with the `lu-av` face of the avatar (`LedgerUI.Components.Avatar`).
  """
  use LedgerUI.Component
  import LedgerUI.Components.Avatar, only: [avatar: 1]

  @shapes ~w(squircle reuleaux-triangle diamond hexagon hexagon-2 octagon star star-2 heart)

  attr :shape, :string, default: "squircle", values: @shapes
  attr :src, :string, default: nil
  attr :alt, :string, default: ""
  attr :label, :string, default: nil, doc: "Names a block mask for assistive technology."
  attr :size, :string, default: "64", doc: "Pixels or an avatar size name."
  attr :style, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  def mask(assigns) do
    assigns = assign(assigns, :attrs, aria(assigns))

    ~H"""
    <.avatar
      :if={@src}
      src={@src}
      alt={@alt}
      shape={@shape}
      size={@size}
      color="primary"
      variant="solid"
      style={@style}
      class={@class}
      {@attrs}
    />
    <.avatar
      :if={!@src}
      shape={@shape}
      size={@size}
      color="primary"
      variant="solid"
      style={@style}
      class={@class}
      {@attrs}
    >
      {render_slot(@inner_block)}
    </.avatar>
    """
  end

  defp aria(%{label: nil, rest: rest}), do: rest
  defp aria(%{label: label, rest: rest}), do: Map.merge(rest, %{role: "img", "aria-label": label})
end
