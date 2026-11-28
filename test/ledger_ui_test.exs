defmodule LedgerUITest do
  use ExUnit.Case, async: true
  alias Phoenix.LiveView.JS

  test "open/close/toggle build JS commands" do
    assert %JS{ops: ops} = LedgerUI.open("dlg")
    assert [["add_class", %{names: ["open"], to: "#dlg"}], ["set_attr", _]] = ops
    assert %JS{} = LedgerUI.close(%JS{}, "dlg")
    assert %JS{} = LedgerUI.toggle("dlg")
  end

  test "socket variants push events" do
    socket = %Phoenix.LiveView.Socket{}

    assert %{
             private: %{
               live_temp: %{
                 push_events: [["ledger:js", %{id: "x", open: true, js: open_ops}]]
               }
             }
           } = LedgerUI.open(socket, "x")

    assert [["add_class", %{names: ["open"], to: "#x"}], ["set_attr", _]] = open_ops
    assert open_ops == JS.to_encodable(LedgerUI.open("x"))

    assert %{
             private: %{
               live_temp: %{
                 push_events: [["ledger:js", %{id: "x", open: false, js: close_ops}]]
               }
             }
           } = LedgerUI.close(socket, "x")

    assert [["remove_class", %{names: ["open"], to: "#x"}], ["set_attr", _]] = close_ops

    # the payload is JSON, as the LiveView 1.2 hook API (`execJS`) expects
    assert {:ok, _} = Jason.encode(%{js: open_ops})
  end

  test "use LedgerUI imports icon" do
    defmodule UsesIt do
      use LedgerUI
      import Phoenix.Component
      def r(assigns), do: ~H|<.icon name="home" />|
    end

    assert %Phoenix.LiveView.Rendered{} = UsesIt.r(%{})
  end

  test "every registered module exists" do
    for m <- LedgerUI.Components.__modules__(), do: assert(Code.ensure_loaded?(m))
    assert length(LedgerUI.Components.__modules__()) == 121
  end
end
