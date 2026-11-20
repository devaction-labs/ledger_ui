defmodule LedgerUI.Components.ViewSwitcher do
  @moduledoc """
  The views of a collection (List, Board, Table...) as a segmented control (`lu-seg`), with an
  optional "+ View" menu to add one and a menu of saved views.

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

  Without `options` and `saved` the root is the `lu-seg` itself; otherwise a `lu-row` wraps it.
  Link views carry `aria-current="page"` when chosen, button views `aria-pressed`; the menu
  triggers carry `aria-haspopup`/`aria-expanded`/`aria-controls` (rendered by `dropdown/1`).
  `data-lu-single` is set on the control when a `value` is chosen.
  """
  use LedgerUI.Component
  import LedgerUI.Components.Dropdown, only: [dropdown: 1, dropdown_item: 1, dropdown_label: 1]

  attr :id, :string, required: true
  attr :value, :any, default: nil
  attr :current, :any, default: nil, doc: "Alias of `value`."
  attr :views, :list, default: []
  attr :options, :list, default: []
  attr :saved, :list, default: []
  attr :saved_value, :any, default: nil
  attr :saved_label, :string, default: "Saved views"
  attr :on_change, :any, default: nil
  attr :on_add, :any, default: nil
  attr :on_saved, :any, default: nil
  attr :target, :any, default: nil
  attr :add_label, :string, default: "View"
  attr :menu_title, :string, default: "Add a new view"
  attr :columns, :integer, default: 2, values: [1, 2]
  attr :placement, :string, default: "bottom-start"
  attr :class, :any, default: nil
  attr :rest, :global

  def view_switcher(assigns) do
    value = assigns.value || assigns.current
    wrapped? = assigns.options != [] or assigns.saved != []

    assigns =
      assigns
      |> assign(:chosen, value)
      |> assign(:views, Enum.map(assigns.views, &view(&1, value, assigns)))
      |> assign(:wrapped?, wrapped?)
      |> assign(:seg_class, cx(["lu-seg", !wrapped? && assigns.class]))
      |> assign(:single, if(value != nil, do: ""))
      |> assign(:menu_style, if(assigns.columns == 2, do: "width:440px", else: "width:260px"))
      |> assign(
        :grid_style,
        "display:grid;grid-template-columns:repeat(#{assigns.columns},minmax(0,1fr));gap:2px"
      )
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
    <div :if={!@wrapped?} id={@id} class={@seg_class} data-lu-single={@single} {@rest}>
      <.view_buttons views={@views} />
    </div>
    <div :if={@wrapped?} id={@id} class={cx(["lu-row", @class])} {@rest}>
      <div class={@seg_class} data-lu-single={@single}>
        <.view_buttons views={@views} />
      </div>
      <.dropdown
        :if={@saved != []}
        id={@id <> "-saved"}
        placement="bottom-start"
        menu_style="width:240px"
      >
        <:toggle :let={t}>
          <button class="lu-btn" type="button" {t}>
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
        menu_style={@menu_style}
      >
        <:toggle :let={t}>
          <button class="lu-btn ghost" type="button" {t}>
            <.icon name="plus" />{@add_label}
          </button>
        </:toggle>
        <.dropdown_label>{@menu_title}</.dropdown_label>
        <div style={@grid_style}>
          <.dropdown_item
            :for={opt <- @options}
            variant="media"
            disabled={opt[:disabled] == true}
            phx-click={opt.js}
          >
            <.icon :if={opt[:icon]} name={opt.icon} boxed />
            <span class="tx">{opt.label}<small :if={opt[:description]}>{opt.description}</small></span>
            <:trailing><.icon :if={opt[:added]} name="check" class="sm ck" /></:trailing>
          </.dropdown_item>
        </div>
      </.dropdown>
    </div>
    """
  end

  attr :views, :list, required: true

  defp view_buttons(assigns) do
    ~H"""
    <%= for v <- @views do %>
      <.link :if={v.link?} class={v.class} aria-current={v.current} {v.link}>
        <.icon :if={v.icon} name={v.icon} size="md" />{v.label}<span :if={v.count != nil} class="n">{v.count}</span>
      </.link>
      <button
        :if={!v.link?}
        class={v.class}
        type="button"
        disabled={v.disabled}
        aria-pressed={v.pressed}
        phx-click={v.js}
      >
        <.icon :if={v.icon} name={v.icon} size="md" />{v.label}<span :if={v.count != nil} class="n">{v.count}</span>
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
      class: cx([on? && "on"]),
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
