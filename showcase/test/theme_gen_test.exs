defmodule LedgerShowcase.ThemeGenTest do
  use ExUnit.Case, async: true

  alias LedgerShowcase.ThemeGen

  # `oracle`: the output of the vitrine's own `tgCode()`/`tgStyle()` (vitrine/temas.js of the design data, run in node)
  # for the same choices.
  @oracle "fixtures/theme_gen_oracle.json"
          |> Path.expand(__DIR__)
          |> File.read!()
          |> Jason.decode!()

  test "code/2 equals tgCode(): default" do
    assert ThemeGen.code("base", "ledger") == @oracle["default"]
    assert @oracle["default"] =~ "Tema padrão do Ledger"
  end

  test "code/2 equals tgCode(): fuchsia + slate" do
    assert ThemeGen.code("fuchsia", "slate") == @oracle["both"]
  end

  test "code/2 equals tgCode(): accent only" do
    assert ThemeGen.code("amber", "ledger") == @oracle["accent"]
    refute ThemeGen.code("amber", "ledger") =~ "--color-gray"
  end

  test "code/2 equals tgCode(): gray only" do
    assert ThemeGen.code("base", "zinc") == @oracle["gray"]
    refute ThemeGen.code("base", "zinc") =~ "@layer theme"
  end

  test "style/3 equals tgStyle() in dark" do
    assert ThemeGen.style("fuchsia", "slate", "dark") == @oracle["style_dark"]
  end

  test "style/3 of the Ledger default carries the base accent and the gray scale" do
    style = ThemeGen.style("base", "ledger", "light")
    assert style =~ "--color-accent:#15786b;"
    assert style =~ "--color-gray-50:oklch(0.985 0.005 142.603);"
    refute style =~ "--teal"
  end

  test "data: 17 accents and 9 grays" do
    assert length(ThemeGen.accents()) == 17
    assert ThemeGen.gray_ids() == ~w(slate gray zinc neutral stone mauve olive mist taupe)
  end
end
