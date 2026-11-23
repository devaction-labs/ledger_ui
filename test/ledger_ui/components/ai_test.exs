defmodule LedgerUI.Components.AiTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LedgerUI.Components.Ai

  defp html(rendered), do: rendered_to_string(rendered)

  test "ai_insights list and card, bold text is escaped" do
    assigns = %{
      items: [
        %{
          icon: "warn-circle",
          title: "T",
          text: "**8 <b>x</b>** atraso",
          impact: "-$1",
          tone: "neg",
          action: "Go"
        }
      ]
    }

    list = html(~H|<.ai_insights variant="list" insights={@items} />|)

    assert list =~
             ~s(<strong data-part="ai-insight-strong" class="font-semibold text-ink">8 &lt;b&gt;x&lt;/b&gt;</strong>)

    assert list =~ ~s(data-part="ai-insights")
    assert list =~ "bg-neg-soft"
    refute list =~ "ai-insights-header"

    card = html(~H|<.ai_insights insights={@items} count={3} on_chat="chat" />|)
    assert card =~ ~s(data-part="ai-insights-header")
    assert card =~ "bg-tray"
    assert card =~ "3 new"
    assert card =~ ~s(aria-label="Abrir chat")
    assert card =~ ~s(phx-click="chat")
  end

  test "ai_promo variants and tones" do
    assigns = %{}
    card = html(~H|<.ai_promo count={3} action="Run" />|)
    assert card =~ ~s(data-part="ai-promo")
    assert card =~ "3 novas sugestões"
    assert card =~ "bg-inverse"
    assert card =~ "w-full"

    rail = html(~H|<.ai_promo variant="rail" tone="warm" count={2} />|)
    assert rail =~ ~s(data-part="aura")
    assert rail =~ "[--t1:var(--lu-warn)]"
    assert rail =~ ~s(data-part="ai-promo")
    refute rail =~ ~r/class="(lu-|[^"]* lu-)/

    ai = html(~H|<.ai_promo variant="rail" />|)
    assert ai =~ "[--t1:var(--lu-ai-1)]"
  end

  test "ai_message roles, variants, status and actions" do
    assigns = %{}
    user = html(~H|<.ai_message role="user" name="Marina Costa">oi</.ai_message>|)
    assert user =~ "flex-row-reverse"
    assert user =~ "bg-inverse"
    assert user =~ "MC"

    card = html(~H|<.ai_message>x</.ai_message>|)
    assert card =~ "bg-panel"
    assert card =~ ~s(data-part="ai-message-content")

    plain =
      html(~H|<.ai_message variant="plain" streaming actions={[:copy, "useful"]}>x</.ai_message>|)

    refute plain =~ "bg-panel"
    assert plain =~ "after:animate-[lu-caret_1s_steps(1)_infinite]"
    refute plain =~ "lu-bounce"

    streaming_card = html(~H|<.ai_message streaming>x</.ai_message>|)
    assert streaming_card =~ "bg-panel"
    assert streaming_card =~ "after:animate-[lu-caret_1s_steps(1)_infinite]"
    refute html(~H|<.ai_message>x</.ai_message>|) =~ "lu-caret"

    thinking = html(~H|<.ai_message thinking />|)
    assert thinking =~ ~s(data-part="ai-message-typing")
    assert thinking =~ "animate-[lu-bounce_1s_.3s_infinite]"
    refute thinking =~ "ai-message-content"
    assert plain =~ ~s(aria-label="Copiar")
    assert plain =~ ~s(aria-label="Útil")

    err = html(~H|<.ai_message status="error">falhou</.ai_message>|)
    assert err =~ "text-neg"
    assert err =~ ~s(data-lu-status="error")
  end

  test "ai_proposal by status" do
    assigns = %{}

    pending =
      html(~H"""
      <.ai_proposal
        id="p1"
        title="Trocar"
        editable
        on_approve="ok"
        on_reject="no"
        on_edit="ed"
        pending_note="Nota"
      >
        <:change label="Linha" from="A" to="B" />
        <:change label="Fato">texto</:change>
      </.ai_proposal>
      """)

    assert pending =~ "Aguardando você"
    assert pending =~ ~s(phx-click="ok")
    assert pending =~ ~s(phx-value-id="p1")
    assert pending =~ "Editar"
    assert pending =~ "Nota"
    assert pending =~ "<s data-part=\"ai-proposal-from\" class=\"text-muted\">A</s>"
    assert pending =~ "texto"

    approved =
      html(~H|<.ai_proposal id="p2" title="T" status={:approved} note="Feito" on_undo="undo" />|)

    assert approved =~ "Aprovado"
    assert approved =~ "Desfazer"
    assert approved =~ "Feito"
    refute approved =~ "Aprovar"

    definition = html(~H|<.ai_proposal id="p3" title="T" layout="definition">
  <:change label="S" from="a" to="b" />
</.ai_proposal>|)
    assert definition =~ "bg-pos-soft"
  end

  test "ai_tool_trace loop: each row runs (spinner) and ends (check) on a staggered delay" do
    assigns = %{tools: [%{label: "a"}, %{label: "b"}]}
    out = html(~H|<.ai_tool_trace tools={@tools} loop expanded />|)
    assert out =~ "animate-[mo-runrow_6s_var(--dl)_infinite]"
    assert out =~ "animate-[mo-okin_6s_var(--dl)_infinite]"
    assert out =~ "mo-rnout_6s_var(--dl)_infinite"
    assert out =~ "--dl:0.0s"
    assert out =~ "--dl:1.1s"
    refute html(~H|<.ai_tool_trace tools={@tools} />|) =~ "mo-runrow"
  end

  test "ai_tool_trace" do
    assigns = %{tools: [%{label: "a", detail: "d", ms: "1ms"}, %{label: "b", failed: true}]}
    closed = html(~H|<.ai_tool_trace tools={@tools} duration_ms={1800} />|)
    assert closed =~ "Usou 2 ferramentas"
    assert closed =~ "1,8s"
    refute closed =~ " open"
    assert closed =~ "warn-circle"
    assert closed =~ "group-open:border-b"
    refute closed =~ ~r/class="[^"]*\sborder-b\s/
    refute closed =~ "group-open:rotate-180"

    open = html(~H|<.ai_tool_trace tools={@tools} expanded running />|)
    assert open =~ "open"
    assert open =~ "Em andamento"
  end

  test "ai_tool_trace: decimal separator follows the locale" do
    assigns = %{tools: [%{label: "a"}]}
    assert html(~H|<.ai_tool_trace tools={@tools} duration_ms={2400} locale="pt_BR" />|) =~ "2,4s"
    en = html(~H|<.ai_tool_trace tools={@tools} duration_ms={2400} locale="en" />|)
    assert en =~ "2.4s"
    refute en =~ "2,4s"
  end

  test "ai_tool_trace: free summary text, chevron and sans names" do
    assigns = %{tools: [%{title: "Procurou em", detail: "empenhos", ms: "0,8s"}]}

    out =
      html(
        ~H|<.ai_tool_trace tools={@tools} summary_text="1 passo · conferiu" chevron name_style="sans" />|
      )

    assert out =~ "1 passo · conferiu"
    refute out =~ "Usou 1 ferramenta"
    assert out =~ "group-open:rotate-180"
    assert out =~ "font-medium text-ink"
    refute out =~ "font-mono text-[12.5px]"

    default = html(~H|<.ai_tool_trace tools={@tools} />|)
    assert default =~ "font-mono text-[12.5px]"
    assert default =~ "Usou 1 ferramenta"
  end

  test "ai_tool_trace: running row spins with ms dash; error row only colors the icon" do
    assigns = %{
      tools: [
        %{title: "Calculando", running: true},
        %{title: "Consultou", failed: true, detail: "tempo esgotado", ms: "30,0s"}
      ]
    }

    out = html(~H|<.ai_tool_trace tools={@tools} expanded />|)
    [running, failed] = String.split(out, ~s(data-part="ai-tool-trace-row"), parts: 3) |> tl()
    assert running =~ ~s(data-part="spinner")
    assert running =~ "animate-[lu-spin_"
    assert running =~ "motion-reduce:animate-none"
    assert running =~ "—"
    refute running =~ "huge-refresh"
    assert failed =~ "text-neg"
    assert failed =~ "tempo esgotado"
    # only the icon is neg: the name keeps the ink
    refute out =~ ~r/row"[^>]*class="[^"]*text-neg/
    assert failed =~ ~r/ai-tool-trace-name" class="[^"]*text-ink/
  end

  test "ai_composer is a form with the hook, field and attachments" do
    form = Phoenix.Component.to_form(%{"pergunta" => "oi"}, as: :ai)
    assigns = %{form: form}

    out =
      html(~H"""
      <.ai_composer
        id="c"
        field={@form[:pergunta]}
        context={[:pedidos, %{label: "X", icon: "table"}]}
        attachments={[%{name: "a.csv", size: 2048}]}
        phx-submit="send"
      />
      """)

    assert out =~ "<form"
    assert out =~ ~s(phx-hook="LedgerUI.AiComposer")
    assert out =~ ~s(name="ai[pergunta]")
    assert out =~ "oi</textarea>"
    assert out =~ "Pedidos"
    assert out =~ "a.csv"
    assert out =~ "2.0 KB"
    assert out =~ ~s(phx-submit="send")
    assert out =~ ~s(type="submit")

    streaming = html(~H|<.ai_composer id="c" streaming on_stop="stop" />|)
    assert streaming =~ "Parar"
    assert streaming =~ "data-lu-streaming"
    refute html(~H|<.ai_composer id="c" />|) =~ "data-lu-streaming"
    refute streaming =~ ~s(type="submit")

    canvas = html(~H|<.ai_composer variant="canvas" mic send_label="Enviar" />|)
    assert canvas =~ "Microfone"
    assert canvas =~ "bg-inverse"
    assert canvas =~ "flex-row items-center"
  end

  test "prompt_suggestions variants" do
    assigns = %{items: [%{title: "Resumo", text: "Faça um resumo", icon: "file", tone: "acc"}]}
    card = html(~H|<.prompt_suggestions items={@items} on_pick="ask" />|)
    assert card =~ ~s(data-part="prompt-suggestion")
    assert card =~ "-rotate-[0.6deg]"
    assert card =~ ~s(phx-value-value="Faça um resumo")

    flat = html(~H|<.prompt_suggestions items={@items} tilt={false} />|)
    refute flat =~ "rotate-"

    pill = html(~H|<.prompt_suggestions items={@items} variant="pill" />|)
    assert pill =~ "rounded-full"
    assert pill =~ "text-accent-content"
    assert pill =~ ~s(phx-value-value="Faça um resumo")
    assert pill =~ "<button"

    grid = html(~H|<.prompt_suggestions items={@items} variant="grid" />|)
    assert grid =~ "uppercase"
    assert grid =~ "bg-sunken"
  end

  test "prompt_suggestions pill: value apart from the text, and links" do
    assigns = %{
      items: [
        %{text: "por trimestre", value: "granularity:quarter"},
        %{text: "vendas por mês", navigate: "/assistente"},
        %{text: "externo", href: "https://x.test"}
      ]
    }

    out = html(~H|<.prompt_suggestions items={@items} variant="pill" on_pick="adjust" />|)
    assert out =~ ~s(phx-value-value="granularity:quarter")
    refute out =~ ~s(phx-value-value="por trimestre")
    assert out =~ ~s(href="/assistente")
    assert out =~ ~s(data-phx-link="redirect")
    assert out =~ ~s(href="https://x.test")
    assert length(String.split(out, "<button")) == 2
    refute out =~ "text-accent-content"
  end

  test "conversation_list groups by day, marks active and filters" do
    assigns = %{
      convs: [
        %{id: 1, title: "Boletos", day: "Hoje", pending: true},
        %{id: 2, title: "Notas", day: "Hoje", navigate: "/c/2"},
        %{id: 3, title: "Resumo", day: "Ontem", content: "churn"}
      ]
    }

    out =
      html(
        ~H|<.conversation_list conversations={@convs} active={1} on_new="new" on_select="open" />|
      )

    assert out =~
             ~r(<div data-part="conversation-heading" class="[^"]*text-muted[^"]*">Hoje</div>)

    assert out =~
             ~r(<div data-part="conversation-heading" class="[^"]*text-muted[^"]*">Ontem</div>)

    assert out =~ ~s(aria-current="true")
    assert out =~ "bg-selected"
    assert out =~ ~s(phx-click="open")
    assert out =~ "Ação pendente"
    assert out =~ "⌘ J"

    filtered = html(~H|<.conversation_list conversations={@convs} search="churn" />|)
    assert filtered =~ "Resumo"
    refute filtered =~ "Boletos"
  end

  test "ai_greeting uses the given line" do
    assigns = %{}

    out =
      html(~H|<.ai_greeting name="Marina" greeting="Boa tarde, Marina" size="sm" tone="warm" />|)

    assert out =~ "Boa tarde, Marina"
    assert out =~ ~s(data-part="ai-greeting")
    assert out =~ "text-[30px]"
    assert out =~ "#ec4899"
    assert out =~ "starting:opacity-0"
  end

  test "ai_chat with a list: messages, proposal, composer, start state" do
    assigns = %{
      messages: [
        %{id: 1, role: :user, text: "Oi", name: "Marina Costa"},
        %{
          id: 2,
          role: :assistant,
          text: "Achei **1 pedido**.\n\nSegundo parágrafo.",
          trace: %{tools: [%{label: "Pedidos"}], duration_ms: 3000},
          proposal: %{
            id: "p1",
            title: "Trocar",
            changes: [%{label: "Linha", from: "A", to: "B"}, %{label: "Fato", text: "ok"}]
          }
        }
      ]
    }

    out =
      html(
        ~H|<.ai_chat id="chat" messages={@messages} on_send="send" on_approve="approve" footnote="Aviso" />|
      )

    assert out =~ ~s(id="chat-msg-1")
    assert out =~ "<b>1 pedido</b>"
    assert out =~ "Segundo parágrafo."
    assert out =~ "Usou 1 ferramenta"
    assert out =~ ~s(phx-click="approve")
    assert out =~ ~s(id="chat-composer")
    assert out =~ ~s(phx-submit="send")
    assert out =~ "Aviso"
    refute out =~ ~s(phx-update="stream")

    start = html(~H|<.ai_chat id="c2" user="Marina Costa">
  <:suggestion title="Resumo" prompt="Faça">Resumo do dia</:suggestion>
</.ai_chat>|)
    assert start =~ "Marina"
    assert start =~ "Resumo do dia"

    bare = html(~H|<.ai_chat id="c3" variant="bare" composer={false} />|)
    refute bare =~ "<form"
    refute bare =~ "bg-panel"
  end

  test "ai_chat accepts a stream" do
    stream =
      Phoenix.LiveView.LiveStream.new(
        :messages,
        make_ref(),
        [%{id: 7, role: :user, text: "A"}],
        []
      )

    assigns = %{stream: stream}
    out = html(~H|<.ai_chat id="s" messages={@stream} />|)
    assert out =~ ~s(phx-update="stream")
    assert out =~ ~s(id="messages-7")
  end

  test "ai_tool_trace bare: no summary, a div, no border on the first row" do
    assigns = %{tools: [%{title: "a", ms: "1s"}, %{title: "b", ms: "2s"}]}
    out = html(~H|<.ai_tool_trace variant="bare" expanded tools={@tools} />|)
    refute out =~ "<summary"
    refute out =~ "<details"
    assert out =~ ~s(data-part="ai-tool-trace")
    [first, second] = String.split(out, ~s(data-part="ai-tool-trace-row"), parts: 3) |> tl()
    assert first =~ "border-t-0"
    assert second =~ "border-t"
    refute second =~ "border-t-0"

    assert html(~H|<.ai_tool_trace summary={false} tools={@tools} />|) =~
             ~r/<div [^>]*data-part="ai-tool-trace"/

    assert html(~H|<.ai_tool_trace tools={@tools} expanded />|) =~ "<summary"
  end

  test "ai_chat variants and compact" do
    assigns = %{}

    for {v, cls} <- [{"default", "border-line"}, {"canvas", "bg-sunken"}, {"page", "shadow-"}] do
      out =
        html(~H|<.ai_chat id="c" variant={v} compact start={false} composer={false}>x</.ai_chat>|)

      assert out =~ cls
      assert out =~ "p-3"
    end

    page = html(~H|<.ai_chat id="c" variant="page" compact start={false} composer={false} />|)
    refute page =~ "p-3.5"
    refute page =~ "min-h-full"
  end
end
