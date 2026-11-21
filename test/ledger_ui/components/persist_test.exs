defmodule LedgerUI.Components.PersistTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Persist

  test "encodes the value as JSON and sets the storage" do
    assigns = %{v: %{open: true, conversation_id: 7}}

    html =
      rendered_to_string(
        ~H|<.persist id="aw" key="agent_widget" value={@v} on_restore="aw_restore" />|
      )

    assert html =~ ~s(phx-hook="LedgerUI.Persist")
    assert html =~ ~s(data-lu-key="agent_widget")
    assert html =~ ~s(data-lu-storage="session")
    assert html =~ ~s(data-lu-on-restore="aw_restore")

    decoded =
      Regex.run(~r/data-lu-value="([^"]*)"/, html)
      |> List.last()
      |> String.replace("&quot;", "\"")
      |> Jason.decode!()

    assert decoded == %{"open" => true, "conversation_id" => 7}
  end

  test "local storage, target and no restore" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.persist id="p" key="k" storage="local" value="x" target="#t" />|)

    assert html =~ ~s(data-lu-storage="local")
    assert html =~ ~s(data-lu-target="#t")
    refute html =~ "data-lu-on-restore"
  end
end
