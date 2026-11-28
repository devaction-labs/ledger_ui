defmodule LedgerUI.Components.FieldLabelsTest do
  # #113 (extension): `label=` names the control in color_picker, datetime_picker, rating,
  # signature_pad, tags_input and the editors' link and image dialogs.
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias LedgerUI.Components, as: C

  defp r(fun, assigns), do: render_component(fun, assigns)

  test "color_picker: the group is named by the label" do
    html = r(&C.ColorPicker.color_picker/1, %{id: "cp", label: "Cor"})
    assert html =~ ~s(id="cp-label")
    assert html =~ ~s(role="group")
    assert html =~ ~s(aria-labelledby="cp-label")
    refute r(&C.ColorPicker.color_picker/1, %{id: "cp"}) =~ "aria-labelledby"
  end

  test "signature_pad: the group is named by the label" do
    html = r(&C.SignaturePad.signature_pad/1, %{id: "sp", label: "Assinatura"})
    assert html =~ ~s(id="sp-label")
    assert html =~ ~s(aria-labelledby="sp-label")
  end

  test "rating: the radiogroup (or the image) is named by the label" do
    html = r(&C.Rating.rating/1, %{id: "rt", label: "Nota", interactive: true, value: 3})
    assert html =~ ~s(id="rt-label")
    assert html =~ ~s(role="radiogroup")
    assert html =~ ~s(aria-labelledby="rt-label")
    refute html =~ ~s(aria-label="Nota")

    static = r(&C.Rating.rating/1, %{id: "rt", label: "Nota", value: 3})
    assert static =~ ~s(aria-labelledby="rt-label rt")
    assert static =~ ~s(role="img" aria-label=)
  end

  test "tags_input: the input is named by the label" do
    html = r(&C.TagsInput.tags_input/1, %{id: "tg", label: "Tags"})
    assert html =~ ~s(id="tg-label")
    assert html =~ ~s(aria-labelledby="tg-label")
  end

  test "datetime_picker: label for the input, time list in a radiogroup, split labels" do
    html = r(&C.DatetimePicker.datetime_picker/1, %{id: "dt", label: "Quando"})
    assert html =~ ~r/<label[^>]*id="dt-label"[^>]*for="dt"|<label[^>]*for="dt"[^>]*id="dt-label"/

    panel =
      r(&C.DatetimePicker.datetime_picker_panel/1, %{
        times: ["09:00"],
        time: "09:00",
        locale: "en"
      })

    assert panel =~ ~s(role="radiogroup" aria-label="Times")
    assert panel =~ ~s(role="radio")

    split =
      r(&C.DatetimePicker.datetime_picker/1, %{
        id: "dt",
        split: true,
        date_label: "Dia",
        time_label: "Hora"
      })

    assert split =~ ~s(for="dt")
    assert split =~ ~s(for="dt-time")
    assert split =~ ~s(id="dt-time")
  end

  test "text_editor: the link and image dialog labels point to their inputs" do
    html = r(&C.TextEditor.text_editor/1, %{id: "ed"})

    for suffix <- ~w(link-url image-src image-alt) do
      assert html =~ ~s(for="ed-#{suffix}")
      assert html =~ ~s(id="ed-#{suffix}")
    end
  end

  test "switch without a name is a button with role switch, no label" do
    html = r(&C.Switch.switch/1, %{label: "Ativo", id: "s"})
    assert html =~ ~r/<button type="button"[^>]*role="switch"/
    refute html =~ "<label"
    disabled = r(&C.Switch.switch/1, %{label: "Ativo", disabled: true})
    assert disabled =~ ~r/<button[^>]*disabled/
  end
end
