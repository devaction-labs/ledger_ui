defmodule LedgerUI.Components.DatePickerTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.DatePicker

  defp render(assigns, template), do: rendered_to_string(template.(assigns))

  test "single: ISO value in a hidden input, formatted text in the input" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.date_picker
  id="d"
  name="due"
  value={~D[2026-10-23]}
  display_format="M j, Y"
  today={~D[2026-10-01]}
/>|)

    assert html =~ ~s(type="hidden" name="due" value="2026-10-23")
    assert html =~ ~s(value="Oct 23, 2026")
    assert html =~ ~s(phx-hook="LedgerUI.DatePicker")
    assert html =~ ~r/class="[^"]*bg-inverse font-semibold text-on-inverse[^"]*"/
  end

  test "range with start/end names sends two fields and paints the band" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.date_picker
  id="r"
  start_name="from"
  end_name="to"
  value={{~D[2026-10-10], ~D[2026-10-12]}}
  today={~D[2026-10-01]}
/>|)

    assert html =~ ~s(name="from" value="2026-10-10")
    assert html =~ ~s(name="to" value="2026-10-12")
    assert html =~ ~r/class="[^"]*rounded-l-\[8px\] rounded-r-none bg-accent-600[^"]*"/
    assert html =~ ~r/class="[^"]*rounded-none bg-accent-soft[^"]*"/
    assert html =~ ~r/class="[^"]*rounded-r-\[8px\] rounded-l-none bg-accent-600[^"]*"/
  end

  test "multiple and range send name[] with an empty first one" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.date_picker id="m" name="days" mode="multiple" value={[~D[2026-10-02], ~D[2026-10-05]]} />|
      )

    assert html =~ ~s(name="days[]" value="")
    assert html =~ ~s(name="days[]" value="2026-10-02")
    assert html =~ ~s(name="days[]" value="2026-10-05")
  end

  test "field fills id, name and value; errors are shown" do
    form = Phoenix.Component.to_form(%{"due_on" => "2026-11-05"}, as: :t)
    assigns = %{form: form}
    html = rendered_to_string(~H|<.date_picker field={@form[:due_on]} errors={["is invalid"]} />|)
    assert html =~ ~s(name="t[due_on]" value="2026-11-05")
    assert html =~ "is invalid"
  end

  test "min, max, disabled weekdays disable days" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.date_picker_panel
  month={~D[2026-10-01]}
  min={~D[2026-10-10]}
  max={~D[2026-10-20]}
  disabled_weekdays={[0, 6]}
/>|)

    # Oct 9 is below min, Oct 11 is a Sunday, Oct 21 is above max
    assert html =~ ~r/<button[^>]*data-part="date-picker-day"[^>]*disabled[^>]*>\s*9\s*</
    assert html =~ ~r/<button[^>]*data-part="date-picker-day"[^>]*disabled[^>]*>\s*11\s*</
    refute html =~ ~r/<button[^>]*data-part="date-picker-day"[^>]*disabled[^>]*>\s*12\s*</
    assert html =~ ~r/<button[^>]*data-part="date-picker-day"[^>]*disabled[^>]*>\s*21\s*</
  end

  test "week_start rotates the weekday letters and the grid" do
    assigns = %{}
    html = rendered_to_string(~H|<.date_picker_panel month={~D[2026-10-01]} week_start={1} />|)
    assert html =~ ~r/<span class="[^"]*text-muted">M<\/span>/
    # Oct 1, 2026 is a Thursday: Monday-first grid starts on Sep 28
    assert html =~ ~r/class="[^"]*text-subtle[^"]*"[^>]*>\s*28\s*</
  end

  test "pt_BR names months and uses dd/mm/aaaa" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.date_picker id="p" name="d" locale="pt_BR" value={~D[2026-10-05]} today={~D[2026-10-01]} />|
      )

    assert html =~ "Outubro 2026"
    assert html =~ ~s(value="05/10/2026")
    assert html =~ ~s(placeholder="dd/mm/aaaa")
  end

  test "presets are computed from today and the matching one is highlighted" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.date_picker_panel
  month={~D[2026-10-01]}
  today={~D[2026-10-19]}
  range={{~D[2026-10-01], ~D[2026-10-31]}}
  presets={[{"Este mês", "this_month"}, {"Mês passado", "last_month"}]}
/>|)

    assert html =~ ~r/aria-pressed="true"[^>]*>\s*Este mês/
    refute html =~ ~r/aria-pressed="true"[^>]*>\s*Mês passado/
  end

  test "preset_range/2" do
    assert preset_range("last_7_days", ~D[2026-10-19]) == {~D[2026-10-13], ~D[2026-10-19]}
    assert preset_range("last_month", ~D[2026-10-19]) == {~D[2026-09-01], ~D[2026-09-30]}
    assert preset_range("this_week", ~D[2026-10-19]) == {~D[2026-10-18], ~D[2026-10-24]}
    assert preset_range("nope", ~D[2026-10-19]) == nil
  end

  test "format/4 tokens" do
    d = ~D[2026-10-23]
    m = locale_data("en").months
    w = locale_data("en").weekdays
    assert format(d, "D, M j", m, w) == "Fri, Oct 23"
    assert format(d, "F j, Y", m, w) == "October 23, 2026"
    assert format(d, "d/m/y", m, w) == "23/10/26"
  end

  test "trailing slot replaces the icon, inline shows the popup, clear is a JS command" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.date_picker id="t" name="t" inline>
        <:trailing><button>x</button></:trailing>
      </.date_picker>
      """)

    refute html =~ ~s(data-icon="calendar")
    assert html =~ "<button>x</button>"
    refute html =~ ~r/role="dialog"[^>]* hidden[ >]/
    assert %Phoenix.LiveView.JS{} = date_picker_clear("t")
    _ = render(%{}, fn _ -> "" end)
  end

  test "size classes" do
    assigns = %{}
    html = rendered_to_string(~H|<.date_picker id="s" name="s" size="lg" show_icon={false} />|)
    assert html =~ ~r/data-part="input" class="[^"]*h-11/
    refute html =~ ~s(data-icon="calendar")
  end

  test "the popup is a top-layer panel positioned from the field, not clipped by overflow" do
    assigns = %{}
    html = rendered_to_string(~H|<.date_picker id="d" name="d" />|)
    assert html =~ ~s(id="d-pop")
    assert html =~ ~s(popover="manual")
    assert html =~ ~s(data-lu-placement="bottom-start")
    assert html =~ ~s(role="dialog")
    assert html =~ ~s(aria-controls="d-pop")
    assert html =~ "keep-hidden"
    assert html =~ "keep-style"
    assert html =~ "fixed"
    refute html =~ "absolute top-full"
  end

  test "inline keeps the calendar in the flow, without popover" do
    assigns = %{}
    html = rendered_to_string(~H|<.date_picker id="d" name="d" inline />|)
    refute html =~ "popover="
    assert html =~ "absolute top-full"
  end
end
