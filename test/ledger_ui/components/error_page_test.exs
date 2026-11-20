defmodule LedgerUI.Components.ErrorPageTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.ErrorPage

  test "code picks tone and English defaults" do
    assigns = %{}
    html = rendered_to_string(~H|<.error_page code={404} />|)
    assert html =~ "Page not found"
    assert html =~ ~s(data-tone="neutral")
    assert rendered_to_string(~H|<.error_page code={500} />|) =~ ~s(data-tone="error")
    assert rendered_to_string(~H|<.error_page code={403} />|) =~ ~s(data-tone="warning")
    assert rendered_to_string(~H|<.error_page code={419} />|) =~ ~s(data-tone="accent")
    assert rendered_to_string(~H|<.error_page code="OFF" />|) =~ "You are offline"
  end

  test "explicit texts, request id with copy button, back button and slots" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.error_page
        code={404}
        title="Gone"
        label="Nope"
        description="Moved"
        request_id="req-1"
        back_label="Back"
        timestamp="now"
        tone="error"
      >
        <:brand><b>Acme</b></:brand>
        <:status href="/status" status="down">Down</:status>
        <:actions><a href="/">Home</a></:actions>
        <:card>similar</:card>
        <:footer><a href="/help">Help</a></:footer>
        body
      </.error_page>
      """)

    for t <- [
          "Gone",
          "Nope",
          "Moved",
          "req-1",
          "Back",
          "now",
          "Acme",
          "Down",
          "Home",
          "similar",
          "Help",
          "body"
        ],
        do: assert(html =~ t)

    assert html =~ ~s(data-copy="req-1")
    assert html =~ "history.back()"
    assert html =~ ~s(data-tone="error")
  end

  test "copy can be turned off" do
    assigns = %{}

    refute rendered_to_string(~H|<.error_page code={404} request_id="r" copy={false} />|) =~
             "data-copy"
  end

  test "error_state and error_links" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.error_state code={404} id="orders" title="Order not found">
        It may be gone.
        <:actions><a href="/">All</a></:actions>
        <:more>recent</:more>
      </.error_state>
      <.error_links title="Who can grant it">
        <:link href="mailto:a@b.c" icon="user" description="Admin">Alex</:link>
        <:link navigate="/orders">Orders</:link>
      </.error_links>
      """)

    assert html =~ ~s(id="orders-title")
    assert html =~ "Order not found"
    assert html =~ "It may be gone."
    assert html =~ "recent"
    assert html =~ "Who can grant it"
    assert html =~ ~s(href="mailto:a@b.c")
    assert html =~ ~s(href="/orders")
  end
end
