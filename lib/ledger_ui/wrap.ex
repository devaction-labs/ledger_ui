defmodule LedgerUI.Wrap do
  @moduledoc """
  Wraps a Ledger UI component in an app component without losing the change tracking of the
  LiveView (#102).

  A wrapper written in HEEx that spreads its attributes into a kit component,

      def status_badge(assigns) do
        ~H"<.badge variant="soft" color={@color} {@rest}>{render_slot(@inner_block)}</.badge>"
      end

  makes the LiveView hand `__changed__: nil` to `badge/1` (a dynamic `{@rest}` turns change
  tracking off): to the kit everything changed, so each render sends the classes, the header and,
  when there is a list, every row again. The HTML is the same, only the diff grows (a badge text
  change goes from 28 B to 403 B, a `card_table` of 25 rows from 975 B to 81 KB).

  Calling the component as a function keeps the `__changed__` that the wrapper received.
  `call/3` does that and also renames, derives and spreads attributes, marking in `__changed__`
  only the keys whose source changed:

      def status_badge(assigns) do
        LedgerUI.Wrap.call(assigns, &LedgerUI.Components.Badge.badge/1,
          put: [variant: {:from, [:color], (assigns.color && "soft") || "outline"}],
          map: [color: {:color, &kit_color/1}],
          rename: [expanded: :row_expanded],
          spread: :rest
        )
      end

  Options:

    * `:put` - `[key: value]`. A plain `value` is fixed for the call site: the key is marked as
      changed only if the wrapper received an assign with that same name as changed. A value that
      depends on assigns of the wrapper is written `{:from, [source, ...], value}`: the key is
      marked as changed when the caller changed any of the sources. Listing too few sources leaves
      the value stale on the client.
    * `:map` - `[kit_attr: {wrapper_attr, fun}]`. `kit_attr` receives `fun.(assigns.wrapper_attr)`
      and is marked as changed when `wrapper_attr` is. `fun` must be pure (it can be an anonymous
      function: it is only called, never kept in the assigns).
    * `:rename` - `[wrapper_attr: :kit_attr]`. The value moves to the kit name (the wrapper name
      is removed); the new key is marked as changed when the old one is.
    * `:spread` - the name of the `:global` attr of the wrapper (`:rest`). Its entries become
      attrs of the kit component and are marked as changed when the rest is.

  With `__changed__: nil` (first render, a caller that spreads a map) nothing is tracked and the
  kit gets `nil` too, as without the wrapper. Do not use `{@rest}` / `{assigns}` on a kit
  component inside a wrapper; call this function.
  """

  @doc """
  Calls `fun` (a component function of the kit) with the assigns of the wrapper changed by `opts`,
  preserving `__changed__`. See the module doc for the options.
  """
  @spec call(map(), (map() -> term()), keyword()) :: term()
  def call(assigns, fun, opts \\ []) when is_map(assigns) and is_function(fun, 1) do
    original = assigns
    changed = Map.get(assigns, :__changed__)

    {assigns, marks} =
      {assigns, []}
      |> spread(opts[:spread], original, changed)
      |> rename(opts[:rename] || [], original, changed)
      |> map(opts[:map] || [], original, changed)
      |> put(opts[:put] || [], original, changed)

    changed = if is_map(changed), do: changed |> remove_dropped(opts) |> add_marks(marks)

    fun.(Map.put(assigns, :__changed__, changed))
  end

  defp spread({assigns, marks}, nil, _original, _changed), do: {assigns, marks}

  defp spread({assigns, marks}, key, original, changed) do
    rest = Map.get(original, key) || %{}
    rest_changed? = is_map(changed) and Map.has_key?(changed, key)
    keys = if rest_changed?, do: Map.keys(rest), else: []
    {assigns |> Map.delete(key) |> Map.merge(rest), keys ++ marks}
  end

  defp rename({assigns, marks}, renames, original, changed) do
    Enum.reduce(renames, {assigns, marks}, fn {from, to}, {assigns, marks} ->
      if Map.has_key?(original, from) do
        assigns = assigns |> Map.delete(from) |> Map.put(to, Map.fetch!(original, from))
        {assigns, if(tracked?(changed, [from]), do: [to | marks], else: marks)}
      else
        {assigns, marks}
      end
    end)
  end

  defp map({assigns, marks}, maps, original, changed) do
    Enum.reduce(maps, {assigns, marks}, fn {to, {from, fun}}, {assigns, marks} ->
      assigns = Map.put(assigns, to, fun.(Map.get(original, from)))
      {assigns, if(tracked?(changed, [from, to]), do: [to | marks], else: marks)}
    end)
  end

  defp put({assigns, marks}, puts, _original, changed) do
    Enum.reduce(puts, {assigns, marks}, fn
      {key, {:from, sources, value}}, {assigns, marks} when is_list(sources) ->
        {Map.put(assigns, key, value),
         if(tracked?(changed, [key | sources]), do: [key | marks], else: marks)}

      {key, value}, {assigns, marks} ->
        {Map.put(assigns, key, value),
         if(tracked?(changed, [key]), do: [key | marks], else: marks)}
    end)
  end

  defp tracked?(changed, sources) when is_map(changed),
    do: Enum.any?(sources, &Map.has_key?(changed, &1))

  defp tracked?(_changed, _sources), do: false

  # Names the wrapper consumed (renamed or spread) no longer exist in what the kit receives.
  defp remove_dropped(changed, opts) do
    dropped = Keyword.keys(opts[:rename] || []) ++ List.wrap(opts[:spread])
    Map.drop(changed, dropped)
  end

  defp add_marks(changed, marks), do: Enum.reduce(marks, changed, &Map.put(&2, &1, true))
end
