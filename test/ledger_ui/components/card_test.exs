defmodule LedgerUI.Components.CardTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Card
  import LedgerUI.Components.Button

  test "the default is one surface: panel, hairline border, shadow-xs, header and footer rules" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card title="Revenue by plan">
        <:actions><.button size="sm">Plans</.button></:actions>
        corpo
        <:footer>trailing 12 mo</:footer>
      </.card>
      """)

    assert html =~ "rounded-[18px]"
    assert html =~ "border border-line bg-panel shadow-xs"
    assert html =~ "overflow-hidden"
    refute html =~ "bg-tray"
    refute html =~ " p-1.5"
    refute html =~ "uppercase"
    assert html =~ "text-sm leading-5 font-semibold text-ink"
    assert html =~ "border-b border-line"
    assert html =~ "border-t border-line"
    assert html =~ "Revenue by plan"
    assert html =~ ~s(data-part="card-actions")
    assert html =~ ~s(data-part="card-body")
    # the body has no border of its own
    refute html =~ ~s(card-body" class="relative min-w-0 flex-1 bg-panel p-4 rounded-lg)
    assert html =~ "trailing 12 mo"
    # the title is text, not a tooltip
    refute html =~ ~s(title=)
  end

  test "panel renders the same single surface as the tray" do
    assigns = %{}
    html = rendered_to_string(~H|<.card variant="panel">x</.card>|)
    assert html =~ "border border-line bg-panel shadow-xs"
    refute html =~ "bg-tray"
    assert html =~ "rounded-[18px]"
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

  test "the default card with body_padded={false} has a p-0 body and clips the table" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card title="Orders" body_padded={false}>
        <table data-x="t"></table>
      </.card>
      """)

    assert html =~ ~r/data-part="card-body"[^>]*class="[^"]*\bp-0\b/
    refute html =~ ~r/data-part="card-body"[^>]*class="[^"]*\bp-4\b/
    assert html =~ "overflow-hidden"
  end

  test "size, shape and padded pick the padding and the radius" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.card variant="default" size="xs" shape="xl" padded={false}>x</.card>|
      )

    assert html =~ "p-0"
    refute html =~ "p-2 "
    assert html =~ "rounded-xl"
    refute html =~ "rounded-[22px]"
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

  test "flat is the sunken surface; canvas and page are aliases" do
    assigns = %{}
    assert rendered_to_string(~H|<.card variant="flat">x</.card>|) =~ "bg-sunken"
    assert rendered_to_string(~H|<.card variant="canvas">x</.card>|) =~ "bg-sunken"
    assert rendered_to_string(~H|<.card variant="page">x</.card>|) =~ "bg-panel"
  end

  test "card_body padded={false} drops the padding" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.card canvas>
  <.card_body padded={false}>x</.card_body>
</.card>|)

    assert html =~ "p-0"
    refute html =~ "p-4"
  end

  describe "composed card (body)" do
    test "without body nothing changes: no composed markup" do
      assigns = %{}
      html = rendered_to_string(~H|<.card title="T">x</.card>|)
      refute html =~ "data-lu-body"
      refute html =~ "--card-p"
    end

    test "each body treatment and variant is on the root" do
      assigns = %{}

      for body <- ~w(seamless divided separated inset flush) do
        assigns = %{body: body}

        html =
          rendered_to_string(~H|<.card body={@body} variant="muted"><:title>T</:title>x</.card>|)

        assert html =~ ~s(data-lu-body="#{body}")
        assert html =~ ~s(data-lu-variant="muted")
        assert html =~ "bg-(--card-band)"
      end

      inset = rendered_to_string(~H|<.card body="inset"><:title>T</:title>x</.card>|)
      # the tray look is gone: header border-b, footer border-t, a bare body
      refute inset =~ "rounded-[calc(var(--card-r)-var(--card-gap))]"
      refute inset =~ "bg-[linear-gradient(var(--card-band),var(--card-band))]"
      assert inset =~ "[&amp;&gt;[data-part=card-header]]:border-b"
      assert inset =~ "[&amp;&gt;[data-part=card-footer]]:border-t"

      outline = rendered_to_string(~H|<.card body="seamless" variant="outline">x</.card>|)
      assert outline =~ "border-line-strong bg-transparent"
      # other variants fall back to default
      glow = rendered_to_string(~H|<.card body="seamless" variant="glow">x</.card>|)
      assert glow =~ ~s(data-lu-variant="default")
    end

    test "sizes set the variables" do
      for {size, p} <- [{"xs", "12px"}, {"sm", "14px"}, {"md", "16px"}, {"lg", "24px"}] do
        assigns = %{size: size}
        html = rendered_to_string(~H|<.card body="divided" size={@size}>x</.card>|)
        assert html =~ "[--card-p:#{p}]"
      end
    end

    test "header: title, description, trailing and leading actions, footer" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.card body="inset">
          <:title>Profile</:title>
          <:description>Manage details</:description>
          <:actions placement="start"><.button size="sm">L</.button></:actions>
          <:actions><.button size="sm">R</.button></:actions>
          corpo
          <:footer>All changes saved</:footer>
        </.card>
        """)

      assert html =~ "Profile"
      assert html =~ "Manage details"
      assert html =~ ~s(data-part="card-subheading")
      assert html =~ "margin-inline-start"
      assert html =~ "margin-inline-end"
      assert html =~ "justify-between"
      assert html =~ "All changes saved"
      [head | _] = String.split(html, ~s(data-part="card-body"))
      assert head =~ "L" and head =~ "R"
      # the leading actions come before the heading, the trailing ones after it
      assert :binary.match(head, "margin-inline-start") < :binary.match(head, "Profile")
      assert :binary.match(head, "Profile") < :binary.match(head, "margin-inline-end")
    end

    test "bleed slot fills the body edge to edge and the footer keeps its padding" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.card body="inset">
          <:bleed><img src="/a.png" alt="" /></:bleed>
          <:footer>Forest path</:footer>
        </.card>
        """)

      assert html =~ ~s(data-part="card-bleed")
      assert html =~ "overflow-hidden"
      assert html =~ "<img"
      refute html =~ ~s(data-part="card-body")
      assert html =~ ~s(data-part="card-footer")
    end

    test "canvas with body keeps the parts as the content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.card body="separated" canvas>
          <.card_header>
            <.card_heading>H</.card_heading>
          </.card_header>
          <.card_body>B</.card_body>
          <.card_footer>F</.card_footer>
        </.card>
        """)

      assert html =~ ~s(data-lu-body="separated")
      assert html =~ ~s(data-part="card-header")
      assert html =~ ~s(data-part="card-body")
      assert html =~ ~s(data-part="card-footer")
    end

    test "links ignore body" do
      assigns = %{}
      html = rendered_to_string(~H|<.card href="/x" body="inset">x</.card>|)
      refute html =~ "data-lu-body"
    end
  end

  test "card_header and card_footer padded={false} are sub-sections" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card_header padded={false}>h</.card_header><.card_footer padded={false}>f</.card_footer>
      """)

    assert html =~ "p-0"
    refute html =~ "pl-3.5"
  end

  describe "composed card, canvas look (#54)" do
    defp unesc(rendered),
      do:
        rendered
        |> rendered_to_string()
        |> String.replace("&amp;&gt;", "&>")
        |> String.replace("&gt;", ">")

    test "inset no longer tightens at md: every size keeps the size paddings" do
      assigns = %{}
      md = unesc(~H|<.card body="inset" size="md"><:title>T</:title>x</.card>|)
      refute md =~ "[&>[data-part=card-header]]:pl-3"
      refute md =~ "[&>[data-part=card-footer]]:pt-[9px]"
      assert md =~ "[&>[data-part=card-header]]:px-(--card-p)"

      sm = unesc(~H|<.card body="inset" size="sm"><:title>T</:title>x</.card>|)
      assert sm =~ "[&>[data-part=card-header]]:px-(--card-p)"
      refute sm =~ "[&>[data-part=card-footer]]:pt-[9px]"

      divided = unesc(~H|<.card body="divided"><:title>T</:title>x</.card>|)
      assert divided =~ "[&>[data-part=card-header]]:px-(--card-p)"
    end

    test "flat: the panel without border or shadow" do
      assigns = %{}

      html =
        unesc(~H|<.card body="inset" variant="flat"><:title>T</:title>x</.card>|)

      assert html =~ ~s(data-lu-variant="flat")
      assert html =~ "bg-(--card-panel)"
      assert html =~ "border-transparent"
      assert html =~ "shadow-none"
      refute html =~ "p-[calc(var(--card-gap)-1px)]"
    end

    test "meta slot in the title" do
      assigns = %{}

      html =
        unesc(~H|<.card body="inset">
  <:title>T</:title><:meta>(3)</:meta>x
</.card>|)

      assert html =~ ~s(data-part="card-meta")
      assert html =~ "text-[13px] leading-none font-normal"
      assert html =~ "(3)"
    end
  end

  test "loading swaps the body for skeleton lines and keeps header and footer" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card title="Revenue" loading loading_rows={4}>
        corpo-real
        <:footer>rodape</:footer>
      </.card>
      """)

    refute html =~ "corpo-real"
    assert html =~ "Revenue"
    assert html =~ "rodape"
    assert html =~ ~s(aria-busy="true")
    assert length(String.split(html, ~s(data-part="skeleton"))) == 5
  end

  test "loading also applies to the composed card" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card body="inset" loading><:title>T</:title>corpo-real</.card>
      """)

    refute html =~ "corpo-real"
    assert html =~ ~s(data-part="skeleton")
  end
end
