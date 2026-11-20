defmodule LedgerShowcaseWeb.Templates.DashboardLive do
  @moduledoc """
  The dashboard template (`/templates/dashboard`): the month's goal, four KPIs, the revenue line
  chart (the Dia / Mês / Ano switch re-draws it), sales by channel (donut), the latest orders and
  the activity feed. The numbers are mock data, in integer reais/cents.

  The hero and the KPI strip are local markup (`lu-hero` and `lu-stats` of canvas v2): the library
  `hero_card` and `stat_group` still draw the previous design.
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
    169_460,
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
      chg: "pos",
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
      chg: "pos",
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
      chg: "pos",
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
      chg: "flat",
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
  def handle_event("range", %{"id" => range}, socket) when range in ~w(dia mes ano) do
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
      sub: "hoje, 21 nov",
      delta: "+25,7%",
      names: {"Hoje", "Ontem"},
      title: &"#{&1} nov"
    }

  defp series("ano"),
    do: %{
      labels: @year_labels,
      now: @year_now,
      before: @year_before,
      min: 600_000,
      max: 2_200_000,
      ticks: 4,
      head: "R$ 2,01 mi",
      sub: "em 2026, até novembro",
      delta: "+16,2%",
      names: {"Ano", "Ano anterior"},
      title: & &1
    }

  defp series(_),
    do: %{
      labels: @month_labels,
      now: @month_2026,
      before: @month_2025,
      min: 60_000,
      max: 200_000,
      ticks: 3,
      head: "R$ 184.320",
      sub: "em novembro",
      delta: "+12,4%",
      names: {"2026", "2025"},
      title: &"#{&1} 2026"
    }

  defp mil(v) when v >= 1_000_000, do: "R$ #{trunc(v / 100_000) / 10} mi"
  defp mil(v) when v >= 1000, do: "R$ #{round(v / 1000)} mil"
  defp mil(v), do: "R$ #{v}"

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
          <section class="lu-hero md soft">
            <div class="tx">
              <span class="eb">Bom dia, Ana</span>
              <h2>Novembro está 12% acima de outubro</h2>
              <p>
                Faltam 10 dias para fechar o mês. Três pedidos esperam aprovação e duas notas estão na fila da SEFAZ.
              </p>
              <div class="in">
                <div class="lu-hmeta">
                  <div class="lu-row" style="justify-content:space-between">
                    <span>Meta de novembro</span><b>R$ 184 mil de R$ 250 mil</b>
                  </div>
                  <span class="lu-smeter"><i style="--sp:74%"></i></span>
                </div>
              </div>
              <div class="ac">
                <.button color="mono" size="lg" phx-click="go" phx-value-to="tabela-modal">
                  <.icon name="plus" />Novo pedido
                </.button>
                <.button variant="outline" size="lg"><.icon name="arrow-up-right" />Ver relatório</.button>
              </div>
            </div>
            <div class="art"><.auth_art id="tpd" /></div>
          </section>

          <div class="lu-stats">
            <div :for={k <- @kpis} class="lu-stat">
              <span class="l"><.icon name={k.icon} size="sm" />{k.label}</span>
              <span class="v">{k.value}</span>
              <span class="f">
                <span class={"lu-chg #{k.chg}"}>
                  <.chg_arrow dir={k.dir} />{k.delta}
                </span>
                <span>{k.note}</span>
              </span>
              <span class="sp"><.spk tone={k.spk} values={k.values} /></span>
            </div>
          </div>

          <div style="display:grid;grid-template-columns:minmax(0,1.75fr) minmax(0,1fr);gap:18px">
            <section class="lu-card">
              <header class="lu-card-h">
                <h3 class="lu-card-t" style="margin:0">Faturamento</h3>
                <div class="act">
                  <div class="lu-seg" role="tablist">
                    <button
                      :for={{id, label} <- [{"dia", "Dia"}, {"mes", "Mês"}, {"ano", "Ano"}]}
                      type="button"
                      class={@range == id && "on"}
                      phx-click="range"
                      phx-value-id={id}
                    >
                      {label}
                    </button>
                  </div>
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
                  axis_format={&mil/1}
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

  attr :dir, :string, required: true

  defp chg_arrow(%{dir: "up"} = assigns),
    do: ~H|<svg viewBox="0 0 12 12"><path d="M6 9.5V2.5M2.8 5.6 6 2.5l3.2 3.1"></path></svg>|

  defp chg_arrow(%{dir: "down"} = assigns),
    do: ~H|<svg viewBox="0 0 12 12"><path d="M6 2.5v7M2.8 6.4 6 9.5l3.2-3.1"></path></svg>|

  defp chg_arrow(assigns), do: ~H|<svg viewBox="0 0 12 12"><path d="M2.5 6h7"></path></svg>|

  attr :tone, :string, required: true
  attr :values, :list, required: true

  # The sparkline of a KPI: 12 points over 120x30, the highest at the top (y = 5), the lowest at 27.
  defp spk(assigns) do
    values = assigns.values
    {lo, hi} = Enum.min_max(values)
    n = length(values) - 1

    pts =
      for {v, i} <- Enum.with_index(values) do
        x = i * 120 / n
        y = 27 - (v - lo) / max(hi - lo, 1) * 22
        {fmt1(x), fmt1(y)}
      end

    [first | rest] = Enum.map(pts, fn {x, y} -> "#{x} #{y}" end)
    path = "M" <> first <> Enum.map_join(rest, "", &(" L" <> &1))
    {lx, ly} = List.last(pts)

    assigns =
      assign(assigns,
        area: path <> " L120 30 L0 30 Z",
        line: path,
        cx: lx,
        cy: ly
      )

    ~H"""
    <svg class={"lu-spk #{@tone}"} viewBox="0 0 120 30" preserveAspectRatio="none" aria-hidden="true">
      <path class="a" d={@area}></path>
      <path class="l" pathLength="1" d={@line}></path>
      <circle cx={@cx} cy={@cy} r="2.6"></circle>
    </svg>
    """
  end

  defp fmt1(f), do: :erlang.float_to_binary(f * 1.0, decimals: 1)
end
