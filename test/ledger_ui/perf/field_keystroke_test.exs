defmodule LedgerUI.Perf.FieldKeystrokeTest do
  # #96 (options 1 and 2): what a keystroke in a field bound to `field={@form[:a]}` sends again.
  # `field` changes (the value moves); the config of the pickers and the markup of the stars that
  # the grade did not touch must not go again.
  #
  # Measured before / after (bytes of the patch, one value change; then the same plus a new error):
  #
  #   rating           2365 / 2927  ->   670 / 1232
  #   date_picker      3488 / 4027  ->  1189 / 1728
  #   datetime_picker  9414 / 9953  ->  3033 / 3572
  #   otp_input        2879 / 3259  (the class of each box depends on `errors`, which `field` always moves)
  #   password_input   1842 / 2327  (the eye's JS and the input class depend on `id` / `errors`)
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI
  import LedgerUI.DiffCase

  defp mk_form(v, errors \\ []), do: to_form(%{"a" => v, "b" => "keep"}, as: :f, errors: errors)

  defp t_rating(assigns), do: ~H|<.rating field={@field} label="L" interactive />|

  defp t_date(assigns),
    do: ~H|<.date_picker field={@field} label="L" locale="en" today="2024-03-10" />|

  defp t_datetime(assigns),
    do: ~H|<.datetime_picker field={@field} label="L" locale="en" today="2024-03-10" />|

  defp size(fun, v1, v2) do
    base = %{field: mk_form(v1)[:a]}
    byte_size(patch(fun, base, field: mk_form(v2)[:a]))
  end

  test "rating: a new grade sends the stars' state, not their markup again" do
    assert size(&t_rating/1, "3", "4") <= 700
    base = %{field: mk_form("3")[:a]}
    json = patch(&t_rating/1, base, field: mk_form("4")[:a])
    refute json =~ "data-[state=on]"
    refute json =~ "viewBox"
    each_source(&t_rating/1, base, field: mk_form("5")[:a])
  end

  test "date_picker: the name is its own attribute, the config does not go on a keystroke" do
    assert size(&t_date/1, "2024-03-05", "2024-03-06") <= 1300
    base = %{field: mk_form("2024-03-05")[:a]}
    json = patch(&t_date/1, base, field: mk_form("2024-03-06")[:a])
    refute json =~ "data-lu-config"
    check(&t_date/1, base, field: mk_form("2024-03-06")[:a])
    {_json, html} = first(&t_date/1, base)
    assert html =~ ~s(data-lu-name="f[a]")
    refute html =~ "&quot;name&quot;"
  end

  test "datetime_picker: the name is its own attribute, the config does not go on a keystroke" do
    assert size(&t_datetime/1, "2024-03-05T10:00", "2024-03-06T10:00") <= 3300
    base = %{field: mk_form("2024-03-05T10:00")[:a]}
    json = patch(&t_datetime/1, base, field: mk_form("2024-03-06T10:00")[:a])
    refute json =~ "data-lu-config"
    check(&t_datetime/1, base, field: mk_form("2024-03-06T10:00")[:a])
    {_json, html} = first(&t_datetime/1, base)
    assert html =~ ~s(data-lu-name="f[a]")
    refute html =~ "&quot;name&quot;"
  end

  test "pickers: a range keeps startName and endName in the config" do
    assigns = %{}

    html =
      Phoenix.LiveViewTest.rendered_to_string(
        ~H|<.date_picker id="r" start_name="from" end_name="to" locale="en" today="2024-03-10" />|
      )

    assert html =~ "&quot;startName&quot;:&quot;from&quot;"
    assert html =~ "&quot;endName&quot;:&quot;to&quot;"
  end

  test "every source of the changed settles still ends in the page a fresh render gives" do
    base = %{field: mk_form("2024-03-05")[:a]}
    each_source(&t_date/1, base, field: mk_form("2024-03-09", a: {"x", []})[:a])
  end
end
