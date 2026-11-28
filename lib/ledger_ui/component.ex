defmodule LedgerUI.Component do
  @moduledoc """
  Boilerplate for a Ledger UI component module.

      defmodule LedgerUI.Components.Button do
        @moduledoc "..."
        use LedgerUI.Component

        attr :class, :any, default: nil
        def button(assigns), do: ~H"..."
      end

  Brings in `Phoenix.Component` (with `global_prefixes: ["keep-"]`: the `keep-*` markers of the earlier
  versions, a no-op now, still compile when an app passes them through `:global`),
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

  ## Event attrs that are only an event name (#119)

  A module that sets `@ledger_ui_event_guard true` before its components makes every `on_*` attr
  declared `:string` raise an `ArgumentError` when it receives a `%Phoenix.LiveView.JS{}` (the hook
  reads the value as an event name and would push an event named after the JSON). Attrs declared
  `:any` accept a `JS` command and are not guarded.
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
    guard? = Module.get_attribute(env.module, :ledger_ui_event_guard) == true
    components = Module.get_attribute(env.module, :__components__) || %{}

    for {name, %{kind: kind, attrs: attrs}} <- components,
        overrides = configured[name] || [],
        guarded = if(guard?, do: event_attrs(attrs), else: []),
        overrides != [] or guarded != [] do
      validate_defaults!(env.module, name, attrs, overrides)
      overrides = Macro.escape(Map.new(overrides))
      module = env.module

      quote do
        defoverridable [{unquote(name), 1}]

        Kernel.unquote(kind)(unquote(name)(assigns)) do
          LedgerUI.Component.__reject_js__!(
            assigns,
            unquote(guarded),
            unquote(module),
            unquote(name)
          )

          super(Map.merge(unquote(overrides), assigns))
        end
      end
    end
  end

  # `on_*` attrs declared `:string`: the hook reads the value as an event name.
  defp event_attrs(attrs) do
    for %{name: name, type: :string} <- attrs,
        String.starts_with?(Atom.to_string(name), "on_"),
        do: name
  end

  @doc false
  # #119: an `on_*` attr declared `:string` is read by its hook as an event name, so a `%JS{}` used
  # to render as JSON in `data-lu-on-*` and the hook pushed an event with that JSON as its name.
  def __reject_js__!(_assigns, [], _module, _name), do: :ok

  def __reject_js__!(assigns, attrs, module, name) do
    for attr <- attrs, match?(%Phoenix.LiveView.JS{}, Map.get(assigns, attr)) do
      raise ArgumentError,
            "#{inspect(module)}.#{name}/1: `#{attr}` takes a LiveView event name (a string), " <>
              "not a %Phoenix.LiveView.JS{}. Use `JS.push` in a handle_event that receives the " <>
              "event, or pass the event name"
    end

    :ok
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
