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

    assert html =~ "overflow-clip"
    assert html =~ ~s(data-part="sidebar")
    refute html =~ "lu-app"
    assert html =~ "<header>top</header>"
    assert html =~ "page"
  end

  test "sidebar format follows the sidebar attr" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.shell sidebar="rail" nav={[%{label: "Home", href: "/", icon: "home"}]}>x</.shell>|
      )

    assert html =~ ~s(data-lu-format="rail")
    assert html =~ ~s(data-part="rail-logo")
  end

  test "preview draws the wireframe of each layout" do
    for layout <- ~w(sidebar minimal sideblock horizontal framed rail) do
      assigns = %{layout: layout}

      html =
        rendered_to_string(~H|<.shell variant="preview" layout={@layout} loop />|)

      assert html =~ "h-[190px]"
      assert html =~ "animate-[mo-sbw_6s" or layout == "minimal" or layout == "horizontal"
      assert html =~ "grid-cols-3"
    end

    assigns = %{}
    rail = rendered_to_string(~H|<.shell variant="preview" layout="rail" />|)
    assert rail =~ "w-[22px]"
    assert rail =~ "w-[26%]"

    assert rendered_to_string(~H|<.shell variant="preview" layout="horizontal" />|) =~
             "bg-accent-500"

    refute rendered_to_string(~H|<.shell variant="preview" layout="minimal" />|) =~
             "shell-wire-side"
  end
end
