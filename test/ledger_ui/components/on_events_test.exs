defmodule LedgerUI.Components.OnEventsTest do
  # #119 item 1 (the fields): an `on_*` that reports a state the form also holds takes a `%JS{}` (the
  # hook runs it); one whose data exists nowhere else (the text typed, an offset, a key, the
  # selection, the values staged) raises an `ArgumentError` for a `%JS{}` instead of reaching the hook
  # as the name of an event.
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias LedgerUI.Components, as: C
  alias Phoenix.LiveView.JS

  @js JS.push("x")

  defp r(fun, assigns), do: render_component(fun, assigns)

  describe "accepted" do
    test "pickers: on_change goes into the config as the JSON of the commands" do
      for {fun, extra} <- [
            {&C.DatePicker.date_picker/1, %{today: "2024-03-10"}},
            {&C.DatetimePicker.datetime_picker/1, %{today: "2024-03-10"}},
            {&C.TimePicker.time_picker/1, %{}}
          ] do
        html = r(fun, Map.merge(%{id: "p", locale: "en", on_change: @js}, extra))
        assert html =~ "&quot;onChange&quot;:&quot;[["

        named = r(fun, Map.merge(%{id: "p", locale: "en", on_change: "go"}, extra))
        assert named =~ "&quot;onChange&quot;:&quot;go&quot;"
      end
    end

    test "signature_pad: on_change and on_confirm" do
      html = r(&C.SignaturePad.signature_pad/1, %{id: "s", on_change: @js, on_confirm: @js})
      assert html =~ "&quot;onChange&quot;:&quot;[["
      assert html =~ "&quot;onConfirm&quot;:&quot;[["
    end

    test "text_editor: on_change, on_image and on_submit" do
      html =
        r(&C.TextEditor.text_editor/1, %{id: "e", on_change: @js, on_image: @js, on_submit: @js})

      assert html =~ ~r/data-lu-on-change="\[\[/
      assert html =~ ~r/data-lu-on-image="\[\[/
      assert html =~ ~r/data-lu-on-submit="\[\[/
      named = r(&C.TextEditor.text_editor/1, %{id: "e", on_change: "chg"})
      assert named =~ ~s(data-lu-on-change="chg")
    end

    test "filter_menu: on_clear" do
      html = r(&C.FilterMenu.filter_menu/1, %{id: "f", on_clear: @js})
      assert html =~ ~r/data-lu-on-clear="\[\[/
    end
  end

  describe "ArgumentError" do
    test "search and load_more carry text and offset" do
      assert_raise ArgumentError, ~r/on_search/, fn ->
        r(&C.Autocomplete.autocomplete/1, %{id: "a", options: ["x"], on_search: @js})
      end

      assert_raise ArgumentError, ~r/on_search/, fn ->
        r(&C.TagsInput.tags_input/1, %{id: "t", on_search: @js})
      end

      assert_raise ArgumentError, ~r/on_search/, fn ->
        r(&C.Pillbox.pillbox/1, %{id: "p", options: ["x"], on_search: @js})
      end

      for fun <- [&C.Select.select/1, &C.Pillbox.pillbox/1] do
        assert_raise ArgumentError, ~r/on_load_more.*offset/, fn ->
          r(fun, %{id: "s", options: ["x"], on_load_more: @js})
        end
      end
    end

    test "text_editor on_ai and on_slash, phone_input on_country_change, filter_menu on_change and on_apply" do
      for key <- [:on_ai, :on_slash] do
        assert_raise ArgumentError, ~r/#{key}/, fn ->
          r(&C.TextEditor.text_editor/1, Map.put(%{id: "e"}, key, @js))
        end
      end

      assert_raise ArgumentError, ~r/on_country_change/, fn ->
        r(&C.PhoneInput.phone_input/1, %{id: "p", on_country_change: @js})
      end

      for key <- [:on_change, :on_apply] do
        assert_raise ArgumentError, ~r/#{key}/, fn ->
          r(&C.FilterMenu.filter_menu/1, Map.put(%{id: "f"}, key, @js))
        end
      end
    end

    test "anything else is not an event" do
      assert_raise ArgumentError, ~r/expects an event name/, fn ->
        r(&C.DatePicker.date_picker/1, %{id: "d", on_change: 3})
      end
    end
  end
end
