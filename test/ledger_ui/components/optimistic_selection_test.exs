defmodule LedgerUI.Components.OptimisticSelectionTest do
  # #73: the markup the optimistic selection hooks read.
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI
  import Phoenix.LiveViewTest

  @rows [%{id: 1, n: "a"}, %{id: 2, n: "b"}]

  defp table_html(extra) do
    assigns = %{rows: @rows, extra: extra}

    rendered_to_string(~H"""
    <.card_table
      id="t"
      rows={@rows}
      row_key={&to_string(&1.id)}
      selected={["2"]}
      on_select={@extra[:on_select]}
      on_select_all={@extra[:on_select_all]}
    >
      <:col :let={r} label="N">{r.n}</:col>
    </.card_table>
    """)
  end

  test "a table with selection carries the hook, the data attrs and aria-selected on rows" do
    html = table_html(on_select: "s", on_select_all: "sa")
    assert html =~ ~s(phx-hook="LedgerUI.TableSelect")
    assert html =~ "data-lu-select"
    assert html =~ ~r/data-lu-sel-class="[^"]+"/
    assert html =~ ~s(aria-selected="true")
    assert html =~ ~s(aria-selected="false")
  end

  test "a table without selection is unchanged" do
    html = table_html([])
    refute html =~ "TableSelect"
    refute html =~ "data-lu-select"
    refute html =~ "aria-selected"
  end

  test "bulk_bar for: always rendered, hidden at zero, with the hook and the labels" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.bulk_bar id="b" for="t" count={0} label="item" label_plural="items" />|
      )

    assert html =~ ~s(phx-hook="LedgerUI.BulkBar")
    assert html =~ ~s(data-lu-for="t")
    assert html =~ ~s(data-lu-count="0")
    assert html =~ ~s(data-lu-one="item")
    assert html =~ ~s(data-lu-many="items")
    assert html =~ "hidden"
    assert html =~ "data-lu-empty"
  end

  test "bulk_bar for: visible with a count, and every look carries the link" do
    for v <- ~w(inverse inline float) do
      assigns = %{v: v}

      html =
        rendered_to_string(~H|<.bulk_bar id="b" for="t" count={2} variant={@v} label="item" />|)

      assert html =~ ~s(data-lu-count="2"), v
      refute html =~ "data-lu-empty", v
      refute html =~ ~r/\shidden[\s>=]/, v
    end
  end

  test "bulk_bar without for is unchanged" do
    assigns = %{}
    html = rendered_to_string(~H|<.bulk_bar id="b" count={2} label="item" />|)
    refute html =~ "data-lu-"
    refute html =~ "phx-hook"
  end
end
