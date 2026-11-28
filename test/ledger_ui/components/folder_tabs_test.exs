defmodule LedgerUI.Components.FolderTabsTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.FolderTabs
  alias Phoenix.LiveView.JS

  defp norm(rendered) do
    rendered
    |> rendered_to_string()
    |> String.replace(~r/\s+/, " ")
    |> String.replace(~r/>\s+/, ">")
    |> String.replace(~r/\s+</, "<")
  end

  # the opening tag of the n-th element with `data-part`
  defp tag(html, part, n \\ 0) do
    ~r/<[a-z0-9]+[^>]*data-part="#{part}"[^>]*>/ |> Regex.scan(html) |> Enum.at(n) |> hd()
  end

  defp tabs_of(html), do: Regex.scan(~r/<(?:button|a)[^>]*data-part="folder-tab"[^>]*>/, html)

  defp page(assigns) do
    ~H"""
    <.folder_tabs id="p" active={@active} size={@size} max={@max} on_change="tab">
      <:tab id="geral" label="Visão geral" count={12} icon="map" />
      <:tab id="receita" label="Receita" />
      <:tab id="insights" label="Insights" />
      <:tab id="metas" label="Metas" count="3" />
      <:tab id="logs" label="Logs" />
      <:content>conteúdo</:content>
    </.folder_tabs>
    """
  end

  defp render_page(extra \\ %{}) do
    assigns = Map.merge(%{active: "receita", size: "md", max: nil}, extra)
    norm(~H|<.page active={@active} size={@size} max={@max} />|)
  end

  test "the active tab: aria-selected, data-state, roving tabindex, panel fill" do
    html = render_page()
    [geral, receita | _] = tabs_of(html) |> Enum.map(&hd/1)

    assert receita =~ ~s(aria-selected="true")
    assert receita =~ ~s(data-state="on")
    assert receita =~ ~s(tabindex="0")
    assert geral =~ ~s(aria-selected="false")
    refute geral =~ "data-state"
    assert geral =~ ~s(tabindex="-1")
    assert html =~ ~s(class="pointer-events-none)
    assert html =~ "group-data-[state=on]/ft:fill-panel"
  end

  test "the first tab is active when active is nil or unknown" do
    for a <- [nil, "nope"] do
      [first | rest] = render_page(%{active: a}) |> tabs_of() |> Enum.map(&hd/1)
      assert first =~ ~s(aria-selected="true")
      assert Enum.all?(rest, &(&1 =~ ~s(aria-selected="false")))
    end
  end

  test "inactive tabs: tab-1 on the first inactive, tab-2 on the others; z-index falls" do
    html = render_page(%{active: "receita"})
    paths = Regex.scan(~r/<path d="[^"]*" class="([^"]*)"/, html) |> Enum.map(&Enum.at(&1, 1))
    tones = Enum.map(paths, &Regex.run(~r/fill-tab-[12]/, &1))
    assert tones == [["fill-tab-1"], nil, ["fill-tab-2"], ["fill-tab-2"], ["fill-tab-2"]]
    assert Enum.at(paths, 1) =~ "fill-panel"
    assert html =~ "group-[:not([data-state=on]):hover]/ft:fill-tab-hov"
    assert html =~ ~s(style="--z:5")
    assert html =~ ~s(style="--z:1")
  end

  test "the SVG is decorative and has the md path" do
    html = render_page()
    assert html =~ ~s(aria-hidden="true")

    assert html =~
             ~s(d="M0 54 L0 18 Q0 0 18 0 L200 0 C218 0 224 5 231 16 L250 45 C256 52 261 54 270 54 Z")

    assert html =~ ~s(viewBox="0 0 270 54")
  end

  test "size sm: 220x44, overlap -38px, padding 40, the sm path" do
    html = render_page(%{size: "sm"})
    t = tag(html, "folder-tab")
    assert t =~ "h-11"
    assert t =~ "w-[220px]"
    assert t =~ "-mr-[38px]"
    assert t =~ "pl-10"
    assert html =~ ~s(viewBox="0 0 220 44")

    assert html =~
             ~s(d="M0 44 L0 18 Q0 0 18 0 L150 0 C168 0 174 5 181 16 L200 35 C206 42 211 44 220 44 Z")
  end

  test "size md: 270x54, overlap -46px, padding 52" do
    t = tag(render_page(), "folder-tab")
    assert t =~ "h-[54px]"
    assert t =~ "w-[270px]"
    assert t =~ "-mr-[46px]"
    assert t =~ "pl-[52px]"
  end

  test "count and icon" do
    html = render_page()
    assert html =~ ~r/data-part="folder-tab-count"[^>]*>12</
    assert html =~ ~r/data-part="folder-tab-count"[^>]*>3</
    assert html =~ "group-data-[state=on]/ft:bg-ink"
    assert html =~ "group-data-[state=on]/ft:text-panel"
    assert html =~ ~s(data-icon="map")
    assert length(Regex.scan(~r/data-part="folder-tab-count"/, html)) == 2
  end

  test "ARIA: tablist, tabs, tabpanel labelled by the active tab, aria-controls" do
    html = render_page()
    assert tag(html, "folder-tabs-list") =~ ~s(role="tablist")
    assert length(Regex.scan(~r/role="tab"/, html)) == 5
    panel = tag(html, "folder-tabs-panel")
    assert panel =~ ~s(role="tabpanel")
    assert panel =~ ~s(id="p-panel")
    assert panel =~ ~s(aria-labelledby="p-tab-receita")
    assert tabs_of(html) |> Enum.map(&hd/1) |> Enum.at(1) =~ ~s(aria-controls="p-panel")
    assert html =~ ~s(phx-hook="LedgerUI.Tabs")
  end

  test "without :content there is no panel and no aria-controls" do
    assigns = %{}

    html =
      norm(~H"""
      <.folder_tabs id="p" on_change="tab">
        <:tab id="a" label="A" />
        <:tab id="b" label="B" />
      </.folder_tabs>
      """)

    refute html =~ "tabpanel"
    refute html =~ "aria-controls"
  end

  test "on_change: buttons with phx-click and phx-value-tab (and phx-target)" do
    assigns = %{}

    html =
      norm(~H"""
      <.folder_tabs id="p" on_change="tab" target="#me">
        <:tab id="a" label="A" />
        <:tab id="b" label="B" />
      </.folder_tabs>
      """)

    assert [a, b] = tabs_of(html) |> Enum.map(&hd/1)
    assert a =~ ~s(phx-click="tab") and a =~ ~s(phx-value-tab="a") and a =~ ~s(phx-target="#me")
    assert b =~ ~s(phx-value-tab="b")
    assert a =~ "<button"
  end

  test "patch: links with data-phx-link, no phx-click" do
    assigns = %{}

    html =
      norm(~H"""
      <.folder_tabs id="p" active="b">
        <:tab id="a" label="A" patch="/x?tab=a" />
        <:tab id="b" label="B" patch="/x?tab=b" />
      </.folder_tabs>
      """)

    assert [a, b] = tabs_of(html) |> Enum.map(&hd/1)
    assert a =~ "<a "
    assert a =~ ~s(href="/x?tab=a")
    assert a =~ ~s(data-phx-link="patch")
    assert a =~ ~s(role="tab")
    refute a =~ "phx-click"
    assert b =~ ~s(aria-selected="true")
  end

  test "a %JS{} in on_change raises" do
    assigns = %{js: JS.push("x")}

    assert_raise ArgumentError, ~r/on_change/, fn ->
      rendered_to_string(~H"""
      <.folder_tabs id="p" on_change={@js}>
        <:tab id="a" label="A" />
      </.folder_tabs>
      """)
    end
  end

  describe "max (overflow)" do
    test "no overflow when the tabs fit" do
      html = render_page(%{max: 5})
      refute html =~ "folder-tabs-more"
      assert length(tabs_of(html)) == 5
    end

    test "+N button with the remaining tabs in a dropdown" do
      html = render_page(%{max: 3, active: "geral"})
      assert length(tabs_of(html)) == 3
      assert tag(html, "folder-tabs-more") =~ ~s(aria-label="More tabs")
      assert html =~ ~r/data-part="folder-tabs-more".*?\+2/
      assert tag(html, "folder-tabs-more") =~ ~s(aria-haspopup="menu")
      assert html =~ ~s(id="p-more")
      menu = html |> String.split(~s(id="p-more"), parts: 2) |> List.last()
      assert menu =~ "Metas"
      assert menu =~ "Logs"
      refute menu =~ "Receita"
      assert menu =~ ~s(phx-click="tab")
      assert menu =~ ~s(phx-value-tab="metas")
    end

    test "an active tab in the overflow takes the last visible place" do
      html = render_page(%{max: 3, active: "logs"})
      [a, b, c] = tabs_of(html) |> Enum.map(&hd/1)
      assert a =~ ~s(id="p-tab-geral")
      assert b =~ ~s(id="p-tab-receita")
      assert c =~ ~s(id="p-tab-logs") and c =~ ~s(aria-selected="true")
      menu = html |> String.split(~s(id="p-more"), parts: 2) |> List.last()
      assert menu =~ "Insights"
      assert menu =~ "Metas"
      assert html =~ ~r/data-part="folder-tabs-more".*?\+2/
      refute menu =~ "Logs"
    end

    test "overflow items with patch are links" do
      assigns = %{}

      html =
        norm(~H"""
        <.folder_tabs id="p" max={1} active="a">
          <:tab id="a" label="A" patch="/x?tab=a" />
          <:tab id="b" label="B" patch="/x?tab=b" />
        </.folder_tabs>
        """)

      assert html =~ ~s(href="/x?tab=b")
    end
  end

  test "pt_BR locale: the +N label" do
    assigns = %{}

    html =
      norm(~H"""
      <.folder_tabs id="p" max={1} locale="pt_BR">
        <:tab id="a" label="A" />
        <:tab id="b" label="B" />
      </.folder_tabs>
      """)

    assert html =~ ~s(aria-label="Mais abas")
  end

  describe "tracked changes" do
    import LedgerUI.DiffCase, only: [check: 3, each_source: 3]

    defp fun(assigns), do: page(assigns)

    test "switching the active tab patches like a fresh render" do
      base = %{active: "geral", size: "md", max: nil}
      check(&fun/1, base, active: "insights")
      check(&fun/1, %{base | active: "receita"}, active: nil)
    end

    test "switching the active tab with overflow patches like a fresh render" do
      base = %{active: "geral", size: "md", max: 3}
      check(&fun/1, base, active: "logs")
      check(&fun/1, %{base | active: "logs"}, active: "receita")
      check(&fun/1, base, max: 2)
    end

    test "size and max patch like a fresh render" do
      base = %{active: "geral", size: "md", max: nil}
      check(&fun/1, base, size: "sm")
      check(&fun/1, base, max: 2)
      each_source(&fun/1, base, active: "metas", size: "sm", max: 2)
    end
  end
end
