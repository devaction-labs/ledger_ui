defmodule LedgerUI.Components.AuthSplitTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.AuthSplit

  test "form only takes the whole card" do
    assigns = %{}
    html = rendered_to_string(~H|<.auth_split title="Hi">form</.auth_split>|)
    refute html =~ "lu-auth-right\""
    assert html =~ "<h1"
  end

  test "picture, quote, providers" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.auth_split title="Hi" src="/a.jpg" subtitle="sub">
  <:providers><.oauth_button provider="google" href="/g">G</.oauth_button></:providers>form<:quote
    author="Ana"
    role="CEO"
    rating={4}
  >
    great
  </:quote><:footer>foot</:footer>
</.auth_split>|)

    assert html =~ ~s(src="/a.jpg")
    assert html =~ "Ana"
    assert html =~ "★★★★☆"
    assert html =~ "Or"
    assert html =~ ~s(data-icon="google")
  end

  test "variant full" do
    assigns = %{}

    assert rendered_to_string(~H|<.auth_split title="x" variant="full">f</.auth_split>|) =~
             "min-height:100vh"
  end

  test "states" do
    assigns = %{}
    assert rendered_to_string(~H|<.auth_sent>sent</.auth_sent>|) =~ ~s(role="status")
    assert rendered_to_string(~H|<.auth_alert>bad</.auth_alert>|) =~ ~s(role="alert")
    html = rendered_to_string(~H|<.auth_submit loading loading_label="Wait">Go</.auth_submit>|)
    assert html =~ "disabled"
    assert html =~ ~s(aria-busy="true")
    assert html =~ "Wait"
  end
end
