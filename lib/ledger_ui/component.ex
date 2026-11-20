defmodule LedgerUI.Component do
  @moduledoc """
  Boilerplate for a Ledger UI component module.

      defmodule LedgerUI.Components.Button do
        @moduledoc "..."
        use LedgerUI.Component

        attr :class, :any, default: nil
        def button(assigns), do: ~H"..."
      end

  Brings in `Phoenix.Component` (with `global_prefixes: ["keep-"]`, so the LiveView patch
  markers `keep-hidden`, `keep-class`, `keep-style`, `keep-data-*` pass through `:global`),
  the `JS` alias, `LedgerUI.Helpers` (`cx/1`, ...) and `LedgerUI.Components.Icon` (`<.icon>`).
  """

  defmacro __using__(_opts) do
    # Icon cannot import itself.
    import_icon =
      if __CALLER__.module != LedgerUI.Components.Icon,
        do: quote(do: import(LedgerUI.Components.Icon))

    quote do
      use Phoenix.Component, global_prefixes: ["keep-"]
      alias Phoenix.LiveView.JS
      import LedgerUI.Helpers
      unquote(import_icon)
    end
  end
end
