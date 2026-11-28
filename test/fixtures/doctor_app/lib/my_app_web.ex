defmodule MyAppWeb do
  defp html_helpers do
    quote do
      use LedgerUI, except: [:input, :badge, :pagination]
    end
  end
end
