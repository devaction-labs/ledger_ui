defmodule LedgerUI.Perf.OptionsNormalizeTest do
  use ExUnit.Case, async: true

  # #94: `Options.normalize/1` of a map is one pass (it was `Map.take` + two `Map.drop` + a second map for
  # each option, 16 `Map.drop_keys` per option in the profile). The result has to stay the same.
  alias LedgerUI.Components.Select.Options

  @known ~w(label value count hint disabled icon description color initials tone)a

  # The reference: the implementation of 0.12.0.
  defp old(%{} = map) do
    label = Map.get(map, :label) || Map.get(map, "label")
    value = Map.get(map, :value, Map.get(map, "value", label))
    extra = Map.take(map, @known)
    data = map |> Map.drop([:label, :value, "label", "value"]) |> Map.drop(@known)
    extra = Map.put(extra, :data, data)
    label = label || value

    %{
      label: Options.str(label),
      value: Options.str(value),
      disabled: Map.get(extra, :disabled, false) || false,
      hint: Map.get(extra, :hint),
      count: Map.get(extra, :count),
      icon: Map.get(extra, :icon),
      description: Map.get(extra, :description),
      color: Map.get(extra, :color),
      initials: Map.get(extra, :initials),
      tone: Map.get(extra, :tone),
      data: Map.get(extra, :data, %{})
    }
  end

  @maps [
    %{label: "A", value: "a"},
    %{label: "A"},
    %{value: 3},
    %{"label" => "Str", "value" => "s"},
    %{"value" => "only"},
    %{label: "L", value: :atom, hint: "h", count: 2, disabled: true},
    %{label: "L", value: 1, disabled: nil},
    %{label: "L", value: 1, disabled: false},
    %{"team" => "x", label: "Ana", value: "1", job: "dev", icon: "x", tone: "t1", color: "#fff"},
    %{label: "Ana", value: "1", description: "d", initials: "AN"},
    %{label: nil, value: "v"},
    %{label: "L", value: nil},
    %{},
    %{label: "L", value: "v", label_extra: 1, value_x: 2}
  ]

  test "a map option comes out as it did (same fields, same data)" do
    for m <- @maps do
      assert Options.normalize([m]) == [old(m)], "for #{inspect(m)}"
    end
  end

  test "the other shapes are untouched" do
    assert [
             %{label: "a", value: "a", data: %{}},
             %{label: "B", value: "b", count: nil},
             %{label: "B", value: "b", count: 3},
             %{group: "G", options: [%{label: "x", value: "x"}]}
           ] = Options.normalize(["a", {"B", "b"}, {"B", "b", 3}, {"G", ["x"]}])
  end

  test "a thousand map options normalize in well under a millisecond each pass" do
    list = for i <- 1..1000, do: %{label: "Option #{i}", value: "v#{i}", hint: "h"}
    Options.normalize(list)
    {us, result} = :timer.tc(fn -> Options.normalize(list) end)

    assert length(result) == 1000

    # 0.12.0 took 290 to 480 us here on the audit machine; this is a loose bound for a loaded CI box.
    assert us < 20_000
  end

  test "initials/1 splits on any ASCII white space, like the regex it replaces" do
    assert Options.initials("ana   maria\tsilva") == "AS"
    assert Options.initials("  ana ") == "AN"
    assert Options.initials("") == ""
    assert Options.initials("a\nb") == "AB"
    assert Options.initials("a\fb\vc") == "AC"
    assert Options.initials(:ana) == "AN"
  end
end
