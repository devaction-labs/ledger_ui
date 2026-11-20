defmodule LedgerShowcaseWebTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint LedgerShowcaseWeb.Endpoint

  alias LedgerShowcase.Vitrine

  test "intro lists groups, cards and the sidebar index" do
    {:ok, _lv, html} = live(build_conn(), "/")
    assert html =~ "Ledger UI"
    assert html =~ ~s(href="/c/icon")
    assert html =~ "d-ghead"
    assert html =~ "01 · Fundamentos"
    assert html =~ "d-nw"
    assert html =~ ~s(id="pal")
    assert html =~ ~s(phx-hook="ShowcasePage")
  end

  test "static pages render" do
    for {path, text} <- [
          {"/instalacao", "import {Hooks, DOM} from"},
          {"/cores", "--bg-page"},
          {"/temas", "data-theme"},
          {"/novidades", "Novidades"}
        ] do
      {:ok, _lv, html} = live(build_conn(), path)
      assert html =~ text, "#{path} missing #{text}"
    end
  end

  test "every NAV id renders its page" do
    assert length(Vitrine.all()) == Vitrine.count()

    for %{id: id, name: name} <- Vitrine.all() do
      {:ok, _lv, html} = live(build_conn(), "/c/#{id}")
      assert html =~ ~s(<h1>#{name}</h1>), "#{id} title"
      assert html =~ "d-crumb"
      assert html =~ ~s(id="x-uso")
      assert html =~ ~s(id="toc")
    end
  end

  test "sections with examples are live, the others fall back to static html" do
    {:ok, _lv, html} = live(build_conn(), "/c/icon")
    assert html =~ ~s(data-icon="download")
    refute html =~ "data-static"

    {:ok, _lv, html} = live(build_conn(), "/c/button")

    case LedgerShowcase.Examples.sections("button") do
      [] -> assert html =~ "prévia estática" and html =~ "data-static"
      _ -> assert html =~ ".heex"
    end
  end

  test "navigating by patch keeps the shell" do
    {:ok, lv, _html} = live(build_conn(), "/")
    html = lv |> element(~s(.d-lst a[href="/c/icon"])) |> render_click()
    assert html =~ ~s(<h1>Icon</h1>)
    assert_patch(lv, "/c/icon")
  end

  test "unknown component id redirects home" do
    assert {:error, {:live_redirect, %{to: "/"}}} = live(build_conn(), "/c/nope")
  end

  test "fullscreen renders the examples alone" do
    {:ok, _lv, html} = live(build_conn(), "/full/icon")
    assert html =~ ~s(data-icon="download")
    refute html =~ "d-top"

    {:ok, _lv, html} = live(build_conn(), "/full/button")
    assert html =~ "d-ex"
  end

  test "root layout has theme bootstrap and legacy hash redirect" do
    html = build_conn() |> get("/") |> html_response(200)
    assert html =~ "lu-theme"
    assert html =~ "location.replace"
    assert html =~ ~s(id="d-search")
  end

  test "component page lists the remaining vitrine sections then the canvas-only demos (TOC included)" do
    {:ok, _lv, html} = live(build_conn(), "/c/hero-card")
    assert html =~ ~s(id="x-3")
    assert html =~ "sem arte"

    page = LedgerShowcase.Vitrine.page("stat")
    assert length(page.sections) == 5

    assert Enum.at(page.sections, 0).t ==
             "Os números sobem, a linha se desenha e a variação aparece"
  end
end
