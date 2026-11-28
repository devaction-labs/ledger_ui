defmodule LedgerUI.Components.TreeviewTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Treeview

  test "leaf and branch rows" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.treeview id="t">
        <.tree_item id="a" label="App" expanded count="2">
          <.tree_item id="b" label="Chrome" selected />
        </.tree_item>
      </.treeview>
      """)

    assert html =~ ~s(phx-hook="LedgerUI.Treeview")
    assert html =~ ~s(data-icon="chevron-down")
    assert html =~ ~s(aria-selected="true")
    assert html =~ ~s(data-part="tree-children")
    assert html =~ ~s(data-part="tree-count")
    assert html =~ ~s(data-part="tree-spacer")
    refute html =~ "lu-"
  end

  test "collapsed branches hide their children and show a right chevron" do
    assigns = %{}
    html = rendered_to_string(~H|<.treeview id="t">
  <.tree_item label="A"><.tree_item label="B" /></.tree_item>
</.treeview>|)
    assert html =~ "chevron-right"
    assert html =~ ~r|data-part="tree-children"[^>]*hidden|
  end

  test "checked: true, false and mixed" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.treeview id="t">
        <.tree_item label="a" checked={true} />
        <.tree_item label="b" checked={false} />
        <.tree_item label="c" checked="mixed" />
        <.tree_item label="d" />
      </.treeview>
      """)

    assert length(String.split(html, ~s(data-part="tree-check"))) == 4
    assert html =~ "checked"
    assert html =~ ~s(data-ind="1")
  end

  test "the checkbox keeps its 18px box and gets a 24px hit area (before:)" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.treeview id="t"><.tree_item label="a" checked={false} /></.treeview>|
      )

    [input] = Regex.run(~r/<input[^>]*data-part="tree-check-input"[^>]*>/, html)
    assert input =~ "size-[18px]"
    assert input =~ "before:-inset-[3px]"
    assert input =~ "before:absolute"
  end

  test "events and options go to the root as data attributes" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.treeview id="t" on_toggle="toggled" on_select="opened" chevrons={false} expanded={["a"]} />|
      )

    assert html =~ ~s(data-on-toggle="toggled")
    assert html =~ ~s(data-on-select="opened")
    assert html =~ ~s(data-chevrons="false")
    assert html =~ "data-expanded"
  end

  test "depth indents side by side rows; tag wraps the row" do
    assigns = %{}
    assert rendered_to_string(~H|<.tree_item label="x" depth={2} />|) =~ "padding-left:44px"
    assert rendered_to_string(~H|<.tree_item label="x" tag="li" />|) =~ "<li"
  end

  test "rows from a stream" do
    stream = Phoenix.LiveView.LiveStream.new(:files, 0, [%{id: 1, name: "a.ex"}], [])
    assigns = %{stream: stream}

    html =
      rendered_to_string(~H"""
      <.treeview id="files" rows={@stream}>
        <:row :let={{_dom_id, f}}><.tree_item id={"file-#{f.id}"} label={f.name} /></:row>
      </.treeview>
      """)

    assert html =~ ~s(phx-update="stream")
    assert html =~ "a.ex"
    assert html =~ ~s(id="file-1")
  end

  describe "tree/1 draws a leaf as a leaf" do
    setup do
      assigns = %{
        items: [
          %{
            id: "a",
            label: "Pasta A",
            children: [%{id: "a1", label: "Arquivo 1"}, %{id: "a2", label: "Arquivo 2"}]
          },
          %{
            id: "b",
            label: "Pasta B",
            expanded: true,
            children: [%{id: "b1", label: "Arquivo 3"}]
          },
          %{id: "c", label: "Vazia", children: []},
          %{id: "d", label: "Solta", expanded: true}
        ]
      }

      {:ok, html: rendered_to_string(~H|<.tree id="tree-a" items={@items} />|)}
    end

    defp row(html, id) do
      [_, rest] = String.split(html, ~s(id="#{id}" data-part="tree-item"), parts: 2)
      rest |> String.split("</div>", parts: 2) |> hd()
    end

    test "a leaf has no aria-expanded, no aria-owns and no chevron", %{html: html} do
      for id <- ~w(a1 a2 b1 c d) do
        r = row(html, id)
        refute r =~ "aria-expanded", id
        refute r =~ "aria-owns", id
        refute r =~ "tree-chevron", id
        assert r =~ "tree-spacer", id
        refute html =~ ~s(id="#{id}-kids")
      end
    end

    test "a branch keeps its chevron, aria-expanded and group", %{html: html} do
      assert row(html, "a") =~ ~s(aria-expanded="false")
      assert row(html, "a") =~ ~s(aria-owns="a-kids")
      assert row(html, "a") =~ "tree-chevron"
      assert row(html, "b") =~ ~s(aria-expanded="true")
      assert html =~ ~s(id="a-kids")
      assert html =~ ~s(id="b-kids")
    end

    test "the order of the siblings is kept", %{html: html} do
      ids = Regex.scan(~r/id="([a-d]\d?)" data-part="tree-item"/, html) |> Enum.map(&List.last/1)
      assert ids == ~w(a a1 a2 b b1 c d)
    end
  end
end
