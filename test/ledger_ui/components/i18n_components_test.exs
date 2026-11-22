defmodule LedgerUI.Components.I18nComponentsTest do
  @moduledoc """
  Every component with a default text renders it in Portuguese when the locale is `pt_BR` through the
  `locale` attr, the process (`LedgerUI.put_locale/1`) or the app config, and in English otherwise.
  The components whose default text was Portuguese before i18n keep it until a locale is set.
  """
  # Not async: the app config is global (the sync modules run after the async ones).
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias LedgerUI.I18nCases

  setup do
    previous = Application.get_env(:ledger_ui, :locale)
    Application.delete_env(:ledger_ui, :locale)
    LedgerUI.put_locale(nil)

    on_exit(fn ->
      LedgerUI.put_locale(nil)

      if previous,
        do: Application.put_env(:ledger_ui, :locale, previous),
        else: Application.delete_env(:ledger_ui, :locale)
    end)
  end

  defp render(mod, fun, assigns, extra \\ %{}),
    do:
      rendered_to_string(
        apply(mod, fun, [assigns |> Map.merge(extra) |> Map.put(:__changed__, nil)])
      )

  defp case!(name), do: Enum.find(I18nCases.all(), &(elem(&1, 0) == name))

  for name <- Enum.map(I18nCases.all(), &elem(&1, 0)) do
    describe name do
      test "with no locale: its default language" do
        {_, mod, fun, assigns, en, pt, default} = case!(unquote(name))
        html = render(mod, fun, assigns)
        {shown, hidden} = if default == :pt, do: {pt, en}, else: {en, pt}

        assert html =~ shown
        refute html =~ hidden
      end

      test "locale attr pt_BR" do
        {_, mod, fun, assigns, en, pt, _} = case!(unquote(name))
        html = render(mod, fun, assigns, %{locale: "pt_BR"})

        assert html =~ pt
        refute html =~ en
      end

      test "locale attr en" do
        {_, mod, fun, assigns, en, pt, _} = case!(unquote(name))
        html = render(mod, fun, assigns, %{locale: "en"})

        assert html =~ en
        refute html =~ pt
      end

      test "process locale pt_BR, and the attr wins over it" do
        {_, mod, fun, assigns, en, pt, _} = case!(unquote(name))
        LedgerUI.put_locale("pt_BR")

        assert render(mod, fun, assigns) =~ pt
        assert render(mod, fun, assigns, %{locale: "en"}) =~ en
      end

      test "app config pt_BR, and the process wins over it" do
        {_, mod, fun, assigns, en, pt, _} = case!(unquote(name))
        Application.put_env(:ledger_ui, :locale, "pt_BR")

        assert render(mod, fun, assigns) =~ pt

        LedgerUI.put_locale("en")
        assert render(mod, fun, assigns) =~ en
      end
    end
  end
end
