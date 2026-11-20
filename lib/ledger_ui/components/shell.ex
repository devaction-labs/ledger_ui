defmodule LedgerUI.Components.Shell do
  @moduledoc """
  The framed shell of the app with the side menu of `sidebar/1`: the menu on the grey frame and the
  page beside it. It is fed by one list of items, so changing `sidebar` changes the menu and not the
  items.

      <.shell nav={MyAppWeb.Nav.items(assigns)} sidebar="rail" current={@current_path}
        brand={%{name: "Ledger", logo: "S"}} user={@user}>
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

  ## Preview

  `variant="preview"` draws the canvas wireframe of a `layout` instead of the app (the docs and the
  showcase use it): `sidebar`, `minimal`, `sideblock`, `horizontal`, `framed` or `rail`. A box with
  grey bars for the menu, the top bar and the cards; `class` takes the animation (`m-collapse`).

      <.shell variant="preview" layout="framed" class="m-collapse" />

  ## Configuration

      config :ledger_ui, :shell, sidebar: :sections, nav: {MyAppWeb.Nav, :items}, footer: :version, version: "v1.4.2"

  Attributes always win over the config.
  """
  use LedgerUI.Component

  import LedgerUI.Components.Sidebar, only: [sidebar: 1]

  @layouts ~w(sidebar minimal sideblock horizontal framed rail)
  @wire_class %{
    "sidebar" => "sidebar",
    "minimal" => "col",
    "sideblock" => "sideblock",
    "horizontal" => "col",
    "framed" => "framed",
    "rail" => nil
  }

  attr :id, :string, default: "shell"
  attr :variant, :string, default: "app", values: ~w(app preview)

  attr :layout, :string,
    default: "sidebar",
    values: @layouts,
    doc: "With `preview`: the wireframe."

  attr :flat, :boolean,
    default: false,
    doc: "The items of the menu without the column around them."

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
  slot :inner_block
  slot :mobile_drawer
  slot :sidebar_footer
  slot :tab_bar
  slot :topbar

  def shell(%{variant: "preview"} = assigns) do
    assigns = assign(assigns, :wire, @wire_class[assigns.layout])

    ~H"""
    <div data-part="shell" class={cx(["lu-wire", @wire, @class])} {@rest}>
      <div :if={@layout == "rail"} class="rail"><i></i><i class="on"></i><i></i><i></i></div>
      <.wire_side :if={@layout in ~w(sidebar sideblock framed)} />
      <.wire_side :if={@layout == "rail"} style="width:26%;border-left:1px solid var(--line)" />
      <div
        :if={@layout in ~w(sidebar sideblock framed)}
        style="flex:1;display:flex;flex-direction:column;min-width:0"
      >
        <.wire_bar /><.wire_main />
      </div>
      <div :if={@layout == "rail"} style="flex:1;display:flex;flex-direction:column">
        <.wire_bar /><.wire_main />
      </div>
      <.wire_bar :if={@layout == "minimal"} />
      <.wire_bar :if={@layout == "horizontal"} nav />
      <.wire_main :if={@layout in ~w(minimal horizontal)} />
    </div>
    """
  end

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
        flat={@flat}
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

  attr :style, :string, default: nil

  defp wire_side(assigns) do
    ~H"""
    <div class="sb" {if @style, do: [style: @style], else: []}>
      <i style="width:70%"></i><i class="on"></i><i></i><i style="width:80%"></i><i style="width:60%"></i>
    </div>
    """
  end

  attr :nav, :boolean, default: false

  defp wire_bar(%{nav: true} = assigns) do
    ~H"""
    <div class="tb">
      <i style="width:8%"></i><i style="width:8%;background:var(--teal-500)"></i><i style="width:8%"></i><i style="width:10%;margin-left:auto"></i>
    </div>
    """
  end

  defp wire_bar(assigns) do
    ~H"""
    <div class="tb"><i></i><i style="width:10%;margin-left:auto"></i></div>
    """
  end

  defp wire_main(assigns) do
    ~H"""
    <div class="mn">
      <i style="width:40%;height:9px"></i>
      <div class="cards"><b></b><b></b><b></b></div>
      <i style="width:80%"></i><i style="width:60%"></i>
    </div>
    """
  end
end
