defmodule LedgerUI.Components.BadgeTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Badge

  test "color, variant, size and shape classes" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.badge color="success" variant="solid" size="sm" shape="pill">Paid</.badge>|
      )

    assert html =~ "lu-bd c-success v-solid s-sm sh-pill"
    assert html =~ "border-radius:999px"
    assert html =~ "Paid"
  end

  test "defaults" do
    assigns = %{}
    assert rendered_to_string(~H|<.badge>x</.badge>|) =~ ~s(class="lu-bd c-neutral v-soft")
  end

  test "dot and live dot" do
    assigns = %{}
    assert rendered_to_string(~H|<.badge dot>x</.badge>|) =~ ~s(<span class="lu-dot"></span>)
    assert rendered_to_string(~H|<.badge dot="live">x</.badge>|) =~ "lu-dot live"
  end

  test "on_remove adds a remove button with its label and event" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.badge on_remove="drop" id="b1" remove_label="Quitar">x</.badge>|)

    assert html =~ ~s(aria-label="Quitar")
    assert html =~ ~s(phx-click="drop")
    assert html =~ ~s(phx-value-id="b1")
  end

  test "canvas badge uses lu-badge tones" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.badge canvas color="warning" variant="outline" size="sm">x</.badge>|
      )

    assert html =~ ~s(class="lu-badge warn outline sm")
  end
end
