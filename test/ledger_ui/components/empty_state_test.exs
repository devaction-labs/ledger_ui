defmodule LedgerUI.Components.EmptyStateTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.EmptyState

  test "canvas (default) has the art tile, title, reason and action" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.empty_state icon="inbox" title="No orders">
        Nothing here.
        <:action><button>New</button></:action>
      </.empty_state>
      """)

    assert html =~ ~s(class="lu-empty")
    assert html =~ ~s(class="art")
    assert html =~ "<b>No orders</b>"
    assert html =~ "<p>"
    assert html =~ "<button>New</button>"
  end

  test "card variant: tone, kicker and level" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.empty_state
  variant="card"
  icon="inbox"
  title="T"
  tone="gradient"
  kicker="Receivables"
  level={3}
/>|)

    assert html =~ "lu-empty-ring"
    assert html =~ "lu-ic acc"
    assert html =~ "Receivables"
    assert html =~ ~s(aria-level="3")
  end

  test "inline colours and plain" do
    assigns = %{}

    assert rendered_to_string(~H|<.empty_state variant="inline" title="x" color="error" />|) =~
             "var(--neg)"

    assert rendered_to_string(~H|<.empty_state variant="inline" title="x" color="success" />|) =~
             "var(--pos)"

    assert rendered_to_string(~H|<.empty_state variant="plain" title="x" />|) =~
             "lu-small lu-muted"
  end

  test "table variant uses a disc tinted by color; illustration replaces the icon" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.empty_state variant="table" icon="inbox" color="success" title="x">
        <:illustration><i id="art"></i></:illustration>
      </.empty_state>
      """)

    assert html =~ "c-success"
    assert html =~ ~s(id="art")
  end

  test "positive tone paints the canvas icon green" do
    assigns = %{}

    assert rendered_to_string(~H|<.empty_state icon="inbox" title="x" tone="positive" />|) =~
             "--muted:var(--pos)"
  end
end
