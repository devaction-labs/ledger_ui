defmodule LedgerUI.Perf.TriageW1Test do
  # #95, the fields of this wave: range, rating and number_input. A new `value` sends the value,
  # not the config, the classes or the root again.
  #
  # Measured before / after (bytes of the patch, `value` changes):
  #
  #   range         507 -> 127   (the config was kept by `id`/`rest`/`marks` listing themselves as their own
  #                                source in `settle/3`, and by `pair?`, which moves with `value`)
  #   rating       2302 -> 251   (the stars are drawn by index, inline; `id` listed itself as a source)
  #   number_input  563 -> 365   (106 with `locale`): the root is no longer a `dynamic_tag`
  #
  # Discarded, with the reason (in the report of the change): radio_group tile, checkbox_group,
  # time_picker and phone_input without `locale`.
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI
  import LedgerUI.DiffCase

  defp t_range(assigns) do
    ~H"""
    <.range
      id={@id}
      name={@name}
      value={@value}
      min={@min}
      max={@max}
      step={@step}
      orientation={@orientation}
      height={@height}
      fill={@fill}
      color={@color}
      variant={@variant}
      size={@size}
      filled={@filled}
      loop={@loop}
      show_value={@show_value}
      value_format={@value_format}
      marks={@marks}
      steppers={@steppers}
      label={@label}
      help={@help}
      errors={@errors}
      disabled={@disabled}
      class={@class}
      locale="en"
    />
    """
  end

  @range %{
    id: "r1",
    name: "r",
    value: 54,
    min: 0,
    max: 100,
    step: 1,
    orientation: "horizontal",
    height: nil,
    fill: nil,
    color: nil,
    variant: "canvas",
    size: "md",
    filled: true,
    loop: false,
    show_value: true,
    value_format: "%{value}%",
    marks: [0, 50, 100],
    steppers: true,
    label: "Volume",
    help: nil,
    errors: [],
    disabled: false,
    class: nil
  }

  describe "range" do
    test "a new value does not send the config again" do
      json = patch(&t_range/1, @range, value: 59)
      refute json =~ "data-lu-config"
      assert byte_size(json) <= 300

      assert byte_size(
               patch(
                 &t_range/1,
                 %{@range | steppers: false, show_value: false, label: nil, marks: []},
                 value: 59
               )
             ) <= 200
    end

    test "every source" do
      each_source(&t_range/1, @range,
        id: "r2",
        name: "n",
        value: 70,
        min: 10,
        max: 200,
        step: 5,
        orientation: "vertical",
        fill: "red",
        color: "error",
        variant: "classic",
        size: "lg",
        filled: false,
        loop: true,
        show_value: false,
        value_format: "%{value} u",
        marks: [{0, "zero"}, 100],
        steppers: false,
        label: "Outro",
        help: "aj",
        errors: ["ruim"],
        disabled: true,
        class: "k"
      )

      each_source(&t_range/1, %{@range | orientation: "vertical"}, height: "200px")
      each_source(&t_range/1, @range, value: {10, 20}, name: nil)
    end

    test "a pair is marked by data-lu-pair, not by the config" do
      assigns = %{}

      pair =
        Phoenix.LiveViewTest.rendered_to_string(
          ~H|<.range start_name="a" end_name="b" value={{10, 20}} />|
        )

      single = Phoenix.LiveViewTest.rendered_to_string(~H|<.range name="a" value={10} />|)
      assert pair =~ "data-lu-pair"
      refute single =~ "data-lu-pair"
      refute pair =~ "&quot;pair&quot;"
      refute pair =~ "&quot;names&quot;"
    end
  end

  defp t_rating(assigns) do
    ~H"""
    <.rating
      id={@id}
      name={@name}
      value={@value}
      max={@max}
      variant={@variant}
      size={@size}
      label={@label}
      disabled={@disabled}
      show_value={@show_value}
      interactive
    />
    """
  end

  @rating %{
    id: "rt",
    name: "grade",
    value: 3,
    max: 5,
    variant: "solid",
    size: "md",
    label: "Nota",
    disabled: false,
    show_value: false
  }

  describe "rating" do
    test "a new value sends the state of the stars, not their markup" do
      json = patch(&t_rating/1, @rating, value: 4)
      assert byte_size(json) <= 400
      refute json =~ "viewBox"
      refute json =~ "data-[state=on]"
    end

    test "every source" do
      each_source(&t_rating/1, @rating,
        id: "rt2",
        name: "other",
        value: 5,
        max: 7,
        variant: "outline",
        size: "lg",
        label: "Outra",
        disabled: true,
        show_value: true
      )
    end

    test "the stars are the same markup as before: one radio and one svg per grade" do
      assigns = %{}

      html =
        Phoenix.LiveViewTest.rendered_to_string(~H|<.rating id="r" name="g" value={2} max={3} />|)

      assert length(Regex.scan(~r/<input type="radio"/, html)) == 3
      assert length(Regex.scan(~r/data-part="rating-icon"/, html)) == 3
      assert html =~ ~r/value="2"\s+checked/
    end
  end

  defp t_num(assigns) do
    ~H"""
    <.number_input
      id={@id}
      name={@name}
      value={@value}
      canvas={@canvas}
      label={@label}
      steppers={@steppers}
      locale="en"
    />
    """
  end

  describe "number_input" do
    test "a new value does not send the root again" do
      base = %{id: "n", name: "n", value: 3, canvas: false, label: nil, steppers: true}
      json = patch(&t_num/1, base, value: 5)
      refute json =~ "data-part"
      refute json =~ "phx-hook"
      assert byte_size(json) <= 200
    end

    test "every source, canvas and plain" do
      base = %{id: "n", name: "n", value: 3, canvas: false, label: "Qtd", steppers: true}

      each_source(&t_num/1, base,
        id: "m",
        name: "m",
        value: 9,
        canvas: true,
        label: "Outra",
        steppers: false
      )
    end

    test "the root is a span, or a div for canvas" do
      assigns = %{}

      html =
        Phoenix.LiveViewTest.rendered_to_string(~H|<.number_input id="a" name="a" value={1} />|)

      assert html =~ ~r/\A\s*<span id="a" data-part="number-input"/

      html =
        Phoenix.LiveViewTest.rendered_to_string(
          ~H|<.number_input id="a" name="a" value={1} canvas />|
        )

      assert html =~ ~r/\A\s*<div id="a" data-part="number-input"/
    end
  end
end
