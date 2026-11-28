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

  # -- contrast of the text tokens (#117): WCAG 1.4.3, 4.5:1 -----------------------------------

  defp rules do
    lines = String.split(@css, "\n")
    find = fn prefix -> Enum.find(lines, &String.starts_with?(&1, prefix)) end

    %{
      light: find.(~s(:root, [data-theme="light"]{--lu-bg-page)),
      dark: find.(~s([data-theme="dark"]{--lu-bg-page)),
      crepusculo_light: find.(~s([data-palette="crepusculo"], [data-theme="light"][data-palette)),
      crepusculo_dark: find.(~s([data-theme="dark"][data-palette="crepusculo"]))
    }
  end

  defp token(rule, name) do
    [_, hex] = Regex.run(~r/--lu-#{name}:#([0-9a-f]{6})/, rule)
    for <<c::binary-size(2) <- hex>>, do: String.to_integer(c, 16) / 255
  end

  defp lum(rgb) do
    [r, g, b] =
      Enum.map(rgb, fn c ->
        if c <= 0.04045, do: c / 12.92, else: :math.pow((c + 0.055) / 1.055, 2.4)
      end)

    0.2126 * r + 0.7152 * g + 0.0722 * b
  end

  defp ratio(a, b) do
    {hi, lo} = Enum.max_by([lum(a), lum(b)], & &1) |> then(&{&1, Enum.min([lum(a), lum(b)])})
    (hi + 0.05) / (lo + 0.05)
  end

  test "--lu-subtle reaches 4.5:1 on page, panel, tray and sunken in the four sets" do
    for {set, rule} <- rules(), bg <- ~w(page panel tray sunken) do
      r = ratio(token(rule, "subtle"), token(rule, "bg-#{bg}"))
      assert r >= 4.5, "#{set} subtle on #{bg}: #{Float.round(r, 2)}"
    end
  end

  test "crepusculo light: pos, neg, warn, violet, lime reach 4.5:1 on the surfaces, on their -soft and under white text" do
    rule = rules().crepusculo_light

    for {name, soft} <- [
          pos: "pos-soft",
          neg: "neg-soft",
          warn: "warn-soft",
          violet: "violet-soft",
          lime: "lime-soft"
        ] do
      c = token(rule, to_string(name))

      for bg <- ["bg-page", "bg-panel", "bg-sunken", soft] do
        r = ratio(c, token(rule, bg))
        assert r >= 4.5, "#{name} on #{bg}: #{Float.round(r, 2)}"
      end

      assert ratio(c, [1.0, 1.0, 1.0]) >= 4.5
    end
  end

  test "the placeholder is the subtle token at full opacity (no alpha that lowers the contrast)" do
    assert @css =~
             "input::placeholder, textarea::placeholder { color: var(--lu-subtle); opacity: 1; }"
  end
end
