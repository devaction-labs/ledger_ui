defmodule LedgerUI.Components.Tabs do
  @moduledoc """
  Tabs: `line`, `boxed`, `pill`, `text`, `segmented` and `nav` (the `lu-tb` family), plus the
  `classic` underline tabs with count badges (`lu-tabs`), horizontal or vertical.

      <.tabs id="profile" selected="home" on_change="select_tab">
        <:tab name="home">Home</:tab>
        <:tab name="profile" count={4}>Profile</:tab>
        <:panel name="home">...</:panel>
        <:panel name="profile">...</:panel>
      </.tabs>

  Switching happens in the browser through the hook `LedgerUI.Tabs`
  (`priv/static/ledger_ui/hooks/tabs.js`): click, ←/→ (↑/↓ when vertical), Home and End, no
  round trip. A choice made in the browser survives patches; when the server changes
  `selected` the server wins. `on_change` (an event name or a `%JS{}`) is pushed with
  `%{"id" => id, "value" => name, "tab" => name}`, and every selection dispatches a
  bubbling `linea:change` event with `detail: {id, value, tab}`.

  Tabs with `patch`, `navigate` or `href` are links (`aria-current="page"` when selected).

  ## Notes on the markup

  The server renders the ARIA: `role="tablist"` (+ `aria-orientation` when vertical), tab buttons
  with `role="tab"`, `aria-selected`, the roving `tabindex` and `aria-controls` (when there is a
  panel); the hook only updates `aria-selected`/`tabindex`/`on` as the selection changes. `color` has no default (nil renders no `c-*` class, which is the primary look);
  pass `color="primary"` to emit `c-primary`. Panels are `role="tabpanel"` boxes that the hook
  shows/hides; there is no sliding transition in the stylesheet, `transition` is exposed as
  `data-transition` for apps that style it.

  Additive tab attrs: `role` (pass `nil` to drop it) and `count_tone` (`acc`, `neg`...).
  """
  use LedgerUI.Component

  @variants ~w(line boxed pill text segmented nav classic)
  @sizes %{"xs" => "s-xs", "sm" => "s-sm", "md" => nil}

  attr :id, :string, required: true
  attr :selected, :string, default: nil
  attr :variant, :string, default: "line", values: @variants
  attr :size, :string, default: "md", values: ~w(xs sm md)
  attr :color, :string, default: nil, values: [nil, "primary", "neutral"]
  attr :orientation, :string, default: "horizontal", values: ~w(horizontal vertical)
  attr :bordered, :boolean, default: false
  attr :overlap, :boolean, default: false
  attr :grow, :boolean, default: false
  attr :transition, :string, default: "left", values: ~w(left up none)
  attr :on_change, :any, default: nil
  attr :soon_label, :string, default: "Em breve"
  attr :target, :any, default: nil
  attr :list_class, :any, default: nil
  attr :panels_class, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :panel do
    attr :name, :string, required: true
    attr :class, :any
  end

  slot :tab, required: true do
    attr :name, :string
    attr :disabled, :boolean
    attr :count, :any
    attr :overdue, :boolean
    attr :count_tone, :string
    attr :patch, :string
    attr :navigate, :string
    attr :href, :string
    attr :replace, :boolean
    attr :soon, :boolean
    attr :role, :any
    attr :"aria-selected", :string
    attr :title, :string
    attr :id, :string
    attr :class, :any
    attr :"phx-click", :any
    attr :"phx-target", :any
    attr :"phx-value-id", :any
    attr :"phx-value-name", :any
  end

  def tabs(assigns) do
    tabs = assigns.tab
    selected = assigns.selected || tabs |> List.first() |> Map.get(:name)
    classic? = assigns.variant == "classic"

    assigns =
      assigns
      |> assign(:list_classes, list_classes(assigns))
      |> assign(:tabs, Enum.map(tabs, &tab_attrs(&1, assigns, selected, classic?)))
      |> assign(:hook_attrs, hook_attrs(assigns))
      |> assign(:list_rest, Map.merge(list_aria(assigns), assigns.rest))
      |> assign(:vertical_aria, list_aria(assigns))
      |> assign(:vertical, assigns.orientation == "vertical")
      |> assign(:selected_name, selected)
      |> assign(:panels_classes, cx([assigns.panels_class]))

    ~H"""
    <div
      :if={@panel == []}
      id={@id}
      class={@list_classes}
      phx-hook="LedgerUI.Tabs"
      {@hook_attrs}
      {@list_rest}
    >
      <.tab_list_items tabs={@tabs} soon_label={@soon_label} />
    </div>
    <div
      :if={@panel != []}
      id={@id}
      class={cx([@class])}
      phx-hook="LedgerUI.Tabs"
      data-transition={@transition != "left" && @transition}
      {@hook_attrs}
      {@rest}
    >
      <div class={@list_classes} {@vertical_aria}>
        <.tab_list_items tabs={@tabs} soon_label={@soon_label} />
      </div>
      <div class={@panels_classes}>
        <div
          :for={panel <- @panel}
          id={"#{@id}-panel-#{panel.name}"}
          class={panel[:class]}
          role="tabpanel"
          aria-labelledby={"#{@id}-tab-#{panel.name}"}
          hidden={panel.name != @selected_name}
          keep-hidden
        >
          {render_slot(panel)}
        </div>
      </div>
    </div>
    """
  end

  attr :tabs, :list, required: true
  attr :soon_label, :string, required: true

  defp tab_list_items(assigns) do
    ~H"""
    <%= for tab <- @tabs do %>
      <.link :if={tab.link?} class={tab.class} aria-current={tab.current} {tab.rest}>
        {render_slot(tab.slot)}<span :if={tab.count != nil} class={tab.count_class}>{tab.count}</span>
      </.link>
      <button
        :if={!tab.link?}
        id={tab.id}
        class={tab.class}
        type="button"
        disabled={tab.disabled}
        title={tab.title}
        {tab.rest}
      >
        {render_slot(tab.slot)}<span :if={tab.count != nil} class={tab.count_class}>{tab.count}</span>
      </button>
    <% end %>
    """
  end

  defp list_classes(a) do
    classic? = a.variant == "classic"

    cx([
      if(classic?, do: "lu-tabs", else: "lu-tb"),
      !classic? && a.variant,
      !classic? && @sizes[a.size],
      a.color && "c-" <> a.color,
      a.orientation == "vertical" && "vert",
      a.bordered && "bordered",
      a.overlap && "overlap",
      a.grow && "grow",
      a.list_class,
      a.panel == [] && a.class
    ])
  end

  defp hook_attrs(a) do
    %{}
    |> put_if(a.variant == "classic", :"data-lu-single", "")
    |> put_if(is_binary(a.on_change), :"data-on-change", a.on_change)
    |> put_if(match?(%JS{}, a.on_change), :"data-on-change-js", a.on_change)
    |> put_if(a.target, :"data-target", a.target)
  end

  defp list_aria(a) do
    if a.orientation == "vertical",
      do: %{role: "tablist", "aria-orientation": "vertical"},
      else: %{role: "tablist"}
  end

  defp put_if(map, cond, key, value), do: if(cond, do: Map.put(map, key, value), else: map)

  defp tab_attrs(tab, a, selected, classic?) do
    name = tab[:name]
    link? = Enum.any?([:patch, :navigate, :href], &tab[&1])
    on? = name != nil and name == selected
    soon_or_disabled = tab[:disabled] == true or tab[:soon] == true

    role =
      case Map.fetch(tab, :role) do
        {:ok, r} -> r
        :error -> if link?, do: nil, else: "tab"
      end

    drop = [
      :__slot__,
      :inner_block,
      :name,
      :disabled,
      :count,
      :overdue,
      :count_tone,
      :soon,
      :role,
      :title,
      :id,
      :class
    ]

    rest =
      tab
      |> Map.drop(drop)
      |> then(fn r ->
        if link?, do: r, else: Map.drop(r, [:patch, :navigate, :href, :replace])
      end)
      |> then(fn r -> if role, do: Map.put(r, :role, role), else: r end)
      |> then(fn r ->
        if role == "tab" and not link? do
          panel? = Enum.any?(a.panel, &(&1.name == name))

          %{"aria-selected": to_string(on?), tabindex: if(on?, do: "0", else: "-1")}
          |> put_if(panel?, :"aria-controls", "#{a.id}-panel-#{name}")
          |> Map.merge(r)
        else
          r
        end
      end)

    %{
      slot: [tab],
      link?: link?,
      id: name && "#{a.id}-tab-#{name}",
      class: cx([classic? && "lu-tab", on? && "on", soon_or_disabled && "disabled", tab[:class]]),
      count: tab[:count],
      count_class: cx(["lu-badge", tab[:count_tone] || (tab[:overdue] && "neg")]),
      disabled: soon_or_disabled,
      title: tab[:title] || (tab[:soon] && a.soon_label) || nil,
      current: link? && on? && "page",
      rest: rest
    }
  end
end
