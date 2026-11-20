defmodule LedgerUI.Components.AuthSplitTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.AuthSplit

  test "form only takes the whole card" do
    assigns = %{}
    html = rendered_to_string(~H|<.auth_split title="Hi">form</.auth_split>|)
    refute html =~ "lu-auth-right\""
    assert html =~ ~s(role="heading" aria-level="1")
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

  test "aside is the tray panel of the right half; providers sit flat above the divider" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.auth_split title="Hi" divider_label="OU">
  <:providers><.oauth_button block provider="google">G</.oauth_button></:providers>form<:aside>
    side
  </:aside>
</.auth_split>|)

    assert html =~ "data-lu-auth-right"
    assert html =~ "padding:40px"
    assert html =~ "lu-btn block lg"
    assert html =~ "OU"
    refute html =~ "lu-auth\""
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

  test "auth_page: brand, column, footer and art; a form with on_submit" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.auth_page brand="Acme" mark="A">
  <h1>Hi</h1>
  <:footer><span>c</span><span>t</span></:footer>
  <:art>art</:art>
</.auth_page>|)

    assert html =~ ~s(class="lu-auth")
    assert html =~ ~s(<span class="mk">A</span>Acme)
    assert html =~ ~s(<div class="in">)
    assert html =~ ~s(class="ft")
    assert html =~ ~s(class="art")

    form =
      rendered_to_string(
        ~H|<.auth_page form_id="f" on_submit="go" on_change="chg">x</.auth_page>|
      )

    assert form =~ ~r/<form[^>]*class="in"/
    assert form =~ ~s(phx-submit="go")
    assert form =~ ~s(phx-change="chg")
    refute form =~ ~s(class="art")
  end

  test "auth_art: the landscape with its own gradient ids, chips and the quote" do
    assigns = %{}

    html =
      rendered_to_string(~H|<.auth_art id="x">
  <:chip top="44px" right="40px">chip</:chip>
  <:quote author="Lia" role="Dona" initials="LI" tone="t4">great</:quote>
</.auth_art>|)

    assert html =~ ~s(class="lu-summit teal")
    assert html =~ ~s(id="x-sky")
    assert html =~ "url(#x-m1)"
    assert html =~ ~s(class="chip" style="top:44px;right:40px")
    assert html =~ ~s(<q>great</q>)
    assert html =~ ~s(lu-av t4)
    assert html =~ "Lia"
  end
end
