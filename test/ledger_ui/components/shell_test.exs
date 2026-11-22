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

  test "full drops the frame and fills the viewport" do
    assigns = %{}
    html = rendered_to_string(~H|<.shell full nav={[%{label: "Home", href: "/"}]}>x</.shell>|)

    assert html =~ "min-h-screen"
    assert html =~ ~s(data-full="true")
    refute html =~ "rounded-2xl"
    refute html =~ "min-h-[520px]"
  end

  test "default keeps the frame and min_height goes through a variable" do
    assigns = %{}
    html = rendered_to_string(~H|<.shell nav={[%{label: "Home", href: "/"}]}>x</.shell>|)
    assert html =~ "rounded-2xl"
    assert html =~ "min-h-[520px]"

    html =
      rendered_to_string(
        ~H|<.shell min_height="900px" style="color:red" nav={[%{label: "Home", href: "/"}]}>x</.shell>|
      )

    assert html =~ "min-h-(--lu-shell-min)"
    assert html =~ "--lu-shell-min:900px;color:red"
  end

  test "aside renders after the page" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.shell nav={[%{label: "Home", href: "/"}]}>
  page<:aside><i id="ov"></i></:aside>
</.shell>|)

    {a, _} = :binary.match(html, "</main>")
    {b, _} = :binary.match(html, ~s(id="ov"))
    assert b > a
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
