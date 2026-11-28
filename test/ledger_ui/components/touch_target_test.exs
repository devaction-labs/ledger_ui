defmodule LedgerUI.Components.TouchTargetTest do
  # #122 item 1: the x of a chip (select, pillbox, tags_input) and the buttons of the number stepper
  # get a touch target of at least 24x24 without changing the look.
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias LedgerUI.Components, as: C

  # The button itself is the 24px box (icon centred), with a negative margin so the layout stays 14px.
  @box ["size-6", "-m-[5px]", "place-items-center"]

  test "select and pillbox chips: the remove button has a 24x24 box" do
    opts = [{"A", "a"}, {"B", "b"}]

    for fun <- [&C.Select.select/1, &C.Pillbox.pillbox/1] do
      html =
        render_component(fun, %{
          id: "x",
          options: opts,
          multiple: true,
          value: ["a"],
          removable: true
        })

      [button] = Regex.run(~r/<button[^>]*data-lu-remove[^>]*>/, html)
      for c <- @box, do: assert(button =~ c)
      refute button =~ "before:"
    end
  end

  test "the classes the hooks draw carry it too" do
    json = C.Select.Options.js_classes()
    for c <- @box, do: assert(json =~ c)
  end

  test "tags_input chip remove button" do
    html = render_component(&C.TagsInput.tags_input/1, %{id: "t", value: ["a"], removable: true})
    [button] = Regex.run(~r/<button[^>]*data-lu-remove[^>]*>/, html)
    for c <- @box, do: assert(button =~ c)
  end

  test "number stepper buttons do not shrink below their width" do
    html = render_component(&C.NumberInput.number_input/1, %{id: "n", value: 1, steppers: true})
    [minus] = Regex.run(~r/<button[^>]*data-part="number-minus"[^>]*>/, html)
    assert minus =~ "shrink-0"
  end
end
