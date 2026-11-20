defmodule LedgerUI.Components.AuraTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Aura

  test "mode, tone, width, radius and shadow become classes" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.aura mode="glow" tone="warn" width="lg" radius="pill" shadow>x</.aura>|
      )

    for c <- ~w(lu-aura m-glow t-warn w-lg r-pill shadow), do: assert(html =~ c)
  end

  test "defaults" do
    assigns = %{}
    html = rendered_to_string(~H|<.aura>x</.aura>|)
    for c <- ~w(m-spin t-accent w-default r-default), do: assert(html =~ c)
    refute html =~ "shadow"
  end
end
