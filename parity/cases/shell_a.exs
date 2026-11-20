defmodule Parity.Cases.ShellA do
  @moduledoc false
  # Shell/app, parte A: ai (chat, composer, insights, message, promo, proposal, tool trace, conversation list,
  # prompt suggestions, greeting), code_block, email (preview), glow_text, tool, trace. The ORIGINAL side
  # of most cases (`shell_a.py`) is a snapshot of THIS file rendered with the pre-migration library
  # (lu-* classes, commit 3506478) on the legacy stylesheet: see `shell_a_snapshot.sh`. A few cases
  # are drawn from the reference generator (c6.py) instead.
  use Phoenix.Component
  use LedgerUI
  import Parity.Common

  defp insights do
    [
      %{
        icon: "warn-circle",
        title: "Boletos vencidos",
        text: "**8 clientes** somam R$ 12.400 em atraso.",
        impact: "-R$ 12.400",
        tone: "neg",
        action: "Ver clientes"
      },
      %{
        icon: "trend-up",
        title: "Café em alta",
        text: "Vendas **+32%** na semana.",
        impact: "+32%",
        tone: "pos",
        action: "Abrir relatório"
      },
      %{icon: "layers", title: "Estoque baixo", text: "**12 itens** abaixo do mínimo."}
    ]
  end

  defp convs do
    [
      %{id: 1, title: "Por que o churn subiu em outubro?", day: "Hoje", pending: true},
      %{id: 2, title: "Contas Scale perto do limite", day: "Hoje", status: "Em andamento"},
      %{id: 3, title: "Comparar coorte de setembro", day: "Últimos 7 dias"},
      %{id: 4, title: "Resumo para o board", day: "Últimos 7 dias"}
    ]
  end

  defp suggestions do
    [
      %{icon: "user-minus", tone: "neg", text: "Quais 23 contas fizeram o churn subir?", title: "Churn"},
      %{icon: "trend-up", tone: "pos", text: "O que puxou o crescimento de agosto?", title: "Receita"},
      %{icon: "table", tone: "acc", text: "Compare a coorte de setembro com a média", title: "Coortes"},
      %{icon: "users", tone: "lime", text: "Quem está perto do limite de assentos?", title: "Assentos"}
    ]
  end

  defp tools do
    [
      %{title: "stripe.list_cancellations", detail: "oct 2026 · 23 rows", ms: "640ms"},
      %{title: "cohorts.compare", detail: "sep vs avg", ms: "410ms"},
      %{title: "accounts.seat_usage", detail: "executando…", ms: "—", running: true}
    ]
  end

  defp messages do
    [
      %{id: 1, role: :user, text: "Por que o churn subiu em outubro?", name: "Ikram Souza"},
      %{
        id: 2,
        role: :assistant,
        text: "O churn subiu **0,4 pts** por causa de **23 contas**.\n\nSete de onze cancelamentos vieram após falha de pagamento.",
        trace: %{tools: tools(), duration_ms: 1800}
      },
      %{
        id: 3,
        role: :assistant,
        text: "Posso ativar a retentativa inteligente.",
        proposal: %{
          id: "p1",
          title: "Ativar retentativa inteligente",
          changes: [%{label: "Retentativas", from: "2", to: "4"}, %{label: "Intervalo", from: "3 dias", to: "1, 3, 5, 7 dias"}]
        }
      }
    ]
  end

  @elixir """
  defmodule Ledgerly.Churn do
    # MRR perdido no período, por plano
    def by_plan(period) do
      Repo.all(cancellations(period), timeout: 5_000)
    end
  end
  """

  def cases do
    assigns = %{
      insights: insights(),
      convs: convs(),
      suggestions: suggestions(),
      tools: tools(),
      messages: messages(),
      code: @elixir,
      diff: [
        "defmodule Ledgerly.Churn do",
        "  def by_plan(period) do",
        %{text: "    Repo.all(cancellations(period))", variant: "removed"},
        %{text: "    period |> cancellations() |> reject_recovered() |> Repo.all()", variant: "added"},
        %{text: "    |> Enum.group_by(& &1.plan, & &1.mrr_cents)", variant: "highlighted"},
        "  end",
        "end"
      ]
    }

    %{
      # ---------------------------------------------------------------- glow_text
      "glow-text-tones" => ~H"""
      <.colm>
        <.glow_text as="div" style="font-size:44px">Assistente Signetum</.glow_text>
        <.glow_text as="h1" style="font-size:32px;margin:0">tone=default · h1</.glow_text>
        <.glow_text as="div" tone="warm" style="font-size:24px">tone=warm · h2</.glow_text>
        <div>texto <.glow_text style="font-size:15px">as=span</.glow_text> dentro do texto</div>
      </.colm>
      """,
      # ---------------------------------------------------------------- code_block
      "code-block-basic" => ~H"""
      <.code_block id="cb1" title="lib/ledgerly/churn.ex" icon="code" language="elixir" code={@code} line_numbers copy />
      """,
      "code-block-plain" => ~H"""
      <.colm>
        <.code_block id="cb2" code={"$ mix deps.get\nResolving Hex dependencies...\nAll dependencies are up to date"} />
        <.code_block id="cb3" title="Terminal" icon="terminal" code={"pnpm --version\n9.12.0"} size="sm" wrap />
        <.code_block id="cb4" code={"line one\nline two"} copy />
      </.colm>
      """,
      "code-block-diff" => ~H"""
      <.code_block id="cb5" title="churn.ex" icon="code" language="elixir" lines={@diff} line_numbers />
      """,
      "code-block-variants" => ~H"""
      <.colm>
        <.code_block id="cb6" title="stderr" icon="terminal" variant="destructive" size="sm" code={"error: lint failed\n  1 problem"} />
        <.code_block id="cb7" code={"a very long line that wraps because the block is narrow and wrap is on, so that the text takes more lines than one"} wrap max_height={48} />
        <.code_block id="cb8" title="js" language="js" code={"const x = 42 // answer\nreturn `ok ${x}`"} highlight={[2]} line_numbers />
      </.colm>
      """,
      "code-block-parts" => ~H"""
      <.code_block id="cb9" title="Saída" code={"ok"} copy>
        <:actions><span>Ação</span></:actions>
        <:footer><div style="padding:8px 14px;border-top:1px solid #252927;font-size:12px;color:#9ba19e">2 linhas</div></:footer>
      </.code_block>
      """,
      # ---------------------------------------------------------------- email (preview)
      "email-preview" => ~H"""
      <.email_layout variant="preview" subject="Resumo" brand="Ledgerly" title="Seu resumo de outubro">
        <:body><p style="margin:0">Oi Ikram, o MRR cresceu <b>8,8%</b> e chegou a <b>$184,320</b>. Três insights novos esperam por você.</p></:body>
        <:action href="#">Abrir dashboard</:action>
        <:footer>Você recebe este e-mail porque é admin do workspace Orbit Cloud.</:footer>
      </.email_layout>
      """,
      "email-preview-bare" => ~H"""
      <.email_layout variant="preview" subject="Resumo" title="Sem marca nem rodapé">
        <:body><p style="margin:0">Só o título e o texto.</p></:body>
      </.email_layout>
      """,
      # ---------------------------------------------------------------- trace
      "trace-lines" => ~H"""
      <.trace>
        <.trace_line icon="brain" title="Thought for 5s" />
        <.trace_line icon="terminal" description="0.4s">Ran <code>pnpm --version</code></.trace_line>
        <.trace_line icon="terminal" status="error">Failed to run <code>pnpm install</code></.trace_line>
        <.trace_line icon="terminal" status="running">Running <code>pnpm lint</code></.trace_line>
        <.trace_line icon="terminal" status="pending">Waiting to run <code>pnpm test</code></.trace_line>
        <.trace_line navigate="/x" icon="file" title="Open the file" end_icon="arrow-right" />
      </.trace>
      """,
      "trace-spans" => ~H"""
      <.trace>
        <.trace_line title="ai.answer" icon="chevron-down" depth={0} duration="1.84s" bar={%{start: 0, width: 100}} />
        <.trace_line title="plan" icon="circle" depth={1} duration="220ms" bar={%{start: 0, width: 12}} />
        <.trace_line title="stripe.list" icon="circle" depth={1} duration="640ms" bar={%{start: 12, width: 35}} />
        <.trace_line title="seat_usage" icon="circle" depth={1} duration="timeout" bar={%{start: 69, width: 8}} />
      </.trace>
      """,
      "trace-steps" => ~H"""
      <.trace>
        <.trace_step icon="terminal" title="Ran node --version" open><pre style="margin:0">v24.18.0</pre></.trace_step>
        <.trace_step icon="terminal" status="error" title="Failed pnpm lint" description="2 problems"><pre style="margin:0">error</pre></.trace_step>
        <.trace_step icon="brain"><:summary>Thought <b>for 5s</b></:summary>text</.trace_step>
      </.trace>
      """,
      # ---------------------------------------------------------------- tool
      "tool-lines" => ~H"""
      <.trace>
        <.tool id="t1" state="running" subject="pnpm install" />
        <.tool id="t2" state="waiting" subject="pnpm test" />
        <.tool id="t3" state="done" subject="node --version" output="v24.18.0" open />
        <.tool id="t4" state="error" subject="pnpm lint" input="pnpm lint" output={"error: 2 problems"} open />
        <.tool id="t5" state="denied" subject="rm -rf" locale="pt_BR" />
        <.tool id="t6" state="done" title="Custom title" description="0.3s" />
      </.trace>
      """,
      "tool-panels" => ~H"""
      <.colm>
        <.tool id="p1" variant="panel" icon="tool" state="running" indicator="ring" title="sefaz.autorizar" description="NF-e 48.211" />
        <.tool id="p2" variant="panel" icon="tool" state="running" title="Transmitindo à SEFAZ" />
        <.tool id="p3" variant="panel" icon="tool" state="waiting" title="Aguardando aprovação" />
        <.tool id="p4" variant="panel" icon="tool" state="done" title="XML assinado" />
        <.tool id="p5" variant="panel" icon="tool" state="error" title="Certificado vencido" />
        <.tool id="p6" variant="panel" icon="tool" state="denied" title="Acesso negado" />
      </.colm>
      """,
      "tool-approval" => ~H"""
      <.colm>
        <.tool_approval id="a1" subject="pnpm install" description="Instala as dependências" input="pnpm install --frozen-lockfile" />
        <.tool_approval id="a2" title="Apagar o cache?" locale="pt_BR" />
      </.colm>
      """,
      # ---------------------------------------------------------------- ai_insights
      "ai-insights-card" => ~H"""
      <.ai_insights insights={@insights} count={3} on_chat="chat" />
      """,
      "ai-insights-list" => ~H"""
      <.ai_insights variant="list" insights={@insights} />
      """,
      # ---------------------------------------------------------------- ai_promo
      "ai-promo-card" => ~H"""
      <div style="width:260px">
        <.ai_promo count={3} text="Ask why revenue moved and get the accounts behind it." action="Run AI insights" />
      </div>
      """,
      "ai-promo-rail" => ~H"""
      <.colm>
        <div style="width:260px"><.ai_promo variant="rail" count={3} on_click="open" /></div>
        <div style="width:260px"><.ai_promo variant="rail" tone="warm" title="Assistente" subtitle="2 alertas" /></div>
      </.colm>
      """,
      # ---------------------------------------------------------------- ai_greeting
      "ai-greeting" => ~H"""
      <.colm>
        <.ai_greeting greeting="Bom dia, Ikram" />
        <.ai_greeting greeting="Black Friday" tone="warm" size="md" tagline="Veja as ofertas" />
        <.ai_greeting greeting="Olá" size="sm" />
      </.colm>
      """,
      # ---------------------------------------------------------------- ai_message
      "ai-message-roles" => ~H"""
      <.colm>
        <.ai_message role="user" name="Ikram Souza">Por que o churn subiu em outubro?</.ai_message>
        <.ai_message role="user">Sem avatar</.ai_message>
        <.ai_message actions={~w(copy useful useless regenerate)}>O churn subiu <b>0,4 pts</b> por causa de <b>23 contas</b>.</.ai_message>
        <.ai_message variant="plain" actions={~w(copy)}>Texto solto ao lado da faísca.</.ai_message>
        <.ai_message status="error">Não consegui acessar o extrato.</.ai_message>
      </.colm>
      """,
      "ai-message-stream" => ~H"""
      <.colm>
        <.ai_message streaming><div>Encontrei 14 contas</div></.ai_message>
        <.ai_message variant="plain" streaming><div>Escrevendo a resposta</div></.ai_message>
        <.ai_message streaming>Texto direto</.ai_message>
      </.colm>
      """,
      "ai-message-trace" => ~H"""
      <.ai_message>
        <:trace><.ai_tool_trace tools={@tools} duration_ms={1800} expanded /></:trace>
        Resposta com rastro.
      </.ai_message>
      """,
      # ---------------------------------------------------------------- ai_tool_trace
      "ai-tool-trace-open" => ~H"""
      <.colm>
        <.ai_tool_trace tools={@tools} duration_ms={1800} expanded />
        <.ai_tool_trace tools={@tools} duration_ms={1800} />
        <.ai_tool_trace tools={[%{label: "buscar", failed: true, detail: "timeout", ms: "5s"}]} running />
        <.ai_tool_trace tools={[%{label: "ler"}]} />
      </.colm>
      """,
      # ---------------------------------------------------------------- ai_proposal
      "ai-proposal-pending" => ~H"""
      <.ai_proposal id="pp1" title="Ativar retentativa inteligente para o plano Pro" layout="table" editable pending_note="Nada muda sem sua aprovação">
        <:change label="Retentativas" from="2" to="4" />
        <:change label="Intervalo" from="3 dias" to="1, 3, 5, 7 dias" />
        <:change label="E-mail ao cliente">Dia 1</:change>
        <:impact>
          <b>+$3,400 MRR recuperável</b>
          <span style="font-size:13px">baseado em 7 contas</span>
        </:impact>
      </.ai_proposal>
      """,
      "ai-proposal-layouts" => ~H"""
      <.colm>
        <.ai_proposal id="pp2" title="Lista" layout="list" note="Uma nota">
          <:change label="Limite" from="R$ 1.000" to="R$ 2.000" />
          <:change label="Texto">Livre</:change>
          <:preview label="Mensagem">Olá, cliente.</:preview>
          <:impact label="Impacto"><b>+R$ 1.000</b></:impact>
        </.ai_proposal>
        <.ai_proposal id="pp3" title="Definição" layout="definition" status="approved" note="Feito" on_undo="undo">
          <:change label="Limite" from="R$ 1.000" to="R$ 2.000" />
        </.ai_proposal>
      </.colm>
      """,
      "ai-proposal-status" => ~H"""
      <.colm>
        <.ai_proposal id="ps1" title="Aplicando" status="applying"><:change label="A" from="1" to="2" /></.ai_proposal>
        <.ai_proposal id="ps2" title="Recusada" status="rejected" note="Recusada por você"><:change label="A" from="1" to="2" /></.ai_proposal>
        <.ai_proposal id="ps3" title="Falhou" status="failed"><:change label="A" from="1" to="2" /><:action><span>Tentar de novo</span></:action></.ai_proposal>
      </.colm>
      """,
      # ---------------------------------------------------------------- ai_composer
      "ai-composer-default" => ~H"""
      <div style="max-width:640px">
        <.ai_composer id="co1" context={[:pedidos, %{label: "Cohorts", icon: "table"}]} mention />
      </div>
      """,
      "ai-composer-states" => ~H"""
      <.colm>
        <.ai_composer id="co2" value="Quais clientes estão com boleto vencido?" attachments={[%{name: "extrato.pdf", size: 2048}, %{name: "nota.xml"}]} placeholder="Pergunte" />
        <.ai_composer id="co3" streaming value="Escrevendo..." />
      </.colm>
      """,
      "ai-composer-canvas" => ~H"""
      <div style="max-width:640px">
        <.ai_composer id="co4" variant="canvas" mic mention send_label="Enviar" />
      </div>
      """,
      # ---------------------------------------------------------------- prompt_suggestions
      "prompt-suggestions-card" => ~H"""
      <.colm>
        <.prompt_suggestions items={@suggestions} />
        <.prompt_suggestions items={@suggestions} tilt={false} />
      </.colm>
      """,
      "prompt-suggestions-pill-grid" => ~H"""
      <.colm>
        <.prompt_suggestions items={@suggestions} variant="pill" />
        <.prompt_suggestions items={@suggestions} variant="grid" />
      </.colm>
      """,
      # ---------------------------------------------------------------- conversation_list
      "conversation-list-card" => ~H"""
      <div style="width:300px">
        <.conversation_list conversations={@convs} active={1} on_new="new" on_search="search" />
      </div>
      """,
      "conversation-list-rail" => ~H"""
      <div style="width:260px;height:420px">
        <.conversation_list conversations={@convs} current={2} variant="rail" on_new="new" shortcut="" search="coorte" on_search="search" />
      </div>
      """,
      # ---------------------------------------------------------------- ai_chat
      "ai-chat-card" => ~H"""
      <div style="max-width:640px;height:560px">
        <.ai_chat id="ch1" messages={@messages} user="Ikram Souza" context={[:pedidos]} footnote="A IA pode errar. Confira os números.">
          <:header><.icon name="sparkles" size="md" /><b>Ledgerly AI</b></:header>
        </.ai_chat>
      </div>
      """,
      "ai-chat-start" => ~H"""
      <div style="max-width:640px;height:520px">
        <.ai_chat id="ch2" messages={[]} user="Ikram Souza" greeting="Olá, Ikram">
          <:suggestion title="Churn" prompt="Quais contas?">Quais contas fizeram o churn subir?</:suggestion>
          <:suggestion title="Receita" prompt="O que puxou?">O que puxou o crescimento?</:suggestion>
        </.ai_chat>
      </div>
      """,
      "ai-chat-variants" => ~H"""
      <.colm>
        <div style="height:260px"><.ai_chat id="ch3" variant="bare" messages={@messages} composer={false} /></div>
        <div style="height:300px"><.ai_chat id="ch4" variant="page" messages={Enum.take(@messages, 1)} streaming /></div>
      </.colm>
      """
    }
  end
end
