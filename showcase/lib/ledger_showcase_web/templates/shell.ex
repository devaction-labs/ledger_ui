defmodule LedgerShowcaseWeb.Templates.Shell do
  @moduledoc """
  The frame shared by the template pages: `frame/1` (the full-screen wrapper and the small
  floating back/theme control, which are not part of the template) and `app/1` (the app shell of
  the dashboard and the orders table: icon rail, side panel and top bar).
  """
  use Phoenix.Component
  use LedgerUI
  alias Phoenix.LiveView.JS

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
      <.alert color="success" variant="soft" style="box-shadow:var(--shadow-lg)">
        <.icon name="check-circle" />
        <span>{@notice}</span>
        <button
          type="button"
          class="lu-x"
          aria-label="Dispensar"
          phx-click="dismiss"
          style="margin-left:8px"
        >
          <.icon name="x" size="sm" />
        </button>
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
  The app shell of the canvas templates (`lu-app full`): the rail, the side panel, the top bar
  and `main`. It fills its parent; `main` scrolls and the overlays stay over the viewport.
  """
  def app(assigns) do
    assigns = assign(assigns, :rail_items, @rail)

    ~H"""
    <div class="lu-app full" style="position:relative;height:100%">
      <nav aria-label="Módulos" class="lu-rail">
        <span
          class="logo"
          style="background:var(--inverse);color:var(--bg-panel);font:700 15px var(--font-sans)"
        >
          L
        </span>
        <.main_sidebar_link
          :for={{key, label, icon, to} <- @rail_items}
          label={label}
          active={key == @rail}
          phx-click={to && JS.navigate(to)}
        >
          <.icon name={icon} />
          <span :if={key == "notas"} class="lu-count warn">3</span>
        </.main_sidebar_link>
        <span style="flex:1"></span>
        <.main_sidebar_link label="Ajustes"><.icon name="settings" /></.main_sidebar_link>
      </nav>
      <.sidebar_panel title={@panel}>
        {render_slot(@panel_body)}
      </.sidebar_panel>
      <main>
        <.navbar>
          <.navbar_crumbs variant="plain" items={crumb_items(@crumbs)} />
          <:end>
            <.navbar_search
              placeholder="Buscar pedido, cliente, nota…"
              kbd="Ctrl K"
              input
              width="300px"
              style="height:40px;border-radius:12px"
            />
            <.navbar_bell dot label="Notificações" class="warn" />
            <.avatar initials="AN" color="t1" size="md" />
          </:end>
        </.navbar>
        {render_slot(@inner_block)}
      </main>
      {render_slot(@overlay)}
    </div>
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
