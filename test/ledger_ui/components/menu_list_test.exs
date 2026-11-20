defmodule LedgerUI.Components.MenuListTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.MenuList

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

  test "variant, color, active link items" do
    assigns = %{}

    html =
      norm(~H"""
      <.menu_list variant="solid" color="neutral" id="nav">
        <:item navigate="/a" active>A</:item>
        <:item href="/b" count={12}>B</:item>
      </.menu_list>
      """)

    # the list carries the look of its links; the active one is marked data-on
    assert tag(html, "menu-list") =~ ~s(id="nav")
    assert tag(html, "menu-list") =~ "[&amp;_a[data-state=on]]:bg-ink"
    assert tag(html, "menu-item", 0) =~ ~s(data-state="on")
    assert tag(html, "menu-item", 0) =~ ~s(aria-current="page")
    refute tag(html, "menu-item", 1) =~ ~s(data-state="on")
    assert tag(html, "menu-item", 1) =~ ~s(href="/b")
    assert tag(html, "menu-item-count") =~ "ml-auto"
    assert tag(html, "menu-item-count") =~ "h-[18px]"
    refute html =~ ~r/[\s"]lu-/
  end

  test "items with a value push on_select" do
    assigns = %{}

    html =
      norm(~H"""
      <.menu_list on_select="pick" target="#x">
        <:item value="shipping">Shipping</:item>
      </.menu_list>
      """)

    assert html =~ ~s(role="button")
    assert html =~ "pick"
    assert html =~ "shipping"
  end

  test "static with :item slots stays a nav" do
    assigns = %{}
    html = norm(~H|<.menu_list variant="static">
  <:item href="#">A</:item>
</.menu_list>|)
    assert tag(html, "menu-list") =~ "[&amp;_a]:pointer-events-none"
    refute tag(html, "menu-list") =~ "[&amp;_a[data-state=on]]"
  end

  test "static rows render a lu-list div" do
    assigns = %{rows: [%{t: "Fatura", s: "Acme"}]}

    html =
      norm(~H"""
      <.menu_list variant="static" id="l" rows={@rows}>
        <:row :let={r}>
          <.menu_row title={r.t} sub={r.s} unread>
            <:value>R$ 1</:value>
          </.menu_row>
        </:row>
      </.menu_list>
      """)

    assert tag(html, "menu-rows") =~ ~s(id="l")
    assert tag(html, "menu-rows") =~ "border-line"
    assert tag(html, "menu-row") =~ "last:border-b-0"
    assert tag(html, "menu-row-unread") =~ "bg-accent-500"
    assert html =~ "Fatura"
    assert html =~ "Acme"
    assert html =~ "R$ 1"
    assert html =~ ~s(aria-label="Unread")
  end

  test "menu_item: link, button with on_select, variant wraps in nav" do
    assigns = %{}

    html =
      norm(~H"""
      <.menu_item navigate="/a" active>A</.menu_item>
      <.menu_item value="b" on_select="pick">
        B<:count>3</:count>
      </.menu_item>
      <.menu_item variant="pill" color="neutral" href="/c">C</.menu_item>
      """)

    assert tag(html, "menu-item", 0) =~ ~s(data-state="on")
    assert html =~ "pick"
    assert html =~ ">3<"
    assert tag(html, "menu-list") =~ "[&amp;_a]:rounded-full"
    assert tag(html, "menu-list") =~ "[&amp;_a[data-state=on]]:bg-selected"
  end

  test "menu_row as a link" do
    assigns = %{}
    html = norm(~H|<.menu_row navigate="/c" title="Acme" sub="12 users" />|)
    assert html =~ ~s(href="/c")
    assert tag(html, "menu-row-title") =~ "font-medium"
    assert html =~ "12 users"
  end
end
