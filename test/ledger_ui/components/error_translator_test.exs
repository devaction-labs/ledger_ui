defmodule LedgerUI.Components.ErrorTranslatorTest do
  # Mutates the application env (global), so it must not run concurrently with other modules.
  use ExUnit.Case, async: false
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.{Input, Textarea, NumberInput, Select, Autocomplete, DatePicker}
  import LedgerUI.Components.{DatetimePicker, Checkbox, Switch, Radio, Pillbox, Segmented}

  defmodule Translator do
    def translate({"can't be blank", _opts}), do: "nao pode ficar em branco"
    def translate({msg, opts}), do: "T:" <> msg <> ":" <> inspect(opts[:count])
  end

  @raw "can&#39;t be blank"
  @translated "nao pode ficar em branco"
  @components ~w(input textarea number_input select select_native autocomplete date_picker
                 date_picker_range date_time_picker checkbox switch radio_group pillbox
                 segmented)a

  setup do
    on_exit(fn -> Application.delete_env(:ledger_ui, :error_translator) end)
  end

  defp configure, do: Application.put_env(:ledger_ui, :error_translator, {Translator, :translate})

  # `f[:x]` and `f[:y]` are used (params present) and carry a required error.
  defp assigns do
    form =
      to_form(%{"x" => "", "y" => ""},
        as: "f",
        errors: [x: {"can't be blank", [validation: :required]}, y: {"can't be blank", []}]
      )

    %{f: form, opts: [{"A", "a"}, {"B", "b"}]}
  end

  defp render(:input, assigns), do: ~H|<.input field={@f[:x]} label="L" />|
  defp render(:textarea, assigns), do: ~H|<.textarea field={@f[:x]} label="L" />|
  defp render(:number_input, assigns), do: ~H|<.number_input field={@f[:x]} label="L" />|
  defp render(:select, assigns), do: ~H|<.select field={@f[:x]} options={@opts} />|
  defp render(:select_native, assigns), do: ~H|<.select native field={@f[:x]} options={@opts} />|

  defp render(:autocomplete, assigns),
    do: ~H|<.autocomplete field={@f[:x]} options={@opts} label="L" />|

  defp render(:date_picker, assigns), do: ~H|<.date_picker field={@f[:x]} />|

  defp render(:date_picker_range, assigns),
    do: ~H|<.date_picker start_field={@f[:x]} end_field={@f[:y]} />|

  defp render(:date_time_picker, assigns), do: ~H|<.date_time_picker field={@f[:x]} />|
  defp render(:checkbox, assigns), do: ~H|<.checkbox field={@f[:x]} label="L" />|
  defp render(:switch, assigns), do: ~H|<.switch field={@f[:x]} label="L" />|

  defp render(:radio_group, assigns),
    do: ~H|<.radio_group field={@f[:x]} options={@opts} label="L" />|

  defp render(:pillbox, assigns), do: ~H|<.pillbox field={@f[:x]} options={@opts} label="L" />|

  defp render(:segmented, assigns),
    do: ~H|<.segmented field={@f[:x]} options={@opts} label="L" />|

  defp html(name), do: name |> render(assigns()) |> rendered_to_string()

  for name <- @components do
    test "#{name}: without the config the message is the original" do
      html = html(unquote(name))
      assert html =~ @raw
      refute html =~ @translated
    end

    test "#{name}: with the config the message is the translator's" do
      configure()
      html = html(unquote(name))
      assert html =~ @translated
      refute html =~ @raw
    end
  end

  test "the range date_picker shows the errors of both fields, translated" do
    configure()
    html = html(:date_picker_range)
    assert length(String.split(html, @translated)) - 1 == 2
  end

  test "the translator receives the options (count) and may interpolate" do
    configure()

    form =
      to_form(%{"x" => ""},
        as: "f",
        errors: [x: {"should be at least %{count} character(s)", [count: 3]}]
      )

    assigns = %{f: form}
    html = rendered_to_string(~H|<.input field={@f[:x]} />|)
    assert html =~ "T:should be at least %{count} character(s):3"
  end

  test "without the config %{key} is interpolated as before" do
    form =
      to_form(%{"x" => ""},
        as: "f",
        errors: [x: {"should be at least %{count} character(s)", [count: 3]}]
      )

    assigns = %{f: form}
    html = rendered_to_string(~H|<.input field={@f[:x]} />|)
    assert html =~ "should be at least 3 character(s)"
  end

  test "strings given by hand in errors skip the translator" do
    configure()
    assigns = %{f: assigns().f}

    html =
      rendered_to_string(~H|<.input name="n" errors={["can't be blank"]} label="L" />|)

    assert html =~ @raw
    refute html =~ @translated

    html =
      rendered_to_string(~H|<.input field={@f[:x]} errors={["manual"]} label="L" />|)

    assert html =~ "manual"
    assert html =~ @translated
  end

  test "a field that was not used shows nothing, with or without the config" do
    configure()
    form = to_form(%{}, as: "f", errors: [x: {"can't be blank", []}])
    assigns = %{f: form}
    html = rendered_to_string(~H|<.input field={@f[:x]} />|)
    refute html =~ @translated
    refute html =~ @raw
  end
end
