defmodule LedgerUI.ComponentDefaultsTest do
  # #102: `config :ledger_ui, :defaults` replaces the default of an attr when the caller does not
  # pass it. The config is read at compile time, so the test modules pass the same keyword with
  # `use LedgerUI.Component, defaults: [...]`.
  use ExUnit.Case, async: true
  import LedgerUI.DiffCase

  defmodule Plain do
    use LedgerUI.Component

    attr :size, :string, default: "md"
    attr :tone, :string, default: nil
    attr :rest, :global

    def chip(assigns) do
      assigns = assign(assigns, :cls, "s-#{assigns.size}")
      settle_chip(assigns)
    end

    defp settle_chip(assigns), do: ~H"<i class={@cls} data-tone={@tone} {@rest}></i>"
  end

  defmodule Configured do
    use LedgerUI.Component, defaults: [chip: [size: "lg", tone: "pos"]]

    attr :size, :string, default: "md"
    attr :tone, :string, default: nil
    attr :rest, :global

    def chip(assigns) do
      assigns = assign(assigns, :cls, "s-#{assigns.size}")
      settle_chip(assigns)
    end

    defp settle_chip(assigns), do: ~H"<i class={@cls} data-tone={@tone} {@rest}></i>"
  end

  defmodule Empty do
    use LedgerUI.Component, defaults: []

    attr :size, :string, default: "md"
    attr :tone, :string, default: nil
    attr :rest, :global

    def chip(assigns), do: ~H"<i class={@size} data-tone={@tone} {@rest}></i>"
  end

  defp render(fun, assigns), do: html(fun, assigns)

  test "without config the attr defaults are the declared ones" do
    assert Application.get_env(:ledger_ui, :defaults) == nil
    assert render(&Plain.chip/1, %{}) == ~s(<i class="s-md"></i>)
    assert render(&Empty.chip/1, %{}) == ~s(<i class="md"></i>)
  end

  test "a configured default replaces the declared one when the caller omits the attr" do
    assert render(&Configured.chip/1, %{}) == ~s(<i class="s-lg" data-tone="pos"></i>)
  end

  test "the caller's value wins, nil included" do
    assert render(&Configured.chip/1, %{size: "sm"}) =~ ~s(class="s-sm")
    assert render(&Configured.chip/1, %{tone: nil}) == ~s(<i class="s-lg"></i>)
  end

  test "global attrs still pass through" do
    assert render(&Configured.chip/1, %{id: "x"}) =~ ~s(id="x")
  end

  test "change tracking: changing an attr resends only what depends on it" do
    base = %{size: "sm", tone: "pos"}
    each_source(&Configured.chip/1, base, size: "lg", tone: "neg")
  end

  test "an unknown or required attr fails the compilation" do
    assert_raise ArgumentError, ~r/has no attr :nope/, fn ->
      Code.compile_string("""
      defmodule LedgerUI.ComponentDefaultsTest.Bad1 do
        use LedgerUI.Component, defaults: [chip: [nope: 1]]
        attr :size, :string, default: "md"
        def chip(assigns), do: ~H"<i></i>"
      end
      """)
    end

    assert_raise ArgumentError, ~r/is required/, fn ->
      Code.compile_string("""
      defmodule LedgerUI.ComponentDefaultsTest.Bad2 do
        use LedgerUI.Component, defaults: [chip: [size: 1]]
        attr :size, :string, required: true
        def chip(assigns), do: ~H"<i></i>"
      end
      """)
    end
  end
end
