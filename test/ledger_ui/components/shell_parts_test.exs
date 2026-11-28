defmodule LedgerUI.Components.ShellPartsTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Shell

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
    assert html =~ "bg-panel text-ink shadow-xs ring-1 ring-line"
    assert html =~ "pl-10"
  end

  test "sidebar_panel and nav links" do
    assigns = %{}
    html = rendered_to_string(~H|<.sidebar_panel title="T">
  <.sidebar_nav_link href="/x" current="/x">X</.sidebar_nav_link>
</.sidebar_panel>|)
    assert html =~ ~r/<h4[^>]*>T<\/h4>/
    assert html =~ "bg-panel text-ink shadow-xs ring-1 ring-line"
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

  describe "rail_module active mark (#50)" do
    defp head_tag(html), do: Regex.run(~r/<button[^>]*rail-module-button[^>]*>/s, html) |> hd()

    test "active child: the head is neutral when open and marked when closed or collapsed" do
      assigns = %{}
      html = rendered_to_string(~H|<.rail_module id="m" label="Sales" current="/o">
  <:icon>i</:icon><:item navigate="/o">Orders</:item><:item navigate="/p">Products</:item>
</.rail_module>|)
      head = head_tag(html)

      # no unconditional active fill on the head; it only applies by variant
      refute head =~ ~r/(?<![:\w-])bg-selected/
      assert head =~ "aria-[expanded=false]:bg-selected"
      assert head =~ "group-data-[collapsed]/side:bg-selected"
      assert head =~ ~s(aria-expanded="true")
      # aria-current stays on the real active item only
      assert length(Regex.scan(~r/aria-current="page"/, html)) == 1
      assert html =~ ~r/<a[^>]*aria-current="page"[^>]*>\s*Orders/s
    end

    test "no active child: the head keeps the plain classes" do
      assigns = %{}
      html = rendered_to_string(~H|<.rail_module id="m" label="Sales" current="/zzz">
  <:icon>i</:icon><:item navigate="/o">Orders</:item>
</.rail_module>|)
      refute head_tag(html) =~ "bg-selected"
      refute html =~ "aria-current"
    end
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
    assert html =~ "data-[collapsed]:w-(--lu-rail-collapsed,60px)"
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

  test "photo logos are taken out of grid flow inside a relative box (#1)" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.main_sidebar current="/a">
  <:logo src="/l.png">x</:logo><:logo src="/m.png" navigate="/">y</:logo>
</.main_sidebar>|)

    for part <- ~w(main-sidebar-logo-image main-sidebar-img) do
      assert html =~ ~r/<img[^>]*#{part}[^>]*class="[^"]*\babsolute inset-0\b/, part
    end

    assert html =~ ~r/data-part="main-sidebar-logo" class="relative /

    html = rendered_to_string(~H|<.sideblock>
  <:logo src="/l.png">x</:logo>
</.sideblock>|)
    assert html =~ ~r/<img[^>]*sideblock-img[^>]*class="[^"]*\babsolute inset-0\b/
    assert html =~ ~r/data-part="sideblock-logo" class="relative /
  end

  test "page_header default keeps the h1 and the 26px top padding" do
    assigns = %{}

    inline = rendered_to_string(~H|<.page_header title="T" />|)
    assert inline =~ "px-7 pb-[18px] pt-[26px]"
    assert inline =~ "<h1"
    refute inline =~ "pt-6"

    page = rendered_to_string(~H|<.page_header variant="page" title="T" />|)
    assert page =~ "px-7 pb-0 pt-[26px]"
    assert page =~ "<h1"
  end

  test "page_header show_heading={false} drops the h1" do
    assigns = %{}

    inline =
      rendered_to_string(~H|<.page_header title="T" description="d" show_heading={false} />|)

    refute inline =~ "<h1"
    assert inline =~ "page-header-description"

    page = rendered_to_string(~H|<.page_header variant="page" title="T" show_heading={false} />|)
    refute page =~ "<h1"
  end

  test "page_header density compact uses pt-6 in both variants" do
    assigns = %{}

    inline = rendered_to_string(~H|<.page_header title="T" density="compact" />|)
    assert inline =~ "px-7 pb-[18px] pt-6"
    refute inline =~ "pt-[26px]"

    page = rendered_to_string(~H|<.page_header variant="page" title="T" density="compact" />|)
    assert page =~ "px-7 pb-0 pt-6"
    refute page =~ "pt-[26px]"
  end

  test "framed_sidebar collapsed width: variable with a 60px fallback, style only when given" do
    assigns = %{}

    default = rendered_to_string(~H|<.framed_sidebar id="menu">x</.framed_sidebar>|)
    assert default =~ "data-[collapsed]:w-(--lu-rail-collapsed,60px)"
    refute default =~ "style="

    wide =
      rendered_to_string(
        ~H|<.framed_sidebar id="menu" collapsed_width={72} style="color:red">x</.framed_sidebar>|
      )

    assert wide =~ "--lu-rail-collapsed: 72px;color:red"
    assert wide =~ "data-[collapsed]:w-(--lu-rail-collapsed,60px)"
  end

  test "rail_link trailing slot" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.rail_link href="/s" label="Search">i<:trailing>⌘K</:trailing></.rail_link>|
      )

    assert html =~ ~s(data-part="rail-link-trailing")
    assert html =~ "ml-auto"
    assert html =~ "⌘K"
    assert html =~ ~r/rail-link-trailing"[^>]*group-data-\[collapsed\]\/side:hidden/

    plain = rendered_to_string(~H|<.rail_link href="/s" label="Search">i</.rail_link>|)
    refute plain =~ "rail-link-trailing"
  end

  test "rail_link sub variant matches a rail_module child" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.rail_link href="/a" label="Orders" variant="sub" />|)

    assert html =~ "h-8 pl-10 text-[14px] font-normal"
    refute html =~ "h-[38px]"

    mod =
      rendered_to_string(~H|<.rail_module id="m" label="S">
  <:icon>i</:icon><:item href="/a">Orders</:item>
</.rail_module>|)

    [child_tag] = Regex.run(~r/<a[^>]*rail-module-link[^>]*>/, mod)
    [sub_tag] = Regex.run(~r/<a[^>]*>/, html)
    [_, child] = Regex.run(~r/class="([^"]*)"/, child_tag)
    [_, sub] = Regex.run(~r/class="([^"]*)"/, sub_tag)
    assert String.split(sub) -- String.split(child) == []
  end

  test "rail_module child badge" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.rail_module id="m" label="S">
  <:icon>i</:icon><:item href="/a" badge="3">Orders</:item><:item href="/b">Plain</:item>
</.rail_module>|)

    assert html =~ ~s(data-part="rail-module-link-badge")
    assert html =~ "ml-auto"
    assert length(String.split(html, "rail-module-link-badge")) == 2
    assert html =~ ~r/rail-module-link-badge"[^>]*>\s*3\s*</
  end

  test "rail_heading variants" do
    assigns = %{}
    mono = rendered_to_string(~H|<.rail_heading>Main</.rail_heading>|)
    assert mono =~ "font-mono text-[11px] uppercase tracking-[.06em]"
    assert mono == rendered_to_string(~H|<.rail_heading variant="mono">Main</.rail_heading>|)

    sans = rendered_to_string(~H|<.rail_heading variant="sans">Main</.rail_heading>|)

    for c <-
          ~w(font-sans text-[11.5px] font-medium uppercase tracking-[.08em] text-muted group-data-[collapsed]/side:hidden) do
      assert sans =~ c
    end

    refute sans =~ "font-mono"
  end
end
