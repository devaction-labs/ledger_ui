defmodule LedgerUI.Components.InputGroupTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.InputGroup

  test "bare group is a row of addons" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input_group>
        <.input_group_addon>R$</.input_group_addon>
        <span class="v">10</span>
        <.input_group_addon variant="filled" size="sm">,00</.input_group_addon>
      </.input_group>
      """)

    assert html =~ ~s(data-part="input-group")
    assert html =~ "inline-flex"
    assert html =~ "h-9"
    refute html =~ "role="
    assert html =~ ~r/<span data-part="addon" class="[^"]*bg-sunken[^"]*">R\$<\/span>/
  end

  test "shape, size, variant and state classes" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input_group shape="pill" size="lg" variant="filled" state="success">x</.input_group>
      """)

    assert html =~ "h-10"
    assert html =~ "rounded-full"
    assert html =~ "bg-sunken"
    assert html =~ "border-pos"

    html = rendered_to_string(~H|<.input_group size="sm" state="error">x</.input_group>|)
    assert html =~ "h-8"
    assert html =~ "border-neg"
  end

  test "label, help and errors name the group and describe it" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input_group id="price" label="Price" errors={["must be positive"]}>x</.input_group>
      """)

    assert html =~ ~s(role="group")
    assert html =~ ~s(aria-labelledby="price-label")
    assert html =~ ~s(id="price-label")
    assert html =~ ~s(aria-invalid="true")
    assert html =~ ~s(aria-describedby="price-msg")
    assert html =~ ~s(id="price-msg")
    assert html =~ "border-neg"
    assert html =~ "must be positive"
  end

  test "the id comes from the label when not given" do
    assigns = %{}
    html = rendered_to_string(~H|<.input_group label="Unit price" help="h">x</.input_group>|)
    assert html =~ ~s(id="igrp-unit-price")
    assert html =~ ~s(aria-labelledby="igrp-unit-price-label")
  end
end
