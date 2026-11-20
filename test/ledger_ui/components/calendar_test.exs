defmodule LedgerUI.Components.CalendarTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Calendar

  @events [
    %{id: 1, title: "Coelba", date: ~D[2026-10-15], color: "error"},
    %{
      id: 2,
      title: "Visit",
      subtitle: "Santa Mônica",
      date: ~D[2026-10-19],
      start: "10:00",
      end: "11:00"
    }
  ]

  test "month: title, chips with the tone of the color, today marked" do
    assigns = %{events: @events}

    html =
      rendered_to_string(
        ~H|<.calendar id="c" date={~D[2026-10-15]} today={~D[2026-10-19]} events={@events} />|
      )

    assert html =~ "October 2026"
    assert html =~ ~r/class="lu-badge neg sm"[^>]*>\s*Coelba/
    assert html =~ "background:var(--inverse)"
    assert html =~ ">Sun<"
  end

  test "events become buttons only with on_event; toolbar disabled without handlers" do
    assigns = %{events: @events}

    html = rendered_to_string(~H|<.calendar id="c" date={~D[2026-10-15]} events={@events} />|)
    refute html =~ ~s(phx-value-event)
    assert html =~ ~r/aria-label="Previous"[^>]*disabled/

    html =
      rendered_to_string(~H|<.calendar
  id="c"
  date={~D[2026-10-15]}
  events={@events}
  on_event="ev"
  on_navigate="nav"
  on_view="view"
  on_select="sel"
/>|)

    assert html =~ ~s(phx-click="ev")
    assert html =~ ~s(phx-value-event="1")
    assert html =~ ~s(phx-value-date="2026-09-01")
    assert html =~ ~s(phx-value-view="week")
    assert html =~ ~s(phx-hook="LedgerUI.Calendar")
    assert html =~ ~s(role="grid")
    refute html =~ ~r/aria-label="Previous"[^>]*disabled/
  end

  test "crowded days collapse into a more button" do
    assigns = %{
      events: for(i <- 1..5, do: %{title: "E#{i}", date: ~D[2026-10-15]})
    }

    html =
      rendered_to_string(
        ~H|<.calendar id="c" date={~D[2026-10-15]} events={@events} max_events={3} on_select="s" />|
      )

    assert html =~ "+2 more"
    refute html =~ ">E4<"
  end

  test "week view: timed events sit in their hour, others in the all-day row" do
    assigns = %{events: @events}

    html =
      rendered_to_string(~H|<.calendar
  id="c"
  view="week"
  date={~D[2026-10-19]}
  events={@events}
  week_start={1}
  show_weekends={false}
/>|)

    assert html =~ "All day"
    assert html =~ "10:00–11:00"
    assert html =~ "Mon 19"
    refute html =~ "Sat 24"
    assert html =~ "08:00"
  end

  test "day view has a single column" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.calendar id="c" view="day" date={~D[2026-10-19]} locale="pt_BR" />|)

    assert html =~ "grid-template-columns:56px repeat(1,1fr)"
    assert html =~ "Seg 19"
  end

  test "mini: dot marks, selected, range and outside days" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.calendar
  id="m"
  variant="mini"
  header={false}
  card={false}
  date={~D[2026-11-01]}
  today={~D[2026-11-10]}
  selected={~D[2026-11-12]}
  range={{~D[2026-11-20], ~D[2026-11-22]}}
  events={[%{title: "x", date: ~D[2026-11-05]}]}
/>|)

    assert html =~ ~s(class="lu-cal")
    assert html =~ ~r/class="d dot"[^>]*>\s*5\s*</
    assert html =~ ~r/class="d t"[^>]*>\s*10\s*</
    assert html =~ ~r/class="d s"[^>]*>\s*12\s*</
    assert html =~ ~r/class="d rs"[^>]*>\s*20\s*</
    assert html =~ ~r/class="d r"[^>]*>\s*21\s*</
    assert html =~ ~r/class="d re"[^>]*>\s*22\s*</
    refute html =~ "lu-panel"
  end

  test "mini tint marks, legend, months_shown and day ids" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.calendar
  id="m"
  variant="mini"
  marks="tint"
  months_shown={2}
  locale="pt_BR"
  date={~D[2026-11-01]}
  day_id="day"
  legend={[{"Receber", "success"}]}
  events={[%{title: "x", date: ~D[2026-11-05], color: "success"}]}
/>|)

    assert html =~ "Novembro 2026"
    assert html =~ "Dezembro 2026"
    assert html =~ "background:var(--pos-soft)"
    assert html =~ ~s(id="day-2026-11-05")
    assert html =~ "Receber"
  end

  test "mini days are buttons only with on_select (and marked ones when asked)" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.calendar
  id="m"
  variant="mini"
  date={~D[2026-11-01]}
  on_select="pick"
  interactive_marked_only
  events={[%{title: "x", date: ~D[2026-11-05]}]}
/>|)

    assert length(Regex.scan(~r/role="button"/, html)) == 1
    assert html =~ ~s(phx-value-date="2026-11-05")
  end

  test "calendar_range/3" do
    assert calendar_range("month", ~D[2026-10-15]) == {~D[2026-09-27], ~D[2026-10-31]}

    assert calendar_range("week", ~D[2026-10-15], week_start: 1) ==
             {~D[2026-10-12], ~D[2026-10-18]}

    assert calendar_range("day", ~D[2026-10-15]) == {~D[2026-10-15], ~D[2026-10-15]}
  end

  test "event slot replaces the chip content" do
    assigns = %{events: @events}

    html =
      rendered_to_string(~H"""
      <.calendar id="c" date={~D[2026-10-15]} events={@events}>
        <:event :let={e}>[{e.title}]</:event>
      </.calendar>
      """)

    assert html =~ "[Coelba]"
  end

  describe "due_calendar" do
    test "status from the date, badges and amounts" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.due_calendar
  today={~D[2026-10-19]}
  locale="pt_BR"
  currency="R$ "
  items={[
    %{date: ~D[2026-10-18], title: "A", subtitle: "s", amount: 4280},
    %{date: ~D[2026-10-19], title: "B", amount: 3500.5},
    %{date: ~D[2026-10-21], title: "C", amount: "txt"}
  ]}
/>|)

      assert html =~ ~r/class="lu-badge neg"[^>]*>Vencida/
      assert html =~ ~r/class="lu-badge acc"[^>]*>Hoje/
      assert html =~ ~r/class="lu-badge"[^>]*>Agendada/
      assert html =~ "R$ 4.280"
      assert html =~ "R$ 3.500,50"
      assert html =~ ">txt<"
      assert html =~ "background:var(--inverse)"
    end

    test "explicit status wins" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.due_calendar
  today={~D[2026-10-19]}
  items={[%{date: ~D[2026-10-21], title: "A", status: "overdue", status_label: "Late"}]}
/>|)

      assert html =~ ~r/class="lu-badge neg"[^>]*>Late/
    end

    test "animated: staged rows, blinking overdue badge, lowercase weekday, warn today" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.due_calendar
  animated
  today={~D[2026-10-19]}
  items={[%{date: ~D[2026-10-18], title: "A"}, %{date: ~D[2026-10-19], title: "B"}]}
/>|)

      assert html =~ "mo-stg"
      assert html =~ ~s(<span class="mo-blink">)
      assert html =~ "--dl:0.4s"
      assert html =~ "lu-badge warn"
      assert html =~ ~r/opacity:\.75">sun</
    end
  end
end
