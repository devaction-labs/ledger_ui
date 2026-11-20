defmodule LedgerUI.Components.DividerTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Divider

  test "plain horizontal is a 1px hr in the line colour" do
    assigns = %{}
    html = rendered_to_string(~H|<.divider />|)
    assert html =~ "<hr"
    assert html =~ "h-px"
    assert html =~ "bg-line"
  end

  test "centred text between two lines" do
    assigns = %{}
    html = rendered_to_string(~H|<.divider>ou</.divider>|)
    assert html =~ "flex flex-wrap items-center gap-3"
    assert length(String.split(html, "<hr")) == 3
    assert html =~ "uppercase"
    assert html =~ "text-muted"
  end

  test "label as an attribute" do
    assigns = %{}
    assert rendered_to_string(~H|<.divider label="ou" />|) =~ ~r/>ou<\/span>/
  end

  test "left text then one line" do
    assigns = %{}
    html = rendered_to_string(~H|<.divider align="left">Entrega</.divider>|)
    assert length(String.split(html, "<hr")) == 2
    assert html =~ ~r/Entrega<\/span><hr/
  end

  test "vertical" do
    assigns = %{}
    html = rendered_to_string(~H|<.divider orientation="vertical" />|)
    assert html =~ "w-px"
    assert html =~ "h-[18px]"
    assert html =~ ~s(role="separator")
    assert html =~ ~s(aria-orientation="vertical")

    html = rendered_to_string(~H|<.divider orientation="vertical" style="height:40px" />|)
    assert html =~ "height:40px"
    refute html =~ "h-[18px]"

    html = rendered_to_string(~H|<.divider orientation="vertical" class="h-10" />|)
    refute html =~ "h-[18px]"
  end

  test "vertical with text" do
    assigns = %{}
    html = rendered_to_string(~H|<.divider orientation="vertical">ou</.divider>|)
    assert html =~ "flex-col"
    assert length(String.split(html, ~s(data-part="divider-line"))) == 3
  end

  test "no legacy class" do
    assigns = %{}

    for html <- [
          rendered_to_string(~H|<.divider />|),
          rendered_to_string(~H|<.divider>x</.divider>|),
          rendered_to_string(~H|<.divider orientation="vertical" />|)
        ] do
      refute html =~ ~r/class="(?:[^"]*\s)?lu-/
    end
  end
end
