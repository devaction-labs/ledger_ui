defmodule LedgerUI.Components.SortPatchTest do
  # #103: `sort_patch` (`(column, direction) -> path`) makes a sortable header a `patch` link in
  # `table/1`, `card_table/1`, `data_table/1` and `table_head/1`; without it the header is as before.
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import LedgerUI.DiffCase
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  @rows [%{id: 1, name: "Ana", city: "Rio"}, %{id: 2, name: "Bia", city: "Lima"}]
  def sort_path(col, dir), do: "/items?sort=#{col}_#{dir}"
  def remote(_col, _dir), do: "javascript:alert(1)"
  @fun &__MODULE__.sort_path/2

  def t_table(assigns),
    do: ~H"""
    <.table id="t" rows={@rows} row_id={&"r-#{&1.id}"} sort_by={@by} sort_dir={@dir} sort_patch={@fun}>
      <:col :let={r} label="Name" sort_key="name">{r.name}</:col>
      <:col :let={r} label="City">{r.city}</:col>
    </.table>
    """

  def t_table_event(assigns),
    do: ~H"""
    <.table id="t" rows={@rows} row_id={&"r-#{&1.id}"} sort_by={@by} sort_dir={@dir} on_sort="sort">
      <:col :let={r} label="Name" sort_key="name">{r.name}</:col>
      <:col :let={r} label="City">{r.city}</:col>
    </.table>
    """

  def t_card(assigns),
    do: ~H"""
    <.card_table
      id="c"
      rows={@rows}
      row_id={&"r-#{&1.id}"}
      sort_by={@by}
      sort_dir={@dir}
      sort_patch={@fun}
    >
      <:col :let={r} label="Name" sort_key="name">{r.name}</:col>
      <:col :let={r} label="City">{r.city}</:col>
    </.card_table>
    """

  def t_data(assigns),
    do: ~H"""
    <.data_table
      id="d"
      rows={@rows}
      row_id={&"r-#{&1.id}"}
      sort_by={@by}
      sort_dir={@dir}
      sort_patch={@fun}
    >
      <:col :let={r} label="Name" sort_key="name">{r.name}</:col>
      <:col :let={r} label="City">{r.city}</:col>
    </.data_table>
    """

  def t_head(assigns),
    do: ~H"""
    <table>
      <.table_head sort_by={@by} sort_dir={@dir} sort_patch={@fun}>
        <:col label="Name" sort_key="name" />
        <:col label="City" />
      </.table_head>
    </table>
    """

  def t_head_event(assigns),
    do: ~H"""
    <table>
      <.table_head sort_by={@by} sort_dir={@dir} on_sort="sort">
        <:col label="Name" sort_key="name" />
        <:col label="City" />
      </.table_head>
    </table>
    """

  @base %{rows: @rows, by: nil, dir: "asc", fun: @fun}

  for {name, fun} <- [
        table: &__MODULE__.t_table/1,
        card_table: &__MODULE__.t_card/1,
        data_table: &__MODULE__.t_data/1,
        table_head: &__MODULE__.t_head/1
      ] do
    test "#{name}: the sortable header is a patch link to the next direction" do
      {_, html} = first(unquote(fun), @base)
      assert html =~ ~s(data-phx-link="patch")
      assert html =~ ~s(href="/items?sort=name_asc")
      assert html =~ ~s(data-part="table-sort-link")
      # the other header has no sort_key: no link
      assert length(String.split(html, "table-sort-link")) == 2
      # a link does not also send an event
      refute html =~ "phx-click"
      refute html =~ ~s(tabindex="0")
    end

    test "#{name}: the current column offers the opposite direction and keeps aria-sort" do
      {_, html} = first(unquote(fun), %{@base | by: "name", dir: "asc"})
      assert html =~ ~s(href="/items?sort=name_desc")
      assert html =~ ~s(aria-sort="ascending")
      {_, html} = first(unquote(fun), %{@base | by: "name", dir: "desc"})
      assert html =~ ~s(href="/items?sort=name_asc")
      assert html =~ ~s(aria-sort="descending")
    end

    test "#{name}: a new order is a correct patch" do
      check(unquote(fun), @base, by: "name", dir: "asc")
      check(unquote(fun), %{@base | by: "name"}, dir: "desc")
    end
  end

  test "a javascript: destination raises as <.link patch> does" do
    assert_raise ArgumentError, fn ->
      html(&__MODULE__.t_table/1, %{@base | fun: &__MODULE__.remote/2})
    end
  end

  describe "without sort_patch" do
    test "the header sends the event and is not a link (as before)" do
      html = rendered_to_string(t_table_event(Map.put(@base, :__changed__, nil)))
      refute html =~ "table-sort-link"
      refute html =~ ~s(data-phx-link)
      assert html =~ ~s(phx-click="sort")
      assert html =~ ~s(tabindex="0")
      assert html =~ ~s(phx-value-direction="asc")

      head = rendered_to_string(t_head_event(Map.put(@base, :__changed__, nil)))
      refute head =~ "table-sort-link"
      assert head =~ ~s(phx-click="sort")
    end

    test "no on_sort and no sort_patch: no sorting attributes at all" do
      assigns = %{rows: @rows}

      html =
        rendered_to_string(~H"""
        <.table id="t" rows={@rows} row_id={&"r-#{&1.id}"}>
          <:col :let={r} label="Name" sort_key="name">{r.name}</:col>
        </.table>
        """)

      refute html =~ "aria-sort"
      refute html =~ "table-sort-link"
      refute html =~ "phx-click"
    end
  end
end
