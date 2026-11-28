defmodule LedgerUI.Components.ConfigOrderTest do
  # #109: the JSON of `data-lu-*` has its keys in alphabetical order at every depth, so two VMs
  # that loaded the modules in another order print the same bytes.
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias LedgerUI.Components, as: C
  alias LedgerUI.HTMLNormalizer

  @calls [
    {&C.DatePicker.date_picker/1, %{id: "d", locale: "en", today: "2024-03-10", name: "n"}},
    {&C.DatetimePicker.datetime_picker/1, %{id: "d", locale: "en", today: "2024-03-10"}},
    {&C.TimePicker.time_picker/1, %{id: "t", locale: "en"}},
    {&C.Range.range/1, %{id: "r", value: 3}},
    {&C.NumberInput.number_input/1, %{id: "n", value: 3, locale: "en"}},
    {&C.SignaturePad.signature_pad/1, %{id: "s"}},
    {&C.TextEditor.text_editor/1, %{id: "e"}},
    {&C.TagsInput.tags_input/1, %{id: "g"}},
    {&C.Select.select/1, %{id: "x", options: [{"A", "a"}], multiple: true, value: ["a"]}}
  ]

  defp sorted?(%Jason.OrderedObject{values: values}) do
    keys = Enum.map(values, &elem(&1, 0))
    keys == Enum.sort(keys) and Enum.all?(values, fn {_, v} -> sorted?(v) end)
  end

  defp sorted?(list) when is_list(list), do: Enum.all?(list, &sorted?/1)
  defp sorted?(_), do: true

  test "every data-lu JSON is printed with sorted keys" do
    for {fun, assigns} <- @calls do
      html = render_component(fun, assigns)

      attrs =
        Regex.scan(~r/ data-lu-[a-z-]+="(\{[^"]*|\[[^"]*)"/, html, capture: :all_but_first)

      assert attrs != [], "#{inspect(fun)} printed no JSON attribute"

      for [raw] <- attrs do
        decoded =
          raw
          |> String.replace("&quot;", "\"")
          |> String.replace("&amp;", "&")
          |> String.replace("&#39;", "'")
          |> Jason.decode!(objects: :ordered_objects)

        assert sorted?(decoded), "#{inspect(fun)}: keys out of order in #{raw}"
      end
    end
  end

  test "the normalizer keeps the order of an already sorted config" do
    {fun, assigns} = hd(@calls)
    html = render_component(fun, assigns)
    normal = HTMLNormalizer.normalize(html)
    assert normal == HTMLNormalizer.normalize(normal)

    [raw] = Regex.run(~r/ data-lu-config="([^"]*)"/, normal, capture: :all_but_first)
    [raw_html] = Regex.run(~r/ data-lu-config="([^"]*)"/, html, capture: :all_but_first)

    assert String.replace(raw, "&#39;", "'") == String.replace(raw_html, "&#39;", "'")
  end
end
