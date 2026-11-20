defmodule LedgerUI.Components.Container do
  @moduledoc """
  Page containers: `container_fixed/1` centers its content up to the `xl` breakpoint (1280px),
  `container_fluid/1` fills the width. Both keep a 24px gutter.

      <.container_fixed>
        <h1>Title</h1>
      </.container_fixed>

  The sizing is inline (no stylesheet class), so a `style` passed by the caller is appended.
  """
  use LedgerUI.Component

  @fixed "width:100%;max-width:1280px;margin-inline:auto;padding-inline:24px"
  @fluid "width:100%;padding-inline:24px"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "A centered container, as wide as the `xl` breakpoint at most."
  def container_fixed(assigns) do
    assigns = assign(assigns, :style, style(@fixed, assigns.rest))

    ~H"""
    <div
      data-part="container"
      class={cx(["lu-container-fixed", @class])}
      {Map.delete(@rest, :style)}
      {style_attr(@style)}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "A container as wide as its parent."
  def container_fluid(assigns) do
    assigns = assign(assigns, :style, style(@fluid, assigns.rest))

    ~H"""
    <div
      data-part="container"
      class={cx(["lu-container-fluid", @class])}
      {Map.delete(@rest, :style)}
      {style_attr(@style)}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp style(base, %{style: extra}) when is_binary(extra) and extra != "",
    do: base <> ";" <> extra

  defp style(base, _), do: base

  defp style_attr(nil), do: []
  defp style_attr(false), do: []
  defp style_attr(""), do: []
  defp style_attr(style), do: [style: style]
end
