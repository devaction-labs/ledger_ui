defmodule LedgerUI.DebugAnnotationsTest do
  # Changes the application environment (compile-time options): not async.
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  defp compile_and_render(name) do
    code = """
    defmodule #{name} do
      use LedgerUI.Component
      def hello(assigns), do: ~H|<p id="x">hi</p>|
    end
    """

    [{mod, _}] = Code.compile_string(code)
    html = rendered_to_string(mod.hello(%{__changed__: nil}))
    :code.purge(mod)
    :code.delete(mod)
    html
  end

  setup do
    old_lv = {
      Application.fetch_env(:phoenix_live_view, :debug_heex_annotations),
      Application.fetch_env(:phoenix_live_view, :debug_attributes)
    }

    old_lu = Application.fetch_env(:ledger_ui, :debug_annotations)
    Application.put_env(:phoenix_live_view, :debug_heex_annotations, true)
    Application.put_env(:phoenix_live_view, :debug_attributes, true)

    on_exit(fn ->
      {a, b} = old_lv
      restore(:phoenix_live_view, :debug_heex_annotations, a)
      restore(:phoenix_live_view, :debug_attributes, b)
      restore(:ledger_ui, :debug_annotations, old_lu)
    end)
  end

  defp restore(app, key, {:ok, v}), do: Application.put_env(app, key, v)
  defp restore(app, key, :error), do: Application.delete_env(app, key)

  test "by default the kit follows the app: annotations on" do
    Application.delete_env(:ledger_ui, :debug_annotations)
    html = compile_and_render("LedgerUI.DebugAnnotationsTest.Default")
    assert html =~ "<!--"
    assert html =~ "data-phx-loc"
  end

  test "debug_annotations: false takes the kit out of both" do
    Application.put_env(:ledger_ui, :debug_annotations, false)
    html = compile_and_render("LedgerUI.DebugAnnotationsTest.Off")
    refute html =~ "<!--"
    refute html =~ "data-phx-loc"
    assert html =~ ~s(<p id="x">hi</p>)
  end
end
