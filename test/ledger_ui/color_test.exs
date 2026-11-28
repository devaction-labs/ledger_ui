defmodule LedgerUI.ColorTest do
  # #102: `config :ledger_ui, :color_aliases` is read at compile time. The test config has none,
  # so the default behaviour (no alias, same HTML) is what runs here; the resolution itself is
  # exercised through `resolve/2`.
  use ExUnit.Case, async: true

  alias LedgerUI.Color

  test "without config: no alias, names and vars are the palette" do
    assert Application.get_env(:ledger_ui, :color_aliases) == nil
    assert "error" in Color.names()
    refute "danger" in Color.names()
    assert Color.resolve("error") == "error"
    assert Color.resolve("danger") == "danger"
    assert_raise KeyError, fn -> Color.vars("danger") end
  end

  test "resolve/2 maps an alias to its target and leaves other names alone" do
    aliases = %{"danger" => "error"}
    assert Color.resolve("danger", aliases) == "error"
    assert Color.resolve("success", aliases) == "success"
    assert Color.vars(Color.resolve("danger", aliases)) == Color.vars("error")
  end
end
