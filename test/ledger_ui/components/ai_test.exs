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
    assert list =~ ~s(<strong>8 &lt;b&gt;x&lt;/b&gt;</strong>)
    assert list =~ "lu-badge neg"
    refute list =~ "lu-card"

    card = html(~H|<.ai_insights insights={@items} count={3} on_chat="chat" />|)
    assert card =~ "lu-card-h"
    assert card =~ "3 new"
    assert card =~ ~s(phx-click="chat")
  end

  test "ai_promo variants and tones" do
    assigns = %{}
    card = html(~H|<.ai_promo count={3} action="Run" />|)
    assert card =~ "lu-promo"
    assert card =~ "3 novas sugestões"
    assert card =~ "lu-btn primary block"

    rail = html(~H|<.ai_promo variant="rail" tone="warm" count={2} />|)
    assert rail =~ "lu-aura m-spin t-warn"
  end

  test "ai_message roles, variants, status and actions" do
    assigns = %{}
    user = html(~H|<.ai_message role="user" name="Marina Costa">oi</.ai_message>|)
    assert user =~ "lu-msg me"
    assert user =~ "MC"

    card = html(~H|<.ai_message>x</.ai_message>|)
    assert card =~ "lu-panel"

    plain =
      html(~H|<.ai_message variant="plain" streaming actions={[:copy, "useful"]}>x</.ai_message>|)

    refute plain =~ "lu-panel"
    assert plain =~ "lu-stream-cursor"
    refute plain =~ "lu-dots"

    streaming_card = html(~H|<.ai_message streaming>x</.ai_message>|)
    assert streaming_card =~ "lu-panel lu-stream-cursor"
    refute html(~H|<.ai_message>x</.ai_message>|) =~ "lu-stream-cursor"
    assert plain =~ ~s(aria-label="Copiar")
    assert plain =~ ~s(aria-label="Útil")

    err = html(~H|<.ai_message status="error">falhou</.ai_message>|)
    assert err =~ "color:var(--neg)"
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
    assert pending =~ "<s class=\"lu-muted\">A</s>"
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
    assert definition =~ "lu-badge pos"
  end

  test "ai_tool_trace" do
    assigns = %{tools: [%{label: "a", detail: "d", ms: "1ms"}, %{label: "b", failed: true}]}
    closed = html(~H|<.ai_tool_trace tools={@tools} duration_ms={1800} />|)
    assert closed =~ "Usou 2 ferramentas"
    assert closed =~ "1.8s"
    refute closed =~ " open"
    assert closed =~ "warn-circle"

    open = html(~H|<.ai_tool_trace tools={@tools} expanded running />|)
    assert open =~ "open"
    assert open =~ "Em andamento"
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
    refute streaming =~ ~s(type="submit")

    canvas = html(~H|<.ai_composer variant="canvas" mic send_label="Enviar" />|)
    assert canvas =~ "Microfone"
    assert canvas =~ "lu-btn primary"
  end

  test "prompt_suggestions variants" do
    assigns = %{items: [%{title: "Resumo", text: "Faça um resumo", icon: "file", tone: "acc"}]}
    card = html(~H|<.prompt_suggestions items={@items} on_pick="ask" />|)
    assert card =~ "lu-prompt"
    assert card =~ "rotate("
    assert card =~ ~s(phx-value-value="Faça um resumo")

    flat = html(~H|<.prompt_suggestions items={@items} tilt={false} />|)
    refute flat =~ "rotate("

    pill = html(~H|<.prompt_suggestions items={@items} variant="pill" />|)
    assert pill =~ "border-radius:999px"

    grid = html(~H|<.prompt_suggestions items={@items} variant="grid" />|)
    assert grid =~ "text-transform:uppercase"
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

    assert out =~ ~s(<div class="lu-nav-h">Hoje</div>)
    assert out =~ ~s(<div class="lu-nav-h">Ontem</div>)
    assert out =~ "lu-nav-item on"
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
    assert out =~ "lu-ai-greet"
    assert out =~ "font-size:30px"
    assert out =~ "#ec4899"
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
    refute bare =~ "lu-panel"
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
end
