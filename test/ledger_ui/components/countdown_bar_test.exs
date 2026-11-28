defmodule LedgerUI.Components.CountdownBarTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  import LedgerUI.DiffCase

  defp r(assigns), do: rendered_to_string(assigns)

  test "the fill is the fraction of the track" do
    assigns = %{}
    html = r(~H|<.countdown_bar value={0.7} />|)
    assert html =~ "width:70%"
    assert html =~ "bg-ink-2"
    assert html =~ "bg-line"
    assert r(~H|<.countdown_bar value={0.2} tone="warn" />|) =~ "bg-chart-3"
  end

  test "values out of range are clamped; junk is zero" do
    assigns = %{}
    assert r(~H|<.countdown_bar value={1.7} />|) =~ "width:100%"
    assert r(~H|<.countdown_bar value={-1} />|) =~ "width:0%"
    assert r(~H|<.countdown_bar value="x" />|) =~ "width:0%"
  end

  test "a11y: image with the translated summary" do
    assigns = %{}
    assert r(~H|<.countdown_bar value={0.7} />|) =~ ~s(role="img" aria-label="70% left")
    assert r(~H|<.countdown_bar value={0.7} locale="pt_BR" />|) =~ ~s(aria-label="70% restante")
    assert r(~H|<.countdown_bar value={0.7} label="20h" />|) =~ ~s(aria-label="20h")
  end

  defp t(assigns), do: ~H|<.countdown_bar value={@v} tone={@t} />|

  test "tracking: only the width travels when the value changes" do
    each_source(&t/1, %{v: 0.7, t: "ink"}, v: 0.4, t: "neg")
    p = patch(&t/1, %{v: 0.7, t: "ink"}, v: 0.4)
    refute p =~ "bg-line"
    refute p =~ "countdown-bar"
  end
end
