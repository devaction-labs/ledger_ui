defmodule LedgerUI.Components.ProgressTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Progress

  test "value is read against max, the colour enters as variables" do
    assigns = %{}
    html = rendered_to_string(~H|<.progress value={30} max={60} color="primary" />|)
    assert html =~ "width:50%"
    assert html =~ ~s(data-part="progress")
    assert html =~ "[--c:var(--color-accent)]"
    assert html =~ "h-(--hgt)"
    assert html =~ "[--hgt:8px]"
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

    assert html =~ "color-mix(in_oklab,var(--c)_55%,var(--lu-bg-panel))"
    assert html =~ "[--hgt:4px]"
    assert html =~ ~s(role="progressbar")
    assert html =~ ~s(aria-label="Upload")
    assert html =~ ~s(aria-valuenow="10")
  end

  test "gradient reads the accent scale" do
    assigns = %{}
    html = rendered_to_string(~H|<.progress value={10} variant="gradient" />|)
    assert html =~ "var(--lu-accent-300)"
  end

  test "xl draws the label inside the bar" do
    assigns = %{}
    html = rendered_to_string(~H|<.progress value={68} size="xl" label="68%" />|)
    assert html =~ ">68%</i>"
    assert html =~ "[--hgt:18px]"
    refute html =~ "aria-label"
  end

  test "indeterminate, shine, active and height" do
    assigns = %{}
    slide = rendered_to_string(~H|<.progress indeterminate />|)
    assert slide =~ "lu-ind"
    assert slide =~ "width:35%"

    shine = rendered_to_string(~H|<.progress indeterminate shine />|)
    assert shine =~ "width:100%"
    assert shine =~ "bg-transparent"

    assert rendered_to_string(~H|<.progress value={5} active />|) =~ "lu-stripes"
    assert rendered_to_string(~H|<.progress value={5} height="1.5" />|) =~ "[--hgt:6px]"
    # `height` wins over `size`
    assert rendered_to_string(~H|<.progress value={5} size="xl" height="1" />|) =~ "[--hgt:4px]"
  end

  test "progress_stack segments take the chart colours" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.progress_stack label="Sales">
        <:segment value={46} label="Counter" />
        <:segment value={54} color="c4" />
      </.progress_stack>
      """)

    assert html =~ "bg-chart-1"
    assert html =~ "bg-chart-4"
    assert html =~ "width:46%"
    assert html =~ "width:54%"
    assert html =~ ~s(title="Counter")
    assert html =~ ~s(role="img")
  end

  test "loop fills the bar up to the value, forever" do
    assigns = %{}
    html = rendered_to_string(~H|<.progress value={60} loop />|)
    assert html =~ "animate-[mo-fillw_5s_cubic-bezier(.4,0,.2,1)_infinite]"
    assert html =~ "--w:60%;width:60%"
    refute rendered_to_string(~H|<.progress value={60} />|) =~ "mo-fillw"
    refute rendered_to_string(~H|<.progress_bar value={60} indeterminate loop />|) =~ "mo-fillw"
    assert rendered_to_string(~H|<.progress_bar value={60} loop />|) =~ "mo-fillw"
  end
end
