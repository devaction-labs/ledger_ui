defmodule LedgerUI.Components.ShellTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Shell
  import LedgerUI.Components.AppShell, only: []

  test "renders sidebar, topbar slot and page" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.shell nav={[%{label: "Home", href: "/"}]} brand={%{name: "L"}}>
  <:topbar><header>top</header></:topbar>page
</.shell>|)

    assert html =~ ~s(class="lu-app")
    assert html =~ "lu-side"
    assert html =~ "<header>top</header>"
    assert html =~ "page"
  end

  test "sidebar format follows the sidebar attr" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.shell sidebar="rail" nav={[%{label: "Home", href: "/", icon: "home"}]}>x</.shell>|
      )

    assert html =~ "lu-rail"
  end

  test "preview draws the wireframe of each layout" do
    for layout <- ~w(sidebar minimal sideblock horizontal framed rail) do
      assigns = %{layout: layout}

      html =
        rendered_to_string(~H|<.shell variant="preview" layout={@layout} class="m-collapse" />|)

      assert html =~ "lu-wire"
      assert html =~ "m-collapse"
      assert html =~ ~s(class="mn")
    end

    assigns = %{}
    rail = rendered_to_string(~H|<.shell variant="preview" layout="rail" />|)
    assert rail =~ ~s(class="rail")
    assert rail =~ "width:26%"

    assert rendered_to_string(~H|<.shell variant="preview" layout="horizontal" />|) =~
             "var(--teal-500)"

    refute rendered_to_string(~H|<.shell variant="preview" layout="minimal" />|) =~ ~s(class="sb")
  end
end
