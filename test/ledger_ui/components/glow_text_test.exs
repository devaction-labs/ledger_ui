defmodule LedgerUI.Components.GlowTextTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.GlowText

  test "tone and tag" do
    assigns = %{}
    assert rendered_to_string(~H|<.glow_text>x</.glow_text>|) =~ "<span"
    html = rendered_to_string(~H|<.glow_text tone="warm" as="h2">x</.glow_text>|)
    assert html =~ "<h2"
    assert html =~ ~s(data-part="glow-text")
    assert html =~ "#e57487"
    assert html =~ "animate-[mo-glowtx_4s_linear_infinite]"
    refute html =~ "lu-glowtx"

    default = rendered_to_string(~H|<.glow_text>x</.glow_text>|)
    assert default =~ "var(--lu-aura-2)"
    refute default =~ "#e57487"
  end
end
