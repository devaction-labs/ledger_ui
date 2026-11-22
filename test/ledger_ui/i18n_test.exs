defmodule LedgerUI.I18nTest do
  # Not async: the app config and the process dictionary are global state.
  use ExUnit.Case, async: false

  alias LedgerUI.I18n

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

  describe "normalize/1" do
    test "pt, pt-BR, pt_br and :pt_BR are pt_BR; anything else is en" do
      for l <- ["pt", "pt_BR", "pt-BR", "pt_br", "PT-br", :pt_BR, :pt] do
        assert I18n.normalize(l) == "pt_BR"
      end

      for l <- ["en", "en-US", "fr", "", :en, 42] do
        assert I18n.normalize(l) == "en"
      end

      assert I18n.normalize(nil) == nil
    end
  end

  describe "locale/1: attr > process > app config > en" do
    test "en with nothing set" do
      assert I18n.locale() == "en"
      assert I18n.locale(nil) == "en"
    end

    test "the app config" do
      Application.put_env(:ledger_ui, :locale, "pt_BR")
      assert I18n.locale() == "pt_BR"
      assert I18n.t("common.close") == "Fechar"
    end

    test "the process wins over the config" do
      Application.put_env(:ledger_ui, :locale, "pt_BR")
      LedgerUI.put_locale("en")
      assert I18n.locale() == "en"
      assert LedgerUI.get_locale() == "en"
    end

    test "the attr wins over the process and the config" do
      Application.put_env(:ledger_ui, :locale, "en")
      LedgerUI.put_locale("en")
      assert I18n.locale("pt_BR") == "pt_BR"
      assert I18n.t("common.close", "pt_BR") == "Fechar"
    end

    test "put_locale(nil) goes back to the config" do
      Application.put_env(:ledger_ui, :locale, "pt_BR")
      LedgerUI.put_locale("en")
      LedgerUI.put_locale(nil)
      assert LedgerUI.get_locale() == nil
      assert I18n.locale() == "pt_BR"
    end

    test "the process locale does not leak to another process" do
      LedgerUI.put_locale("pt_BR")
      assert Task.async(fn -> I18n.locale() end) |> Task.await() == "en"
    end

    test "a fallback for the components whose default is Portuguese" do
      assert I18n.locale(nil, "pt_BR") == "pt_BR"
      assert I18n.tp("common.remove") == "Remover"
      assert I18n.tp("common.remove", "en") == "Remove"

      LedgerUI.put_locale("en")
      assert I18n.tp("common.remove") == "Remove"
    end
  end

  describe "t/3" do
    test "bindings, as a keyword list or a map" do
      assert I18n.t("pagination.page", "en", page: 3) == "Page 3"
      assert I18n.t("pagination.page", "pt_BR", %{page: 3}) == "Página 3"
      assert I18n.t("bulk_bar.select_all", "pt_BR", total: 10) == "Selecionar todos (10)"
    end

    test "a binding that is not given stays as it is" do
      assert I18n.t("pagination.page", "en") == "Page %{page}"
    end

    test "an unknown key is the key" do
      assert I18n.t("nope.nothing", "pt_BR") == "nope.nothing"
    end
  end

  describe "list/2 and labels/2" do
    test "months and weekdays" do
      assert I18n.list("date.months", "en") |> Enum.at(2) == "March"
      assert I18n.list("date.months", "pt_BR") |> Enum.at(2) == "Março"
      assert I18n.list("date.weekdays", "pt_BR") |> hd() == "Domingo"
      assert length(I18n.list("date.weekdays", "en")) == 7
    end

    test "labels are an atom-keyed map" do
      assert %{signature_draw: "Draw"} = I18n.labels("signature", "en")
      assert %{signature_draw: "Desenhar"} = I18n.labels("signature", "pt_BR")
    end
  end

  describe "texts/3" do
    test "fills the nil attrs, keeps the given ones (also the empty string)" do
      out =
        I18n.texts(%{a: nil, b: "mine", c: "", locale: "pt_BR"},
          a: "common.close",
          b: "common.close",
          c: "common.close"
        )

      assert out.a == "Fechar"
      assert out.b == "mine"
      assert out.c == ""
    end

    test "uses the process locale when the assigns have no locale" do
      LedgerUI.put_locale("pt_BR")
      assert I18n.texts(%{a: nil}, a: "common.close").a == "Fechar"
    end

    test "{:pt, key} is Portuguese until a locale is set" do
      assert I18n.texts(%{a: nil}, a: {:pt, "common.close"}).a == "Fechar"
      assert I18n.texts(%{a: nil, locale: "en"}, a: {:pt, "common.close"}).a == "Close"
    end

    test "marks the filled text as changed when the locale attr changed" do
      out =
        I18n.texts(%{a: nil, locale: "pt_BR", __changed__: %{locale: true}}, a: "common.close")

      assert out.__changed__[:a]
    end

    test "a sentinel for the attrs where nil means none" do
      assert I18n.texts(%{a: :default}, [a: "common.close"], :default).a == "Close"
      assert I18n.texts(%{a: nil}, [a: "common.close"], :default).a == nil
    end
  end

  describe "non_default/2" do
    test "nil for the English text of the key, the text otherwise" do
      assert I18n.non_default("Close", "common.close") == nil
      assert I18n.non_default("Fechar", "common.close") == "Fechar"
      assert I18n.non_default("", "common.close") == ""
    end
  end

  describe "on_mount" do
    test "reads the locale of the session" do
      assert {:cont, :socket} = I18n.on_mount(:default, %{}, %{"locale" => "pt-BR"}, :socket)
      assert LedgerUI.get_locale() == "pt_BR"
    end

    test "leaves the locale alone without one in the session" do
      assert {:cont, :socket} = I18n.on_mount(:default, %{}, %{}, :socket)
      assert LedgerUI.get_locale() == nil
    end

    test "a fixed locale" do
      assert {:cont, :socket} = I18n.on_mount({:locale, "pt_BR"}, %{}, %{}, :socket)
      assert LedgerUI.get_locale() == "pt_BR"
    end
  end

  describe "the translations" do
    @en LedgerUI.I18n.En.messages()
    @pt LedgerUI.I18n.PtBR.messages()

    test "every key is in both languages" do
      assert Map.keys(@en) -- Map.keys(@pt) == []
      assert Map.keys(@pt) -- Map.keys(@en) == []
    end

    test "both languages have the same bindings and the same list sizes" do
      for {key, en} <- @en do
        pt = Map.fetch!(@pt, key)

        case {en, pt} do
          {l1, l2} when is_list(l1) ->
            assert length(l1) == length(l2), key

          {m1, m2} when is_map(m1) ->
            assert Map.keys(m1) |> Enum.sort() == Map.keys(m2) |> Enum.sort(), key

          {t1, t2} ->
            assert bindings(t1) == bindings(t2), key
        end
      end
    end

    test "the keys the components use exist" do
      known = MapSet.new(Map.keys(@en))

      used =
        for file <- Path.wildcard("lib/ledger_ui/components/**/*.ex"),
            [_, key] <- Regex.scan(~r/"([a-z_]+\.[a-z_0-9.\-]+)"/, File.read!(file)),
            # a module, a file or an icon name, not a translation key
            not String.ends_with?(key, [".ex", ".exs", ".js", ".css", ".png", ".svg", ".jpg"]),
            not String.starts_with?(key, ["phoenix.", "lu.", "tooltip.", "yaxis.", "mix."]),
            do: {Path.basename(file), key}

      missing =
        for {file, key} <- Enum.uniq(used), not MapSet.member?(known, key), do: "#{file}: #{key}"

      # keys built from a state or a tool name ("error_page.\#{code}.title") are checked by the components test
      assert missing == []
    end
  end

  defp bindings(text),
    do:
      ~r/%\{(\w+)\}/ |> Regex.scan(text, capture: :all_but_first) |> List.flatten() |> Enum.sort()
end
