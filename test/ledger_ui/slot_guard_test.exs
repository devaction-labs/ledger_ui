defmodule LedgerUI.SlotGuardTest do
  # Guard for the whole class of bug of #90/#91: a slot body that reads an assign of the caller
  # (`{@p}`) must be redrawn when only that assign changes. For every public component with
  # declared slots (`__components__/0`) it is called with `{@p_<slot>}` in each slot, and for
  # each slot `@p_<slot>` is changed alone: `LedgerUI.DiffCase.check/3` asserts that the patch
  # applied equals a fresh render. A slot whose probe changes nothing in the HTML (the component
  # does not draw it with those attrs) is skipped; a component that does not mount with an
  # automatic call is in `@no_mount`, with the reason.
  use ExUnit.Case, async: true

  import LedgerUI.DiffCase

  # `{component, reason}`: components an automatic call cannot mount.
  @no_mount %{
    card_table: "needs `rows` and columns with row data; covered by TableSlotsTest",
    data_table: "needs `rows` and columns with row data; covered by TableSlotsTest",
    bar_list: "the `:item` slot needs `amount`/`label` keys in its attrs",
    filter_menu: "its `:filter`/`:option` slots need `name`/`options` of a given shape",
    flow: "the slots need an `id` per node",
    navbar_user: "a `:menu` slot needs an `id` the generic call does not give",
    progress_stack: "the slots need a `value` the generic call does not give",
    text_editor: "needs an `id`, `name` or `field` that is not a required attr",
    rich_text_editor: "same as `text_editor`",
    comment_editor: "same as `text_editor`",
    upload: "no clause for the generic call (needs a `field` or an `upload` struct)"
  }

  defp val(%{name: :id}), do: "sg-id"

  defp val(%{opts: opts} = a) do
    case Keyword.get(opts, :values) do
      [v | _] when not is_nil(v) -> v
      _ -> tval(a)
    end
  end

  defp tval(%{type: :string, name: n}), do: to_string(n)
  defp tval(%{type: :integer}), do: 3
  defp tval(%{type: :float}), do: 3.0
  defp tval(%{type: :boolean}), do: false
  defp tval(%{type: :list}), do: []
  defp tval(%{type: :map}), do: %{}
  defp tval(%{type: :atom}), do: :x
  defp tval(_), do: "x"

  def targets do
    for mod <- LedgerUI.Components.__modules__(),
        {f, 1} <- LedgerUI.Components.__imports__(mod),
        c = mod.__components__()[f],
        c != nil,
        c.slots != [],
        do: {f, c}
  end

  # {heex, base assigns, [probe keys]}
  defp build(f, c) do
    req = for a <- c.attrs, a.required, do: {a.name, val(a)}
    base0 = Map.new(req, fn {n, v} -> {:"v_#{n}", v} end)
    # A control with a hook needs a stable id (#118): give one to those that have the attr.
    {req, base0} =
      if Enum.any?(c.attrs, &(&1.name == :id)) and not Enum.any?(req, &(elem(&1, 0) == :id)),
        do: {req ++ [id: "sg-id"], Map.put(base0, :v_id, "sg-id")},
        else: {req, base0}

    attrs = Enum.map_join(req, "", fn {n, _} -> " #{n}={@v_#{n}}" end)

    {body, base, probes} =
      Enum.reduce(c.slots, {"", base0, []}, fn s, {body, base, probes} ->
        key = :"p_#{s.name}"
        base = Map.put(base, key, "AAA")

        if s.name == :inner_block do
          {"{@#{key}}" <> body, base, [{s.name, key} | probes]}
        else
          sreq = for a <- s.attrs, a.required, do: {a.name, val(a)}
          sattrs = Enum.map_join(sreq, "", fn {n, _} -> " #{n}={@s_#{s.name}_#{n}}" end)
          base = Enum.reduce(sreq, base, fn {n, v}, b -> Map.put(b, :"s_#{s.name}_#{n}", v) end)
          {body <> "<:#{s.name}#{sattrs}>{@#{key}}</:#{s.name}>", base, [{s.name, key} | probes]}
        end
      end)

    {"<.#{f}#{attrs}>#{body}</.#{f}>", base, Enum.reverse(probes)}
  end

  defp compile(heex) do
    n = System.unique_integer([:positive])
    mod = Module.concat(__MODULE__, "Probe#{n}")

    Code.compile_string("""
    defmodule #{inspect(mod)} do
      use Phoenix.Component
      use LedgerUI
      def render(assigns) do
        ~H\"\"\"
        #{heex}
        \"\"\"
      end
    end
    """)

    &mod.render/1
  end

  @tag timeout: 120_000
  test "every declared slot of every component is redrawn when its assign changes" do
    results =
      targets()
      |> Task.async_stream(
        fn {f, c} ->
          if Map.has_key?(@no_mount, f) do
            []
          else
            {heex, base, probes} = build(f, c)

            try do
              fun = compile(heex)
              html(fun, base)

              for {slot, key} <- probes do
                try do
                  check(fun, base, [{key, "BBB"}])
                  {f, slot, :ok}
                rescue
                  e in ExUnit.AssertionError ->
                    if e.message =~ "changes nothing",
                      do: {f, slot, :nochange},
                      else: {f, slot, {:stale, e.message}}

                  e ->
                    {f, slot, {:error, Exception.message(e)}}
                end
              end
            rescue
              e -> [{f, :all, {:no_mount, Exception.message(e)}}]
            end
          end
        end,
        timeout: 120_000,
        max_concurrency: System.schedulers_online()
      )
      |> Enum.flat_map(fn {:ok, r} -> r end)

    bad = for {f, s, r} <- results, r not in [:ok, :nochange], do: {f, s, r}

    assert bad == [],
           "a slot body that reads an assign of the caller went stale, or a component does not mount (add it to @no_mount with the reason):\n" <>
             inspect(bad, limit: :infinity, printable_limit: 300)

    assert Enum.count(results, &match?({_, _, :ok}, &1)) > 300
  end
end
