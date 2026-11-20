defmodule LedgerUI.Components.InputTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Input

  test "bare input is a lu-input box with a real input" do
    assigns = %{}
    html = rendered_to_string(~H|<.input name="q" placeholder="Buscar" />|)
    assert html =~ ~s(<span data-part="input" class="lu-input">)
    assert html =~ ~s(name="q")
    assert html =~ ~s(type="text")
    assert html =~ ~s(placeholder="Buscar")
    refute html =~ "lu-field"
  end

  test "variant, size, shape, align and state map to lu-* classes" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input variant="filled" size="sm" shape="pill" align="right" state="success" />
      """)

    for c <- ~w(lu-input filled sm pill right ok), do: assert(html =~ c)

    html = rendered_to_string(~H|<.input variant="plain" size="lg" state="error" disabled />|)
    assert html =~ ~r/class="lu-input plain lg err disabled"/
    assert html =~ "disabled"
    assert html =~ ~s(aria-invalid="true")
  end

  test "label wraps in lu-field; hint, help, required and inline layout" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input label="Apelido" label_hint="opcional" help="Aparece no DANFE" layout="inline" required />
      """)

    assert html =~ ~s(<label class="lu-field inline")
    assert html =~ ~s(<span class="hint">opcional</span>)
    assert html =~ ~s(<span class="req">*</span>)
    assert html =~ "Aparece no DANFE"
  end

  test "errors replace help and paint the box red" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input label="CNPJ" help="dica" errors={["CNPJ incompleto"]} />
      """)

    assert html =~ "CNPJ incompleto"
    assert html =~ "lu-input err"
    refute html =~ "dica"
  end

  test "field fills id, name, value and errors" do
    form =
      to_form(%{"email" => "a@b.c"},
        as: :user,
        errors: [email: {"is taken", []}],
        action: :validate
      )

    assigns = %{f: form[:email]}
    html = rendered_to_string(~H|<.input field={@f} type="email" label="E-mail" />|)
    assert html =~ ~s(id="user_email")
    assert html =~ ~s(name="user[email]")
    assert html =~ ~s(value="a@b.c")
    assert html =~ ~s(type="email")
    assert html =~ "is taken"
  end

  test "prefix, suffix and icon" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input icon="search" name="u">
        <:prefix text>https://</:prefix>
        <:suffix text>.com.br</:suffix>
      </.input>
      """)

    assert html =~ ~s(data-icon="search")
    assert html =~ ~r/<span class="addon sep">https:\/\/<\/span>/
    assert html =~ ~r/<span class="addon sep-r">\.com\.br<\/span>/

    html =
      rendered_to_string(~H"""
      <.input name="m">
        <:suffix interactive><button type="submit" aria-label="Send">go</button></:suffix>
      </.input>
      """)

    assert html =~ ~s(aria-label="Send")
    refute html =~ "addon"
  end

  test "label_aside and below slots" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input label="Senha" name="p">
        <:label_aside><a href="/forgot">Esqueci</a></:label_aside>
        <:below><i class="bars"></i></:below>
      </.input>
      """)

    assert html =~ "Esqueci"
    assert html =~ "bars"
  end

  test "mask adds the hook with its options; raw submit moves the name to a hidden input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input id="doc" name="doc" mask="cpf_cnpj" mask_submit="raw" phx-debounce="300" />
      """)

    assert html =~ ~s(phx-hook="LedgerUI.InputMask")
    assert html =~ ~s(data-lu-mask="cpf_cnpj")
    assert html =~ ~s(data-lu-mask-raw="true")
    assert html =~ ~s(inputmode="numeric")
    assert html =~ ~s(<input type="hidden" name="doc")
    assert html =~ ~s(phx-debounce="300")
    # the visible input does not submit
    refute html =~ ~r/<input[^>]*id="doc"[^>]*name="doc"/

    html =
      rendered_to_string(~H"""
      <.input id="n" name="n" mask="numeral" mask_options={%{thousands: "lakh", prefix: "R$ "}} />
      """)

    assert html =~ "&quot;thousands&quot;:&quot;lakh&quot;"
    refute html =~ ~s(type="hidden")
  end

  test "clear_on_submit uses the hook; no hook otherwise" do
    assigns = %{}
    html = rendered_to_string(~H|<.input id="todo" name="title" value="x" clear_on_submit />|)
    assert html =~ ~s(phx-hook="LedgerUI.InputMask")
    assert html =~ ~s(data-lu-clear-on-submit="true")

    html = rendered_to_string(~H|<.input name="title" />|)
    refute html =~ "phx-hook"
  end

  test "options render a datalist; hidden type renders only the hidden input" do
    assigns = %{}
    html = rendered_to_string(~H|<.input id="c" name="c" options={~w(a b)} />|)
    assert html =~ ~s(<datalist id="c-list">)
    assert html =~ ~s(list="c-list")

    html = rendered_to_string(~H|<.input type="hidden" name="h" value="1" />|)
    assert html =~ ~s(type="hidden")
    refute html =~ "lu-input"
  end
end
