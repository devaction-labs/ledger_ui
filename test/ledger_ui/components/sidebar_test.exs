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
    assert html =~ ~s(data-part="brand")
    assert html =~ "border border-line bg-panel"
    assert html =~ "uppercase tracking-[.06em]"
  end

  test "variant classes" do
    assigns = %{}
    assert rendered_to_string(~H|<.sidebar nav={[]} />|) =~ "rounded-[18px] bg-panel"
    assert rendered_to_string(~H|<.sidebar nav={[]} variant="inset" />|) =~ "bg-transparent"
    refute rendered_to_string(~H|<.sidebar nav={[]} variant="sidebar" />|) =~ "floating"
  end

  test "tree: active child opens its parent, disabled item is a span" do
    html = render_sidebar("tree")
    assert html =~ ~s(aria-expanded="true")
    assert html =~ ~s(aria-disabled="true")
    assert html =~ "pl-10"
    assert html =~ "bg-selected text-ink"
  end

  test "prefix match lights a parent" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.sidebar nav={[%{label: "T", navigate: "/app/tasks"}]} current="/app/tasks/1" match="prefix" />|
      )

    assert html =~ "bg-selected text-ink"
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

  test "flat items, separators, kbd, loose items and carets follow the canvas" do
    nav = [
      %{label: "Search", icon: "search", href: "#", kbd: "⌘K"},
      :separator,
      %{label: "Folder", icon: "folder", href: "#", class: "folder", caret: "right"},
      %{label: "Alone", href: "#", loose: true}
    ]

    assigns = %{nav: nav}

    html =
      rendered_to_string(
        ~H|<.sidebar flat variant="sidebar" nav={@nav} brand={%{name: "X", mark: true}} />|
      )

    assert html =~ "⌘K"
    assert html =~ ~s(data-part="kbd")
    assert html =~ "mx-1 my-2.5 h-px bg-line"
    assert html =~ ~s(data-icon="chevron-right")
    # flat: no column around the items
    refute html =~ ~r{<div[^>]*class="flex flex-col gap-0.5"}
    # the chart glyph of the brand
    assert html =~ "M4 19V5"

    columns =
      rendered_to_string(~H|<.sidebar nav={@nav} />|)

    assert columns =~ "flex flex-col gap-0.5"
  end

  test "plan card with description and action, user with role and status" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.sidebar
  footer="user"
  plan={
    %{
      name: "AI",
      text: "3 new",
      description: "Ask why.",
      action: %{label: "Run", icon: "sparkles"}
    }
  }
  user={%{name: "Ana", role: "Head", initials: "AN", tone: "t1", status: "on"}}
/>|)

    assert html =~ ~s(data-part="plan")
    assert html =~ "Ask why."
    assert html =~ "justify-between!"
    assert html =~ ~s(data-part="avatar")
    assert html =~ "Head"
    assert html =~ "bg-accent-100 text-accent-800"
  end
end
