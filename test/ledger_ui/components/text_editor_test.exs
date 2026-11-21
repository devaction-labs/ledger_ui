defmodule LedgerUI.Components.TextEditorTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.TextEditor

  alias LedgerUI.Components.TextEditor

  doctest LedgerUI.Components.TextEditor

  describe "<.text_editor>" do
    test "renders the editor, the full default toolbar and a hidden input" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H|<.text_editor name="note" value="<p>Ola</p>" placeholder="Escreva" />|
        )

      assert html =~ "rounded-lg border border-line-strong bg-panel"
      assert html =~ ~s(phx-hook="LedgerUI.TextEditor")
      assert html =~ ~s(id="note")
      assert html =~ ~s(id="note-body")
      assert html =~ ~s(contenteditable="true")
      assert html =~ ~s(role="textbox")
      assert html =~ ~s(phx-update="ignore")
      assert html =~ "<p>Ola</p>"
      assert html =~ ~s(<input type="hidden" name="note" value="&lt;p&gt;Ola&lt;/p&gt;")
      assert html =~ "Escreva"
      assert html =~ ~s(role="toolbar")

      for tool <- ~w(bold italic underline strike blockquote code-block header-1 header-2
                     list-ordered list-bullet script-sub script-super indent-minus1 indent-plus1
                     direction-rtl size header color background font align clean) do
        assert html =~ ~s(data-lu-tool="#{tool}"), "missing tool #{tool}"
      end

      # opt-in buttons are not in the default toolbar
      for tool <- ~w(image variable mark link), do: refute(html =~ ~s(data-lu-tool="#{tool}"))
      # groups are separated
      assert html =~ "mx-1 h-[18px] w-px bg-line-strong"
    end

    test "custom toolbar, tool_labels and filled" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.text_editor
          name="n"
          filled
          toolbar={[~w(bold mark), ~w(link image variable nope)]}
          tool_labels={%{"mark" => "Destacar"}}
        />
        """)

      assert html =~ "rounded-lg border border-line-strong bg-panel"

      for tool <- ~w(bold mark link image variable),
          do: assert(html =~ ~s(data-lu-tool="#{tool}"))

      refute html =~ ~s(data-lu-tool="italic")
      refute html =~ "nope"
      assert html =~ ~s(aria-label="Destacar")
      assert html =~ ~s(aria-label="Bold")
    end

    test "content_class, disabled and the id from field" do
      form = to_form(%{"body" => "<b>x</b>"}, as: :post)
      assigns = %{f: form[:body]}
      html = rendered_to_string(~H|<.text_editor field={@f} content_class="h-72" disabled />|)
      assert html =~ ~s(id="post_body")
      assert html =~ ~s(name="post[body]")
      assert html =~ ~r/class="[^"]*min-h-\[110px\] h-72"/
      assert html =~ ~s(contenteditable="false")
      assert html =~ ~s(data-lu-disabled="true")
      assert html =~ "<b>x</b>"
    end

    test "label, help and errors wrap the editor" do
      assigns = %{}
      html = rendered_to_string(~H|<.text_editor name="n" label="Corpo" help="Dica" />|)
      assert html =~ "Corpo"
      assert html =~ "Dica"
      assert html =~ ~s(aria-labelledby="n-label")

      html = rendered_to_string(~H|<.text_editor name="n" errors={["Obrigatorio"]} />|)
      assert html =~ "Obrigatorio"
      assert html =~ ~s(aria-invalid="true")
    end

    test "the server cleans the HTML it renders" do
      assigns = %{v: ~S|<p onclick="x()">a</p><script>alert(1)</script><img src="x.png">|}
      html = rendered_to_string(~H|<.text_editor name="n" value={@v} />|)
      refute html =~ "onclick"
      refute html =~ "<script"
      refute html =~ "<img"
      assert html =~ "<p>a</p>"
    end

    test "config: slash, variables, mentions, events" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.text_editor
          name="n"
          slash
          variables={~w(cliente)}
          on_ai="write"
          on_slash="slash"
          on_change="chg"
          on_submit="sub"
          on_image="img"
          target="#t"
          footer
          hint="Dica"
          words_label="palavras"
        >
          <:ai>Escrever com IA</:ai>
        </.text_editor>
        """)

      assert html =~ ~s(data-lu-on-ai="write")
      assert html =~ ~s(data-lu-on-slash="slash")
      assert html =~ ~s(data-lu-on-change="chg")
      assert html =~ ~s(data-lu-on-submit="sub")
      assert html =~ ~s(data-lu-on-image="img")
      assert html =~ ~s(data-lu-target="#t")
      assert html =~ ~s(data-lu-tool="ai")
      assert html =~ "Escrever com IA"
      assert html =~ "palavras"
      assert html =~ "data-lu-words"
      assert html =~ "Dica"
      # config JSON carries slash items and variables
      assert html =~ "&quot;slash&quot;:true"
      assert html =~ "&quot;variables&quot;:[&quot;cliente&quot;]"
      assert html =~ "Heading 1"
    end

    test "comment variant: no toolbar, a bar with mention, actions and submit" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.text_editor
          name="c"
          variant="comment"
          on_submit="comment"
          mentions={[%{handle: "juliana", label: "Juliana"}]}
          submit_label="Comentar"
          submit_key="Enter"
          submit_hint="para enviar"
          mention_label="Mencionar"
        >
          <:actions><button type="button" class="lu-btn icon ghost sm">clip</button></:actions>
          <:attachments><span class="lu-chip">arq.pdf</span></:attachments>
        </.text_editor>
        """)

      refute html =~ ~s(role="toolbar")
      assert html =~ ~s(data-lu-variant="comment")
      assert html =~ ~s(data-part="text-editor-footer")
      assert html =~ ~s(aria-label="Mencionar")
      assert html =~ ~s(data-lu-tool="mention")
      assert html =~ "clip"
      assert html =~ "arq.pdf"
      assert html =~ ~r/<kbd data-part="kbd" class="[^"]*font-mono[^"]*">Enter<\/kbd>/
      assert html =~ "para enviar"
      assert html =~ ~s(data-lu-tool="submit")
      assert html =~ "Comentar"
      assert html =~ "juliana"
      assert html =~ "min-h-16"
    end

    test "comment bar can be dropped and the shortcut hidden" do
      assigns = %{}
      html = rendered_to_string(~H|<.text_editor name="c" variant="comment" bar={false} />|)
      refute html =~ ~s(data-lu-tool="submit")

      html = rendered_to_string(~H|<.text_editor name="c" variant="comment" submit_key={nil} />|)
      refute html =~ "<kbd"
      assert html =~ ~s(data-lu-tool="submit")

      html = rendered_to_string(~H|<.text_editor
  name="c"
  variant="comment"
  mention_button={false}
  mentions={[%{handle: "a", label: "A"}]}
/>|)
      refute html =~ ~s(data-lu-tool="mention")
    end

    test "needs an id" do
      assigns = %{}
      assert_raise ArgumentError, fn -> rendered_to_string(~H|<.text_editor />|) end
    end

    test "popups live under an ignored container" do
      assigns = %{}
      html = rendered_to_string(~H|<.text_editor name="n" />|)
      assert html =~ ~s(id="n-ui" phx-update="ignore")
      assert html =~ ~s(data-lu-pop="link")
      assert html =~ ~s(data-lu-pop="image")
      assert html =~ "data-lu-menu"
    end
  end

  describe "<.text_editor_content>" do
    test "shows safe html as is and escapes plain strings" do
      assigns = %{}

      html =
        rendered_to_string(~H|<.text_editor_content value={Phoenix.HTML.raw("<b>Oi</b>")} />|)

      assert html =~ "<b>Oi</b>"

      assigns = %{v: "<b>Oi</b>"}
      html = rendered_to_string(~H|<.text_editor_content value={@v} />|)
      assert html =~ "&lt;b&gt;Oi&lt;/b&gt;"
    end

    test "the inner block wins" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.text_editor_content value="ignored" class="x">
          <p>Olá, <strong>Joel</strong>!</p>
        </.text_editor_content>
        """)

      assert html =~ "<strong>Joel</strong>"
      refute html =~ "ignored"
      assert html =~ ~r/class="[^"]*leading-\[22px\][^"]* x"/
    end
  end

  describe "sanitize/2" do
    test "keeps formatting tags and drops attributes" do
      assert TextEditor.sanitize(~S|<p class="a" onclick="x()">Hi <b>you</b></p>|) ==
               "<p>Hi <b>you</b></p>"

      assert TextEditor.sanitize(
               "<h1>T</h1><ul><li>a</li></ul><blockquote>q</blockquote><pre>c</pre>"
             ) ==
               "<h1>T</h1><ul><li>a</li></ul><blockquote>q</blockquote><pre>c</pre>"

      assert TextEditor.sanitize("a<br>b<hr>") == "a<br>b<hr>"
    end

    test "drops script, iframe, style tags (their text is escaped text)" do
      out =
        TextEditor.sanitize(
          ~S|<script>alert(1)</script><iframe src="x"></iframe><style>a{}</style>ok|
        )

      refute out =~ "<"
      assert out =~ "ok"
    end

    test "escapes stray angle brackets and drops comments" do
      assert TextEditor.sanitize("1 < 2 and <!-- c -->x") == "1 &lt; 2 and x"
    end

    test "links: only safe schemes, with rel" do
      assert TextEditor.sanitize(~s(<a href="https://x.com/a?b=1&c=2" target="_blank">l</a>)) =~
               ~s(href="https://x.com/a?b=1&amp;c=2" rel="noopener noreferrer")

      refute TextEditor.sanitize(~S|<a href="javascript:alert(1)">l</a>|) =~ "href"
      refute TextEditor.sanitize(~s(<a href="//evil.com">l</a>)) =~ "href"
      refute TextEditor.sanitize(~s(<a href=" javascript:x">l</a>)) =~ "href"
      refute TextEditor.sanitize(~s(<a href="&#106;avascript:x">l</a>)) =~ "href"
      assert TextEditor.sanitize(~s(<a href="/rel">l</a>)) =~ ~s(href="/rel")
      assert TextEditor.sanitize(~s(<a href="mailto:a@b.c">l</a>)) =~ "mailto:a@b.c"
      # quotes cannot break out of the attribute
      out = TextEditor.sanitize(~s(<a href='https://x.com/"onmouseover="x'>l</a>))
      refute out =~ ~s("onmouseover)
    end

    test "images need images: true, a safe src and sane sizes" do
      img = ~S|<img src="https://x.com/a.png" alt="A" width="10" height="5000" onerror="x()">|
      refute TextEditor.sanitize(img) =~ "img"
      out = TextEditor.sanitize(img, images: true)
      assert out =~ ~s(<img src="https://x.com/a.png" alt="A" width="10">)
      refute out =~ "height"
      refute out =~ "onerror"

      for bad <- ~w(data:image/png;base64,AAA javascript:x //host/a.png) do
        refute TextEditor.sanitize(~s(<img src="#{bad}">), images: true) =~ "<img"
      end

      assert TextEditor.sanitize(~s(<img src="/up/a.png">), images: true) =~ ~s(src="/up/a.png")
      long = String.duplicate("a", 400)
      out = TextEditor.sanitize(~s(<img src="/a.png" alt="#{long}">), images: true)
      assert out =~ ~s(alt="#{String.duplicate("a", 300)}")
      refute out =~ String.duplicate("a", 301)
    end

    test "style is limited to typographic properties" do
      out =
        TextEditor.sanitize(
          ~S|<span style="color: red; position:fixed; background-color:#fff; background:url(x)">t</span>|
        )

      assert out =~ ~s(style="color:red;background-color:#fff")
      refute out =~ "position"
      refute out =~ "url"
      refute TextEditor.sanitize(~S|<span style="color:expression(alert(1))">t</span>|) =~ "style"
    end

    test "dir is kept only for ltr/rtl; nil and safe tuples" do
      assert TextEditor.sanitize(~s(<p dir="rtl">a</p><p dir="x">b</p>)) ==
               ~s(<p dir="rtl">a</p><p>b</p>)

      assert TextEditor.sanitize(nil) == ""
      assert TextEditor.sanitize(Phoenix.HTML.raw("<b>a</b>")) == "<b>a</b>"
    end

    test "upper-case tags are normalized" do
      assert TextEditor.sanitize("<B>a</B><SCRIPT>x</SCRIPT>") == "<b>a</b>x"
    end
  end

  describe "server helpers" do
    test "insert_html pushes sanitized html to the editor" do
      socket = %Phoenix.LiveView.Socket{}
      socket = TextEditor.insert_html(socket, "post", ~s(<b onclick="x">a</b>))
      assert %{"lu:editor:insert" => _} = push_events(socket)
      assert [%{id: "post", html: "<b>a</b>"}] = events(socket, "lu:editor:insert")
    end

    test "insert_image builds an escaped img and keeps only safe sources" do
      socket =
        TextEditor.insert_image(%Phoenix.LiveView.Socket{}, "post", "/up/a.png", ~s(A "photo"))

      [%{html: html}] = events(socket, "lu:editor:insert")
      assert html =~ ~s(src="/up/a.png")
      assert html =~ "alt="
      refute html =~ ~s(alt="A "photo")

      socket =
        TextEditor.insert_image(%Phoenix.LiveView.Socket{}, "post", "javascript:alert(1)", "x")

      [%{html: html}] = events(socket, "lu:editor:insert")
      refute html =~ "img"
    end
  end

  defp events(socket, name) do
    for [^name, payload] <- socket.private.live_temp[:push_events] |> Enum.reverse(), do: payload
  end

  defp push_events(socket) do
    Map.new(socket.private.live_temp[:push_events], fn [n, p] -> {n, p} end)
  end

  describe "canvas parity" do
    test "heading tool, no default content class and no inline popup styles" do
      assigns = %{}
      html = rendered_to_string(~H|<.text_editor name="e" toolbar={[~w(heading bold)]} />|)
      assert html =~ ~s(data-lu-tool="heading")
      refute html =~ "h-48"
      refute html =~ "position:fixed"
    end

    test "comment actions come before the mention button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.text_editor name="c" variant="comment" mentions={[%{handle: "a", label: "A"}]}>
          <:actions><button id="attach">x</button></:actions>
        </.text_editor>
        """)

      {a, _} = :binary.match(html, ~s(id="attach"))
      {m, _} = :binary.match(html, ~s(data-lu-tool="mention"))
      assert a < m
    end
  end
end
