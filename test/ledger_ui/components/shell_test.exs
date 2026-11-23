defmodule LedgerUI.Components.ShellTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Shell

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

  test "format attr picks the sidebar format" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.shell format="rail" nav={[%{label: "Home", href: "/", icon: "home"}]}>x</.shell>|
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

  describe "slot mode (the free-form :sidebar slot)" do
    test "classes, state and the hook" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.shell id="s" layout="minimal" header_sticky={false}><:sidebar>menu</:sidebar>x</.shell>|
        )

      assert html =~ "has-min-sidebar"
      assert html =~ "is-header-not-sticky"
      assert html =~ "is-header-blur"
      assert html =~ "group/shell"
      refute html =~ "is-sidebar-open"
      assert html =~ "menu"
      refute html =~ ~s(data-part="sidebar")

      open = rendered_to_string(~H|<.shell id="s"><:sidebar>menu</:sidebar>x</.shell>|)
      assert open =~ "is-sidebar-open"
      assert open =~ ~s(phx-hook="LedgerUI.Shell")
      assert open =~ ~s(data-lu-open="true")
      assert open =~ ~s(data-lu-persist="true")

      sb =
        rendered_to_string(~H|<.shell id="s" layout="sideblock"><:sidebar>m</:sidebar>x</.shell>|)

      assert sb =~ "navigation:sideblock"

      hz =
        rendered_to_string(
          ~H|<.shell id="s" layout="horizontal"><:sidebar>m</:sidebar>x</.shell>|
        )

      assert hz =~ "navigation:horizontal"
      refute hz =~ "is-sidebar-open"
    end

    test "sidebar_open, on_toggle, target and persist reach the hook" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.shell id="s" sidebar_open={false} on_toggle="side" target="#t" persist={false}>
  <:sidebar>m</:sidebar>x
</.shell>|
        )

      refute html =~ "is-sidebar-open"
      assert html =~ ~s(data-lu-open="false")
      assert html =~ ~s(data-lu-on-toggle="side")
      assert html =~ ~s(data-lu-target="#t")
      assert html =~ ~s(data-lu-persist="false")

      js =
        rendered_to_string(
          ~H|<.shell id="s" on_toggle={Phoenix.LiveView.JS.push("side")}><:sidebar>m</:sidebar>x</.shell>|
        )

      assert js =~ "data-on-toggle-js"
      refute js =~ "data-lu-on-toggle"
    end

    test "full and the float column" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.shell id="s" full style="width:10px"><:sidebar>m</:sidebar>x</.shell>|
        )

      assert html =~ "min-h-screen"
      assert html =~ ~s(style="width:10px")
      assert html =~ "overflow-clip"
      refute html =~ "overflow-hidden"
      refute html =~ "rounded-[18px]"

      framed =
        rendered_to_string(~H|<.shell id="s" layout="framed"><:sidebar>m</:sidebar>x</.shell>|)

      assert framed =~ "rounded-[18px]"
      assert framed =~ "py-2 pr-2"

      float = rendered_to_string(~H|<.shell id="s" float><:sidebar>m</:sidebar>x</.shell>|)
      assert float =~ "rounded-[18px]"

      assert rendered_to_string(
               ~H|<.shell id="s" layout="framed" full><:sidebar>m</:sidebar>x</.shell>|
             ) =~ "border-l border-line"
    end

    test "min_height goes through a variable and keeps the caller's style" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.shell id="s" float min_height="900px" style="color:red"><:sidebar>m</:sidebar>x</.shell>|
        )

      assert html =~ ~s(style="--lu-shell-min:900px;color:red")
    end

    test "the main column resets its padding and the preloader shows" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.shell id="s" preloader><:sidebar>m</:sidebar>x</.shell>|)

      assert html =~ ~r/<main [^>]*class="[^"]*\bp-0\b/
      assert html =~ "data-preloader"
    end

    test "topbar, aside and tab_bar slots" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.shell id="s">
          <:sidebar>m</:sidebar>
          <:topbar>
            <header>top</header>
          </:topbar>
          page
          <:aside><i id="ov"></i></:aside>
          <:tab_bar>
            <nav>tabs</nav>
          </:tab_bar>
        </.shell>
        """)

      assert html =~ "<header>top</header>"
      assert html =~ "max-md:pb-16"
      assert html =~ ~s(data-part="tab-bar-slot")
      {a, _} = :binary.match(html, "</main>")
      {b, _} = :binary.match(html, ~s(id="ov"))
      assert b > a
    end
  end

  test "data mode has no sticky header by default and carries the hook" do
    assigns = %{}
    html = rendered_to_string(~H|<.shell nav={[%{label: "Home", href: "/"}]}>x</.shell>|)
    assert html =~ "is-header-not-sticky"
    refute html =~ "is-header-blur"
    assert html =~ ~s(phx-hook="LedgerUI.Shell")
    assert html =~ ~s(data-part="sidebar")
    assert html =~ ~r/<main [^>]*class="[^"]*\bp-0\b/

    sticky =
      rendered_to_string(
        ~H|<.shell header_sticky header_blur nav={[%{label: "Home", href: "/"}]}>x</.shell>|
      )

    assert sticky =~ "is-header-blur"
    refute sticky =~ "is-header-not-sticky"
  end

  test "the app_shell constructs are gone" do
    refute function_exported?(LedgerUI.Components.Shell, :app_shell, 1)
    refute Code.ensure_loaded?(LedgerUI.Components.AppShell)
    assert function_exported?(LedgerUI.Components.Shell, :page_header, 1)
  end

  test "the root exposes --lu-sidebar-w for the open, closed and collapsed menu" do
    assigns = %{}
    html = rendered_to_string(~H|<.shell nav={[%{label: "Home", href: "/"}]}>page</.shell>|)
    assert html =~ "[--lu-sidebar-w:var(--lu-sidebar-open-w,248px)]"
    assert html =~ "not-[.open]:[--lu-sidebar-w:var(--lu-sidebar-closed-w,60px)]"

    assert html =~
             "has-[aside[data-collapsed]]:[--lu-sidebar-w:var(--lu-sidebar-collapsed-w,60px)]"
  end
end
