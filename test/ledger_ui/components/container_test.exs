defmodule LedgerUI.Components.ContainerTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Container

  test "fixed and fluid" do
    assigns = %{}
    assert rendered_to_string(~H|<.container_fixed>x</.container_fixed>|) =~ "max-width:1280px"

    fluid =
      rendered_to_string(~H|<.container_fluid class="c" style="color:red">x</.container_fluid>|)

    refute fluid =~ "max-width"
    assert fluid =~ "color:red"
    assert fluid =~ "c"
  end
end
