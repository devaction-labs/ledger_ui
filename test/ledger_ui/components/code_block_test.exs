defmodule LedgerUI.Components.CodeBlockTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.CodeBlock

  doctest LedgerUI.Components.CodeBlock

  defp html(rendered), do: rendered_to_string(rendered)

  # the token colours: keyword, string, comment, function/module, number/atom
  @k "text-[#7fd4c3]"
  @s "text-[#e8c07a]"
  @c "text-[oklch(from_var(--color-gray-500)_0.5563_c_h)]"
  @f "text-[#a5b8f5]"
  @n "text-[#f0a0ae]"
  @ln "inline-block w-6 text-[oklch(from_var(--color-gray-600)_0.4358_c_h)] select-none"

  defp hl(text, lang) do
    {:safe, io} = LedgerUI.Components.CodeBlock.highlight(text, lang)
    IO.iodata_to_binary(io)
  end

  test "highlight elixir with one colour utility per token" do
    out = hl(~s(defmodule Foo.Bar do), "elixir")
    assert out =~ ~s(<span data-part="code-token" class="#{@k}">defmodule</span>)
    assert out =~ ~s(<span data-part="code-token" class="#{@f}">Foo.Bar</span>)

    out = hl(~S(x = "a<b" # note), "elixir")
    assert out =~ ~s(<span data-part="code-token" class="#{@s}">&quot;a&lt;b&quot;</span>)
    assert out =~ ~s(<span data-part="code-token" class="#{@c}"># note</span>)

    assert hl("pedido |> montar_xml(1_000)", "elixir") =~
             ~s|<span data-part="code-token" class="#{@f}">montar_xml</span>(<span data-part="code-token" class="#{@n}">1_000</span>)|

    assert hl("x = :ok", "ex") =~ ~s(<span data-part="code-token" class="#{@n}">:ok</span>)
  end

  test "highlight js and unknown languages (escaped only)" do
    assert hl("const a = 1 // hi", "js") =~
             ~s(<span data-part="code-token" class="#{@k}">const</span>)

    assert hl("const a = 1 // hi", "js") =~
             ~s(<span data-part="code-token" class="#{@c}">// hi</span>)

    assert hl("<script>", "text") == "&lt;script&gt;"
    assert hl("é <", "elixir") == "é &lt;"
  end

  test "renders code with line numbers, header, copy and the hook" do
    assigns = %{code: "one\ntwo <b>\n"}

    out =
      html(~H"""
      <.code_block
        id="c1"
        title="a.ex"
        icon="terminal"
        code={@code}
        line_numbers
        copy
        copy_label="Copiar"
      />
      """)

    assert out =~ ~s(data-part="code-block")
    assert out =~ "bg-[oklch(from_var(--color-gray-900)_0.1841_c_h)]"
    assert out =~ ~s(phx-hook="LedgerUI.CodeBlock")
    assert out =~ ~s(data-part="code-block-header")
    assert out =~ ~s(data-part="code-block-copy-label")
    assert out =~ ~s(<span data-part="code-line-number" class="#{@ln}">1</span>one)
    assert out =~ ~s(<span data-part="code-line-number" class="#{@ln}">2</span>two &lt;b&gt;)
    refute out =~ ~r/class="(lu-|[^"]* lu-)/
    assert out =~ "Copiar"
    assert out =~ ~s(data-lu-copy="one\ntwo &lt;b&gt;") or out =~ "data-lu-copy="
    refute out =~ ~s(style="")
  end

  test "floating copy without header, sizes, variants, wrap and max_height" do
    assigns = %{}

    out =
      html(
        ~H|<.code_block id="c2" code="x" copy size="sm" variant="destructive" wrap max_height={256} />|
      )

    refute out =~ ~s(data-part="code-block-header")
    assert out =~ "absolute top-2 right-2"
    assert out =~ "relative"
    assert out =~ "text-[12px] leading-[18px]"
    assert out =~ "var(--lu-neg)"
    assert out =~ "whitespace-pre-wrap"
    assert out =~ "max-height:256px"
  end

  test "diff lines, highlighted lines, start_line" do
    assigns = %{
      lines: ["a", %{text: "old", variant: "removed"}, %{text: "new", variant: "added"}, "b", "c"]
    }

    out =
      html(
        ~H|<.code_block id="c3" lines={@lines} line_numbers start_line={10} highlight={[12]} />|
      )

    assert out =~
             ~s|<span data-part="code-line" class="block bg-[rgba(240,120,139,.12)]"><span data-part="code-line-number" class="#{@ln}">11</span>old</span>|

    assert out =~
             ~s|<span data-part="code-line" class="block bg-[rgba(76,201,133,.12)]"><span data-part="code-line-number" class="#{@ln}">11</span>new</span>|

    assert out =~ ~s(<span data-part="code-line-number" class="#{@ln}">12</span>b)
    assert out =~ "bg-[rgba(255,255,255,.07)]"
    refute out =~ ~s(style="")
  end

  test "language highlights each line; inner block is drawn as is; footer and actions" do
    assigns = %{}
    out = html(~H|<.code_block id="c4" code="def x do" language="elixir" />|)

    assert out =~
             ~s(<span data-part="code-token" class="#{@k}">def</span> <span data-part="code-token" class="#{@f}">x</span>)

    block = html(~H|<.code_block id="c5" title="t">
  <i>raw</i><:footer>more</:footer><:actions><b>act</b></:actions>
</.code_block>|)
    assert block =~ "<i>raw</i>"
    assert block =~ "more"
    assert block =~ "<b>act</b>"
  end

  test "the pre keeps the browser's own monospace family (the canvas does), the box keeps font-mono" do
    assigns = %{}
    out = html(~H(<.code_block id="c" code="a |> b" />))
    assert out =~ ~r/<pre [^>]*font-\[family-name:monospace\]/
    assert out =~ ~r/<div id="c" [^>]*\bfont-mono\b/
    refute out =~ "font-[inherit]"
  end
end
