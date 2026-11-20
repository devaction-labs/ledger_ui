defmodule LedgerUI.Components.ToolTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Tool

  defp html(rendered), do: rendered_to_string(rendered)

  test "states pick status and verb" do
    for {state, verb, marker} <- [
          {"running", "Running", "lu-ring2"},
          {"waiting", "Waiting to run", "opacity:.55"},
          {"done", "Ran", "lu-trace-i"},
          {"error", "Failed to run", "color:var(--neg)"},
          {"denied", "Denied", "lu-trace-i"}
        ] do
      assigns = %{state: state}
      out = html(~H|<.tool id="t" state={@state} subject="ls" />|)
      assert out =~ verb
      assert out =~ marker
      assert out =~ ~r/#{verb}\s*<code>ls<\/code>/
    end
  end

  test "locale, verbs and title" do
    assigns = %{}
    assert html(~H|<.tool id="t" subject="ls" locale="pt_BR" />|) =~ "Rodou"

    assert html(~H|<.tool id="t" state="running" subject="a.ex" verbs={%{running: "Reading"}} />|) =~
             "Reading"

    out = html(~H|<.tool id="t" title="Custom" subject="ls" />|)
    assert out =~ "Custom"
    refute out =~ "<code>"
  end

  test "output makes a step with a small code block, error is destructive" do
    assigns = %{}
    out = html(~H|<.tool id="t2" subject="node -v" output="v24" input="args" open />|)
    assert out =~ "<details"
    assert out =~ ~s(id="t2-output")
    assert out =~ ~s(id="t2-input")
    assert out =~ "max-height:256px"
    assert out =~ " open"

    err = html(~H|<.tool id="t3" state="error" output="boom" />|)
    assert err =~ "var(--neg)"
  end

  test "panel variant" do
    assigns = %{}
    out = html(~H|<.tool id="t" variant="panel" icon="tool" state="done" title="XML assinado" />|)
    assert out =~ "lu-panel"
    assert out =~ "lu-ic pos"
    assert out =~ "lu-badge pos"

    ring =
      html(
        ~H|<.tool id="t" variant="panel" state="running" indicator="ring" title="x" description="d" />|
      )

    assert ring =~ "lu-ring2"
    refute ring =~ "lu-badge"
    assert ring =~ "padding:12px 14px"
  end

  test "tool_approval" do
    assigns = %{}
    out = html(~H|<.tool_approval
  id="a1"
  subject="rm -rf tmp"
  input="args"
  value="c1"
  on_approve="approve"
  on_deny="deny"
/>|)
    assert out =~ "Run <code>rm -rf tmp</code>?"
    assert out =~ ~s(phx-click="approve")
    assert out =~ ~s(phx-click="deny")
    assert out =~ ~s(phx-value-value="c1")
    assert out =~ ~s(id="a1-input")

    pt = html(~H|<.tool_approval id="a2" title="Pode?" locale="pt_BR" approve_label="Sim" />|)
    assert pt =~ "Pode?"
    assert pt =~ "Negar"
    assert pt =~ "Sim"
  end
end
