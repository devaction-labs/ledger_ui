defmodule LedgerUI.Perf.ActiveLinkTest do
  # #105: with `match` on the items and `active_link` on the menu, the client marks the active item
  # (`LedgerUI.ActiveLink`), so a route change sends nothing of the menu.
  use ExUnit.Case, async: true

  import LedgerUI.DiffCase

  defmodule W do
    use Phoenix.Component
    use LedgerUI

    def nav(assigns) do
      ~H"""
      <.sidebar_nav id="m" active_link>
        <.sidebar_nav_link navigate="/items" match="/items">Items</.sidebar_nav_link>
        <.sidebar_nav_link navigate="/items/new" match="/items/new">New</.sidebar_nav_link>
      </.sidebar_nav>
      <main>{@route}</main>
      """
    end

    def nav_server(assigns) do
      ~H"""
      <.sidebar_nav id="m">
        <.sidebar_nav_link navigate="/items" current={@route}>Items</.sidebar_nav_link>
        <.sidebar_nav_link navigate="/items/new" current={@route}>New</.sidebar_nav_link>
      </.sidebar_nav>
      <main>{@route}</main>
      """
    end

    def rail(assigns) do
      ~H"""
      <.sidebar_nav id="m" active_link>
        <.rail_link navigate="/items" match="/items" label="Items" />
        <.rail_link navigate="/users" match="/users" label="Users" />
      </.sidebar_nav>
      <main>{@route}</main>
      """
    end

    def main_side(assigns) do
      ~H"""
      <.main_sidebar id="ms" active_link>
        <:item navigate="/items" match="/items" label="Items" icon="home" />
        <:item navigate="/users" match="/users" label="Users" icon="user" />
      </.main_sidebar>
      <main>{@route}</main>
      """
    end

    def links(assigns) do
      ~H"""
      <.navbar_links
        id="l"
        active_link
        items={[%{label: "A", navigate: "/a", match: "/a"}, %{label: "B", navigate: "/b", match: "/b"}]}
      />
      <main>{@route}</main>
      """
    end

    def tabs(assigns) do
      ~H"""
      <.navbar_tabs
        id="t"
        active_link
        items={[%{label: "A", navigate: "/a", match: "/a"}, %{label: "B", navigate: "/b", match: "/b"}]}
      />
      <main>{@route}</main>
      """
    end

    def plain(assigns) do
      ~H"""
      <.sidebar_nav>
        <.sidebar_nav_link navigate="/items">Items</.sidebar_nav_link>
      </.sidebar_nav>
      <.rail_link navigate="/x" label="X" />
      <.navbar_links items={[%{label: "A", navigate: "/a"}]} />
      <.navbar_tabs items={[%{label: "A", navigate: "/a"}]} />
      <.main_sidebar id="ms"><:item navigate="/i" label="I" icon="home" /></.main_sidebar>
      """
    end
  end

  for {name, fun} <- [
        sidebar_nav: &W.nav/1,
        rail_link: &W.rail/1,
        main_sidebar: &W.main_side/1,
        navbar_links: &W.links/1,
        navbar_tabs: &W.tabs/1
      ] do
    test "#{name}: a route change with `match` sends only the page, not the menu" do
      json = check(unquote(fun), %{route: "/items"}, route: "/users")
      refute json =~ "data-lu-match"
      refute json =~ "aria-current"
      assert byte_size(json) < 30, json
    end
  end

  test "the menu with `match` carries the hook and the classes of the client" do
    {_, html} = first(&W.nav/1, %{route: "/items"})
    assert html =~ ~s(phx-hook="LedgerUI.ActiveLink")
    assert html =~ ~s(data-lu-match="/items")
    assert html =~ ~s(data-lu-active-class="bg-panel)
    assert html =~ ~s(data-lu-inactive-class="bg-transparent)
  end

  test "against the server `current`: the menu goes again on a route change" do
    json = patch(&W.nav_server/1, %{route: "/items"}, route: "/items/new")
    assert byte_size(json) > 100
  end

  test "without `match` and `active_link` there is no hook, no attribute" do
    {_, html} = first(&W.plain/1, %{})
    refute html =~ "ActiveLink"
    refute html =~ "data-lu-match"
    refute html =~ "data-lu-active-class"
  end
end
