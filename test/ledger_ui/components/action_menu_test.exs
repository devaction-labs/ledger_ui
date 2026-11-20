defmodule LedgerUI.Components.ActionMenuTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.ActionMenu

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

  test "action_menu: button, title, placement, hook" do
    assigns = %{}

    html =
      norm(~H"""
      <.action_menu id="am" label="Actions of Acme" placement="top-start" class="w-64">
        <:title>Acme</:title>
        <.action_menu_item icon="edit" kbd="E" phx-click="e">Edit</.action_menu_item>
        <.action_menu_separator />
        <.action_menu_item danger icon="trash">Delete</.action_menu_item>
      </.action_menu>
      """)

    assert html =~ ~s(phx-hook="LedgerUI.ActionMenu")
    assert html =~ ~s(aria-label="Actions of Acme")
    assert tag(html, "action-menu-trigger") =~ "bg-transparent"
    assert tag(html, "action-menu-trigger") =~ "h-9"
    assert tag(html, "action-menu-panel") =~ ~s(data-lu-placement="top-start")
    assert tag(html, "pop") =~ "w-64"
    assert tag(html, "pop-label") =~ ~s(role="presentation")
    assert html =~ ~r/<kbd[^>]*>E<\/kbd>/
    assert tag(html, "pop-item", 1) =~ "text-neg"
    assert tag(html, "pop-separator") =~ "h-px"
    refute html =~ ~r/[\s"]lu-/
  end

  test "action_menu defaults to bottom-end" do
    assigns = %{}
    html = norm(~H|<.action_menu id="a" label="x">
  <.action_menu_item>a</.action_menu_item>
</.action_menu>|)
    assert tag(html, "action-menu-panel") =~ ~s(data-lu-placement="bottom-end")
  end

  test "item: link vs button, disabled with hint" do
    assigns = %{}

    html =
      norm(~H"""
      <.action_menu_item navigate="/x" icon="external">Open</.action_menu_item>
      <.action_menu_item disabled hint="Already accepted" phx-click="r">Resend</.action_menu_item>
      """)

    assert html =~ "<a"
    assert html =~ ~s(href="/x")
    assert html =~ ~s(aria-disabled="true")
    assert html =~ ~r/<small[^>]*>Already accepted<\/small>/
    assert tag(html, "pop-item", 1) =~ "h-auto"
  end

  test "action_button: icon only, text, link, danger, variant, size" do
    assigns = %{}

    html =
      norm(~H"""
      <.action_button label="Delete" icon="trash" danger phx-click="d" />
      <.action_button label="Open" navigate="/x" variant="solid" size="lg">Open</.action_button>
      """)

    assert html =~ ~s(aria-label="Delete")
    # outline error, sm, square
    assert tag(html, "action-button", 0) =~ "[--c:var(--lu-neg)]"
    assert tag(html, "action-button", 0) =~ "w-[30px]"
    assert tag(html, "action-button", 0) =~ "bg-transparent"
    assert html =~ ~s(phx-click="d")
    # solid lg with text: not square
    assert tag(html, "action-button", 1) =~ "h-11"
    refute tag(html, "action-button", 1) =~ "w-11"
    assert html =~ ~s(href="/x")
  end
end
