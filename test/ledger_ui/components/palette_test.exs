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

    assert html =~ ~s(style="--cols:3")
    assert html =~ "grid-cols-[repeat(var(--cols),minmax(0,1fr))]"
    assert html =~ ~s(data-part="palette-swatch")
    # the design's token name and the kit's read the same variable
    assert html =~ "background:var(--lu-ink)"
    assert html =~ "#141514 · #f2f3f2"
    assert html =~ ~r/data-part="palette-token"[^>]*>--line<\/span>/
    refute html =~ ~r/class="(?:[^"]*\s)?lu-/
  end

  test "token names: the kit's own prefix is kept" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.palette colors={[%{token: "--lu-accent-500", name: "A"}, %{token: "--bg-tray", name: "B"}]} />|
      )

    assert html =~ "background:var(--lu-accent-500)"
    assert html =~ "background:var(--lu-bg-tray)"
  end

  test "ramp labels the steps with the accent scale and flips the text colour" do
    assigns = %{}
    html = rendered_to_string(~H|<.palette variant="ramp" />|)
    assert html =~ "bg-accent-50"
    assert html =~ "text-accent-900"
    assert html =~ "bg-accent-500"
    assert html =~ "text-white"
    refute html =~ "teal"
    assert length(String.split(html, ~s(data-part="palette-step"))) == 11
  end

  test "ramp of the gray scale and a custom set of steps" do
    assigns = %{}
    html = rendered_to_string(~H|<.palette variant="ramp" scale="gray" steps={~w(50 950)} />|)
    assert html =~ "bg-gray-50"
    assert html =~ "bg-gray-950"
    assert length(String.split(html, ~s(data-part="palette-step"))) == 3
  end

  test "chips are staggered" do
    assigns = %{}
    html = rendered_to_string(~H|<.palette variant="chips" />|)
    assert html =~ "animate-[mo-stg_7s_cubic-bezier(.2,.8,.2,1)_infinite]"
    assert html =~ "--dl:0.00s"
    assert html =~ "--dl:1.08s"
    assert html =~ "bg-accent-900"
  end
end
