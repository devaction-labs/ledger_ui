defmodule LedgerUI.Components.CollapseTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Collapse

  defp html(fun), do: fun.(%{}) |> rendered_to_string()

  test "native details with a summary trigger" do
    html =
      html(fn assigns ->
        ~H|<.collapse id="c"><:trigger>Title</:trigger>Content</.collapse>|
      end)

    assert html =~ "<details"
    assert html =~ "<summary"
    assert html =~ "Title"
    assert html =~ "Content"
    assert html =~ ~s(phx-hook="LedgerUI.Collapse")
    refute html =~ ~s( open)
    # canvas by default
    assert html =~ "border-radius:14px"
    assert html =~ "ac-panel"
  end

  test "open attribute" do
    html = html(fn assigns -> ~H|<.collapse id="c" open><:trigger>T</:trigger>x</.collapse>| end)
    assert html =~ ~r/<details[^>]* open/
    assert html =~ ~s(data-lu-open="true")
  end

  test "classic leaves the trigger to its class and has no panel wrapper" do
    html =
      html(fn assigns ->
        ~H|<.collapse id="c" variant="classic" class="box"><:trigger class="row">T</:trigger>x</.collapse>|
      end)

    assert html =~ ~s(class="box")
    assert html =~ ~s(<summary class="row">)
    refute html =~ "ac-panel"
    refute html =~ "border-radius:14px"
  end

  test "framed, flat and section looks" do
    for {v, needle} <- [
          {"framed", "border-radius:12px"},
          {"flat", "border-bottom:1px solid var(--line)"},
          {"section", "text-transform:uppercase"}
        ] do
      assigns = %{v: v}

      html =
        rendered_to_string(~H|<.collapse id="c" variant={@v}><:trigger>T</:trigger>x</.collapse>|)

      assert html =~ needle, "#{v} should contain #{needle}"
    end
  end

  test "chevron adds an icon and makes the trigger a flex row" do
    down =
      html(fn assigns ->
        ~H|<.collapse id="c" chevron="down"><:trigger>T</:trigger>x</.collapse>|
      end)

    right =
      html(fn assigns ->
        ~H|<.collapse id="c" chevron="right" chevron_class="big"><:trigger>T</:trigger>x</.collapse>|
      end)

    assert down =~ ~s(data-icon="chevron-down")
    assert down =~ "justify-content:space-between"
    assert right =~ ~s(data-icon="chevron-right")
    assert right =~ "big"
    assert right =~ ~s(data-lu-chevron="right")
  end

  test "events and panel_class" do
    html =
      html(fn assigns ->
        ~H|<.collapse id="c" on_open="o" on_close="c" target="#t" panel_class="px-4">
  <:trigger>T</:trigger>x
</.collapse>|
      end)

    assert html =~ ~s(data-lu-on-open="o")
    assert html =~ ~s(data-lu-on-close="c")
    assert html =~ "ac-panel px-4"
  end

  test "collapse_text clamps and links to the text" do
    html =
      html(fn assigns ->
        ~H|<.collapse_text id="d" lines={3} more="More" less="Less">Long text</.collapse_text>|
      end)

    assert html =~ "-webkit-line-clamp:3"
    assert html =~ "Long text"
    assert html =~ ">\n        More\n" or html =~ "More"
    assert html =~ ~s(aria-expanded="false")
    assert html =~ ~s(aria-controls="d-text")

    open = html(fn assigns -> ~H|<.collapse_text id="d" open>Long</.collapse_text>| end)
    refute open =~ "line-clamp"
    assert open =~ "Show less"
    assert open =~ ~s(aria-expanded="true")
  end
end
