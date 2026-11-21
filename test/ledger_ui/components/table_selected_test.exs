defmodule LedgerUI.Components.TableSelectedTest do
  # `selected` stays a list in the API; inside, the table tests membership in a `MapSet`.
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  defp render(rows, selected) do
    assigns = %{rows: rows, selected: selected}

    rendered_to_string(~H"""
    <.table
      id="t"
      rows={@rows}
      row_key={& &1.id}
      on_select="s"
      on_select_all="all"
      selected={@selected}
    >
      <:col :let={r} label="N">{r.id}</:col>
    </.table>
    """)
  end

  # [head box, row boxes...]: the `checked` and `data-ind` attributes of each checkbox input
  defp boxes(html) do
    ~r/<input[^>]*type="checkbox"[^>]*>/
    |> Regex.scan(html)
    |> Enum.map(fn [tag] -> {tag =~ ~r/\schecked[\s=>]/, tag =~ "data-ind"} end)
  end

  @rows for i <- 1..4, do: %{id: i}

  test "none selected: nothing checked" do
    assert boxes(render(@rows, [])) == List.duplicate({false, false}, 5)
  end

  test "some selected: the head box is indeterminate, the rows are checked one by one" do
    assert boxes(render(@rows, [2, 4, 99])) ==
             [{false, true}, {false, false}, {true, false}, {false, false}, {true, false}]
  end

  test "all selected (with a repeated key): the head box is checked" do
    assert boxes(render(@rows, [1, 2, 3, 4, 4, 1])) == List.duplicate({true, false}, 5)
  end

  test "keys are matched exactly (1 is not 1.0 nor \"1\")" do
    assert boxes(render(@rows, [1.0, "1"])) == List.duplicate({false, false}, 5)
  end

  test "an empty row list is never all selected" do
    assert render([], [1]) =~ "table"
  end
end
