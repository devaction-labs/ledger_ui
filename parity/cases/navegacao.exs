defmodule Parity.Cases.Navegacao do
  @moduledoc "Navegação (lado HEEx + Tailwind): mesmos ids de navegacao.py."
  use Phoenix.Component
  use LedgerUI
  import Parity.Common
  alias LedgerUI.Components.Dropdown

  @tvars ~w(line boxed pill text segmented nav)
  @tsizes ~w(xs sm md)
  @pl ~w(top-start top top-end right-start right right-end bottom-start bottom bottom-end left-start left left-end)
  @variants ~w(solid glow outline soft bordered flat glass ghost dim)
  @sizes ~w(xs sm md lg xl)

  # ---- helpers ------------------------------------------------------------------------

  attr :id, :string, required: true
  attr :variant, :string, default: "line"
  attr :size, :string, default: "md"
  attr :color, :string, default: nil
  attr :on, :integer, default: 0
  attr :vert, :boolean, default: false
  attr :items, :list, default: ["Todas", "Abertas", "Pagas"]

  defp mini_tabs(assigns) do
    ~H"""
    <.tabs
      id={@id}
      variant={@variant}
      size={@size}
      color={@color}
      orientation={if @vert, do: "vertical", else: "horizontal"}
      selected={"t#{@on}"}
    >
      <:tab :for={{t, i} <- Enum.with_index(@items)} name={"t#{i}"}>{t}</:tab>
    </.tabs>
    """
  end

  attr :shape, :string, default: "canvas"
  attr :size, :string, default: "md"
  attr :page, :integer, default: 2

  defp pg(assigns) do
    ~H"""
    <.pagination page={@page} total_pages={44} shape={@shape} size={@size} />
    """
  end

  attr :color, :string, default: "primary"
  attr :size, :string, default: nil
  attr :vert, :boolean, default: false
  attr :current, :integer, default: 2
  attr :error, :boolean, default: false
  attr :subs, :list, default: nil
  attr :labels, :list, default: ["Conta", "Plano", "Pagamento", "Revisão"]

  defp st(assigns) do
    ~H"""
    <.stepper
      color={@color}
      size={@size}
      current={@current}
      error={@error}
      orientation={if @vert, do: "vertical", else: "horizontal"}
    >
      <:step :for={{l, i} <- Enum.with_index(@labels)} label={l} sub={@subs && Enum.at(@subs, i)} />
    </.stepper>
    """
  end

  attr :variant, :string, required: true
  attr :color, :string, default: "primary"
  attr :counts, :boolean, default: false

  defp ml(assigns) do
    ~H"""
    <.menu_list variant={@variant} color={@color}>
      <:item
        :for={
          {{icon, t}, k} <-
            Enum.with_index([
              {"grid", "Visão geral"},
              {"cart", "Pedidos"},
              {"users", "Clientes"},
              {"wallet", "Financeiro"}
            ])
        }
        href="#"
        active={k == 1}
        count={if @counts, do: k * 4 + 3}
      >
        <.icon name={icon} />{t}
      </:item>
    </.menu_list>
    """
  end

  attr :on, :integer, default: 0
  attr :counts, :boolean, default: false

  defp vs(assigns) do
    ~H"""
    <.view_switcher
      id={"vs-#{@on}-#{@counts}"}
      value={Enum.at(~w(list board calendar table), @on)}
      views={
        for {{icon, label, v}, i} <-
              Enum.with_index([
                {"list", "Lista", "list"},
                {"kanban", "Quadro", "board"},
                {"calendar", "Agenda", "calendar"},
                {"table", "Tabela", "table"}
              ]) do
          %{label: label, value: v, icon: icon, count: if(@counts, do: i * 3 + 4)}
        end
      }
    />
    """
  end

  defp dd_items(assigns) do
    ~H"""
    <.dropdown_item :for={
      {t, i} <- [
        {"Editar", "edit"},
        {"Duplicar", "copy"},
        {"Compartilhar", "link"},
        {"Arquivar", "folder"}
      ]
    }>
      <:icon><.icon name={i} /></:icon>{t}
    </.dropdown_item>
    <.dropdown_separator />
    <.dropdown_item danger><:icon><.icon name="trash" /></:icon>Excluir</.dropdown_item>
    """
  end

  # ---- cases ---------------------------------------------------------------------------

  def cases do
    assigns = %{
      tvars: @tvars,
      tsizes: @tsizes,
      pl: @pl,
      variants: @variants,
      sizes: @sizes,
      colors: ~w(neutral primary secondary info success warning error),
      vsizes: ~w(sm md lg)
    }

    %{
      "tabs-matrix" => ~H"""
      <.colm>
        <.row :for={v <- @tvars}>
          <.mini_tabs :for={s <- @tsizes} id={"m-#{v}-#{s}"} variant={v} size={s} />
        </.row>
      </.colm>
      """,
      "tabs-color" => ~H"""
      <.row>
        <.colm>
          <.mini_tabs id="c1" variant="pill" color="primary" />
          <.mini_tabs id="c2" variant="pill" color="neutral" />
          <.mini_tabs id="c3" variant="text" color="primary" />
          <.mini_tabs id="c4" variant="text" color="neutral" />
        </.colm>
        <.mini_tabs
          id="v1"
          variant="line"
          vert
          items={["Geral", "Cobrança", "Equipe", "Integrações"]}
          on={1}
        />
        <.mini_tabs id="v2" variant="nav" vert items={["Geral", "Cobrança", "Equipe"]} on={0} />
      </.row>
      """,
      "tabs-active" => ~H"""
      <.colm>
        <.mini_tabs :for={v <- @tvars} id={"a-#{v}"} variant={v} on={2} />
      </.colm>
      """,
      "tabs-vertical" => ~H"""
      <.row>
        <.mini_tabs
          id="tv1"
          variant="boxed"
          size="md"
          vert
          items={["Geral", "Cobrança", "Equipe"]}
          on={1}
        />
        <.mini_tabs
          id="tv2"
          variant="boxed"
          size="sm"
          vert
          items={["Geral", "Cobrança", "Equipe"]}
          on={1}
        />
        <.mini_tabs
          id="tv3"
          variant="pill"
          size="md"
          vert
          items={["Geral", "Cobrança", "Equipe"]}
          on={1}
        />
        <.mini_tabs
          id="tv4"
          variant="text"
          size="sm"
          vert
          items={["Geral", "Cobrança", "Equipe"]}
          on={1}
        />
        <.mini_tabs
          id="tv5"
          variant="segmented"
          size="md"
          vert
          items={["Geral", "Cobrança", "Equipe"]}
          on={1}
        />
        <.mini_tabs
          id="tv6"
          variant="line"
          size="xs"
          vert
          items={["Geral", "Cobrança", "Equipe"]}
          on={1}
        />
      </.row>
      """,
      "tabs-count" => ~H"""
      <.colm>
        <.tabs id="n1" variant="line" selected="a">
          <:tab name="a">Visão geral</:tab>
          <:tab name="b" count={12}>Faturas</:tab>
          <:tab name="c">Uso</:tab>
          <:tab name="d" count={3} count_tone="acc">Atividade</:tab>
          <:tab name="e" count={2} count_tone="neg">Vencidas</:tab>
        </.tabs>
        <.tabs id="n2" variant="boxed" selected="b">
          <:tab name="a" count={48}>Todas</:tab>
          <:tab name="b" count={7} count_tone="acc">Abertas</:tab>
          <:tab name="c" count={41} count_tone="pos">Pagas</:tab>
        </.tabs>
      </.colm>
      """,
      "tabs-classic" => ~H"""
      <.colm>
        <.tabs id="k1" variant="classic" selected="a">
          <:tab name="a">Visão geral</:tab>
          <:tab name="b" count={12}>Faturas</:tab>
          <:tab name="c">Uso</:tab>
          <:tab name="d" count={3} count_tone="acc">Atividade</:tab>
          <:tab name="e">Configurações</:tab>
        </.tabs>
        <.tabs id="k2" variant="classic" selected="b">
          <:tab name="a"><.icon name="grid" size="md" />Overview</:tab>
          <:tab name="b"><.icon name="trend-up" size="md" />Revenue</:tab>
          <:tab name="c"><.icon name="users" size="md" />Customers</:tab>
        </.tabs>
      </.colm>
      """,
      "tabs-links" => ~H"""
      <.colm>
        <.tabs :for={v <- ~w(line boxed pill nav)} id={"l-#{v}"} variant={v} selected="b">
          <:tab name="a" href="#">Todas</:tab>
          <:tab name="b" href="#">Abertas</:tab>
          <:tab name="c" href="#">Pagas</:tab>
        </.tabs>
      </.colm>
      """,
      "breadcrumb-variants" => ~H"""
      <.colm>
        <.row :for={v <- [nil, "canvas", "plain", "bordered"]}>
          <span class="w-[80px] font-mono text-[12px] leading-4 text-muted">{v || "default"}</span>
          <.breadcrumb variant={v} label="Trilha">
            <:item href="#">Signetum</:item>
            <:item href="#">Vendas</:item>
            <:item>Pedido #2491</:item>
          </.breadcrumb>
        </.row>
      </.colm>
      """,
      "breadcrumb-icon" => ~H"""
      <.colm>
        <.breadcrumb label="Trilha">
          <:item href="#" icon="grid">Orbit Cloud</:item>
          <:item>Overview</:item>
        </.breadcrumb>
        <.breadcrumb variant="canvas" label="Trilha">
          <:item href="#" icon="grid">Orbit Cloud</:item>
          <:item href="#">Contas</:item>
          <:item>Nordic Pay</:item>
        </.breadcrumb>
      </.colm>
      """,
      "breadcrumb-truncated" => ~H"""
      <.colm>
        <.breadcrumb label="Trilha" id="bc1" max_items={4}>
          <:item href="#">St. Aurelia General</:item>
          <:item href="#">Unit</:item>
          <:item href="#">Floor</:item>
          <:item href="#">ICU</:item>
          <:item>Cases</:item>
        </.breadcrumb>
        <.breadcrumb variant="canvas" label="Trilha" id="bc2" max_items={4}>
          <:item href="#">Início</:item>
          <:item href="#">Loja</:item>
          <:item href="#">Canal</:item>
          <:item href="#">Vendas</:item>
          <:item>Pedido #2491</:item>
        </.breadcrumb>
      </.colm>
      """,
      "pagination-matrix" => ~H"""
      <.colm>
        <.row :for={sh <- ~w(canvas rounded pill)}>
          <span class="w-[70px] font-mono text-[12px] leading-4 text-muted">{sh}</span>
          <.pg :for={s <- @vsizes} shape={sh} size={s} />
        </.row>
      </.colm>
      """,
      "pagination-current" => ~H"""
      <.colm>
        <.pg shape="canvas" size="md" page={1} />
        <.pagination page={4} total_pages={44} shape="rounded" on_change="go" />
        <.pg shape="pill" size="sm" page={3} />
      </.colm>
      """,
      "pagination-classic" => ~H"""
      <.pagination page={2} total_pages={44} shape="classic" summary="1–25 de 1.096" />
      """,
      "pagination-footer" => ~H"""
      <.pagination
        page={2}
        total_entries={660}
        page_size={15}
        page_sizes={[15, 30]}
        on_page_size="ps"
        shape="rounded"
        size="sm"
      />
      """,
      "steps-color" => ~H"""
      <.colm>
        <.row :for={c <- @colors}>
          <span class="w-[80px] font-mono text-[12px] leading-4 text-muted">{c}</span>
          <.st color={c} />
        </.row>
      </.colm>
      """,
      "steps-size" => ~H"""
      <.colm>
        <.st :for={s <- ~w(xs sm md lg)} size={s} />
        <.st error current={2} />
      </.colm>
      """,
      "steps-vertical" => ~H"""
      <.grid2>
        <.st vert subs={["Dados do CNPJ", "Profissional", "Cartão final 4417", "Confirme e ative"]} />
        <.st
          vert
          color="success"
          labels={["Pedido recebido", "Separado", "NF-e emitida", "Saiu para entrega"]}
          subs={["14:02", "14:40", "agora", "—"]}
        />
      </.grid2>
      """,
      "steps-classic" => ~H"""
      <.stepper variant="classic" current={2}>
        <:step label="Conta" />
        <:step label="Plano" />
        <:step label="Pagamento" />
        <:step label="Revisão" />
      </.stepper>
      """,
      "menu-list-matrix" => ~H"""
      <.colm>
        <.row :for={c <- ~w(primary neutral)}>
          <.ml :for={v <- ~w(link solid pill)} variant={v} color={c} />
        </.row>
        <.row :for={c <- ~w(primary neutral)}>
          <.ml :for={v <- ~w(gradient bordered static)} variant={v} color={c} />
        </.row>
      </.colm>
      """,
      "menu-list-count" => ~H"""
      <.row>
        <.ml variant="solid" counts />
        <.ml variant="pill" color="neutral" counts />
      </.row>
      """,
      "menu-row" => ~H"""
      <.menu_list variant="static" rows={[1, 2]}>
        <:row :let={n}>
          <.menu_row :if={n == 1} title="Pedidos" sub="11 abertos" unread>
            <:icon><.icon name="grid" /></:icon>
            <:value><b>R$ 4.200</b></:value>
          </.menu_row>
          <.menu_row :if={n == 2} title="Clientes" href="#">
            <:value><span class="text-muted">38</span></:value>
          </.menu_row>
        </:row>
      </.menu_list>
      """,
      "scrollspy-demo" => ~H"""
      <div class="w-[170px]">
        <.scrollspy id="spy" demo label={nil}>
          <:item href="#" style="--dl:0s">Dados gerais</:item>
          <:item href="#" style="--dl:2s">Endereço</:item>
          <:item href="#" style="--dl:4s">Fiscal</:item>
          <:item href="#" style="--dl:6s">Financeiro</:item>
        </.scrollspy>
      </div>
      """,
      "view-switcher-seg" => ~H"""
      <.colm>
        <.vs on={0} />
        <.vs on={2} />
        <.vs on={1} counts />
      </.colm>
      """,
      "view-switcher-row" => ~H"""
      <.row>
        <.view_switcher
          id="vsr"
          value="list"
          views={[
            %{label: "Lista", value: "list", icon: "list"},
            %{label: "Quadro", value: "board", icon: "kanban"},
            %{label: "Agenda", value: "calendar", icon: "calendar"},
            %{label: "Tabela", value: "table", icon: "table"}
          ]}
          saved={[%{label: "Pro churn watch", value: "pcw"}]}
          saved_value="pcw"
          options={[%{label: "Gráfico", value: "chart", icon: "bar-chart"}]}
          add_label="Salvar visão"
          class="contents"
        />
      </.row>
      """,
      "dropdown-open" => ~H"""
      <div class="h-[300px] px-5 pt-2.5">
        <.dropdown id="dd1" label="Ações" demo="loop" class="w-[220px]"><.dd_items /></.dropdown>
      </div>
      """,
      "dropdown-open-end" => ~H"""
      <div class="h-[300px] px-5 pt-2.5 text-right">
        <.dropdown
          id="dd2"
          toggle_icon="dots"
          toggle_label="Mais ações"
          placement="bottom-end"
          demo="loop"
          class="w-[220px]"
        >
          <.dd_items />
        </.dropdown>
      </div>
      """,
      "dropdown-triggers" => ~H"""
      <.row>
        <.dropdown
          :for={c <- ~w(neutral primary secondary info success warning error mono)}
          id={"t-#{c}"}
          label="Período"
          color={c}
        >
          <.dropdown_item>x</.dropdown_item>
        </.dropdown>
      </.row>
      """,
      "dropdown-kebab" => ~H"""
      <.row>
        <.dropdown id="k1" toggle_icon="dots" toggle_label="Mais">
          <.dropdown_item>x</.dropdown_item>
        </.dropdown>
        <.dropdown id="k2" toggle_icon="dots-vertical" toggle_label="Mais">
          <.dropdown_item>x</.dropdown_item>
        </.dropdown>
        <.dropdown id="k3" label="rounded">
          <.dropdown_item>x</.dropdown_item>
        </.dropdown>
        <.dropdown id="k4" label="pill" shape="pill">
          <.dropdown_item>x</.dropdown_item>
        </.dropdown>
      </.row>
      """,
      "dropdown-split" => ~H"""
      <.row>
        <.dropdown id="s1" color="mono" toggle_label="Mais">
          <:action>Emitir NF-e</:action>
          <.dropdown_item>x</.dropdown_item>
        </.dropdown>
        <.dropdown id="s2" color="primary" toggle_label="Mais">
          <:action>Salvar</:action>
          <.dropdown_item>x</.dropdown_item>
        </.dropdown>
        <.dropdown id="s3" color="neutral" toggle_label="Mais">
          <:action>Exportar</:action>
          <.dropdown_item>x</.dropdown_item>
        </.dropdown>
      </.row>
      """,
      "dropdown-items" => ~H"""
      <div class={Dropdown.pop_classes(min: "w-[280px]")}>
        <.dropdown_item><:icon><.icon name="external" /></:icon>Abrir pedido</.dropdown_item>
        <.dropdown_item color="primary"><:icon><.icon name="file" /></:icon>Emitir NF-e</.dropdown_item>
        <.dropdown_separator />
        <.dropdown_item variant="media" description="Financeiro">
          <:icon><.icon name="user" /></:icon>Ana Nogueira
        </.dropdown_item>
        <.dropdown_item variant="media" description="Dev">
          <:icon><.icon name="user" /></:icon>Carlos André
        </.dropdown_item>
        <.dropdown_separator />
        <.dropdown_item color="error">
          <:icon><.icon name="x-circle" /></:icon>Cancelar pedido
        </.dropdown_item>
      </div>
      """,
      "dropdown-rich" => ~H"""
      <.row>
        <div class={Dropdown.pop_classes(min: "w-[240px]")}>
          <.dropdown_label>Período</.dropdown_label>
          <.dropdown_item selected><:icon><.icon name="calendar" /></:icon>Out 2026</.dropdown_item>
          <.dropdown_item><:icon><.icon name="calendar" /></:icon>Sep 2026</.dropdown_item>
          <.dropdown_item><:icon><.icon name="calendar" /></:icon>Q3 2026</.dropdown_item>
          <.dropdown_separator />
          <.dropdown_item><:icon><.icon name="edit" /></:icon>Personalizado…</.dropdown_item>
        </div>
        <div class={Dropdown.pop_classes(min: "w-[250px]")}>
          <.dropdown_item shortcut="E"><:icon><.icon name="edit" /></:icon>Editar</.dropdown_item>
          <.dropdown_item shortcut="⌘ D"><:icon><.icon name="copy" /></:icon>Duplicar</.dropdown_item>
          <.dropdown_item><:icon><.icon name="link" /></:icon>Compartilhar</.dropdown_item>
          <.dropdown_item>
            <:icon><.icon name="folder" /></:icon>Mover para<:trailing>
              <.icon name="chevron-right" size="sm" />
            </:trailing>
          </.dropdown_item>
          <.dropdown_separator />
          <.dropdown_item danger shortcut="⌫">
            <:icon><.icon name="trash" /></:icon>Excluir
          </.dropdown_item>
        </div>
      </.row>
      """,
      "dropdown-extras" => ~H"""
      <div class={Dropdown.pop_classes(min: "w-[260px]")}>
        <.dropdown_search placeholder="Buscar" />
        <.dropdown_header subtitle="ana@empresa.com">Ana Nogueira</.dropdown_header>
        <.dropdown_separator />
        <.dropdown_checkbox checked count={12}>Em aberto</.dropdown_checkbox>
        <.dropdown_checkbox count={41}>Pagos</.dropdown_checkbox>
        <.dropdown_item disabled>Arquivadas</.dropdown_item>
        <.dropdown_footer apply_count={2} on_apply="x" />
      </div>
      """,
      "dropdown-placement" => ~H"""
      <div class="grid grid-cols-4 gap-1.5">
        <div :for={p <- @pl} class="grid h-[170px] place-items-center">
          <.dropdown
            id={"pl-#{p}"}
            placement={p}
            demo="loop"
            class="w-[230px]"
            toggle_label={p}
            label={p}
          >
            <.dropdown_item><:icon><.icon name="edit" /></:icon>Editar</.dropdown_item>
            <.dropdown_item danger><:icon><.icon name="trash" /></:icon>Excluir</.dropdown_item>
          </.dropdown>
        </div>
      </div>
      """,
      "action-menu-open" => ~H"""
      <div class="h-[300px] px-5 pt-2.5">
        <.action_menu id="am1" label="Ações" demo="loop" class="w-[230px]">
          <:title>Pedido #2491</:title>
          <.action_menu_item icon="external">Ver relatório</.action_menu_item>
          <.action_menu_item icon="download">Baixar CSV</.action_menu_item>
          <.action_menu_item icon="compare">Comparar com 2025</.action_menu_item>
          <.action_menu_item icon="sparkles">Perguntar à IA</.action_menu_item>
          <.action_menu_separator />
          <.action_menu_item icon="x" danger>Remover do dashboard</.action_menu_item>
        </.action_menu>
      </div>
      """,
      "action-menu-trigger" => ~H"""
      <.row>
        <.action_menu id="am2" label="Ações">
          <.action_menu_item>x</.action_menu_item>
        </.action_menu>
      </.row>
      """,
      "action-menu-rich" => ~H"""
      <div class={Dropdown.pop_classes(min: "w-[260px]")}>
        <.action_menu_item icon="external" kbd="↵">Abrir</.action_menu_item>
        <.action_menu_item icon="edit" kbd="F2">Renomear</.action_menu_item>
        <.action_menu_item icon="link" kbd="⌘ L">Copiar link</.action_menu_item>
        <.action_menu_separator />
        <.action_menu_item icon="file" hint="Gera o XML e o PDF">Emitir NF-e</.action_menu_item>
        <.action_menu_item disabled>Arquivar</.action_menu_item>
        <.action_menu_item icon="trash" kbd="⌫" danger>Excluir</.action_menu_item>
      </div>
      """,
      "action-button-variants" => ~H"""
      <.colm>
        <.row>
          <.action_button :for={v <- @variants} label={"Excluir #{v}"} icon="trash" variant={v} />
        </.row>
        <.row>
          <.action_button :for={v <- @variants} label={"Excluir #{v}"} icon="trash" variant={v} danger />
        </.row>
      </.colm>
      """,
      "action-button-sizes" => ~H"""
      <.row>
        <.action_button :for={s <- @sizes} label="Ações" icon="more-h" variant="ghost" size={s} />
      </.row>
      """,
      "action-button-label" => ~H"""
      <.row>
        <.action_button label="Abrir" icon="external" size="sm">Abrir</.action_button>
        <.action_button label="Excluir" icon="trash" danger variant="soft" size="md">Excluir</.action_button>
      </.row>
      """,
      "action-button-row" => ~H"""
      <div class="flex w-[420px] items-center gap-3 rounded-lg border border-line bg-panel px-3.5 py-2.5">
        <span class="min-w-0 flex-1">Nordic Pay · INV-1043</span>
        <.action_button label="Excluir" icon="trash" danger variant="ghost" />
      </div>
      """,
      "steps-loop" => ~H"""
      <.stepper loop color="primary">
        <:step label="Pedido" style="--dl:0.0s" />
        <:step label="Separação" style="--dl:1.4s" />
        <:step label="Nota fiscal" style="--dl:2.8s" />
        <:step label="Entrega" style="--dl:4.2s" />
      </.stepper>
      """,
      "pagination-loop" => ~H"""
      <.pagination loop page={0} total_pages={44} />
      """,
      "menu-list-loop" => ~H"""
      <.menu_list demo variant="pill">
        <:item href="#" style="--dl:0s"><.icon name="grid" />Visão geral</:item>
        <:item href="#" style="--dl:1.5s"><.icon name="cart" />Pedidos</:item>
        <:item href="#" style="--dl:3s"><.icon name="users" />Clientes</:item>
        <:item href="#" style="--dl:4.5s"><.icon name="wallet" />Financeiro</:item>
      </.menu_list>
      """,
      "context-menu-box" => ~H"""
      <div class="[&_[popover]]:static [&_[popover]]:m-0 [&_[popover]]:block [&_[popover]]:w-[230px] [&_[popover]]:overflow-visible">
        <.context_menu id="ctx1">
          <span></span>
          <:item icon="external" kbd="↵">Abrir</:item>
          <:item icon="edit" kbd="F2">Renomear</:item>
          <:item icon="link" kbd="⌘ L">Copiar link</:item>
          <:item icon="trash" kbd="⌫" tone="danger" divider>Excluir</:item>
        </.context_menu>
      </div>
      """
    }
  end

  attr :cols, :integer, default: 2
  slot :inner_block, required: true

  defp grid2(assigns) do
    ~H"""
    <div style="display:grid;gap:16px;grid-template-columns:repeat(2,minmax(0,1fr))">
      {render_slot(@inner_block)}
    </div>
    """
  end
end
