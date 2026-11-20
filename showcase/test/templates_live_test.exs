defmodule LedgerShowcase.TemplatesLiveTest do
  @moduledoc "The behavior of the app templates (`/templates/:slug`): routes, forms, selection, overlays."
  use ExUnit.Case, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint LedgerShowcaseWeb.Endpoint

  alias LedgerShowcase.Templates

  test "the index lists the templates of t/index.json and the sidebar group" do
    {:ok, _lv, html} = live(build_conn(), "/templates")
    assert html =~ "16 · Templates"
    assert html =~ ~s(id="side-templates")

    for slug <- Templates.slugs() do
      assert html =~ ~s(id="tpl-card-#{slug}"), slug
      assert html =~ ~s(href="/templates/#{slug}")
    end

    {:ok, _lv, home} = live(build_conn(), "/")
    assert home =~ "intro-templates"
    assert home =~ ~s(href="/templates/tabela-gaveta")
  end

  test "every slug mounts full screen, without the showcase chrome, with the theme toggle" do
    assert length(Templates.slugs()) == 10

    for slug <- Templates.slugs() do
      {:ok, _lv, html} = live(build_conn(), "/templates/#{slug}")
      assert html =~ ~s(data-template="#{slug}")
      assert html =~ ~s(id="th")
      refute html =~ "d-top"
      refute html =~ ~s(id="side")
    end

    # the same page with a theme in the query (the root layout script reads it)
    {:ok, _lv, html} = live(build_conn(), "/templates/dashboard?theme=dark")
    assert html =~ "URLSearchParams(location.search).get(\"theme\")"
    assert html =~ "lu-theme"
  end

  describe "login" do
    test "a wrong pair shows the tries left and locks after three misses" do
      {:ok, lv, html} = live(build_conn(), "/templates/auth-login")
      refute html =~ "incorretos"

      bad = %{login: %{email: "ana@bompreco.com.br", password: "errada"}}
      html = lv |> form("#login-form", bad) |> render_submit()
      assert html =~ "E-mail ou senha incorretos."
      assert html =~ "Restam 2 tentativas."

      lv |> form("#login-form", bad) |> render_submit()
      html = lv |> form("#login-form", bad) |> render_submit()
      assert html =~ "Acesso bloqueado"
      assert html =~ "disabled"
    end

    test "the error board starts with the notice; the right pair goes to the dashboard" do
      {:ok, lv, html} = live(build_conn(), "/templates/auth-login-erro")
      assert html =~ "E-mail ou senha incorretos."
      assert html =~ "Restam 2 tentativas."

      ok = %{login: %{email: "ana@bompreco.com.br", password: "demo123456"}}
      lv |> form("#login-form", ok) |> render_submit()
      assert_redirect(lv, "/templates/dashboard")
    end

    test "validates the e-mail while typing" do
      {:ok, lv, _} = live(build_conn(), "/templates/auth-login")
      html = lv |> form("#login-form", %{login: %{email: "ana"}}) |> render_change()
      assert html =~ "E-mail inválido."
    end
  end

  describe "cadastro" do
    test "step 2 looks the CNPJ up, then goes to the plan and finishes" do
      {:ok, lv, html} = live(build_conn(), "/templates/auth-cadastro")
      assert html =~ "Encontrado"
      assert html =~ "Conte sobre sua empresa"

      html =
        lv |> form("#signup-form", %{signup: %{cnpj: "11.222.333/0001-81"}}) |> render_change()

      refute html =~ "Encontrado"

      html =
        lv |> form("#signup-form", %{signup: %{cnpj: "98.765.432/0001-10"}}) |> render_change()

      assert html =~ "Encontrado"

      html =
        lv
        |> element("#signup-regime")
        |> render_hook("regime", %{"id" => "signup-regime", "value" => "Real"})

      assert html =~ ~r/aria-pressed="true"[^>]*>\s*Real/

      html =
        lv |> form("#signup-form", %{signup: %{cnpj: "98.765.432/0001-10"}}) |> render_submit()

      assert html =~ "Escolha seu plano"

      html = lv |> element("button[phx-click=back]") |> render_click()
      assert html =~ "Conte sobre sua empresa"
    end

    test "an unknown CNPJ blocks the step" do
      {:ok, lv, _} = live(build_conn(), "/templates/auth-cadastro")
      lv |> form("#signup-form", %{signup: %{cnpj: "00.000.000/0001-00"}}) |> render_change()

      html =
        lv |> form("#signup-form", %{signup: %{cnpj: "00.000.000/0001-00"}}) |> render_submit()

      assert html =~ "Informe um CNPJ válido"
      assert html =~ "Conte sobre sua empresa"
    end
  end

  describe "codigo" do
    test "a wrong code shows the error, the right one signs in" do
      {:ok, lv, html} = live(build_conn(), "/templates/auth-codigo")
      assert html =~ "Reenviar em 0:42"

      html = render_submit(lv, "verify", %{"verify" => %{"code" => "111111"}})
      assert html =~ "Código incorreto"

      render_submit(lv, "verify", %{"verify" => %{"code" => "482915"}})
      assert_redirect(lv, "/templates/dashboard")
    end

    test "an incomplete code asks for the six digits" do
      {:ok, lv, _} = live(build_conn(), "/templates/auth-codigo")
      html = render_submit(lv, "verify", %{"verify" => %{"code" => "123"}})
      assert html =~ "Digite os 6 dígitos"
    end

    test "the resend counts down" do
      {:ok, lv, _} = live(build_conn(), "/templates/auth-codigo")
      send(lv.pid, :tick)
      assert render(lv) =~ "Reenviar em 0:41"
    end
  end

  describe "senha" do
    test "the notice follows the submit, an invalid e-mail shows the error" do
      {:ok, lv, html} = live(build_conn(), "/templates/auth-senha")
      assert html =~ "Link enviado."

      html = lv |> form("#recover-form", %{recover: %{email: "rita"}}) |> render_change()
      refute html =~ "Link enviado."
      assert html =~ "E-mail inválido."

      html =
        lv |> form("#recover-form", %{recover: %{email: "rita@loja.com.br"}}) |> render_submit()

      assert html =~ "Link enviado."
      assert html =~ "rita@loja.com.br"
    end
  end

  describe "dashboard" do
    test "the range switch redraws the chart" do
      {:ok, lv, html} = live(build_conn(), "/templates/dashboard")
      assert html =~ "R$ 184.320"
      assert html =~ "Nov 2026"

      html =
        lv
        |> element("#tp-range")
        |> render_hook("range", %{"id" => "tp-range", "value" => "ano"})

      assert html =~ "2026"
      assert html =~ "Ano anterior"
      refute html =~ "Nov 2026"
    end
  end

  describe "tabela" do
    test "selection drives the floating bulk bar" do
      {:ok, lv, html} = live(build_conn(), "/templates/tabela")
      assert html =~ "3 selecionados"
      assert html =~ "lu-bulkfloat"

      html = lv |> element(~s(input[phx-click=toggle][phx-value-id="2496"])) |> render_click()
      assert html =~ "4 selecionados"

      html = lv |> element("button[aria-label='Limpar seleção']") |> render_click()
      refute html =~ "lu-bulkfloat"

      html = lv |> element("input[phx-click=toggle_all]") |> render_click()
      assert html =~ "12 selecionados"

      html = lv |> element("button[phx-click=bulk][phx-value-id=export]") |> render_click()
      assert html =~ "12 pedidos exportados."
      refute html =~ "lu-bulkfloat"
    end

    test "the tabs and the search filter the rows" do
      {:ok, lv, _} = live(build_conn(), "/templates/tabela")

      html =
        lv |> element(~s(div[role=tablist] button[phx-value-name=atrasados])) |> render_click()

      assert html =~ "Lanchonete do Zé"
      refute html =~ "Padaria Central"

      html = lv |> element("input[phx-keyup=search]") |> render_keyup(%{"value" => "feira boa"})
      refute html =~ "Lanchonete do Zé"
    end

    test "a row opens the drawer by patch and closing returns to the table" do
      {:ok, lv, html} = live(build_conn(), "/templates/tabela")
      refute html =~ "lu-drawer"

      html = lv |> element("#order-2491") |> render_click()
      assert_patch(lv, "/templates/tabela?pedido=2491")
      assert html =~ "Pedido #2491"
      assert html =~ "lu-drawer"

      lv |> element("button.lu-x[aria-label=Fechar]") |> render_click()
      assert_patch(lv, "/templates/tabela")
      refute render(lv) =~ "lu-drawer"
    end

    test "the drawer and the modal open from the url, and the three slugs keep their state" do
      {:ok, _lv, html} = live(build_conn(), "/templates/tabela?pedido=2491")
      assert html =~ "Pedido #2491"

      {:ok, _lv, html} = live(build_conn(), "/templates/tabela?novo=1")
      assert html =~ "Novo pedido"
      assert html =~ "lu-modal"

      {:ok, _lv, html} = live(build_conn(), "/templates/tabela-gaveta")
      assert html =~ "Pedido #2495"

      {:ok, _lv, html} = live(build_conn(), "/templates/tabela-modal")
      assert html =~ "lu-modal"

      # other params (the theme) do not change which overlay opens
      {:ok, _lv, html} = live(build_conn(), "/templates/tabela-gaveta?theme=dark")
      assert html =~ "Pedido #2495"
    end

    test "the new order form edits the items, validates and creates" do
      {:ok, lv, _} = live(build_conn(), "/templates/tabela-modal")

      # the stepper's hidden input fires `input`: the form's phx-change reports the whole quantity
      html = render_hook(lv, "validate_order", %{"order" => %{"qty" => %{"0" => "13"}}})

      assert html =~ "R$ 310,70"

      html = lv |> element("button[phx-click=remove_item][phx-value-index='2']") |> render_click()
      refute html =~ "Óleo de soja"

      lv |> element("button[phx-click=add_item]") |> render_click()
      html = lv |> element("button[phx-click=add_item]") |> render_click()
      assert html =~ "Arroz tipo 1 5 kg"

      html =
        lv
        |> element("#order-payment")
        |> render_hook("pay", %{"id" => "order-payment", "value" => "Boleto"})

      assert html =~ ~r/aria-pressed="true"[^>]*>\s*Boleto/

      lv |> form("#order-modal", %{order: %{delivery: "Amanhã, 9h"}}) |> render_change()
      assert :sys.get_state(lv.pid).socket.assigns.form["delivery"] == "Amanhã, 9h"

      lv |> form("#order-modal") |> render_submit()
      assert_patch(lv, "/templates/tabela")
      html = render(lv)
      assert html =~ "Pedido criado"
      refute html =~ "lu-modal"
    end
  end

  describe "tabela-app (Pedidos · interativa)" do
    test "starts with no selection and no overlay, and keeps the visitor on its own page" do
      {:ok, lv, html} = live(build_conn(), "/templates/tabela-app")
      assert html =~ ~s(data-template="tabela-app")
      refute html =~ "lu-bulkfloat"
      refute html =~ "lu-drawer"

      html = lv |> element(~s(input[phx-click=toggle][phx-value-id="2496"])) |> render_click()
      assert html =~ "1 selecionado"

      lv |> element("#order-2491") |> render_click()
      assert_patch(lv, "/templates/tabela-app?pedido=2491")
      assert render(lv) =~ "lu-drawer"

      lv |> element("button[phx-click=close_overlay]") |> render_click()
      assert_patch(lv, "/templates/tabela-app")
    end

    test "Emitir NF-e closes the drawer, shows the transmission and then the authorization" do
      {:ok, lv, _} = live(build_conn(), "/templates/tabela-app?pedido=2495")
      html = lv |> element("button[data-tp-nfe]") |> render_click()
      assert html =~ "Emitindo NF-e"
      assert_patch(lv, "/templates/tabela-app")
      refute render(lv) =~ "lu-drawer"

      send(lv.pid, {:nfe_done, 2495})
      assert render(lv) =~ "NF-e 48.212 autorizada · Pedido #2495"
    end
  end

  describe "palette" do
    test "?palette=crepusculo marks the template root; the page and the index show the palette pages" do
      {:ok, _lv, html} = live(build_conn(), "/templates/dashboard?palette=crepusculo")
      assert html =~ ~s(data-palette="crepusculo")
      assert html =~ "data-palette"

      {:ok, _lv, html} = live(build_conn(), "/templates/paleta")
      assert html =~ ~s(data-template="paleta")
      assert html =~ ~s(data-palette="crepusculo")
      assert html =~ "--state-working"
      assert html =~ "Crepúsculo"

      {:ok, _lv, html} = live(build_conn(), "/templates")

      for %{path: path} = t <- Templates.palette_pages() do
        assert html =~ ~s(href="#{path}"), t.title
      end
    end

    test "the showcase header has the palette menu and the Temas page lists both palettes" do
      {:ok, _lv, html} = live(build_conn(), "/")
      assert html =~ ~s(id="plb")
      assert html =~ ~s(id="plm")
      assert html =~ ~s(id="d-palettes")
      assert html =~ "Inter+Tight"

      {:ok, _lv, html} = live(build_conn(), "/temas")
      assert html =~ ~s(data-palette="crepusculo")
      assert html =~ ~s(data-palette="ledger")
      assert html =~ "Usar esta"
      assert html =~ "Céu da abertura"
    end
  end
end
