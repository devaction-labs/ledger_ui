defmodule LedgerUI.Components.DividerTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Divider

  test "plain horizontal is an hr" do
    assigns = %{}
    assert rendered_to_string(~H|<.divider />|) =~ ~s(class="lu-sep")
  end

  test "centred text between two lines" do
    assigns = %{}
    html = rendered_to_string(~H|<.divider>ou</.divider>|)
    assert html =~ ~s(class="lu-row")
    assert html =~ "gap:12px"
    assert length(String.split(html, "<hr")) == 3
    assert html =~ "text-transform:uppercase"
  end

  test "left text then one line" do
    assigns = %{}
    html = rendered_to_string(~H|<.divider align="left">Entrega</.divider>|)
    assert length(String.split(html, "<hr")) == 2
    assert html =~ ~r/Entrega<\/span>\s*<hr/
  end

  test "vertical" do
    assigns = %{}
    html = rendered_to_string(~H|<.divider orientation="vertical" />|)
    assert html =~ "width:1px;height:18px;background:var(--line)"
    html = rendered_to_string(~H|<.divider orientation="vertical" style="height:40px" />|)
    assert html =~ "height:40px"
    refute html =~ "18px"
  end
end
