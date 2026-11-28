defmodule LedgerUI.MixProject do
  use Mix.Project

  @version "0.12.1"
  @source_url "https://github.com/devaction-labs/ledger_ui"

  def project do
    [
      app: :ledger_ui,
      version: @version,
      elixir: "~> 1.20",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Phoenix LiveView components with the Ledger UI design.",
      package: package(),
      docs: docs(),
      name: "LedgerUI",
      source_url: @source_url
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.8"},
      lv_dep(),
      {:phoenix_html, "~> 4.1"},
      {:jason, "~> 1.4"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  # CI sets LEDGER_UI_LV_VERSION (e.g. "1.2.13") to test the declared floor of LiveView.
  # LEDGER_UI_LV_GIT (a branch or tag, e.g. "main") swaps the Hex package for that ref of the
  # LiveView repository: the scheduled job `lv-main.yml` uses it. Never set it for a release.
  defp lv_dep do
    case System.get_env("LEDGER_UI_LV_GIT") do
      ref when ref in [nil, ""] ->
        {:phoenix_live_view, lv_requirement()}

      ref ->
        {:phoenix_live_view,
         github: "phoenixframework/phoenix_live_view", branch: ref, override: true}
    end
  end

  defp lv_requirement do
    case System.get_env("LEDGER_UI_LV_VERSION") do
      v when v in [nil, ""] -> "~> 1.2 and >= 1.2.13"
      v -> v
    end
  end

  defp package do
    [
      licenses: ["MIT"],
      files:
        ~w(lib priv assets guides mix.exs package.json README.md LICENSE CHANGELOG.md UPGRADING.md),
      links: %{"GitHub" => @source_url},
      maintainers: ["Alex Nogueira"]
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: ["README.md", "guides/liveview-eficiente.md", "guides/shell-live.md", "UPGRADING.md", "CHANGELOG.md"]
    ]
  end
end
