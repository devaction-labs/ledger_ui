defmodule LedgerUI.Components.ContainerTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Container

  test "fixed and fluid" do
    assigns = %{}

    assert rendered_to_string(~H|<.container_fixed>x</.container_fixed>|) =~
             "lu-container-fixed"

    fluid =
      rendered_to_string(~H|<.container_fluid class="c" style="color:red">x</.container_fluid>|)

    assert fluid =~ "lu-container-fluid"
    assert fluid =~ "color:red"
    assert fluid =~ "c"
  end

  test "preview draws the canvas diagram of a size" do
    assigns = %{}
    html = rendered_to_string(~H|<.container_fixed preview size="lg" style="flex:1" />|)
    assert html =~ ~s(class="lu-cont")
    assert html =~ ~s(<span style="width:64%">1024px</span>)
    assert html =~ "flex:1"

    html = rendered_to_string(~H|<.container_fluid preview label="x" width="100%" />|)
    assert html =~ ~s(<span style="width:100%">x</span>)
  end
end
