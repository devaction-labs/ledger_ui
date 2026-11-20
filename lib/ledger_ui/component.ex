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

  @doc """
  Declares `name/1` as an alias of the function component `target/1` of the same module, under
  the name the design vitrine uses (`progress_bar` for `progress`, ...).

  The alias declares the same attrs and slots as the target (so `__components__/0`, the compile
  time checks and the generated skill see a real component) and calls it with the assigns.
  It must come after the target's `def`.

      component_alias :progress_bar, :progress
      component_alias :sheet, :drawer, defaults: [placement: "bottom"]

  `defaults:` changes the default of attrs the alias shares with its target; `class:` is a class
  the alias always adds to the caller's `class` (`component_alias :shell_floating, :app_shell,
  class: "float"`).
  """
  defmacro component_alias(name, target, opts \\ [])
           when is_atom(name) and is_atom(target) and is_list(opts) do
    # `def` unhygienic on purpose: it must be the caller's (Phoenix.Component's) `def`
    var = {:assigns, [], nil}

    call =
      case Keyword.get(opts, :class) do
        nil ->
          {target, [], [var]}

        class ->
          {target, [],
           [
             quote do
               Map.update(
                 unquote(var),
                 :class,
                 unquote(class),
                 &LedgerUI.Helpers.cx([unquote(class), &1])
               )
             end
           ]}
      end

    def_ast = {:def, [], [{name, [], [var]}, [do: call]]}

    quote do
      LedgerUI.Component.__declare_like__(
        __MODULE__,
        unquote(target),
        __ENV__,
        unquote(Keyword.get(opts, :defaults, []))
      )

      @doc "Same component as `#{unquote(target)}/1` (same attributes and slots), under the name the design vitrine uses."
      unquote(def_ast)
    end
  end

  @doc false
  def __declare_like__(module, target, env, defaults \\ []) do
    %{attrs: attrs, slots: slots} = Module.get_attribute(module, :__components__)[target]
    decl = Phoenix.Component.Declarative

    for a <- Enum.sort_by(attrs, & &1.line) do
      decl.__attr__!(module, a.name, type(a), attr_opts(a, defaults), a.line, env.file)
    end

    for s <- Enum.sort_by(slots, & &1.line) do
      opts =
        [required: s.required] ++
          if(s.doc, do: [doc: s.doc], else: []) ++
          if(s.validate_attrs == false, do: [validate_attrs: false], else: []) ++ s.opts

      decl.__slot__!(module, s.name, opts, s.line, env.file, fn ->
        for a <- Enum.sort_by(s.attrs, & &1.line),
            do: decl.__attr__!(module, a.name, type(a), attr_opts(a, []), a.line, env.file)
      end)
    end

    :ok
  end

  # `__components__/0` keeps a struct type as `{:struct, Mod}`; `attr` takes `Mod`
  defp type(%{type: {:struct, mod}}), do: mod
  defp type(%{type: type}), do: type

  defp attr_opts(a, defaults) do
    opts =
      if Keyword.has_key?(defaults, a.name),
        do: Keyword.put(a.opts, :default, defaults[a.name]),
        else: a.opts

    opts ++
      if(a.required, do: [required: true], else: []) ++ if(a.doc, do: [doc: a.doc], else: [])
  end

  defmacro __using__(_opts) do
    # Icon cannot import itself.
    import_icon =
      if __CALLER__.module != LedgerUI.Components.Icon,
        do: quote(do: import(LedgerUI.Components.Icon))

    quote do
      use Phoenix.Component, global_prefixes: ["keep-"]
      alias Phoenix.LiveView.JS
      import LedgerUI.Helpers
      import LedgerUI.Component, only: [component_alias: 2, component_alias: 3]
      unquote(import_icon)
    end
  end
end
