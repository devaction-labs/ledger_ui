defmodule LedgerShowcaseWeb.Templates.Shell do
  @moduledoc """
  The frame shared by the template pages: `frame/1` (the full-screen wrapper and the small
  floating back/theme control, which are not part of the template) and `app/1` (the app shell of
  the dashboard and the orders table: icon rail, side panel and top bar).
  """
  use Phoenix.Component
  use LedgerUI
  alias LedgerUI.Components.AppShell

  attr :slug, :string, required: true
  attr :palette, :string, default: nil, doc: "`data-palette` of the template (`?palette=`)."
  attr :scroll, :boolean, default: false, doc: "A page taller than the viewport (it scrolls)."
  attr :notice, :string, default: nil, doc: "A one-line result of an action, dismissible."
  slot :inner_block, required: true

  @doc """
  The template page: a full-viewport box holding the template (`data-template`), and, outside of it,
  the control that goes back to the index and flips the theme (the showcase's own `#th` button).
  """
  def frame(assigns) do
    ~H"""
    <div
      id="tpl"
      data-template={@slug}
      data-palette={@palette}
      class={["tpl-root", @scroll && "tpl-scroll"]}
    >
      {render_slot(@inner_block)}
    </div>
    <div :if={@notice} class="tpl-notice" id="tpl-notice">
      <.alert
        color="success"
        variant="soft"
        class="shadow-lg"
        dismissible
        on_dismiss="dismiss"
        close_label="Dispensar"
      >
        <:icon><.icon name="check-circle" /></:icon>
        {@notice}
      </.alert>
    </div>
    <div class="tpl-chrome" id="tpl-chrome">
      <.link navigate="/templates" class="tpl-btn" aria-label="Todos os templates" title="Templates">
        <.icon name="arrow-left" />
      </.link>
      <button type="button" id="th" class="tpl-btn" aria-label="Alternar tema" title="Alternar tema">
        <.icon name="moon" />
      </button>
    </div>
    """
  end

  @rail [
    {"inicio", "Início", "home", "/templates/dashboard"},
    {"pedidos", "Pedidos", "cart", "/templates/tabela"},
    {"clientes", "Clientes", "users", nil},
    {"estoque", "Estoque", "package", nil},
    {"financeiro", "Financeiro", "wallet", nil},
    {"notas", "Notas fiscais", "invoice", nil},
    {"relatorios", "Relatórios", "pie", nil}
  ]

  attr :rail, :string, required: true, doc: "The active module of the rail (`inicio`, `pedidos`)."
  attr :panel, :string, required: true, doc: "Title of the side panel."
  attr :crumbs, :list, required: true, doc: "The trail after the company; the last is the page."
  slot :panel_body, required: true
  slot :inner_block, required: true

  slot :overlay,
    doc: "Rendered after `main`, over the whole app (the drawer, the modal)."

  @doc """
  The app shell of the canvas templates (`app_shell full`): the rail, the side panel, the top bar
  and `main`. It fills its parent; `main` scrolls and the overlays stay over the viewport.
  """
  def app(assigns) do
    assigns = assign(assigns, :rail_items, @rail)

    ~H"""
    <.app_shell
      id="tpl-app"
      full
      persist={false}
      header_sticky={false}
      header_blur={false}
      class="relative h-full"
      main_class="min-h-0 overflow-auto"
    >
      <:sidebar>
        <nav
          aria-label="Módulos"
          data-part="main-sidebar"
          class="flex w-16 flex-none flex-col items-center gap-1.5 py-3"
        >
          <span class={AppShell.rail_logo_classes()}>
            <b class="font-sans text-[15px] font-bold">L</b>
          </span>
          <.main_sidebar_link
            :for={{key, label, icon, to} <- @rail_items}
            label={label}
            active={key == @rail}
            navigate={to}
          >
            <.icon name={icon} />
            <span
              :if={key == "notas"}
              class="absolute right-px top-0.5 inline-grid h-4 min-w-4 place-items-center rounded-[5px] bg-warn px-[5px] text-[10px] font-semibold tabular-nums text-[#1b1300]"
            >
              3
            </span>
          </.main_sidebar_link>
          <span class="flex-1"></span>
          <.main_sidebar_link label="Ajustes"><.icon name="settings" /></.main_sidebar_link>
        </nav>
        <.sidebar_panel title={@panel}>
          {render_slot(@panel_body)}
        </.sidebar_panel>
      </:sidebar>
      <:header>
        <.navbar>
          <.navbar_crumbs variant="plain" items={crumb_items(@crumbs)} />
          <:end>
            <.navbar_search
              placeholder="Buscar pedido, cliente, nota…"
              kbd="Ctrl K"
              input
              width="300px"
              class="h-10 rounded-[12px]"
            />
            <.navbar_bell dot label="Notificações" class="after:bg-warn!" />
            <.avatar initials="AN" color="t1" size="md" />
          </:end>
        </.navbar>
      </:header>
      {render_slot(@inner_block)}
      <:aside>{render_slot(@overlay)}</:aside>
    </.app_shell>
    """
  end

  @doc "The class of a small mono section title (page layout of the templates)."
  def sec_h,
    do: "font-mono text-[11.5px] leading-none font-semibold tracking-[.08em] text-muted uppercase"

  attr :class, :any, default: nil
  slot :inner_block, required: true

  @doc "A small title over a group of links of the side panel."
  def nav_heading(assigns) do
    ~H"""
    <div class={[AppShell.nav_h_classes(), @class]}>
      <.icon name="chevron-down" size="sm" />{render_slot(@inner_block)}
    </div>
    """
  end

  slot :inner_block, required: true

  @doc "The count (or the key hint) at the end of a link of the side panel."
  def nav_count(assigns) do
    ~H"""
    <span class={AppShell.nav_r_classes()}>{render_slot(@inner_block)}</span>
    """
  end

  defp crumb_items(crumbs) do
    items = ["Bom Preço Distribuidora" | crumbs]
    last = length(items) - 1

    items
    |> Enum.with_index()
    |> Enum.map(fn {label, i} ->
      if i == last, do: %{label: label}, else: %{label: label, href: "#"}
    end)
  end
end
