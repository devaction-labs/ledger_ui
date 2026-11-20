defmodule LedgerShowcase.TemplatesParityTest do
  @moduledoc """
  Each template (`/templates/:slug`) in its initial state against the canvas board (Claro), and the
  Escuro board against the Claro one. See `LedgerShowcase.TemplateParity` for the normalization
  and the documented exceptions.

      mix test test/templates_parity_test.exs
  """
  use ExUnit.Case, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint LedgerShowcaseWeb.Endpoint

  alias LedgerShowcase.{TemplateParity, Templates}

  # Documented divergences from the board (the canvas board is a static mock).
  #
  # `dashboard`: the line chart is responsive and its data consistent (round y ticks 0/50/…/200 mil
  # instead of the board's 60/107/153/200, October fixed so the +12,4% header is true); the chart
  # and its head are emptied on both sides (`TemplateParity.without_chart/1`), the rest is compared.
  @chart_slugs ["dashboard"]

  defp prep(trees, slug) do
    if slug in @chart_slugs, do: TemplateParity.without_chart(trees), else: trees
  end

  # MIGRATION (Tailwind): these pages render `input`/`field`, already migrated to utility classes, which
  # no longer emit the `lu-input`/`lu-field`/`lu-label` classes and structure this class-based comparison
  # (`TemplateParity`) normalizes. Pixel parity of the components is checked by `python parity/run.py`;
  # re-enable each slug (removing it here) when the Templates batch migrates the page. See MIGRATION.md.
  @migrated "input/field migrated to Tailwind (see MIGRATION.md): re-enable with the Templates batch"
  @exceptions Map.new(
                ~w(auth-login auth-login-erro auth-cadastro auth-codigo auth-senha tabela-modal),
                &{&1, @migrated}
              )

  for %{slug: slug, board: board} <- Templates.pages(), slug != "tabela-app" do
    @tag template: slug
    if reason = @exceptions[slug], do: @tag(skip: reason)

    test "#{slug} matches the Claro board" do
      {:ok, _lv, html} = live(build_conn(), "/templates/#{unquote(slug)}")
      expected = TemplateParity.board_root(unquote(board)) |> prep(unquote(slug))
      actual = TemplateParity.actual_root(html) |> prep(unquote(slug))

      case TemplateParity.compare(expected, actual, unquote(slug)) do
        :ok -> :ok
        {:error, report} -> flunk(report)
      end
    end

    @tag template: slug
    test "#{slug}: the Escuro board is the Claro markup with data-theme dark" do
      assert TemplateParity.board_theme(unquote(board), :claro) == "light"
      assert TemplateParity.board_theme(unquote(board), :escuro) == "dark"

      case TemplateParity.compare(
             TemplateParity.board_root(unquote(board)),
             TemplateParity.board_root(unquote(board), :escuro),
             unquote(slug) <> " (claro vs escuro)"
           ) do
        :ok -> :ok
        {:error, report} -> flunk(report)
      end
    end
  end

  # Every template page of `t/index.json` against the vitrine's own page (`design/vitrine/t/<slug>.html`).
  # `tabela-app` has no canvas board (the interactive page), so this is where it is checked.
  for %{slug: slug} <- Templates.pages() do
    @tag template: slug
    if reason = @exceptions[slug], do: @tag(skip: reason)

    test "#{slug} matches the vitrine page t/#{slug}.html" do
      {:ok, _lv, html} = live(build_conn(), "/templates/#{unquote(slug)}")

      case TemplateParity.compare(
             TemplateParity.vitrine_root(unquote(slug)) |> prep(unquote(slug)),
             TemplateParity.actual_root(html) |> prep(unquote(slug)),
             unquote(slug) <> " (vitrine)"
           ) do
        :ok -> :ok
        {:error, report} -> flunk(report)
      end
    end
  end

  test "the index lists the templates of t/index.json, same order and titles" do
    index =
      Path.expand("../../design/vitrine/t/index.json", __DIR__)
      |> File.read!()
      |> Jason.decode!()

    assert Enum.map(Templates.pages(), &{&1.slug, &1.title, &1.h}) ==
             Enum.map(index, &{&1["slug"], &1["title"], &1["h"]})

    {:ok, _lv, html} = live(build_conn(), "/templates")

    shown =
      Regex.scan(~r/id="tpl-card-([a-z-]+)"[^>]*>.*?<b>([^<]*)<\/b>/s, html)
      |> Enum.map(fn [_, slug, title] -> {slug, title} end)

    for %{"slug" => slug, "title" => title} <- index do
      assert {slug, title} in shown, "#{slug} (#{title}) is not on /templates"
    end

    assert shown |> Enum.take(length(index)) |> Enum.map(&elem(&1, 0)) ==
             Enum.map(index, & &1["slug"])
  end

  # The Crepúsculo variants (`?palette=crepusculo`) against the `TCrep*` boards (the same markup as
  # the Ledger boards: the palette is only `data-palette`) and the palette page.
  for %{path: path, board: board, slug: slug, palette: palette} <- Templates.palette_pages() do
    @tag template: slug, palette: palette
    if reason = @exceptions[slug], do: @tag(skip: reason)

    test "#{path} matches the #{board}Claro board" do
      {:ok, _lv, html} = live(build_conn(), unquote(path))

      assert html =~ ~s(data-palette="#{unquote(palette)}")
      expected = TemplateParity.board_root(unquote(board)) |> prep(unquote(slug))
      actual = TemplateParity.actual_root(html) |> prep(unquote(slug))

      case TemplateParity.compare(expected, actual, unquote(path)) do
        :ok -> :ok
        {:error, report} -> flunk(report)
      end
    end

    @tag template: slug, palette: palette
    test "#{path}: the #{board}Escuro board is the Claro markup in data-theme dark and data-palette #{palette}" do
      for {theme, expect} <- [claro: "light", escuro: "dark"] do
        assert TemplateParity.board_theme(unquote(board), theme) == expect
        assert TemplateParity.board_palette(unquote(board), theme) == unquote(palette)
      end

      assert :ok ==
               TemplateParity.compare(
                 TemplateParity.board_root(unquote(board)),
                 TemplateParity.board_root(unquote(board), :escuro),
                 unquote(path) <> " (claro vs escuro)"
               )
    end
  end

  test "?palette= is applied on the template root; an unknown palette is ignored" do
    {:ok, _lv, html} = live(build_conn(), "/templates/auth-login?palette=crepusculo")
    assert html =~ ~s(data-palette="crepusculo")
    {:ok, _lv, html} = live(build_conn(), "/templates/auth-login?palette=nope")
    refute html =~ "data-palette=\"nope\""
    {:ok, _lv, html} = live(build_conn(), "/templates/auth-login")
    refute html =~ ~s(id="tpl" data-template="auth-login" data-palette)
  end
end
