defmodule LedgerUI.Components.PaletteTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Palette

  test "swatches" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.palette
        cols={3}
        colors={[
          %{token: "--ink", name: "Ink", light: "#141514", dark: "#f2f3f2"},
          %{token: "--line", name: "Linha"}
        ]}
      />
      """)

    assert html =~ "--cols:3;gap:10px"
    assert html =~ ~s(class="lu-swc")
    assert html =~ "background:var(--ink)"
    assert html =~ "#141514 · #f2f3f2"
    assert html =~ "<span>--line</span>"
  end

  test "ramp labels the steps and flips the text colour" do
    assigns = %{}
    html = rendered_to_string(~H|<.palette variant="ramp" />|)
    assert html =~ ~s(class="lu-ramp")
    assert html =~ "background:var(--teal-50);color:var(--teal-900)"
    assert html =~ "background:var(--teal-500);color:#fff"
    assert length(String.split(html, "<div style=")) == 11
  end

  test "chips are staggered" do
    assigns = %{}
    html = rendered_to_string(~H|<.palette variant="chips" scale="teal" />|)
    assert html =~ "lu-palrow"
    assert html =~ "--dl:0.00s"
    assert html =~ "--dl:1.08s"
  end
end
