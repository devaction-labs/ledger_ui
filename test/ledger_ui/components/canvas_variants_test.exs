defmodule LedgerUI.Components.CanvasVariantsTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.{Button, Checkbox, NumberInput, Segmented}

  test "button canvas is the compact lu-btn" do
    assigns = %{}
    html = rendered_to_string(~H|<.button canvas size="sm">Colunas</.button>|)
    assert html =~ "h-[30px]"
    assert html =~ "border-line-strong bg-panel"
    refute html =~ "bg-(--c)"
    assert rendered_to_string(~H|<.button canvas>Ok</.button>|) =~ "h-9"
  end

  test "checkbox style goes on the label, not on the input" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.checkbox name="n" label="Avisar" style="margin-right:auto" />|)

    assert html =~ ~s(<label class="lu-check c-neutral s-md" style="margin-right:auto">)
    refute html =~ ~r/<input[^>]*style=/
  end

  test "segmented stretch and role" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.segmented id="s" value="a" role="tablist" stretch options={~w(a b)} />|
      )

    assert html =~ ~s(role="tablist")
    assert html =~ ~s(style="width:100%")
    assert html =~ ~s(style="flex:1")
    assert rendered_to_string(~H|<.segmented id="s" options={~w(a)} />|) =~ ~s(role="group")
  end

  test "number_input canvas is a div with a .minus button and small icons" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.number_input id="q" name="q" value={3} steppers canvas size="sm" />|
      )

    assert html =~ ~r/<div[^>]*class="lu-num s-sm"/
    assert html =~ ~s(class="minus")
    assert html =~ "size-3.5"

    plain = rendered_to_string(~H|<.number_input id="q" name="q" value={3} steppers />|)
    assert plain =~ ~r/<span[^>]*class="lu-num/
    refute plain =~ ~s(class="minus")
  end
end
