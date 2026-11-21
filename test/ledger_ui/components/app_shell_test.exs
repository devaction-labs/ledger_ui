defmodule LedgerUI.Components.AppShellTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.AppShell

  test "app_shell classes and state" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.app_shell id="s" layout="minimal" header_sticky={false}>x</.app_shell>|
      )

    assert html =~ "has-min-sidebar"
    assert html =~ "is-header-not-sticky"
    refute html =~ "is-sidebar-open"
    open = rendered_to_string(~H|<.app_shell id="s">x</.app_shell>|)
    assert open =~ "is-sidebar-open"
    assert open =~ ~s(phx-hook="LedgerUI.AppShell")
  end

  test "the shell keeps overflow clip and fills the screen" do
    assigns = %{}
    html = rendered_to_string(~H|<.app_shell id="s" full style="width:10px">x</.app_shell>|)
    assert html =~ "min-h-(--lu-shell-min,100vh)"
    refute html =~ "min-height:100vh"
    assert html =~ ~s(style="width:10px")
    plain = rendered_to_string(~H|<.app_shell id="s">x</.app_shell>|)
    assert plain =~ "min-h-(--lu-shell-min,100vh)"
    # the drawer slide: the shell clips (it can never be scrolled), it does not `hidden`
    for h <- [html, plain] do
      assert h =~ "overflow-clip"
      refute h =~ "overflow-hidden"
    end

    # floating main column: framed layout or `float`
    framed = rendered_to_string(~H|<.app_shell id="s" layout="framed">x</.app_shell>|)
    assert framed =~ "rounded-[18px]"

    assert rendered_to_string(~H|<.app_shell id="s" layout="framed" full>x</.app_shell>|) =~
             "border-l border-line"
  end

  test "main_sidebar with items and logo" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.main_sidebar current="/a">
  <:logo>L</:logo><:item navigate="/a" label="A">a</:item><:item label="B">b</:item>
</.main_sidebar>|)

    assert html =~ ~s(data-part="main-sidebar-logo")
    assert html =~ "bg-selected text-ink"
    assert html =~ ~s(aria-current="page")
    assert html =~ ~s(aria-label="B")
  end

  test "sidebar_nav_group opens with an active item" do
    assigns = %{}
    html = rendered_to_string(~H|<.sidebar_nav_group label="Starter" current="/s/1">
  <:item navigate="/s/1">One</:item>
</.sidebar_nav_group>|)
    assert html =~ ~s(aria-expanded="true")
    assert html =~ "bg-selected text-ink"
    assert html =~ "pl-10"
  end

  test "sidebar_panel and nav links" do
    assigns = %{}
    html = rendered_to_string(~H|<.sidebar_panel title="T">
  <.sidebar_nav_link href="/x" current="/x">X</.sidebar_nav_link>
</.sidebar_panel>|)
    assert html =~ ~r/<h4[^>]*>T<\/h4>/
    assert html =~ "bg-selected text-ink"
    assert html =~ ~s(data-part="sidebar-panel")
  end

  test "page_header inline" do
    assigns = %{}
    html = rendered_to_string(~H|<.page_header title="Avatar" description="d">
  <:crumb href="/e">E</:crumb><:crumb>Avatar</:crumb><:actions>act</:actions>
</.page_header>|)
    assert html =~ ~s(data-part="page-header")
    assert html =~ ~r/<h1 [^>]*>\s*Avatar\s*<\/h1>/
    assert html =~ "ml-auto flex flex-wrap gap-2"
    assert html =~ ~s(aria-current="page")
  end

  test "page_header page variant with back link" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.page_header variant="page" title="Order" back="/o" back_label="Orders" bell />|
      )

    assert html =~ "Orders"
  end

  test "tab_bar marks the current tab, prefix match" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.tab_bar current="/app/tasks/1" match="prefix">
  <:tab navigate="/app/tasks" label="Tasks">t</:tab><:tab navigate="/" label="Home">h</:tab>
</.tab_bar>|)

    assert html =~ ~s(aria-label="Tasks")

    assert html =~
             ~r/aria-current="page"[^>]*text-accent-content|text-accent-content[^>]*aria-current|aria-current="page"/
  end

  test "rail_module opens when a page is current" do
    assigns = %{}
    html = rendered_to_string(~H|<.rail_module id="m" label="Sales" current="/o">
  <:icon>i</:icon><:item navigate="/o">Orders</:item>
</.rail_module>|)
    assert html =~ ~s(aria-expanded="true")
  end

  test "right_sidebar open state and toggle" do
    assigns = %{}
    html = rendered_to_string(~H|<.right_sidebar id="rs" open>x</.right_sidebar>|)
    assert html =~ ~s(data-part="right-sidebar")
    assert html =~ ~r/class="[^"]*\bopen\b/
    assert html =~ "[&amp;.open]:fixed"
    assert html =~ ~s(phx-hook="LedgerUI.RightSidebar")
    assert rendered_to_string(~H|<.right_sidebar_toggle target="rs" />|) =~ ~s(aria-controls="rs")
  end

  test "header toggles and slots" do
    assigns = %{}
    html = rendered_to_string(~H|<.header right_sidebar="rs">
  <:notifications dot>n</:notifications>
</.header>|)
    assert html =~ ~s(data-part="header")
    assert html =~ "group-not-[.is-header-not-sticky]/shell:sticky"
    assert html =~ "data-sidebar-toggle"
    assert html =~ "after:bg-neg"
  end

  test "rail_toggle and framed_sidebar" do
    assigns = %{}
    assert rendered_to_string(~H|<.rail_toggle for="menu" />|) =~ ~s(data-rail-toggle="menu")
    html = rendered_to_string(~H|<.framed_sidebar id="menu">
  <.rail_link href="/a" label="A" badge="2">i</.rail_link>
</.framed_sidebar>|)
    assert html =~ "group-data-[collapsed]/side:hidden"
    assert html =~ "data-[collapsed]:w-[60px]"
    assert html =~ ~s(data-lu-persist="true")
  end

  test "monochrome toggle variants" do
    assigns = %{}
    assert rendered_to_string(~H|<.monochrome_toggle />|) =~ "LedgerUI.MonochromeToggle"

    assert rendered_to_string(~H|<.monochrome_toggle variant="switch">M</.monochrome_toggle>|) =~
             "group-aria-checked:bg-accent"
  end

  test "horizontal nav menu" do
    assigns = %{}
    html = rendered_to_string(~H|<.horizontal_nav_menu id="n" label="Pages" current="/p">
  <:item navigate="/p">P</:item>
</.horizontal_nav_menu>|)
    assert html =~ ~s(data-part="horizontal-nav-menu")
    assert html =~ ~s(role="menuitem")
    assert html =~ "font-medium text-ink"
  end

  test "page_header with a heading slot and title class" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.page_header title_class="animate-[mo-stg_1s]">
  <:heading><span>Pedidos</span></:heading>
</.page_header>|)

    assert html =~ ~r/<h1 [^>]*animate-\[mo-stg_1s\][^>]*>\s*<span>Pedidos<\/span>\s*<\/h1>/
  end

  test "min_height goes through a variable and keeps the caller's style" do
    assigns = %{}
    plain = rendered_to_string(~H|<.app_shell id="s">x</.app_shell>|)
    assert plain =~ "min-h-(--lu-shell-min,100vh)"
    refute plain =~ "--lu-shell-min:"

    html =
      rendered_to_string(
        ~H|<.shell_floating id="s" min_height="900px" style="color:red">x</.shell_floating>|
      )

    assert html =~ ~s(style="--lu-shell-min:900px;color:red")
  end

  test "rail_workspace bare drops the margin under the box" do
    assigns = %{}
    assert rendered_to_string(~H|<.rail_workspace name="X" />|) =~ "mb-2.5"
    bare = rendered_to_string(~H|<.rail_workspace name="X" bare />|)
    assert bare =~ "mb-0"
    refute bare =~ "mb-2.5"
  end

  test "sub_nav loop animates the first group only" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.sub_nav title="T" loop>
        <:group label="A">a</:group>
        <:group label="B">b</:group>
      </.sub_nav>
      """)

    assert length(String.split(html, "animate-[mo-expand_5s_ease-in-out_infinite]")) == 2
    assert length(String.split(html, "animate-[mo-rot_5s_ease-in-out_infinite]")) == 2
  end

  test "the main column resets its padding (a page stylesheet may style the bare `main`)" do
    assigns = %{}
    html = rendered_to_string(~H|<.app_shell id="s">x</.app_shell>|)
    assert html =~ ~r/<main [^>]*class="[^"]*\bp-0\b/
  end
end
