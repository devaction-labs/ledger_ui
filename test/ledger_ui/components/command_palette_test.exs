defmodule LedgerUI.Components.CommandPaletteTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.CommandPalette

  defp html(fun), do: fun.(%{}) |> rendered_to_string()

  @items [
    %{
      label: "Orders",
      group: "Go to",
      icon: "cart",
      navigate: "/orders",
      keys: ["G", "O"],
      scope: "pages"
    },
    %{
      label: "New order",
      group: "Actions",
      icon: "plus",
      value: "new",
      scope: "actions",
      sub: "Opens the form"
    },
    %{label: "Loose", value: "x"}
  ]

  test "dialog, input, groups and links" do
    assigns = %{items: @items}

    html =
      rendered_to_string(~H|<.command_palette id="cp" items={@items} on_select="pick" />|)

    assert html =~ ~s(phx-hook="LedgerUI.Overlay")
    assert html =~ ~s(role="dialog")
    assert html =~ ~s(data-state="closed")
    refute html =~ "display:none"
    assert html =~ "lu-cmd"
    assert html =~ ~s(placeholder="Search or type a command")
    assert html =~ "Go to"
    assert html =~ "Actions"
    assert html =~ ~s(href="/orders")
    assert html =~ ~s(data-lu-value="new")
    assert html =~ ~s(data-lu-value="x")
    assert html =~ "Opens the form"
    assert html =~ ~s(<kbd class="lu-kbd">G</kbd>)
    assert html =~ ~s(data-lu-on-select="pick")
    # ungrouped items come first, without a heading
    assert :binary.match(html, "Loose") < :binary.match(html, "Go to")
  end

  test "first row is active unless highlight is typed" do
    assigns = %{items: @items}
    always = rendered_to_string(~H|<.command_palette id="cp" items={@items} />|)
    typed = rendered_to_string(~H|<.command_palette id="cp" items={@items} highlight="typed" />|)
    assert always =~ "lu-menu-item hl"
    refute typed =~ "lu-menu-item hl"
    assert typed =~ ~s(data-lu-highlight="typed")
  end

  test "scopes: the first is pressed" do
    html =
      html(fn assigns ->
        ~H|<.command_palette id="cp" scopes={[{"All", "all"}, {"Pages", "pages"}]} />|
      end)

    assert html =~ ~s(aria-pressed="true")
    assert html =~ ~s(aria-pressed="false")
    assert html =~ ~s(data-lu-scope="pages")
    assert html =~ ~s(aria-label="Where to search")
  end

  test "hints footer and the footer slot; hints false drops the keys" do
    on = html(fn assigns -> ~H|<.command_palette id="cp">
  <:footer>status</:footer>
</.command_palette>| end)
    off = html(fn assigns -> ~H|<.command_palette id="cp" hints={false} />| end)
    assert on =~ "↑↓ Navigate"
    assert on =~ "status"
    assert on =~ "Open in new tab"
    refute off =~ ~s(class="ft")
  end

  test "variants" do
    canvas = html(fn assigns -> ~H|<.command_palette id="cp" />| end)
    classic = html(fn assigns -> ~H|<.command_palette id="cp" variant="classic" />| end)
    assert canvas =~ "border-radius:10px"
    assert canvas =~ "padding:4px"
    refute classic =~ "padding:4px"
  end

  test "assistant row is rendered hidden, with the sparkle by default" do
    html =
      html(fn assigns ->
        ~H|<.command_palette
  id="cp"
  assistant={%{label: "Ask: %{query}", sub: "AI"}}
  on_assistant="ask"
  assistant_mode="always"
/>|
      end)

    assert html =~ "data-lu-assistant"
    assert html =~ ~s(data-icon="sparkles")
    assert html =~ ~s(data-lu-assistant-mode="always")
    assert html =~ ~s(data-lu-on-assistant="ask")
  end

  test "server filtering config and shortcut" do
    html =
      html(fn assigns ->
        ~H|<.command_palette id="cp" on_search="search" debounce={50} shortcut="Mod+j" />|
      end)

    assert html =~ ~s(data-lu-on-search="search")
    assert html =~ ~s(data-lu-debounce="50")
    assert html =~ ~s(data-lu-shortcut="Mod+j")
  end

  test "item_icon slot draws the icon of items without one" do
    assigns = %{items: [%{label: "A", kind: "x"}]}

    html =
      rendered_to_string(~H"""
      <.command_palette id="cp" items={@items}>
        <:item_icon :let={item}><i class="mine">{item.kind}</i></:item_icon>
      </.command_palette>
      """)

    assert html =~ ~s(<i class="mine">x</i>)
  end

  test "bare and inline previews" do
    bare = html(fn assigns -> ~H|<.command_palette id="cp" bare />| end)
    inline = html(fn assigns -> ~H|<.command_palette id="cp" inline />| end)
    refute bare =~ "lu-scrim"
    refute bare =~ "phx-hook"
    assert inline =~ "lu-scrim"
    refute inline =~ "phx-hook"
  end
end
