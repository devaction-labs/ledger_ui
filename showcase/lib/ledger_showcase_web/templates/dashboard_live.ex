defmodule LedgerShowcaseWeb.Templates.DashboardLive do
  @moduledoc """
  The dashboard template (`/templates/dashboard`): the month's goal, four KPIs, the revenue line
  chart (the Dia / Mês / Ano switch re-draws it), sales by channel (donut), the latest orders and
  the activity feed. The numbers are mock data, in integer reais/cents.

  The hero is `hero_card` and the KPI strip `stat_group` with `stat_item`s (canvas v2).
  """
  use Phoenix.LiveView
  use LedgerUI

  alias LedgerShowcase.Templates, as: T
  alias LedgerShowcaseWeb.Templates.Shell
  alias Phoenix.LiveView.JS

  # Monthly revenue (reais) Feb..Nov 2026 and the same months of 2025.
  @month_labels ~w(Fev Mar Abr Mai Jun Jul Ago Set Out Nov)
  @month_2026 [
    114_000,
    118_400,
    123_100,
    128_500,
    134_100,
    140_600,
    147_900,
    156_190,
    163_990,
    184_320
  ]
  @month_2025 [
    92_000,
    95_500,
    99_000,
    103_000,
    107_400,
    111_800,
    115_200,
    118_300,
    121_200,
    124_100
  ]

  @day_labels ~w(12 13 14 15 16 17 18 19 20 21)
  @day_now [5_900, 6_400, 5_100, 7_200, 8_900, 4_300, 6_800, 7_500, 8_100, 9_300]
  @day_before [5_100, 5_800, 5_600, 6_200, 7_300, 3_900, 6_100, 6_400, 6_900, 7_400]

  @year_labels ~w(2022 2023 2024 2025 2026)
  @year_now [980_000, 1_240_000, 1_510_000, 1_730_000, 2_010_000]
  @year_before [820_000, 980_000, 1_240_000, 1_510_000, 1_730_000]

  # `{name, share in %, reais, color}`: the donut is drawn from the shares.
  @channels [
    {"Loja física", 45, 82_940, "var(--chart-1)"},
    {"WhatsApp", 30, 55_300, "var(--chart-2)"},
    {"iFood", 15, 27_650, "var(--chart-5)"},
    {"Site", 10, 18_430, "var(--chart-3)"}
  ]

  @kpis [
    %{
      icon: "wallet",
      label: "Faturamento",
      value: "R$ 184.320",
      dir: "up",
      delta: "12,4%",
      note: "vs. outubro",
      spk: "acc",
      values: [0, 35, 23, 61, 52, 87, 110, 98, 133, 151, 177, 220]
    },
    %{
      icon: "cart",
      label: "Pedidos",
      value: "1.096",
      dir: "up",
      delta: "8,1%",
      note: "vs. outubro",
      spk: "acc",
      values: [6, 30, 0, 48, 77, 59, 95, 131, 113, 149, 184, 220]
    },
    %{
      icon: "alert",
      label: "Cancelamentos",
      value: "23",
      dir: "down",
      delta: "0,4 pt",
      note: "caiu",
      spk: "pos",
      values: [204, 173, 220, 157, 126, 141, 79, 110, 63, 31, 47, 0]
    },
    %{
      icon: "tag",
      label: "Ticket médio",
      value: "R$ 168",
      dir: "flat",
      delta: "0%",
      note: "estável",
      spk: "mut",
      values: [0, 73, 37, 37, 110, 73, 147, 110, 147, 183, 147, 220]
    }
  ]

  @activity [
    %{
      tone: "success",
      icon: "check",
      title: "NF-e 48.211 autorizada",
      sub: "Pedido #2491 · Feira Boa",
      at: "14:02"
    },
    %{
      tone: "info",
      icon: "truck",
      title: "Saiu para entrega",
      sub: "Rota Centro · Rita",
      at: "13:40"
    },
    %{
      tone: "warning",
      icon: "alert",
      title: "Estoque baixo: café 500 g",
      sub: "Restam 6 unidades",
      at: "12:15"
    },
    %{
      tone: "success",
      icon: "wallet",
      title: "Pix recebido",
      sub: "Bom Preço · R$ 3.120,50",
      at: "11:02"
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Painel · Templates", slug: "dashboard", range: "mes")}
  end

  @impl true
  def handle_event("range", %{"value" => range}, socket) when range in ~w(dia mes ano) do
    {:noreply, assign(socket, range: range)}
  end

  def handle_event("go", %{"to" => to}, socket) when to in ["tabela", "tabela-modal"] do
    {:noreply, push_navigate(socket, to: "/templates/" <> to)}
  end

  defp series("dia"),
    do: %{
      labels: @day_labels,
      now: @day_now,
      before: @day_before,
      min: 0,
      max: 10_000,
      ticks: 5,
      head: "R$ 9.300",
      sub: "hoje, 21 nov, vs. ontem",
      delta: "+25,7%",
      names: {"Hoje", "Ontem"},
      title: &"#{&1} nov"
    }

  defp series("ano"),
    do: %{
      labels: @year_labels,
      now: @year_now,
      before: @year_before,
      min: 0,
      max: 2_500_000,
      ticks: 5,
      head: "R$ 2,01 mi",
      sub: "em 2026 até novembro, vs. 2025",
      delta: "+16,2%",
      names: {"Ano", "Ano anterior"},
      title: & &1
    }

  defp series(_),
    do: %{
      labels: @month_labels,
      now: @month_2026,
      before: @month_2025,
      min: 0,
      max: 200_000,
      ticks: 4,
      head: "R$ 184.320",
      sub: "em novembro, vs. outubro",
      delta: "+12,4%",
      names: {"2026", "2025"},
      title: &"#{&1} 2026"
    }

  # Tooltip figures: "R$ 184 mil", "R$ 2,01 mi".
  defp mil(v) when v >= 1_000_000, do: "R$ " <> num_pt(v / 1_000_000, 2) <> " mi"
  defp mil(v) when v >= 1000, do: "R$ #{round(v / 1000)} mil"
  defp mil(v), do: "R$ #{v}"

  # Round, short figures for the Y axis ("0", "50 mil", "1,5 mi"); the unit is in the head.
  defp short(v) when v >= 1_000_000, do: num_pt(v / 1_000_000, 1) <> " mi"
  defp short(v) when v >= 1000, do: num_pt(v / 1000, 1) <> " mil"
  defp short(v), do: Integer.to_string(round(v))

  defp num_pt(f, digits) do
    r = Float.round(f, digits)

    if r == Float.round(r),
      do: Integer.to_string(round(r)),
      else: String.replace("#{r}", ".", ",")
  end

  defp reais(v), do: "R$ " <> T.group(v)

  defp delta_pct(a, b) when b > 0 do
    pct = (a - b) / b * 100
    "#{if pct >= 0, do: "+", else: "−"}#{pct |> abs() |> Float.round(0) |> trunc()}%"
  end

  defp delta_pct(_, _), do: "—"

  ## Render

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns,
        c: series(assigns.range),
        kpis: @kpis,
        channels: @channels,
        activity: @activity,
        orders: Enum.take(T.orders(), 5)
      )

    ~H"""
    <Shell.frame slug={@slug}>
      <Shell.app rail="inicio" panel="Painel" crumbs={["Painel"]}>
        <:panel_body>
          <.sidebar_nav_link active>
            <.icon name="home" size="md" />Visão geral<span class="r"></span>
          </.sidebar_nav_link>
          <.sidebar_nav_link phx-click={JS.navigate("/templates/tabela")}>
            <.icon name="cart" size="md" />Vendas<span class="r">1.096</span>
          </.sidebar_nav_link>
          <.sidebar_nav_link href="#">
            <.icon name="wallet" size="md" />Financeiro<span class="r">12</span>
          </.sidebar_nav_link>
          <.sidebar_nav_link href="#">
            <.icon name="package" size="md" />Estoque<span class="r">4</span>
          </.sidebar_nav_link>
          <div class="lu-nav-h"><.icon name="chevron-down" size="sm" />Atalhos</div>
          <.sidebar_nav_link phx-click={JS.navigate("/templates/tabela-modal")}>
            <.icon name="plus" size="md" />Novo pedido<span class="r">N</span>
          </.sidebar_nav_link>
          <.sidebar_nav_link href="#">
            <.icon name="invoice" size="md" />Emitir NF-e<span class="r">E</span>
          </.sidebar_nav_link>
          <.sidebar_nav_link href="#">
            <.icon name="users" size="md" />Novo cliente<span class="r">C</span>
          </.sidebar_nav_link>
          <div class="lu-nav-h"><.icon name="chevron-down" size="sm" />Equipes</div>
          <.sidebar_nav_link href="#">
            <.icon name="users" size="md" />Comercial<span class="r">6</span>
          </.sidebar_nav_link>
          <.sidebar_nav_link href="#">
            <.icon name="truck" size="md" />Expedição<span class="r">4</span>
          </.sidebar_nav_link>
        </:panel_body>

        <div style="padding:4px 28px 32px;display:flex;flex-direction:column;gap:18px">
          <.hero_card
            id="dash-hero"
            eyebrow="Bom dia, Ana"
            title="Novembro está 12% acima de outubro"
            description="Faltam 10 dias para fechar o mês. Três pedidos esperam aprovação e duas notas estão na fila da SEFAZ."
            meta="Meta de novembro"
            meta_value="R$ 184 mil de R$ 250 mil"
            meter={74}
          >
            <:actions>
              <.button color="mono" size="lg" phx-click="go" phx-value-to="tabela-modal">
                <.icon name="plus" />Novo pedido
              </.button>
              <.button variant="outline" size="lg"><.icon name="arrow-up-right" />Ver relatório</.button>
            </:actions>
          </.hero_card>

          <.stat_group>
            <.stat_item
              :for={k <- @kpis}
              icon={k.icon}
              label={k.label}
              value={k.value}
              change={k.delta}
              trend={k.dir}
              note={k.note}
              sparkline={k.values}
              sparkline_tone={k.spk}
            />
          </.stat_group>

          <div style="display:grid;grid-template-columns:minmax(0,1.75fr) minmax(0,1fr);gap:18px">
            <section class="lu-card">
              <header class="lu-card-h">
                <h3 class="lu-card-t" style="margin:0">Faturamento</h3>
                <div class="act">
                  <.segmented
                    id="tp-range"
                    role="tablist"
                    value={@range}
                    on_change="range"
                    options={[{"Dia", "dia"}, {"Mês", "mes"}, {"Ano", "ano"}]}
                  />
                </div>
              </header>
              <div class="lu-card-b" style="">
                <.line_chart
                  id="tp-line"
                  label="Faturamento"
                  head={@c.head}
                  sub={@c.sub}
                  sub_delta={@c.delta}
                  labels={@c.labels}
                  min={@c.min}
                  max={@c.max}
                  ticks={@c.ticks}
                  height={220}
                  pin={length(@c.labels) - 1}
                  axis_format={&short/1}
                  value_format={&reais/1}
                  series={[
                    %{name: elem(@c.names, 0), values: @c.now, area: true},
                    %{
                      name: elem(@c.names, 1),
                      values: @c.before,
                      dashed: true,
                      color: "var(--chart-ghost)"
                    }
                  ]}
                  tip_title={fn i -> @c.title.(Enum.at(@c.labels, i)) end}
                  tip={
                    fn i ->
                      now = Enum.at(@c.now, i)
                      before = Enum.at(@c.before, i)

                      [
                        [elem(@c.names, 0), mil(now), "acc"],
                        [elem(@c.names, 1), mil(before), "ghost"],
                        ["Variação", delta_pct(now, before), "lime"]
                      ]
                    end
                  }
                />
              </div>
            </section>
            <section class="lu-card">
              <header class="lu-card-h">
                <h3 class="lu-card-t" style="margin:0">Vendas por canal</h3>
                <div class="act">
                  <.button variant="outline" size="sm"><.icon name="arrow-up-right" />Detalhes</.button>
                </div>
              </header>
              <div class="lu-card-b" style="">
                <.donut_chart
                  id="tp-donut"
                  label="Vendas por canal"
                  center_label="NOVEMBRO"
                  center_value="R$ 184 mil"
                  value_format={&reais/1}
                  segments={
                    for {name, share, amount, color} <- @channels,
                        do: %{name: name, value: share, display: reais(amount), color: color}
                  }
                />
              </div>
            </section>
          </div>

          <div style="display:grid;grid-template-columns:minmax(0,1.75fr) minmax(0,1fr);gap:18px">
            <section class="lu-card">
              <header class="lu-card-h">
                <h3 class="lu-card-t" style="margin:0">Últimos pedidos</h3>
                <div class="act">
                  <.button variant="ghost" size="sm" phx-click="go" phx-value-to="tabela">
                    <.icon name="arrow-right" />Ver todos
                  </.button>
                </div>
              </header>
              <div class="lu-card-b" style="padding:0">
                <table class="lu-table">
                  <thead>
                    <tr>
                      <th>Pedido</th>
                      <th>Cliente</th>
                      <th>Data</th>
                      <th>Status</th>
                      <th class="num">Total</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr :for={o <- @orders}>
                      <td class="mono" style="color:var(--ink);font-weight:500">#{o.id}</td>
                      <td>
                        <div class="lu-row" style="flex-wrap:nowrap;gap:10px">
                          <.avatar initials={o.initials} color={o.tone} size="sm" />
                          <span style="display:flex;flex-direction:column;line-height:1.25">
                            <span style="color:var(--ink);font-weight:500">{o.name}</span>
                          </span>
                        </div>
                      </td>
                      <td class="lu-muted">{o.at}</td>
                      <td><.status_badge status={o.status} /></td>
                      <td class="num mono" style="color:var(--ink);font-weight:500">
                        {T.money(o.total)}
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </section>
            <section class="lu-card">
              <header class="lu-card-h">
                <h3 class="lu-card-t" style="margin:0">Atividade</h3>
                <div class="act"></div>
              </header>
              <div class="lu-card-b" style="">
                <.timeline marker="icon">
                  <.timeline_item
                    :for={a <- @activity}
                    variant="icon"
                    color={a.tone}
                    title={a.title}
                    description={a.sub}
                    time={a.at}
                  >
                    <:point><.icon name={a.icon} size="sm" /></:point>
                  </.timeline_item>
                </.timeline>
              </div>
            </section>
          </div>
        </div>
      </Shell.app>
    </Shell.frame>
    """
  end

  attr :status, :string, required: true

  defp status_badge(assigns) do
    {color, dot?} = T.status_badge(assigns.status)
    assigns = assign(assigns, color: color, dot?: dot?)

    ~H"""
    <.badge :if={@dot?} canvas color={@color} dot>{@status}</.badge>
    <.badge :if={!@dot?} canvas variant="outline">{@status}</.badge>
    """
  end
end
