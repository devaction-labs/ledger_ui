defmodule LedgerUI.Components.TimelineTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Timeline

  test "items render the marker, title, description and time" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.timeline marker="icon" size="lg" density="compact">
        <.timeline_item title="Autorizada" description="Protocolo" time="14:02" color="success">
          <:point><i id="pt"></i></:point>
        </.timeline_item>
      </.timeline>
      """)

    assert html =~ ~s(data-lu-marker="icon")
    assert html =~ "[--mk:34px]"
    assert html =~ "[--pb:8px]"
    assert html =~ "[--c:var(--lu-pos)]"
    assert html =~ ~s(data-part="timeline-point")
    assert html =~ ~r|<b [^>]*class="font-medium">Autorizada</b>|
    assert html =~ ~r|<small [^>]*>Protocolo</small>|
    assert html =~ ~r|<time [^>]*>14:02</time>|
    assert html =~ ~s(id="pt")
  end

  test "details slot replaces the description; accent maps to primary" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.timeline_item title="t" description="plain" color="accent">
        <:details><b>3 items</b></:details>
      </.timeline_item>
      """)

    assert html =~ "[--c:var(--color-accent)]"
    assert html =~ "<b>3 items</b>"
    refute html =~ "plain"
  end

  test "rows from a list through the item slot" do
    assigns = %{events: [%{id: 1, title: "a"}, %{id: 2, title: "b"}]}

    html =
      rendered_to_string(~H"""
      <.timeline id="ev" rows={@events} row_id={&"ev-#{&1.id}"}>
        <:item :let={{dom_id, e}}><.timeline_item id={dom_id} title={e.title} /></:item>
      </.timeline>
      """)

    assert html =~ ~s(id="ev-1")
    assert html =~ ~s(id="ev-2")
    refute html =~ "phx-update"
  end

  test "rows from a stream render with phx-update=stream" do
    stream = Phoenix.LiveView.LiveStream.new(:events, 0, [%{id: 1, title: "a"}], [])
    assigns = %{stream: stream}

    html =
      rendered_to_string(~H"""
      <.timeline id="ev" rows={@stream}>
        <:item :let={{dom_id, e}}><.timeline_item id={dom_id} title={e.title} /></:item>
      </.timeline>
      """)

    assert html =~ ~s(phx-update="stream")
    assert html =~ ~s(id="events-1")
  end

  test "canvas variant with events" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.timeline variant="canvas">
        <.timeline_event tone="neg" title="Falhou" subtitle="Visa" time="há 2h">
          <:icon><i id="i"></i></:icon>
        </.timeline_event>
      </.timeline>
      """)

    assert html =~ ~s(data-part="timeline")
    assert html =~ "bg-neg-soft text-neg"
    assert html =~ ~r|<span [^>]*class="ml-1.5 [^"]*">há 2h|

    loop =
      rendered_to_string(
        ~H|<.timeline loop><.timeline_item title="a" style="--dl:.6s" /></.timeline>|
      )

    assert loop =~ "animate-[mo-stg_var(--dur,6s)_cubic-bezier(.2,.8,.2,1)_var(--dl,0s)_infinite]"
    ping = rendered_to_string(~H|<.timeline_item title="a" ping />|)
    assert ping =~ "animate-[mo-pulse_2s_ease-in-out_infinite]"
  end

  test "timeline_day" do
    assigns = %{}
    assert rendered_to_string(~H|<.timeline_day label="Today" />|) =~ "Today"
  end
end
