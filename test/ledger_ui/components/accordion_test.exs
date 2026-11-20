defmodule LedgerUI.Components.AccordionTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Accordion

  defp html(fun), do: fun.(%{}) |> rendered_to_string()

  test "variant and color classes; multiple flag" do
    html =
      html(fn assigns ->
        ~H|<.accordion id="a" variant="primary" color="warning" multiple>
  <.accordion_item id="a1" title="T">c</.accordion_item>
</.accordion>|
      end)

    assert html =~ "text-(--c-ink)"
    assert html =~ "[--c-ink:var(--lu-warn)]"
    assert html =~ ~s(data-lu-multiple="true")
  end

  test "default is canvas, single open" do
    html = html(fn assigns -> ~H|<.accordion id="a">
  <.accordion_item id="a1" title="T">c</.accordion_item>
</.accordion>| end)
    assert html =~ "*:bg-sunken"
    refute html =~ "--c-ink"
    assert html =~ ~s(data-lu-multiple="false")
  end

  test "item: closed hides the body, open marks it" do
    html =
      html(fn assigns ->
        ~H"""
        <.accordion id="a">
          <.accordion_item id="a1" title="One" open>Body one</.accordion_item>
          <.accordion_item id="a2" title="Two">Body two</.accordion_item>
        </.accordion>
        """
      end)

    [_, one, two] = String.split(html, ~s(data-part="accordion-item"))
    assert one =~ ~s(data-state="open")
    assert one =~ "Body one"
    refute one =~ "display:none"
    assert two =~ "display:none"
    assert html =~ ~s(phx-hook="LedgerUI.Collapse")
    assert html =~ ~s(data-icon="chevron-down")
  end

  test "item without content has no body; header slot replaces the title" do
    html =
      html(fn assigns ->
        ~H"""
        <.accordion_item id="a1" title="ignored">
          <:header>Custom header</:header>
        </.accordion_item>
        """
      end)

    assert html =~ "Custom header"
    refute html =~ "ignored"
    refute html =~ "accordion-body"
  end

  test "events, extra classes" do
    html =
      html(fn assigns ->
        ~H|<.accordion_item
  id="a1"
  title="T"
  on_open="o"
  on_close="c"
  target="#t"
  class="mo"
  trigger_class="tc"
>
  x
</.accordion_item>|
      end)

    assert html =~ ~s(data-lu-on-open="o")
    assert html =~ ~s(data-lu-on-close="c")
    assert html =~ ~s(data-lu-target="#t")
    assert html =~ ~r/class="[^"]*\bmo\b/
    assert html =~ ~r/accordion-header" class="[^"]*\btc\b/
  end
end
