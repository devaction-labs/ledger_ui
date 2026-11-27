defmodule LedgerUI.Perf.TableSortTest do
  # Sorting, density, paging and searching a `<.table>` / `<.data_table>`: the rows keep their
  # `:key`, and what every row shares (`ctx`, the columns, the classes) is not sent again when
  # only `rows`, `sort_by`, `compact`... changed. For each case the first render plus the patch is
  # checked against a fresh render (`LedgerUI.DiffCase`), and the size of the patch is bounded.
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import LedgerUI.DiffCase

  defp t_table(assigns) do
    ~H"""
    <.table
      id="t"
      rows={@rows}
      row_id={fn r -> "row-#{r.id}" end}
      sort_by={@sort_by}
      sort_dir={@sort_dir}
      on_sort="sort"
      compact={@compact}
      variant={@variant}
      on_select="sel"
      on_select_all="all"
      selected={@sel}
    >
      <:col :let={c} label="Name" sort_key="name">{c.name}</:col>
      <:col :let={c} label="Status">
        <.badge>{c.status}</.badge>
      </:col>
      <:action :let={c}>
        <a href={"/edit/" <> to_string(c.id)}>Edit {c.id}</a>
      </:action>
    </.table>
    """
  end

  defp t_norid(assigns) do
    ~H"""
    <.table
      id="t"
      rows={@rows}
      sort_by={@sort_by}
      sort_dir={@sort_dir}
      on_sort="sort"
      compact={@compact}
    >
      <:col :let={c} label="Name" sort_key="name">{c.name}</:col>
      <:col :let={c} label="Status">{c.status}</:col>
    </.table>
    """
  end

  defp t_groups(assigns) do
    ~H"""
    <.table
      id="t"
      rows={@rows}
      row_id={fn r -> "row-#{r.id}" end}
      row_groups
      details
      sort_by={@sort_by}
      sort_dir={@sort_dir}
      on_sort="sort"
      compact={@compact}
    >
      <:col :let={c} label="Name" sort_key="name">{c.name}</:col>
      <:detail :let={c} label="Status">{c.status}</:detail>
      <:expand :let={%{row: c}}>more {c.name}</:expand>
    </.table>
    """
  end

  defp t_dt(assigns) do
    ~H"""
    <.data_table
      id="dt"
      rows={@rows}
      row_id={fn r -> "row-#{r.id}" end}
      search={@search}
      on_search="search"
      sort_by={@sort_by}
      sort_dir={@sort_dir}
      on_sort="sort"
      page={@page}
      page_size={100}
      total={@total}
      on_page="paginate"
      compact={@compact}
      on_select="sel"
      on_select_all="all"
      selected={@sel}
    >
      <:title>Customers</:title>
      <:col :let={c} label="Name" sort_key="name">{c.name}</:col>
      <:col :let={c} label="Status">
        <.badge>{c.status}</.badge>
      </:col>
      <:action :let={c}>
        <a href={"/edit/" <> to_string(c.id)}>Edit {c.id}</a>
      </:action>
    </.data_table>
    """
  end

  defp t_card(assigns) do
    ~H"""
    <.card_table
      id="ct"
      rows={@rows}
      row_id={fn r -> "row-#{r.id}" end}
      sort_by={@sort_by}
      sort_dir={@sort_dir}
      on_sort="sort"
      selected={@sel}
      on_select="sel"
    >
      <:col :let={c} label="Name" sort_key="name" role="title">{c.name}</:col>
      <:col :let={c} label="Status" role="status">{c.status}</:col>
    </.card_table>
    """
  end

  defp data(n, offset \\ 0),
    do: for(i <- 1..n, do: %{id: i + offset, name: "Customer #{i + offset}", status: "Active"})

  defp base(rows),
    do: %{
      rows: rows,
      sel: [],
      sort_by: nil,
      sort_dir: "asc",
      compact: false,
      variant: nil,
      search: "",
      page: 1,
      total: 300
    }

  defp measure(label, size), do: IO.puts("MEASURE #{label}: #{size}")

  describe "<.table>" do
    test "sorting 100 rows (reverse order) sends the order, not the rows" do
      rows = data(100)
      b = base(rows)
      asc = check(&t_table/1, b, sort_by: "name", sort_dir: "asc", rows: Enum.reverse(rows))
      measure("table sort asc", byte_size(asc))
      assert byte_size(asc) < 3_000

      desc =
        check(
          &t_table/1,
          %{b | sort_by: "name"},
          sort_dir: "desc",
          rows: Enum.reverse(rows)
        )

      measure("table sort desc", byte_size(desc))
      assert byte_size(desc) < 3_000

      # the order alone (the app sorts, the header arrow does not change)
      only = check(&t_table/1, b, rows: Enum.reverse(rows))
      measure("table reorder only", byte_size(only))
      assert byte_size(only) < 3_000

      # the header arrow alone
      arrow = check(&t_table/1, b, sort_by: "name")
      measure("table arrow only", byte_size(arrow))
      assert byte_size(arrow) < 1_500
    end

    test "density sends the table classes once, not every row" do
      b = base(data(100))
      p = check(&t_table/1, b, compact: true)
      measure("table compact", byte_size(p))
      assert byte_size(p) < 4_000
      check(&t_table/1, %{b | compact: true}, compact: false)
      check(&t_table/1, b, variant: "zebra")
    end

    test "page and filter replace the rows" do
      rows = data(100)
      b = base(rows)
      page = check(&t_table/1, b, rows: data(100, 100))
      measure("table page", byte_size(page))
      filtered = check(&t_table/1, b, rows: Enum.take(rows, 10))
      measure("table filter", byte_size(filtered))
      assert byte_size(filtered) < 1_500
    end

    test "without row_id: sort, density, page" do
      rows = data(30)
      b = %{base(rows) | sel: nil}
      check(&t_norid/1, b, sort_by: "name", sort_dir: "desc", rows: Enum.reverse(rows))
      check(&t_norid/1, b, compact: true)
      check(&t_norid/1, b, rows: data(30, 30))
    end

    test "row_groups, details and expand" do
      rows = data(30)
      b = base(rows)
      check(&t_groups/1, b, sort_by: "name", sort_dir: "desc", rows: Enum.reverse(rows))
      check(&t_groups/1, b, compact: true)
      check(&t_groups/1, b, rows: data(30, 30))
    end

    test "selection together with sort, and each source still changes the HTML" do
      rows = data(20)
      b = base(rows)

      check(&t_table/1, %{b | sel: ["row-3"]},
        sel: ["row-3", "row-4"],
        sort_by: "name",
        rows: Enum.reverse(rows)
      )

      each_source(&t_table/1, b,
        sort_by: "name",
        compact: true,
        variant: "zebra",
        rows: Enum.take(rows, 5),
        sel: ["row-2"]
      )
    end
  end

  describe "<.data_table>" do
    test "sort, density, page and search" do
      rows = data(100)
      b = base(rows)
      s = check(&t_dt/1, b, sort_by: "name", sort_dir: "desc", rows: Enum.reverse(rows))
      measure("dt sort", byte_size(s))
      assert byte_size(s) < 3_000
      c = check(&t_dt/1, b, compact: true)
      measure("dt compact", byte_size(c))
      assert byte_size(c) < 4_000
      p = check(&t_dt/1, b, page: 2, rows: data(100, 100))
      measure("dt page", byte_size(p))

      q = check(&t_dt/1, b, search: "Customer 1", rows: Enum.take(rows, 10), total: 10)
      measure("dt search", byte_size(q))
      assert byte_size(q) < 1_500
    end
  end

  describe "<.card_table>" do
    test "sort sends the order, not the rows" do
      rows = data(100)
      b = base(rows)
      s = check(&t_card/1, b, sort_by: "name", sort_dir: "desc", rows: Enum.reverse(rows))
      measure("card sort", byte_size(s))
      assert byte_size(s) < 3_000
      check(&t_card/1, b, sort_by: "name")
      check(&t_card/1, %{b | sel: ["row-2"]}, sort_by: "name", sel: ["row-2", "row-3"])
    end
  end
end
