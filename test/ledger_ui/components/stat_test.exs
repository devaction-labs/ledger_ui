defmodule LedgerUI.Components.StatTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Stat

  test "item sizes and tones" do
    assigns = %{}
    html = rendered_to_string(~H|<.stat_item label="a" value="1" tone="accent" size="sm" />|)
    assert html =~ "font-size:18px;color:var(--accent-ink)"
  end

  test "group is a grid panel" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.stat_group columns={2}><.stat_item cell label="a" value="1" /></.stat_group>|
      )

    assert html =~ "lu-panel"
    assert html =~ "repeat(2,1fr)"
  end
end
