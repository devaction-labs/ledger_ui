defmodule LedgerUI.Components.AuthSplitTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.AuthSplit

  test "form only takes the whole card" do
    assigns = %{}
    html = rendered_to_string(~H|<.auth_split title="Hi">form</.auth_split>|)
    refute html =~ "data-lu-auth-right"
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
    assert html =~ "bg-tray p-10"
    assert html =~ "max-lg:hidden!"
    assert html =~ "w-full"
    assert html =~ "OU"
    refute html =~ "grid-cols-[minmax(0,1fr)_minmax(0,1.05fr)]"
  end

  test "variant full" do
    assigns = %{}

    assert rendered_to_string(~H|<.auth_split title="x" variant="full">f</.auth_split>|) =~
             "min-h-screen"
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

    assert html =~ "grid-cols-[minmax(0,1fr)_minmax(0,1.05fr)]"
    assert html =~ ">A</span>Acme"
    assert html =~ "max-w-[380px]"
    assert html =~ "justify-between text-[12.5px]"
    assert html =~ ~s(data-part="auth-art-box")

    form =
      rendered_to_string(
        ~H|<.auth_page form_id="f" on_submit="go" on_change="chg">x</.auth_page>|
      )

    assert form =~ ~r/<form[^>]*max-w-\[380px\]/
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

    assert html =~ ~s(data-part="summit")
    assert html =~ ~s(id="x-sky")
    assert html =~ "url(#x-m1)"
    assert html =~ ~s(data-part="auth-chip")
    assert html =~ ~s(style="top:44px;right:40px")
    assert html =~ ~r{<q [^>]*>great</q>}
    assert html =~ ~s(data-part="avatar")
    assert html =~ "Lia"
  end

  describe "top, page footer, heading and form width" do
    test "default: variable width class, no new slots, no style" do
      assigns = %{}
      html = rendered_to_string(~H|<.auth_split title="Hi">form</.auth_split>|)
      assert html =~ "w-(--lu-auth-form-w,360px)"
      refute html =~ "w-[360px]"
      refute html =~ "style="
      refute html =~ "auth-split-top"
      refute html =~ "auth-split-page-footer"
    end

    test "top and page footer are around the form, in order" do
      for v <- ~w(card full) do
        assigns = %{v: v}

        html =
          rendered_to_string(~H|<.auth_split title="Hi" variant={@v}>
  form<:top>TOPO</:top><:page_footer>RODAPE</:page_footer><:footer>LINHA</:footer>
</.auth_split>|)

        pos = fn s -> :binary.match(html, s) |> elem(0) end
        assert pos.("TOPO") < pos.("auth-split-form\"")
        assert pos.("auth-split-form\"") < pos.("LINHA")
        assert pos.("LINHA") < pos.("RODAPE")
        assert html =~ "justify-between"
      end
    end

    test "heading replaces title in the same element" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.auth_split title="Plain" subtitle="sub">
  f<:heading>Entrar<br /><em>agora</em></:heading>
</.auth_split>|)

      refute html =~ "Plain"
      assert html =~ "<br"
      assert html =~ ~r/data-part="auth-split-title"[^>]*>\s*Entrar<br/
      assert html =~ "sub"
    end

    test "no title and no heading renders no title" do
      assigns = %{}
      html = rendered_to_string(~H|<.auth_split>f</.auth_split>|)
      refute html =~ "auth-split-title"
    end

    test "form_width sets the variable, merged with the rest style" do
      assigns = %{}
      html = rendered_to_string(~H|<.auth_split title="x" form_width={380}>f</.auth_split>|)
      assert html =~ ~s(style="--lu-auth-form-w: 380px")

      html =
        rendered_to_string(
          ~H|<.auth_split title="x" form_width={380} style="color:red">f</.auth_split>|
        )

      assert html =~ ~s(style="--lu-auth-form-w: 380px;color:red")

      html = rendered_to_string(~H|<.auth_split title="x" style="color:red">f</.auth_split>|)
      assert html =~ ~s(style="color:red")
    end
  end
end
