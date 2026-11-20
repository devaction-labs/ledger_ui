defmodule LedgerUI.Components.TraceTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Trace

  defp html(rendered), do: rendered_to_string(rendered)

  test "trace_line: title, block, description, statuses" do
    assigns = %{}

    out =
      html(~H"""
      <.trace>
        <.trace_line icon="brain" title="Thought" description="5s" />
        <.trace_line icon="terminal">Ran <code>pnpm</code></.trace_line>
        <.trace_line status="error">Failed</.trace_line>
        <.trace_line status="running">Working</.trace_line>
        <.trace_line status="pending">Later</.trace_line>
      </.trace>
      """)

    assert out =~ ~s(class="lu-trace")
    assert out =~ "Thought"
    assert out =~ "<code>pnpm</code>"
    assert out =~ "color:var(--neg)"
    assert out =~ "lu-ring2"
    assert out =~ "opacity:.55"
    assert out =~ ~s(data-icon="alert")
  end

  test "trace_line as link and with end icon" do
    assigns = %{}
    out = html(~H|<.trace_line href="/x" title="Open" end_icon="arrow-right" />|)
    assert out =~ ~s(<a)
    assert out =~ ~s(href="/x")
    assert out =~ ~s(data-icon="arrow-right")
  end

  test "trace_line span bar" do
    assigns = %{bar: %{start: 18, width: 30, color: "var(--warn)", delay: "0.6s"}}
    out = html(~H|<.trace_line title="x" depth={1} duration="0,7s" bar={@bar} />|)
    assert out =~ "padding-left:30px"
    assert out =~ "left:18%;width:30%"
    assert out =~ "lu-spanbar"
    assert out =~ "--dl:0.6s"
    assert out =~ "0,7s"
  end

  test "trace_step is a details" do
    assigns = %{}
    out = html(~H|<.trace_step title="Ran" open><pre>v24</pre></.trace_step>|)
    assert out =~ "<details"
    assert out =~ " open"
    assert out =~ "<pre>v24</pre>"

    closed = html(~H|<.trace_step title="Ran"><:summary>Ran <b>x</b></:summary>out</.trace_step>|)
    refute closed =~ " open"
    assert closed =~ "<b>x</b>"
  end
end
