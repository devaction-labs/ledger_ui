defmodule LedgerUI.Components.ViewSwitcher do
  @moduledoc """
  The views of a collection (List, Board, Table...) as a segmented control, with an
  optional "+ View" menu to add one and a menu of saved views. Styled only with Tailwind
  utilities; every part carries `data-part` (`view-switcher`, `view-switcher-seg`,
  `view-switcher-view`, `view-switcher-count`, `view-switcher-saved`, `view-switcher-add`).

      <.view_switcher
        id="invoice-views"
        value={@view}
        on_change="set_view"
        on_add="add_view"
        views={[%{label: "List", value: "list", icon: "list"}, %{label: "Board", value: "board", icon: "kanban"}]}
        options={[%{label: "Table", value: "table", icon: "table", description: "Table view"}]}
      />

  `views` are maps with `:label`, `:value` and optionally `:icon`, `:count`, `:disabled`,
  `:patch`/`:navigate`/`:href` (a link, `aria-current="page"` when chosen); plain strings
  stand for `%{label: s, value: s}`. A tab sends `on_change` with `%{"view" => value}`.

  `options` are the views the menu offers (`:label`, `:value`, `:icon`, `:description`, `:added`,
  `:disabled`); choosing one sends `on_add` with `%{"view" => value}`. The menu is a
  `dropdown/1` with id `"\#{id}-add"`. `saved` (same shape) adds a menu of saved views
  (`on_saved`, `saved_value`, `saved_label`).

  Without `options` and `saved` the root is the segmented control itself; otherwise a row wraps
  it. The chosen view is read from `aria-current="page"` (links) or `aria-pressed` (buttons); the menu
  triggers carry `aria-haspopup`/`aria-expanded`/`aria-controls` (rendered by `dropdown/1`).
  `data-lu-single` is set on the control when a `value` is chosen (the legacy script then moves
  `aria-pressed` on click, before the server answers).
  """
  use LedgerUI.Component
  import LedgerUI.Components.Dropdown, only: [dropdown: 1, dropdown_item: 1, dropdown_label: 1]

  @seg "inline-flex gap-0.5 rounded-md bg-sunken p-[3px]"
  @view_base "h-7 cursor-pointer items-center gap-1.5 rounded-[7px] border-0 px-3 text-[13.5px] font-medium text-muted no-underline transition-[color,background] duration-150 " <>
               "hover:text-ink focus-visible:outline-none focus-visible:shadow-[0_0_0_3px_var(--lu-focus)]"
  @view_on "bg-transparent aria-pressed:bg-panel aria-pressed:text-ink aria-pressed:shadow-[var(--lu-shadow-xs),0_0_0_1px_var(--lu-line)] " <>
             "aria-[current=page]:bg-panel aria-[current=page]:text-ink aria-[current=page]:shadow-[var(--lu-shadow-xs),0_0_0_1px_var(--lu-line)]"
  # `loop`: the highlight is the sliding `before` of the control, not the pressed button
  @view_loop "relative bg-transparent"
  # the highlight of the demo: one third (1/n) wide, sliding over the views every 6s
  @loop_seg "relative before:absolute before:top-[3px] before:bottom-[3px] before:left-[3px] before:w-[calc((100%-6px-2px*(var(--n)-1))/var(--n))] " <>
              "before:rounded-[7px] before:bg-panel before:shadow-[var(--lu-shadow-xs),0_0_0_1px_var(--lu-line)] before:content-[''] " <>
              "before:animate-[lu-segslide_6s_cubic-bezier(.4,0,.2,1)_infinite]"
  @count "inline-grid h-[18px] min-w-[18px] place-items-center rounded-[5px] bg-selected px-1 text-[11.5px] text-ink-2 tabular-nums"

  # the toolbar buttons of the menus (the canvas `default` and `ghost` looks)
  @btn "inline-flex h-9 cursor-pointer items-center justify-center gap-2 rounded-md border px-3.5 text-sm font-medium leading-none whitespace-nowrap " <>
         "no-underline transition-[background,border-color,box-shadow,transform] duration-150 active:translate-y-[.5px] " <>
         "focus-visible:outline-none focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] [&_svg]:size-4"
  @btn_default "border-line-strong bg-panel text-ink shadow-xs hover:bg-hover"
  @btn_ghost "border-transparent bg-transparent text-ink-2 shadow-none hover:bg-hover hover:text-ink"

  attr :id, :string, required: true
  attr :value, :any, default: nil
  attr :current, :any, default: nil, doc: "Alias of `value`."
  attr :views, :list, default: []
  attr :options, :list, default: []
  attr :saved, :list, default: []
  attr :saved_value, :any, default: nil
  attr :saved_label, :string, default: nil
  attr :on_change, :any, default: nil
  attr :on_add, :any, default: nil
  attr :on_saved, :any, default: nil
  attr :target, :any, default: nil
  attr :add_label, :string, default: nil
  attr :menu_title, :string, default: nil

  attr :stretch, :boolean,
    default: false,
    doc: "The views share the width of the control equally (each `flex-1`, content centered)."

  attr :loop, :boolean,
    default: false,
    doc:
      "The canvas demo animation: a highlight slides over the views, 6s per round. It implies `stretch`."

  attr :columns, :integer, default: 2, values: [1, 2]
  attr :placement, :string, default: "bottom-start"
  attr :class, :any, default: nil
  attr :rest, :global

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def view_switcher(assigns) do
    assigns =
      I18n.texts(assigns,
        saved_label: "view_switcher.saved",
        add_label: "view_switcher.add",
        menu_title: "view_switcher.new"
      )

    value = assigns.value || assigns.current
    wrapped? = assigns.options != [] or assigns.saved != []

    assigns =
      assigns
      |> assign(:chosen, value)
      |> assign(:views, Enum.map(assigns.views, &view(&1, value, assigns)))
      |> assign(:wrapped?, wrapped?)
      |> assign(
        :seg_class,
        cx([
          @seg,
          assigns.loop && @loop_seg,
          !wrapped? && assigns.class
        ])
      )
      |> assign(:single, if(value != nil, do: ""))
      |> assign(:seg_style, assigns.loop && "--n:#{length(assigns.views)}")
      |> assign(:menu_class, if(assigns.columns == 2, do: "w-[440px]", else: "w-[260px]"))
      |> assign(:grid_class, [
        "grid gap-0.5",
        if(assigns.columns == 2, do: "grid-cols-2", else: "grid-cols-1")
      ])
      |> assign(:btn_default, [@btn, @btn_default])
      |> assign(:btn_ghost, [@btn, @btn_ghost])
      |> assign(:view_class, [
        if(assigns.stretch or assigns.loop,
          do: "flex flex-1 justify-center",
          else: "inline-flex"
        ),
        @view_base,
        if(assigns.loop, do: @view_loop, else: @view_on)
      ])
      |> assign(:count_class, @count)
      |> assign(:row_class, cx(["flex flex-wrap items-center gap-2.5", assigns.class]))
      |> assign(
        :options,
        Enum.map(
          assigns.options,
          &Map.put(&1, :js, push(assigns.on_add, &1.value, assigns.target))
        )
      )
      |> assign(:saved, Enum.map(assigns.saved, &saved(&1, assigns)))
      |> assign(:saved_current, saved_current(assigns))

    ~H"""
    <div
      :if={!@wrapped?}
      id={@id}
      data-part="view-switcher-seg"
      class={@seg_class}
      style={@seg_style}
      data-lu-single={@single}
      {@rest}
    >
      <.view_buttons views={@views} view_class={@view_class} count_class={@count_class} />
    </div>
    <div :if={@wrapped?} id={@id} data-part="view-switcher" class={@row_class} {@rest}>
      <div
        data-part="view-switcher-seg"
        class={@seg_class}
        style={@seg_style}
        data-lu-single={@single}
      >
        <.view_buttons views={@views} view_class={@view_class} count_class={@count_class} />
      </div>
      <.dropdown
        :if={@saved != []}
        id={@id <> "-saved"}
        placement="bottom-start"
        class="w-60"
      >
        <:toggle :let={t}>
          <button data-part="view-switcher-saved" class={@btn_default} type="button" {t}>
            <.icon name="folder" />{@saved_current}<.icon name="chevron-down" />
          </button>
        </:toggle>
        <.dropdown_item :for={s <- @saved} selected={s.selected} phx-click={s.js}>
          <:icon><.icon name="folder" /></:icon>
          {s.label}
        </.dropdown_item>
      </.dropdown>
      <.dropdown
        :if={@options != []}
        id={@id <> "-add"}
        placement={@placement}
        class={@menu_class}
      >
        <:toggle :let={t}>
          <button data-part="view-switcher-add" class={@btn_ghost} type="button" {t}>
            <.icon name="plus" />{@add_label}
          </button>
        </:toggle>
        <.dropdown_label>{@menu_title}</.dropdown_label>
        <div data-part="view-switcher-grid" class={@grid_class}>
          <.dropdown_item
            :for={opt <- @options}
            variant="media"
            disabled={opt[:disabled] == true}
            phx-click={opt.js}
            description={opt[:description]}
          >
            <:icon><.icon :if={opt[:icon]} name={opt.icon} boxed /></:icon>
            {opt.label}
            <:trailing><.icon :if={opt[:added]} name="check" size="sm" /></:trailing>
          </.dropdown_item>
        </div>
      </.dropdown>
    </div>
    """
  end

  attr :views, :list, required: true
  attr :view_class, :string, required: true
  attr :count_class, :string, required: true

  defp view_buttons(assigns) do
    ~H"""
    <%= for v <- @views do %>
      <.link
        :if={v.link?}
        data-part="view-switcher-view"
        class={@view_class}
        aria-current={v.current}
        {v.link}
      >
        <.icon :if={v.icon} name={v.icon} size="md" />{v.label}<span
          :if={v.count != nil}
          data-part="view-switcher-count"
          class={@count_class}
        >{v.count}</span>
      </.link>
      <button
        :if={!v.link?}
        data-part="view-switcher-view"
        class={@view_class}
        type="button"
        disabled={v.disabled}
        aria-pressed={v.pressed}
        phx-click={v.js}
      >
        <.icon :if={v.icon} name={v.icon} size="md" />{v.label}<span
          :if={v.count != nil}
          data-part="view-switcher-count"
          class={@count_class}
        >{v.count}</span>
      </button>
    <% end %>
    """
  end

  defp view(v, value, a) when is_binary(v), do: view(%{label: v, value: v}, value, a)

  defp view(v, value, a) do
    link = Map.take(v, [:patch, :navigate, :href])
    on? = v.value == value

    %{
      label: v.label,
      icon: v[:icon],
      count: v[:count],
      disabled: v[:disabled] == true,
      link: link,
      link?: link != %{},
      current: on? && "page",
      pressed: to_string(on?),
      js: push(a.on_change, v.value, a.target)
    }
  end

  defp saved(s, a) when is_binary(s), do: saved(%{label: s, value: s}, a)

  defp saved(s, a) do
    %{
      label: s.label,
      selected: s.value == a.saved_value,
      js: push(a.on_saved, s.value, a.target)
    }
  end

  defp saved_current(a) do
    Enum.find_value(a.saved, a.saved_label, fn s ->
      s = if is_binary(s), do: %{label: s, value: s}, else: s
      s.value == a.saved_value && s.label
    end)
  end

  defp push(nil, _value, _target), do: nil
  defp push(%JS{} = js, _value, _target), do: js

  defp push(event, value, target) do
    opts = [value: %{view: value}]
    opts = if target, do: Keyword.put(opts, :target, target), else: opts
    JS.push(event, opts)
  end
end
