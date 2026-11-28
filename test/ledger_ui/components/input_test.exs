defmodule LedgerUI.Components.InputTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Input

  test "bare input is a box with a real input" do
    assigns = %{}
    html = rendered_to_string(~H|<.input name="q" placeholder="Buscar" />|)
    assert html =~ ~s(<span data-part="input" class="flex min-w-0 items-center gap-2 border)
    assert html =~ "h-10 rounded-md px-3"
    assert html =~ "bg-panel border-line-strong"
    assert html =~ "focus-within:border-ink-2"
    assert html =~ "focus-within:shadow-[0_0_0_4px_var(--lu-focus)]"
    assert html =~ ~s(name="q")
    assert html =~ ~s(type="text")
    assert html =~ ~s(placeholder="Buscar")
    refute html =~ ~s(data-part="field")
  end

  test "variant, size, shape, align and state pick one utility per property" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input variant="filled" size="sm" shape="pill" align="right" state="success" />
      """)

    for c <- ~w(bg-sunken border-pos h-9 rounded-full px-4 text-right tabular-nums),
        do: assert(html =~ c)

    refute html =~ "px-2.5"
    refute html =~ "rounded-[8px]"

    html = rendered_to_string(~H|<.input variant="plain" size="lg" state="error" disabled />|)
    assert html =~ "bg-transparent border-neg"
    assert html =~ "pr-3 pl-0.5"
    assert html =~ "h-11 rounded-[14px]"
    assert html =~ "cursor-not-allowed"
    assert html =~ "disabled"
    assert html =~ ~s(aria-invalid="true")
  end

  test "label wraps in a field; hint, help, required and inline layout" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input label="Apelido" label_hint="opcional" help="Aparece no DANFE" layout="inline" required />
      """)

    assert html =~ ~s(<label class="flex min-w-0 flex-row items-center gap-3.5)
    assert html =~ ~s(>opcional</span>)
    assert html =~ ~s(<span data-part="label-required" class="text-neg">*</span>)
    assert html =~ "Aparece no DANFE"
  end

  test "errors replace help and paint the box red" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input label="CNPJ" help="dica" errors={["CNPJ incompleto"]} />
      """)

    assert html =~ "CNPJ incompleto"
    assert html =~ "border-neg"
    assert html =~ ~s(aria-invalid="true")
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
      <.input icon="search" name="u" prefix="https://" suffix=".com.br" />
      """)

    assert html =~ ~s(data-icon="search")
    assert html =~ ~r/<span data-part="input-addon" class="[^"]*border-r[^"]*">https:\/\/<\/span>/
    assert html =~ ~r/<span data-part="input-addon" class="[^"]*border-l[^"]*">\.com\.br<\/span>/

    html =
      rendered_to_string(~H"""
      <.input name="m">
        <:trailing><button type="submit" aria-label="Send">go</button></:trailing>
      </.input>
      """)

    assert html =~ ~s(aria-label="Send")
    refute html =~ " border-l "
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

  test "a masked input without id gets a stable id derived from its name (hooks need one)" do
    assigns = %{}
    html = rendered_to_string(~H|<.input name="signup[cnpj]" mask="cpf_cnpj" />|)
    assert html =~ ~s(phx-hook="LedgerUI.InputMask")
    assert html =~ ~s(id="lu-in-signup-cnpj-")

    html = rendered_to_string(~H|<.input id="doc" name="doc" mask="cpf_cnpj" />|)
    assert html =~ ~s(id="doc")
  end

  test "shortcut draws an aria-hidden kbd, aria-keyshortcuts and the hook on the box" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H|<.input type="search" id="q" name="q" shortcut="/" placeholder="Buscar" />|
      )

    assert html =~ ~s(id="q-box")
    assert html =~ ~s(phx-hook="LedgerUI.SearchShortcut")
    assert html =~ ~s(data-lu-shortcut="/")
    assert html =~ ~s(aria-keyshortcuts="/")
    assert html =~ ~s(<kbd data-part="kbd")
    assert html =~ ~s(aria-hidden="true")
    assert html =~ ">/</kbd>"
    # the field keeps its own hook
    refute html =~ ~s(phx-hook="LedgerUI.InputMask")
  end

  test "shortcut works with a mask (separate hooks) and derives the id from the name" do
    assigns = %{}
    html = rendered_to_string(~H|<.input name="user[q]" mask="cpf_cnpj" shortcut="/" />|)
    assert html =~ ~s(phx-hook="LedgerUI.InputMask")
    assert html =~ ~s(phx-hook="LedgerUI.SearchShortcut")
    assert html =~ ~s(id="lu-in-user-q--box")

    html = rendered_to_string(~H|<.input type="search" name="q" shortcut="/" />|)
    assert html =~ ~s(id="lu-in-q")
  end

  test "without shortcut the markup has no kbd, hook or aria-keyshortcuts" do
    assigns = %{}
    html = rendered_to_string(~H|<.input type="search" id="q" name="q" />|)
    refute html =~ "kbd"
    refute html =~ "phx-hook"
    refute html =~ "aria-keyshortcuts"
    refute html =~ "data-lu-shortcut"
    refute html =~ ~s(id="q-box")

    html = rendered_to_string(~H|<.input type="search" id="q" name="q" shortcut="" />|)
    refute html =~ "kbd"
  end
end
