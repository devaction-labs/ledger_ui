defmodule LedgerUI.Components.SidebarAuroraTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import Phoenix.LiveViewTest
  import LedgerUI.DiffCase

  @nav [
    %{
      group: "Main",
      items: [
        %{label: "Overview", icon: "home", navigate: "/"},
        %{
          label: "Contacts",
          icon: "users",
          navigate: "/contacts",
          count: 214,
          preview: %{title: "Contacts", description: "Clients and people", image: "/c.png"}
        },
        %{label: "Alerts", icon: "bell", navigate: "/alerts", alert: true}
      ]
    },
    %{
      group: "Sales",
      collapsible: true,
      items: [
        %{
          label: "Orders",
          icon: "box",
          children: [
            %{label: "Proposals", navigate: "/proposals"},
            %{label: "Contracts", navigate: "/contracts"}
          ]
        },
        %{label: "Soon", icon: "clock", disabled: true}
      ]
    },
    %{
      group: "Admin",
      collapsible: true,
      open: false,
      items: [%{label: "Team", icon: "users", navigate: "/team"}]
    },
    %{group: "Help", footer: true, items: [%{label: "Docs", icon: "help", href: "/docs"}]}
  ]

  defp aurora(assigns) do
    assigns =
      assigns
      |> Map.put_new(:nav, @nav)
      |> Map.put_new(:current, "/contracts")
      |> Map.put_new(:collapsed, false)
      |> Map.put_new(:peek, false)
      |> Map.put_new(:persist, true)
      |> Map.put_new(:shortcut, "b")
      |> Map.put_new(:class, nil)

    ~H"""
    <.sidebar
      id="nav"
      format="aurora"
      nav={@nav}
      current={@current}
      collapsed={@collapsed}
      peek={@peek}
      persist={@persist}
      shortcut={@shortcut}
      class={@class}
      persist_groups
      on_collapse="saved"
      brand={%{name: "Orbit Cloud", subtitle: "orbit.startkit.app", logo: "O"}}
      search={%{label: "Search", kbd: "⌘ K", click: "search"}}
      user={%{name: "Alex Nogueira", menu: [%{label: "Sign out", click: "out"}]}}
    />
    """
  end

  defp render_aurora(extra \\ %{}), do: rendered_to_string(aurora(extra))

  defp doc(html), do: LazyHTML.from_fragment(html)

  describe "open and collapsed" do
    test "the root is the hooked aside, 248px, with the format marked" do
      html = render_aurora()
      assert html =~ ~s(<aside id="nav")
      assert html =~ ~s(phx-hook="LedgerUI.Sidebar")
      assert html =~ ~s(data-lu-format="aurora")
      assert html =~ "w-[248px]"
      assert html =~ "data-[collapsed]:w-16"
      assert html =~ "in-data-[collapsed]:w-16"
      assert html =~ ~s(data-lu-collapsed="false")
      refute html =~ ~s( data-collapsed)
    end

    test "collapsed: the root carries data-collapsed and the server state" do
      html = render_aurora(%{collapsed: true})
      assert html =~ ~s(data-lu-collapsed="true")
      assert html =~ ~r/<aside[^>]* data-collapsed/
    end

    test "brand with name and subtitle, search with the shortcut, toggle button, user" do
      html = render_aurora()
      assert html =~ "Orbit Cloud"
      assert html =~ "orbit.startkit.app"
      assert html =~ ~s(data-part="sidebar-aurora-search")
      assert html =~ "⌘ K"
      assert html =~ ~s(phx-click="search")
      assert html =~ ~s(data-lu-sb-toggle)
      assert html =~ ~s(aria-keyshortcuts="Control+B Meta+B")
      assert html =~ "Alex Nogueira"
      assert html =~ ~s(data-part="sidebar-aurora-user")
    end

    test "no search, no user: the cards are left out" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.sidebar format="aurora" nav={[%{label: "A", href: "/a"}]} />|)

      refute html =~ "sidebar-aurora-search"
      refute html =~ "sidebar-aurora-user"
      assert html =~ "sidebar-aurora-toggle"
    end

    test "the icons keep their column: items give back the 5px the collapsed menu pads" do
      html = render_aurora()
      assert html =~ "pl-[15px]"
      assert html =~ "in-data-[collapsed]:pl-2.5"
      assert html =~ "in-data-[collapsed]:px-[5px]"
    end

    test "labels fade in the first half of the 200ms (100ms) and come back in the second" do
      html = render_aurora()

      assert html =~
               "duration-100 delay-100 in-data-[collapsed]:opacity-0 in-data-[collapsed]:delay-0"

      assert html =~ "duration-200"
    end

    test "the mobile top bar still works: the body is the only child below md" do
      assert render_aurora() =~ "max-md:"
    end

    test "active_link is refused, as with rail" do
      assigns = %{}

      assert_raise ArgumentError, ~r/active_link.*aurora/, fn ->
        rendered_to_string(~H|<.sidebar format="aurora" nav={[]} active_link />|)
      end
    end
  end

  describe "groups" do
    test "a group title opens and closes the group: button, aria-expanded and aria-controls" do
      doc = doc(render_aurora())
      sales = LazyHTML.query(doc, ~s(button[data-lu-sb-group="Sales"]))
      assert LazyHTML.attribute(sales, "aria-expanded") == ["true"]
      [body_id] = LazyHTML.attribute(sales, "aria-controls")
      body = LazyHTML.query(doc, "##{body_id}")
      assert LazyHTML.attribute(body, "data-lu-au-body") == [""]
      assert LazyHTML.attribute(body, "data-closed") == []
    end

    test "open: false closes a collapsible group (data-closed on the body, aria-expanded false)" do
      doc = doc(render_aurora())
      admin = LazyHTML.query(doc, ~s(button[data-lu-sb-group="Admin"]))
      assert LazyHTML.attribute(admin, "aria-expanded") == ["false"]
      [body_id] = LazyHTML.attribute(admin, "aria-controls")
      assert LazyHTML.attribute(LazyHTML.query(doc, "##{body_id}"), "data-closed") == [""]
    end

    test "a group that holds the active item starts open" do
      doc = doc(render_aurora(%{current: "/contracts"}))
      sales = LazyHTML.query(doc, ~s(button[data-lu-sb-group="Sales"]))
      assert LazyHTML.attribute(sales, "aria-expanded") == ["true"]
    end

    test "a non-collapsible group has a plain title (no button)" do
      doc = doc(render_aurora())
      assert LazyHTML.query(doc, ~s(button[data-lu-sb-group="Main"])) |> Enum.count() == 0
      assert render_aurora() =~ "Main"
    end

    test "a closed group is closed with a grid row and not with `hidden`, and stays shown when collapsed" do
      html = render_aurora()
      assert html =~ "grid-rows-[1fr]"
      assert html =~ "not-in-data-[collapsed]:data-[closed]:grid-rows-[0fr]"
      assert html =~ "not-in-data-[collapsed]:data-[closed]:invisible"
    end

    test "the titles go away when collapsed" do
      html = render_aurora()
      assert html =~ "in-data-[collapsed]:h-0"
      assert html =~ "in-data-[collapsed]:opacity-0"
    end

    test "persist_groups reaches the hook" do
      assert render_aurora() =~ ~s(data-lu-groups="true")
    end

    test "the footer group is the last run, after a line" do
      html = render_aurora()
      assert html =~ "Docs"
      assert html =~ ~s(data-part="sidebar-aurora-separator")
    end
  end

  describe "items" do
    test "count and alert dot" do
      html = render_aurora()
      assert html =~ ~s(data-part="sidebar-item-count")
      assert html =~ "214"
      assert html =~ ~s(data-part="sidebar-aurora-alert")
      assert html =~ "in-data-[collapsed]:absolute"
    end

    test "the active item is aria-current and painted" do
      doc = doc(render_aurora(%{current: "/contacts"}))
      on = LazyHTML.query(doc, ~s(a[aria-current="page"]))
      assert LazyHTML.text(on) =~ "Contacts"
      assert LazyHTML.attribute(on, "class") |> hd() =~ "bg-panel text-ink"
    end

    test "a disabled item is a span with aria-disabled" do
      html = render_aurora()
      assert html =~ ~s(<span data-part="sidebar-item-disabled" aria-disabled="true")
    end

    test "an item without a preview gets a native title from the hook only (none in the markup)" do
      html = render_aurora()
      refute html =~ ~r/data-lu-au-item[^>]*title=/
    end
  end

  describe "children" do
    test "a parent is a disclosure of its children, with the guide line" do
      doc = doc(render_aurora(%{current: "/proposals"}))
      parent = LazyHTML.query(doc, "[data-lu-au-menu]")
      assert LazyHTML.attribute(parent, "aria-expanded") == ["true"]
      assert LazyHTML.attribute(parent, "data-lu-sb-parent") == ["Orders"]
      [kids] = LazyHTML.attribute(parent, "aria-controls")
      assert LazyHTML.attribute(LazyHTML.query(doc, "##{kids}"), "data-lu-au-body") == [""]
      assert render_aurora() =~ "before:left-6 before:w-[1.5px]"
    end

    test "the active child paints the line and is aria-current" do
      doc = doc(render_aurora(%{current: "/contracts"}))
      on = LazyHTML.query(doc, ~s(a[data-part="sidebar-item-child-link"][aria-current="page"]))
      assert LazyHTML.text(on) =~ "Contracts"
      cls = LazyHTML.attribute(on, "class") |> hd()
      assert cls =~ "before:bg-ink"
      refute cls =~ "before:bg-line-strong"
      off = LazyHTML.query(doc, ~s|a[data-part="sidebar-item-child-link"]:not([aria-current])|)
      assert LazyHTML.attribute(off, "class") |> hd() =~ "before:bg-line-strong"
    end

    test "the parent is open when a child is active and closed otherwise" do
      open = doc(render_aurora(%{current: "/contracts"}))

      kids =
        LazyHTML.attribute(LazyHTML.query(open, "[data-lu-au-menu]"), "aria-controls") |> hd()

      assert LazyHTML.attribute(LazyHTML.query(open, "##{kids}"), "data-closed") == []

      closed = doc(render_aurora(%{current: "/overview"}))

      kids =
        LazyHTML.attribute(LazyHTML.query(closed, "[data-lu-au-menu]"), "aria-controls") |> hd()

      assert LazyHTML.attribute(LazyHTML.query(closed, "##{kids}"), "data-closed") == [""]
    end

    test "the children are hidden when collapsed (the grid row goes to 0)" do
      assert render_aurora() =~ "in-data-[collapsed]:grid-rows-[0fr]"
    end

    test "a parent with a destination is a link, without one a button" do
      nav = [
        %{
          group: "G",
          items: [
            %{label: "Link", navigate: "/l", children: [%{label: "k", navigate: "/k"}]},
            %{label: "Btn", children: [%{label: "j", navigate: "/j"}]}
          ]
        }
      ]

      doc = doc(render_aurora(%{nav: nav}))
      assert LazyHTML.query(doc, "a[data-lu-au-menu]") |> Enum.count() == 1
      assert LazyHTML.query(doc, "button[data-lu-au-menu]") |> Enum.count() == 1

      assert LazyHTML.attribute(LazyHTML.query(doc, "a[data-lu-au-menu]"), "data-lu-sb-dest") == [
               "1"
             ]
    end
  end

  describe "preview (collapsed)" do
    test "the item points at its card with aria-describedby; the card is a tooltip in the DOM" do
      doc = doc(render_aurora())
      item = LazyHTML.query(doc, ~s(a[data-rail-item]))
      [pv] = LazyHTML.attribute(item, "aria-describedby")
      card = LazyHTML.query(doc, "##{pv}")
      assert LazyHTML.attribute(card, "role") == ["tooltip"]
      assert LazyHTML.text(card) =~ "Contacts"
      assert LazyHTML.text(card) =~ "Clients and people"
      assert LazyHTML.attribute(LazyHTML.query(card, "img"), "src") == ["/c.png"]
    end

    test "only an item with a preview has a card and the marker" do
      html = render_aurora()
      assert html |> String.split("data-rail-item") |> length() == 2
      assert html |> String.split(~s(role="tooltip")) |> length() == 2
    end

    test "the preview card is the one of the rail (bg-tip-glass), outside the glass cards" do
      doc = doc(render_aurora())

      assert LazyHTML.attribute(LazyHTML.query(doc, "[data-lu-rail-preview]"), "class") |> hd() =~
               "bg-tip-glass"

      # the nav hosts the RailPreview hook that only works collapsed; the cards are its children
      nav = LazyHTML.query(doc, ~s(nav[phx-hook="LedgerUI.RailPreview"]))
      assert LazyHTML.attribute(nav, "data-lu-when") == ["collapsed"]
      assert LazyHTML.query(nav, "[data-lu-rail-preview]") |> Enum.count() == 1

      assert LazyHTML.query(
               doc,
               ~s(nav > div[data-part="sidebar-aurora-nav"] [data-lu-rail-preview])
             )
             |> Enum.count() == 0
    end
  end

  describe "submenu (collapsed)" do
    test "an item with children owns a floating menu: role=menu, labelled, with menuitems" do
      doc = doc(render_aurora())
      parent = LazyHTML.query(doc, "[data-lu-au-menu]")
      [menu_id] = LazyHTML.attribute(parent, "data-lu-au-menu")
      menu = LazyHTML.query(doc, "##{menu_id}")
      assert LazyHTML.attribute(menu, "role") == ["menu"]
      assert LazyHTML.attribute(menu, "aria-label") == ["Orders"]
      items = LazyHTML.query(menu, ~s([role="menuitem"]))
      assert Enum.count(items) == 2
      assert LazyHTML.attribute(items, "tabindex") == ["-1", "-1"]
    end

    test "the menu is hidden until the hook opens it (data-open), fixed, outside the glass cards" do
      doc = doc(render_aurora())
      menu = LazyHTML.query(doc, "[data-lu-au-menu-box]")
      cls = LazyHTML.attribute(menu, "class") |> hd()
      assert cls =~ "hidden"
      assert cls =~ "fixed"
      assert cls =~ "md:data-[open]:flex"

      assert LazyHTML.query(doc, ~s(div[data-part="sidebar-aurora-nav"] [data-lu-au-menu-box]))
             |> Enum.count() == 0
    end

    test "the expanded markup is a disclosure; the hook turns it into aria-haspopup when collapsed" do
      doc = doc(render_aurora())
      parent = LazyHTML.query(doc, "[data-lu-au-menu]")
      assert LazyHTML.attribute(parent, "aria-haspopup") == []
      assert LazyHTML.attribute(parent, "aria-controls") |> hd() =~ "-kids"
      assert LazyHTML.attribute(parent, "data-lu-au-menu") |> hd() =~ "-menu"
    end

    test "the active child is marked in the submenu too" do
      doc = doc(render_aurora(%{current: "/contracts"}))
      on = LazyHTML.query(doc, ~s([role="menuitem"][aria-current="page"]))
      assert LazyHTML.text(on) =~ "Contracts"
    end
  end

  describe "peek, shortcut, persist, callbacks" do
    test "peek reaches the hook with its delay" do
      html = render_aurora(%{peek: true})
      assert html =~ ~s(data-lu-peek="true")
      assert html =~ ~s(data-lu-peek-delay="300")
      assert html =~ "data-[peek]:w-16"
      assert html =~ "group-data-[peek]/side:absolute"
      assert html =~ "group-data-[peek]/side:shadow-popover"
    end

    test "without peek there is no peek attribute" do
      html = render_aurora()
      refute html =~ "data-lu-peek="
    end

    test "peek_delay is configurable" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.sidebar format="aurora" nav={[]} peek peek_delay={450} />|)

      assert html =~ ~s(data-lu-peek-delay="450")
    end

    test "shortcut, persist and on_collapse" do
      html = render_aurora(%{shortcut: "j", persist: false})
      assert html =~ ~s(data-lu-shortcut="j")
      assert html =~ ~s(data-lu-persist="false")
      assert html =~ ~s(data-lu-on-collapse="saved")
      assert render_aurora() =~ ~s(data-lu-shortcut="b")
      assert render_aurora() =~ ~s(data-lu-persist="true")
    end
  end

  describe "sidebar_script/1" do
    test "marks <html> from the key the hook writes" do
      assigns = %{}
      html = rendered_to_string(~H|<.sidebar_script />|)
      assert html =~ "<script>"
      assert html =~ ~s|localStorage.getItem("ledger-rail")==="1"|
      assert html =~ ~s|setAttribute("data-collapsed","")|
    end

    test "takes the CSP nonce" do
      assigns = %{}
      assert rendered_to_string(~H|<.sidebar_script nonce="abc" />|) =~ ~s(<script nonce="abc">)
    end
  end

  describe "in the aurora shell" do
    test "the :rail slot takes the sidebar and the grid column is auto, so the panel follows the width" do
      assigns = %{nav: @nav}

      html =
        rendered_to_string(~H"""
        <.shell layout="aurora" id="shell">
          <:rail><.sidebar id="nav" format="aurora" nav={@nav} current="/" /></:rail>
          page
        </.shell>
        """)

      assert html =~ ~s(data-layout="aurora")
      assert html =~ "md:grid-cols-[auto_minmax(0,1fr)]"
      assert html =~ ~r/data-part="shell-rail".*<aside id="nav"/s
    end
  end

  describe "change tracking" do
    defp t_aurora(assigns) do
      ~H"""
      <.sidebar
        id="nav"
        format="aurora"
        nav={@nav}
        current={@current}
        collapsed={@collapsed}
        class={@class}
        peek={@peek}
      />
      """
    end

    @big for i <- 1..8,
             do: %{
               label: "item-label-#{i}",
               href: "/i#{i}",
               icon: "home",
               preview: %{title: "pv-title-#{i}"}
             }
    @tnav [
      %{group: "Main", items: @big},
      %{
        group: "Kids",
        items: [
          %{label: "Parent", icon: "box", children: [%{label: "child-label", navigate: "/k"}]}
        ]
      }
    ]
    @base %{nav: @tnav, current: "/i3", collapsed: false, class: "a", peek: false}

    test "collapsing does not send the items again" do
      {first, _} = first(&t_aurora/1, @base)
      patch = patch(&t_aurora/1, @base, %{collapsed: true})
      assert first =~ "item-label-8"
      refute patch =~ "item-label"
      refute patch =~ "pv-title"
      refute patch =~ "child-label"
      assert byte_size(patch) * 10 < byte_size(first)
    end

    test "a new class does not send the items again" do
      {first, _} = first(&t_aurora/1, @base)
      patch = patch(&t_aurora/1, @base, %{class: "b"})
      refute patch =~ "item-label"
      assert byte_size(patch) * 10 < byte_size(first)
    end

    test "peek on or off does not send the items again" do
      {first, _} = first(&t_aurora/1, @base)
      patch = patch(&t_aurora/1, @base, %{peek: true})
      refute patch =~ "item-label"
      assert byte_size(patch) * 10 < byte_size(first)
    end

    test "only the active item changing does not send the whole menu again" do
      {first, _} = first(&t_aurora/1, @base)
      patch = patch(&t_aurora/1, @base, %{current: "/i5"})
      # the two items that changed are in the patch, the other six are not
      assert patch =~ "item-label-3" or patch =~ "bg-panel"

      for i <- [1, 2, 4, 6, 7, 8],
          do: refute(patch =~ "item-label-#{i}", "item #{i} was sent again")

      refute patch =~ "pv-title"
      refute patch =~ "child-label"
      assert byte_size(patch) * 3 < byte_size(first)
    end

    test "each source patches to the same page as a fresh render" do
      each_source(&t_aurora/1, @base, collapsed: true, class: "z", peek: true, current: "/i6")
    end
  end
end
