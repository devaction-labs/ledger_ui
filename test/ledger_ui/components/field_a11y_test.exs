defmodule LedgerUI.Components.FieldA11yTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.{DatePicker, DatetimePicker, NumberInput, TimePicker}

  describe "number_input (#113)" do
    test "the spinbutton is named by the label" do
      assigns = %{}
      html = rendered_to_string(~H|<.number_input id="qty" label="Qtd" value={1} />|)
      assert html =~ ~s(id="qty-label")

      assert html =~
               ~r/role="spinbutton"[^>]*aria-labelledby="qty-label"|aria-labelledby="qty-label"[^>]*role="spinbutton"/
    end

    test "no label, no aria-labelledby" do
      assigns = %{}
      html = rendered_to_string(~H|<.number_input id="qty" value={1} />|)
      refute html =~ "aria-labelledby"
      refute html =~ "qty-label"
    end
  end

  describe "time_picker (#113)" do
    test "the label points at the input" do
      assigns = %{}
      html = rendered_to_string(~H|<.time_picker id="tp-a" name="t1" label="Hora" />|)
      assert html =~ ~r/<label[^>]*for="tp-a"/
    end
  end

  describe "pickers: the input with aria-expanded is a combobox (#113)" do
    test "date_picker, time_picker and datetime_picker" do
      assigns = %{}

      for html <- [
            rendered_to_string(~H|<.date_picker id="dp" name="d" />|),
            rendered_to_string(~H|<.time_picker id="tp" name="t" />|),
            rendered_to_string(~H|<.datetime_picker id="dt" name="dt" />|)
          ] do
        [input] = Regex.run(~r/<input[^>]*aria-expanded="false"[^>]*>/, html)
        assert input =~ ~s(role="combobox")
        assert input =~ ~s(aria-haspopup="dialog")
        assert input =~ "aria-controls="
      end
    end

    test "the split datetime_picker has no aria-expanded on its inputs" do
      assigns = %{}
      html = rendered_to_string(~H|<.datetime_picker id="dt" name="dt" split />|)
      refute html =~ "aria-expanded"
      refute html =~ ~s(role="combobox")
    end
  end
end
