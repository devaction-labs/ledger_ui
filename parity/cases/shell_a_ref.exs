defmodule Parity.Cases.ShellARef do
  @moduledoc false
  # Shell/app, parte A: the HEEx side of the cases drawn from the reference generator (`shell_a_ref.py`).
  use Phoenix.Component
  use LedgerUI
  import Parity.Common

  defp tok(kind, text) do
    class =
      %{"k" => "text-[#7fd4c3]", "f" => "text-[#a5b8f5]", "c" => "text-[oklch(from_var(--color-gray-500)_0.5563_c_h)]"}[kind]

    ~s(<span data-part="code-token" class="#{class}">#{text}</span>)
  end

  defp raw(html), do: Phoenix.HTML.raw(html)

  def cases do
    assigns = %{
      insights: [
        %{
          icon: "warn-circle",
          title: "Churn led by Pro",
          text: "**7 of 11** Pro cancels followed a failed payment.",
          impact: "−$3,400 MRR",
          tone: "neg",
          action: "Recover"
        },
        %{
          icon: "users",
          title: "Seat expansion ready",
          text: "**14 Scale accounts** are above 90% of seats.",
          impact: "+$4,200 potential",
          tone: "lime",
          action: "View accounts"
        },
        %{
          icon: "trend-up",
          title: "Strongest cohort start",
          text: "September kept **97%** at M1, best this year.",
          impact: "+2 pts vs avg",
          tone: "pos",
          action: "Compare"
        }
      ],
      convs: [
        %{id: 1, title: "Por que o churn subiu em outubro?", day: "Hoje"},
        %{id: 2, title: "Contas Scale perto do limite", day: "Hoje"},
        %{id: 3, title: "Comparar coorte de setembro", day: "Últimos 7 dias"},
        %{id: 4, title: "Resumo para o board", day: "Últimos 7 dias"},
        %{id: 5, title: "Previsão de MRR Q4", day: "Últimos 7 dias"}
      ],
      tools: [
        %{title: "stripe.list_cancellations", detail: "oct 2026 · 23 rows", ms: "640ms"},
        %{title: "cohorts.compare", detail: "sep vs avg", ms: "410ms"},
        %{title: "accounts.seat_usage", detail: "executando…", ms: "—", running: true}
      ],
      spans: [
        %{title: "ai.answer", icon: "chevron-down", depth: 0, start: 0, width: 100, color: "var(--lu-accent-500)", duration: "1.84s"},
        %{title: "plan", icon: "circle", depth: 1, start: 0, width: 12, color: "var(--lu-accent-300)", duration: "220ms"},
        %{title: "stripe.list", icon: "circle", depth: 1, start: 12, width: 35, color: "var(--lu-accent-500)", duration: "640ms"},
        %{title: "cohorts.compare", icon: "circle", depth: 1, start: 47, width: 22, color: "var(--lu-accent-500)", duration: "410ms"},
        %{title: "seat_usage", icon: "circle", depth: 1, start: 69, width: 8, color: "var(--lu-neg)", duration: "timeout"},
        %{title: "compose", icon: "circle", depth: 1, start: 77, width: 23, color: "var(--lu-accent-400)", duration: "420ms"}
      ],
      code_lines: [
        %{html: raw(tok("k", "defmodule") <> " " <> tok("f", "Ledgerly.Churn") <> " " <> tok("k", "do"))},
        %{html: raw("  " <> tok("c", "# MRR perdido no período, por plano"))},
        %{html: raw("  " <> tok("k", "def") <> " " <> tok("f", "by_plan") <> "(period) " <> tok("k", "do"))},
        %{html: raw("    Repo.all(" <> tok("f", "cancellations") <> "(period))"), variant: "removed"},
        %{
          html:
            raw(
              "    period |&gt; " <>
                tok("f", "cancellations") <>
                "() |&gt; " <> tok("f", "reject_recovered") <> "() |&gt; Repo.all()"
            ),
          variant: "added"
        },
        %{html: raw("    |&gt; Enum.group_by(&amp; &amp;1.plan, &amp; &amp;1.mrr_cents)")},
        %{html: raw("  " <> tok("k", "end"))},
        %{html: raw(tok("k", "end"))}
      ]
    }

    %{
      "ref-ai-insights" => ~H"""
      <div style="max-width:440px">
        <.ai_insights insights={@insights} count={3} on_chat="chat" />
      </div>
      """,
      "ref-ai-promo" => ~H"""
      <div style="width:260px">
        <.ai_promo title="Ledgerly AI" subtitle="3 new revenue insights" text="Ask why revenue moved and get the accounts behind it." action="Run AI insights" />
      </div>
      """,
      "ref-ai-message" => ~H"""
      <div style="display:flex;flex-direction:column;gap:16px">
        <.ai_message role="user">Por que o churn subiu em outubro?</.ai_message>
        <.ai_message variant="plain" actions={~w(copy useful useless regenerate)}>
          <div>O churn subiu <b>0,4 pts</b> por causa de <b>23 contas</b>. Dessas, <b>7 de 11</b> cancelamentos Pro vieram logo após uma falha de pagamento.</div>
        </.ai_message>
        <.ai_message thinking />
      </div>
      """,
      "ref-ai-composer" => ~H"""
      <div style="max-width:640px">
        <.ai_composer id="rc1" mention mention_label="Mencionar conta" placeholder="Pergunte sobre receita, churn ou contas…" context={[%{label: "Cohorts", icon: "table"}]} />
      </div>
      """,
      "ref-conversation-list" => ~H"""
      <div style="width:300px">
        <.conversation_list conversations={@convs} active={1} on_new="new" shortcut="" />
      </div>
      """,
      "ref-ai-proposal" => ~H"""
      <.ai_proposal id="rp1" title="Ativar retentativa inteligente para o plano Pro" layout="table" editable pending_label="Aguardando aprovação">
        <:change label="Retentativas" from="2" to="4" />
        <:change label="Intervalo" from="3 dias" to="1, 3, 5, 7 dias" />
        <:change label="E-mail ao cliente" from="Não" to="Dia 1" />
        <:impact>
          <.badge canvas color="lime">+$3,400 MRR recuperável</.badge>
          <span class="text-[13px] leading-[18px] text-muted">baseado em 7 contas</span>
        </:impact>
      </.ai_proposal>
      """,
      "ref-ai-tool-trace" => ~H"""
      <.ai_tool_trace tools={@tools} duration_ms={1800} expanded />
      """,
      "ref-trace" => ~H"""
      <.trace spans={@spans} />
      """,
      "ref-code-block" => ~H"""
      <.code_block id="rcb1" title="lib/ledgerly/churn.ex" icon="code" lines={@code_lines} line_numbers copy copy_label="Copiar" />
      """,
      "ref-glow-text" => ~H"""
      <div style="display:flex;flex-direction:column;gap:10px">
        <.glow_text as="div" style="font-size:44px">Assistente Signetum</.glow_text>
        <.glow_text as="div" style="font-size:32px">tone=default · h1</.glow_text>
        <.glow_text as="div" tone="warm" style="font-size:24px">tone=warm · h2</.glow_text>
        <.glow_text style="font-size:15px">as=span dentro do texto</.glow_text>
      </div>
      """
    }
  end
end
