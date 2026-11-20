defmodule LedgerUI.Components.CodeBlockTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.CodeBlock

  doctest LedgerUI.Components.CodeBlock

  defp html(rendered), do: rendered_to_string(rendered)

  defp hl(text, lang) do
    {:safe, io} = LedgerUI.Components.CodeBlock.highlight(text, lang)
    IO.iodata_to_binary(io)
  end

  test "highlight elixir with lu-code token classes" do
    out = hl(~s(defmodule Foo.Bar do), "elixir")
    assert out =~ ~s(<span class="k">defmodule</span>)
    assert out =~ ~s(<span class="f">Foo.Bar</span>)

    out = hl(~S(x = "a<b" # note), "elixir")
    assert out =~ ~s(<span class="s">&quot;a&lt;b&quot;</span>)
    assert out =~ ~s(<span class="c"># note</span>)

    assert hl("pedido |> montar_xml(1_000)", "elixir") =~
             ~s|<span class="f">montar_xml</span>(<span class="n">1_000</span>)|

    assert hl("x = :ok", "ex") =~ ~s(<span class="n">:ok</span>)
  end

  test "highlight js and unknown languages (escaped only)" do
    assert hl("const a = 1 // hi", "js") =~ ~s(<span class="k">const</span>)
    assert hl("const a = 1 // hi", "js") =~ ~s(<span class="c">// hi</span>)
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

    assert out =~ ~s(class="lu-code")
    assert out =~ ~s(phx-hook="LedgerUI.CodeBlock")
    assert out =~ ~s(class="hd")
    assert out =~ ~s(<span class="ln">1</span>one)
    assert out =~ ~s(<span class="ln">2</span>two &lt;b&gt;)
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

    refute out =~ ~s(class="hd")
    assert out =~ "position:absolute"
    assert out =~ "font-size:12px"
    assert out =~ "var(--neg)"
    assert out =~ "white-space:pre-wrap"
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

    assert out =~ ~s(<span class="lu-diff-del"><span class="ln">11</span>old</span>)
    assert out =~ ~s(<span class="lu-diff-add"><span class="ln">11</span>new</span>)
    assert out =~ ~s(<span class="ln">12</span>b)
    assert out =~ "background:rgba(255,255,255,.07)"
  end

  test "language highlights each line; inner block is drawn as is; footer and actions" do
    assigns = %{}
    out = html(~H|<.code_block id="c4" code="def x do" language="elixir" />|)
    assert out =~ ~s(<span class="k">def</span> <span class="f">x</span>)

    block = html(~H|<.code_block id="c5" title="t">
  <i>raw</i><:footer>more</:footer><:actions><b>act</b></:actions>
</.code_block>|)
    assert block =~ "<i>raw</i>"
    assert block =~ "more"
    assert block =~ "<b>act</b>"
  end
end
