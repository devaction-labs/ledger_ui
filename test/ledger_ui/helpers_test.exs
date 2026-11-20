defmodule LedgerUI.HelpersTest do
  use ExUnit.Case, async: true
  doctest LedgerUI.Helpers
  import LedgerUI.Helpers

  test "cx/1 joins and drops empties" do
    assert cx(["a", nil, false, "", {"b", true}, {"c", nil}, [:d]]) == "a b d"
    assert cx(nil) == ""
  end

  test "bool_attr/1" do
    assert bool_attr(1) == "true"
    assert bool_attr(false) == "false"
  end
end
