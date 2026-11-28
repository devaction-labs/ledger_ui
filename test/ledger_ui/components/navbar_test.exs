defmodule LedgerUI.Components.NavbarTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Navbar
  alias Phoenix.LiveView.JS

  test "variant and size classes" do
    assigns = %{}
    html = rendered_to_string(~H|<.navbar variant="float" size="sm">x</.navbar>|)
    assert html =~ "m-2.5 rounded-xl bg-panel"
    assert html =~ "h-[52px]"
    refute html =~ "h-16"
  end

  test "tabs make two rows" do
    assigns = %{}
    html = rendered_to_string(~H|<.navbar>
  a<:tabs>t</:tabs>
</.navbar>|)
    assert html =~ "flex-col items-stretch gap-0 pb-0"
    assert html =~ "h-auto"
  end

  test "crumbs: links, separators, current" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.navbar_crumbs items={[%{label: "A", href: "/a"}, %{label: "B"}]} />|
      )

    assert html =~ ~s(href="/a")
    assert html =~ ~r{<span [^>]*class="text-line-strong">/</span>}
    assert html =~ ~s(aria-current="page")
    assert html =~ ~s(aria-label="Breadcrumb")
  end

  test "search is a button only with phx-click" do
    assigns = %{}
    plain = rendered_to_string(~H|<.navbar_search width="200px" />|)
    refute plain =~ "role="
    assert plain =~ "width:200px"
    click = rendered_to_string(~H|<.navbar_search phx-click="open" />|)
    assert click =~ ~s(role="button")
  end

  test "bell, env, user menu" do
    assigns = %{}
    assert rendered_to_string(~H|<.navbar_bell dot />|) =~ "after:bg-pos"
    assert rendered_to_string(~H|<.navbar_env label="Prod" tone="warn" />|) =~ "bg-warn-soft"

    html =
      rendered_to_string(~H|<.navbar_user id="me" user={%{name: "Ana B"}}>
  <:menu>
    <.navbar_menu_item icon="user" href="/p">Perfil</.navbar_menu_item>
  </:menu>
</.navbar_user>|)

    assert html =~ ~s(role="menu")
    assert html =~ "Perfil"
    assert html =~ "AB"
  end

  test "user menu needs an id" do
    assigns = %{}

    assert_raise ArgumentError, fn ->
      rendered_to_string(~H|<.navbar_user user={%{name: "A"}}>
  <:menu>x</:menu>
</.navbar_user>|)
    end
  end

  test "links mark the current one" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.navbar_links current="/b" items={[%{label: "A", href: "/a"}, %{label: "B", href: "/b"}]} />|
      )

    assert html =~
             ~r/bg-selected text-ink[^>]*aria-current="page"|aria-current="page"[^>]*bg-selected text-ink|aria-current="page"/
  end

  test "plain crumbs with an icon and a search that is a real input" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.navbar_crumbs
  variant="plain"
  icon="grid"
  label="Trilha"
  items={[%{label: "A", href: "#"}, %{label: "B"}]}
/>|)

    assert html =~ ~s(data-part="navbar-crumbs")
    assert html =~ "text-line-strong"
    refute html =~ "canvas"
    assert html =~ ~s(data-icon="grid")

    search =
      rendered_to_string(~H|<.navbar_search input kbd="Ctrl K" placeholder="Search or run…" />|)

    assert search =~ ~r{<input [^>]*placeholder="Search or run…"}
    refute search =~ ~s(class="ph")
  end

  test "navbar_search typing demo: typed text, steps and a caret" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.navbar_search demo="typing" value="pedidos" kbd={nil} />|)

    assert html =~ "animate-[lu-typeloop_6s_steps(var(--steps,20))_infinite]"
    assert html =~ "--steps:7"
    assert html =~ ">pedidos</span>"
    assert html =~ "navbar-search-caret"
    refute html =~ "<input"

    assert rendered_to_string(~H|<.navbar_search loop placeholder="x" />|) =~ "--steps:1"
    refute rendered_to_string(~H|<.navbar_search placeholder="x" />|) =~ "navbar-search-caret"
  end

  test "navbar_bell tone colors the dot and the count" do
    assigns = %{}
    assert rendered_to_string(~H|<.navbar_bell dot />|) =~ "after:bg-pos"
    neg = rendered_to_string(~H|<.navbar_bell dot tone="neg" />|)
    assert neg =~ "after:bg-neg"
    assert rendered_to_string(~H|<.navbar_bell count={3} />|) =~ "bg-neg text-white"
    warn = rendered_to_string(~H|<.navbar_bell dot tone="warn" />|)
    assert warn =~ "after:bg-[#f59e0b]"
    refute warn =~ "after:bg-neg"
    assert rendered_to_string(~H|<.navbar_bell count={3} tone="warn" />|) =~ "bg-[#f59e0b]"
  end

  test "navbar_search size: md keeps the 36px field, sm is the compact 32px one" do
    assigns = %{}
    md = rendered_to_string(~H|<.navbar_search />|)
    assert md =~ "h-9 rounded-md"
    assert md =~ "bg-sunken px-3 text-ink"
    refute md =~ "h-8"

    sm = rendered_to_string(~H|<.navbar_search size="sm" />|)
    assert sm =~ "h-8 rounded-[8px]"
    assert sm =~ "bg-sunken px-2.5 text-ink"
    refute sm =~ "h-[38px]"
    refute sm =~ "px-3"
  end

  describe "navbar_cluster" do
    test "a bordered capsule, rounded by default, md" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.navbar_cluster><.navbar_bell dot /></.navbar_cluster>|)

      assert html =~ ~s(data-part="navbar-cluster")
      assert html =~ "border border-line"
      assert html =~ "rounded-md [&amp;_[data-part=navbar-search]]:rounded-sm"
      assert html =~ "[&amp;_[data-part=navbar-search]]:bg-tray"
      assert html =~ "[&amp;_[data-part=navbar-icon]]:size-8"
      assert html =~ "[&amp;_[data-part=navbar-icon]_svg]:size-[18px]"
      assert html =~ "[&amp;_[data-part=navbar-icon]]:after:size-2"
      refute html =~ "rounded-full [&"
      assert html =~ "p-1 "
      assert html =~ "[&amp;_[data-part=navbar-icon]]:border-0"
      assert html =~ "[&amp;_[data-part=navbar-bell-count]]:border-panel"
    end

    test "pill and sm" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.navbar_cluster shape="pill" size="sm" label="Actions">x</.navbar_cluster>|
        )

      assert html =~ "rounded-full"
      refute html =~ "rounded-md [&"
      assert html =~ "p-[3px]"
      assert html =~ "[&amp;_[data-part=navbar-icon]]:size-7"
      assert html =~ ~s(aria-label="Actions")
    end

    test "the pieces keep their own HTML outside the cluster" do
      assigns = %{}
      alone = rendered_to_string(~H|<.navbar_bell dot />|)
      inside = rendered_to_string(~H|<.navbar_cluster><.navbar_bell dot /></.navbar_cluster>|)
      assert inside =~ alone
      assert alone =~ "after:shadow-[0_0_0_2px_var(--lu-bg-panel)]"
    end

    test "bell with a count and a fullscreen button" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.navbar_cluster>
  <.navbar_bell count={12} />
  <.navbar_icon name="maximize" label="Fullscreen" phx-click={JS.dispatch("lu:fullscreen")} />
</.navbar_cluster>|)

      assert html =~ ~s(data-part="navbar-bell-count")
      assert html =~ "[&amp;_[data-part=navbar-bell-count]]:h-4"
      assert html =~ "rounded-[5px]"
      assert html =~ "bg-neg"
      assert html =~ "lu:fullscreen"
    end

    test "navbar_fullscreen dispatches lu:fullscreen and carries aria-pressed" do
      assigns = %{}
      html = rendered_to_string(~H|<.navbar_cluster><.navbar_fullscreen /></.navbar_cluster>|)
      assert html =~ "lu:fullscreen"
      assert html =~ ~s(aria-pressed="false")
      assert html =~ "data-lu-fullscreen"
      assert html =~ ~s(aria-label="Fullscreen")
      assert html =~ ~s(data-part="navbar-icon")
      pt = rendered_to_string(~H|<.navbar_fullscreen locale="pt_BR" />|)
      assert pt =~ ~s(aria-label="Tela cheia")
    end

    test "the dot is 8px with a panel ring" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.navbar_cluster size="sm"><.navbar_bell dot /></.navbar_cluster>|)

      assert html =~ "[&amp;_[data-part=navbar-icon]]:after:size-2"
      assert html =~ "after:shadow-[0_0_0_2px_var(--lu-bg-panel)]"
    end
  end

  describe "navbar_search icon_only" do
    test "only the icon, a button when clickable" do
      assigns = %{}
      html = rendered_to_string(~H|<.navbar_search icon_only phx-click="open" />|)
      assert html =~ "data-icon-only"
      assert html =~ ~s(role="button")
      assert html =~ ~s(aria-label="Search)
      assert html =~ "<svg"
      refute html =~ "navbar-search-value"
      refute html =~ "<kbd"
    end

    test "default HTML has no icon-only marks" do
      assigns = %{}
      html = rendered_to_string(~H|<.navbar_search />|)
      refute html =~ "data-icon-only"
      refute html =~ "aria-label"
      assert html =~ "navbar-search-value"
      assert html =~ "<kbd"
    end
  end
end
