defmodule LedgerUI.Components.CodeBlock do
  @moduledoc """
  Code, terminal output, logs and diffs in a dark card: an optional header with a title and a
  copy button, line numbers, wrapping, added, removed and highlighted lines, and a small size for
  tool output inside a `LedgerUI.Components.Trace.trace/1`.

      <.code_block id="install" title="Terminal" icon="terminal" code={@output} line_numbers wrap />

  `code` is a string split into lines. `lines` is a list instead, each a string or a map with
  `:text` (or `:html`, already safe HTML) and `:variant` (`"added"`, `"removed"`, `"highlighted"`):

      <.code_block id="diff" title="mix.exs" lines={[
        "defp deps do",
        %{text: ~s(  {:phoenix, "~> 1.7"},), variant: "removed"},
        %{text: ~s(  {:phoenix, "~> 1.8"},), variant: "added"},
        "end"
      ]} />

  ## Syntax highlighting

  `language` (`"elixir"`, `"js"`) highlights the text of each line on the server with the
  `lu-code` token classes (`k` keyword, `s` string/atom, `c` comment, `f` function/module,
  `n` number); see `highlight/2`. No client library is involved. Without `language` the text is
  only escaped. The block (`:inner_block`) can also hold your own safe HTML, drawn as is.

  ## Copy

  `copy` adds a button (hook `LedgerUI.CodeBlock`, file `priv/static/ledger_ui/hooks/code_block.js`)
  that copies the code without line numbers. It needs the `id`.
  """
  use LedgerUI.Component

  @elixir_keywords ~w(defmodule def defp defmacro defmacrop defstruct defprotocol defimpl defguard
    defdelegate do end fn if else case cond when with for in and or not use import alias require
    true false nil unless raise rescue catch after receive try quote unquote super)
  @js_keywords ~w(const let var function return if else for while do switch case break continue
    new class extends import export from default async await try catch finally throw typeof
    instanceof in of true false null undefined this)

  @doc """
  Highlights one line of code and returns safe HTML (`{:safe, iodata}`).

  Supported languages: `"elixir"` (`"ex"`, `"exs"`) and `"js"` (`"javascript"`, `"ts"`,
  `"typescript"`); any other value is only escaped. Every piece of the text is escaped.

      iex> {:safe, html} = LedgerUI.Components.CodeBlock.highlight("def run(1) # ok", "elixir")
      iex> IO.iodata_to_binary(html)
      ~s|<span class="k">def</span> <span class="f">run</span>(<span class="n">1</span>) <span class="c"># ok</span>|
  """
  @spec highlight(String.t(), String.t() | nil) :: Phoenix.HTML.safe()
  def highlight(text, language) when language in ["elixir", "ex", "exs"],
    do: {:safe, scan(text, :elixir, [], nil)}

  def highlight(text, language)
      when language in ["js", "javascript", "ts", "typescript", "json"],
      do: {:safe, scan(text, :js, [], nil)}

  def highlight(text, _language), do: {:safe, esc(text)}

  # `style={nil}` would render `style=""`: pass the attribute through a map instead.
  defp sa(style) when style in [nil, false, ""], do: %{}
  defp sa(style), do: %{style: style}

  defp esc(text), do: text |> Phoenix.HTML.html_escape() |> elem(1)

  defp tok(class, text), do: [~s(<span class="), class, ~s(">), esc(text), "</span>"]

  # `prev` is the last keyword seen (to colour the name after `def`).
  defp scan("", _lang, acc, _prev), do: Enum.reverse(acc)

  defp scan("#" <> _ = rest, :elixir, acc, prev),
    do: scan("", :elixir, [tok("c", rest) | acc], prev)

  defp scan("//" <> _ = rest, :js, acc, prev), do: scan("", :js, [tok("c", rest) | acc], prev)

  defp scan(<<q, _::binary>> = rest, lang, acc, prev) when q in [?", ?', ?`] do
    {str, tail} = take_string(rest, q)
    scan(tail, lang, [tok("s", str) | acc], prev)
  end

  defp scan(<<":", c, _::binary>> = rest, :elixir, acc, prev) when c in ?a..?z or c == ?_ do
    {atom, tail} = take_while(binary_part(rest, 1, byte_size(rest) - 1), &word?/1)
    scan(tail, :elixir, [tok("n", ":" <> atom) | acc], prev)
  end

  defp scan(<<c, _::binary>> = rest, lang, acc, prev) when c in ?0..?9 do
    {num, tail} = take_while(rest, fn ch -> ch in ?0..?9 or ch in [?_, ?.] end)
    {num, tail} = trim_trailing_dot(num, tail)
    scan(tail, lang, [tok("n", num) | acc], prev)
  end

  defp scan(<<c, _::binary>> = rest, lang, acc, prev)
       when c in ?a..?z or c in ?A..?Z or c == ?_ or c == ?$ do
    {word, tail} = take_while(rest, &word?/1)
    {word, tail} = take_suffix(word, tail, lang)

    cond do
      word in keywords(lang) ->
        scan(tail, lang, [tok("k", word) | acc], word)

      c in ?A..?Z and lang == :elixir ->
        {mod, tail2} = take_alias(word, tail)
        scan(tail2, lang, [tok("f", mod) | acc], nil)

      prev in ~w(def defp defmacro defmacrop defdelegate function) or
          String.starts_with?(tail, "(") ->
        scan(tail, lang, [tok("f", word) | acc], nil)

      true ->
        scan(tail, lang, [esc(word) | acc], nil)
    end
  end

  defp scan(<<c::utf8, tail::binary>>, lang, acc, prev) do
    prev = if c in [?\s, ?\t], do: prev, else: nil
    scan(tail, lang, [esc(<<c::utf8>>) | acc], prev)
  end

  defp scan(<<byte, tail::binary>>, lang, acc, prev),
    do: scan(tail, lang, [esc(<<byte>>) | acc], prev)

  defp keywords(:elixir), do: @elixir_keywords
  defp keywords(:js), do: @js_keywords

  defp word?(c), do: c in ?a..?z or c in ?A..?Z or c in ?0..?9 or c == ?_ or c == ?$

  # elixir names may end in ? or !
  defp take_suffix(word, <<s, tail::binary>>, :elixir) when s in [??, ?!],
    do: {word <> <<s>>, tail}

  defp take_suffix(word, tail, _), do: {word, tail}

  # Foo.Bar.Baz as one token
  defp take_alias(word, <<".", c, _::binary>> = tail) when c in ?A..?Z do
    <<".", rest::binary>> = tail
    {next, tail2} = take_while(rest, &word?/1)
    take_alias(word <> "." <> next, tail2)
  end

  defp take_alias(word, tail), do: {word, tail}

  defp trim_trailing_dot(num, tail) do
    if String.ends_with?(num, "."),
      do: {binary_part(num, 0, byte_size(num) - 1), "." <> tail},
      else: {num, tail}
  end

  defp take_while(bin, fun), do: take_while(bin, fun, 0)

  defp take_while(bin, fun, n) when n < byte_size(bin) do
    if fun.(:binary.at(bin, n)),
      do: take_while(bin, fun, n + 1),
      else: {binary_part(bin, 0, n), binary_part(bin, n, byte_size(bin) - n)}
  end

  defp take_while(bin, _fun, _n), do: {bin, ""}

  # Quoted string up to the closing quote (escapes honoured); unterminated runs to the end.
  defp take_string(<<q, rest::binary>>, q), do: take_string(rest, q, <<q>>)

  defp take_string(<<?\\, c, rest::binary>>, q, acc),
    do: take_string(rest, q, <<acc::binary, ?\\, c>>)

  defp take_string(<<q, rest::binary>>, q, acc), do: {<<acc::binary, q>>, rest}
  defp take_string(<<c, rest::binary>>, q, acc), do: take_string(rest, q, <<acc::binary, c>>)
  defp take_string("", _q, acc), do: {acc, ""}

  # -- component ---------------------------------------------------------------

  attr :id, :string, required: true
  attr :code, :string, default: nil, doc: "The code, split into lines."

  attr :lines, :list,
    default: nil,
    doc: "Strings or maps with `:text` (or `:html`) and `:variant` (added, removed, highlighted)."

  attr :language, :string, default: nil, doc: "Highlights each line server-side: `elixir`, `js`."
  attr :highlight, :list, default: [], doc: "Line numbers drawn highlighted."
  attr :title, :string, default: nil
  attr :icon, :string, default: nil
  attr :copy, :boolean, default: false
  attr :copy_label, :string, default: "Copy"

  attr :copy_text, :string,
    default: nil,
    doc: "What the copy button copies; the code itself when `nil`."

  attr :line_numbers, :boolean, default: false
  attr :start_line, :integer, default: 1
  attr :wrap, :boolean, default: false
  attr :max_height, :integer, default: nil
  attr :size, :string, default: "default", values: ~w(default sm)
  attr :variant, :string, default: "default", values: ~w(default destructive)
  attr :class, :any, default: nil
  attr :rest, :global

  slot :actions, doc: "Buttons next to the copy button."
  slot :footer, doc: "A row under the code."
  slot :inner_block, doc: "Code as safe HTML (highlighted), drawn as is."

  @doc "Renders the code block."
  def code_block(assigns) do
    {style, rest} = Map.pop(assigns.rest, :style)
    entries = if assigns.inner_block == [], do: build_lines(assigns), else: []

    assigns =
      assigns
      |> assign(:body, body(entries, assigns.line_numbers))
      |> assign(:copy_value, assigns.copy_text || copy_text(assigns))
      |> assign(:hook, assigns.copy && "LedgerUI.CodeBlock")
      |> assign(:root_style, root_style(assigns, style))
      |> assign(:pre_style, pre_style(assigns))
      |> assign(:rest, rest)

    ~H"""
    <div
      id={@id}
      data-part="code-block"
      class={cx(["lu-code", @class])}
      {sa(@root_style)}
      phx-hook={@hook}
      {@rest}
    >
      <div :if={@title} class="hd">
        <.icon :if={@icon} name={@icon} size="sm" />{@title}<button
          :if={@copy}
          type="button"
          data-lu-copy={@copy_value}
        ><span class="lu-copy-label">{@copy_label}</span></button>
        {render_slot(@actions)}
      </div>
      <button
        :if={@copy and !@title}
        type="button"
        data-lu-copy={@copy_value}
        aria-label={@copy_label}
        style="position:absolute;top:8px;right:8px;height:26px;padding:0 8px;border-radius:6px;border:0;background:rgba(255,255,255,.08);color:#e6e8e7;font-size:12px;cursor:pointer"
      >
        <span class="lu-copy-label">{@copy_label}</span>
      </button>
      <%= if @inner_block != [] do %>
        <pre {sa(@pre_style)}>{render_slot(@inner_block)}</pre>
      <% else %>
        <pre {sa(@pre_style)}>{@body}</pre>
      <% end %>
      <div :if={@footer != []}>{render_slot(@footer)}</div>
    </div>
    """
  end

  # The whole content of `<pre>` as one safe iodata: whitespace matters here and every
  # text piece was escaped by `highlight/2` (or given as safe HTML by the caller).
  defp body(entries, numbers?) do
    iodata =
      Enum.map(entries, fn {kind, number, {:safe, html}} ->
        ln =
          if numbers?, do: [~s(<span class="ln">), Integer.to_string(number), "</span>"], else: []

        case kind do
          :plain ->
            [ln, html, "\n"]

          :added ->
            [~s(<span class="lu-diff-add">), ln, html, "</span>"]

          :removed ->
            [~s(<span class="lu-diff-del">), ln, html, "</span>"]

          :highlighted ->
            [
              ~s|<span style="display:block;background:rgba(255,255,255,.07)">|,
              ln,
              html,
              "</span>"
            ]
        end
      end)

    {:safe, iodata}
  end

  defp root_style(assigns, extra) do
    [
      (assigns.copy and !assigns.title) && "position:relative",
      assigns.size == "sm" && "font-size:12px;line-height:18px",
      assigns.variant == "destructive" &&
        "border-color:color-mix(in oklab, var(--neg) 55%, #252927);background:color-mix(in oklab, var(--neg) 9%, #111312)",
      extra
    ]
    |> Enum.filter(& &1)
    |> Enum.join(";")
    |> case do
      "" -> nil
      style -> style
    end
  end

  defp pre_style(assigns) do
    [
      assigns.wrap && "white-space:pre-wrap;overflow-wrap:anywhere",
      assigns.max_height && "max-height:#{assigns.max_height}px",
      assigns.size == "sm" && "padding:10px 12px"
    ]
    |> Enum.filter(& &1)
    |> Enum.join(";")
    |> case do
      "" -> nil
      style -> style
    end
  end

  # [{kind, number, safe_html}]. A removed line does not advance the counter (the line that
  # replaces it takes the same number, as in a diff of the new file).
  defp build_lines(assigns) do
    raw = assigns.lines || split_code(assigns.code)
    highlighted = MapSet.new(assigns.highlight)

    {entries, _} =
      Enum.map_reduce(raw, assigns.start_line, fn line, number ->
        {text, html, variant} = normalize_line(line)

        kind =
          case variant do
            "added" -> :added
            "removed" -> :removed
            "highlighted" -> :highlighted
            _ -> if MapSet.member?(highlighted, number), do: :highlighted, else: :plain
          end

        html = html || highlight(text, assigns.language)
        {{kind, number, html}, if(kind == :removed, do: number, else: number + 1)}
      end)

    entries
  end

  defp normalize_line(line) when is_binary(line), do: {line, nil, nil}

  defp normalize_line(%{} = line),
    do: {line[:text] || "", line[:html], line[:variant] && to_string(line[:variant])}

  defp split_code(nil), do: []

  defp split_code(code) do
    lines = String.split(code, ~r/\r?\n/)
    if List.last(lines) == "", do: Enum.drop(lines, -1), else: lines
  end

  defp copy_text(%{copy: false}), do: nil

  defp copy_text(%{inner_block: [_ | _]}), do: nil

  defp copy_text(assigns) do
    (assigns.lines || split_code(assigns.code))
    |> Enum.map(fn
      line when is_binary(line) -> line
      %{variant: v} when v in ["removed", :removed] -> nil
      line -> line[:text] || ""
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end
end
