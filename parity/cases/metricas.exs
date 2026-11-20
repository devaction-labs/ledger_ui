defmodule Parity.Cases.Metricas do
  use Phoenix.Component
  use LedgerUI

  # Métricas e gráficos: kpi_card, sparkline, bar_chart, donut_chart, waterfall_chart, cohort_heatmap,
  # line_chart, bar_list, heatmap. Os mesmos ids existem em metricas.py (que carrega o instantâneo da lib
  # anterior à migração, `metricas_orig.json`, ver metricas_snapshot.sh).
  def cases do
    mrr = [120, 124, 123, 131, 129, 138, 142, 150, 149, 158, 166, 170, 184]
    users = [900, 920, 915, 950, 980, 1001, 1020, 1050, 1080, 1096]
    down = [30, 28, 31, 27, 25, 26, 22, 24, 21, 19, 20, 17]

    cohort = [
      %{label: "Jan", values: [100, 94, 91, 88, 86, 85]},
      %{label: "Feb", values: [100, 95, 91, 89, 87, 85]},
      %{label: "Mar", values: [100, 93, 89, 86, 84, 82]},
      %{label: "Apr", values: [100, 95, 92, 90, 88, 86]},
      %{label: "May", values: [100, 96, 93, 90, 89, 87]},
      %{label: "Jun", values: [100, 94, 90, 88, 87, nil]},
      %{label: "Jul", values: [100, 96, 93, 91, nil, nil]},
      %{label: "Aug", values: [100, 95, 92, nil, nil, nil]},
      %{label: "Sep", values: [100, 97, nil, nil, nil, nil]},
      %{label: "Oct", values: [100, nil, nil, nil, nil, nil]}
    ]

    m26 = [114000, 118400, 123100, 128500, 134100, 140600, 147900, 156190, 169460, 184320]
    m25 = [72000, 75500, 79000, 83000, 87400, 91800, 95200, 98300, 101200, 104100]
    months = ~w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct)

    plans = [
      %{name: "Pro", value: 96900, color: "var(--chart-1)"},
      %{name: "Scale", value: 49020, color: "var(--chart-2)"},
      %{name: "Starter", value: 38400, color: "var(--chart-5)"}
    ]

    five = [
      %{name: "Pro", value: 40, color: "var(--chart-1)"},
      %{name: "Scale", value: 25, color: "var(--chart-2)"},
      %{name: "Starter", value: 15, color: "var(--chart-3)"},
      %{name: "Free", value: 12, color: "var(--chart-4)"},
      %{name: "Trial", value: 8, color: "var(--chart-5)"}
    ]

    steps = [
      %{name: "New", value: 18400, label: "+$18.4k", color: "var(--chart-1)"},
      %{name: "Expand", value: 6200, label: "+$6.2k", color: "var(--chart-5)"},
      %{name: "Contract", value: -2100, label: "−$2.1k", color: "var(--chart-3)"},
      %{name: "Churn", value: -7600, label: "−$7.6k", color: "var(--chart-4)"},
      %{name: "Net", value: 14900, label: "$14.9k", total: true, color: "var(--chart-2)"}
    ]

    assigns = %{
      mrr: mrr, users: users, down: down, cohort: cohort, m26: m26, m25: m25, months: months,
      plans: plans, five: five, steps: steps,
      tip: fn i ->
        net = if i == 0, do: 0, else: Enum.at(m26, i) - Enum.at(m26, i - 1)

        [
          ["2026", LedgerUI.Components.Chart.money(Enum.at(m26, i)), "acc"],
          ["2025", LedgerUI.Components.Chart.money(Enum.at(m25, i)), "ghost"],
          ["Net new", "+" <> LedgerUI.Components.Chart.money(net), "lime"]
        ]
      end
    }

    %{
      # ------------------------------------------------------------------ kpi_card
      "kpi-card-canvas" => ~H"""
      <div style="display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:14px">
        <.kpi_card id="k1" label="MRR" prefix="$" value="184,320" live delta="8.8%" compare="vs $169,460 in Sep" spark={@mrr} open_label="Abrir" />
        <.kpi_card id="k2" label="Net new MRR" prefix="$" value="14,860" delta="12%" compare="vs September" />
        <.kpi_card id="k3" label="Churn rate" value="2.1" unit="%" trend="up" delta_tone="error" delta="0.4 pts" compare="23 accounts" />
        <.kpi_card id="k4" label="Net revenue retention" value="108" unit="%" delta="2 pts" compare="trailing 12 mo" />
      </div>
      """,
      "kpi-card-trend" => ~H"""
      <div style="display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:14px">
        <.kpi_card id="t1" label="Cancelamentos" value="23" trend="down" delta="0,4 pt" compare="vs outubro" />
        <.kpi_card id="t2" label="Ticket médio" prefix="R$" value="168" trend="flat" delta="0%" compare="estável" />
        <.kpi_card id="t3" label="Inadimplência" value="4,2" unit="%" trend="down" delta_tone="error" delta="0,6 pt" compare="vs outubro" />
      </div>
      """,
      "kpi-card-spark" => ~H"""
      <div style="display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:14px">
        <.kpi_card id="s1" label="Clientes" value="1.096" delta="48" compare="este mês" spark={@users} open_label="Abrir" />
        <.kpi_card id="s2" label="Churn" value="17" trend="down" delta="3" compare="vs mês passado" spark={@down} />
      </div>
      """,
      "kpi-card-progress" => ~H"""
      <div style="display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:14px">
        <.kpi_card id="p1" label="Meta do mês" value="72" unit="%" progress={72} caption="R$ 184 mil de R$ 256 mil" />
        <.kpi_card id="p2" label="Sem delta" value="1.284" unit="un" caption="estoque" gap={false} />
        <.kpi_card id="p3" label="Com ícone" value="42" unit="k" prefix="R$" delta="8,8%" compare="vs outubro">
          <:icon><.icon name="huge-wallet" size="md" /></:icon>
        </.kpi_card>
      </div>
      """,
      "kpi-card-badge" => ~H"""
      <div style="display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:12px">
        <.kpi_card variant="badge" color="neutral" label="Faturamento" prefix="R$" value="184.320" delta="8,8%" compare="vs outubro" trend="up" />
        <.kpi_card variant="badge" color="neutral" label="Pedidos" value="1.096" delta="12%" compare="vs outubro" trend="up" />
        <.kpi_card variant="badge" color="neutral" label="Cancelamentos" value="23" delta="0,4 pt" compare="vs outubro" trend="down" />
        <.kpi_card variant="badge" color="neutral" label="Ticket médio" prefix="R$" value="168" delta="0%" compare="vs outubro" trend="flat" />
      </div>
      """,
      "kpi-card-badge-icon" => ~H"""
      <div style="display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:12px">
        <.kpi_card variant="badge" color="neutral" layout="stack" icon_tone="pos" label="Recebido" prefix="R$" value="42" unit="k" delta="8,8%" compare="vs outubro" trend="up">
          <:icon><.icon name="huge-wallet" size="md" /></:icon>
        </.kpi_card>
        <.kpi_card variant="badge" color="neutral" layout="inline" icon_tone="neg" label="Em atraso" prefix="R$" value="8" unit="k" delta="8,8%" compare="vs outubro" trend="down">
          <:icon><.icon name="huge-alert" size="md" /></:icon>
        </.kpi_card>
        <.kpi_card variant="badge" color="neutral" layout="inline" icon_tone="warn" label="Estoque baixo" value="12" delta="8,8%" compare="vs outubro" trend="flat">
          <:icon><.icon name="huge-layers" size="md" /></:icon>
        </.kpi_card>
        <.kpi_card variant="badge" color="neutral" layout="stack" icon_tone="info" label="Clientes" value="312" delta="8,8%" compare="vs outubro" trend="up">
          <:icon><.icon name="huge-users" size="md" /></:icon>
        </.kpi_card>
      </div>
      """,
      "kpi-card-badge-count" => ~H"""
      <div style="display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px">
        <.kpi_card variant="badge" color="neutral" label="Faturamento" prefix="R$" count={184320} delta="8,8%" compare="vs outubro" trend="up" />
        <.kpi_card variant="badge" color="neutral" label="Pedidos" count={1096} delta="12%" compare="vs outubro" trend="up" />
        <.kpi_card variant="badge" color="neutral" label="Cancelamentos" count={23} delta="0,4 pt" compare="vs outubro" trend="down" />
      </div>
      """,
      "kpi-card-loading" => ~H"""
      <div style="display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:14px">
        <.kpi_card loading label="x" value="1" />
        <.kpi_card label="Pronto" value="1" />
      </div>
      """,
      # ------------------------------------------------------------------ sparkline
      "sparkline-colors" => ~H"""
      <div style="display:flex;gap:16px;flex-wrap:wrap">
        <div style="padding:12px 14px;display:flex;gap:16px;align-items:center;width:300px">
          <div style="display:flex;flex-direction:column;gap:2px"><span>MRR</span><b>$184k</b></div>
          <.sparkline id="sp1" values={@mrr} color="primary" style="flex:1;min-width:0;height:46px" />
        </div>
        <div style="padding:12px 14px;display:flex;gap:16px;align-items:center;width:300px">
          <div style="display:flex;flex-direction:column;gap:2px"><span>Clientes</span><b>1.096</b></div>
          <.sparkline id="sp2" values={@users} style="flex:1;min-width:0;height:46px" />
        </div>
      </div>
      """,
      "sparkline-shapes" => ~H"""
      <div style="display:flex;gap:16px;flex-wrap:wrap;align-items:flex-end">
        <.sparkline id="sp3" values={[5]} style="width:120px;height:40px" />
        <.sparkline id="sp4" values={[3, 3, 3, 3]} color="primary" style="width:120px;height:40px" />
        <.sparkline id="sp5" values={@down} style="width:200px;height:70px" />
        <.sparkline id="sp6" values={[]} style="width:120px;height:40px" />
      </div>
      """,
      # ------------------------------------------------------------------ bar_chart
      "bar-chart-default" => ~H"""
      <div style="width:320px">
        <.bar_chart data={Enum.zip(~w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct), [40, 52, 48, 61, 58, 66, 72, 69, 80, 92])} labels={~w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct)} highlight="Oct" />
      </div>
      """,
      "bar-chart-shapes" => ~H"""
      <div style="display:flex;gap:20px;align-items:flex-end">
        <.bar_chart height="120px" width="160px" shape="round" values={[40, 55, 48, 66, 58, 72, 69, 92]} />
        <.bar_chart height="120px" width="160px" shape="square" values={[40, 55, 48, 66, 58, 72, 69, 92]} />
        <.bar_chart height="90px" width="160px" values={[10, 20, 30, 40]} highlight={1} labels={~w(Q1 Q2 Q3 Q4)} titles={~w(a b c d)} />
        <.bar_chart height="90px" width="160px" values={[10, 20, 30, 40]} highlight={nil} />
      </div>
      """,
      # ------------------------------------------------------------------ donut_chart
      "donut-chart-default" => ~H"""
      <div style="width:380px">
        <.donut_chart id="d1" label="Receita por plano" center_label="TOTAL MRR" center_value="$184.3k" segments={@plans} />
      </div>
      """,
      "donut-chart-variants" => ~H"""
      <div style="display:flex;gap:30px;align-items:flex-start">
        <div style="width:300px"><.donut_chart id="d2" segments={@five} value_format={fn v -> "#{v}" end} /></div>
        <div style="width:200px"><.donut_chart id="d3" segments={@plans} rows={false} center_label="MRR" /></div>
      </div>
      """,
      # ------------------------------------------------------------------ waterfall_chart
      "waterfall-chart-default" => ~H"""
      <div style="width:480px">
        <.waterfall_chart id="w1" label="Movimento de MRR" steps={@steps} />
      </div>
      """,
      "waterfall-chart-auto" => ~H"""
      <div style="width:480px">
        <.waterfall_chart id="w2" steps={[%{name: "In", value: 12000, label: "+12k"}, %{name: "Out", value: -5000, label: "-5k"}, %{name: "Total", value: 7000, label: "7k", total: true}]} max={15000} ticks={5} />
      </div>
      """,
      # ------------------------------------------------------------------ cohort_heatmap
      "cohort-heatmap-default" => ~H"""
      <div style="width:560px">
        <.cohort_heatmap columns={~w(M0 M1 M2 M3 M4 M5)} rows={@cohort} />
      </div>
      """,
      "cohort-heatmap-thresholds" => ~H"""
      <div style="width:420px">
        <.cohort_heatmap columns={~w(M0 M1 M2)} suffix=" pt" thresholds={[20, 40, 60, 80]} rows={[%{label: "A", values: [10, 30, 50]}, %{label: "B", values: [70, 90, nil]}, %{label: "C", values: [100, nil, nil]}]} />
      </div>
      """,
      # ------------------------------------------------------------------ line_chart
      "line-chart-default" => ~H"""
      <div style="width:640px;padding:16px">
        <.line_chart id="l1" label="MRR month" head="+$70,320" sub="since January" labels={@months} min={60000} max={240000} ticks={3} pin={7} width={608}
          series={[%{name: "2026", values: @m26, area: true}, %{name: "2025", values: @m25, dashed: true, color: "var(--chart-ghost)"}]}
          tip={@tip} />
      </div>
      """,
      "line-chart-single" => ~H"""
      <div style="width:560px;padding:16px">
        <.line_chart id="l2" labels={@months} min={100000} max={200000} ticks={4} width={528} height={200} label_every={2}
          series={[%{name: "2026", values: @m26, area: true}]} sub_delta="+12,4%" head="$184k" sub="no mês" />
      </div>
      """,
      "line-chart-sub-delta" => ~H"""
      <div style="width:560px;padding:16px">
        <.line_chart id="l3" labels={@months} min={60000} max={200000} ticks={3} width={528} height={220} pin={9}
          head="-$3k" sub="vs. mês passado" sub_delta="-2,1%" sub_delta_tone="neg"
          series={[%{values: @m25, area: true}, %{values: @m26, color: "var(--chart-3)"}]} />
      </div>
      """,
      # ------------------------------------------------------------------ bar_list / heatmap
      "bar-list-default" => ~H"""
      <div style="width:360px">
        <.bar_list label="Canais">
          <:item label="Balcão" value="R$ 46 mil" amount={46} />
          <:item label="Online" value="R$ 33 mil" amount={33} />
          <:item label="Parceiros" value="R$ 12 mil" amount={12} />
        </.bar_list>
      </div>
      """,
      "heatmap-default" => ~H"""
      <div style="display:flex;gap:30px;align-items:flex-start">
        <.heatmap label="Atividade" columns={10} levels={Enum.map(0..49, &rem(&1 * 7, 5))} less="Menos" more="Mais" />
        <.heatmap label="Quadrado" columns={7} size={16} shape="square" levels={Enum.map(0..27, &rem(&1 * 3, 5))} />
      </div>
      """
    }
  end
end
