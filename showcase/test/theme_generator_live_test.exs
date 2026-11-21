defmodule LedgerShowcaseWeb.ThemeGeneratorLiveTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint LedgerShowcaseWeb.Endpoint

  test "/temas shows the generator above the ready palettes" do
    {:ok, _lv, html} = live(build_conn(), "/temas")
    assert html =~ "Faça o seu tema"
    assert html =~ "Tema do seu projeto"
    assert html =~ "Tema padrão do Ledger"
    {a, _} = :binary.match(html, "Faça o seu tema")
    {b, _} = :binary.match(html, "Paletas prontas")
    assert a < b
  end

  test "accent, gray and mode events repaint the section and rebuild the CSS" do
    {:ok, lv, _} = live(build_conn(), "/temas")

    assert render(lv) =~ ~s(data-mode="light")

    lv |> element(~s([data-part=tg-accents] button[phx-value-id=fuchsia])) |> render_click()
    lv |> element(~s([data-part=tg-grays] button[phx-value-id=slate])) |> render_click()
    html = lv |> element(~s([data-part=tg-mode] button[phx-value-mode=dark])) |> render_click()

    assert html =~ ~s(data-theme="dark")
    assert html =~ "--color-accent:oklch(59.1% 0.293 322.896)"
    assert html =~ "--color-gray-50:oklch(98.4% 0.003 247.858)"
    assert html =~ "--color-fuchsia-400"
    assert html =~ "--color-slate-950"
  end

  test "unknown ids are ignored" do
    {:ok, lv, _} = live(build_conn(), "/temas")
    render_hook(lv, "tg_restore", %{"acc" => "nope", "gray" => "x", "mode" => "blue"})
    assert render(lv) =~ ~s(data-acc="base")
    render_hook(lv, "tg_restore", %{"acc" => "pink", "gray" => "mist", "mode" => "dark"})
    assert render(lv) =~ ~s(data-acc="pink")
  end
end
