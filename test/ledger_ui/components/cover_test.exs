defmodule LedgerUI.Components.CoverTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Cover

  test "band height and tone" do
    assigns = %{}
    html = rendered_to_string(~H|<.cover height={110} />|)
    assert html =~ "height:110px"
    assert html =~ "var(--teal-300)"
    assert rendered_to_string(~H|<.cover tone="neutral" />|) =~ "var(--bg-selected)"
  end

  test "title on the band" do
    assigns = %{}
    assert rendered_to_string(~H|<.cover title="Sertão" />|) =~ "Sertão"
  end

  test "avatar overlaps the band, title beside it" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.cover title="Sertão" subtitle="Cliente desde 2021">
        <:avatar><span id="av">A</span></:avatar>
      </.cover>
      """)

    assert html =~ ~s(id="av")
    assert html =~ "Cliente desde 2021"
    assert html =~ "margin-top:-32px"
  end

  test "src covers the band" do
    assigns = %{}
    assert rendered_to_string(~H|<.cover src="/x.jpg" />|) =~ ~s(src="/x.jpg")
  end
end
