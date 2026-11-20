defmodule LedgerUI.Components.NavbarTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Navbar

  test "variant and size classes" do
    assigns = %{}
    html = rendered_to_string(~H|<.navbar variant="float" size="sm">x</.navbar>|)
    assert html =~ "m-2.5 rounded-[16px] bg-panel"
    assert html =~ "h-[52px]"
    refute html =~ "h-16"
  end

  test "tabs make two rows" do
    assigns = %{}
    html = rendered_to_string(~H|<.navbar>
  a<:tabs>t</:tabs>
</.navbar>|)
    assert html =~ "flex-col items-stretch gap-0 pb-0"
    assert html =~ "h-auto"
  end

  test "crumbs: links, separators, current" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.navbar_crumbs items={[%{label: "A", href: "/a"}, %{label: "B"}]} />|
      )

    assert html =~ ~s(href="/a")
    assert html =~ ~r{<span [^>]*class="text-line-strong">/</span>}
    assert html =~ ~s(aria-current="page")
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
    assert rendered_to_string(~H|<.navbar_bell dot />|) =~ "after:bg-neg"
    assert rendered_to_string(~H|<.navbar_env label="Prod" tone="warn" />|) =~ "bg-warn-soft"

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
             ~r/bg-selected text-ink[^>]*aria-current="page"|aria-current="page"[^>]*bg-selected text-ink|aria-current="page"/
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

    assert html =~ ~s(data-part="navbar-crumbs")
    assert html =~ "text-line-strong"
    refute html =~ "canvas"
    assert html =~ ~s(data-icon="grid")

    search =
      rendered_to_string(~H|<.navbar_search input kbd="Ctrl K" placeholder="Search or run…" />|)

    assert search =~ ~r{<input [^>]*placeholder="Search or run…"}
    refute search =~ ~s(class="ph")
  end
end
