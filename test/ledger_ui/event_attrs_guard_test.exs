defmodule LedgerUI.EventAttrsGuardTest do
  # #119 item 1: an `on_*` attr declared `:string` is read by its hook as an event name. For the
  # components that opt in (`@ledger_ui_event_guard true`) a `%JS{}` raises an ArgumentError that
  # says what to do, instead of rendering JSON that the hook would push as an event name.
  use ExUnit.Case, async: true
  use Phoenix.Component
  use LedgerUI

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
  alias Phoenix.LiveView.JS

  test "a JS command in a string-only on_* attr raises" do
    assigns = %{js: JS.push("x")}

    assert_raise ArgumentError, ~r/`on_restore` takes a LiveView event name/, fn ->
      rendered_to_string(~H|<.persist id="p" key="k" value={1} on_restore={@js} />|)
    end
  end

  test "an event name still renders as before" do
    assigns = %{}

    assert rendered_to_string(~H|<.persist id="p" key="k" value={1} on_restore="back" />|) =~
             ~s(data-lu-on-restore="back")
  end

  test "an :any on_* attr (not guarded) still takes a JS command" do
    assigns = %{js: JS.push("x")}
    assert rendered_to_string(~H|<.badge on_remove={@js}>a</.badge>|) =~ "push"
  end
end
