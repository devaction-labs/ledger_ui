defmodule LedgerUI.Components.SidebarTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Sidebar

  @nav [
    %{label: "Home", icon: "home", navigate: "/", count: 3},
    %{
      group: "Work",
      items: [
        %{
          label: "Tasks",
          icon: "kanban",
          navigate: "/t",
          children: [%{label: "Mine", navigate: "/t/m"}]
        },
        %{label: "Soon", disabled: true}
      ]
    },
    %{group: "Help", footer: true, items: [%{label: "Docs", icon: "help", href: "/d"}]}
  ]

  defp render_sidebar(format, extra \\ %{}) do
    assigns = Map.merge(%{format: format, nav: @nav, current: "/t/m"}, extra)
    rendered_to_string(~H|<.sidebar
  format={@format}
  nav={@nav}
  current={@current}
  brand={%{name: "Ledger"}}
  user={%{name: "Ana B", email: "a@b"}}
/>|)
  end

  test "all four formats render the same items" do
    for f <- ~w(sections tree rail nested) do
      html = render_sidebar(f)
      assert html =~ "Home" or html =~ ~s(aria-label="Home")
      assert html =~ ~s(<aside id="sidebar")
    end
  end

  test "sections: brand, grow, user" do
    html = render_sidebar("sections", %{})
    assert html =~ ~s(class="lu-ws")
    assert html =~ "lu-nav-h"
  end

  test "variant classes" do
    assigns = %{}
    assert rendered_to_string(~H|<.sidebar nav={[]} />|) =~ "lu-side floating"
    assert rendered_to_string(~H|<.sidebar nav={[]} variant="inset" />|) =~ "lu-side inset"
    refute rendered_to_string(~H|<.sidebar nav={[]} variant="sidebar" />|) =~ "floating"
  end

  test "tree: active child opens its parent, disabled item is a span" do
    html = render_sidebar("tree")
    assert html =~ ~s(aria-expanded="true")
    assert html =~ ~s(aria-disabled="true")
    assert html =~ "lu-nav-item sub on"
  end

  test "prefix match lights a parent" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.sidebar nav={[%{label: "T", navigate: "/app/tasks"}]} current="/app/tasks/1" match="prefix" />|
      )

    assert html =~ "lu-nav-item on"
  end

  test "version line" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.sidebar nav={[]} footer="version" version={%{version: "v1.2", build: "abc"}} />|
      )

    assert html =~ "v1.2"
    assert html =~ "Version v1.2 (abc)"
  end

  test "collapse config goes to the hook" do
    assigns = %{}
    html = rendered_to_string(~H|<.sidebar nav={[]} collapsed on_collapse="c" />|)
    assert html =~ ~s(phx-hook="LedgerUI.Sidebar")
    assert html =~ ~s(data-lu-collapsed="true")
    assert html =~ ~s(data-lu-on-collapse="c")
  end
end
