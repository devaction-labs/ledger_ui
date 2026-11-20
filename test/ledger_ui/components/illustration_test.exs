defmodule LedgerUI.Components.IllustrationTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Illustration

  test "presets" do
    assigns = %{}
    html = rendered_to_string(~H|<.illustration name="success" />|)
    assert html =~ ~s(class="lu-ill c-success")
    assert html =~ ~s(data-icon="check-circle")
    html = rendered_to_string(~H|<.illustration name="empty-inbox" />|)
    assert html =~ "c-neutral"
    assert html =~ ~s(data-icon="inbox")
  end

  test "tone and icon override" do
    assigns = %{}
    html = rendered_to_string(~H|<.illustration tone="primary" icon="star" />|)
    assert html =~ "c-primary"
    assert html =~ ~s(data-icon="star")
  end

  test "empty_box, summit and scene" do
    assigns = %{}
    assert rendered_to_string(~H|<.empty_box />|) =~ ~s(class="h-36")
    html = rendered_to_string(~H|<.summit id="s2" />|)
    assert html =~ ~s(id="s2-sky")
    assert html =~ "url(#s2-sky)"
    assert html =~ ~s(class="h-full w-full")

    for name <- ~w(voyage lighthouse balloons aurora) do
      assigns = %{name: name}
      html = rendered_to_string(~H|<.scene name={@name} position="xMidYMax" label="Foto" />|)
      assert html =~ ~s(data-scene="#{name}")
      assert html =~ ~s(preserveAspectRatio="xMidYMax slice")
      assert html =~ ~s(aria-label="Foto")
    end

    assigns = %{}
    assert rendered_to_string(~H|<.scene name="voyage" />|) =~ ~s(aria-hidden="true")
  end
end
