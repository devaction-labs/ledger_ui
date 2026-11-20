defmodule LedgerUI.Components.ContextMenuTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.ContextMenu

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

  test "renders the area, the hook and the items" do
    assigns = %{}

    html =
      norm(~H"""
      <.context_menu id="m" label="File actions" class="area">
        <p>Right click</p>
        <:item phx-click="rename" kbd="F2" icon="edit">Rename</:item>
        <:item phx-click="delete" phx-value-id="7" tone="danger" divider>Delete</:item>
        <:item disabled>Locked</:item>
      </.context_menu>
      """)

    assert html =~ ~s(phx-hook="LedgerUI.ContextMenu")
    assert html =~ "Right click"
    assert html =~ ~s(role="menu")
    assert html =~ ~s(aria-label="File actions")
    assert html =~ ~s(phx-click="rename")
    assert html =~ ~s(phx-value-id="7")
    assert tag(html, "pop-item", 1) =~ "text-neg"
    assert tag(html, "pop-separator") =~ "h-px"
    assert tag(html, "pop") =~ "bg-panel"
    assert tag(html, "pop-kbd") =~ "font-mono"
    assert html =~ ~s(aria-disabled="true")
    assert html =~ "F2"
    assert html =~ ~s(class="area")
  end

  test "default label" do
    assigns = %{}
    html = norm(~H|<.context_menu id="m">
  <p>a</p><:item>x</:item>
</.context_menu>|)
    assert html =~ ~s(aria-label="Actions")
  end
end
