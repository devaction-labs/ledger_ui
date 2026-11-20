defmodule LedgerUI.Components.CardTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Card
  import LedgerUI.Components.Button

  test "the default is the tray with a title hugging a panel" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card title="Revenue by plan">
        <:actions><.button size="sm">Plans</.button></:actions>
        corpo
        <:footer>trailing 12 mo</:footer>
      </.card>
      """)

    assert html =~ "bg-tray rounded-xl p-1.5"
    assert html =~ "Revenue by plan"
    assert html =~ ~s(data-part="card-actions")
    assert html =~ ~s(data-part="card-body")
    assert html =~ "rounded-lg border border-line"
    assert html =~ "trailing 12 mo"
    # the title is text, not a tooltip
    refute html =~ ~s(title=)
  end

  test "flat drops the tray" do
    assigns = %{}
    html = rendered_to_string(~H|<.card variant="flat">x</.card>|)
    assert html =~ "bg-panel rounded-xl p-0"
    refute html =~ "bg-tray"
    assert html =~ "rounded-xl"
  end

  test "the title slot and title_extra" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card>
        <:title>Markup</:title><:title_extra>(3)</:title_extra>x
      </.card>
      """)

    assert html =~ "Markup"
    assert html =~ "(3)"
  end

  test "surface variants, colour and gradient" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.card variant="gradient" gradient="sky-blue"><:title>T</:title>body</.card>|
      )

    assert html =~ "[--g1:#0ea5e9] [--g2:#2563eb]"
    assert html =~ "bg-[linear-gradient(135deg,var(--g1),var(--g2))]"
    assert html =~ ~r/<b[^>]*>T<\/b>/
    assert html =~ "body"

    solid = rendered_to_string(~H|<.card variant="solid" color="error">x</.card>|)
    assert solid =~ "[--c:var(--lu-neg)]"
    assert solid =~ "bg-(--c) text-(--c-on)"
  end

  test "size, shape and padded pick the padding and the radius" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.card variant="default" size="xs" shape="xl" padded={false}>x</.card>|
      )

    assert html =~ "p-0"
    refute html =~ "p-2 "
    assert html =~ "rounded-[22px]"
    assert html =~ "min-h-0"

    md = rendered_to_string(~H|<.card variant="default">x</.card>|)
    assert md =~ "p-3.5"
    assert md =~ "min-h-[92px]"
  end

  test "links render as a row with an arrow" do
    assigns = %{}
    html = rendered_to_string(~H|<.card href="/banks/1">Banco</.card>|)
    assert html =~ ~s(<a)
    assert html =~ ~s(href="/banks/1")
    assert html =~ "flex-row items-center gap-2.5"
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
    assert html =~ ~s(data-part="card-header")
    assert html =~ "<h3"
    assert html =~ ~s(data-part="card-actions")
    assert html =~ ~s(data-part="card-body")
    assert html =~ "justify-between"
    assert html =~ ~s(data-part="card-footer")
    # the parts read the variant of the card
    assert html =~ ~s(data-lu-variant="tray")
  end

  test "heading and header sizes" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card_header size="lg">
        <.card_heading size="xl" level={1}>X</.card_heading>
      </.card_header>
      """)

    assert html =~ "min-h-[52px]"
    assert html =~ "text-[18px]"
    assert html =~ "<h1"
  end
end
