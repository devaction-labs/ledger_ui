defmodule LedgerUI.Helpers do
  @moduledoc """
  Small helpers shared by all components.
  """

  @doc """
  Joins class values into a single string, dropping empties.

  Accepts strings, `nil`, `false`, `{class, condition}` tuples and nested lists.

      iex> LedgerUI.Helpers.cx(["flex", nil, false, {"on", true}, {"off", false}, ["a", " "], "b  c"])
      "flex on a b c"

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

  defp flatten(class) when is_binary(class),
    do: :binary.split(class, [" ", "\n", "\t", "\r"], [:global, :trim_all])

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

  @doc """
  Keeps a derived assign from being sent again when none of its sources changed.

  A function component that computes a value in its body (`assign(assigns, :cls, ...)`) creates a
  key the caller never passed, so `assign/3` marks it as changed on every call, even when the string
  came out the same: the LiveView then sends the classes again each time the component is called
  again, for instance when only its slot changed. `settle/3` takes those keys back out of
  `assigns.__changed__` when the call changed none of what they are computed from.

  Capture `assigns.__changed__` on entry, before deriving anything, and call `settle/3` once the last
  derived key is assigned, right before the template:

      def badge(assigns) do
        changed0 = assigns.__changed__
        assigns = assign(assigns, :cls, classes(assigns))

        assigns =
          settle(assigns, changed0, cls: [:color, :variant, :size, :shape, :canvas])

        ~H"<span class={[@cls, @class]}>{render_slot(@inner_block)}</span>"
      end

  `derived` is a keyword list `derived_key: [source, ...]`.

    * `changed0` is `nil` (first render, static render, or a caller that spreads a map such as
      `<.badge {@attrs} />`): nothing is done and everything is sent, as without `settle/3`.
    * A derived key stays in `__changed__` when the caller changed the key itself, or any of its
      sources. Otherwise it is dropped.
    * A source can be another derived key listed before it: it counts as changed when that key was
      kept. A derived key that is assigned but not listed stays changed, and so do the keys that
      list it as a source. A source that is not a key of `assigns` raises `ArgumentError` (a typo
      would leave the value stale).
    * Global attributes (`attr :rest, :global`) arrive as `:rest` plus one key per attribute: list
      `:rest` as the source of whatever reads `rest`.

  Rules for what goes in the sources (the risk is listing too few, which leaves a stale value):

    * List every attr (and every assign set earlier in the body) that the value reads, directly
      or in a helper it calls. `class`, `rest`, `disabled`, `errors` and `field` count.
    * A value that also depends on something outside the assigns (the process locale of
      `LedgerUI.put_locale/1`, `Application.get_env/2`, Gettext) must not be listed: leave it out
      of `derived` so it is sent every time, or add the `:locale` attr when that is the only input.
    * Slots: do not list slot names to say "the content changed" (that is exactly what must not
      resend the classes). List a slot only when a derived value reads it (`slot != []` where the
      slot may appear or disappear between renders of the same call site).
    * `assign/3` on a key whose new value equals the old one is not a change: such a key needs no
      `settle/3`.
  """
  @spec settle(map(), map() | nil, keyword([atom()])) :: map()
  def settle(assigns, changed0, derived) do
    Enum.each(derived, fn {_key, sources} ->
      Enum.each(sources, fn source ->
        Map.has_key?(assigns, source) or
          raise ArgumentError,
                "settle/3: #{inspect(source)} is not an assign of the component " <>
                  "(sources: #{inspect(Map.keys(assigns))})"
      end)
    end)

    case {changed0, assigns} do
      {%{} = changed0, %{__changed__: %{} = changed}} ->
        changed =
          Enum.reduce(derived, changed, fn {key, sources}, changed ->
            if Map.has_key?(changed0, key) or Enum.any?(sources, &Map.has_key?(changed, &1)),
              do: changed,
              else: Map.delete(changed, key)
          end)

        %{assigns | __changed__: changed}

      _ ->
        assigns
    end
  end

  @doc """
  `render_slot/2` for a slot kept inside a map that a child component draws (`tab.slot`,
  `item.content`): the body is drawn in full, whatever the `__changed__` of the child.

  `render_slot/2` hands the slot the `__changed__` of the component that calls it, and the slot
  draws its body again only when its own name (`:tab`) is a key of it, which it is not in a
  component that got the slot inside a derived map. Then a new text of the body never reached the
  client. Use it only where the slot comes from such a map; `render_slot/2` is right for a slot
  that is an assign of the component.
  """
  def render_slot_full(slot, argument \\ nil),
    do: Phoenix.Component.__render_slot__(nil, slot, argument)

  @doc """
  Serializes a `%Phoenix.LiveView.JS{}` to the JSON string the hooks read from a `data-*`
  attribute (or a toast action), through the public `JS.to_encodable/1`.
  """
  @spec js_json(Phoenix.LiveView.JS.t()) :: String.t()
  def js_json(%Phoenix.LiveView.JS{} = js),
    do: Phoenix.json_library().encode!(Phoenix.LiveView.JS.to_encodable(js))

  @doc """
  The DOM id of a form control, one rule for every component.

    1. `assigns.id` (when not empty);
    2. the `id` of `assigns.field` (a `Phoenix.HTML.FormField`);
    3. the `name` (or the first of `opts[:names]`) sanitized: every run of characters outside
       `[A-Za-z0-9_-]` becomes one `-` and the ends are trimmed (`"user[role][]"` is
       `"user-role"`);
    4. nothing of the above: by `opts[:fallback]`. `:raise` (the default, for a component with a
       hook: without a stable id the hook cannot mount and two instances would share the id)
       is an `ArgumentError`; `:hash` is a deterministic `"\#{prefix}-\#{hash}"` of `opts[:seed]`
       (default `assigns.label`); `:none` is `nil`.

  `prefix` names the component in the error and in the hashed id.

      iex> LedgerUI.Helpers.field_id(%{id: "x", name: "a[b]"}, "date-picker")
      "x"
      iex> LedgerUI.Helpers.field_id(%{id: nil, name: "user[role][]"}, "date-picker")
      "user-role"
      iex> LedgerUI.Helpers.field_id(%{id: nil, name: nil, label: "Q"}, "box", fallback: :hash) =~ "box-"
      true
  """
  @spec field_id(map(), String.t(), keyword()) :: String.t()
  def field_id(assigns, prefix, opts \\ []) do
    names = Keyword.get_lazy(opts, :names, fn -> [Map.get(assigns, :name)] end)

    present(Map.get(assigns, :id)) || field_struct_id(Map.get(assigns, :field)) ||
      Enum.find_value(names, &name_id/1) ||
      case Keyword.get(opts, :fallback, :raise) do
        :raise ->
          raise ArgumentError,
                "#{prefix} needs an id (or a name, or a field): without a stable id its hook " <>
                  "cannot mount and two instances would share the same id"

        :hash ->
          seed = Keyword.get_lazy(opts, :seed, fn -> Map.get(assigns, :label) end)
          "#{prefix}-#{:erlang.phash2(seed)}"

        :none ->
          nil
      end
  end

  defp present(value) when value in [nil, ""], do: nil
  defp present(value), do: value

  defp field_struct_id(%Phoenix.HTML.FormField{id: id}), do: present(id)
  defp field_struct_id(_), do: nil

  defp name_id(name) when is_binary(name) and name != "" do
    name |> squash_name("", false) |> String.trim("-") |> present()
  end

  defp name_id(_), do: nil

  # `String.replace(name, ~r/[^A-Za-z0-9_-]+/, "-")` without the regex: each run of other bytes
  # becomes one "-".
  defp squash_name("", acc, _), do: acc

  defp squash_name(<<c, rest::binary>>, acc, _)
       when c in ?a..?z or c in ?A..?Z or c in ?0..?9 or c in [?_, ?-],
       do: squash_name(rest, <<acc::binary, c>>, false)

  defp squash_name(<<_, rest::binary>>, acc, true), do: squash_name(rest, acc, true)

  defp squash_name(<<_, rest::binary>>, acc, false),
    do: squash_name(rest, <<acc::binary, ?->>, true)
end
