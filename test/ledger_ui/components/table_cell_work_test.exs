defmodule LedgerUI.Components.TableCellWorkTest do
  # The class and the style of a body cell are the same on every row, so `Table.table/1` works them
  # out once per column, not once per cell. The calls are counted with `:erlang.trace_pattern/3`
  # (call counting of the local functions, no tracer process).
  use ExUnit.Case, async: false
  use Phoenix.Component
  use LedgerUI

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LedgerUI.Components.Table

  @rows for i <- 1..60, do: %{id: i, n: "n#{i}"}

  defp rid(r), do: "r#{r.id}"

  defp grid(assigns) do
    ~H"""
    <.table id="t" rows={@rows} row_id={&rid/1} on_select="s" selected={["1"]}>
      <:col :let={r} label="A" width="minmax(120px,1fr)" style="color:red">{r.n}</:col>
      <:col :let={r} label="B" align="right" dim>{r.n}</:col>
      <:col :let={r} label="C" truncate={false}>{r.n}</:col>
      <:action :let={r}>x{r.id}</:action>
    </.table>
    """
  end

  defp calls(fun) do
    :erlang.trace_pattern({Table, fun, :_}, true, [:local, :call_count])
    html = rendered_to_string(grid(%{rows: @rows, __changed__: nil}))

    n =
      for {m, f, a} <- [
            {Table, fun, 1},
            {Table, fun, 2},
            {Table, fun, 3},
            {Table, fun, 4},
            {Table, fun, 5}
          ],
          {:call_count, c} <- [:erlang.trace_info({m, f, a}, :call_count)],
          is_integer(c),
          reduce: 0 do
        acc -> acc + c
      end

    :erlang.trace_pattern({Table, fun, :_}, false, [:local, :call_count])
    {html, n}
  end

  test "td_class and col_style run per column and per table, not per cell" do
    {html, td_calls} = calls(:td_class)
    {_html, style_calls} = calls(:col_style)

    # 60 rows x 5 cells (select box, 3 columns, action); a handful of calls per table, not 300
    assert html =~ "min-width:120px;color:red"
    assert length(String.split(html, ~s(data-part="table-cell"))) - 1 >= 60 * 4
    assert td_calls <= 20, "td_class ran #{td_calls} times"
    assert style_calls <= 3, "col_style ran #{style_calls} times"
  end

  test "every row gets the same class and style on the same column" do
    html = rendered_to_string(grid(%{rows: @rows, __changed__: nil}))

    cells = Regex.scan(~r/<td data-part="table-cell"([^>]*)>/, html)
    per_row = 5
    chunks = cells |> Enum.map(&List.last/1) |> Enum.chunk_every(per_row)
    assert length(chunks) == 60
    assert chunks |> Enum.uniq() |> length() == 1
  end
end
