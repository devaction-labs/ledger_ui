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

  test "main_sidebar with items and logo" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.main_sidebar current="/a">
  <:logo>L</:logo><:item navigate="/a" label="A">a</:item><:item label="B">b</:item>
</.main_sidebar>|)

    assert html =~ ~s(class="logo")
    assert html =~ "lu-rail-btn on"
    assert html =~ ~s(aria-label="B")
  end

  test "sidebar_nav_group opens with an active item" do
    assigns = %{}
    html = rendered_to_string(~H|<.sidebar_nav_group label="Starter" current="/s/1">
  <:item navigate="/s/1">One</:item>
</.sidebar_nav_group>|)
    assert html =~ ~s(aria-expanded="true")
    assert html =~ "lu-nav-item sub on"
  end

  test "sidebar_panel and nav links" do
    assigns = %{}
    html = rendered_to_string(~H|<.sidebar_panel title="T">
  <.sidebar_nav_link href="/x" current="/x">X</.sidebar_nav_link>
</.sidebar_panel>|)
    assert html =~ "<h4>T</h4>"
    assert html =~ "lu-nav-item on"
  end

  test "page_header inline" do
    assigns = %{}
    html = rendered_to_string(~H|<.page_header title="Avatar" description="d">
  <:crumb href="/e">E</:crumb><:crumb>Avatar</:crumb><:actions>act</:actions>
</.page_header>|)
    assert html =~ "lu-page-h"
    assert html =~ ~r/<h1>\s*Avatar\s*<\/h1>/
    assert html =~ ~s(class="act")
    assert html =~ ~s(class="cur")
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
    assert html =~ ~r/class="lu-tab-item on"/
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
    assert html =~ "lu-rs open"
    assert html =~ ~s(phx-hook="LedgerUI.RightSidebar")
    assert rendered_to_string(~H|<.right_sidebar_toggle target="rs" />|) =~ ~s(aria-controls="rs")
  end

  test "header toggles and slots" do
    assigns = %{}
    html = rendered_to_string(~H|<.header right_sidebar="rs">
  <:notifications dot>n</:notifications>
</.header>|)
    assert html =~ "lu-topbar"
    assert html =~ "data-sidebar-toggle"
    assert html =~ "lu-tbtn dot"
  end

  test "rail_toggle and framed_sidebar" do
    assigns = %{}
    assert rendered_to_string(~H|<.rail_toggle for="menu" />|) =~ ~s(data-rail-toggle="menu")
    html = rendered_to_string(~H|<.framed_sidebar id="menu">
  <.rail_link href="/a" label="A" badge="2">i</.rail_link>
</.framed_sidebar>|)
    assert html =~ "rail-label"
    assert html =~ ~s(data-lu-persist="true")
  end

  test "monochrome toggle variants" do
    assigns = %{}
    assert rendered_to_string(~H|<.monochrome_toggle />|) =~ "LedgerUI.MonochromeToggle"

    assert rendered_to_string(~H|<.monochrome_toggle variant="switch">M</.monochrome_toggle>|) =~
             "lu-sw"
  end

  test "horizontal nav menu" do
    assigns = %{}
    html = rendered_to_string(~H|<.horizontal_nav_menu id="n" label="Pages" current="/p">
  <:item navigate="/p">P</:item>
</.horizontal_nav_menu>|)
    assert html =~ "lu-menu-item sel"
  end

  test "page_header with a heading slot and title class" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.page_header title_class="mo-stg">
  <:heading><span>Pedidos</span></:heading>
</.page_header>|)

    assert html =~ ~r/<h1 class="mo-stg">\s*<span>Pedidos<\/span>\s*<\/h1>/
  end
end
