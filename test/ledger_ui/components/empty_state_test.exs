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

    assert html =~ ~s(data-part="empty-state")
    assert html =~ ~s(data-part="empty-state-art")
    assert html =~ "before:border-dashed"
    assert html =~ ">No orders</b>"
    assert html =~ ~s(data-part="empty-state-text")
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

    assert html =~ ~s(data-part="empty-state-ring")
    assert html =~ "animate-[mo-ring_3s_ease-out_infinite]"
    assert html =~ "animate-[mo-ring_3s_ease-out_1.5s_infinite]"
    assert html =~ "bg-accent-soft"
    assert html =~ "Receivables"
    assert html =~ ~s(aria-level="3")
  end

  test "inline colours and plain" do
    assigns = %{}

    inline = rendered_to_string(~H|<.empty_state variant="inline" title="x" color="error" />|)
    assert inline =~ "text-neg"
    assert inline =~ "border-dashed"

    assert rendered_to_string(~H|<.empty_state variant="inline" title="x" color="success" />|) =~
             "text-pos"

    assert rendered_to_string(~H|<.empty_state variant="plain" title="x" />|) =~ "text-muted"
  end

  test "table variant uses a disc tinted by color; illustration replaces the icon" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.empty_state variant="table" icon="inbox" color="success" title="x">
        <:illustration><i id="art"></i></:illustration>
      </.empty_state>
      """)

    assert html =~ "[--c:var(--lu-pos)]"
    assert html =~ ~s(data-part="empty-state-disc")
    assert html =~ ~s(id="art")
  end

  test "positive tone paints the canvas icon green" do
    assigns = %{}

    assert rendered_to_string(~H|<.empty_state icon="inbox" title="x" tone="positive" />|) =~
             "[--lu-muted:var(--lu-pos)]"
  end

  test "a reason slot with only named slots draws no empty paragraph" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.empty_state title="x">
        <:action><a href="#">Go</a></:action>
      </.empty_state>
      """)

    refute html =~ "empty-state-text"
  end

  test "inline_empty is the inline variant" do
    assigns = %{}
    html = rendered_to_string(~H|<.inline_empty icon="inbox" text="No comments yet" />|)
    assert html =~ "border-dashed"
    assert html =~ "No comments yet"
  end
end
