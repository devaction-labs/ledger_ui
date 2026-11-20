defmodule LedgerUI.Components.DataTableTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.DataTable

  test "advanced card with footer and pager" do
    assigns = %{rows: [%{n: "a"}]}

    html =
      rendered_to_string(~H|<.data_table
  id="d"
  rows={@rows}
  total={100}
  page={2}
  page_size={10}
  on_page="go"
  on_search="q"
  pager="pill"
>
  <:title>Users</:title>
  <:col :let={r} label="N">{r.n}</:col>
</.data_table>|)

    assert html =~ ~s(data-part="data-table-header")
    assert html =~ "11 - 20 of 100 entries"
    assert html =~ "bg-accent-600"
    assert html =~ ~s(data-part="data-table-pager")
    assert html =~ "phx-value-page=\"3\""
    assert html =~ "d-search-form"
  end

  test "grid variant summary" do
    assigns = %{rows: []}

    html =
      rendered_to_string(
        ~H|<.data_table id="g" variant="grid" rows={@rows} total={15} on_page="go">
  <:col label="N">x</:col>
</.data_table>|
      )

    assert html =~ "[--tbr:1px_solid_var(--lu-line)]"
    assert html =~ "Showing 1 to 10 of 15 results"
  end

  test "pager gaps and pages shape" do
    assigns = %{}
    html = rendered_to_string(~H|<.data_table_pager page={5} pages={20} />|)
    assert html =~ "…"
    html = rendered_to_string(~H|<.data_table_pager page={1} pages={3} shape="pages" />|)
    assert html =~ "tabular-nums"
    assert html =~ ~s(aria-current="page")

    links =
      rendered_to_string(~H|<.data_table_pager page={2} pages={3} page_path={&"/p/#{&1}"} />|)

    assert links =~ ~s(href="/p/3")
  end

  test "toolbar chips" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.table_toolbar filters={[%{id: "a", label: "A"}]} on_clear="c" on_remove_filter="r" />|
      )

    assert html =~ ~s(data-part="table-filter-chip")
    assert html =~ "Limpar tudo"
  end
end
