defmodule LedgerUI.Components.Tabs do
  @moduledoc """
  Tabs: `line`, `boxed`, `pill`, `text`, `segmented` and `nav`, plus the `classic` underline tabs
  with count badges, horizontal or vertical. Styled only with Tailwind utilities; the selected tab
  carries `data-state="on"` (and `aria-selected`) and the utilities read it (`data-[state=on]:text-ink`...).

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
  bubbling `ledger:change` event with `detail: {id, value, tab}`.

  Tabs with `patch`, `navigate` or `href` are links (`aria-current="page"` when selected).

  ## Notes on the markup

  The server renders the ARIA: `role="tablist"` (+ `aria-orientation` when vertical), tab buttons
  with `role="tab"`, `aria-selected`, the roving `tabindex` and `aria-controls` (when there is a
  panel); the hook only updates `aria-selected`/`tabindex`/`data-state` as the selection changes.
  `color` (`primary`, the default look, or `neutral`) tints the `pill` and `text` variants. Panels
  are `role="tabpanel"` boxes that the hook shows/hides; there is no sliding transition,
  `transition` is exposed as `data-transition` for apps that style it. `bordered`, `overlap` and
  `grow` are kept for compatibility and have no visual effect.

  Every part carries `data-part`: `tabs`, `tabs-list`, `tab`, `tab-count`, `tabs-panels`, `tabs-panel`.

  Additive tab attrs: `role` (pass `nil` to drop it) and `count_tone` (`acc`, `neg`...).
  """
  use LedgerUI.Component
  import LedgerUI.Components.Badge, only: [badge: 1]

  @variants ~w(line boxed pill text segmented nav classic)
  @sizes ~w(xs sm md)

  @underline "data-[state=on]:after:absolute data-[state=on]:after:rounded-[2px] data-[state=on]:after:bg-ink data-[state=on]:after:content-['']"

  # the list: layout and frame per variant (horizontal / vertical)
  @lists %{
    "line" => {"gap-[22px] border-b border-line", "border-l border-line"},
    "boxed" =>
      {"inline-flex gap-0.5 rounded-md bg-sunken p-[3px]",
       "inline-flex rounded-md bg-sunken p-[3px] border-l border-line"},
    "pill" => {"gap-1", "border-l border-line"},
    "text" => {"gap-[18px]", "border-l border-line"},
    "segmented" =>
      {"inline-flex gap-0 overflow-hidden rounded-md border border-line-strong",
       "inline-flex overflow-hidden rounded-md border border-line-strong border-b-0 border-l-line"},
    "nav" => {"gap-1", "border-l border-line"}
  }

  @heights %{
    "line" => "h-10",
    "text" => "h-10",
    "boxed" => "h-[30px]",
    "pill" => "h-8",
    "segmented" => "h-8",
    "nav" => "h-8"
  }

  @pads %{
    "line" => "px-0",
    "text" => "px-0",
    "boxed" => "px-3",
    "pill" => "px-3.5",
    "segmented" => "px-3.5",
    "nav" => "px-2.5"
  }

  @radii %{"boxed" => "rounded-[7px]", "pill" => "rounded-[9px]", "nav" => "rounded-[8px]"}

  # what the selected tab looks like
  @on %{
    "line" => "data-[state=on]:text-ink",
    "text" => "data-[state=on]:text-accent-content",
    "boxed" =>
      "data-[state=on]:bg-panel data-[state=on]:text-ink data-[state=on]:shadow-[var(--lu-shadow-xs),0_0_0_1px_var(--lu-line)]",
    "pill" => "data-[state=on]:bg-accent data-[state=on]:text-accent-foreground",
    "segmented" => "data-[state=on]:bg-sunken data-[state=on]:text-ink",
    "nav" => "data-[state=on]:bg-selected data-[state=on]:text-ink"
  }

  @on_neutral %{
    "pill" => "data-[state=on]:bg-ink data-[state=on]:text-on-inverse",
    "text" => "data-[state=on]:text-ink"
  }

  @count_tones %{
    "acc" => "primary",
    "pos" => "success",
    "neg" => "error",
    "warn" => "warning",
    "info" => "info",
    "lime" => "lime"
  }

  attr :id, :string, required: true
  attr :selected, :string, default: nil
  attr :variant, :string, default: "line", values: @variants
  attr :size, :string, default: "md", values: @sizes
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
    attr :name, :string,
      doc: "Names the tab for `selected` and its panel (the position when missing)."

    attr :active, :boolean,
      doc: "The tab that is selected at first, when `selected` is not given."

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
    tabs =
      assigns.tab
      |> Enum.with_index()
      |> Enum.map(fn {tab, i} -> Map.put_new(tab, :name, "#{i}") end)

    selected =
      assigns.selected ||
        Enum.find_value(tabs, &(&1[:active] && &1.name)) || tabs |> List.first() |> Map.get(:name)

    classic? = assigns.variant == "classic"

    assigns =
      assigns
      |> assign(:list_classes, list_classes(assigns))
      |> assign(:tabs, Enum.map(tabs, &tab_attrs(&1, assigns, selected)))
      |> assign(:count_size, if(classic?, do: "sm", else: "md"))
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
      data-part="tabs-list"
      class={@list_classes}
      phx-hook="LedgerUI.Tabs"
      {@hook_attrs}
      {@list_rest}
    >
      <.tab_list_items tabs={@tabs} soon_label={@soon_label} count_size={@count_size} />
    </div>
    <div
      :if={@panel != []}
      id={@id}
      data-part="tabs"
      class={cx([@class])}
      phx-hook="LedgerUI.Tabs"
      data-transition={@transition != "left" && @transition}
      {@hook_attrs}
      {@rest}
    >
      <div data-part="tabs-list" class={@list_classes} {@vertical_aria}>
        <.tab_list_items tabs={@tabs} soon_label={@soon_label} count_size={@count_size} />
      </div>
      <div data-part="tabs-panels" class={@panels_classes}>
        <div
          :for={panel <- @panel}
          id={"#{@id}-panel-#{panel.name}"}
          data-part="tabs-panel"
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
  attr :count_size, :string, required: true

  defp tab_list_items(assigns) do
    ~H"""
    <%= for tab <- @tabs do %>
      <.link
        :if={tab.link?}
        data-part="tab"
        data-state={tab.on? && "on"}
        class={tab.class}
        aria-current={tab.current}
        {tab.rest}
      >
        {render_slot(tab.slot)}
        <.badge
          :if={tab.count != nil}
          data-part="tab-count"
          canvas
          size={@count_size}
          color={tab.count_color}
        >
          {tab.count}
        </.badge>
      </.link>
      <button
        :if={!tab.link?}
        id={tab.id}
        data-part="tab"
        data-state={tab.on? && "on"}
        class={tab.class}
        type="button"
        disabled={tab.disabled}
        title={tab.title}
        {tab.rest}
      >
        {render_slot(tab.slot)}
        <.badge
          :if={tab.count != nil}
          data-part="tab-count"
          canvas
          size={@count_size}
          color={tab.count_color}
        >
          {tab.count}
        </.badge>
      </button>
    <% end %>
    """
  end

  defp list_classes(a) do
    vertical? = a.orientation == "vertical"

    cond do
      a.variant == "classic" ->
        cx(["flex gap-[22px] border-b border-line", a.list_class, a.panel == [] && a.class])

      true ->
        {horizontal, vertical} = @lists[a.variant]

        cx([
          "relative flex",
          if(vertical?, do: ["flex-col w-[180px] gap-0", vertical], else: horizontal),
          a.list_class,
          a.panel == [] && a.class
        ])
    end
  end

  # one tab: font, dimensions per variant and size, the selected look
  defp tab_classes(a) do
    base =
      "relative inline-flex cursor-pointer items-center gap-[7px] border-0 bg-transparent font-medium text-muted"

    # a link tab shows a focus ring on a 6px radius
    link_focus =
      "[&:is(a)]:no-underline [&:is(a)]:focus-visible:rounded-[6px] [&:is(a)]:focus-visible:outline-0 [&:is(a)]:focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] [&:is(a):not([data-state=on])]:hover:text-ink"

    cond do
      a.variant == "classic" ->
        [
          base,
          "h-10 p-0 text-[14px] hover:text-ink focus-visible:outline-none focus-visible:shadow-[0_0_0_3px_var(--lu-focus)]",
          "data-[state=on]:text-ink",
          @underline,
          "data-[state=on]:after:inset-x-0 data-[state=on]:after:-bottom-px data-[state=on]:after:h-0.5"
        ]

      true ->
        [base, link_focus, dims(a.variant, a.size, a.orientation == "vertical"), on_classes(a)]
    end
  end

  # height, padding, font and radius: the variant gives the base, `sm`/`xs` and vertical tabs
  # change the height (the boxed ones follow the size), one utility per property
  defp dims(variant, size, vertical?) do
    boxed? = variant == "boxed"

    height =
      cond do
        boxed? and size == "sm" -> "h-[26px]"
        boxed? and size == "xs" -> "h-[22px]"
        vertical? -> "h-[34px]"
        size == "sm" -> "h-[34px]"
        size == "xs" -> "h-7"
        true -> @heights[variant]
      end

    px =
      cond do
        boxed? and size == "xs" -> "px-2.5"
        vertical? -> "px-3"
        true -> @pads[variant]
      end

    font =
      cond do
        boxed? and size == "sm" -> "text-[12.5px]"
        size == "sm" -> "text-[13px]"
        size == "xs" -> "text-[12px]"
        true -> "text-[14px]"
      end

    [
      height,
      px,
      font,
      @radii[variant],
      variant == "segmented" && "border-l border-line-strong first:border-l-0",
      vertical? && "justify-start"
    ]
  end

  defp on_classes(%{variant: variant, color: color} = a) do
    base =
      cond do
        color == "neutral" and @on_neutral[variant] -> @on_neutral[variant]
        true -> @on[variant]
      end

    [base, a.variant == "line" && line_mark(a.orientation == "vertical")]
  end

  defp line_mark(false),
    do: [
      @underline,
      "data-[state=on]:after:inset-x-0 data-[state=on]:after:-bottom-px data-[state=on]:after:h-0.5"
    ]

  defp line_mark(true),
    do: [
      @underline,
      "data-[state=on]:after:-left-px data-[state=on]:after:top-1.5 data-[state=on]:after:bottom-1.5 data-[state=on]:after:w-0.5"
    ]

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

  defp count_color(nil), do: "neutral"
  defp count_color(false), do: "neutral"
  defp count_color(tone), do: @count_tones[tone] || tone

  defp tab_attrs(tab, a, selected) do
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
      on?: on?,
      id: name && "#{a.id}-tab-#{name}",
      class: cx([tab_classes(a), tab[:class]]),
      count: tab[:count],
      count_color: count_color(tab[:count_tone] || (tab[:overdue] && "neg")),
      disabled: soon_or_disabled,
      title: tab[:title] || (tab[:soon] && a.soon_label) || nil,
      current: link? && on? && "page",
      rest: rest
    }
  end
end
