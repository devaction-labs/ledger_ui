defmodule LedgerUI.Perf.ActiveLinkPathTest do
  # #105: `match_path` is the client path of the `sidebar/1` driven by data (and its `<:item>`
  # slots) and of the `:tab` of `tab_bar/1`, where `match` already means `exact | prefix`.
  use ExUnit.Case, async: true

  import LedgerUI.DiffCase

  @nav [
    %{label: "Items", icon: "home", navigate: "/items", match_path: "/items", count: 2},
    %{
      group: "Work",
      items: [
        %{
          label: "Tasks",
          icon: "kanban",
          navigate: "/tasks",
          match_path: "/tasks",
          children: [%{label: "Mine", navigate: "/tasks/mine", match_path: "/tasks/mine"}]
        }
      ]
    }
  ]

  defmodule W do
    use Phoenix.Component
    use LedgerUI

    def data(assigns) do
      ~H"""
      <.sidebar id="m" active_link nav={@nav} />
      <main>{@route}</main>
      """
    end

    def tree(assigns) do
      ~H"""
      <.sidebar id="m" active_link format="tree" nav={@nav} />
      <main>{@route}</main>
      """
    end

    def slots(assigns) do
      ~H"""
      <.sidebar id="m" active_link>
        <:item name="a" label="A" icon="home" navigate="/a" match_path="/a" />
        <:item name="b" label="B" icon="user" navigate="/b" match_path="/b" />
      </.sidebar>
      <main>{@route}</main>
      """
    end

    def server(assigns) do
      ~H"""
      <.sidebar id="m" nav={@nav} current={@route} />
      <main>{@route}</main>
      """
    end

    def rail(assigns) do
      ~H"""
      <.sidebar id="m" active_link format="rail" nav={@nav} />
      """
    end

    def bar(assigns) do
      ~H"""
      <.tab_bar id="bar" active_link>
        <:tab navigate="/items" match_path="/items" label="Items">i</:tab>
        <:tab navigate="/orders" match_path="/orders" label="Orders">o</:tab>
      </.tab_bar>
      <main>{@route}</main>
      """
    end

    def bar_server(assigns) do
      ~H"""
      <.tab_bar current={@route} match="prefix">
        <:tab navigate="/items" label="Items">i</:tab>
        <:tab navigate="/orders" label="Orders">o</:tab>
      </.tab_bar>
      <main>{@route}</main>
      """
    end
  end

  for {name, fun} <- [
        sidebar_data: &W.data/1,
        sidebar_tree: &W.tree/1,
        sidebar_slots: &W.slots/1,
        tab_bar: &W.bar/1
      ] do
    test "#{name}: a route change sends only the page, not the menu" do
      json = check(unquote(fun), %{route: "/items", nav: @nav}, route: "/tasks")
      refute json =~ "data-lu-match"
      refute json =~ "aria-current"
      assert byte_size(json) < 30, json
    end
  end

  test "against the server `current` the sidebar and the bar are sent again" do
    assert byte_size(patch(&W.server/1, %{route: "/items", nav: @nav}, route: "/tasks")) > 200

    assert byte_size(patch(&W.bar_server/1, %{route: "/items"}, route: "/orders")) > 100
  end

  test "the sidebar carries the hook on one column and `match_path` on the links" do
    {_, html} = first(&W.data/1, %{route: "/items", nav: @nav})
    assert length(Regex.scan(~r/phx-hook="LedgerUI.ActiveLink"/, html)) == 1
    assert html =~ ~s(id="m-active-link")
    assert html =~ ~s(data-lu-match="/items")
    assert html =~ ~s(data-lu-match="/tasks")
    assert html =~ ~s(data-lu-match="/tasks/mine")
    assert html =~ ~s(data-lu-active-class="bg-panel)
    # the Sidebar hook of the aside is still there
    assert html =~ ~s(phx-hook="LedgerUI.Sidebar")
    # nothing marked by the server
    refute html =~ ~s(aria-current="page")
  end

  test "the tab bar carries the hook and `match_path`" do
    {_, html} = first(&W.bar/1, %{route: "/items"})
    assert html =~ ~s(phx-hook="LedgerUI.ActiveLink")
    assert html =~ ~s(data-lu-match="/orders")
    assert html =~ ~s(data-lu-active-class="text-accent-content)
    assert html =~ ~s(data-lu-inactive-class="text-muted)
  end

  test "without `active_link` and `match_path` there is no hook, no attribute" do
    nav = [%{label: "Items", icon: "home", navigate: "/items"}]
    {_, html} = first(&W.server/1, %{route: "/items", nav: nav})
    refute html =~ "ActiveLink"
    refute html =~ "data-lu-match"
    {_, html} = first(&W.bar_server/1, %{route: "/items"})
    refute html =~ "ActiveLink"
    refute html =~ "data-lu-match"
  end

  test "active_link does not work with the rail format" do
    assert_raise ArgumentError, ~r/active_link/, fn ->
      html(&W.rail/1, %{route: "/", nav: @nav})
    end
  end
end
