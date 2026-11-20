defmodule LedgerUI.Components.KanbanTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Kanban
  import LedgerUI.Components.Icon

  test "board has the hook, the event and a group role when labelled" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.kanban id="b" event="move" group="orders" aria-label="Funnel" active="open">
        <.kanban_column id="c" label="Open">x</.kanban_column>
      </.kanban>
      """)

    for c <- [
          ~s(phx-hook="LedgerUI.Sortable"),
          ~s(data-event="move"),
          ~s(data-group="orders"),
          ~s(role="group"),
          ~s(data-phone="open"),
          "lu-kanban",
          "grid-auto-flow:column",
          "272px"
        ],
        do: assert(html =~ c)
  end

  test "--cols in style leaves the grid to the style; fluid shares the width; disabled" do
    assigns = %{}
    cols = rendered_to_string(~H|<.kanban id="b" style="--cols:3">x</.kanban>|)
    refute cols =~ "grid-auto-flow"
    fluid = rendered_to_string(~H|<.kanban id="b" fluid disabled>x</.kanban>|)
    assert fluid =~ "minmax(0,1fr)"
    assert fluid =~ ~s(data-disabled="true")
  end

  test "column header, count, colour, list and stats" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.kanban_column
        id="c"
        list="open"
        label="Open"
        count={2}
        color="primary"
        meta="60%"
        total="R$ 1"
        progress={60}
      >
        <:icon><.icon name="check" /></:icon>
        <:actions><button>+</button></:actions>
        cards
      </.kanban_column>
      """)

    for c <- [
          "lu-kcol k-primary",
          ~s(data-list="open"),
          "Open",
          ~s(<span class="n">2</span>),
          "60%",
          "R$ 1",
          "width:60%",
          "<button>+</button>",
          "cards"
        ],
        do: assert(html =~ c)
  end

  test "work in progress limit turns the column red" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.kanban_column id="c" label="Doing" count={4} limit={3} progress={50}>x</.kanban_column>|
      )

    assert html =~ ~s(data-wip="exceeded")
    assert html =~ "var(--neg)"

    ok =
      rendered_to_string(
        ~H|<.kanban_column id="c" label="Doing" count={2} limit={3}>x</.kanban_column>|
      )

    refute ok =~ "data-wip"

    over =
      rendered_to_string(
        ~H|<.kanban_column id="c" label="D" count_label="5 / 3" over_limit>x</.kanban_column>|
      )

    assert over =~ ~s(data-wip="exceeded")
    assert over =~ "5 / 3"
  end

  test "empty hint shows at count 0 only (or always)" do
    assigns = %{}

    zero = rendered_to_string(~H|<.kanban_column id="c" label="L" count={0}>
  <:empty>Drop here</:empty>
</.kanban_column>|)
    assert zero =~ ~s(class="hint")
    one = rendered_to_string(~H|<.kanban_column id="c" label="L" count={1}>
  <:empty>Drop here</:empty>
</.kanban_column>|)
    refute one =~ "hint"
    always = rendered_to_string(~H|<.kanban_column id="c" label="L" count={1} hint="always">
  <:empty>Drop here</:empty>
</.kanban_column>|)
    assert always =~ "hint"

    titled =
      rendered_to_string(~H|<.kanban_column id="c" label="L" count={0}>
  <:empty title="No orders" icon="inbox">Wait</:empty>
</.kanban_column>|)

    assert titled =~ "lu-empty"
    assert titled =~ "No orders"
  end

  test "disabled column is dimmed" do
    assigns = %{}
    html = rendered_to_string(~H|<.kanban_column id="c" label="L" disabled>x</.kanban_column>|)
    assert html =~ "opacity:.6"
    assert html =~ ~s(data-disabled="true")
  end

  test "card item id, risk, dense and grip" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.kanban_card id="k" item="42" risk dense grip class="drag">
        <b>x</b><:actions><i>m</i></:actions>
      </.kanban_card>
      """)

    for c <- [
          "lu-kcard drag",
          ~s(data-id="42"),
          "var(--warn)",
          "padding:8px",
          "data-grip",
          "data-card-actions",
          "position:relative"
        ],
        do: assert(html =~ c)

    plain = rendered_to_string(~H|<.kanban_card id="k"><b>x</b></.kanban_card>|)
    refute plain =~ "data-id"
  end

  test "lost aside" do
    assigns = %{}
    html = rendered_to_string(~H|<.kanban_lost label="Lost" count={3} meta="R$ 6" list="lost" />|)

    for c <- ["Lost · R$ 6", ~s(data-list="lost"), ~s(aria-label="Lost"), ">3<", "width:52px"],
        do: assert(html =~ c)
  end
end
