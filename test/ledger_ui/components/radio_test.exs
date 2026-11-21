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

    assert html =~ "[--c:var(--color-accent)]"
    assert html =~ "size-4"
    assert html =~ ~r/name="f\[plan\]" value="free"/
    assert html =~ ~r/name="f\[plan\]" value="pro" checked/
    assert html =~ ~s(data-part="radio-text")
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

    assert html =~ ~r/class="grid"/
    assert html =~ "[--c:var(--lu-neg)]"
    assert html =~ "rounded-[6px]"
    assert html =~ "bg-(--c-soft)"
    assert html =~ "cursor-not-allowed"
    assert html =~ "Primary"
  end

  test "card variant: choice, control end, description, count and icon" do
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

    assert html =~ ~s(data-part="choice")
    assert html =~ "[&amp;_input]:order-3"
    # the control is drawn from the tokens (it follows the accent), not the browser's native radio
    assert html =~ "appearance-none"
    assert html =~ "checked:border-(--c)"
    assert html =~ ~s(data-part="choice-count")
    assert html =~ "500 notas"
    assert html =~ "group-has-checked:bg-accent-soft"
    refute html =~ "LedgerUI.ChoiceGroup"
  end

  test "chip and tile variants keep a real radio and the has-checked look" do
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

    assert html =~ "rounded-full"
    assert html =~ "has-checked:bg-(--c-soft)"
    assert html =~ ~r/<input[^>]*type="radio"[^>]*name="s"/

    html =
      rendered_to_string(~H"""
      <.radio_group name="m" variant="tile" value="a" label="Mark" label_hint="optional">
        <:radio value="a" aria_label="Segment A">A</:radio>
        <:radio value="b" aria_label="Segment B" disabled>B</:radio>
      </.radio_group>
      """)

    assert html =~ "size-[52px]"
    assert html =~ ~s(aria-label="Segment A")
    assert html =~ "opacity-35"
    assert html =~ ~s(role="radiogroup")
    assert html =~ ~s(data-part="label-hint")
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

    assert html =~ "bg-sunken"
    assert html =~ "h-6 px-[9px]"
    assert html =~ ~s(phx-hook="LedgerUI.Segmented")
    assert html =~ ~r/<input[^>]*type="radio"[^>]*name="period" value="week" checked/
    assert html =~ ~r/<button[^>]*aria-pressed="true"/
    assert html =~ ~s(data-part="segmented-count")
  end

  test "slots take a style, a checked flag, a shape and filled" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.radio_group id="g" variant="chip">
        <:radio value="a" style="--dl:1s">A</:radio>
        <:radio value="b" checked>B</:radio>
      </.radio_group>
      """)

    assert html =~ ~s(style="--dl:1s")
    assert html =~ "has-checked:bg-(--c-soft)"

    html =
      rendered_to_string(~H"""
      <.radio_group id="h">
        <:radio value="a" shape="squircle" checked>A</:radio>
        <:radio value="b" filled>B</:radio>
      </.radio_group>
      """)

    assert html =~ "rounded-[6px]"
    assert html =~ "bg-(--c-soft)"
    assert html =~ "checked"
  end

  @signers [
    %{label: "Ana", value: "ana", description: "Titular"},
    %{label: "Bia", value: "bia", disabled: true}
  ]

  test "card trailing: inside the card, outside the label, per option" do
    assigns = %{signers: @signers}

    html =
      rendered_to_string(~H"""
      <.radio_group id="s" name="s" variant="card" options={@signers}>
        <:trailing :let={opt}><button type="button">Enviar {opt.label}</button></:trailing>
      </.radio_group>
      """)

    assert html =~ "Enviar Ana"
    assert html =~ "Enviar Bia"
    # the card is a div; the label (for the radio) holds only the text
    refute html =~ "<label data-part=\"choice\""
    assert html =~ ~s(<label for="s-0" data-part="choice-text")
    assert html =~ "after:absolute after:inset-0"
    # no button inside a label
    refute Regex.match?(~r|<label[^>]*>(?:(?!</label>).)*<button|s, html)
    assert html =~ ~s(data-part="choice-trailing")
  end

  test "card trailing: a disabled option makes the whole card inert" do
    assigns = %{signers: @signers}

    html =
      rendered_to_string(~H"""
      <.radio_group id="s" name="s" variant="card" options={@signers}>
        <:trailing :let={opt}><button type="button">Enviar {opt.label}</button></:trailing>
      </.radio_group>
      """)

    [first, second] = String.split(html, ~s(data-part="choice" ), trim: true) |> Enum.take(-2)
    refute first =~ "inert"
    assert second =~ "inert"
    assert second =~ "disabled"
    assert second =~ "cursor-not-allowed opacity-45"
  end

  test "card without trailing keeps the label card" do
    assigns = %{signers: @signers}

    html =
      rendered_to_string(~H|<.radio_group id="s" name="s" variant="card" options={@signers} />|)

    assert html =~ ~s(<label data-part="choice")
    refute html =~ "choice-trailing"
  end
end
