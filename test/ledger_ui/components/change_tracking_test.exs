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

  @nav [
    %{
      group: "Main",
      items: for(i <- 1..8, do: %{label: "item-label-#{i}", href: "/i#{i}", icon: "home"})
    }
  ]
  @cmd_items for i <- 1..10, do: %{label: "cmd-label-#{i}", icon: "search"}
  @notifs for i <- 1..5,
              do: %{id: "n#{i}", text: "notif-title-#{i}", read: false}

  defp t_sidebar(assigns) do
    ~H"""
    <.sidebar id="sb" nav={@nav} current="/i3" collapsed={@collapsed} class={@class}>
      <:sidebar_footer>footer-markup-{@mark}</:sidebar_footer>
    </.sidebar>
    """
  end

  defp t_header(assigns) do
    ~H"""
    <.header id="h" class={@class}>
      <:actions>actions-markup-{@mark}</:actions>
      <:search_results>results-markup-{@mark}</:search_results>
      <:profile>profile-markup-{@mark}</:profile>
    </.header>
    """
  end

  defp t_palette(assigns) do
    ~H"""
    <.command_palette id="cp" items={@cmd_items} open={@open}>
      <:footer>palette-footer-{@mark}</:footer>
    </.command_palette>
    """
  end

  defp t_notifs(assigns) do
    ~H"""
    <.notification_center id="nc" items={@notifs} open={@open} />
    """
  end

  defp t_drop(assigns) do
    ~H"""
    <.upload_drop over={@over} hint={"drop-hint-markup-" <> @mark}>
      <:label>drop-label-markup-{@mark}</:label>
    </.upload_drop>
    """
  end

  defp t_chart(assigns) do
    ~H"""
    <.chart id="ch" options={@options} class={@class} />
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

  @base %{
    rows: @rows,
    search: "",
    page: 1,
    selected: [],
    description: "d",
    unread: false,
    nav: @nav,
    cmd_items: @cmd_items,
    notifs: @notifs,
    collapsed: false,
    class: "a",
    mark: "m",
    open: false,
    over: false,
    options: %{series: [%{data: for(i <- 1..50, do: [i, i * 7])}]}
  }

  test "data_table: a new search or page does not send the rows again" do
    for change <- [%{search: "x"}, %{page: 2}] do
      {first, patch} = patch(&t_data/1, @base, change)
      assert rows_in(first) == 20
      assert rows_in(patch) == 0
      # the first render shrank (#93), so the bound is absolute: only the summary and the pager
      assert byte_size(patch) < 2_000
    end
  end

  # #89: the table keeps its own tracking, so a new selection sends the checkbox of the row that
  # changed (its cells are not sent again), not the 20 rows.
  test "data_table: a new selection sends the checkbox of that row, not the rows" do
    {first, patch} = patch(&t_data/1, @base, %{selected: ["3"]})
    assert rows_in(patch) == 0
    assert patch =~ "checked"
    assert byte_size(patch) * 20 < byte_size(first)
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

  # The sidebar, the palette and the notification center derive their rows in the body; the part that
  # draws them gets the attributes one by one, so a change that does not touch them leaves them out.
  test "sidebar: collapsing it does not send the items again" do
    {first, patch} = patch(&t_sidebar/1, @base, %{collapsed: true})
    assert first =~ "item-label-8"
    refute patch =~ "item-label"
    refute patch =~ "footer-markup"
    assert byte_size(patch) * 10 < byte_size(first)
  end

  test "header: a new class does not send the tools again" do
    {first, patch} = patch(&t_header/1, @base, %{class: "b"})
    assert first =~ "actions-markup"
    assert first =~ "profile-markup"
    refute patch =~ "actions-markup"
    refute patch =~ "results-markup"
    refute patch =~ "profile-markup"
    # the search box, the toggles and the icons are the tools of the header: not sent either
    refute patch =~ "data-icon"
    assert byte_size(patch) * 10 < byte_size(first)
  end

  test "command_palette: opening it does not send the rows again" do
    {first, patch} = patch(&t_palette/1, @base, %{open: true})
    assert first =~ "cmd-label-10"
    refute patch =~ "cmd-label"
    refute patch =~ "palette-footer"
    # 10, not 20: the rows' icons are static template since #85 (icons), so `first` got smaller
    assert byte_size(patch) * 10 < byte_size(first)
  end

  test "notification_center: opening it does not send the rows again" do
    {first, patch} = patch(&t_notifs/1, @base, %{open: true})
    assert first =~ "notif-title-5"
    refute patch =~ "notif-title"
    assert byte_size(patch) * 3 < byte_size(first)
  end

  test "upload_drop: the drag-over state does not send the label and the hint again" do
    {first, patch} = patch(&t_drop/1, @base, %{over: true})
    assert first =~ "drop-label-markup"
    refute patch =~ "drop-label-markup"
    refute patch =~ "drop-hint-markup"
  end

  test "chart: a new class does not send the options JSON again" do
    {first, patch} = patch(&t_chart/1, @base, %{class: "b"})
    assert first =~ "data-options"
    refute patch =~ "data-options"
    assert byte_size(patch) * 20 < byte_size(first)
  end
end
