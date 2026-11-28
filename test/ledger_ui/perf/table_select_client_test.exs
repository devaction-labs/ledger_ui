defmodule LedgerUI.Perf.TableSelectClientTest do
  # `select_sync="client"` (#100): over a stream, a new `selected` sends the list on the <table>
  # and no row. The hook paints the rows from it (test/js/table_select_client_test.mjs).
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import LedgerUI.DiffCase

  defp t_stream(assigns) do
    ~H"""
    <.table
      id="t"
      rows={@rows}
      on_select="sel"
      on_select_all="all"
      selected={@sel}
      all_selected={@all}
      select_sync={@sync}
    >
      <:col :let={{_id, c}} label="Name">{c.name}</:col>
      <:col :let={{_id, c}} label="Status">{c.status}</:col>
      <:action :let={{_id, c}}>
        <a href={"/edit/" <> to_string(c.id)}>Edit {c.id}</a>
      </:action>
    </.table>
    """
  end

  defp t_card(assigns) do
    ~H"""
    <.card_table
      id="c"
      rows={@rows}
      on_select="sel"
      selected={@sel}
      select_sync={@sync}
    >
      <:col :let={{_id, c}} label="Name" role="title">{c.name}</:col>
    </.card_table>
    """
  end

  defp t_list(assigns) do
    ~H"""
    <.table
      id="t"
      rows={@rows}
      row_id={fn r -> "row-#{r.id}" end}
      on_select="sel"
      selected={@sel}
      select_sync={@sync}
    >
      <:col :let={c} label="Name">{c.name}</:col>
    </.table>
    """
  end

  defp data(n), do: for(i <- 1..n, do: %{id: i, name: "Customer #{i}", status: "Active"})
  defp stream(rows), do: Phoenix.LiveView.LiveStream.new(:items, 0, rows, [])
  defp ids(n), do: for(i <- 1..n, do: "items-#{i}")

  defp base(sync, sel \\ []), do: %{rows: stream(data(25)), sel: sel, all: nil, sync: sync}

  defp tag(html, name), do: Regex.run(~r/<#{name}\b[^>]*>/s, html) |> hd()

  test "client mode: marking 1 row, or all, sends no row (< 500 B each)" do
    one = patch(&t_stream/1, base("client"), sel: ["items-3"])
    IO.puts("MEASURE select one, client (#100): #{byte_size(one)}")
    assert byte_size(one) < 500
    refute one =~ "Customer"

    all = patch(&t_stream/1, base("client"), sel: ids(25), all: true)
    IO.puts("MEASURE select all, client (#100): #{byte_size(all)}")
    assert byte_size(all) < 500 + 25 * 12
    refute all =~ "Customer"
  end

  test "server mode: the stream still needs the rows to be inserted again (the cost it avoids)" do
    # the same patch re-sends nothing of the rows, so the box of row 3 would stay unticked
    {_json, html} = first(&t_stream/1, base("server", ["items-3"]))
    assert html =~ ~s(aria-selected="true")
    refute tag(html, "table") =~ "data-lu-selected"
  end

  test "client mode: rows are rendered unticked and the table carries the list" do
    {_json, html} = first(&t_stream/1, base("client", ["items-3", "items-7"]))
    assert tag(html, "table") =~ ~s(data-lu-selected="[&quot;items-3&quot;,&quot;items-7&quot;]")
    refute html =~ ~s(aria-selected="true")
    refute html =~ ~r/<input[^>]*\schecked(\s|>|=)/
    assert html =~ ~s(phx-value-selected="true")
  end

  test "client mode on a list and on card_table" do
    rows = data(5)
    {_json, html} = first(&t_list/1, %{rows: rows, sel: ["row-2"], sync: "client"})
    assert tag(html, "table") =~ "data-lu-selected"
    refute html =~ ~s(aria-selected="true")

    one = patch(&t_list/1, %{rows: rows, sel: [], sync: "client"}, sel: ["row-2"])
    refute one =~ "Customer"

    {_json, html} = first(&t_card/1, %{rows: stream(rows), sel: ["items-2"], sync: "client"})
    assert html =~ "data-lu-selected"
    refute html =~ ~s(aria-selected="true")
  end

  test "default (server): no data-lu-selected, HTML as before" do
    {_json, html} = first(&t_list/1, %{rows: data(3), sel: ["row-2"], sync: "server"})
    refute html =~ "data-lu-selected"
    assert html =~ ~s(aria-selected="true")
  end
end
