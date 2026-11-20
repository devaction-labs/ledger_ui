defmodule LedgerUI.Components.TypographyTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Typography

  test "heading levels, display, title" do
    assigns = %{}
    assert rendered_to_string(~H|<.heading level={1}>A</.heading>|) =~ "<h1"
    assert rendered_to_string(~H|<.heading level={1}>A</.heading>|) =~ "font-size:40px"
    assert rendered_to_string(~H|<.heading display={2}>A</.heading>|) =~ "<h1"
    assert rendered_to_string(~H|<.heading display={2}>A</.heading>|) =~ "font-weight:600"
    html = rendered_to_string(~H|<.heading level={2} size="title">A</.heading>|)
    assert html =~ "<h2"
    assert html =~ "font-size:34px"
    assert html =~ "color:var(--ink)"
    html = rendered_to_string(~H|<.heading level={3} weight="light" color="info">A</.heading>|)
    assert html =~ "font-weight:300"
    assert html =~ "color:var(--info)"
  end

  test "text defaults to a bare paragraph" do
    assigns = %{}
    html = rendered_to_string(~H|<.text>as p</.text>|)
    assert html =~ "<p"
    refute html =~ "style="
    refute html =~ "class="
  end

  test "text size, weight, colour, mono, gradient, decoration" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.text as="span" size="lg" weight="semibold" color="faint" mono decoration="underline" style="x:y">
  t
</.text>|
      )

    assert html =~ "<span"
    assert html =~ ~s(class="mono")

    assert html =~
             ~s|style="font-size:18px;font-weight:600;color:var(--subtle);text-decoration:underline;x:y"|

    html = rendered_to_string(~H|<.text gradient="sky-blue">t</.text>|)
    assert html =~ ~s(class="lu-ty-grad g-sky-blue")
  end

  test "text_link" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.text_link href="#" decoration_color="info" decoration_style="wavy">T</.text_link>|
      )

    assert html =~ ~s(<a href="#")
    assert html =~ "text-decoration:underline wavy"
    assert html =~ "text-decoration-color:var(--info)"
  end

  test "inline_code and kbd" do
    assigns = %{}
    assert rendered_to_string(~H|<.inline_code>x</.inline_code>|) =~ "<code"
    assert rendered_to_string(~H|<.kbd>K</.kbd>|) =~ ~s(class="lu-kbd">K</kbd>)
    flat = rendered_to_string(~H|<.kbd variant="flat">K</.kbd>|)
    assert flat =~ "box-shadow:none"
    assert rendered_to_string(~H|<.kbd variant="dark">K</.kbd>|) =~ ~s(class="lu-kbd dark")
  end
end
