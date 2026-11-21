defmodule LedgerUI.Components.BadgeTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Badge

  test "color, variant, size and shape pick one utility per property" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.badge color="success" variant="solid" size="sm" shape="pill">Paid</.badge>|
      )

    assert html =~ "[--c:var(--lu-pos)]"
    assert html =~ "bg-(--c) text-(--c-on)"
    assert html =~ "h-[19px] px-1.5 text-[11px]"
    assert html =~ "rounded-full"
    refute html =~ "rounded-sm"
    assert html =~ "Paid"
  end

  test "defaults" do
    assigns = %{}
    html = rendered_to_string(~H|<.badge>x</.badge>|)
    assert html =~ "bg-(--c-soft) text-(--c-ink)"
    assert html =~ "h-[22px] px-2 text-xs rounded-sm"
    assert html =~ ~s(data-part="badge")
    refute html =~ ~r/(^|[\s"])lu-/
  end

  test "icon" do
    assigns = %{}
    html = rendered_to_string(~H|<.badge icon="huge-sparkles">x</.badge>|)
    assert html =~ ~s(data-icon="sparkles")
  end

  test "dot and live dot" do
    assigns = %{}
    assert rendered_to_string(~H|<.badge dot>x</.badge>|) =~ "bg-current"

    live = rendered_to_string(~H|<.badge dot="live">x</.badge>|)
    assert live =~ "animate-[mo-blink_1.4s_ease-in-out_infinite]"
    assert live =~ "bg-accent"
  end

  test "on_remove adds a remove button with its label and event" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.badge on_remove="drop" id="b1" remove_label="Quitar">x</.badge>|)

    assert html =~ ~s(aria-label="Quitar")
    assert html =~ ~s(phx-click="drop")
    assert html =~ ~s(phx-value-id="b1")
  end

  test "canvas badge is tinted by color" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.badge canvas color="warning" variant="outline" size="sm">x</.badge>|
      )

    assert html =~ "text-warn"
    assert html =~ "h-[18px] px-1.5 text-[11px]"
    assert html =~ "shadow-[inset_0_0_0_1px_color-mix(in_oklab,var(--lu-warn)_55%,transparent)]"

    soft = rendered_to_string(~H|<.badge canvas color="success">x</.badge>|)
    assert soft =~ "bg-pos-soft text-pos"

    assert rendered_to_string(~H|<.badge canvas variant="solid">x</.badge>|) =~
             "bg-inverse text-on-inverse"
  end
end
