defmodule LedgerUI.Components.DatetimePickerTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.DatetimePicker

  test "wall-clock value, default en format and 12h list" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.datetime_picker id="d" name="at" value="2026-10-14T10:30" today={~D[2026-10-01]} />|
      )

    assert html =~ ~s(name="at" value="2026-10-14T10:30")
    assert html =~ ~s(value="Oct 14, 2026, 10:30 AM")
    assert html =~ "10:30 AM"
    assert html =~ ~s(phx-hook="LedgerUI.DatetimePicker")
  end

  test "NaiveDateTime and DateTime keep their clock; pt_BR uses 24h" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.datetime_picker id="d" name="at" value={~N[2026-10-14 15:45:00]} locale="pt_BR" />|
      )

    assert html =~ ~s(value="2026-10-14T15:45")
    assert html =~ ~s(value="14/10/2026 15:45")

    html =
      rendered_to_string(~H|<.datetime_picker
  id="d"
  name="at"
  value={DateTime.from_naive!(~N[2026-10-14 09:05:00], "Etc/UTC")}
  time_format="24"
/>|)

    assert html =~ ~s(value="2026-10-14T09:05")
  end

  test "range sends name[] with an empty first, or two fields" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.datetime_picker
  id="r"
  name="shift"
  mode="range"
  value={{"2026-10-14T09:00", "2026-10-15T17:00"}}
/>|)

    assert html =~ ~s(name="shift[]" value="")
    assert html =~ ~s(name="shift[]" value="2026-10-14T09:00")
    assert html =~ ~s(name="shift[]" value="2026-10-15T17:00")

    html =
      rendered_to_string(
        ~H|<.datetime_picker id="r" start_name="from" end_name="to" value={{"2026-10-14T09:00", nil}} />|
      )

    assert html =~ ~s(name="from" value="2026-10-14T09:00")
    assert html =~ ~s(name="to" value="")
  end

  test "config carries interval, bounds and unavailable" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.datetime_picker
  id="u"
  name="slot"
  interval={15}
  min="now"
  min_time="08:00"
  max_time="18:00"
  unavailable="12:00-13:00, 2026-10-14, 2026-10-15T10:00"
/>|)

    [_, config] = Regex.run(~r/data-lu-config="([^"]*)"/, html)

    cfg =
      config
      |> Phoenix.HTML.html_escape()
      |> then(fn _ -> config end)
      |> String.replace("&quot;", "\"")
      |> Jason.decode!()

    assert cfg["interval"] == 15
    assert cfg["min"] == "now"
    assert cfg["minTime"] == 480 and cfg["maxTime"] == 1080
    assert cfg["unavailable"]["days"] == ["2026-10-14"]
    assert cfg["unavailable"]["ranges"] == [[720, 780]]
    assert cfg["unavailable"]["moments"] == ["2026-10-15T10:00"]
  end

  test "trigger slot replaces the input; timezone goes on the help line; split has two fields" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.datetime_picker id="w" name="w" help="Local" timezone="BRT">
        <:trigger><button>Pick</button></:trigger>
      </.datetime_picker>
      """)

    assert html =~ "<button>Pick</button>"
    refute html =~ ~s(data-field="text")
    assert html =~ "Local · BRT"

    html =
      rendered_to_string(
        ~H|<.datetime_picker id="s" name="s" split date_label="Data" time_label="Hora" />|
      )

    assert html =~ ~s(data-field="date")
    assert html =~ ~s(data-field="time")
    assert html =~ "Data"
  end

  test "legacy attributes map to the new ones" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.datetime_picker
  id="l"
  name="l"
  time_24hr
  minute_step={10}
  default_hour={9}
  value="2026-10-14T21:00"
/>|)

    [_, config] = Regex.run(~r/data-lu-config="([^"]*)"/, html)
    cfg = config |> String.replace("&quot;", "\"") |> Jason.decode!()
    assert cfg["h24"] == true and cfg["interval"] == 10 and cfg["defaultStart"] == 540
  end

  test "panel shows the calendar, the time zone caption and the list" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.datetime_picker_panel
  month={~D[2026-10-01]}
  selected={~D[2026-10-21]}
  times={["12:00", "13:00"]}
  time="13:00"
  timezone="BRT (UTC−3)"
/>|)

    assert html =~ "BRT (UTC−3)"
    assert html =~ ~r/aria-checked="true"[^>]*>\s*13:00/
    assert html =~ ~r/class="[^"]*bg-inverse font-semibold text-on-inverse[^"]*"/
  end

  test "the popup is a top-layer panel and the placement goes to the hook" do
    assigns = %{}
    html = rendered_to_string(~H|<.datetime_picker id="dt" name="dt" />|)
    assert html =~ ~s(popover="manual")
    assert html =~ ~s(data-lu-placement="bottom-start")
    assert html =~ "keep-hidden"
    assert html =~ "keep-style"
    refute html =~ ~s(class="absolute z-50)

    top = rendered_to_string(~H|<.datetime_picker id="dt" name="dt" placement="top" />|)
    assert top =~ ~s(data-lu-placement="top-start")

    end_ = rendered_to_string(~H|<.datetime_picker id="dt" name="dt" placement="bottom-end" />|)
    assert end_ =~ ~s(data-lu-placement="bottom-end")
  end
end
