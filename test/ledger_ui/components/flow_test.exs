defmodule LedgerUI.Components.FlowTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Flow

  describe "layout/3" do
    test "rows follow the depth along the edges; the parent is centred over its children" do
      edges = [%{from: "a", to: "b"}, %{from: "a", to: "c"}, %{from: "b", to: "d"}]
      lay = layout(~w(a b c d), edges, node_width: 300)
      {ax, ay} = lay.positions["a"]
      {bx, by} = lay.positions["b"]
      {cx, cy} = lay.positions["c"]
      {_dx, dy} = lay.positions["d"]
      assert by == cy and by > ay and dy > by
      assert bx < cx
      # centred over the children (b and c share a row 348px apart)
      assert ax == div(bx + cx, 2) or abs(ax - (bx + cx) / 2) <= 1
      assert length(lay.edges) == 3
      assert lay.width > cx and lay.height > dy
    end

    test "without edges the nodes are a grid, four to a row" do
      lay = layout(~w(a b c d e), [])
      {_, y1} = lay.positions["a"]
      {_, y4} = lay.positions["d"]
      {x5, y5} = lay.positions["e"]
      assert y1 == y4 and y5 > y1
      assert x5 == elem(lay.positions["a"], 0)
    end

    test "edge status and selected node" do
      edges = [
        %{from: "a", to: "b", status: "done"},
        %{from: "b", to: "c", status: "error"},
        %{from: "a", to: "d"}
      ]

      lay = layout(~w(a b c d), edges, selected: "d")
      by_to = Map.new(lay.edges, &{&1.to, &1.status})
      assert by_to == %{"b" => "done", "c" => "error", "d" => "selected"}
    end

    test "labelled gaps are taller and edges to unknown nodes or cycles are harmless" do
      plain = layout(~w(a b), [%{from: "a", to: "b"}])
      labelled = layout(~w(a b), [%{from: "a", to: "b", label: "yes"}])
      assert elem(labelled.positions["b"], 1) > elem(plain.positions["b"], 1)
      assert hd(labelled.edges).label == "yes"

      cyc =
        layout(~w(a b), [%{from: "a", to: "b"}, %{from: "b", to: "a"}, %{from: "a", to: "zzz"}])

      assert map_size(cyc.positions) == 2
    end

    test "paths: straight when aligned, elbow otherwise" do
      assert path(10, 0, 10, 50, 25) == "M10 0 V50"
      assert path(10, 0, 110, 100, 50) =~ ~r/^M10 0 V34 Q10 50 26 50 H94 Q110 50 110 66 V100$/
    end

    test "positions can be overridden (dragged nodes)" do
      lay = layout(~w(a b), [%{from: "a", to: "b"}], positions: %{"b" => {500, 400}})
      assert lay.positions["b"] == {500, 400}
    end
  end

  test "renders nodes, sections, edges, labels, toolbar and panel" do
    assigns = %{edges: [%{from: "in", to: "m", label: "ok"}]}

    html =
      rendered_to_string(~H"""
      <.flow id="f" edges={@edges} on_add="add_node" on_move="move" aria-label="Triage">
        <:node
          id="in"
          kind="Trigger"
          kind_icon="check"
          icon="info"
          title="Received"
          status="done"
          metrics={[%{label: "runs", value: "12"}]}
        >
          <.flow_section label="Event">An invoice arrives.</.flow_section>
        </:node>
        <:node id="m" kind="Agent" title="Match" selected>
          <.flow_chips>
            <.flow_chip>erp.lookup</.flow_chip>
          </.flow_chips>
        </:node>
        <:actions :let={id}><button data-del={id}>Del</button></:actions>
        <:hint title="Start here">Then use +</:hint>
        <:toolbar><button>Add node</button></:toolbar>
        <:panel label="Match">
          <.flow_panel_head icon="info" title="Match" on_close="close_panel" />
          <.flow_panel_tabs>tabs</.flow_panel_tabs>
          <.flow_panel_body>fields</.flow_panel_body>
          <.flow_panel_foot><span>Edited</span><span class="sp"></span></.flow_panel_foot>
        </:panel>
      </.flow>
      """)

    for c <- [
          ~s(phx-hook="LedgerUI.Flow"),
          ~s(data-node="in"),
          ~s(data-node="m"),
          "Received",
          "Trigger",
          "An invoice arrives.",
          ~s(data-edge),
          ~s(data-from="in"),
          "ok",
          "border-accent-500",
          ~s(data-del="m"),
          "Start here",
          "Add node",
          ~s(aria-label="Match"),
          "close_panel",
          "fields",
          "tabs",
          "Edited",
          ~s(data-lu-move-event="move"),
          ~s(role="group"),
          "erp.lookup",
          "runs",
          "[&amp;_.sp]:flex-1",
          "Add step after"
        ],
        do: assert(html =~ c, "missing #{c}")

    # the + only under the node with no outgoing edge
    assert length(Regex.scan(~r/aria-label="Add step after"/, html)) == 1
  end

  test "node actions only on the selected node; x/y override the layout" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.flow id="f">
        <:node id="a" title="A" x={10} y={20} />
        <:node id="b" title="B" />
        <:actions :let={id}><i>act-{id}</i></:actions>
      </.flow>
      """)

    assert html =~ "left:10px;top:20px"
    refute html =~ "act-a"
  end

  test "steps turn on branching in the browser: handles, menu and templates" do
    assigns = %{
      steps: [
        %{key: "acao", label: "Ação", title: "Atualizar", sub: "ERP", icon: "zap", tone: "acc"},
        %{
          key: "cond",
          label: "Condição",
          title: "Valor?",
          icon: "filter",
          branches: [%{label: "Sim", tone: "pos"}, %{label: "Não", tone: "neg"}]
        }
      ]
    }

    html =
      rendered_to_string(~H"""
      <.flow id="f" steps={@steps} on_branch="added">
        <:node id="a" title="A" />
      </.flow>
      """)

    assert html =~ ~s(data-branch)
    assert html =~ ~s(data-lu-branch-event="added")
    assert length(Regex.scan(~r/data-part="flow-handle"/, html)) >= 3
    assert html =~ ~s(data-flow-template="node")
    assert html =~ ~s(data-flow-template="ghost")
    assert html =~ ~s(data-part="flow-menu")
    assert html =~ ~s(data-flow-type="cond")
    assert html =~ "&quot;label&quot;:&quot;Sim&quot;"

    plain = rendered_to_string(~H|<.flow id="g"><:node id="a" title="A" /></.flow>|)
    refute plain =~ "flow-handle"
    refute plain =~ "<template"
  end
end
