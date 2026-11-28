defmodule LedgerUI.EscapeScanTest do
  @moduledoc """
  A text with HTML markup goes into every `:string` attr of every public component; it must
  never reach the HTML raw. Catches a value written with `raw/1` or into a script by mistake.
  """
  use ExUnit.Case, async: false

  @xss ~s|x"><script>alert(1)</script><img src=x onerror=alert(2)>|

  # Raw forms that would mean the text escaped. An escaped text has `&lt;`/`&quot;` instead.
  @raw ["<script>alert(1)", "<img src=x", ~s|x"><script|]

  # Components that cannot be mounted by an automatic call (they need data a fuzz cannot guess),
  # or whose string attrs are not text (see the reason). Each is still covered by its own tests.
  @skip %{
    {LedgerUI.Components.Progress, :progress_stack} => "slot attrs the fuzz cannot guess",
    {LedgerUI.Components.Flow, :flow} => "slot attrs the fuzz cannot guess",
    {LedgerUI.Components.Chart, :bar_list} => "slot attrs the fuzz cannot guess",
    {LedgerUI.Components.Upload, :upload} => "needs a %Phoenix.LiveView.UploadConfig{}",
    {LedgerUI.Components.Upload, :upload_dropzone} => "needs a %Phoenix.LiveView.UploadConfig{}"
  }

  # Attrs holding an icon name, a URL or a class list: sanitised or validated on purpose, not text.
  @not_text ~w(id icon class locale)a

  defp value(%{type: :string, name: name, opts: opts}) do
    cond do
      name == :id -> "scan-id"
      match?([_ | _], opts[:values]) -> hd(opts[:values])
      true -> "x"
    end
  end

  defp value(%{type: :integer}), do: 1
  defp value(%{type: :list}), do: []
  defp value(%{type: :map}), do: %{}
  defp value(%{type: :boolean}), do: true
  defp value(%{type: :atom}), do: :x

  defp value(%{type: {:struct, Phoenix.HTML.FormField}}),
    do: Phoenix.Component.to_form(%{"f" => "v"}, as: "scan")[:f]

  defp value(%{type: :any, name: name}) when name in [:rows, :options, :counts], do: %{}
  defp value(%{type: :any}), do: "x"
  defp value(_), do: nil

  defp base(comp),
    do: for(a <- comp.attrs, a.required, a.type != :global, into: %{}, do: {a.name, value(a)})

  defp slots(comp) do
    for s <- comp.slots, s.required, into: "" do
      if s.name == :inner_block do
        "body"
      else
        attrs =
          for a <- s.attrs, a.required, into: "" do
            " #{a.name}=" <>
              case a.type do
                :integer -> "{1}"
                :boolean -> "{true}"
                :list -> "{[]}"
                _ -> ~s|"x"|
              end
          end

        "<:#{s.name}#{attrs}>s</:#{s.name}>"
      end
    end
  end

  defp markup(tag, ""), do: "<#{tag} {@a} />"
  defp markup(tag, body), do: "<#{tag} {@a}>#{body}</#{tag}>"

  defp render(mod, fun, comp, attrs, n) do
    name = Module.concat(__MODULE__, "Scan#{n}")
    tag = "#{inspect(mod)}.#{fun}"

    Code.put_compiler_option(:ignore_module_conflict, true)

    Code.compile_string("""
    defmodule #{inspect(name)} do
      use Phoenix.Component
      def run(assigns), do: ~H|#{markup(tag, slots(comp))}|
    end
    """)

    name.run(%{a: attrs, __changed__: nil})
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  test "text with markup in a string attr never reaches the HTML raw" do
    previous = Logger.level()
    Logger.configure(level: :error)
    on_exit(fn -> Logger.configure(level: previous) end)

    comps =
      for mod <- LedgerUI.Components.__modules__(),
          {fun, comp} <- mod.__components__(),
          comp.kind == :def,
          not Map.has_key?(@skip, {mod, fun}),
          do: {mod, fun, comp}

    {leaks, errors, rendered} =
      comps
      |> Enum.with_index()
      |> Enum.reduce({[], [], 0}, fn {{mod, fun, comp}, i}, {leaks, errors, rendered} ->
        strs =
          Enum.filter(
            comp.attrs,
            &(&1.type == :string and &1.name not in @not_text and is_nil(&1.opts[:values]))
          )

        attrs = Enum.reduce(strs, base(comp), &Map.put(&2, &1.name, @xss))

        try do
          html = render(mod, fun, comp, attrs, i)
          found = Enum.filter(@raw, &String.contains?(html, &1))
          {if(found == [], do: leaks, else: [{mod, fun, found} | leaks]), errors, rendered + 1}
        rescue
          e -> {leaks, [{mod, fun, Exception.message(e)} | errors], rendered}
        end
      end)

    assert leaks == [], "text leaked raw: #{inspect(leaks)}"
    assert rendered > 250, "too few components rendered (#{rendered}); errors: #{inspect(errors)}"

    assert errors == [],
           "components that did not mount (add to @skip with a reason): #{inspect(errors)}"
  end
end
