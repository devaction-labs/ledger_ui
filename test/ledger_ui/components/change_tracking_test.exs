defmodule LedgerUI.Components.ChangeTrackingTest do
  # A re-render that changes one assign must not send again what does not depend on it. The diff
  # is built the way the LiveView does it (`Phoenix.LiveView.Diff.render/4`) for a first render and
  # for a second one whose `__changed__` names only the assign that changed; the patch is then
  # searched for the cell texts of the rows. Spreading `{assigns}` into a child component (the
  # data table body, the card table content, the menu row body, the tree row) turns that
  # tracking off: the child gets every dynamic marked as changed.
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  alias Phoenix.LiveView.Diff

  @rows for i <- 1..20, do: %{id: i, n: "cell-text-#{i}", a: "amount-#{i}"}

  defp row_id(r), do: "r#{r.id}"
  defp row_key(r), do: to_string(r.id)

  defp t_data(assigns) do
    ~H"""
    <.data_table
      id="d"
      rows={@rows}
      row_id={&row_id/1}
      row_key={&row_key/1}
      search={@search}
      on_search="se"
      page={@page}
      page_size={20}
      total={100}
      on_page="pg"
      selected={@selected}
      on_select="s"
    >
      <:title>People</:title>
      <:col :let={r} label="Name">{r.n}</:col>
      <:col :let={r} label="Amount">{r.a}</:col>
      <:action :let={r}>act-{r.id}</:action>
    </.data_table>
    """
  end

  defp t_card(assigns) do
    ~H"""
    <.card_table
      id="c"
      rows={@rows}
      row_id={&row_id/1}
      row_key={&row_key/1}
      description={@description}
      selected={@selected}
      on_select="s"
    >
      <:col :let={r} label="Name">{r.n}</:col>
      <:col :let={r} label="Amount">{r.a}</:col>
    </.card_table>
    """
  end

  defp t_row(assigns) do
    ~H"""
    <.menu_row title="Title" unread={@unread}>
      <:icon>icon-markup</:icon>
      <:value>value-markup</:value>
      body-markup-{@body}
    </.menu_row>
    """
  end

  # The JSON of the first render and of the patch after `change`.
  defp patch(fun, base, change) do
    {first, prints, comps} = render(fun.(Map.put(base, :__changed__, nil)))

    changed = Map.new(change, fn {k, _} -> {k, true} end)

    {patch, _, _} =
      render(
        fun.(base |> Map.merge(change) |> Map.put(:__changed__, changed)),
        prints,
        comps
      )

    {Jason.encode!(first), Jason.encode!(patch)}
  end

  defp render(rendered, prints \\ Diff.new_fingerprints(), comps \\ Diff.new_components()),
    do: Diff.render(%Phoenix.LiveView.Socket{}, rendered, prints, comps)

  defp rows_in(json), do: length(Regex.scan(~r/cell-text-\d+/, json))

  @base %{rows: @rows, search: "", page: 1, selected: [], description: "d", unread: false}

  test "data_table: a new search or page does not send the rows again" do
    for change <- [%{search: "x"}, %{page: 2}] do
      {first, patch} = patch(&t_data/1, @base, change)
      assert rows_in(first) == 20
      assert rows_in(patch) == 0
      assert byte_size(patch) * 20 < byte_size(first)
    end
  end

  test "data_table: a new selection still re-renders the rows (the checkboxes change)" do
    {_first, patch} = patch(&t_data/1, @base, %{selected: ["3"]})
    assert rows_in(patch) == 20
  end

  test "card_table: a new description does not send the rows again" do
    {first, patch} = patch(&t_card/1, @base, %{description: "other"})
    assert rows_in(first) == 20
    assert rows_in(patch) == 0
    assert byte_size(patch) * 20 < byte_size(first)
  end

  test "menu_row: a new `unread` does not send the slots again" do
    {first, patch} = patch(&t_row/1, Map.put(@base, :body, "b"), %{unread: true})
    assert first =~ "value-markup"
    refute patch =~ "value-markup"
    refute patch =~ "icon-markup"
    refute patch =~ "Title"
  end
end
