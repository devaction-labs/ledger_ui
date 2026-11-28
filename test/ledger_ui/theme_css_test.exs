defmodule LedgerUI.ThemeCssTest do
  # The theme's CSS (assets/css/ledger_ui.css): focus, forced-colors and reduced motion (#116).
  use ExUnit.Case, async: true

  @css File.read!(Path.expand("../../assets/css/ledger_ui.css", __DIR__))

  test "--lu-focus: Aurora (default) is a translucent ring; classic and crepusculo keep the opaque accent (#116)" do
    values = Regex.scan(~r/--lu-focus:([^;]+);/, @css) |> Enum.map(&List.last/1)

    assert length(values) == 6
    assert "rgba(59,52,64,.16)" in values and "rgba(242,239,244,.18)" in values

    for set <- [:classic_light, :classic_dark, :crepusculo_light, :crepusculo_dark] do
      assert Map.fetch!(decls(Map.fetch!(rules(), set)), "focus") == "var(--lu-accent-600)"
    end

    for set <- [:light, :dark] do
      refute Map.fetch!(decls(Map.fetch!(rules(), set)), "focus") =~ "var("
    end
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
      light_derived: find.(~s(:root, [data-theme="light"]{color-scheme:light;)),
      dark_derived: find.(~s([data-theme="dark"]{color-scheme:dark;)),
      crepusculo_light: find.(~s([data-palette="crepusculo"], [data-theme="light"][data-palette)),
      crepusculo_dark: find.(~s([data-theme="dark"][data-palette="crepusculo"])),
      classic_light: find.(~s([data-palette="classic"], [data-theme="light"][data-palette)),
      classic_dark: find.(~s([data-theme="dark"][data-palette="classic"])),
      classic_light_inputs: find.(~s([data-palette="classic"], [data-theme=light][data-palette)),
      classic_dark_inputs: find.(~s([data-theme=dark][data-palette="classic"]))
    }
  end

  # `--lu-x:v;` declarations of a one-line rule, without the prefix (--color-* inputs keep their name)
  defp decls(rule) do
    [_, body] = Regex.run(~r/\{(.*)\}\s*$/, rule)

    for [_, k, v] <- Regex.scan(~r/--(?:lu-)?([a-z0-9-]+):([^;]+);/, body), into: %{} do
      {k, String.trim(v)}
    end
  end

  # theme inputs (--color-accent, --color-gray-N), `@theme` for light, `@layer theme` for dark
  defp inputs(:light), do: input_pairs(Regex.run(~r/@theme \{(.*?)\n\}/s, @css))

  defp inputs(:dark),
    do:
      input_pairs(Regex.run(~r/\[data-theme=dark\] \{(.*?)\}/s, @css))
      |> then(&Map.merge(inputs(:light), &1))

  defp input_pairs([_, body]) do
    for [_, k, v] <- Regex.scan(~r/--color-([a-z0-9-]+):\s*([^;]+);/, body), into: %{}, do: {k, v}
  end

  # a token of a set (:default | :classic | :crepusculo) and theme, as {r, g, b} 0..255 (hex or oklch relative to the inputs)
  defp resolve(set, th, name) do
    r = rules()

    {base, inp} =
      case {set, th} do
        {:default, :light} ->
          {Map.merge(decls(r.light), decls(r.light_derived)), inputs(:light)}

        {:default, :dark} ->
          {Map.merge(decls(r.dark), decls(r.dark_derived)), inputs(:dark)}

        {:crepusculo, t} ->
          {Map.merge(resolve_base(t), decls(r[:"crepusculo_#{t}"])), inputs(t)}

        {:classic, t} ->
          i =
            for {k, v} <- decls(r[:"classic_#{t}_inputs"]),
                into: %{},
                do: {String.replace_prefix(k, "color-", ""), v}

          {Map.merge(resolve_base(t), decls(r[:"classic_#{t}"])), Map.merge(inputs(t), i)}
      end

    eval(Map.fetch!(base, name), base, inp)
  end

  defp resolve_base(:light), do: Map.merge(decls(rules().light), decls(rules().light_derived))
  defp resolve_base(:dark), do: Map.merge(decls(rules().dark), decls(rules().dark_derived))

  defp eval("#" <> hex, _, _), do: hex_rgb(hex)

  defp eval("var(--lu-" <> n, base, inp),
    do: eval(Map.fetch!(base, String.trim_trailing(n, ")")), base, inp)

  defp eval("var(--color-" <> n, base, inp),
    do: eval(Map.fetch!(inp, String.trim_trailing(n, ")")), base, inp)

  defp eval("oklch(from var(--color-" <> rest, base, inp) do
    [n, l, c, h] =
      Regex.run(
        ~r/^([a-z0-9-]+)\) ([\d.]+) (c|0|calc\(c \* [\d.]+\)) (h|calc\(h [+-] [\d.]+\))\)$/,
        rest,
        capture: :all_but_first
      )

    {l0, c0, h0} = eval_lch(Map.fetch!(inp, n), base, inp)

    k =
      case Regex.run(~r/calc\(c \* ([\d.]+)\)/, c) do
        [_, k] -> c0 * num(k)
        nil -> if c == "0", do: 0.0, else: c0
      end

    hh =
      case Regex.run(~r/calc\(h ([+-]) ([\d.]+)\)/, h) do
        [_, "+", d] -> h0 + num(d)
        [_, "-", d] -> h0 - num(d)
        nil -> h0
      end

    _ = l0
    oklch_rgb(num(l), k, hh)
  end

  defp eval_lch("oklch(" <> rest, _, _) do
    [l, c, h] = rest |> String.trim_trailing(")") |> String.split(" ") |> Enum.map(&num/1)
    {l, c, h}
  end

  defp eval_lch(v, base, inp) do
    {r, g, b} = eval(v, base, inp)
    rgb_oklch({r, g, b})
  end

  defp num(s),
    do: s |> then(&if(String.contains?(&1, "."), do: &1, else: &1 <> ".0")) |> String.to_float()

  defp hex_rgb(<<r::binary-2, g::binary-2, b::binary-2>>),
    do: {String.to_integer(r, 16), String.to_integer(g, 16), String.to_integer(b, 16)}

  defp lin(c), do: if(c <= 0.04045, do: c / 12.92, else: :math.pow((c + 0.055) / 1.055, 2.4))
  defp gam(c), do: if(c <= 0.0031308, do: 12.92 * c, else: 1.055 * :math.pow(c, 1 / 2.4) - 0.055)

  defp rgb_oklch({r, g, b}) do
    {r, g, b} = {lin(r / 255), lin(g / 255), lin(b / 255)}
    l = :math.pow(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b, 1 / 3)
    m = :math.pow(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b, 1 / 3)
    s = :math.pow(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b, 1 / 3)
    big_l = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
    a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
    bb = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
    h = :math.atan2(bb, a) * 180 / :math.pi()
    {big_l, :math.sqrt(a * a + bb * bb), if(h < 0, do: h + 360, else: h)}
  end

  defp oklch_rgb(l, c, h) do
    a = c * :math.cos(h * :math.pi() / 180)
    b = c * :math.sin(h * :math.pi() / 180)
    l_ = :math.pow(l + 0.3963377774 * a + 0.2158037573 * b, 3)
    m_ = :math.pow(l - 0.1055613458 * a - 0.0638541728 * b, 3)
    s_ = :math.pow(l - 0.0894841775 * a - 1.2914855480 * b, 3)
    r = 4.0767416621 * l_ - 3.3077115913 * m_ + 0.2309699292 * s_
    g = -1.2684380046 * l_ + 2.6097574011 * m_ - 0.3413193965 * s_
    bl = -0.0041960863 * l_ - 0.7034186147 * m_ + 1.7076147010 * s_
    {to8(r), to8(g), to8(bl)}
  end

  defp to8(c), do: (gam(max(0.0, min(1.0, c))) * 255) |> round() |> max(0) |> min(255)

  defp token(set, th, name) do
    {r, g, b} = resolve(set, th, name)
    [r / 255, g / 255, b / 255]
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

  test "classic and crepusculo: --lu-subtle reaches 4.5:1 on page, panel, tray and sunken (#117)" do
    for set <- [:classic, :crepusculo], th <- [:light, :dark], bg <- ~w(page panel tray sunken) do
      r = ratio(token(set, th, "subtle"), token(set, th, "bg-#{bg}"))
      assert r >= 4.5, "#{set} #{th} subtle on #{bg}: #{Float.round(r, 2)}"
    end
  end

  test "crepusculo light: pos, neg, warn, violet, lime reach 4.5:1 on the surfaces, on their -soft and under white text" do
    for {name, soft} <- [
          pos: "pos-soft",
          neg: "neg-soft",
          warn: "warn-soft",
          violet: "violet-soft",
          lime: "lime-soft"
        ] do
      c = token(:crepusculo, :light, to_string(name))

      for bg <- ["bg-page", "bg-panel", "bg-sunken", soft] do
        r = ratio(c, token(:crepusculo, :light, bg))
        assert r >= 4.5, "#{name} on #{bg}: #{Float.round(r, 2)}"
      end

      assert ratio(c, [1.0, 1.0, 1.0]) >= 4.5
    end
  end

  # -- Aurora (default palette): the exact values of the spec ------------------------------------

  @aurora %{
    "bg-page" => {"#ffffff", "#121113"},
    "bg-shell" => {"#f4f1f5", "#121113"},
    "bg-tray" => {"#f6f4f7", "#1a191c"},
    "bg-panel" => {"#ffffff", "#1d1c1f"},
    "bg-sunken" => {"#f3f1f4", "#232226"},
    "bg-hover" => {"#f3f1f4", "#28272b"},
    "bg-selected" => {"#ece8ee", "#2e2d32"},
    "line" => {"#ece9ee", "#2b2a2e"},
    "line-strong" => {"#e1dde4", "#3a383e"},
    "ink" => {"#2a2530", "#f2eff4"},
    "ink-2" => {"#4a4450", "#cdc8d1"},
    "muted" => {"#8a8490", "#8d8792"},
    "subtle" => {"#b0aab4", "#6a646f"},
    "inverse" => {"#3b3440", "#f2eff4"},
    "on-inverse" => {"#ffffff", "#1d1c1f"},
    "accent-50" => {"#e6f9f1", "#10261f"},
    "accent-100" => {"#c9f1e1", "#133328"},
    "accent-200" => {"#98e4c8", "#17473a"},
    "accent-300" => {"#5fd3ab", "#1e6b55"},
    "accent-400" => {"#2fc493", "#26a079"},
    "accent-500" => {"#20b383", "#2fd6a0"},
    "accent-600" => {"#0b8a63", "#5fe3b8"},
    "accent-700" => {"#08704f", "#8beccb"},
    "accent-800" => {"#075a40", "#b7f3df"},
    "accent-900" => {"#054532", "#dcf9ef"},
    "on-accent" => {"#ffffff", "#0b1f18"},
    "pos" => {"#0b8a63", "#5fe3b8"},
    "pos-soft" => {"#d8f6ea", "#13281f"},
    "warn" => {"#8a6500", "#f4cd5e"},
    "warn-soft" => {"#fbf0c6", "#2f2812"},
    "neg" => {"#b8204e", "#ff8fae"},
    "neg-soft" => {"#fde3ea", "#33171f"},
    "info" => {"#3b6fd8", "#8fb0f5"},
    "info-soft" => {"#e6eefc", "#16213a"},
    "violet" => {"#7b5cd6", "#b6a3f5"},
    "violet-soft" => {"#efeafc", "#231d3a"},
    "lime" => {"#0b8a63", "#5fe3b8"},
    "lime-soft" => {"#d8f6ea", "#13281f"},
    "highlight" => {"#f7d53f", "#f7d53f"},
    "highlight-ink" => {"#3b3216", "#3b3216"},
    "tip" => {"#141215", "#2a282d"},
    "chart-1" => {"#20c08f", "#2fd6a0"},
    "chart-2" => {"#3b3440", "#f2eff4"},
    "chart-3" => {"#f7d53f", "#f7d53f"},
    "chart-4" => {"#ef4f7d", "#ff6b93"},
    "chart-5" => {"#b9a6e8", "#8a76c9"},
    "chart-grid" => {"#efecf0", "#28272b"},
    "chart-ghost" => {"#c9c3cd", "#4c4851"}
  }

  test "Aurora: every color token of the spec resolves to its exact hex, light and dark" do
    for {name, {light, dark}} <- @aurora, {th, "#" <> hex} <- [light: light, dark: dark] do
      assert resolve(:default, th, name) == hex_rgb(hex), "#{th} #{name} should be ##{hex}"
    end
  end

  test "Aurora: translucent tokens, app background, shadows and radii of the spec" do
    light = decls(rules().light)
    dark = decls(rules().dark)

    assert {light["bg-overlay"], dark["bg-overlay"]} == {"rgba(42,37,48,.32)", "rgba(0,0,0,.6)"}
    assert {light["focus"], dark["focus"]} == {"rgba(59,52,64,.16)", "rgba(242,239,244,.18)"}
    assert light["bg-app"] =~ "radial-gradient(1200px 800px at 0% 0%,#efe3f6 0%,transparent 60%)"

    assert String.ends_with?(light["bg-app"], ",#f4f1f5")

    assert dark["bg-app"] =~
             "radial-gradient(1000px 700px at 0% 100%,rgba(70,160,90,.15) 0%,transparent 60%)"

    assert dark["bg-app"] =~ "rgba(150,90,170,.10) 0%,transparent 60%),#121113"

    assert light["shadow-xs"] == "0 1px 2px rgba(40,30,50,.05)"
    assert light["shadow-sm"] == "0 1px 3px rgba(40,30,50,.07)"
    assert light["shadow-md"] == "0 1px 2px rgba(40,30,50,.06),0 12px 32px rgba(40,30,50,.12)"
    assert light["shadow-lg"] == "0 2px 6px rgba(40,30,50,.06),0 28px 64px rgba(40,30,50,.18)"
    assert light["shadow-popover"] == light["shadow-md"] and light["shadow-btn"] == "none"
    assert dark["shadow-xs"] == "none"
    assert dark["shadow-sm"] == "0 1px 3px rgba(0,0,0,.4)"
    assert dark["shadow-md"] == "0 0 0 1px rgba(255,255,255,.05),0 16px 40px rgba(0,0,0,.5)"
    assert dark["shadow-lg"] == "0 0 0 1px rgba(255,255,255,.05),0 28px 70px rgba(0,0,0,.6)"
    assert dark["shadow-popover"] == dark["shadow-md"] and dark["shadow-btn"] == "none"

    for {k, v} <- [xs: 6, sm: 8, md: 12, lg: 16, xl: 20, "2xl": 24] do
      assert @css =~ "--radius-#{k}: #{v}px;"
    end
  end

  test "utilities bg-app, bg-highlight, text-highlight-ink and bg-tip exist" do
    assert @css =~ "@utility bg-app { background: var(--lu-bg-app); }"
    assert @css =~ "--color-highlight: var(--lu-highlight);"
    assert @css =~ "--color-highlight-ink: var(--lu-highlight-ink);"
    assert @css =~ "--color-tip: var(--lu-tip);"

    # bg-app is a background, not a color: no --color-app (bg-app would be a color utility otherwise)
    refute @css =~ "--color-app:"
  end

  test "classic palette keeps the pre-Aurora values (teal brand, opaque focus, warm neutrals, button shadow)" do
    assert resolve(:classic, :light, "accent-600") == hex_rgb("0b8572")
    assert resolve(:classic, :dark, "accent-600") == hex_rgb("4fc0ab")
    assert resolve(:classic, :light, "pos") == hex_rgb("11773e")
    assert elem(resolve(:classic, :light, "ink"), 0) in 19..21
    assert decls(rules().classic_light)["shadow-btn"] =~ "0 6px 14px rgba(20,21,20,0.22)"
    assert decls(rules().classic_dark)["shadow-btn"] =~ "0 6px 14px rgba(0,0,0,0.5)"
  end

  test "the placeholder is the subtle token at full opacity (no alpha that lowers the contrast)" do
    assert @css =~
             "input::placeholder, textarea::placeholder { color: var(--lu-subtle); opacity: 1; }"
  end
end
