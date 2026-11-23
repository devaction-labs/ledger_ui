defmodule LedgerUI.Components.CardTableSelectionDiffTest do
  # #70: a change in `selected` alone (plus a row put back in the stream) must not send again the
  # header, the toolbar, the classes of the table or the cells of the other rows. The diff is built
  # like the LiveView does it (`Diff.render/4`): a first render with 25 rows in a stream, then a
  # second one whose `__changed__` names only what a `toggle_select` event changes.
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  alias Phoenix.LiveView.Diff
  alias Phoenix.LiveView.LiveStream

  @rows for i <- 1..25, do: %{id: i, n: "cell-text-#{i}"}

  defp row_key(r), do: to_string(r.id)

  defp t_card(assigns) do
    ~H"""
    <.card_table
      id="c"
      rows={@rows}
      row_key={&row_key/1}
      row_item={&elem(&1, 1)}
      selected={@selected}
      all_selected={@all_selected}
      on_select="s"
      on_select_all="sa"
    >
      <:toolbar>toolbar-marker</:toolbar>
      <:selection :let={s}>selection-marker-{s.count}</:selection>
      <:col :let={r} label="HeaderMarker">{r.n}</:col>
      <:col :let={r} label="Other">other-{r.id}</:col>
      <:action :let={r}>act-{r.id}</:action>
      <:empty>empty-marker</:empty>
    </.card_table>
    """
  end

  defp render(rendered, prints \\ Diff.new_fingerprints(), comps \\ Diff.new_components()),
    do: Diff.render(%Phoenix.LiveView.Socket{}, rendered, prints, comps)

  defp stream(rows), do: LiveStream.new(:rows, 1, rows, [])

  # The JSON of the first render and of the patch of a selection (row 3 checked and put back).
  defp toggle do
    base = %{rows: stream(@rows), selected: [], all_selected: nil}
    {first, prints, comps} = render(t_card(Map.put(base, :__changed__, nil)))

    next = %{
      rows: stream([Enum.at(@rows, 2)]),
      selected: ["3"],
      all_selected: false,
      __changed__: %{rows: true, selected: true, all_selected: true}
    }

    {patch, _, _} = render(t_card(Map.merge(base, next)), prints, comps)
    {Jason.encode!(first), Jason.encode!(patch)}
  end

  test "a selection change does not send again the header, the toolbar, the classes or the cells" do
    {first, patch} = toggle()
    IO.puts("selection diff bytes: #{byte_size(patch)} (first render #{byte_size(first)})")

    assert first =~ "toolbar-marker"
    assert first =~ "HeaderMarker"
    assert first =~ "w-full border-separate"

    refute patch =~ "toolbar-marker"
    refute patch =~ "HeaderMarker"
    refute patch =~ "w-full border-separate"
    refute patch =~ "rounded-xl"

    # Only the reinserted row, with its checkbox checked.
    assert length(Regex.scan(~r/cell-text-\d+/, patch)) == 1
    assert patch =~ "cell-text-3"
    # The row put back knows it is selected: its checkbox now asks to uncheck it.
    assert patch =~ ~r/phx-value-selected=\\+"false/
    assert patch =~ "selection-marker-"
    assert byte_size(patch) * 3 < byte_size(first)
  end
end
