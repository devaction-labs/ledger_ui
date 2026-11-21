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
          ~s(data-part="kanban"),
          "grid-flow-col",
          "auto-cols-[272px]"
        ],
        do: assert(html =~ c)
  end

  test "--cols in style leaves the grid to the style; fluid shares the width; disabled" do
    assigns = %{}
    cols = rendered_to_string(~H|<.kanban id="b" style="--cols:3">x</.kanban>|)
    refute cols =~ "grid-flow-col"
    assert cols =~ "repeat(var(--cols,3)"
    fluid = rendered_to_string(~H|<.kanban id="b" fluid disabled>x</.kanban>|)
    assert fluid =~ "auto-cols-[minmax(0,1fr)]"
    assert fluid =~ ~s(data-disabled="true")
  end

  test "accent colours the bar with the accent" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.kanban_column id="c" label="L" color="accent">x</.kanban_column>|)

    assert html =~ "[--kc:var(--lu-accent-400)]"
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
          "[--kc:var(--lu-accent-600)]",
          "shadow-[inset_0_3px_0_var(--kc)]",
          ~s(data-list="open"),
          "Open",
          ~s(data-part="kanban-column-count"),
          "60%",
          "R$ 1",
          "width:60%",
          "data-part=\"kanban-column-progress\"",
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
    assert html =~ "[--c:var(--lu-neg)]"
    assert html =~ "text-neg"

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
    assert zero =~ ~s(data-part="kanban-column-hint")
    one = rendered_to_string(~H|<.kanban_column id="c" label="L" count={1}>
  <:empty>Drop here</:empty>
</.kanban_column>|)
    refute one =~ "kanban-column-hint"
    always = rendered_to_string(~H|<.kanban_column id="c" label="L" count={1} hint="always">
  <:empty>Drop here</:empty>
</.kanban_column>|)
    assert always =~ "kanban-column-hint"

    titled =
      rendered_to_string(~H|<.kanban_column id="c" label="L" count={0}>
  <:empty title="No orders" icon="inbox">Wait</:empty>
</.kanban_column>|)

    assert titled =~ "kanban-column-empty"
    assert titled =~ "No orders"
  end

  test "disabled column is dimmed" do
    assigns = %{}
    html = rendered_to_string(~H|<.kanban_column id="c" label="L" disabled>x</.kanban_column>|)
    assert html =~ "opacity-60"
    assert html =~ ~s(data-disabled="true")
  end

  test "card item id, risk, dense and grip" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.kanban_card id="k" item="42" risk dense grip>
        <b>x</b><:actions><i>m</i></:actions>
      </.kanban_card>
      """)

    for c <- [
          "relative",
          "shadow-[0_0_0_2px_var(--lu-warn)]",
          ~s(data-id="42"),
          "p-2",
          "data-grip",
          "data-card-actions"
        ],
        do: assert(html =~ c)

    plain = rendered_to_string(~H|<.kanban_card id="k"><b>x</b></.kanban_card>|)
    refute plain =~ "data-id"
  end

  test "lost aside" do
    assigns = %{}
    html = rendered_to_string(~H|<.kanban_lost label="Lost" count={3} meta="R$ 6" list="lost" />|)

    for c <- ["Lost · R$ 6", ~s(data-list="lost"), ~s(aria-label="Lost"), ">3<", "w-[52px]"],
        do: assert(html =~ c)
  end
end
