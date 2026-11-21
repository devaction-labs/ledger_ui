defmodule LedgerUI.Components.TableTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Table

  test "rows mode with sorting, selection and alignment" do
    assigns = %{rows: [%{id: 1, n: "a"}, %{id: 2, n: "b"}]}

    html =
      rendered_to_string(~H|<.table
  id="t"
  rows={@rows}
  variant="zebra"
  rounded="top"
  on_sort="sort"
  sort_by="n"
  on_select="sel"
  on_select_all="all"
  selected={[1]}
  row_key={& &1.id}
>
  <:col :let={r} label="N" sort_key="n" align="right">{r.n}</:col>
</.table>|)

    assert html =~ ~s(data-part="table")
    assert html =~ "[--z:color-mix"
    assert html =~ "[&amp;_thead_th]:bg-sunken"
    assert html =~ "text-right tabular-nums"
    assert html =~ "cursor-pointer"
    assert html =~ "aria-sort=\"ascending\""
    assert html =~ "phx-value-direction=\"desc\""
    assert html =~ "[--s:color-mix"
    assert html =~ "checked"
    assert html =~ "data-ind=\"1\""
  end

  test "priority columns add a scoped container query" do
    assigns = %{rows: [%{n: 1}]}

    html =
      rendered_to_string(~H|<.table id="p" rows={@rows}>
  <:col :let={r} label="N" priority={2}>{r.n}</:col>
</.table>|)

    assert html =~ "@container"
    assert html =~ "@max-[560px]:hidden"
    refute html =~ "<style"

    assert_raise ArgumentError, ~r/not supported/, fn ->
      rendered_to_string(~H|<.table id="p" rows={@rows} breakpoints={[701]}>
  <:col :let={r} label="N" priority={1}>{r.n}</:col>
</.table>|)
    end
  end

  test "empty slot and expandable rows" do
    assigns = %{}
    html = rendered_to_string(~H|<.table id="e" rows={[]}>
  <:col label="N">x</:col><:empty>none</:empty>
</.table>|)
    assert html =~ "none"
    assigns = %{rows: [%{n: 1}]}

    html =
      rendered_to_string(~H|<.table id="x" rows={@rows} row_id={&"r#{&1.n}"}>
  <:col :let={r} label="N">{r.n}</:col><:expand :let={c}>detail {c.row.n}</:expand>
</.table>|)

    assert html =~ "r1-detail"
    assert html =~ "display:none"
  end

  test "hand written table" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.table id="h">
  <.table_head on_select_all="all">
    <:col sort_key="a">A</:col>
  </.table_head>
  <.table_body>
    <.table_row selected on_select="s" select_value={1}>
      <:cell align="right">1</:cell>
    </.table_row>
  </.table_body>
  <.table_foot>
    <:cell>T</:cell>
  </.table_foot>
</.table>|)

    assert html =~ "cursor-pointer"
    assert html =~ "[--s:color-mix"
    assert html =~ "<tfoot"
    assert html =~ "text-right tabular-nums"
  end

  test "skeleton" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.table_skeleton id="s" rows={2} columns={~w(A B)} shapes={["avatar"]} />|
      )

    assert html =~ "aria-busy"
    assert html =~ "animate-[lu-shim_1.4s_linear_infinite]"
  end

  test "only the sorted column's arrow shows; the others on hover" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.table id="t" rows={[%{a: 1}]} sort_by="a" on_sort="s">
        <:col :let={r} label="A" sort_key="a">{r.a}</:col>
        <:col :let={r} label="B" sort_key="b">{r.a}</:col>
      </.table>
      """)

    assert html =~ "group-hover/th:opacity-100"
    assert length(String.split(html, "group-hover/th:opacity-100")) == 2
  end
end
