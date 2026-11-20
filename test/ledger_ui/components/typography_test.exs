defmodule LedgerUI.Components.TypographyTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Typography

  test "heading levels, display, title" do
    assigns = %{}
    assert rendered_to_string(~H|<.heading level={1}>A</.heading>|) =~ "<h1"
    assert rendered_to_string(~H|<.heading level={1}>A</.heading>|) =~ "text-[40px]"
    html = rendered_to_string(~H|<.heading display={2}>A</.heading>|)
    assert html =~ "<h1"
    assert html =~ "text-[48px]"
    assert html =~ "font-semibold"
    assert html =~ "tracking-[-.03em]"
    html = rendered_to_string(~H|<.heading level={2} size="title">A</.heading>|)
    assert html =~ "<h2"
    assert html =~ "text-[34px] leading-10"
    assert html =~ "text-ink"
    html = rendered_to_string(~H|<.heading level={3} weight="light" color="info">A</.heading>|)
    assert html =~ "font-light"
    assert html =~ "text-info"
    refute html =~ "style="
  end

  test "text defaults to a bare paragraph" do
    assigns = %{}
    html = rendered_to_string(~H|<.text>as p</.text>|)
    assert html =~ "<p"
    refute html =~ "style="
    refute html =~ "class="
  end

  test "text size, weight, colour, mono, decoration" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.text as="span" size="lg" weight="semibold" color="faint" mono decoration="underline" style="x:y">
  t
</.text>|
      )

    assert html =~ "<span"
    assert html =~ "text-[18px]"
    assert html =~ "font-semibold"
    assert html =~ "text-subtle"
    assert html =~ "font-mono"
    assert html =~ "underline"
    assert html =~ ~s(style="x:y")
    refute html =~ ~r/class="(?:[^"]*\s)?lu-/
  end

  test "text gradient is bold text clipped to the gradient, whatever the colour" do
    assigns = %{}
    html = rendered_to_string(~H|<.text gradient="sky-blue" color="error">t</.text>|)
    assert html =~ "bg-[linear-gradient(90deg,#0ea5e9,#2563eb)]"
    assert html =~ "text-transparent"
    assert html =~ "font-bold"
    refute html =~ "text-neg"
    html = rendered_to_string(~H|<.text gradient="sky-blue" weight="medium">t</.text>|)
    assert html =~ "font-medium"
    refute html =~ "font-bold"
  end

  test "colours are theme tokens" do
    for {color, utility} <- [
          {"primary", "text-accent-content"},
          {"secondary", "text-violet"},
          {"success", "text-pos"},
          {"warning", "text-warn"},
          {"error", "text-neg"},
          {"neutral", "text-ink-2"},
          {"muted", "text-muted"}
        ] do
      assigns = %{color: color}
      assert rendered_to_string(~H|<.text color={@color}>t</.text>|) =~ utility
    end
  end

  test "typography is text" do
    assigns = %{}
    assert rendered_to_string(~H|<.typography size="xs">a</.typography>|) =~ "text-[12px]"
  end

  test "text_link" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.text_link href="#" decoration_color="info" decoration_style="wavy">T</.text_link>|
      )

    assert html =~ ~s(<a href="#")
    assert html =~ "underline"
    assert html =~ "decoration-wavy"
    assert html =~ "decoration-info"
    assert html =~ "underline-offset-[3px]"
    assert html =~ ">T</a>"
  end

  test "inline_code and kbd" do
    assigns = %{}
    html = rendered_to_string(~H|<.inline_code>x</.inline_code>|)
    assert html =~ "<code"
    assert html =~ "font-mono"
    assert html =~ "bg-sunken"
    assert html =~ ">x</code>"
    kbd = rendered_to_string(~H|<.kbd>K</.kbd>|)
    assert kbd =~ "border-line-strong"
    assert kbd =~ "bg-panel"
    assert kbd =~ "font-mono"
    assert kbd =~ ">K</kbd>"
    flat = rendered_to_string(~H|<.kbd variant="flat">K</.kbd>|)
    assert flat =~ "bg-sunken"
    assert flat =~ "shadow-none"
    refute flat =~ "style="
    dark = rendered_to_string(~H|<.kbd variant="dark">K</.kbd>|)
    assert dark =~ "bg-[rgba(255,255,255,.12)]"
    assert dark =~ "text-inherit"
    refute dark =~ ~r/class="(?:[^"]*\s)?lu-/
  end
end
