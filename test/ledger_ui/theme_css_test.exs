defmodule LedgerUI.ThemeCssTest do
  # The theme's CSS (assets/css/ledger_ui.css): focus, forced-colors and reduced motion (#116).
  use ExUnit.Case, async: true

  @css File.read!(Path.expand("../../assets/css/ledger_ui.css", __DIR__))

  test "--lu-focus is an opaque accent in every theme and palette (no rgba/alpha ring)" do
    values = Regex.scan(~r/--lu-focus:([^;]+);/, @css) |> Enum.map(&List.last/1)

    assert length(values) == 6
    assert Enum.all?(values, &(&1 == "var(--lu-accent-600)"))
  end

  test "forced-colors: the focus outline, the switch, the segmented item and the checkbox have a state" do
    [_, block] = Regex.run(~r/@media \(forced-colors: active\) \{(.*?)\n\}\n/s, @css)

    assert block =~ ":focus-visible { outline: 2px solid Highlight"
    assert block =~ ~s([data-part="switch"][aria-checked="true"] [data-part="switch-track"])
    assert block =~ ~s([data-part="segmented-item"][aria-pressed="true"])
    assert block =~ ~s([data-part="checkbox-input"]:checked)
    # outside @layer: it has to win against `focus-visible:outline-none` (utilities layer)
    [_, base] = Regex.run(~r/@layer base \{(.*?)\n\}\n/s, @css)
    refute base =~ "@media (forced-colors"
  end

  test "prefers-reduced-motion in @layer base, with the spinner left out" do
    [_, base] = Regex.run(~r/@layer base \{(.*?)\n\}\n/s, @css)

    assert base =~ "@media (prefers-reduced-motion: reduce)"
    assert base =~ "animation-iteration-count: 1 !important"
    assert base =~ ~s([data-part="spinner"])
    assert base =~ ~s([data-part="button-auto-spinner"])
  end
end
