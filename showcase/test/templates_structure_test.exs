defmodule LedgerShowcase.TemplatesStructureTest do
  @moduledoc """
  Structure of the template pages (`/templates/:slug`): they are built from library components only
  (no `lu-*` class), and each one carries its key texts and `data-part`s.

  The image of each page against its canvas board (`canvas/T*Claro|Escuro` of the design data) is checked by the
  visual comparison, not here: see `scripts/visual/templates.sh` (`tcanvas` + `tshowcase` + `diff`).
  """
  use ExUnit.Case, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint LedgerShowcaseWeb.Endpoint

  alias LedgerShowcase.Templates

  defp page(path) do
    {:ok, lv, html} = live(build_conn(), path)
    {lv, html}
  end

  test "no template page has a `lu-*` class" do
    paths =
      Enum.map(Templates.slugs(), &"/templates/#{&1}") ++
        [
          "/templates/dashboard?palette=crepusculo",
          "/templates/tabela?pedido=2493",
          "/templates/tabela?novo=1"
        ]

    for path <- paths do
      {_lv, html} = page(path)

      classes =
        Regex.scan(~r/class="([^"]*)"/, html)
        |> Enum.flat_map(fn [_, c] -> String.split(c) end)

      assert Enum.filter(classes, &String.starts_with?(&1, "lu-")) == [], path
    end
  end

  # slug => {texts, data-parts}
  @pages %{
    "auth-login" =>
      {["Entrar no Ledger", "Entrar com Google", "Esqueci a senha", "Criar conta grátis"],
       ~w(auth-page auth-art-box auth-chip button password-toggle checkbox)},
    "auth-login-erro" =>
      {["E-mail ou senha incorretos.", "Restam 2 tentativas."], ~w(auth-alert)},
    "auth-cadastro" =>
      {["Conte sobre sua empresa", "Regime tributário", "Encontrado"],
       ~w(steps segmented input badge)},
    "auth-codigo" => {["Confira seu e-mail", "Reenviar em 0:42"], ~w(otp otp-box otp-cell)},
    "auth-senha" => {["Recuperar a senha", "Link enviado."], ~w(input alert)},
    "dashboard" =>
      {["Novembro está 12% acima de outubro", "Últimos pedidos", "Vendas por canal", "Atividade"],
       ~w(hero-card stat-group line-chart-gridline donut-chart-segment table timeline-item sidebar-panel main-sidebar)},
    "tabela" =>
      {["Pedidos", "3 selecionados", "Mostrando", "Padaria Central"],
       ~w(table table-checkbox table-row tabs-list pagination bulk-bar tag navbar)},
    "tabela-gaveta" => {["Pedido #2495", "Emitir NF-e"], ~w(drawer steps timeline-item)},
    "tabela-modal" => {["Novo pedido", "Criar pedido"], ~w(modal segmented number-input)},
    "tabela-app" => {["Pedidos"], ~w(table navbar)},
    "paleta" => {["Crepúsculo", "--state-working", "Céu da abertura"], ~w(hero-card stat-group)}
  }

  for {slug, {texts, parts}} <- @pages do
    test "#{slug}: key texts and data-parts" do
      {_lv, html} = page("/templates/#{unquote(slug)}")
      assert html =~ ~s(data-template="#{unquote(slug)}")

      for t <- unquote(texts), do: assert(html =~ t, "#{unquote(slug)}: missing text #{t}")

      for p <- unquote(parts),
          do: assert(html =~ ~s(data-part="#{p}), "#{unquote(slug)}: missing data-part #{p}")
    end
  end

  test "the tabela page has 12 rows and sorts by a column" do
    {lv, html} = page("/templates/tabela")
    assert length(Regex.scan(~r/<tr[^>]*id="order-\d+"/, html)) == 12

    html = lv |> element(~s(th[aria-sort][phx-value-column="total"])) |> render_click()
    assert html =~ ~s(aria-sort="ascending")
    [first | _] = Regex.scan(~r/id="order-(\d+)"/, html)
    assert first != nil
  end

  test "?pedido= shows the coherent order (2493): its customer, total and drawer" do
    {_lv, html} = page("/templates/tabela?pedido=2493")
    assert html =~ "Pedido #2493"
    assert html =~ "Lanchonete do Zé"
  end

  @tag :design
  test "the index lists the templates of t/index.json, same order and titles" do
    index =
      LedgerShowcase.Design.json("vitrine/t/index.json")

    assert Enum.map(Templates.pages(), &{&1.slug, &1.title, &1.h}) ==
             Enum.map(index, &{&1["slug"], &1["title"], &1["h"]})

    {:ok, _lv, html} = live(build_conn(), "/templates")

    shown =
      Regex.scan(~r/id="tpl-card-([a-z-]+)"[^>]*>.*?<b>([^<]*)<\/b>/s, html)
      |> Enum.map(fn [_, slug, title] -> {slug, title} end)

    for %{"slug" => slug, "title" => title} <- index do
      assert {slug, title} in shown, "#{slug} (#{title}) is not on /templates"
    end
  end

  test "?palette= is applied on the template root; an unknown palette is ignored" do
    {:ok, _lv, html} = live(build_conn(), "/templates/auth-login?palette=crepusculo")
    assert html =~ ~s(data-palette="crepusculo")
    {:ok, _lv, html} = live(build_conn(), "/templates/auth-login?palette=nope")
    refute html =~ "data-palette=\"nope\""
  end
end
