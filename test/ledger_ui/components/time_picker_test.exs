defmodule LedgerUI.Components.TimePickerTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.TimePicker

  test "hidden input gets HH:MM and the text follows the clock" do
    assigns = %{}
    html = rendered_to_string(~H|<.time_picker id="t" name="at" value="13:05" />|)
    assert html =~ ~s(name="at" value="13:05")
    assert html =~ ~s(value="1:05 PM")

    html =
      rendered_to_string(~H|<.time_picker id="t" name="at" value={~T[13:05:00]} time_24hr />|)

    assert html =~ ~s(value="13:05")
  end

  test "variant list renders slots between min_time and max_time" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.time_picker
  id="l"
  name="slot"
  variant="list"
  min_time="14:00"
  max_time="14:45"
  minute_step={15}
  value="14:30"
  time_24hr
/>|)

    for t <- ~w(14:00 14:15 14:30 14:45), do: assert(html =~ ~s(data-value="#{t}"))
    refute html =~ ~s(data-value="15:00")
    assert html =~ ~r/aria-checked="true"[^>]*data-value="14:30"/
  end

  test "field errors and help" do
    form = Phoenix.Component.to_form(%{"at" => "09:30"}, as: :t)
    assigns = %{form: form}

    html =
      rendered_to_string(~H|<.time_picker field={@form[:at]} help="Local" errors={["bad"]} />|)

    assert html =~ ~s(name="t[at]" value="09:30")
    assert html =~ "bad"
    assert html =~ "Local"
  end

  test "minutes/1 and display/2" do
    assert minutes("09:30") == 570
    assert minutes("9:30") == 570
    assert minutes("25:00") == nil
    assert display(570, false) == "9:30 AM"
    assert display(0, false) == "12:00 AM"
    assert hhmm(570) == "09:30"
  end

  test "panel marks the chosen time" do
    assigns = %{}
    html = rendered_to_string(~H|<.time_picker_panel times={["09:00", "09:30"]} value="09:30" />|)
    assert html =~ ~r/aria-checked="true"[^>]*>\s*09:30/
  end

  test "the input variant's popup is a top-layer panel, the list variant has none" do
    assigns = %{}
    html = rendered_to_string(~H|<.time_picker id="t" name="at" />|)
    assert html =~ ~s(popover="manual")
    assert html =~ ~s(data-lu-placement="bottom-start")
    assert html =~ "keep-style"
    refute html =~ "absolute top-full"

    list = rendered_to_string(~H|<.time_picker id="t" name="at" variant="list" />|)
    refute list =~ "popover="
  end
end
