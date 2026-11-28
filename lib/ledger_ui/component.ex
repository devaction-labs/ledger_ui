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

  ## Debug annotations

  An app that turns on `:debug_heex_annotations` / `:debug_attributes` of `:phoenix_live_view`
  (the Phoenix 1.8 generator does in dev) gets comments and `data-phx-loc` from inside the kit too.
  To leave the kit out of them:

      # config/dev.exs
      config :ledger_ui, debug_annotations: false

  The default follows `:phoenix_live_view`. It is read at compile time: after changing it run
  `mix deps.compile ledger_ui --force`.
  """

  defmacro __using__(_opts) do
    # Icon cannot import itself.
    import_icon =
      if __CALLER__.module != LedgerUI.Components.Icon,
        do: quote(do: import(LedgerUI.Components.Icon))

    quote do
      use Phoenix.Component, global_prefixes: ["keep-"]
      alias Phoenix.LiveView.JS
      alias LedgerUI.I18n
      import LedgerUI.Helpers
      unquote(import_icon)

      if Application.compile_env(:ledger_ui, :debug_annotations, true) == false do
        @debug_heex_annotations false
        @debug_attributes false
      end
    end
  end
end
