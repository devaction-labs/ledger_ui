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
  @exceptions %{
    "dashboard" =>
      "the line chart is responsive and its data consistent: round y ticks (0/50/…/200 mil) " <>
        "instead of the board's 60/107/153/200, October value fixed so the +12,4% header is true"
  }

  for %{slug: slug, board: board} <- Templates.pages() do
    @tag template: slug
    if reason = @exceptions[slug], do: @tag(skip: reason)

    test "#{slug} matches the Claro board" do
      {:ok, _lv, html} = live(build_conn(), "/templates/#{unquote(slug)}")
      expected = TemplateParity.board_root(unquote(board))
      actual = TemplateParity.actual_root(html)

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
end
