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

  ## Default values of attrs (#102)

  An app that wraps a component only to change a default (`card_table` with
  `selection_badge={false}` everywhere) can set it once:

      # config/config.exs
      config :ledger_ui, :defaults,
        card_table: [selection_badge: false],
        bulk_bar: [canvas: true, offset: "auto"]

  The keys are component function names, then attr names. The configured value replaces the
  `default:` of the attr only when the caller does not pass the attr (the caller's value, even
  `nil`, always wins). It is applied as the first thing the component function does, so the
  `attr` declarations (and the docs generated from them) keep the original default. It is read
  at compile time: after changing it run `mix deps.compile ledger_ui --force`. An unknown
  attr, or a `required: true` one, fails the compilation of the component. Without the config
  nothing is generated and the HTML is the same.
  """

  defmacro __using__(opts) do
    defaults = Keyword.get(opts, :defaults)

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

      @ledger_ui_defaults unquote(defaults) || Application.compile_env(:ledger_ui, :defaults, [])
      @before_compile LedgerUI.Component

      if Application.compile_env(:ledger_ui, :debug_annotations, true) == false do
        @debug_heex_annotations false
        @debug_attributes false
      end
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    configured = Module.get_attribute(env.module, :ledger_ui_defaults) || []
    components = Module.get_attribute(env.module, :__components__) || %{}

    for {name, %{kind: kind, attrs: attrs}} <- components,
        overrides = configured[name],
        overrides not in [nil, []] do
      validate_defaults!(env.module, name, attrs, overrides)
      overrides = Macro.escape(Map.new(overrides))

      quote do
        defoverridable [{unquote(name), 1}]

        Kernel.unquote(kind)(unquote(name)(assigns)) do
          super(Map.merge(unquote(overrides), assigns))
        end
      end
    end
  end

  defp validate_defaults!(module, name, attrs, overrides) do
    for {attr_name, _value} <- overrides do
      case Enum.find(attrs, &(&1.name == attr_name)) do
        nil ->
          raise ArgumentError,
                "config :ledger_ui, :defaults: #{inspect(module)}.#{name}/1 has no attr " <>
                  "#{inspect(attr_name)}"

        %{required: true} ->
          raise ArgumentError,
                "config :ledger_ui, :defaults: #{inspect(attr_name)} of " <>
                  "#{inspect(module)}.#{name}/1 is required: it has no default to replace"

        _ ->
          :ok
      end
    end
  end
end
