defmodule LedgerUI.Components.DataTablePagerTest do
  # The default pager is made of buttons (#114) and `page_size={0}` does not divide by zero (#122).
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import Phoenix.LiveViewTest

  defp pager(assigns) do
    ~H"""
    <.data_table_pager page={3} pages={10} on_page="paginate" />
    """
  end

  defp dt(assigns) do
    ~H"""
    <.data_table id="d" rows={[]} page_size={@size} total={10} on_page="paginate">
      <:col label="x">y</:col>
    </.data_table>
    """
  end

  defp scrolled(assigns) do
    ~H"""
    <.table id="t" rows={[%{n: 1}]} scroll_label="Orders">
      <:col :let={r} label="N">{r.n}</:col>
    </.table>
    """
  end

  test "the default pager: every clickable item is a <button type=button>, none is a span" do
    html = rendered_to_string(pager(%{}))
    refute html =~ ~r/<span[^>]*phx-click/

    buttons =
      Regex.scan(~r/<button[^>]*data-part="data-table-page"[^>]*>/s, html) |> Enum.map(&hd/1)

    assert length(buttons) >= 5
    assert Enum.all?(buttons, &(&1 =~ ~s(type="button") and &1 =~ "phx-click"))
    assert html =~ ~r/<button[^>]*aria-current="page"/
    assert html =~ ~r/<button[^>]*aria-label="Next"[^>]*phx-value-page="4"/s
  end

  test "data_table with page_size 0 (or negative) renders" do
    for size <- [0, -3] do
      html = rendered_to_string(dt(%{size: size}))
      assert html =~ ~s(data-part="data-table-pager")
    end
  end

  test "scroll_label makes the scrolling box a focusable region" do
    html = rendered_to_string(scrolled(%{}))

    assert html =~
             ~r/<div[^>]*data-part="table-wrap"[^>]*role="region"[^>]*aria-label="Orders"[^>]*tabindex="0"/s
  end
end
