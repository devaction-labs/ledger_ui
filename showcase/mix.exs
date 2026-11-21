defmodule LedgerShowcase.MixProject do
  use Mix.Project

  def project do
    [
      app: :ledger_showcase,
      version: "0.1.0",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [mod: {LedgerShowcase.Application, []}, extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      # Compiles assets/css/app.css (Tailwind v4 + the ledger_ui theme) into priv/static/assets/app.css.
      "assets.build": ["tailwind ledger_showcase"],
      "assets.setup": ["tailwind.install --if-missing"]
    ]
  end

  defp deps do
    [
      {:ledger_ui, path: ".."},
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_html, "~> 4.1"},
      {:bandit, "~> 1.5"},
      {:jason, "~> 1.4"},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:lazy_html, ">= 0.1.0", only: :test}
    ]
  end
end
