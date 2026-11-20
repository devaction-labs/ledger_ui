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

  test "variant, color, active link items" do
    assigns = %{}

    html =
      norm(~H"""
      <.menu_list variant="solid" color="neutral" id="nav">
        <:item navigate="/a" active>A</:item>
        <:item href="/b" count={12}>B</:item>
      </.menu_list>
      """)

    assert html =~ ~s(<nav id="nav" class="lu-ml solid c-neutral">)
    assert html =~ ~s(class="on")
    assert html =~ ~s(href="/b")
    assert html =~ ~s(<span class="lu-badge sm" style="margin-left:auto">12</span>)
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
    assert html =~ "lu-ml static c-primary"
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

    assert html =~ ~s(<div id="l" class="lu-list">)
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

    assert html =~ ~s(class="on")
    assert html =~ "pick"
    assert html =~ ">3<"
    assert html =~ ~s(<nav class="lu-ml pill c-neutral">)
  end

  test "menu_row as a link" do
    assigns = %{}
    html = norm(~H|<.menu_row navigate="/c" title="Acme" sub="12 users" />|)
    assert html =~ ~s(href="/c")
    assert html =~ ~s(class="t")
    assert html =~ "12 users"
  end
end
