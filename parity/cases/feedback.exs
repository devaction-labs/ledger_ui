defmodule Parity.Cases.Feedback do
  use Phoenix.Component
  use LedgerUI
  import Parity.Common

  @acolors ~w(neutral primary secondary info success warning error dark)
  @aicons %{
    "neutral" => "info",
    "primary" => "sparkles",
    "secondary" => "ai",
    "info" => "info",
    "success" => "check-circle",
    "warning" => "alert",
    "error" => "x-circle",
    "dark" => "info"
  }
  @pcol ~w(neutral primary secondary info success warning error white)
  @sizes ~w(xs sm md lg xl)
  @chip "block bg-panel px-4 py-3 text-[13.5px] leading-5 whitespace-nowrap"

  # ---- helpers

  attr :gap, :integer, default: 10
  attr :align, :string, default: nil
  slot :inner_block, required: true

  defp stack(assigns) do
    ~H"""
    <div style={"display:flex;flex-direction:column;gap:#{@gap}px" <> if(@align, do: ";align-items:#{@align}", else: "")}>{render_slot(@inner_block)}</div>
    """
  end

  slot :inner_block, required: true
  attr :w, :integer, default: 380

  defp wrap(assigns) do
    ~H"""
    <div style={"width:#{@w}px;max-width:100%"}>{render_slot(@inner_block)}</div>
    """
  end

  attr :c, :string, required: true
  attr :v, :string, required: true
  attr :title, :string, default: "Título do aviso"
  attr :desc, :string, default: "Uma frase de contexto."
  attr :shape, :string, default: "rounded"
  attr :accent, :any, default: nil
  attr :action, :boolean, default: false
  attr :dismiss, :boolean, default: false

  defp al(assigns) do
    ~H"""
    <.alert color={@c} variant={@v} shape={@shape} accent={@accent} dismissible={@dismiss} close_label="Fechar" title={@title} description={@desc}>
      <:icon><.icon name={Map.fetch!(aicons(), @c)} /></:icon>
      <:action :if={@action}>
        <.button color={if @v == "solid", do: "white", else: @c} variant={if @v == "solid", do: "solid", else: "soft"} size="xs">Ação</.button>
      </:action>
    </.alert>
    """
  end

  defp aicons, do: @aicons

  attr :v, :string, required: true
  attr :s, :string, required: true
  attr :c, :string, default: "primary"

  defp sp(assigns) do
    ~H"""
    <.spinner color={@c} variant={@v} size={@s} label="Carregando" />
    """
  end

  attr :tone, :string, default: "default"
  attr :title, :string, default: "Nenhum pedido ainda"
  attr :kicker, :string, default: nil
  attr :level, :integer, default: nil

  defp emp_card(assigns) do
    ~H"""
    <div class="rounded-lg border border-line bg-panel">
      <.empty_state variant="card" icon="inbox" tone={@tone} title={@title} kicker={@kicker} level={@level}>
        Os pedidos do balcão e do site aparecem aqui.
        <:action><.button color="mono" size="sm" icon="plus">Novo pedido</.button></:action>
      </.empty_state>
    </div>
    """
  end

  attr :links, :list, required: true
  attr :title, :string, required: true

  defp links_block(assigns) do
    ~H"""
    <.error_links title={@title}>
      <:link :for={{i, t, d} <- @links} href="#" icon={i} description={if d == "", do: nil, else: d}>{t}</:link>
    </.error_links>
    """
  end

  def cases do
    kinds = [
      {"neutral", "Alterações salvas", "info"},
      {"primary", "Assistente pronto", "sparkles"},
      {"info", "Nova versão disponível", "info"},
      {"success", "Relatório exportado", "check-circle"},
      {"warning", "Assentos em 80%", "alert"},
      {"error", "Falha ao sincronizar", "x-circle"}
    ]

    assigns = %{
      kinds: kinds,
      dark_kinds: Enum.filter(kinds, &(elem(&1, 0) in ~w(neutral primary success error))),
      acolors: @acolors,
      pcol: @pcol,
      sizes: @sizes,
      chip: @chip,
      links3: [{"file", "Orders", "Every order"}, {"users", "Customers", ""}],
      links3b: [
        {"file", "Orders", "Every order"},
        {"users", "Customers", "People and companies"},
        {"settings", "Settings", ""}
      ]
    }

    alerts =
      for v <- ~w(canvas soft bordered outline solid), into: %{} do
        assigns = %{v: v, colors: @acolors}

        {"alert-#{v}",
         ~H"""
         <.colm>
           <.al :for={c <- @colors} c={c} v={@v} title={String.capitalize(c)} desc="Contexto curto." />
         </.colm>
         """}
      end

    progress =
      for v <- ~w(solid soft gradient), into: %{} do
        assigns = %{v: v, colors: Enum.with_index(@pcol)}

        {"progress-#{v}",
         ~H"""
         <.colm>
           <.progress :for={{c, i} <- @colors} color={c} variant={@v} value={40 + i * 8} class="w-full" />
         </.colm>
         """}
      end

    tones7 = ~w(accent ai info pos warn neg violet)

    aura_tones =
      for {id, mode} <- [{"aura-tones", "spin"}, {"aura-tones-dual", "dual"}, {"aura-tones-glow", "glow"}], into: %{} do
        assigns = %{tones: tones7, mode: mode, chip: @chip}

        {id,
         ~H"""
         <.row>
           <.aura :for={t <- @tones} mode={@mode} tone={t}><span class={@chip}>{t}</span></.aura>
         </.row>
         """}
      end

    skel_anim =
      ~H"""
      <div style="display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:16px">
        <div :for={a <- ~w(wave pulse none)} style="display:flex;flex-direction:column;gap:8px">
          <span class="font-mono text-xs leading-4 text-muted">{a}</span>
          <.skeleton animation={a} class="w-4/5" />
          <.skeleton animation={a} class="w-[55%]" />
        </div>
      </div>
      """

    base =
      %{
        "alert-pill" => ~H"""
        <.colm>
          <.al c="info" v="soft" shape="pill" title="Dados de demonstração" desc="Workspace com dados gerados." />
          <.al c="warning" v="bordered" shape="pill" title="Atenção" desc="Revise antes de continuar." />
          <.al c="neutral" v="canvas" shape="pill" title="Aviso" desc="Contexto curto." dismiss />
        </.colm>
        """,
        "alert-accent" => ~H"""
        <.colm>
          <.al c="warning" v="canvas" title="7 de 11 cancelamentos Pro vieram de falha de pagamento" desc="Revise a régua de cobrança." accent="" action dismiss />
          <.al c="error" v="soft" title="Sincronização falhou" desc="Última tentativa há 12 min." accent="left" />
          <.al c="success" v="outline" title="Relatório exportado" desc="board-pack-oct-2026.pdf" accent="right" />
          <.al c="info" v="solid" title="Dados de demonstração" desc="Este workspace usa dados gerados." accent="" action />
        </.colm>
        """,
        "alert-actions" => ~H"""
        <.colm>
          <.al c="primary" v="soft" title="Pagamento pendente" desc="Revise a régua." action dismiss />
          <.al c="error" v="solid" title="Pagamento pendente" desc="Revise a régua." action dismiss />
          <.al c="warning" v="bordered" title="Pagamento pendente" desc="Revise a régua." action dismiss />
          <.al c="info" v="outline" title="Pagamento pendente" desc="Revise a régua." action dismiss />
          <.al c="neutral" v="canvas" title="Pagamento pendente" desc="Revise a régua." action dismiss />
        </.colm>
        """,
        "alert-bare" => ~H"""
        <.colm>
          <.alert color="warning" variant={nil}>Certificado vence em 3 dias</.alert>
          <.alert color="info" variant="soft">Só texto, sem ícone nem título</.alert>
        </.colm>
        """,
        "aura-modes" => ~H"""
        <.row>
          <.aura :for={m <- ~w(spin dual glow)} mode={m} tone="ai"><span class={@chip}>{m}</span></.aura>
        </.row>
        """,
        "aura-modes-accent" => ~H"""
        <.row>
          <.aura :for={m <- ~w(spin dual glow)} mode={m} tone="accent"><span class={@chip}>{m}</span></.aura>
        </.row>
        """,
        "aura-widths" => ~H"""
        <.row>
          <.aura :for={w <- ~w(xs sm default lg)} tone="ai" width={w}><span class={@chip}>width={w}</span></.aura>
        </.row>
        """,
        "aura-shapes" => ~H"""
        <.row>
          <.aura tone="ai" width="sm" radius="pill"><.button shape="pill" icon="sparkles">Resumir com IA</.button></.aura>
          <.aura tone="accent" radius="r12" shadow><span class={@chip}>r12 + shadow</span></.aura>
          <.aura mode="dual" tone="info" radius="pill" shadow><span class={@chip}>pill</span></.aura>
        </.row>
        """,
        "spinner-variants" => ~H"""
        <.colm>
          <.row :for={v <- ~w(canvas border soft grow svg)}><.sp :for={s <- @sizes} v={v} s={s} /></.row>
        </.colm>
        """,
        "spinner-colors" => ~H"""
        <.colm>
          <.row><.sp :for={c <- Enum.take(@pcol, 7)} v="border" s="md" c={c} /></.row>
          <.row><.sp :for={c <- Enum.take(@pcol, 7)} v="canvas" s="md" c={c} /></.row>
          <.row><.sp :for={c <- Enum.take(@pcol, 7)} v="soft" s="md" c={c} /></.row>
        </.colm>
        """,
        "skeleton-animation" => skel_anim,
        "skeleton-shapes" => ~H"""
        <.row>
          <.skeleton class="h-8 w-12" />
          <.skeleton shape="pill" class="h-5 w-16" />
          <.skeleton shape="circle" class="h-10 w-10" />
          <.skeleton shape="square" class="h-8 w-12" />
          <.skeleton shape="lg" class="h-10 w-16" />
        </.row>
        """,
        "skeleton-layout" => ~H"""
        <div class="flex flex-col gap-3.5 rounded-lg border border-line bg-panel p-3.5">
          <div :for={_ <- 1..3} style="display:flex;align-items:center;gap:10px;flex-wrap:nowrap">
            <.skeleton shape="circle" class="h-8 w-8" />
            <div style="display:flex;flex-direction:column;flex:1;min-width:0;gap:6px">
              <.skeleton class="w-[55%]" />
              <.skeleton animation="pulse" class="h-2.5 w-[35%]" />
            </div>
          </div>
        </div>
        """,
        "skeleton-lineone" => ~H"""
        <.colm>
          <.skeleton variant="lineone" class="w-[60%]" />
          <.skeleton variant="lineone" class="h-[34px] w-[40%]" />
        </.colm>
        """,
        "progress-default" => ~H"""
        <.colm>
          <.progress value={64} />
          <.progress value={0} color="primary" />
          <.progress value={100} color="success" />
        </.colm>
        """,
        "progress-sizes" => ~H"""
        <.colm>
          <.progress :for={s <- ~w(sm md lg xl)} color="primary" size={s} value={68} label={if s == "xl", do: "68%"} />
        </.colm>
        """,
        "progress-heights" => ~H"""
        <.colm>
          <.progress :for={h <- ~w(1 1.5 2 3 4)} color="info" height={h} value={60} />
        </.colm>
        """,
        "progress-states" => ~H"""
        <.colm>
          <.progress color="primary" indeterminate />
          <.progress color="primary" value={60} active />
          <.progress color="primary" indeterminate shine />
          <.progress color="success" variant="soft" size="lg" value={45} active />
        </.colm>
        """,
        "progress-stack" => ~H"""
        <.colm>
          <.progress_stack label="Receita por plano">
            <:segment value={52.6} color="1" />
            <:segment value={26.6} color="3" />
            <:segment value={20.8} color="4" />
          </.progress_stack>
          <.progress_stack>
            <:segment value={40} color="3" />
            <:segment value={30} color="4" />
          </.progress_stack>
        </.colm>
        """,
        "empty-canvas" => ~H"""
        <.colm>
          <div class="rounded-lg border border-line bg-panel">
            <.empty_state icon="table" title="Nenhuma coorte ainda">
              Conecte o Stripe para ver a retenção mês a mês dos seus clientes.
              <:action><.button size="sm">Conectar Stripe</.button></:action>
            </.empty_state>
          </div>
          <div class="rounded-lg border border-line bg-panel">
            <.empty_state icon="check-circle" tone="positive" title="Tudo em dia">Nenhuma fatura vencida.</.empty_state>
          </div>
          <div class="rounded-lg border border-line bg-panel"><.empty_state title="Sem ícone" /></div>
        </.colm>
        """,
        "empty-card" => ~H"""
        <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:16px">
          <.emp_card :for={t <- ~w(default gradient positive)} tone={t} />
        </div>
        """,
        "empty-card-heading" => ~H"""
        <.emp_card title="Nenhum pedido" kicker="Pedidos" level={3} />
        """,
        "empty-inline" => ~H"""
        <.colm>
          <.empty_state :for={c <- ~w(neutral success error)} variant="inline" icon="inbox" color={c} title="Sem comentários ainda.">Escrever o primeiro</.empty_state>
        </.colm>
        """,
        "empty-plain" => ~H"""
        <div class="rounded-lg border border-line bg-panel px-3 py-2">
          <.empty_state variant="plain" icon="check-circle" title="Tudo em dia — nenhuma fatura vencida." />
        </div>
        """,
        "empty-table" => ~H"""
        <div class="rounded-lg border border-line bg-panel">
          <.empty_state :for={c <- ~w(neutral success error)} variant="table" icon="inbox" color={c} title="Nada por aqui">
            Importe uma planilha para começar.
            <:action><.button variant="outline" size="sm">Importar</.button></:action>
          </.empty_state>
        </div>
        """,
        "error-page-404" => ~H"""
        <.error_page code={404} request_id="req_8f2a91" timestamp="2026-11-04 14:22 UTC" back_label="Go back">
          <:brand><b>Acme</b></:brand>
          <:status href="https://status.acme.com">All systems operational</:status>
          <:actions><.button size="lg">Back home</.button></:actions>
          <.links_block title="Maybe you were looking for" links={@links3} />
          <:footer><a href="/help">Help center</a></:footer>
        </.error_page>
        """,
        "error-page-500" => ~H"""
        <.error_page code={500}>
          <:actions><.button>Try again</.button></:actions>
          <:card><div class="rounded-lg border border-line bg-panel px-3.5 py-3">Incident INC-204 is being investigated</div></:card>
        </.error_page>
        """,
        "error-page-tones" => ~H"""
        <.error_page id="p403" code={403} />
        <.error_page id="p419" code={419} />
        """,
        "error-state" => ~H"""
        <.colm>
          <.error_state code={404} title="Order #2499 not found">It may have been deleted or belong to another branch.</.error_state>
          <.error_state code={500} title="We were notified" description="Try again in a moment.">
            <:actions><.button size="sm">Retry</.button></:actions>
          </.error_state>
          <.error_state code={403} title="You do not have access" description="Ask the owner.">
            <:actions><.button variant="outline" size="sm">Request access</.button></:actions>
            <:more><.links_block title="Try instead" links={[{"file", "Orders", "Every order"}]} /></:more>
          </.error_state>
          <.error_state code={401} title="Sign in to continue" description="Your session ended." />
        </.colm>
        """,
        "error-links" => ~H"""
        <.links_block title="Maybe you were looking for" links={@links3b} />
        """,
        "toast-card-light" => ~H"""
        <div style="display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px">
          <.toast_card :for={{k, t, i} <- @kinds} kind={k} icon={i} title={t} description="Orbit Cloud · agora" close_label="Close" />
        </div>
        """,
        "toast-card-dark" => ~H"""
        <div style="display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px">
          <.toast_card :for={{k, t, i} <- @dark_kinds} tone="dark" kind={k} icon={i} title={t} description="Orbit Cloud · agora" close_label="Close" />
        </div>
        """,
        "toast-card-plain" => ~H"""
        <.stack>
          <.toast_card kind="neutral" title="Só o título" dismissible={false} />
          <.toast_card kind="success" title="Sem ícone" description="Com descrição" close_label="Close" />
          <.toast_card kind="primary" tone="dark" icon="sparkles" title="Escuro sem descrição" close_label="Close" />
        </.stack>
        """,
        "toast-card-actions" => ~H"""
        <.stack>
          <.toast_card kind="primary" icon="sparkles" title="3 new AI insights" description="Churn liderado por Pro, expansão em Scale." close_label="Close">
            <:action><.button size="sm">Ver</.button><.button variant="ghost" size="sm">Depois</.button></:action>
          </.toast_card>
          <.toast_card kind="success" icon="check-circle" title="Relatório exportado" description="board-pack.pdf" close_label="Close">
            <:action><.button variant="outline" size="sm">Ver</.button></:action>
          </.toast_card>
          <.toast_card kind="error" tone="dark" icon="x-circle" title="Falha ao sincronizar" description="Tente de novo" close_label="Close">
            <:action><.button color="error" variant="soft" size="sm">Tentar</.button></:action>
          </.toast_card>
        </.stack>
        """,
        "toast-card-aura" => ~H"""
        <.stack gap={16}>
          <.toast_card aura="spin" aura_tone="ai" busy dismissible={false} kind="primary" icon="sparkles" title="Lendo a nota fiscal…" description="O assistente está extraindo os itens." />
          <.toast_card aura="dual" aura_tone="ai" dismissible={false} kind="success" icon="check-circle" title="Conciliação pronta" description="18 lançamentos casados">
            <:action><.button variant="outline" size="sm">Ver</.button></:action>
          </.toast_card>
          <.toast_card aura="glow" aura_tone="warn" dismissible={false} kind="warning" icon="alert" title="Certificado vence hoje" description="Renove para continuar">
            <:action><.button size="sm">Renovar</.button></:action>
          </.toast_card>
          <.toast_card aura="spin" aura_tone="info" aura_width="xs" dismissible={false} kind="info" icon="info" title="Aura fina" description="width xs" />
        </.stack>
        """,
        "toast-card-progress" => ~H"""
        <.stack gap={12}>
          <.toast_card progress={42} kind="primary" icon="file" title="Emitindo NF-e do pedido #2491" description="Assinando o XML…" dismissible={false} />
          <.toast_card progress={100} progress_state="done" kind="success" icon="check" title="NF-e 48.212 autorizada" description="Protocolo 129 2611 0004 8221" dismissible={false} />
          <.toast_card progress={0} progress_state="fail" kind="error" icon="x-circle" title="Envio da planilha falhou" description="Linha 214: CNPJ inválido" dismissible={false}>
            <:action><.button variant="outline" size="sm">Tentar de novo</.button></:action>
          </.toast_card>
          <.toast_card progress={0} kind="primary" icon="file" title="Importando com valor zero" description="0%" dismissible={false} />
        </.stack>
        """,
        "toast-status" => ~H"""
        <.stack align="flex-start">
          <.status_toast state="run">Importando <b>stripe-oct.csv</b></.status_toast>
          <.status_toast state="run" percent={64}>Gerando board pack · <b>64%</b><:action ghost>Cancelar</:action></.status_toast>
          <.status_toast state="queue">Backup <b>orbit-db</b> na fila</.status_toast>
          <.status_toast state="ok">Deploy de <b>nexus_pro</b> concluído<:action>Ver</:action></.status_toast>
          <.status_toast state="err">Falha ao transmitir <b>NF-e 4312</b><:action>Tentar de novo</:action></.status_toast>
        </.stack>
        """,
        "toaster-static" => ~H"""
        <.toaster id="t1" contained>
          <.wrap><.toast_card kind="success" icon="check-circle" title="Relatório exportado" description="board-pack-oct-2026.pdf" dismissible={false} /></.wrap>
          <.wrap><.toast_card kind="info" icon="info" title="3 new AI insights" dismissible={false} /></.wrap>
          <.status_toast state="run">Importando <b>stripe-oct.csv</b></.status_toast>
          <.wrap><.toast_card kind="neutral" icon="info" title="Quarto toast, escondido" dismissible={false} /></.wrap>
        </.toaster>
        """,
        "toaster-static-top" => ~H"""
        <.toaster id="t2" contained position="right-top">
          <.wrap><.toast_card kind="success" icon="check-circle" title="Relatório exportado" description="board-pack-oct-2026.pdf" dismissible={false} /></.wrap>
          <.wrap><.toast_card kind="warning" icon="alert" title="Assentos em 80%" dismissible={false} /></.wrap>
        </.toaster>
        """,
        "connection-banner-toast" => ~H"""
        <.toast_card aura="spin" aura_tone="warn" dismissible={false} kind="primary" title="Connection lost" description="Trying to reconnect...">
          <:icon_tile><.spinner variant="border" size="sm" color="primary" label="Loading" /></:icon_tile>
        </.toast_card>
        """,
        "connection-banner" => ~H"""
        <.connection_banner /><span class="text-[13px] leading-[18px]">sem marcação visível</span>
        """
      }

    base
    |> Map.merge(alerts)
    |> Map.merge(progress)
    |> Map.merge(aura_tones)
  end
end
