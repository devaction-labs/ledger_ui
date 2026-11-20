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

    assert html =~ "lu-tl2 icon s-lg compact"
    assert html =~ "e c-success"
    assert html =~ ~s(<span class="mk">)
    assert html =~ "<b>Autorizada</b>"
    assert html =~ "<small>Protocolo</small>"
    assert html =~ "<time>14:02</time>"
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

    assert html =~ "c-primary"
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

    assert html =~ ~s(class="lu-tl")
    assert html =~ ~s(class="lu-ic neg")
    assert html =~ ~s(class="when">há 2h)
  end

  test "timeline_day" do
    assigns = %{}
    assert rendered_to_string(~H|<.timeline_day label="Today" />|) =~ "Today"
  end
end
