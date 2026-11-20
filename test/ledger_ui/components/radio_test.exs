defmodule LedgerUI.Components.RadioTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Radio

  test "basic radios share a name and check the value" do
    form = to_form(%{"plan" => "pro"}, as: "f")
    assigns = %{form: form}

    html =
      rendered_to_string(~H"""
      <.radio_group
        field={@form[:plan]}
        color="primary"
        size="sm"
        options={[{"Free", "free"}, {"Pro", "pro"}]}
      />
      """)

    assert html =~ ~s(class="lu-check c-primary s-sm")
    assert html =~ ~r/name="f\[plan\]" value="free"/
    assert html =~ ~r/name="f\[plan\]" value="pro" checked/
    assert html =~ ~s(<span class="t">)
  end

  test "slots may override color and disabled; shape and filled classes" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.radio_group name="b" value="primary" shape="squircle" filled class="grid">
        <:radio value="default">Default</:radio>
        <:radio value="primary" color="primary">Primary</:radio>
        <:radio value="error" color="error" disabled>Error</:radio>
      </.radio_group>
      """)

    assert html =~ ~s(class="grid")
    assert html =~ "c-error"
    assert html =~ "squircle"
    assert html =~ "filled"
    assert html =~ "dis"
    assert html =~ "Primary"
  end

  test "card variant: lu-choice, control end, description, count and icon" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.radio_group
        name="p"
        variant="card"
        control="end"
        value="a"
        options={[
          %{label: "Essencial", value: "a", description: "500 notas", count: "R$ 89", icon: "building"}
        ]}
      />
      """)

    assert html =~ ~s(class="lu-choice end")
    assert html =~ ~s(class="lu-rd")
    assert html =~ ~s(class="price")
    assert html =~ "500 notas"
    assert html =~ "lu-ic acc"
    assert html =~ ~s(phx-hook="LedgerUI.ChoiceGroup")
  end

  test "chip and tile variants keep a real radio and the on class" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.radio_group
        name="s"
        variant="chip"
        shape="pill"
        value="b"
        options={[%{label: "Todos", value: "a", count: 4}, "b"]}
      />
      """)

    assert html =~ ~s(class="lu-rchip pill c-neutral") == false
    assert html =~ ~r/class="lu-rchip pill on"/
    assert html =~ ~r/<input type="radio"[^>]*name="s"/

    html =
      rendered_to_string(~H"""
      <.radio_group name="m" variant="tile" value="a" label="Mark" label_hint="optional">
        <:radio value="a" aria_label="Segment A">A</:radio>
        <:radio value="b" aria_label="Segment B" disabled>B</:radio>
      </.radio_group>
      """)

    assert html =~ ~s(class="lu-rtile on")
    assert html =~ ~s(aria-label="Segment A")
    assert html =~ "opacity:.35"
    assert html =~ ~s(role="radiogroup")
    assert html =~ ~s(class="hint")
  end

  test "segmented variant: buttons over real radios" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.radio_group
        name="period"
        variant="segmented"
        size="xs"
        value="week"
        options={[
          %{label: "Day", value: "day"},
          %{label: "Week", value: "week", count: 3},
          %{label: "Month", value: "month", disabled: true}
        ]}
      />
      """)

    assert html =~ ~s(class="lu-seg sm")
    assert html =~ ~s(phx-hook="LedgerUI.Segmented")
    assert html =~ ~r/<input type="radio"[^>]*name="period" value="week" checked/
    assert html =~ ~r/<button[^>]*class="on"/
    assert html =~ ~s(<span class="n">3</span>)
  end
end
