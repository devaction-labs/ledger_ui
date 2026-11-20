defmodule LedgerUI.Helpers do
  @moduledoc """
  Small helpers shared by all components.
  """

  @doc """
  Joins class values into a single string, dropping empties.

  Accepts strings, `nil`, `false`, `{class, condition}` tuples and nested lists.

      iex> LedgerUI.Helpers.cx(["lu-btn", nil, false, {"on", true}, {"off", false}, ["a", " "], "b  c"])
      "lu-btn on a b c"

      iex> LedgerUI.Helpers.cx([nil])
      ""
  """
  @spec cx(term()) :: String.t()
  def cx(list) do
    list
    |> flatten()
    |> Enum.join(" ")
  end

  defp flatten(list) when is_list(list), do: Enum.flat_map(list, &flatten/1)
  defp flatten({class, cond}), do: if(cond in [nil, false], do: [], else: flatten(class))
  defp flatten(class) when is_binary(class), do: String.split(class, ~r/\s+/, trim: true)

  defp flatten(class) when is_atom(class) and class not in [nil, true, false],
    do: [Atom.to_string(class)]

  defp flatten(_), do: []

  @doc """
  Renders a boolean as the strings `"true"` / `"false"` (for `aria-*` attributes).

      iex> LedgerUI.Helpers.bool_attr(true)
      "true"
      iex> LedgerUI.Helpers.bool_attr(nil)
      "false"
  """
  @spec bool_attr(term()) :: String.t()
  def bool_attr(value) when value in [nil, false], do: "false"
  def bool_attr(_), do: "true"
end
