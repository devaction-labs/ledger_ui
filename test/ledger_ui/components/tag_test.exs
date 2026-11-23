defmodule LedgerUI.Components.TagTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Tag

  test "a button by default, a link with href, a span when static" do
    assigns = %{}
    assert rendered_to_string(~H|<.tag>x</.tag>|) =~ ~s(<button)
    assert rendered_to_string(~H|<.tag href="/x">x</.tag>|) =~ ~s(<a)
    assert rendered_to_string(~H|<.tag static>x</.tag>|) =~ "<span"
    assert rendered_to_string(~H|<.tag as="span">x</.tag>|) =~ "<span"
  end

  test "classes for color, variant and shape" do
    assigns = %{}
    html = rendered_to_string(~H|<.tag color="info" variant="bordered" shape="pill">x</.tag>|)
    assert html =~ "[--c:var(--lu-info)]"
    assert html =~ "border-[color-mix(in_oklab,var(--c)_35%,transparent)]"
    assert html =~ "rounded-full"
  end

  test "active sets aria-pressed" do
    assigns = %{}
    html = rendered_to_string(~H|<.tag active>x</.tag>|)
    assert html =~ ~s(aria-pressed="true")
  end

  test "tint paints its own colour and drops the colour class" do
    assigns = %{}
    html = rendered_to_string(~H|<.tag tint="#0d8f91">VIP</.tag>|)
    assert html =~ "color:#0d8f91"
    refute html =~ "[--c:"
  end

  test "count and removable" do
    assigns = %{}
    html = rendered_to_string(~H|<.tag count={3} removable>x</.tag>|)
    assert html =~ ~s(data-part="tag-count")
    assert html =~ ">3</span>"
    assert html =~ ~s(data-part="tag-remove")
  end

  test "canvas tag with swatch and remove button" do
    assigns = %{}
    html = rendered_to_string(~H|<.tag canvas swatch="red" removable>Pro</.tag>|)
    assert html =~ "h-[26px]"
    assert html =~ "border-line-strong bg-panel"
    assert html =~ "background:red"
    assert html =~ "data-lu-remove"
  end

  test "tag_group" do
    assigns = %{}
    assert rendered_to_string(~H|<.tag_group>
  <.tag>a</.tag>
</.tag_group>|) =~ "inline-flex flex-wrap"
  end

  describe "canvas tag (#60)" do
    test "md default is unchanged, sm is 24px, never wraps" do
      assigns = %{}
      md = rendered_to_string(~H|<.tag canvas>A</.tag>|)
      assert md =~ "h-[26px] pr-1.5 pl-[9px] text-[13px]"
      assert md =~ "whitespace-nowrap"
      assert md =~ "text-ink-2"
      refute md =~ "border-dashed"

      sm = rendered_to_string(~H|<.tag canvas size="sm">A</.tag>|)
      assert sm =~ "h-6 px-2 text-[12.5px]"
      refute sm =~ "h-[26px]"
    end

    test "label and value" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.tag canvas label="Period:" value="jan/2025" removable />|)

      assert html =~ ~s(<span data-part="tag-label" class="text-muted">Period:</span>)
      assert html =~ ~s(<b data-part="tag-value" class="font-medium text-ink">jan/2025</b>)
      assert html =~ ~s(data-part="tag-remove")
    end

    test "dashed and acc tone" do
      assigns = %{}
      html = rendered_to_string(~H|<.tag canvas dashed tone="acc">Client</.tag>|)
      assert html =~ "border-dashed"
      assert html =~ "text-accent-content"
      refute html =~ "text-ink-2"
    end

    test "value stays an HTML attribute on a plain tag" do
      assigns = %{}
      html = rendered_to_string(~H|<.tag value="x">A</.tag>|)
      assert html =~ ~s(value="x")
    end
  end
end
