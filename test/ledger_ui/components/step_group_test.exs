defmodule LedgerUI.Components.StepGroupTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.StepGroup

  test "steps render status, title and result" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.step_group>
        <:step title="Validar" status={:ok} result="0,4s" />
        <:step title="Enviar" status={:running} />
        <:step title="Imprimir" status={:canceled} />
      </.step_group>
      """)

    assert html =~ ~s(class="lu-sg2")
    assert html =~ "r ok"
    assert html =~ "lu-ring2"
    assert html =~ "r canceled"
    assert html =~ "<time>0,4s</time>"
  end

  test "header with title, duration and collapse button" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.step_group id="deploy" title="Deploy logs" status={:running} duration="1m 04s" collapsed>
        <:step title="a" status={:ok} />
      </.step_group>
      """)

    assert html =~ "Deploy logs"
    assert html =~ "1m 04s"
    assert html =~ ~s(id="deploy-panel")
    assert html =~ "display:none"
    assert html =~ "phx-click"
  end

  test "a step with a log is a button that opens it" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.step_group id="d">
        <:step title="Update" status={:running} open>
          <.step_group_line n={1} at="09:41:02" tone="err">Rejected</.step_group_line>
        </:step>
      </.step_group>
      """)

    assert html =~ "<button"
    assert html =~ ~s(id="d-step-0-log")
    assert html =~ "09:41:02"
    assert html =~ "Rejected"
    assert html =~ "r ln mono err"
  end
end
