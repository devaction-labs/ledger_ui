defmodule LedgerUI.Components.ConversationListFormTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Ai

  # #108 B: a form with `phx-change` needs an id (LiveView's form recovery; the 1.2 test client warns).
  test "the search form takes <id>-search from the list's id" do
    assigns = %{c: [%{id: "1", title: "A"}]}

    html =
      rendered_to_string(
        ~H|<.conversation_list id="convs" conversations={@c} on_search="search" />|
      )

    assert html =~ ~s(id="convs")
    assert html =~ ~s(id="convs-search")
    refute html =~ "phx-ignore-missing-id"
  end

  test "without an id the form is marked phx-ignore-missing-id" do
    assigns = %{c: [%{id: "1", title: "A"}]}
    html = rendered_to_string(~H|<.conversation_list conversations={@c} on_search="search" />|)
    assert html =~ "phx-ignore-missing-id"
  end

  test "without on_search there is no form" do
    assigns = %{c: [%{id: "1", title: "A"}]}
    html = rendered_to_string(~H|<.conversation_list id="convs" conversations={@c} />|)
    refute html =~ "<form"
  end
end
