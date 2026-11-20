defmodule LedgerUI.Components.Shell do
  @moduledoc """
  The framed shell of the app with the side menu of `sidebar/1`: the menu on the grey frame and the
  page beside it. It is fed by one list of items, so changing `sidebar` changes the menu and not the
  items.

      <.shell nav={MyAppWeb.Nav.items(assigns)} sidebar="rail" current={@current_path}
        brand={%{name: "Linea", logo: "S"}} user={@user}>
        <:topbar><.navbar>...</.navbar></:topbar>
        ...the page...
      </.shell>

  `nav`, `brand`, `user`, `plan`, `trial`, `rail_extra`, `footer`, `version`, `match`,
  `persist_groups`, `collapsible` and `collapsed` are those of `LedgerUI.Components.Sidebar.sidebar/1`,
  which documents the data of the items. `sidebar` is the format (`sections`, `rail`, `tree` or
  `nested`).

  The `:topbar` slot is the row at the top of the page (a `navbar/1`), the `:tab_bar` slot is the
  phone's bottom bar of tabs (a `tab_bar/1`, shown only below 768px by the `LedgerUI.AppShell`
  hook stylesheet).

  ## Configuration

      config :ledger_ui, :shell, sidebar: :sections, nav: {MyAppWeb.Nav, :items}, footer: :version, version: "v1.4.2"

  Attributes always win over the config.
  """
  use LedgerUI.Component

  import LedgerUI.Components.Sidebar, only: [sidebar: 1]

  attr :id, :string, default: "shell"
  attr :sidebar, :any, default: nil
  attr :nav, :list, default: nil
  attr :current, :string, default: nil
  attr :brand, :map, default: nil
  attr :user, :map, default: nil
  attr :footer, :any, default: nil
  attr :show_user, :boolean, default: nil
  attr :version, :any, default: nil
  attr :match, :string, default: "exact", values: ~w(exact prefix)
  attr :persist_groups, :boolean, default: false
  attr :plan, :map, default: nil
  attr :trial, :map, default: nil
  attr :rail_extra, :list, default: []
  attr :collapsible, :boolean, default: true
  attr :collapsed, :boolean, default: false
  attr :class, :any, default: nil
  attr :main_class, :any, default: nil
  attr :rest, :global

  slot :brand_mark
  slot :inner_block, required: true
  slot :mobile_drawer
  slot :sidebar_footer
  slot :tab_bar
  slot :topbar

  def shell(assigns) do
    ~H"""
    <div id={@id} data-part="shell" class={cx(["lu-app", @class])} {@rest}>
      <.sidebar
        id={"#{@id}-menu"}
        format={@sidebar}
        nav={@nav}
        current={@current}
        brand={@brand}
        user={@user}
        footer={@footer}
        show_user={@show_user}
        version={@version}
        match={@match}
        persist_groups={@persist_groups}
        plan={@plan}
        trial={@trial}
        rail_extra={@rail_extra}
        collapsible={@collapsible}
        collapsed={@collapsed}
        variant="sidebar"
      >
        <:brand_mark :if={@brand_mark != []}>{render_slot(@brand_mark)}</:brand_mark>
        <:mobile_drawer :if={@mobile_drawer != []}>{render_slot(@mobile_drawer)}</:mobile_drawer>
        <:sidebar_footer :if={@sidebar_footer != []}>{render_slot(@sidebar_footer)}</:sidebar_footer>
      </.sidebar>
      <main class={@main_class}>
        {render_slot(@topbar)}
        {render_slot(@inner_block)}
      </main>
      <div :if={@tab_bar != []} class="lu-tabbar-slot">{render_slot(@tab_bar)}</div>
    </div>
    """
  end
end
