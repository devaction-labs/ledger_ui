defmodule LedgerUI.Perf.PickerClassesTest do
  # #98, the pickers: what every day or time button shares sits once on the container (descendant
  # selectors, as the `select` does for its options), and the date picker's config holds no `today`
  # unless the attr gives one (the hook uses the browser's day).
  #
  # First render, bytes of HTML, before -> after (82-call parity script, locale and today given):
  #
  #   date_picker               14 693 ->  11 699
  #   datetime_picker           36 433 ->  22 883
  #   time_picker variant=list  20 155 ->   9 060   (288 buttons, step 5)
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI
  import LedgerUI.DiffCase
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  @day_base "relative grid h-[34px] cursor-pointer place-items-center border-0 text-[13.5px] tabular-nums"

  test "date_picker: a day carries its tone, the grid carries the rest" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.date_picker id="d" name="d" value="2026-11-05" locale="en" today="2026-11-20" />|
      )

    refute html =~ @day_base
    [grid] = Regex.run(~r/<div data-part="date-picker-grid"[^>]*>/, html)

    assert grid =~ "[&amp;_[data-part=date-picker-day]]:h-[34px]" or
             grid =~ "[&_[data-part=date-picker-day]]:h-[34px]"

    assert grid =~ "grid-cols-[repeat(7,1fr)]"
    days = Regex.scan(~r/<button[^>]*data-part="date-picker-day"[^>]*>/, html)
    assert length(days) == 35
    assert Enum.all?(days, fn [d] -> d =~ ~r/class="[^"]*(rounded-md|rounded-none)/ end)
    assert byte_size(html) <= 12_500
  end

  test "date_picker: the config has no today unless the attr gives one" do
    assigns = %{}
    without = rendered_to_string(~H|<.date_picker id="d" name="d" locale="en" />|)

    with_today =
      rendered_to_string(~H|<.date_picker id="d" name="d" locale="en" today="2026-11-20" />|)

    refute without =~ ~r/&quot;today&quot;:&quot;\d{4}-/
    assert with_today =~ "&quot;today&quot;:&quot;2026-11-20&quot;"
  end

  test "date_picker without today: a new label does not send the config, and a new value does not either" do
    t = fn assigns ->
      ~H|<.date_picker id="d" name="d" label={@label} value={@value} locale="en" />|
    end

    base = %{label: "L", value: "2026-11-05"}
    refute patch(t, base, label: "M") =~ "data-lu-config"
    refute patch(t, base, value: "2026-11-06") =~ "data-lu-config"
    check(t, base, label: "M")
    check(t, base, value: "2026-11-06")
  end

  test "date_picker with relative presets and no today keeps sending the config (the dates depend on today)" do
    t = fn assigns ->
      ~H|<.date_picker id="d" name="d" label={@label} presets={[{"Hoje", "today"}]} locale="en" />|
    end

    assert patch(t, %{label: "L"}, label: "M") =~ "data-lu-config"
  end

  test "time_picker variant=list: the buttons have no class, the list has the look" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.time_picker id="t" name="t" variant="list" value="10:30" locale="en" />|
      )

    slots = Regex.scan(~r/<button[^>]*data-part="time-picker-slot"[^>]*>/, html)
    assert length(slots) == 288
    assert Enum.all?(slots, fn [b] -> not (b =~ "class=") end)
    [list] = Regex.run(~r/<div data-part="time-picker-list"[^>]*>/, html)
    assert list =~ "data-part=time-picker-slot]]:h-8"
    assert list =~ "data-part=time-picker-slot]]:aria-checked:bg-inverse"
    # 288 buttons of 5 minutes; with 08:00 to 12:00 the parity script measured 20 155 -> 9 060
    assert byte_size(html) <= 45_000
  end

  test "time_picker variant=input: the hook still gets the button class in the config" do
    assigns = %{}
    html = rendered_to_string(~H|<.time_picker id="t" name="t" locale="en" />|)
    assert html =~ "&quot;slot&quot;:&quot;h-8 cursor-pointer"
    [list] = Regex.run(~r/<div data-part="time-picker-list"[^>]*>/, html)
    refute list =~ "time-picker-slot]]"
  end

  test "datetime_picker: the panel the server draws has no class on days and times" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.datetime_picker id="d" name="d" value="2026-11-05T10:30" locale="en" today="2026-11-20" />|
      )

    refute String.replace(html, ~r/data-lu-config="[^"]*"/, "") =~ @day_base
    slots = Regex.scan(~r/<button[^>]*data-part="datetime-picker-slot"[^>]*>/, html)
    assert length(slots) == 48
    assert Enum.all?(slots, fn [b] -> not (b =~ "class=") end)
    [list] = Regex.run(~r/<div data-part="datetime-picker-times"[^>]*>/, html)
    assert list =~ "data-part=datetime-picker-slot]]:disabled:line-through"
    # what the hook draws is unchanged: the whole class on every day and time
    assert html =~ "&quot;base&quot;:&quot;relative grid h-[34px]"
    assert html =~ "&quot;slot&quot;:&quot;h-8 cursor-pointer"
    assert byte_size(html) <= 24_000
  end
end
