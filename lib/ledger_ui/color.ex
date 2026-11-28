defmodule LedgerUI.Color do
  @moduledoc """
  Paleta semântica compartilhada (Button, Badge, Card, Avatar…). `light` is `white`; `current` follows the text colour of the parent.

  ## Aliases (#102)

  An app that calls the semantic colours by other names (`danger` for `error`) can declare them
  once, instead of wrapping every component:

      # config/config.exs
      config :ledger_ui, :color_aliases, %{"danger" => "error"}

  Each alias is added to `names/0` (so `values:` of `color` attrs accept it) and resolves to the
  colour it points at in `vars/1` and `resolve/1`. It is read at compile time: after changing it
  run `mix deps.compile ledger_ui --force`. Without the config nothing changes: no alias exists
  and the HTML is the same. An alias must point at a colour of the palette (checked at compile
  time) and cannot shadow one. Components that compare the colour name with a literal
  (`color == "error"`) only see aliases where they call `resolve/1`.

  Cada cor define quatro variáveis locais lidas pelas variantes:
  `--c` (cheia), `--c-on` (texto sobre a cheia), `--c-soft` (fundo suave) e `--c-ink` (texto colorido).
  """

  @colors %{
    "neutral" =>
      "[--c:var(--lu-ink)] [--c-on:var(--lu-on-inverse)] [--c-soft:var(--lu-bg-sunken)] [--c-ink:var(--lu-ink)]",
    "primary" =>
      "[--c:var(--color-accent)] [--c-on:var(--color-accent-foreground)] [--c-soft:var(--lu-accent-soft)] [--c-ink:var(--color-accent-content)]",
    "secondary" =>
      "[--c:var(--lu-violet)] [--c-on:#fff] dark:[--c-on:#0e100f] [--c-soft:var(--lu-violet-soft)] [--c-ink:var(--lu-violet)]",
    "info" =>
      "[--c:var(--lu-info)] [--c-on:#fff] dark:[--c-on:#0e100f] [--c-soft:var(--lu-info-soft)] [--c-ink:var(--lu-info)]",
    "success" =>
      "[--c:var(--lu-pos)] [--c-on:#fff] dark:[--c-on:#0e100f] [--c-soft:var(--lu-pos-soft)] [--c-ink:var(--lu-pos)]",
    "warning" =>
      "[--c:var(--lu-warn)] [--c-on:#fff] dark:[--c-on:#0e100f] [--c-soft:var(--lu-warn-soft)] [--c-ink:var(--lu-warn)]",
    "error" =>
      "[--c:var(--lu-neg)] [--c-on:#fff] dark:[--c-on:#0e100f] [--c-soft:var(--lu-neg-soft)] [--c-ink:var(--lu-neg)]",
    "dark" =>
      "[--c:#141514] dark:[--c:#f2f3f2] [--c-on:#fff] dark:[--c-on:#141514] [--c-soft:#2a2e2c] [--c-ink:#141514] dark:[--c-ink:#f2f3f2]",
    "white" => "[--c:#fff] [--c-on:#141514] [--c-soft:#f4f4f2] [--c-ink:#141514]",
    "lime" =>
      "[--c:var(--lu-lime)] [--c-on:#0e100f] [--c-soft:var(--lu-lime-soft)] [--c-ink:var(--lu-lime)]",
    "light" => "[--c:#fff] [--c-on:#141514] [--c-soft:#f4f4f2] [--c-ink:#141514]",
    "mono" =>
      "[--c:var(--lu-ink)] [--c-on:var(--lu-bg-page)] [--c-soft:var(--lu-bg-sunken)] [--c-ink:var(--lu-ink)]",
    "current" =>
      "[--c:currentColor] [--c-on:var(--lu-bg-page)] [--c-soft:transparent] [--c-ink:currentColor]"
  }

  @aliases Application.compile_env(:ledger_ui, :color_aliases, %{})

  for {alias_name, target} <- @aliases do
    cond do
      not is_binary(alias_name) or not is_binary(target) ->
        raise ArgumentError,
              "config :ledger_ui, :color_aliases must map strings to strings, got " <>
                inspect({alias_name, target})

      Map.has_key?(@colors, alias_name) ->
        raise ArgumentError,
              "config :ledger_ui, :color_aliases: #{inspect(alias_name)} is already a colour"

      not Map.has_key?(@colors, target) ->
        raise ArgumentError,
              "config :ledger_ui, :color_aliases: #{inspect(alias_name)} points at " <>
                "#{inspect(target)}, which is not a colour (#{inspect(Map.keys(@colors))})"

      true ->
        :ok
    end
  end

  def names, do: Map.keys(@colors) ++ Map.keys(@aliases)

  @doc "The palette name for `color`: an alias of `:color_aliases` becomes its target."
  def resolve(color), do: resolve(color, @aliases)

  @doc false
  def resolve(color, aliases) when is_map(aliases), do: Map.get(aliases, color, color)

  def vars(color), do: Map.fetch!(@colors, resolve(color))
end
