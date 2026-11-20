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

    assert html =~ ~s(data-part="step-group")
    assert html =~ "bg-pos text-white"
    assert html =~ "animate-[lu-spin_.9s_linear_infinite]"
    assert html =~ "text-muted shadow-[inset_0_0_0_1.5px_var(--lu-muted)]"
    assert html =~ ~r|<time [^>]*>0,4s</time>|

    loop = rendered_to_string(~H|<.step_group loop><:step title="a" /></.step_group>|)
    assert loop =~ "animate-[mo-stg_var(--dur,6s)"
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

    assert html =~ ~r|id="deploy-panel"[^>]*class="hidden"| or
             html =~ ~r|class="hidden"[^>]*id="deploy-panel"|

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
    assert html =~ "bg-neg-soft"
    assert html =~ ~s(data-part="step-group-line")
  end
end
