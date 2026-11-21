defmodule Parity.Cases.ShellB do
  @moduledoc """
  Shell/app, parte B (lado HEEx + Tailwind): mesmos ids de shell_b.py. O lado original é um instantâneo
  desta mesma lista renderizado pela biblioteca ANTES da migração (commit 3506478) sobre a folha legada
  (ver shell_b_snapshot.sh). Os estados que o JS aplica (menu recolhido) vão como atributo no caso:
  `data-collapsed`.
  """
  use Phoenix.Component
  use LedgerUI
  import Parity.Common

  @nav [
    %{label: "Início", icon: "grid", href: "#", active: true},
    %{label: "Pedidos", icon: "cart", href: "#", count: "12"},
    %{label: "Notas fiscais", icon: "file", href: "#", kbd: "G N"},
    %{label: "Estoque", icon: "layers", href: "#", count: "3", alert: true},
    %{label: "Alertas", icon: "bell", href: "#", badge: "novo"},
    %{label: "Em breve", icon: "star", href: "#", disabled: "Em breve"},
    :separator,
    %{
      group: "Cadastros",
      items: [
        %{label: "Clientes", icon: "users", href: "#", count: "1.096"},
        %{label: "Produtos", icon: "box", href: "#"}
      ]
    },
    %{
      group: "Sistema",
      collapsible: true,
      open: true,
      items: [%{label: "Ajustes", icon: "settings", href: "#"}]
    },
    %{group: "Rodapé", footer: true, items: [%{label: "Ajuda", icon: "help", href: "#"}]}
  ]

  @tree [
    %{label: "Início", icon: "grid", href: "#", color: "blue", active: true},
    %{
      label: "Vendas",
      icon: "cart",
      color: "green",
      children: [%{label: "Pedidos", href: "#", active: true}, %{label: "Orçamentos", href: "#"}]
    },
    %{group: "Gestão", items: [%{label: "Equipe", icon: "users", href: "#", color: "violet"}]}
  ]

  @rail [
    %{label: "Início", icon: "home", href: "#"},
    %{
      group: "Vendas",
      icon: "cart",
      action: %{label: "Novo pedido", href: "#", icon: "add"},
      try: %{label: "Experimente", items: [%{label: "Relatórios", icon: "chart", href: "#"}]},
      items: [
        %{label: "Pedidos", href: "#", active: true, count: "8"},
        %{label: "Orçamentos", href: "#"},
        %{group: "Arquivo", items: [%{label: "Antigos", href: "#"}]}
      ]
    },
    %{group: "Financeiro", icon: "wallet", items: [%{label: "Contas", href: "#"}]},
    %{label: "Mensagens", icon: "message", href: "#", count: "2"}
  ]

  @nested [
    %{label: "Início", icon: "grid", href: "#", active: true},
    %{
      label: "Projetos",
      icon: "kanban",
      href: "#",
      children: [%{label: "Alpha", href: "#", color: "blue"}, %{label: "Beta", href: "#"}]
    },
    %{group: "Conta", items: [%{label: "Perfil", icon: "user", href: "#", caret: "right"}]}
  ]

  @brand %{name: "Signetum", sub: "Bom Preço · Matriz", mark: true, switch: true}
  @user %{name: "Marina Costa", email: "marina@ledger.com", status: "online"}

  # ---- helpers ------------------------------------------------------------------------

  attr :id, :string, required: true
  attr :nav, :list, default: @nav
  attr :format, :string, default: "sections"
  attr :variant, :string, default: "sidebar"
  attr :rest, :global
  attr :extra, :map, default: %{}
  attr :brand, :map, default: @brand

  defp sb(assigns) do
    ~H"""
    <.sidebar
      id={@id}
      format={@format}
      variant={@variant}
      nav={@nav}
      brand={@extra[:brand] || @brand}
      user={@extra[:user]}
      footer={@extra[:footer]}
      plan={@extra[:plan]}
      trial={@extra[:trial]}
      version={@extra[:version]}
      rail_extra={@extra[:rail_extra] || []}
      {@rest}
    />
    """
  end

  defp sbs(assigns) do
    ~H"""
    <div style="display:flex;gap:12px;align-items:flex-start;background:var(--lu-bg-page, var(--bg-page));padding:4px">
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :id, :string, required: true
  attr :layout, :string, required: true
  attr :full, :boolean, default: false

  defp mini_shell(assigns) do
    ~H"""
    <.app_shell id={@id} layout={@layout} full={@full}>
      <:sidebar>
        <.main_sidebar current="/b">
          <:logo><.icon name="grid" /></:logo>
          <:item navigate="/a" label="A" icon="grid" />
          <:item navigate="/b" label="B" icon="cart" />
          <:item navigate="/c" label="C" icon="file" />
          <:bottom><.main_sidebar_link label="Ajuda"><.icon name="help" /></.main_sidebar_link></:bottom>
        </.main_sidebar>
        <.sidebar_panel :if={@layout in ["sidebar", "framed"]} title="Layouts">
          <.sidebar_nav>
            <.sidebar_nav_link navigate="/a">Alpha</.sidebar_nav_link>
            <.sidebar_nav_link navigate="/b" current="/b">Beta</.sidebar_nav_link>
          </.sidebar_nav>
          <.sidebar_nav_divider />
          <.sidebar_nav_group label="Mais" open>
            <:item navigate="/g1">Um</:item>
            <:item navigate="/g2" active>Dois</:item>
          </.sidebar_nav_group>
        </.sidebar_panel>
      </:sidebar>
      <:header><.header search={false} theme_toggle={false} monochrome_toggle={false} /></:header>
      <.page_header title="Painel" description="Visão geral" />
      <div style="padding:0 28px 28px;color:var(--lu-muted, var(--muted))">Conteúdo</div>
    </.app_shell>
    """
  end

  attr :id, :string, default: "x"
  attr :variant, :string, default: "default"

  defp lnav(assigns) do
    ~H"""
    <.landing_nav id={@id} variant={@variant} brand={%{name: "Signetum", logo: "S", navigate: "/"}}>
      <:link label="Produto" caret />
      <:link label="Preços" navigate="/precos" active />
      <:link label="Clientes" navigate="/clientes" />
      <:actions>
        <.landing_login>Entrar</.landing_login>
        <.landing_cta>Começar grátis</.landing_cta>
      </:actions>
    </.landing_nav>
    """
  end

  # ---- cases --------------------------------------------------------------------------

  def cases do
    assigns = %{nav: @nav, tree: @tree, rail: @rail, nested: @nested, brand: @brand, user: @user}

    %{
      # ---- container / scroll area / sticky ---------------------------------------
      "container-fixed" =>
        ~H"""
        <div style="background:var(--lu-bg-sunken, var(--bg-sunken));width:1500px">
          <.container_fixed><div style="background:var(--lu-bg-panel, var(--bg-panel));padding:10px">fixed</div></.container_fixed>
        </div>
        """,
      "container-fluid" =>
        ~H"""
        <div style="background:var(--lu-bg-sunken, var(--bg-sunken))">
          <.container_fluid><div style="background:var(--lu-bg-panel, var(--bg-panel));padding:10px">fluid</div></.container_fluid>
          <.container size="prose"><div style="background:var(--lu-bg-panel, var(--bg-panel));padding:10px">prose</div></.container>
          <.container size="md"><div style="background:var(--lu-bg-panel, var(--bg-panel));padding:10px">md</div></.container>
          <.container size="full"><div style="background:var(--lu-bg-panel, var(--bg-panel));padding:10px">full</div></.container>
        </div>
        """,
      "container-preview" =>
        ~H"""
        <.colm>
          <.container_fixed :for={s <- ~w(sm md lg xl 2xl prose full)} preview size={s} />
          <.container_fluid preview label="fluid" width="56%" />
        </.colm>
        """,
      "scroll-plain" =>
        ~H"""
        <div style="display:flex;gap:12px">
          <.scroll_area style="height:90px;width:200px">
            <div :for={i <- 1..8} style="height:24px">linha {i}</div>
          </.scroll_area>
          <.scroll_area orientation="horizontal" scrollbar="always" style="width:200px">
            <div style="width:600px;height:70px">largo</div>
          </.scroll_area>
          <.scroll_area orientation="both" scrollbar="hidden" style="height:90px;width:200px">
            <div style="width:400px;height:200px">ambos</div>
          </.scroll_area>
        </div>
        """,
      "scroll-panel" =>
        ~H"""
        <.scroll_area variant="panel" focusable label="Notas" style="height:110px;width:260px">
          <div :for={i <- 1..8} style="height:30px;padding:0 12px">nota {i}</div>
        </.scroll_area>
        """,
      "scroll-preview" =>
        ~H"""
        <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:12px">
          <.scroll_area variant="preview" scrollbar="always" style="height:110px"><div style="padding:10px">vertical</div></.scroll_area>
          <.scroll_area variant="preview" orientation="both" scrollbar="hover" style="height:110px"><div style="padding:10px">hover</div></.scroll_area>
          <.scroll_area variant="preview" orientation="horizontal" scrollbar="hidden" style="height:110px"><div style="padding:10px">oculta</div></.scroll_area>
        </div>
        """,
      "sticky-preview" =>
        ~H"""
        <.sticky id="st-demo" preview>
          <:header><.icon name="cart" size="md" />Pedidos de hoje</:header>
          <i style="width:90%"></i><i style="width:70%"></i><i style="width:85%"></i><i style="width:60%"></i><i style="width:95%"></i>
        </.sticky>
        """,
      "sticky-bar" =>
        ~H"""
        <.sticky id="st-bar"><div style="padding:12px 16px;font-weight:600">Barra fixa</div></.sticky>
        """,

      # ---- logo ---------------------------------------------------------------------
      "logo-chart" =>
        ~H"""
        <.row>
          <.logo /><.logo tone="mono" /><.logo size={48} /><.logo size={28} wordmark /><.logo tone="mono" size={56} wordmark />
          <.logo name="Acme" context="Orbit Cloud" size={40} />
        </.row>
        """,
      "logo-hexagon" =>
        ~H"""
        <.row>
          <.logo mark="hexagon" size={64} /><.logo mark="hexagon" size={64} id="lg-1" /><.logo mark="hexagon" tone="mono" size={64} id="lg-2" />
          <.logo mark="hexagon" size={32} wordmark />
        </.row>
        """,

      # ---- theme switch / picker --------------------------------------------------------
      "theme-switch-matrix" =>
        ~H"""
        <.colm>
          <.row><.theme_switch id="ts1" /><.theme_switch id="ts2" size="sm" /><.theme_switch id="ts3" system={false} /></.row>
          <.row><.theme_switch id="ts4" variant="icons" /><.theme_switch id="ts5" variant="icons" size="sm" /></.row>
          <.row><.theme_switch id="ts6" variant="switch" dark_label="Escuro" /><.theme_switch id="ts7" variant="switch" size="sm" dark_label="Escuro" /></.row>
          <.theme_toggle id="tt1" />
        </.colm>
        """,
      "theme-picker-grid" =>
        ~H"""
        <.theme_picker id="tp1" variant="grid" themes={~w(ledger noite areia oceano)} default="ledger" />
        """,
      "theme-picker-menu" =>
        ~H"""
        <div style="height:46px"><.theme_picker id="tp2" /></div>
        """,

      # ---- icon rail, sidebar panel, page header, sub nav --------------------------
      "icon-rail" =>
        ~H"""
        <div style="display:flex;gap:16px;background:var(--lu-bg-shell, var(--bg-shell));padding:0 16px;height:400px">
          <.icon_rail current="/b">
            <:logo><.icon name="grid" /></:logo>
            <:item navigate="/a" label="A" icon="grid" />
            <:item navigate="/b" label="B" icon="cart" />
            <:item navigate="/c" label="C" icon="file" />
            <:bottom><.main_sidebar_link label="Ajuda"><.icon name="help" /></.main_sidebar_link></:bottom>
          </.icon_rail>
          <.main_sidebar centered>
            <:logo><.icon name="grid" /></:logo>
            <:item label="A" icon="grid" /><:item label="B" icon="cart" active />
          </.main_sidebar>
          <div style="display:flex;flex-direction:column;align-items:center;gap:8px">
            <.sidebar_profile id="sp1" src="data:image/gif;base64,R0lGODlhAQABAIAAAAUEBAAAACwAAAAAAQABAAACAkQBADs=" name="Marina" subtitle="Gerente" />
            <.sidebar_min_group>
              <.sidebar_min_link label="A" active><.icon name="grid" /></.sidebar_min_link>
              <.sidebar_min_link label="B"><.icon name="cart" /></.sidebar_min_link>
            </.sidebar_min_group>
            <.sidebar_min_divider />
          </div>
        </div>
        """,
      "sidebar-panel" =>
        ~H"""
        <div style="display:flex;background:var(--lu-bg-shell, var(--bg-shell));height:420px">
          <.sidebar_panel title="Layouts">
            <.sidebar_nav>
              <.sidebar_nav_link navigate="/a">Alpha</.sidebar_nav_link>
              <.sidebar_nav_link navigate="/b" current="/b">Beta</.sidebar_nav_link>
            </.sidebar_nav>
            <.sidebar_nav_divider />
            <.sidebar_nav_group label="Aberto" open>
              <:item navigate="/g1">Um</:item><:item navigate="/g2" active>Dois</:item>
            </.sidebar_nav_group>
            <.sidebar_nav_group label="Fechado"><:item navigate="/h1">Três</:item></.sidebar_nav_group>
          </.sidebar_panel>
          <.sub_nav title="Casos">
            <:group label="Status"><.sidebar_nav_link navigate="/s1">Abertos</.sidebar_nav_link><.sidebar_nav_link navigate="/s2" active>Fechados</.sidebar_nav_link></:group>
            <:group label="Equipe" open={false}><.sidebar_nav_link navigate="/e1">Todos</.sidebar_nav_link></:group>
          </.sub_nav>
        </div>
        """,
      "page-header-inline" =>
        ~H"""
        <div style="background:var(--lu-bg-page, var(--bg-page))">
          <.page_header title="Pedidos" description="Pedidos de novembro.">
            <:crumb navigate="/">Início</:crumb><:crumb navigate="/p">Vendas</:crumb><:crumb>Pedidos</:crumb>
            <:actions><.button color="mono">Novo pedido</.button></:actions>
            <:tabs><div style="height:40px;border-bottom:1px solid var(--lu-line, var(--line))">abas</div></:tabs>
          </.page_header>
          <.page_header>
            <:heading><span>Com marcação</span></:heading>
            <:subtitle><b>1.096</b> itens.</:subtitle>
          </.page_header>
        </div>
        """,
      "page-header-page" =>
        ~H"""
        <div style="background:var(--lu-bg-page, var(--bg-page))">
          <.page_header variant="page" title="Cliente" description="Detalhes" clock bell>
            <:crumb navigate="/">Início</:crumb><:crumb>Cliente</:crumb>
            <:badge><.badge color="success" size="sm">Ativo</.badge></:badge>
            <:actions><.button color="mono">Editar</.button></:actions>
          </.page_header>
          <.page_header variant="page" title="Voltar" back="/x" back_label="Clientes" badge_position="inline">
            <:badge><.badge color="info" size="sm">Novo</.badge></:badge>
            <:icon><.icon name="user" size="lg" /></:icon>
          </.page_header>
        </div>
        """,

      # ---- app shell / shell --------------------------------------------------------
      "app-shell-sidebar" => ~H"""
      <.mini_shell id="as1" layout="sidebar" full />
      """,
      "app-shell-framed" => ~H"""
      <.mini_shell id="as2" layout="framed" />
      """,
      "app-shell-minimal" => ~H"""
      <.mini_shell id="as3" layout="minimal" full />
      """,
      "shell-floating" =>
        ~H"""
        <.shell_floating id="sf1">
          <:sidebar><.main_sidebar><:logo><.icon name="grid" /></:logo><:item label="A" icon="grid" active /><:item label="B" icon="cart" /></.main_sidebar></:sidebar>
          <.page_header title="Flutuante" />
        </.shell_floating>
        """,
      "app-shell-sideblock" =>
        ~H"""
        <.app_shell id="as4" layout="sideblock">
          <:sidebar>
            <.sideblock>
              <:logo navigate="/"><.icon name="grid" /></:logo>
              <.sidebar_nav><.sidebar_nav_link navigate="/a" active>Alpha</.sidebar_nav_link><.sidebar_nav_link navigate="/b">Beta</.sidebar_nav_link></.sidebar_nav>
            </.sideblock>
          </:sidebar>
          <.page_header title="Sideblock" />
        </.app_shell>
        """,
      "app-shell-horizontal" =>
        ~H"""
        <.app_shell id="as5" layout="horizontal">
          <:sidebar></:sidebar>
          <:header>
            <.header id="hd5" search={false} theme_toggle={false} monochrome_toggle={false}>
              <:brand navigate="/">Signetum</:brand>
              <:nav>
                <.horizontal_nav_menu id="hn1" label="Vendas" active><:icon><.icon name="cart" size="md" /></:icon><:item navigate="/a">Pedidos</:item></.horizontal_nav_menu>
                <.horizontal_nav_menu id="hn2" label="Outros"><:item navigate="/o">Um</:item></.horizontal_nav_menu>
              </:nav>
            </.header>
          </:header>
          <.page_header title="Horizontal" />
        </.app_shell>
        """,
      "header-full" =>
        ~H"""
        <div style="background:var(--lu-bg-page, var(--bg-page))">
          <.header id="hd6" search_placeholder="Buscar…" right_sidebar="rs-x">
            <:notifications dot>Sem novas</:notifications>
          </.header>
        </div>
        """,
      "framed-sidebar" =>
        ~H"""
        <div style="display:flex;gap:12px;background:var(--lu-bg-shell, var(--bg-shell));padding:8px">
          <.framed_sidebar id="fs1">
            <:brand><.icon name="grid" /></:brand>
            <:wordmark>Ledger</:wordmark>
            <:workspace><.rail_workspace name="Orbit Cloud" subtitle="Finance" /></:workspace>
            <:search><.icon name="search" size="md" />Buscar</:search>
            <.rail_heading>Geral</.rail_heading>
            <.rail_link navigate="/a" label="Início" current="/a"><.icon name="grid" /></.rail_link>
            <.rail_link navigate="/b" label="Pedidos" badge="12"><.icon name="cart" /></.rail_link>
            <.rail_module id="rm1" label="Vendas" badge="2" open>
              <:icon><.icon name="wallet" /></:icon>
              <:item navigate="/m1" active>Notas</:item><:item navigate="/m2">Boletos</:item>
            </.rail_module>
            <:bottom><.rail_user name="Marina" subtitle="Gerente"><span style="width:32px;height:32px;border-radius:50%;background:var(--lu-bg-sunken, var(--bg-sunken))"></span></.rail_user></:bottom>
          </.framed_sidebar>
        </div>
        """,
      "tab-bar" =>
        ~H"""
        <.colm>
          <.tab_bar current="/a"><:tab navigate="/a" label="A"><.icon name="grid" /></:tab><:tab navigate="/b" label="B"><.icon name="cart" /></:tab><:tab navigate="/c" label="C"><.icon name="file" /></:tab></.tab_bar>
          <.tab_bar variant="canvas" current="/b"><:tab navigate="/a" label="A"><.icon name="grid" /></:tab><:tab navigate="/b" label="B"><.icon name="cart" /></:tab></.tab_bar>
        </.colm>
        """,
      "right-sidebar" =>
        ~H"""
        <div style="position:relative;height:300px;overflow:hidden">
          <.right_sidebar id="rs1" open>
            <:title><b>Painel</b></:title>
            Conteúdo
            <:footer><.button size="sm">Fechar</.button></:footer>
          </.right_sidebar>
        </div>
        """,
      "monochrome" =>
        ~H"""
        <.row><.monochrome_toggle id="mt1" /><.monochrome_toggle id="mt2" variant="switch">Mono</.monochrome_toggle></.row>
        """,
      "shell-wire" =>
        ~H"""
        <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:14px">
          <.shell :for={l <- ~w(sidebar minimal sideblock horizontal framed rail)} variant="preview" layout={l} />
        </div>
        """,
      "shell-app" =>
        ~H"""
        <.shell id="sh1" nav={@nav} sidebar="sections" current="#" brand={@brand} style="height:520px" user={@user}>
          <:topbar><.navbar><.navbar_crumbs items={[%{label: "Início", href: "#"}, %{label: "Pedidos"}]} /></.navbar></:topbar>
          <div style="padding:20px">conteúdo</div>
        </.shell>
        """,

      # ---- sidebar (formats, variants, collapsed) -----------------------------------
      "sidebar-sections" =>
        ~H"""
        <.sbs>
          <.sb id="sbs1" extra={%{plan: %{name: "Pro", text: "Plano atual", badge: "novo", description: "Recursos ilimitados", action: %{label: "Fazer upgrade", href: "#", icon: "spark"}}}} style="min-height:640px" />
          <.sb id="sbs2" variant="floating" extra={%{user: @user, footer: "user"}} style="min-height:640px" />
          <.sb id="sbs3" variant="inset" extra={%{version: %{version: "v1.4.2", build: "b88", navigate: "#", status: "warning"}}} style="min-height:640px" />
        </.sbs>
        """,
      "sidebar-collapsed" =>
        ~H"""
        <.sbs>
          <.sb id="sbc1" data-collapsed style="min-height:560px" />
          <.sb id="sbc2" data-collapsed format="tree" nav={@tree} extra={%{user: @user, footer: "user"}} style="min-height:560px" />
          <.sb id="sbc3" data-collapsed variant="floating" extra={%{version: %{version: "v1", build: "2"}}} style="min-height:560px" />
        </.sbs>
        """,
      "sidebar-tree" =>
        ~H"""
        <.sbs>
          <.sb id="sbt1" format="tree" nav={@tree} extra={%{user: @user, footer: "user"}} style="min-height:560px" />
          <.sb id="sbn1" format="nested" nav={@nested} extra={%{user: Map.put(@user, :menu, [%{label: "Perfil", href: "#", icon: "user"}, :separator, %{label: "Sair", icon: "logout", danger: true, href: "#"}]), footer: "user", brand: %{name: "Acme", plan: "Pro", menu: [%{heading: true, label: "Times"}, %{label: "Time A", href: "#"}]}}} style="min-height:560px" />
        </.sbs>
        """,
      "sidebar-rail" =>
        ~H"""
        <.sbs>
          <.sb id="sbr1" format="rail" nav={@rail} variant="sidebar" extra={%{rail_extra: [%{label: "App", icon: "spark", color: "violet", href: "#"}], trial: %{title: "Teste grátis", label: "10 dias", text: "Aproveite", value: 40, action: "Assinar", href: "#"}, user: @user, footer: "user"}} />
          <.sb id="sbr2" format="rail" nav={@rail} variant="floating" data-collapsed />
        </.sbs>
        """,
      "sidebar-items" =>
        ~H"""
        <.sbs>
          <.sidebar id="sbi1" variant="sidebar" current="/b" style="min-height:300px" brand={%{name: "Slots", logo: "S"}}>
            <:item navigate="/a" icon="grid" label="Início" />
            <:item navigate="/b" icon="cart" label="Pedidos" count="3" />
            <:item name="x" icon="file" label="Notas" badge="1" tone="neg" />
            <:view navigate="/v" icon="star" label="Favoritos" count="2" />
          </.sidebar>
        </.sbs>
        """,

      # ---- navbar -------------------------------------------------------------------
      "navbar-variants" =>
        ~H"""
        <div style="background:var(--lu-bg-shell, var(--bg-shell));display:flex;flex-direction:column;gap:6px">
          <.navbar><.navbar_brand name="Signetum" /><.navbar_crumbs variant="plain" items={[%{label: "Início", href: "#"}, %{label: "Pedidos"}]} /><:end><.navbar_bell dot /><.navbar_icon name="help" label="Ajuda" /></:end></.navbar>
          <.navbar variant="float"><.navbar_brand name="Float" logo="F" /><:end><.navbar_bell /></:end></.navbar>
          <.navbar variant="clear"><.navbar_brand name="Clear" /></.navbar>
          <.navbar variant="dense"><.navbar_brand name="Dense" /></.navbar>
          <.navbar size="sm"><.navbar_brand name="Pequena" /><:end><.navbar_bell size="sm" dot /><.navbar_icon name="help" label="Ajuda" size="sm" /></:end></.navbar>
          <.navbar variant="mobile"><.navbar_icon name="menu" label="Menu" /><.navbar_title>Título</.navbar_title><.navbar_icon name="search" label="Buscar" /></.navbar>
          <.navbar>
            <.navbar_brand name="Abas" />
            <:tabs><.navbar_tabs items={[%{label: "Visão", active: true}, %{label: "Faturas", count: "12"}, %{label: "Uso"}]} /></:tabs>
          </.navbar>
        </div>
        """,
      "navbar-pieces" =>
        ~H"""
        <div style="background:var(--lu-bg-page, var(--bg-page));display:flex;flex-direction:column;gap:12px;padding:8px">
          <.navbar>
            <.navbar_workspace name="Orbit Cloud" sub="Finance" />
            <.navbar_chip label="Acme" square="AC" tag="Pro" />
            <.navbar_slash />
            <.navbar_chip label="Projeto" color="#3b82f6" square="PR" />
            <:center><.navbar_links items={[%{label: "Produto", active: true}, %{label: "Preços"}]} /></:center>
            <:end>
              <.navbar_search placeholder="Buscar…" width="220px" />
              <.navbar_sync text="Salvo há 2 min" />
              <.navbar_env label="Produção" /><.navbar_env label="Homolog" tone="warn" /><.navbar_env compact label="ok" />
              <.navbar_lang locales={["PT", "EN"]} current="PT" />
              <.navbar_sep />
              <.navbar_avatars users={[%{name: "Ana Souza"}, %{name: "Bia Lima"}, %{name: "Caio Dias"}, %{name: "Duda Reis"}]} max={3} total={7} />
              <.navbar_bell count={4} />
            </:end>
          </.navbar>
          <.navbar>
            <:center><.navbar_search placeholder="Buscar" wide /></:center>
            <:end><.navbar_search placeholder="Campo" input kbd="" width="180px" /><.navbar_user user={%{name: "Marina Costa"}} /><.navbar_user user={%{name: "Marina Costa"}} variant="ring" /><.navbar_user user={%{name: "Marina Costa"}} variant="named" /></:end>
          </.navbar>
          <.navbar>
            <:end>
              <.navbar_user id="nu1" user={%{name: "Marina Costa", email: "m@x.com"}} variant="named">
                <:menu>
                  <.navbar_menu_head user={%{name: "Marina Costa", email: "m@x.com"}}><:badge>Admin</:badge></.navbar_menu_head>
                  <.navbar_menu_status label="Online"><:action>Mudar</:action></.navbar_menu_status>
                  <.navbar_menu_row label="Idioma"><.navbar_lang locales={["PT", "EN"]} current="EN" /></.navbar_menu_row>
                  <.navbar_menu_item icon="user" navigate="/p" kbd="G P">Perfil</.navbar_menu_item>
                  <.navbar_menu_item icon="logout" danger href="/s" method="delete">Sair</.navbar_menu_item>
                </:menu>
              </.navbar_user>
            </:end>
          </.navbar>
        </div>
        """,

      # ---- landing nav --------------------------------------------------------------
      "landing-nav-variants" =>
        ~H"""
        <.colm>
          <div :for={v <- ~w(default float clear tint dark mobile)} style={"background:var(--lu-bg-page, var(--bg-page));padding:8px;#{if v == "dark", do: "", else: ""}"}>
            <.lnav id={"ln-#{v}"} variant={v} />
          </div>
        </.colm>
        """,
      "landing-nav-responsive" =>
        ~H"""
        <.landing_nav id="ln-r" responsive sticky brand={%{name: "Signetum", icon: "grid"}}>
          <:link label="Produto" navigate="/p" /><:actions><.landing_cta size="lg" icon="arrow-right">Começar</.landing_cta></:actions>
        </.landing_nav>
        """,
      "landing-mega" =>
        ~H"""
        <div style="position:relative;height:420px;width:900px">
          <.landing_mega>
            <.landing_feature icon="file" title="Notas fiscais" description="NF-e e NFC-e" />
            <.landing_feature icon="cart" title="PDV" description="Venda no balcão" />
            <.landing_feature icon="wallet" title="Financeiro" />
            <:side><.landing_mega_side eyebrow="Novo" title="Painel" thumb link_label="Ver">Tudo em um lugar.</.landing_mega_side></:side>
          </.landing_mega>
        </div>
        """,
      "landing-products" =>
        ~H"""
        <div style="position:relative;height:300px;width:900px">
          <.landing_mega variant="cards" columns={3}>
            <.landing_product title="Gestão" name="ERP" logo="grid" link_label="Saiba mais" mock />
            <.landing_product title="Fiscal" tone="tint" accent="#8b5cf6" link_label="Ver" />
            <.landing_product title="Pagamentos" tone="dark" />
            <.landing_product title="Mini" compact />
          </.landing_mega>
        </div>
        """,
      "landing-announcement" =>
        ~H"""
        <.landing_announcement id="la1" eyebrow="Novo" link_label="Saiba mais">Chegou a versão 2.</.landing_announcement>
        """,

      # ---- auth ---------------------------------------------------------------------
      "auth-split-card" =>
        ~H"""
        <.auth_split title="Criar conta" subtitle="Preencha seus dados.">
          <:brand><.icon name="grid" /></:brand>
          <:providers><.oauth_button provider="google" block>Google</.oauth_button><.oauth_button provider="github">GitHub</.oauth_button></:providers>
          <.auth_submit>Entrar</.auth_submit>
          <:aside><b>Aside</b><span>Texto</span></:aside>
          <:footer>Já tem conta? <a href="#">Entrar</a></:footer>
        </.auth_split>
        """,
      "auth-split-art" =>
        ~H"""
        <.auth_split title="Entrar" variant="full" style="height:620px">
          <.auth_alert>Senha incorreta</.auth_alert>
          <.auth_sent>Enviamos o link.</.auth_sent>
          <.auth_submit loading loading_label="Enviando">Entrar</.auth_submit>
          <:art><div style="position:absolute;inset:0;background:var(--lu-bg-sunken, var(--bg-sunken))"></div></:art>
          <:quote author="Marina Costa" role="Gerente" rating={4}>Muito bom.</:quote>
        </.auth_split>
        """,
      "auth-page" =>
        ~H"""
        <div style="height:620px">
          <.auth_page brand="Ledger">
            <h1>Entrar no Ledger</h1>
            <p class="sub">Pedidos, notas e financeiro.</p>
            <div class="or">ou com e-mail</div>
            <a href="#">Esqueci a senha</a>
            <:footer><span>© 2026 Acme</span><span>Termos</span></:footer>
            <:art>
              <.auth_art id="aa1">
                <:chip top="24px" right="24px"><b>R$ 12k</b><small>no mês</small></:chip>
                <:quote author="Marina Costa" role="Gerente" initials="MC" tone="t2">Excelente.</:quote>
              </.auth_art>
            </:art>
          </.auth_page>
        </div>
        """
    }
  end
end
