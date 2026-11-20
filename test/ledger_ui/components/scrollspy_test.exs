defmodule LedgerUI.Components.ScrollspyTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Scrollspy

  defp norm(rendered) do
    rendered
    |> rendered_to_string()
    |> String.replace(~r/\s+/, " ")
    |> String.replace(~r/>\s+/, ">")
    |> String.replace(~r/\s+</, "<")
  end

  test "renders a nav of anchors with the hook" do
    assigns = %{}

    html =
      norm(~H"""
      <.scrollspy id="nav" offset={96}>
        <:item href="#profile">Profile</:item>
        <:item href="#security" style="--dl:1s">Security</:item>
      </.scrollspy>
      """)

    assert html =~ ~s(<nav id="nav")
    assert html =~ ~s(aria-label="On this page")
    assert html =~ ~s(phx-hook="LedgerUI.Scrollspy")
    assert html =~ ~s(data-offset="96")
    assert html =~ ~s(<a href="#profile">Profile</a>)
    assert html =~ ~s(style="--dl:1s")
  end

  test "default offset sends no attribute; label can be dropped" do
    assigns = %{}
    html = norm(~H|<.scrollspy id="n" label={nil}>
  <:item href="#a">A</:item>
</.scrollspy>|)
    refute html =~ "data-offset"
    refute html =~ "aria-label"
  end
end
