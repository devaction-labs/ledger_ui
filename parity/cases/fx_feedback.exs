defmodule Parity.Cases.FxFeedback do
  @moduledoc false
  # Rodada de correções: casos novos dos recursos acrescentados. Mesmos ids de `fx_feedback.py`.
  use Phoenix.Component
  use LedgerUI
  import Parity.Common

  def cases do
    assigns = %{}

    %{
      "fx-toast-steps" => ~H"""
      <.colm>
        <.toast_card kind="primary" icon="layers" title="Emitindo lote #118" description="Validando, assinando e transmitindo." steps={5} step={0} dismissible={false} />
        <.toast_card kind="primary" icon="layers" title="Emitindo lote #118" description="Passo 3 de 5." steps={5} step={2} dismissible={false} />
        <.toast_card kind="primary" icon="layers" title="Lote concluído" description="Todos os passos." steps={4} step={4} dismissible={false} />
      </.colm>
      """,
      "fx-ring" => ~H"""
      <.row>
        <.progress_ring value={64} />
        <.progress_ring value={92} />
        <.progress_ring value={0} />
        <.progress_ring value={100} />
      </.row>
      """,
      "fx-conn" => ~H"""
      <.colm>
        <.connection_banner preview state="off" label="Sem conexão" />
        <.connection_banner preview state="re" label="Reconectando…" />
        <.connection_banner preview state="on" label="Conectado" />
      </.colm>
      """,
      "fx-palette-nomatch" => ~H"""
      <.command_palette id="pm" state="no_match" query="bolet" empty={~s(Nada encontrado para "bolet".)} assistant={%{label: "Perguntar ao assistente"}} />
      """,
      "fx-tooltip-tip" => ~H"""
      <div style="display:flex;flex-direction:column;gap:22px;padding:8px 0 10px 8px;align-items:flex-start">
        <.tooltip_tip size="md" arrow="bottom">Buscar <.kbd variant="dark">⌘K</.kbd></.tooltip_tip>
        <.tooltip_tip size="md" arrow="left">Salvar rascunho</.tooltip_tip>
        <.tooltip_tip size="md" arrow="top">Em cima</.tooltip_tip>
      </div>
      """,
      "fx-count-delta" => ~H"""
      <.row>
        <.count>23</.count>
        <.count tone="warning">8</.count>
        <.count>128</.count>
        <.delta trend="up">8.8%</.delta>
        <.delta trend="down">0.4 pts</.delta>
        <.delta trend="up" tone="error">0.4 pts</.delta>
        <.badge canvas color="primary" dot="live">Live</.badge>
      </.row>
      """,
      "fx-error-compact" => ~H"""
      <.error_state code={404} compact title="Página não encontrada" description="O endereço pode ter mudado." />
      """
    }
  end
end
