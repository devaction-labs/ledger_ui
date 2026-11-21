defmodule Parity.Cases.DadosB do
  use Phoenix.Component
  use LedgerUI

  @accts [
    %{id: 1, name: "Orbit Cloud", email: "ikram@orbit.cloud", plan: "Pro", mrr: "$4,200", delta: "+8.2%", status: "Ativa"},
    %{id: 2, name: "Lumen GmbH", email: "ops@lumen.de", plan: "Scale", mrr: "$1,900", delta: "+12%", status: "Ativa"},
    %{id: 3, name: "Nordic Pay", email: "fin@nordicpay.se", plan: "Pro", mrr: "$3,400", delta: "-100%", status: "Churn"},
    %{id: 4, name: "Atlas Labs", email: "hello@atlas.io", plan: "Starter", mrr: "$340", delta: "0%", status: "Trial"}
  ]

  def cases do
    assigns = %{
      rows: @accts,
      variants: ~w(basic bordered hoverable zebra grid data data-grid flat),
      colors: ~w(neutral primary secondary info success warning error dark),
      sizes: ~w(md lg xl 2xl),
      markers: ~w(solid outline icon avatar dot),
      statuses: ~w(ok running waiting failed skipped canceled)a,
      pagers: ~w(rounded pill circle canvas pages)
    }

    %{
      # ------------------------------------------------------------------ Kanban
      "kanban-board" => ~H"""
      <.kanban id="kb1" style="--cols:3" aria-label="Pipeline">
        <.kanban_column id="kc1" list="risk" label="Em risco" count={2} color="warning" meta="2 contas" total="$3,740">
          <:icon><span style="display:inline-block;width:7px;height:7px;flex:none;border-radius:50%;background:currentColor;color:#d6336c"></span></:icon>
          <:actions><.button variant="ghost" size="sm" shape="square" aria-label="Adicionar"><.icon name="plus" /></.button></:actions>
          <.kanban_card id="k1" item="1">
            <div style="display:flex;align-items:center;justify-content:space-between"><.badge color="primary">Pro</.badge><.icon name="more-h" size="md" style="color:#8a8e8b" /></div>
            <b>Nordic Pay — falha de pagamento</b>
            <span style="display:flex;align-items:center;gap:4px;font-size:12px;color:#8a8e8b"><.icon name="calendar" size="sm" />21 nov</span>
          </.kanban_card>
          <.kanban_card id="k2" item="2" risk>
            <b>Atlas Labs — trial expira</b>
            <span style="font-size:12px;color:#8a8e8b">24 nov</span>
          </.kanban_card>
        </.kanban_column>
        <.kanban_column id="kc2" list="neg" label="Em negociação" count={1} color="info" progress={40}>
          <.kanban_card id="k3" item="3" grip>
            <b>Lumen GmbH — upgrade 50 assentos</b>
            <span style="font-size:12px;color:#8a8e8b">28 nov</span>
          </.kanban_card>
        </.kanban_column>
        <.kanban_column id="kc3" list="won" label="Renovado" count={2} color="success" limit={1}>
          <.kanban_card id="k4" item="4" dense><b>Orbit Cloud — anual</b></.kanban_card>
          <.kanban_card id="k5" item="5">
            <b>Vektor — mensal</b>
            <:actions><.icon name="more-h" size="md" /></:actions>
          </.kanban_card>
        </.kanban_column>
      </.kanban>
      """,
      "kanban-colors" => ~H"""
      <.kanban id="kb2" style="--cols:3">
        <.kanban_column :for={{c, i} <- Enum.with_index(~w(neutral info warning primary success))} id={"kk#{i}"} label={c} count={i}>
          <.kanban_card id={"kkc#{i}"}><b>Card {c}</b></.kanban_card>
        </.kanban_column>
        <.kanban_column id="kn1" label="Sem cor" count={0}>
          <:empty>Solte aqui</:empty>
        </.kanban_column>
        <.kanban_column id="kn2" label="Vazio" count={0} hint="always">
          <:empty title="Nada por aqui" icon="inbox">Arraste um card</:empty>
        </.kanban_column>
        <.kanban_lost label="Perdidos" count={3} meta="R$ 12 mil" list="lost" />
      </.kanban>
      """,
      "kanban-scroll" => ~H"""
      <.kanban id="kb3" aria-label="Rolagem">
        <.kanban_column :for={i <- 1..4} id={"ks#{i}"} label={"Coluna #{i}"} count={1}>
          <.kanban_card id={"ksc#{i}"}><b>Item {i}</b></.kanban_card>
        </.kanban_column>
      </.kanban>
      <.kanban id="kb4" fluid style="margin-top:16px">
        <.kanban_column :for={i <- 1..2} id={"kf#{i}"} label={"Fluida #{i}"} count={1} disabled={i == 2}>
          <.kanban_card id={"kfc#{i}"}><b>Item {i}</b></.kanban_card>
        </.kanban_column>
      </.kanban>
      """,
      # ------------------------------------------------------------------ Timeline
      "timeline-markers" => ~H"""
      <div style="display:grid;grid-template-columns:repeat(5,1fr);gap:14px">
        <div :for={m <- @markers}>
          <.timeline marker={m}>
            <.timeline_item title="NF-e autorizada" description="Protocolo 129 2611" time="14:02" color="success"><:point><.icon name="check" size="sm" /></:point></.timeline_item>
            <.timeline_item title="Saiu para entrega" description="Motorista: Rita" time="14:40" color="info"><:point><.icon name="truck" size="sm" /></:point></.timeline_item>
            <.timeline_item title="Cliente ausente" time="15:10" color="warning" ping><:point><.icon name="alert" size="sm" /></:point></.timeline_item>
          </.timeline>
        </div>
      </div>
      """,
      "timeline-sizes" => ~H"""
      <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:14px">
        <.timeline :for={s <- @sizes} size={s} marker="icon">
          <.timeline_item title="Autorizada" time="14:02" color="success"><:point><.icon name="check" size="sm" /></:point></.timeline_item>
          <.timeline_item title="Entregue" description="Assinado" time="16:05" color="primary"><:point><.icon name="check-circle" size="sm" /></:point></.timeline_item>
        </.timeline>
      </div>
      """,
      "timeline-colors" => ~H"""
      <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:14px">
        <.timeline :for={c <- @colors} marker={if(c in ~w(neutral secondary info error), do: "outline", else: "solid")} density="compact" line_space>
          <.timeline_item title={c} time="09:00" color={c}><:point><.icon name="check" size="sm" /></:point></.timeline_item>
          <.timeline_item title="Depois" time="10:00" color={c}><:point><.icon name="check" size="sm" /></:point></.timeline_item>
        </.timeline>
      </div>
      """,
      "timeline-dot" => ~H"""
      <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:14px">
        <.timeline marker="dot" line_space items={[%{title: "Criada", time: "10:00", color: "primary"}, %{title: "Enviada", time: "11:00", color: "info", description: "Por e-mail"}]} />
        <.timeline marker="dot" density="compact" items={[%{title: "A", color: "success"}, %{title: "B", color: "error"}, %{title: "C"}]} />
        <.timeline marker="avatar" size="lg">
          <.timeline_item title="Ana" time="agora" color="primary"><:point>AN</:point></.timeline_item>
          <.timeline_item title="Rita" time="ontem" color="warning"><:point>RT</:point></.timeline_item>
        </.timeline>
      </div>
      """,
      "timeline-canvas" => ~H"""
      <.timeline variant="canvas">
        <.timeline_day label="Hoje" />
        <.timeline_event title="Pagamento falhou" time="há 2h" subtitle="Visa •••• 4417 recusado; nova tentativa em 3 dias." tone="neg"><:icon><.icon name="card" size="md" /></:icon></.timeline_event>
        <.timeline_event title="Upgrade para Scale" time="ontem" subtitle="+$1,200 MRR · 14 → 28 assentos." tone="pos"><:icon><.icon name="arrow-up-right" size="md" /></:icon></.timeline_event>
        <.timeline_event title="Fatura enviada" time="3 out" subtitle="INV-2026-1043 · $4,200" tone="info"><:icon><.icon name="mail" size="md" /></:icon></.timeline_event>
        <.timeline_event title="Conta criada" time="12 jan" tone="acc"><:icon><.icon name="user-plus" size="md" /></:icon></.timeline_event>
        <.timeline_event title="Sem tom" time="1 jan" tone="warn"><:icon><.icon name="clock" size="md" /></:icon></.timeline_event>
      </.timeline>
      """,
      # ------------------------------------------------------------------ StepGroup
      "step-group-states" => ~H"""
      <.step_group id="sg1" title="Emissão da NF-e" status={:running} duration="1m 04s">
        <:step title="Validar XML" status={:ok} result="0,4s" />
        <:step title="Assinar" status={:ok} result="1,2s" />
        <:step title="Transmitir à SEFAZ" status={:running} result="Em curso…" />
        <:step title="Gerar DANFE" status={:waiting} />
        <:step title="Enviar por WhatsApp" status={:skipped} />
        <:step title="Enviar por e-mail" status={:failed} result="erro" />
        <:step title="Imprimir" status={:canceled} />
      </.step_group>
      """,
      "step-group-plain" => ~H"""
      <.step_group id="sg2" steps={[%{title: "Criar workspace", result: "2s"}, %{title: "Convidar equipe"}, %{title: "Conectar Stripe"}, %{title: "Metas"}]} current={3} />
      """,
      "step-group-logs" => ~H"""
      <.step_group id="sg3" title="Deploy logs" status={:running} duration="2m 11s">
        <:step title="Preparando ambiente" status={:ok} result="12s" />
        <:step title="Atualizando a stack" status={:running} result="Em curso…" open>
          <.step_group_line n={1} at="09:41:02" tone="dim">Conectando</.step_group_line>
          <.step_group_line n={2} at="09:41:04" tone="ok">Imagem baixada</.step_group_line>
          <.step_group_line n={3} at="09:41:09" tone="err">Rejeitado pelo servidor</.step_group_line>
          <.step_group_line n={4}>Sem horário</.step_group_line>
        </:step>
        <:step title="Roteando tráfego" status={:waiting} result="Aguardando">
          <.step_group_line n={1}>escondido</.step_group_line>
        </:step>
      </.step_group>
      <.step_group id="sg4" title="Recolhido" status={:running} collapsed style="margin-top:12px">
        <:step title="Passo" status={:ok} />
      </.step_group>
      """,
      # ------------------------------------------------------------------ Treeview
      "tree-basic" => ~H"""
      <.treeview id="tv1" style="width:320px">
        <.tree_item id="bp" label="Board packs" count="4" expanded icon="folder">
          <.tree_item id="q3" label="Q3 2026" icon="file" />
          <.tree_item id="q2" label="Q2 2026" icon="file" selected />
          <.tree_item id="old" label="Anteriores" icon="folder" branch />
        </.tree_item>
        <.tree_item id="pcw" label="Pro churn watch" count="23" icon="folder" branch>
          <.tree_item id="hid" label="Escondido" icon="file" />
        </.tree_item>
        <.tree_item id="emea" label="EMEA expansion" count="12" icon="folder" expanded>
          <.tree_item id="lm" label="Lumen GmbH" icon="building" />
          <.tree_item id="np" label="Nordic Pay" icon="building" />
        </.tree_item>
      </.treeview>
      """,
      "tree-data" => ~H"""
      <div style="display:grid;grid-template-columns:repeat(2,1fr);gap:14px">
        <.tree id="tv2" selected="nfe" items={[%{id: "fiscal", label: "Fiscal", icon: "folder", count: 12, expanded: true, children: [%{id: "nfe", label: "NF-e", icon: "file"}, %{id: "nfs", label: "NFS-e", icon: "file", count: 3}]}, %{id: "rh", label: "RH", icon: "folder", children: [%{id: "x", label: "x"}]}]} />
        <.tree id="tv3" chevrons={false} items={[%{label: "Sem chevron", icon: "folder", expanded: true, children: [%{label: "Filho", icon: "file"}]}]} />
      </div>
      """,
      "tree-check" => ~H"""
      <.treeview id="tv4" style="width:340px">
        <.tree_item id="all" label="Todos" checked="mixed" expanded icon="folder">
          <.tree_item id="a" label="Marcado" checked={true} icon="file" />
          <.tree_item id="b" label="Desmarcado" checked={false} icon="file" />
          <.tree_item id="c" label="Sub" checked={false} expanded icon="folder">
            <.tree_item id="c1" label="Fundo" checked={false} icon="file" />
          </.tree_item>
        </.tree_item>
        <.tree_item id="rows1" label="Lado a lado" depth={1} icon="file" />
        <.tree_item id="rows2" label="Mais fundo" depth={2} icon="file" />
      </.treeview>
      """,
      # ------------------------------------------------------------------ HeroCard
      "hero-soft" => ~H"""
      <.hero_card id="h1" eyebrow="Bem-vindo de volta" title="Metas do trimestre" description="Alinhe a equipe e acompanhe o que importa para a empresa.">
        <:icon><.icon name="sparkles" /></:icon>
        <:actions>
          <.button color="mono" size="lg"><.icon name="plus" />Novo pedido</.button>
          <.button variant="outline" size="lg">Ver tudo</.button>
        </:actions>
      </.hero_card>
      """,
      "hero-lg-meter" => ~H"""
      <.hero_card id="h2" size="lg" eyebrow="Bom dia, Alex" title="Novembro está 12% acima de outubro" meta="Meta de novembro" meta_value="R$ 184 mil de R$ 250 mil" meter={74}>
        <:actions><.button size="lg" color="primary">Abrir painel</.button></:actions>
      </.hero_card>
      """,
      "hero-panel-steps" => ~H"""
      <.hero_card id="h3" variant="panel" eyebrow="Configuração" title="Falta pouco para emitir sua primeira NF-e" picture="none" steps={[%{label: "Empresa", state: "done"}, %{label: "Série e numeração", state: "current"}, %{label: "Teste"}]}>
        <:actions><.button color="primary">Continuar</.button></:actions>
      </.hero_card>
      """,
      "hero-ai" => ~H"""
      <.hero_card id="h4" variant="ai" eyebrow="Sugestão" title="Três faturas vencem hoje" description="O assistente separou as que têm maior risco.">
        <:icon><.icon name="ai" /></:icon>
        <div style="font-size:12px;color:#8a8e8b">Nota extra no corpo</div>
      </.hero_card>
      """,
      "hero-picture" => ~H"""
      <.hero_card id="h5" title="Imagem" src="data:image/svg+xml;utf8,%3Csvg xmlns='http://www.w3.org/2000/svg' width='400' height='200'%3E%3Crect width='400' height='200' fill='%236fb9ab'/%3E%3C/svg%3E" position="left" description="Com a foto à direita" />
      <.hero_card id="h6" title="Arte própria" style="margin-top:12px">
        <:art><svg viewBox="0 0 10 10" preserveAspectRatio="none"><rect width="10" height="10" fill="#d9ece7"></rect></svg></:art>
      </.hero_card>
      """,
      # ------------------------------------------------------------------ Flow
      "flow-edges" => ~H"""
      <div style="height:620px;display:grid"><.flow id="fl1" aria-label="Triagem" node_width={260}
        edges={[%{from: "in", to: "ai"}, %{from: "ai", to: "ok", label: "Sim", status: "done"}, %{from: "ai", to: "no", label: "Não", status: "error"}]}>
        <:node id="in" kind="Gatilho" kind_icon="zap" icon="zap" title="Pagamento falhou" status="done"><span style="font-size:12px;color:#8a8e8b">Stripe</span></:node>
        <:node id="ai" kind="IA" kind_icon="ai" icon="ai" title="Classificar risco" selected status="running" metrics={[%{label: "Regras", value: "3"}, %{label: "Docs", value: "2"}]}><span style="font-size:12px;color:#8a8e8b">3 regras</span></:node>
        <:node id="ok" kind="Ação" kind_icon="mail" icon="mail" title="E-mail ao cliente" status="waiting" />
        <:node id="no" kind="Aprovação" kind_icon="user" icon="user" title="Aprovação do CS" status="skipped" />
        <:actions :let={id}><.button size="sm" variant="outline" shape="square" aria-label={"Ações #{id}"}><.icon name="more-h" /></.button></:actions>
        <:toolbar><.button size="sm" color="primary">Adicionar nó</.button><.button size="sm" variant="outline">Zoom</.button></:toolbar>
        <:hint title="Dica" left={560} top={40} width={200}>Arraste os nós.</:hint>
      </.flow></div>
      """,
      "flow-panel" => ~H"""
      <div style="height:460px;display:grid"><.flow id="fl2" aria-label="Painel" on_add="add" on_move="move" node_width={240}
        edges={[%{from: "a", to: "b"}]}>
        <:node id="a" kind="Gatilho" kind_icon="mail" icon="mail" title="Fatura recebida" x={30} y={30}>
          <.flow_section label="Evento">Uma fatura chega.</.flow_section>
          <.flow_chips><.flow_chip>nfe</.flow_chip><.flow_chip>xml</.flow_chip></.flow_chips>
        </:node>
        <:node id="b" kind="Aprovação" icon="shield" title="Aprovação" x={300} y={260} selected class="extra" />
        <:panel label="Aprovação">
          <.flow_panel_head icon="shield" title="Aprovação" on_close="close" />
          <.flow_panel_tabs>Abas</.flow_panel_tabs>
          <.flow_panel_body>
            <span>Campos</span>
          </.flow_panel_body>
          <.flow_panel_foot>Salvo agora</.flow_panel_foot>
        </:panel>
      </.flow></div>
      """,
      "flow-grid" => ~H"""
      <div style="height:420px;display:grid"><.flow id="fl3" node_width={200}>
        <:node :for={i <- 1..5} id={"n#{i}"} kind={"Passo #{i}"} icon="zap" title={"Título #{i}"} />
      </.flow></div>
      """,
      # ------------------------------------------------------------------ Table
      "table-variants" => ~H"""
      <div style="display:flex;flex-direction:column;gap:14px">
        <.table :for={v <- @variants} id={"tv-#{v}"} rows={@rows} variant={v}>
          <:col :let={r} label={"Conta · #{v}"} style="font-weight:500;color:var(--ink)">{r.name}</:col>
          <:col :let={r} label="Plano"><.badge color="primary">{r.plan}</.badge></:col>
          <:col :let={r} label="MRR" align="right">{r.mrr}</:col>
          <:col :let={r} label="Status" align="center">{r.status}</:col>
        </.table>
      </div>
      """,
      "table-shapes" => ~H"""
      <div style="display:flex;flex-direction:column;gap:14px">
        <.table id="ts-row" rows={@rows} rounded="row" variant="hoverable">
          <:col :let={r} label="Conta">{r.name}</:col><:col :let={r} label="MRR" align="right" style="font-family:var(--font-mono);font-size:13px">{r.mrr}</:col>
        </.table>
        <.table id="ts-top" rows={@rows} rounded="top" compact>
          <:col :let={r} label="Conta">{r.name}</:col><:col :let={r} label="E-mail">{r.email}</:col>
        </.table>
        <.table id="ts-hdl" rows={@rows} headless wrapper={false}>
          <:col :let={r} label="Conta">{r.name}</:col><:col :let={r} label="MRR" align="right">{r.mrr}</:col>
        </.table>
        <.table id="ts-ph" rows={@rows} hoverable variant="basic" borderless>
          <:col :let={r} label="Conta">{r.name}</:col>
          <:action :let={r}><.button variant="ghost" size="sm" shape="square" aria-label={"Ações #{r.name}"}><.icon name="more-h" /></.button></:action>
        </.table>
      </div>
      """,
      "table-select" => ~H"""
      <.table id="tsel" rows={@rows} on_sort="sort" sort_by="mrr" sort_dir="desc" on_select="sel" on_select_all="all" selected={[1, 3]} row_key={& &1.id} sort_label="Ordenar por %{label}">
        <:col :let={r} label="Conta" sort_key="name">{r.name}</:col>
        <:col :let={r} label="Plano">{r.plan}</:col>
        <:col :let={r} label="MRR" align="right" sort_key="mrr">{r.mrr}</:col>
        <:col :let={r} label="Δ" align="right" style="font-family:var(--font-mono);font-size:13px">{r.delta}</:col>
        <:foot colspan={2}>Total</:foot>
        <:foot align="right">$9,840</:foot>
      </.table>
      """,
      "table-select-all" => ~H"""
      <div style="display:flex;flex-direction:column;gap:14px">
        <.table id="tsa" rows={@rows} on_select="sel" on_select_all="all" selected={[1, 2, 3, 4]} row_key={& &1.id}>
          <:col :let={r} label="Conta" sort_key="name">{r.name}</:col>
        </.table>
        <.table id="tsb" rows={@rows} on_select="sel" on_select_all="all" row_key={& &1.id} on_sort="sort" sort_by="name">
          <:col :let={r} label="Conta" sort_key="name">{r.name}</:col>
          <:col :let={r} label="MRR" sort_key="mrr" align="right">{r.mrr}</:col>
        </.table>
      </div>
      """,
      "table-expand" => ~H"""
      <div style="display:flex;flex-direction:column;gap:14px">
        <.table id="tx" rows={@rows} row_id={&"r#{&1.id}"} expand_label="Detalhes">
          <:col :let={r} label="Conta">{r.name}</:col>
          <:expand :let={c}>Detalhes de {c.row.name}</:expand>
        </.table>
        <.table id="tx2" rows={@rows} row_id={&"s#{&1.id}"} expand_open={&(&1.id == 2)}>
          <:col :let={r} label="Conta">{r.name}</:col>
          <:expand :let={c}>Aberto: {c.row.name}</:expand>
        </.table>
        <.table id="tx3" rows={[]}>
          <:col label="Conta">x</:col>
          <:empty>Nenhuma conta</:empty>
        </.table>
        <.table id="tx4" rows={@rows} sticky_header scroll_label="Rolagem" row_click={&Phoenix.LiveView.JS.push("open", value: %{id: &1.id})} row_class={&(&1.id == 2 && "extra")}>
          <:col :let={r} label="Conta">{r.name}</:col>
        </.table>
      </div>
      """,
      "table-hand" => ~H"""
      <.table id="th">
        <.table_head on_select_all="all" sort_by="a" on_sort="sort">
          <:col sort_key="a">Conta</:col>
          <:col align="right" sort_key="b">MRR</:col>
          <:col align="center">Sit</:col>
        </.table_head>
        <.table_body>
          <.table_row selected on_select="s" select_value={1}>
            <:cell>Orbit</:cell><:cell align="right">$1</:cell>
            <:cell align="center">ok</:cell>
          </.table_row>
          <.table_row on_select="s" select_value={2} on_click="go">
            <:cell>Lumen</:cell><:cell align="right">$2</:cell>
          </.table_row>
          <tr><.table_cell header>Linha</.table_cell><.table_cell align="right" colspan={2}>x</.table_cell></tr>
          <.table_detail_row row_id="x">Detalhe</.table_detail_row>
          <.table_empty id="te">Vazio</.table_empty>
        </.table_body>
        <.table_foot><:cell>Total</:cell><:cell align="right" colspan={2}>$3</:cell></.table_foot>
      </.table>
      """,
      "table-priority" => ~H"""
      <div style="display:flex;flex-direction:column;gap:14px">
        <.table id="tp1" rows={@rows}>
          <:col :let={r} label="Conta">{r.name}</:col>
          <:col :let={r} label="Plano" priority={1}>{r.plan}</:col>
          <:col :let={r} label="E-mail" priority={2}>{r.email}</:col>
          <:col :let={r} label="MRR" priority={3} align="right">{r.mrr}</:col>
          <:foot>Total</:foot><:foot priority={1}>x</:foot><:foot priority={2}>y</:foot><:foot priority={3}>z</:foot>
        </.table>
      </div>
      """,
      "table-card" => ~H"""
      <.table id="tc" rows={@rows} card_below={520} on_select="s" on_select_all="all" row_key={& &1.id} selected={[2]}>
        <:col :let={r} label="Conta" role="head">{r.name}</:col>
        <:col :let={r} label="Status" role="status"><.badge color="success">{r.status}</.badge></:col>
        <:col :let={r} label="Obs" role="title" width="minmax(120px,1.3fr)">Uma observação longa sobre a conta {r.name} que passa de duas linhas se o espaço for curto</:col>
        <:col :let={r} label="MRR" role="value" align="right">{r.mrr}</:col>
        <:col :let={r} label="E-mail" card>{r.email}</:col>
        <:action :let={_r}><.icon name="more-h" /></:action>
      </.table>
      """,
      "table-details" => ~H"""
      <.table id="td" rows={@rows} row_id={&"d#{&1.id}"} details panel_label="Detalhes">
        <:col :let={r} label="Conta">{r.name}</:col>
        <:col :let={r} label="E-mail" priority={1}>{r.email}</:col>
        <:detail :let={r} label="Plano">{r.plan}</:detail>
        <:col :let={r} label="Copiar" copy={& &1.email} copy_label="Copiar" copied_label="Copiado" copy_show="inline">{r.email}</:col>
        <:col :let={r} label="Cop2" copy={& &1.name} copy_tip="value_label">{r.name}</:col>
      </.table>
      """,
      "table-edit" => ~H"""
      <.table id="te1" rows={@rows} row_editing={&(&1.id == 2)} row_action={&(&1.id != 3)}>
        <:col :let={r} label="Conta">{r.name}</:col>
        <:col :let={r} label="Plano">{r.plan}</:col>
        <:action :let={_r}><.icon name="more-h" /></:action>
        <:edit><span>editando</span></:edit>
      </.table>
      """,
      "table-skeleton" => ~H"""
      <div style="display:flex;flex-direction:column;gap:14px">
        <.table_skeleton id="sk1" columns={["Conta", "Plano", "MRR"]} shapes={["avatar", "pill", "number"]} rows={3} />
        <.table_skeleton id="sk2" cols={3} rows={2} variant="grid" compact headless />
      </div>
      """,
      # ------------------------------------------------------------------ DataTable
      "data-table-advanced" => ~H"""
      <.data_table id="dt1" rows={@rows} search="" on_search="search" sort_by="name" on_sort="sort" page={1} page_size={4} total={1096} on_page="page" selected={[1, 3]} on_select="sel" on_select_all="all" row_key={& &1.id}>
        <:title>Contas</:title>
        <:actions><.button size="sm" variant="outline"><.icon name="download" />Exportar</.button></:actions>
        <:filters :let={_toggle}>Filtros aqui</:filters>
        <:col :let={r} label="Conta" sort_key="name">{r.name}</:col>
        <:col :let={r} label="Plano">{r.plan}</:col>
        <:col :let={r} label="MRR" align="right" sort_key="mrr">{r.mrr}</:col>
        <:action :let={_r}><.icon name="more-h" /></:action>
      </.data_table>
      """,
      "data-table-grid" => ~H"""
      <.data_table id="dt2" variant="grid" rows={@rows} search_placeholder="Buscar" on_search="search" page={2} page_size={2} total={7} on_page="page" pager="pill">
        <:col :let={r} label="Conta">{r.name}</:col>
        <:col :let={r} label="E-mail">{r.email}</:col>
      </.data_table>
      """,
      "data-table-pagers" => ~H"""
      <div style="display:flex;flex-direction:column;gap:14px">
        <.data_table :for={p <- @pagers} id={"dp-#{p}"} rows={Enum.take(@rows, 2)} page={5} page_size={2} total={40} on_page="page" pager={p} body="card" page_sizes={[10, 25]} on_page_size="size">
          <:toolbar><span>Barra {p}</span></:toolbar>
          <:col :let={r} label="Conta">{r.name}</:col>
        </.data_table>
      </div>
      """,
      "data-table-states" => ~H"""
      <div style="display:flex;flex-direction:column;gap:14px">
        <.data_table id="ds1" rows={@rows} loading loading_rows={2} page={1} total={4} on_page="p">
          <:title>Carregando</:title>
          <:col :let={r} label="Conta">{r.name}</:col>
          <:col :let={r} label="Plano">{r.plan}</:col>
        </.data_table>
        <.data_table id="ds2" rows={[]} page={1} total={0} summary_label="Mostrando %{from}–%{to} de %{total}">
          <:col label="Conta">x</:col>
          <:empty>Nenhuma conta</:empty>
          <:bulk><div style="padding:8px;font-size:12px">bulk</div></:bulk>
        </.data_table>
      </div>
      """,
      "table-toolbar" => ~H"""
      <div style="display:flex;flex-direction:column;gap:18px">
        <.table_toolbar id="tb1" search="" on_search="s" shortcut="/" filters={[%{id: "plan", label: "Plano: Pro"}, %{id: "st", label: "Status: Em risco"}]} on_remove_filter="rm" on_clear="clr">
          <:start><.button size="sm" variant="outline"><.icon name="filter" />Filtro</.button></:start>
          <:actions><.button size="sm" variant="outline"><.icon name="download" />Export</.button><.button size="sm" color="primary"><.icon name="plus" />Nova conta</.button></:actions>
        </.table_toolbar>
        <.table_toolbar id="tb2" search_placeholder="Buscar nome, MRN" />
        <.table_search id="tb3" value="orbit" width="180px" />
      </div>
      """
    }
  end
end
