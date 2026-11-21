defmodule Parity.Cases.FxShell do
  @moduledoc false
  # Rodada FX (shell/app): mesmos ids de fx_shell.py (lado original = marcação do bundle da referência).
  use Phoenix.Component
  use LedgerUI

  def cases do
    assigns = %{
      tools: [
        %{title: "buscar_pedidos", detail: "status=atrasado", ms: "0,4s"},
        %{title: "ler_extrato", detail: "Banco do Brasil", ms: "1,1s"},
        %{title: "conciliar", detail: "64 lançamentos", ms: "0,7s", running: true}
      ],
      colors: ~w(neutral secondary info success warning error)
    }

    %{
      "fx-ai-tool-trace-bare" =>
        ~H"""
        <.ai_tool_trace variant="bare" tools={@tools} />
        """,
      "fx-navbar-search-typing" =>
        ~H"""
        <.navbar_search demo="typing" value="pedidos" width="240px" style="height:36px;border-radius:10px" />
        """,
      "fx-theme-picker-menu-open" =>
        ~H"""
        <.theme_picker id="fx-tp" variant="menu" open themes={~w(ledger noite areia oceano)} default="ledger" />
        """,
      "fx-theme-switch-value" =>
        ~H"""
        <div style="display:flex;gap:10px;align-items:center;flex-wrap:wrap">
          <.theme_switch id="fx-ts1" value="dark" />
          <.theme_switch id="fx-ts2" value="system" variant="icons" />
          <.theme_switch id="fx-ts3" value="system" variant="icons" size="sm" />
          <.theme_switch id="fx-ts4" value="dark" variant="switch"><:icon><.icon name="moon" size="md" /></:icon></.theme_switch>
        </div>
        """,
      "fx-sidebar-nav-color" =>
        ~H"""
        <div style="display:flex;flex-direction:column;gap:6px">
          <.sidebar_nav_link :for={c <- @colors} active color={c}><.icon name="grid" size="md" />Item</.sidebar_nav_link>
        </div>
        """,
      "fx-sidebar-nav-count" =>
        ~H"""
        <div style="display:flex;flex-direction:column;gap:6px">
          <.sidebar_nav_link active><.icon name="cart" size="md" />Vendas<:count>1.096</:count></.sidebar_nav_link>
          <.sidebar_nav_link><.icon name="wallet" size="md" />Financeiro<:count>12</:count></.sidebar_nav_link>
          <.sidebar_nav_link><.icon name="plus" size="md" />Novo pedido<:count>N</:count></.sidebar_nav_link>
        </div>
        """,
      "fx-main-sidebar-count" =>
        ~H"""
        <div style="display:flex;gap:8px;padding:10px">
          <.main_sidebar_link label="Notas" count={3} count_tone="warn"><.icon name="invoice" /></.main_sidebar_link>
          <.main_sidebar_link label="Alertas" count={12}><.icon name="bell" /></.main_sidebar_link>
        </div>
        """,
      "fx-rail-workspace-bare" =>
        ~H"""
        <.rail_workspace name="Ledgerly" subtitle="Orbit Cloud · Finance" bare class="w-[280px]!"><svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true" style="fill:none;stroke:currentColor;stroke-width:2;stroke-linecap:round;stroke-linejoin:round"><path d="M4 19V5" /><path d="M4 19h16" /><path d="m8 14 3.5-4 3 2.5L19 7" /></svg></.rail_workspace>
        """,
      "fx-ai-chat-variants" =>
        ~H"""
        <div style="display:flex;flex-direction:column;gap:8px">
          <.ai_chat :for={v <- ~w(default canvas bare page)} id={"fx-chat-#{v}"} variant={v} compact start={false} composer={false} class="w-full"><span :if={v in ~w(canvas page)} class="text-[13px] leading-[18px] text-muted">variant={v}</span><div :if={v in ~w(default bare)}><span class="text-[13px] leading-[18px]">variant={v}</span></div></.ai_chat>
        </div>
        """
    }
  end
end
