defmodule LedgerUI.Perf.TableCheckboxLiteralTest do
  # The box of a body row (`middle`, no `class`) is a literal of the template: a new row sends its
  # dynamic values only, not the 1.4 KB class of the `<input>` (#93).
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import LedgerUI.DiffCase
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LedgerUI.Components.Checkbox

  defp t_table(assigns) do
    ~H"""
    <.table
      id="t"
      rows={@rows}
      row_id={fn r -> "row-#{r.id}" end}
      sort_by="name"
      on_select="sel"
      on_select_all="all"
      selected={@sel}
    >
      <:col :let={c} label="Name">{c.name}</:col>
      <:col :let={c} label="Status">
        <.badge>{c.status}</.badge>
      </:col>
      <:action :let={c}>
        <a href={"/edit/" <> to_string(c.id)}>Edit {c.id}</a>
      </:action>
    </.table>
    """
  end

  defp data(n, offset \\ 0),
    do: for(i <- 1..n, do: %{id: i + offset, name: "Customer #{i + offset}", status: "Active"})

  defp box(assigns), do: assigns |> table_box() |> rendered_to_string()

  defp table_box(assigns) do
    ~H"""
    <.table_checkbox {@attrs} label="L" />
    """
  end

  defp norm(html), do: html |> String.replace("&#39;", "'") |> String.trim()

  test "page change of 100 rows with selection is at most 120 KB" do
    b = %{rows: data(100), sel: []}
    page = check(&t_table/1, b, rows: data(100, 100))
    IO.puts("MEASURE table page (#93): #{byte_size(page)}")
    assert byte_size(page) <= 120_000
  end

  test "one changed row stays small" do
    rows = data(100)
    b = %{rows: rows, sel: []}
    one = check(&t_table/1, b, rows: List.update_at(rows, 5, &%{&1 | name: "Other"}))
    IO.puts("MEASURE table one row (#93): #{byte_size(one)}")
    assert byte_size(one) < 600
    sel = check(&t_table/1, b, sel: ["row-3"])
    assert byte_size(sel) < 600
  end

  test "the literal renders like the dynamic path and follows the theme" do
    literal = box(%{attrs: %{middle: true, id: nil, checked: true}})
    dynamic = box(%{attrs: %{middle: true, id: nil, checked: true, class: false}})
    assert norm(literal) == norm(dynamic)

    input_class =
      "checkbox"
      |> Checkbox.input_class("md", "square", false, false)
      |> List.flatten()
      |> Enum.filter(& &1)
      |> Enum.join(" ")

    assert norm(literal) =~ ~s(class="#{input_class}")
  end

  test "with a class or without middle the dynamic path is kept" do
    assert box(%{attrs: %{middle: true, class: "x-extra"}}) =~ "x-extra"
    refute box(%{attrs: %{middle: false}}) =~ "align-middle"
  end
end
