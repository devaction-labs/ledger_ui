defmodule LedgerUI.Components.AuraTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Aura

  test "mode, tone, width, radius and shadow become utilities" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.aura mode="glow" tone="warn" width="lg" radius="pill" shadow>x</.aura>|
      )

    assert html =~ ~s(data-part="aura")
    assert html =~ "lu-aura-glow"
    assert html =~ "[--t1:var(--lu-warn)]"
    assert html =~ "[--w:2px]"
    assert html =~ "[--r:999px]"
    assert html =~ "filter:drop-shadow"
    refute html =~ "lu-aura "
  end

  test "defaults: a turning light, accent tone, 1.25px ring, 16px corner, no shadow" do
    assigns = %{}
    html = rendered_to_string(~H|<.aura>x</.aura>|)
    assert html =~ "lu-aura-spin"
    assert html =~ "[--t1:var(--lu-accent-500)]"
    assert html =~ "[--w:1.25px]"
    assert html =~ "[--r:16px]"
    refute html =~ "drop-shadow"
  end

  test "dual has the second colour, motion is an alias of mode" do
    assigns = %{}
    html = rendered_to_string(~H|<.aura motion="dual">x</.aura>|)
    assert html =~ "var(--a2)_72%"
  end

  test "the pieces are shared with the toast hook" do
    parts = LedgerUI.Components.Aura.parts()
    assert Map.keys(parts.modes) |> Enum.sort() == ["dual", "glow", "spin"]
    assert Map.has_key?(parts.tones, "ai")
  end
end
