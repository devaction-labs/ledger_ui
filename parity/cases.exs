# Driver do lado HEEx + Tailwind: carrega parity/cases/*.exs (um módulo `Parity.Cases.<Grupo>` com
# `cases/0 :: %{id => rendered}` por arquivo) e escreve JSON {id: html} em $OUT.
# Cada lote de componentes adiciona o SEU arquivo; ninguém edita este driver.
defmodule Parity.Common do
  use Phoenix.Component

  def row(assigns) do
    ~H"""
    <div style="display:flex;gap:10px;align-items:center;flex-wrap:wrap">{render_slot(@inner_block)}</div>
    """
  end

  def colm(assigns) do
    ~H"""
    <div style="display:flex;flex-direction:column;gap:14px">{render_slot(@inner_block)}</div>
    """
  end
end

here = __DIR__

mods =
  Path.wildcard(Path.join(here, "cases/*.exs"))
  |> Enum.sort()
  |> Enum.flat_map(fn f -> f |> Code.require_file() |> Enum.map(&elem(&1, 0)) end)
  |> Enum.filter(&function_exported?(&1, :cases, 0))

mods
|> Enum.reduce(%{}, fn mod, acc ->
  new = mod.cases()
  dup = Map.keys(new) |> Enum.filter(&Map.has_key?(acc, &1))
  if dup != [], do: raise("ids de caso repetidos em #{inspect(mod)}: #{inspect(dup)}")
  Map.merge(acc, new)
end)
|> Map.new(fn {k, r} -> {k, r |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()} end)
|> Jason.encode!()
|> then(&File.write!(System.get_env("OUT", "/tmp/parity_heex.json"), &1))
