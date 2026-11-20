defmodule LedgerUI.Components.StepsTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Steps

  defp norm(rendered) do
    rendered
    |> rendered_to_string()
    |> String.replace(~r/\s+/, " ")
    |> String.replace(~r/>\s+/, ">")
    |> String.replace(~r/\s+</, "<")
  end

  test "stepper: states follow current, markers and labels" do
    assigns = %{}

    html =
      norm(~H"""
      <.stepper current={1}>
        <:step label="Company" />
        <:step label="Certificate" />
        <:step label="Tax" />
      </.stepper>
      """)

    assert html =~ ~s(class="lu-st2")
    assert html =~ ~s(<div class="s done")
    assert html =~ ~s(data-icon="check")
    assert html =~ ~s(<div class="s cur")
    assert html =~ "<b>2</b>"
    assert html =~ "<b>3</b>"
    assert html =~ "Tax"
  end

  test "error flags the current step with !" do
    assigns = %{}

    html =
      norm(~H|<.stepper current={0} error><:step label="A" /><:step label="B" /></.stepper>|)

    assert html =~ ~s(class="s err")
    assert html =~ "<b>!</b>"
  end

  test "a step's own state wins; marker and icon override" do
    assigns = %{}

    html =
      norm(~H"""
      <.stepper current={0}>
        <:step label="A" state="done" marker="1" />
        <:step label="B" state="error" />
        <:step label="C" icon="file" />
      </.stepper>
      """)

    assert html =~ ~s(class="s done")
    assert html =~ "<b>1</b>"
    assert html =~ "<b>!</b>"
    assert html =~ ~s(data-icon="file")
  end

  test "color, size and the xs/sm dots show numbers when done" do
    assigns = %{}

    html =
      norm(~H"""
      <.stepper current={1} color="success" size="xs"><:step label="A" /><:step label="B" /></.stepper>
      """)

    assert html =~ "lu-st2 c-success s-xs"
    assert html =~ "<b>1</b>"
    refute html =~ "data-icon"
  end

  test "vertical: label and sub in a span, content after" do
    assigns = %{}

    html =
      norm(~H"""
      <.stepper orientation="vertical" current={0}>
        <:step label="Company" sub="12 registered"><button>Import</button></:step>
      </.stepper>
      """)

    assert html =~ "lu-st2 vert"
    assert html =~ "<span>Company<small>12 registered</small><button>Import</button></span>"
  end

  test "classic variant renders lu-steps with lines" do
    assigns = %{}

    html =
      norm(~H"""
      <.stepper variant="classic" current={1}>
        <:step label="A" /><:step label="B" /><:step label="C" />
      </.stepper>
      """)

    assert html =~ ~s(class="lu-steps")
    assert html =~ ~s(class="lu-step done")
    assert html =~ ~s(class="lu-step cur")
    assert html =~ ~s(class="lu-step-line done")
    assert html =~ ~s(class="lu-step-line")
  end

  test "steps/1: points with their content, colors and sizes" do
    assigns = %{}

    html =
      norm(~H"""
      <.steps color="primary" size="sm" orientation="vertical">
        <:step label="Cart" state="done">1</:step>
        <:step label="Ship" current color="success">2</:step>
        <:step label="Pay" />
      </.steps>
      """)

    assert html =~ "lu-st2 c-primary s-sm vert"
    assert html =~ ~s(class="s done")
    assert html =~ "<b>1</b>"
    assert html =~ ~s(class="s cur")
    assert html =~ "--c:var(--success)"
    assert html =~ "<span>Cart</span>"
  end
end
