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
end
