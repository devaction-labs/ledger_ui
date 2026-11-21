defmodule Parity.Cases.Metrics do
  use Phoenix.Component
  use LedgerUI

  def cases do
    v1 = [120, 132, 128, 141, 138, 150, 158, 154, 166, 172, 181, 196]
    v3 = [30, 28, 31, 27, 25, 26, 22, 24, 21, 19, 20, 17]
    v4 = [12, 14, 13, 13, 15, 14, 16, 15, 16, 17, 16, 18]
    assigns = %{v1: v1, v3: v3, v4: v4}

    %{
      "stat-default" => ~H"""
      <.stat_group>
        <.stat_item label="Subtotal" value="R$ 3.240" />
        <.stat_item label="Desconto" value="− R$ 120" />
        <.stat_item label="Frete" value="R$ 0" hint="grátis acima de R$ 300" />
        <.stat_item label="Total" value="R$ 3.120" tone="accent" />
      </.stat_group>
      """,
      "stat-sunken" => ~H"""
      <.stat_group variant="sunken">
        <.stat_item label="Estoque" value="1.284" unit="un" />
        <.stat_item label="Reservado" value="96" unit="un" />
        <.stat_item label="Giro" value="18" unit="dias" />
        <.stat_item label="Cobertura" value="42" unit="dias" tone="accent" />
      </.stat_group>
      """,
      "stat-bare" => ~H"""
      <.stat_group card={false}>
        <.stat_item label="Abertas" value="12" />
        <.stat_item label="Vencidas" value="3" delta="1" delta_tone="bad" />
        <.stat_item label="Pagas no mês" value="R$ 48,2 mil" delta="9%" />
      </.stat_group>
      """,
      "stat-rich" => ~H"""
      <.stat_group>
        <.stat_item label="Faturamento" value="R$ 184.320" icon="huge-wallet" delta="12,4%" hint="vs. outubro" spark={@v1} />
        <.stat_item label="Cancelamentos" value="23" icon="huge-alert" delta="0,4 pt" trend="down" hint="caiu" spark={@v3} spark_tone="pos" />
        <.stat_item label="Ticket médio" value="R$ 168" icon="huge-tag" delta="0%" trend="flat" hint="estável" spark={@v4} spark_tone="muted" />
        <.stat_item label="Meta do mês" value="72%" size="sm" goal={72} goal_label="R$ 184 mil de R$ 256 mil" />
      </.stat_group>
      """
    }
  end
end
