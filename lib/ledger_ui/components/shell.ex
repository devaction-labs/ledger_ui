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
  phone's bottom bar of tabs (a `tab_bar/1`, shown only below 768px).

  `full` makes it a full-screen app (no border, radius or shadow, viewport height), `min_height` sets
  the minimum height, and the `:aside` slot is rendered after the page, over the whole shell (a drawer,
  a modal). These replace `app_shell full` with its `:aside`.

  Only utilities. The root is a framed app (`overflow-clip`: a drawer that slides in over it is
  clipped, never scrolled).

  ## Preview

  `variant="preview"` draws the canvas wireframe of a `layout` instead of the app (the docs and the
  showcase use it): `sidebar`, `minimal`, `sideblock`, `horizontal`, `framed` or `rail`. A box with
  grey bars for the menu, the top bar and the cards; `loop` animates the menu collapsing.

      <.shell variant="preview" layout="framed" loop />

  ## Configuration

      config :ledger_ui, :shell, sidebar: :sections, nav: {MyAppWeb.Nav, :items}, footer: :version, version: "v1.4.2"

  Attributes always win over the config.
  """
  use LedgerUI.Component

  import LedgerUI.Components.Sidebar, only: [sidebar: 1]

  @layouts ~w(sidebar minimal sideblock horizontal framed rail)
  attr :id, :string, default: "shell"
  attr :variant, :string, default: "app", values: ~w(app preview)

  attr :layout, :string,
    default: "sidebar",
    values: @layouts,
    doc: "With `preview`: the wireframe."

  attr :loop, :boolean,
    default: false,
    doc: "With `preview`: the menu collapses and expands on its own (the showcase demo)."

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

  attr :full, :boolean,
    default: false,
    doc:
      "Full-screen app: no border, radius or shadow, and a minimum height of the viewport (`100vh`) " <>
        "instead of 520px. The replacement of `app_shell full`."

  attr :min_height, :string,
    default: nil,
    doc:
      ~s|The minimum height of the shell, a CSS length ("900px", "40rem"). Default: 520px, or the viewport with `full`.|

  attr :class, :any, default: nil
  attr :main_class, :any, default: nil
  attr :rest, :global

  slot :aside,
    doc: "Rendered after the page, over the whole shell: a drawer, a modal, a right sidebar."

  slot :brand_mark
  slot :inner_block
  slot :mobile_drawer
  slot :sidebar_footer
  slot :tab_bar
  slot :topbar

  def shell(%{variant: "preview"} = assigns) do
    ~H"""
    <div
      data-part="shell"
      class={
        cx([
          "relative flex h-[190px] overflow-hidden rounded-[14px] bg-shell text-[0px] shadow-[inset_0_0_0_1px_var(--lu-line)]",
          @layout in ["minimal", "horizontal"] && "flex-col",
          @layout == "framed" && "gap-2 p-2",
          @class
        ])
      }
      {@rest}
    >
      <div
        :if={@layout == "rail"}
        data-part="shell-wire-rail"
        class="flex w-[22px] flex-none flex-col items-center gap-1.5 pt-2.5"
      >
        <i data-part="shell-wire-rail-dot" class={wire_dot()}></i><i
          data-part="shell-wire-rail-dot-active"
          class={wire_dot(true)}
        ></i><i
          data-part="shell-wire-rail-dot"
          class={wire_dot()}
        ></i><i data-part="shell-wire-rail-dot" class={wire_dot()}></i>
      </div>
      <.wire_side :if={@layout in ~w(sidebar sideblock framed)} layout={@layout} loop={@loop} />
      <.wire_side :if={@layout == "rail"} layout="rail" loop={@loop} />
      <div
        :if={@layout in ~w(sidebar sideblock framed)}
        data-part="shell-wire-column"
        class="flex min-w-0 flex-1 flex-col"
      >
        <.wire_bar /><.wire_main framed={@layout == "framed"} />
      </div>
      <div :if={@layout == "rail"} data-part="shell-wire-rail-column" class="flex flex-1 flex-col">
        <.wire_bar /><.wire_main />
      </div>
      <.wire_bar :if={@layout == "minimal"} />
      <.wire_bar :if={@layout == "horizontal"} nav />
      <.wire_main :if={@layout in ~w(minimal horizontal)} />
    </div>
    """
  end

  def shell(assigns) do
    assigns = assign(assigns, :style, shell_style(assigns))

    ~H"""
    <div
      id={@id}
      data-part="shell"
      data-full={@full && "true"}
      class={
        cx([
          # `overflow-clip`, never `hidden`: the focus a page drawer takes must not scroll the app
          "flex overflow-clip bg-shell",
          min_height_class(@full, @min_height),
          !@full &&
            "rounded-2xl border border-line shadow-[0_30px_80px_-30px_color-mix(in_oklab,var(--lu-accent-700)_25%,transparent)] dark:shadow-[0_30px_80px_-30px_color-mix(in_oklab,var(--lu-accent-300)_25%,transparent)]",
          @class
        ])
      }
      {style_attr(@style)}
      {Map.delete(@rest, :style)}
    >
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
      <main
        data-part="shell-main"
        class={cx(["flex min-w-0 flex-1 flex-col border-l border-line bg-page p-0", @main_class])}
      >
        {render_slot(@topbar)}
        {render_slot(@inner_block)}
      </main>
      {render_slot(@aside)}
      <div
        :if={@tab_bar != []}
        data-part="tab-bar-slot"
        class="hidden pb-[env(safe-area-inset-bottom)] max-md:fixed max-md:inset-x-0 max-md:bottom-0 max-md:z-40 max-md:block"
      >
        {render_slot(@tab_bar)}
      </div>
    </div>
    """
  end

  defp style_attr(nil), do: []
  defp style_attr(""), do: []
  defp style_attr(style), do: [style: style]

  defp min_height_class(_full, h) when is_binary(h), do: "min-h-(--lu-shell-min)"
  defp min_height_class(true, _), do: "min-h-screen"
  defp min_height_class(false, _), do: "min-h-[520px]"

  # `min_height` goes through a variable; the caller's own `style` is kept
  defp shell_style(%{min_height: nil, rest: rest}), do: rest[:style]

  defp shell_style(%{min_height: h, rest: rest}),
    do: Enum.join(Enum.reject(["--lu-shell-min:#{h}", rest[:style]], &is_nil/1), ";")

  defp wire_dot(on? \\ false),
    do: ["block size-2.5 rounded-[3px]", if(on?, do: "bg-accent-500", else: "bg-line-strong")]

  # one bar of the wireframe: width in `w`, `on` takes the accent
  attr :w, :string, default: nil
  attr :h, :string, default: "h-[7px]"
  attr :on, :boolean, default: false
  attr :class, :string, default: nil

  defp wi(assigns) do
    ~H"""
    <i
      data-part="wire-item"
      class={[
        "block rounded-[4px]",
        @h,
        if(@on, do: "bg-accent-500", else: "bg-line-strong"),
        @w,
        @class
      ]}
    ></i>
    """
  end

  attr :layout, :string, required: true
  attr :loop, :boolean, default: false

  defp wire_side(assigns) do
    ~H"""
    <div
      data-part="shell-wire-side"
      class={
        cx([
          "flex flex-none flex-col gap-1.5 px-2 py-2.5",
          side_look(@layout),
          @loop &&
            "animate-[mo-sbw_6s_cubic-bezier(.4,0,.2,1)_infinite] overflow-hidden [&_i]:min-w-2.5"
        ])
      }
    >
      <.wi w="w-[70%]" /><.wi on /><.wi /><.wi w="w-[80%]" /><.wi w="w-[60%]" />
    </div>
    """
  end

  defp side_look("sideblock"),
    do: "m-2 w-[26%] rounded-[10px] bg-panel shadow-[0_0_0_1px_var(--lu-line)]"

  defp side_look("rail"), do: "w-[26%] border-l border-line"
  defp side_look(_), do: "w-[30%]"

  attr :nav, :boolean, default: false

  defp wire_bar(%{nav: true} = assigns) do
    ~H"""
    <div
      data-part="wire-bar"
      class="flex h-[22px] items-center gap-1.5 border-b border-line bg-page px-2.5"
    >
      <.wi w="w-[8%]" /><.wi w="w-[8%]" on /><.wi w="w-[8%]" /><.wi w="w-[10%]" class="ml-auto" />
    </div>
    """
  end

  defp wire_bar(assigns) do
    ~H"""
    <div
      data-part="wire-bar-simple"
      class="flex h-[22px] items-center gap-1.5 border-b border-line bg-page px-2.5"
    >
      <.wi w="w-[18%]" /><.wi w="w-[10%]" class="ml-auto" />
    </div>
    """
  end

  attr :framed, :boolean, default: false

  defp wire_main(assigns) do
    ~H"""
    <div
      data-part="wire-main"
      class={[
        "flex flex-1 flex-col gap-[7px] bg-page p-2.5",
        @framed && "rounded-[10px] shadow-[0_0_0_1px_var(--lu-line),var(--lu-shadow-sm)]"
      ]}
    >
      <.wi h="h-[9px]" w="w-[40%]" />
      <div data-part="wire-main-cards" class="grid grid-cols-3 gap-1.5">
        <b data-part="wire-main-card" class="block h-[34px] rounded-[6px] bg-sunken"></b><b
          data-part="wire-main-card"
          class="block h-[34px] rounded-[6px] bg-sunken"
        ></b><b data-part="wire-main-card" class="block h-[34px] rounded-[6px] bg-sunken"></b>
      </div>
      <.wi w="w-[80%]" /><.wi w="w-[60%]" />
    </div>
    """
  end
end
