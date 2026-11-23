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

  describe "cell classes live on the table (#25)" do
    defp cells_table(extra \\ []) do
      assigns = %{rows: for(i <- 1..3, do: %{id: i, a: "a#{i}", b: "b#{i}"}), extra: extra}

      rendered_to_string(~H"""
      <.table id="t" rows={@rows} {@extra}>
        <:col :let={r} label="A" class="font-mono">{r.a}</:col>
        <:col :let={r} label="B" align="right">{r.b}</:col>
        <:foot>f</:foot>
      </.table>
      """)
    end

    test "the shared td/th classes are on the <table> once, not on each cell" do
      html = cells_table()
      table_tag = hd(Regex.run(~r/<table[^>]*>/, html))
      assert table_tag =~ "py-[var(--td-py,12px)]"
      assert table_tag =~ "[border-bottom:var(--tbb,1px_solid_var(--lu-line))]"
      refute table_tag =~ "uppercase"
      refute table_tag =~ "tracking-"
      assert table_tag =~ "text-[length:var(--th-fs,12.5px)]"

      # a body cell keeps only what varies
      assert html =~ ~s(<td data-part="table-cell" class="whitespace-nowrap font-mono">)
      assert html =~ ~s(class="text-right tabular-nums whitespace-nowrap")

      # the cells (not the table) carry no long shared class
      body = html |> String.split("<tbody") |> Enum.at(1) |> String.split("<tfoot") |> hd()
      refute body =~ "var(--td-py"
      refute body =~ "var(--tbb"
      assert html |> String.split("var(--td-py,12px)") |> length() == 3
    end

    test "the totals row (tfoot) and the hand-written table keep the cell classes" do
      assert cells_table() =~ ~r/<tfoot>.*?py-\[var\(--td-py,12px\)\].*?border-t/s

      assigns = %{}

      hand =
        rendered_to_string(~H"""
        <.table id="h">
          <.table_head><:col label="A" /></.table_head>
          <.table_body>
            <.table_row>
              <:cell>x</:cell>
            </.table_row>
          </.table_body>
        </.table>
        """)

      assert hand =~ "py-[var(--td-py,12px)]"
      refute hand =~ "[:where(&amp;&gt;tbody"
    end

    test "a cell's html no longer grows with the shared classes" do
      assigns = %{rows: for(i <- 1..50, do: %{id: i, c: for(j <- 1..8, do: "v#{j}")})}

      html =
        rendered_to_string(~H"""
        <.table id="t" rows={@rows}>
          <:col :let={r} :for={j <- 0..7} label={"C#{j}"}>{Enum.at(r.c, j)}</:col>
        </.table>
        """)

      assert byte_size(html) < 90_000
    end

    test "the last row drops its border from the table, once" do
      assert cells_table() =~ esc("[&>tbody>tr:last-child>td]:[border-bottom:0_none]")
    end

    defp esc(s), do: s |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
  end

  test "bleed drops the box and pads the end cells by the card padding" do
    assigns = %{rows: [%{id: 1, n: "a"}]}

    html =
      rendered_to_string(~H|<.table id="b" rows={@rows} bleed>
  <:col :let={r} label="N">{r.n}</:col>
</.table>|)

    assert html =~ "pl-[var(--card-p,16px)]"
    assert html =~ "pr-[var(--card-p,16px)]"
    refute html =~ "rounded-lg border border-line bg-panel"

    plain = rendered_to_string(~H|<.table id="b" rows={@rows}>
  <:col :let={r} label="N">{r.n}</:col>
</.table>|)

    refute plain =~ "--card-p"
    assert plain =~ "rounded-lg border border-line bg-panel"
  end

  describe "column sizing: grow, wrap, min" do
    defp sizing_html(cols_html) do
      assigns = %{rows: [%{n: 1}]}

      case cols_html do
        :none ->
          rendered_to_string(~H|<.table id="s" rows={@rows}>
  <:col :let={r} label="A">{r.n}</:col>
  <:col :let={r} label="B">{r.n}</:col>
</.table>|)

        :one ->
          rendered_to_string(~H|<.table id="s" rows={@rows}>
  <:col :let={r} label="A" grow={1}>{r.n}</:col>
  <:col :let={r} label="B">{r.n}</:col>
</.table>|)

        :weights ->
          rendered_to_string(~H|<.table id="s" rows={@rows}>
  <:col :let={r} label="A" grow={2}>{r.n}</:col>
  <:col :let={r} label="B" grow={1}>{r.n}</:col>
  <:col :let={r} label="C">{r.n}</:col>
</.table>|)

        :truncate ->
          rendered_to_string(~H|<.table id="s" rows={@rows}>
  <:col :let={r} label="A" grow={1} wrap="truncate" min="12rem">{r.n}</:col>
</.table>|)

        :never ->
          rendered_to_string(~H|<.table id="s" rows={@rows}>
  <:col :let={r} label="A" grow={1} wrap="never">{r.n}</:col>
</.table>|)

        :auto ->
          rendered_to_string(~H|<.table id="s" rows={@rows}>
  <:col :let={r} label="A" wrap="auto">{r.n}</:col>
</.table>|)

        :width ->
          rendered_to_string(~H|<.table id="s" rows={@rows}>
  <:col :let={r} label="A" width="max-content" grow={1} wrap="auto" min="9rem">{r.n}</:col>
</.table>|)

        :card ->
          rendered_to_string(~H|<.table id="s" rows={@rows} card_below={640}>
  <:col :let={r} label="A" role="title" grow={1} min="12rem">{r.n}</:col>
  <:col :let={r} label="B" role="value">{r.n}</:col>
</.table>|)
      end
    end

    test "without the attrs nothing is added" do
      html = sizing_html(:none)
      assert html =~ ~s(<td data-part="table-cell" class="whitespace-nowrap">)
      refute html =~ ~s(<td data-part="table-cell" class="w-full)
      refute html =~ "--cmin"
      refute html =~ "--gt"
    end

    test "the only growing column takes the free width and wraps when it must" do
      html = sizing_html(:one)
      assert html =~ ~s(class="whitespace-normal w-full")
      refute html =~ "--gt"
    end

    test "several growing columns share by weight" do
      html = sizing_html(:weights)
      assert html =~ "w-[calc(100%*var(--g)/var(--gt))]"
      assert html =~ "--g:2;--gt:3"
      assert html =~ "--g:1;--gt:3"
    end

    test "wrap never, truncate and auto" do
      refute sizing_html(:never) =~ "whitespace-normal"
      assert sizing_html(:never) =~ ~s(class="whitespace-nowrap w-full")

      html = sizing_html(:truncate)
      assert html =~ "max-w-0 overflow-hidden text-ellipsis whitespace-nowrap"
      assert html =~ "min-w-[var(--cmin)]"
      assert html =~ "--cmin:12rem"

      assert sizing_html(:auto) =~ "whitespace-normal"
    end

    test "width wins over grow, wrap and min" do
      html = sizing_html(:width)
      refute html =~ ~s(<td data-part="table-cell" class="w-full)
      refute html =~ "whitespace-normal"
      refute html =~ "--cmin"
      assert html =~ "whitespace-nowrap"
    end

    test "the card layout keeps its own width and min width classes after the sizing ones" do
      html = sizing_html(:card)
      assert html =~ "w-full"
      assert html =~ "@max-[640px]:w-auto"
      assert html =~ "@max-[640px]:min-w-0"
      assert html =~ "min-w-[var(--cmin)]"
    end
  end
end
