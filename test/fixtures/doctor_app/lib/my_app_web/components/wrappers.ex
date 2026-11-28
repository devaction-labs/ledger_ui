defmodule MyAppWeb.Wrappers do
  use Phoenix.Component

  attr :rest, :global

  def badge(assigns) do
    ~H"""
    <.badge variant="soft" {@rest}>{render_slot(@inner_block)}</.badge>
    """
  end

  def input(assigns) do
    ~H"""
    <.input field={@field} {assigns} />
    """
  end

  def pagination(assigns), do: LedgerUI.Components.Pagination.pagination(assigns)
end
