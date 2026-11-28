defmodule LedgerUI.Perf.TableRootTest do
  # A row of `<.table>` has ONE static root tag where it can (#127): the `<tr>`, or the `<tbody>`
  # with `row_groups`. The LiveView marks such a component as a root (`"r":1` in the diff) and the
  # client skips it when it did not change, instead of building and morphing every row. A row with
  # a panel or a detail row outside `row_groups` is several `<tr>` side by side and has no root.
  # What can be checked here is the shape of the diff: one changed row does not resend the others.
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import LedgerUI.DiffCase

  defp t_plain(assigns) do
    ~H"""
    <.table
      id="t"
      rows={@rows}
      row_id={fn r -> "row-#{r.id}" end}
      on_select="sel"
      on_select_all="all"
      selected={@sel}
      row_editing={fn r -> r.id == @eid end}
    >
      <:col :let={c} label="Name">{c.name}</:col>
      <:col :let={c} label="Status">{c.status}</:col>
      <:action :let={c}>
        <a href={"/edit/" <> to_string(c.id)}>Edit {c.id}</a>
      </:action>
      <:edit :let={c}>editing {c.name}</:edit>
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
      on_select="sel"
      selected={@sel}
    >
      <:col :let={c} label="Name">{c.name}</:col>
      <:detail :let={c} label="Status">{c.status}</:detail>
      <:expand :let={%{row: c}}>more {c.name}</:expand>
    </.table>
    """
  end

  defp t_panel(assigns) do
    ~H"""
    <.table id="t" rows={@rows} row_id={fn r -> "row-#{r.id}" end} details selected={@sel}>
      <:col :let={c} label="Name">{c.name}</:col>
      <:detail :let={c} label="Status">{c.status}</:detail>
    </.table>
    """
  end

  defp t_expand(assigns) do
    ~H"""
    <.table id="t" rows={@rows} row_id={fn r -> "row-#{r.id}" end}>
      <:col :let={c} label="Name">{c.name}</:col>
      <:expand :let={%{row: c}}>more {c.name}</:expand>
    </.table>
    """
  end

  defp data(n),
    do: for(i <- 1..n, do: %{id: i, name: "Customer #{i}", status: "Active"})

  defp base(rows), do: %{rows: rows, sel: [], eid: nil}

  defp roots(json), do: json |> String.split(~s("r":1)) |> length() |> Kernel.-(1)

  defp rename(rows, i), do: List.update_at(rows, i, &%{&1 | name: "Renamed"})

  describe "rows with a single root" do
    test "plain rows with selection: each row is a root, one changed row sends one row" do
      rows = data(100)
      b = base(rows)
      {json, _html} = first(&t_plain/1, b)
      assert roots(json) >= 100

      one = check(&t_plain/1, b, rows: rename(rows, 40))
      IO.puts("MEASURE root one row (#127): #{byte_size(one)}")
      assert byte_size(one) < 700
      assert one =~ "Renamed"
      refute one =~ "Customer"

      each_source(&t_plain/1, b, rows: rename(rows, 3), sel: ["row-2"], eid: 5)
      check(&t_plain/1, %{b | eid: 5}, eid: nil)
    end

    test "row_groups: each row is one <tbody> root with its panel and detail" do
      rows = data(100)
      b = base(rows)
      {json, _html} = first(&t_groups/1, b)
      assert roots(json) >= 100

      one = check(&t_groups/1, b, rows: rename(rows, 40))
      IO.puts("MEASURE root groups one row (#127): #{byte_size(one)}")
      assert byte_size(one) < 1_200
      refute one =~ "Customer"
      each_source(&t_groups/1, b, rows: rename(rows, 3), sel: ["row-2"])
    end
  end

  describe "rows without a single root (panel or detail row outside row_groups)" do
    test "panel" do
      rows = data(30)
      b = base(rows)
      one = check(&t_panel/1, b, rows: rename(rows, 10))
      refute one =~ "Customer"
      each_source(&t_panel/1, b, rows: rename(rows, 3), sel: ["row-2"])
    end

    test "expand" do
      rows = data(30)
      b = base(rows)
      one = check(&t_expand/1, b, rows: rename(rows, 10))
      refute one =~ "Customer"
    end
  end
end
