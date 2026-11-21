defmodule LedgerUI.MixProject do
  use Mix.Project

  @version "0.5.7"
  @source_url "https://github.com/devaction-labs/ledger_ui"

  def project do
    [
      app: :ledger_ui,
      version: @version,
      elixir: "~> 1.16",
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
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_html, "~> 4.1"},
      {:jason, "~> 1.4"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      files: ~w(lib priv assets mix.exs package.json README.md LICENSE CHANGELOG.md),
      links: %{"GitHub" => @source_url},
      maintainers: ["Alex Nogueira"]
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end
end
