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
    assert html =~ "lu-b c-neutral v-ghost s-md"
    assert html =~ "fl p-top-start"
    assert html =~ "lu-pop w-64"
    assert html =~ ~s(<div class="lu-menu-label">Acme</div>)
    assert html =~ ~s(<kbd class="lu-kbd">E</kbd>)
    assert html =~ "lu-menu-item danger"
    assert html =~ "lu-menu-sep"
  end

  test "action_menu defaults to bottom-end" do
    assigns = %{}
    html = norm(~H|<.action_menu id="a" label="x">
  <.action_menu_item>a</.action_menu_item>
</.action_menu>|)
    assert html =~ "p-bottom-end"
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
    assert html =~ "<small>Already accepted</small>"
    assert html =~ "media"
  end

  test "action_button: icon only, text, link, danger, variant, size" do
    assigns = %{}

    html =
      norm(~H"""
      <.action_button label="Delete" icon="trash" danger phx-click="d" />
      <.action_button label="Open" navigate="/x" variant="solid" size="lg">Open</.action_button>
      """)

    assert html =~ ~s(aria-label="Delete")
    assert html =~ "lu-b c-error v-outline s-sm sh-square"
    assert html =~ ~s(phx-click="d")
    assert html =~ "v-solid s-lg"
    refute html =~ "v-solid s-lg sh-square"
    assert html =~ ~s(href="/x")
  end
end
