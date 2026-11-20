defmodule LedgerUI.Components.ProgressTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Progress

  test "value is read against max" do
    assigns = %{}
    html = rendered_to_string(~H|<.progress value={30} max={60} color="primary" />|)
    assert html =~ "width:50%"
    assert html =~ "lu-pg c-primary"
  end

  test "value is clamped" do
    assigns = %{}
    assert rendered_to_string(~H|<.progress value={140} />|) =~ "width:100%"
    assert rendered_to_string(~H|<.progress value={-5} />|) =~ "width:0%"
  end

  test "variant, size and label" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.progress value={10} variant="soft" size="sm" label="Upload" />|)

    assert html =~ "v-soft"
    assert html =~ "s-sm"
    assert html =~ ~s(role="progressbar")
    assert html =~ ~s(aria-label="Upload")
    assert html =~ ~s(aria-valuenow="10")
  end

  test "xl draws the label inside the bar" do
    assigns = %{}
    html = rendered_to_string(~H|<.progress value={68} size="xl" label="68%" />|)
    assert html =~ ">68%</i>"
    refute html =~ "aria-label"
  end

  test "indeterminate, active and height" do
    assigns = %{}
    assert rendered_to_string(~H|<.progress indeterminate />|) =~ "lu-ind"
    assert rendered_to_string(~H|<.progress value={5} active />|) =~ "lu-stripes"
    assert rendered_to_string(~H|<.progress value={5} height="1.5" />|) =~ "--hgt:6px"
  end

  test "progress_stack segments" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.progress_stack label="Sales">
        <:segment value={46} label="Counter" />
        <:segment value={54} color="c4" />
      </.progress_stack>
      """)

    assert html =~ "width:46%;background:var(--chart-1)"
    assert html =~ "width:54%;background:var(--chart-4)"
    assert html =~ ~s(title="Counter")
    assert html =~ ~s(role="img")
  end
end
