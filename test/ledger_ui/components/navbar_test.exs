defmodule LedgerUI.Components.NavbarTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Navbar

  test "variant and size classes" do
    assigns = %{}
    html = rendered_to_string(~H|<.navbar variant="float" size="sm">x</.navbar>|)
    assert html =~ ~r/class="lu-topbar float sm"/
  end

  test "tabs make two rows" do
    assigns = %{}
    html = rendered_to_string(~H|<.navbar>
  a<:tabs>t</:tabs>
</.navbar>|)
    assert html =~ "flex-direction:column"
  end

  test "crumbs: links, separators, current" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.navbar_crumbs items={[%{label: "A", href: "/a"}, %{label: "B"}]} />|
      )

    assert html =~ ~s(href="/a")
    assert html =~ ~s(<span class="s">/</span>)
    assert html =~ ~s(class="cur")
    assert html =~ ~s(aria-label="Breadcrumb")
  end

  test "search is a button only with phx-click" do
    assigns = %{}
    plain = rendered_to_string(~H|<.navbar_search width="200px" />|)
    refute plain =~ "role="
    assert plain =~ "width:200px"
    click = rendered_to_string(~H|<.navbar_search phx-click="open" />|)
    assert click =~ ~s(role="button")
  end

  test "bell, env, user menu" do
    assigns = %{}
    assert rendered_to_string(~H|<.navbar_bell dot />|) =~ "lu-tbtn dot"
    assert rendered_to_string(~H|<.navbar_env label="Prod" tone="warn" />|) =~ "lu-badge warn"

    html =
      rendered_to_string(~H|<.navbar_user id="me" user={%{name: "Ana B"}}>
  <:menu>
    <.navbar_menu_item icon="user" href="/p">Perfil</.navbar_menu_item>
  </:menu>
</.navbar_user>|)

    assert html =~ ~s(role="menu")
    assert html =~ "Perfil"
    assert html =~ "AB"
  end

  test "user menu needs an id" do
    assigns = %{}

    assert_raise ArgumentError, fn ->
      rendered_to_string(~H|<.navbar_user user={%{name: "A"}}>
  <:menu>x</:menu>
</.navbar_user>|)
    end
  end

  test "links mark the current one" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.navbar_links current="/b" items={[%{label: "A", href: "/a"}, %{label: "B", href: "/b"}]} />|
      )

    assert html =~
             ~r/lu-nav-item on"[^>]*aria-current="page"|aria-current="page"[^>]*lu-nav-item on/
  end

  test "plain crumbs with an icon and a search that is a real input" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.navbar_crumbs
  variant="plain"
  icon="grid"
  label="Trilha"
  items={[%{label: "A", href: "#"}, %{label: "B"}]}
/>|)

    assert html =~ ~s(class="lu-crumb")
    refute html =~ "canvas"
    assert html =~ ~s(data-icon="grid")

    search =
      rendered_to_string(~H|<.navbar_search input kbd="Ctrl K" placeholder="Search or run…" />|)

    assert search =~ ~s(<input placeholder="Search or run…")
    refute search =~ ~s(class="ph")
  end
end
