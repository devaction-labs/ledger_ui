defmodule LedgerUI.Components.CardTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Card

  test "surface classes, colour and gradient" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.card variant="gradient" gradient="sky-blue"><:title>T</:title>body</.card>|
      )

    assert html =~ "lu-cv gradient c-primary g-sky-blue"
    assert html =~ ~r/<b[^>]*>T<\/b>/
    assert html =~ "body"
  end

  test "size, shape and padded set the inline style" do
    assigns = %{}
    html = rendered_to_string(~H|<.card size="xs" shape="xl" padded={false}>x</.card>|)
    assert html =~ "padding:0"
    assert html =~ "border-radius:22px"
  end

  test "links render as a row with an arrow" do
    assigns = %{}
    html = rendered_to_string(~H|<.card href="/banks/1">Banco</.card>|)
    assert html =~ ~s(<a)
    assert html =~ ~s(href="/banks/1")
    assert html =~ "chevron-right"
    refute rendered_to_string(~H|<.card href="/b" arrow={false}>x</.card>|) =~ "chevron-right"
  end

  test "canvas card composes its parts" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card canvas>
        <.card_header>
          <.card_heading level={3}>Profile</.card_heading>
          <.card_subheading>Sub</.card_subheading>
          <.card_actions>act</.card_actions>
        </.card_header>
        <.card_body>body</.card_body>
        <.card_footer align="between">foot</.card_footer>
      </.card>
      """)

    assert html =~ ~s(<section)
    assert html =~ "lu-card-h"
    assert html =~ "<h3"
    assert html =~ ~s(class="act")
    assert html =~ ~s(class="lu-card-b" style="")
    assert html =~ "justify-content:space-between"
    assert html =~ "lu-card-f"
  end

  test "card_body can omit its style" do
    assigns = %{}
    refute rendered_to_string(~H|<.card_body style={false}>x</.card_body>|) =~ "style"
  end
end
