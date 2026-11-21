defmodule LedgerUI.Components.TableRowGroupsTest do
  # #24: a stream with `:expand`/`:detail` gets one <tbody> per row.
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Table
  import LedgerUI.Components.CardTable, only: [card_table: 1]
  import LedgerUI.Components.DataTable, only: [data_table: 1]

  defp stream,
    do: Phoenix.LiveView.LiveStream.new(:items, 0, [%{id: 1, n: "a"}, %{id: 2, n: "b"}], [])

  # the markup is HTML-escaped (`>` and `&` inside class names)
  defp esc(s), do: s |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

  defp count(html, tag), do: length(String.split(html, "<#{tag}")) - 1

  test "a stream with :expand: a tbody per item, phx-update on the table" do
    assigns = %{rows: stream()}

    html =
      rendered_to_string(~H"""
      <.table id="t" rows={@rows} variant="zebra">
        <:col :let={{_id, r}} label="N">{r.n}</:col>
        <:expand :let={%{row: {_id, r}}}>detail {r.n}</:expand>
      </.table>
      """)

    assert html =~ ~r/<table id="t"[^>]*phx-update="stream"/
    assert html =~ ~s(<tbody id="items-1" data-part="table-row-group")
    assert html =~ ~s(<tbody id="items-2" data-part="table-row-group")
    assert html =~ ~s(<tr id="items-1-row" data-part="table-row")
    assert html =~ ~s(id="items-1-detail")
    assert html =~ ~s(<thead id="t-head")
    refute html =~ ~s(id="t-body")
    assert count(html, "tbody") == 2
    # zebra counts items, last row drops its own border
    assert html =~ esc("[&_tbody:nth-of-type(even)>tr:first-child]")
    refute html =~ esc("[&_tbody_tr:nth-child(even)]")
    assert html =~ esc("[&>tbody:last-of-type>tr:last-child>td]:[border-bottom:0_none]")
    refute html =~ esc("[tr:last-child>&]")
  end

  test "the detail row sits inside the tbody of its item" do
    assigns = %{rows: stream()}

    html =
      rendered_to_string(~H"""
      <.table id="t" rows={@rows}>
        <:col :let={{_id, r}} label="N">{r.n}</:col>
        <:expand :let={%{row: {_id, r}}}>detail {r.n}</:expand>
      </.table>
      """)

    [first | _] = String.split(html, ~s(<tbody id="items-2"))
    [_, group] = String.split(first, ~s(<tbody id="items-1"))
    assert group =~ ~s(data-part="table-row")
    assert group =~ ~s(data-part="table-detail-row")
    assert group =~ "</tbody>"
  end

  test "a stream with the details panel: hook on the table, panel row in the item tbody" do
    assigns = %{rows: stream()}

    html =
      rendered_to_string(~H"""
      <.table id="t" rows={@rows} details>
        <:col :let={{_id, r}} label="N">{r.n}</:col>
        <:detail :let={{_id, r}} label="Name">{r.n}</:detail>
      </.table>
      """)

    assert html =~ ~r/<table id="t"[^>]*phx-hook="LedgerUI.CardTable"/
    refute html =~ ~r/<tbody[^>]*phx-hook/
    assert html =~ ~s(id="items-1-panel")
    assert html =~ ~s(aria-controls="items-1-panel")
  end

  test "an empty stream: the empty row has a tbody of its own" do
    assigns = %{rows: Phoenix.LiveView.LiveStream.new(:items, 0, [], [])}

    html =
      rendered_to_string(~H"""
      <.table id="t" rows={@rows}>
        <:col :let={{_id, r}} label="N">{r.n}</:col>
        <:expand :let={%{row: {_id, r}}}>d {r.n}</:expand>
        <:empty>nothing</:empty>
        <:foot>f</:foot>
      </.table>
      """)

    assert html =~
             ~s(<tbody id="t-empty-stream" data-part="table-row-group" class="not-only-of-type:hidden")

    assert html =~ ~s(<tfoot id="t-foot")
  end

  test "row_groups={false} keeps the single tbody; without expand a stream keeps it too" do
    assigns = %{rows: stream()}

    html =
      rendered_to_string(~H"""
      <.table id="t" rows={@rows} row_groups={false}>
        <:col :let={{_id, r}} label="N">{r.n}</:col>
        <:expand :let={%{row: {_id, r}}}>d {r.n}</:expand>
      </.table>
      """)

    assert html =~ ~s(<tbody data-part="table-body" id="t-body")
    assert html =~ ~s(phx-update="stream")
    assert html =~ ~s(<tr id="items-1" data-part="table-row")

    plain =
      rendered_to_string(~H"""
      <.table id="t" rows={@rows}>
        <:col :let={{_id, r}} label="N">{r.n}</:col>
      </.table>
      """)

    assert plain =~ ~s(<tbody data-part="table-body" id="t-body")
    refute plain =~ "table-row-group"
    refute plain =~ ~s(id="t-head")
  end

  test "a list with :expand is unchanged; row_groups={true} forces the layout" do
    assigns = %{rows: [%{id: 1, n: "a"}, %{id: 2, n: "b"}]}

    list =
      rendered_to_string(~H"""
      <.table id="t" rows={@rows}>
        <:col :let={r} label="N">{r.n}</:col>
        <:expand :let={%{row: r}}>d {r.n}</:expand>
      </.table>
      """)

    assert count(list, "tbody") == 1
    refute list =~ "table-row-group"
    assert list =~ esc("[&>tbody>tr:last-child>td]:[border-bottom:0_none]")
    refute list =~ esc("[&>tbody:last-of-type>tr:last-child>td]")

    forced =
      rendered_to_string(~H"""
      <.table id="t" rows={@rows} row_groups>
        <:col :let={r} label="N">{r.n}</:col>
        <:expand :let={%{row: r}}>d {r.n}</:expand>
      </.table>
      """)

    assert count(forced, "tbody") == 2
    refute forced =~ ~s(phx-update="stream")
  end

  test "card layout: the row separator is dropped only on the last row of the last tbody" do
    assigns = %{rows: stream()}

    html =
      rendered_to_string(~H"""
      <.card_table id="c" rows={@rows} row_expanded={fn _ -> true end}>
        <:col :let={{_id, r}} label="N" role="head">{r.n}</:col>
        <:expand :let={{_id, r}}>d {r.n}</:expand>
      </.card_table>
      """)

    assert html =~ esc("@max-[520px]:[tbody:last-of-type>&:last-child]:border-b-0")
    refute html =~ "@max-[520px]:last:border-b-0"
    assert html =~ ~s(<tbody id="items-1")
    assert html =~ ~s(role="rowgroup")
  end

  test "data_table forwards row_groups; a stream with :expand turns it on" do
    assigns = %{rows: stream()}

    html =
      rendered_to_string(~H"""
      <.data_table id="d" rows={@rows}>
        <:col :let={{_id, r}} label="N">{r.n}</:col>
        <:expand :let={%{row: {_id, r}}}>d {r.n}</:expand>
      </.data_table>
      """)

    assert html =~ ~s(<tbody id="items-1" data-part="table-row-group")

    off =
      rendered_to_string(~H"""
      <.data_table id="d" rows={@rows} row_groups={false}>
        <:col :let={{_id, r}} label="N">{r.n}</:col>
        <:expand :let={%{row: {_id, r}}}>d {r.n}</:expand>
      </.data_table>
      """)

    refute off =~ "table-row-group"
  end
end
