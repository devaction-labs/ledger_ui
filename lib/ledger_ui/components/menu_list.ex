defmodule LedgerUI.Components.MenuList do
  @moduledoc """
  Menu lists: a vertical list of links with one active entry, plus `menu_item` and `menu_row`.
  Styled only with Tailwind utilities: the list carries the look of its links (and of the active
  one, marked `data-state="on"`), so a `menu_item` inside a `:row` takes it from the list. Every part
  carries `data-part` (`menu-list`, `menu-item`, `menu-item-count`, `menu-rows`, `menu-row`...).

      <.menu_list variant="solid" color="primary">
        <:item navigate={~p"/orders"} active><.icon name="cart" />Orders</:item>
        <:item navigate={~p"/clients"} count={12}>Clients</:item>
      </.menu_list>

      <.menu_list variant="pill" on_select="pick">
        <:item value="shipping" active={@tab == "shipping"}>Shipping</:item>
      </.menu_list>

  Items with a destination (`href`, `navigate`, `patch`) are links; items with a `value` push
  `on_select` with `%{"value" => value}` (a `%JS{}` runs instead). `variant="static"` with
  `:item` slots is the read-only list (links ignore the pointer); with `rows` and `:row` it is the
  canvas list of `menu_row`s (a `div`).

  Streams: `<.menu_list id="pages" rows={@streams.pages}><:row :let={{_id, page}}>...`.

  ## Notes

    * An `active` link item (or `menu_item`) carries `aria-current="page"`.
    * Each `:item` accepts any attribute (`style`, `phx-click`, `id`...).
    * `menu_item`'s `variant`/`color` default to `nil`: the item is then a bare `<a>` meant for a
      `menu_list` `:row`; with a variant it is wrapped in its own `lu-ml` navigation.
  """
  use LedgerUI.Component
  import LedgerUI.Components.Badge, only: [badge: 1]

  @variants ~w(link solid pill gradient bordered static)
  @item_variants ~w(link solid pill gradient bordered)
  @colors ~w(primary neutral)

  # the look of the links of a list, written on the list (`[&_a]:`) and on its active link
  # (`[&_a[data-state=on]]:`)
  @list "flex w-[220px] flex-col gap-0.5 [&_a]:flex [&_a]:h-9 [&_a]:items-center [&_a]:gap-2.5 [&_a]:px-2.5 [&_a]:text-[14px] [&_a]:text-ink-2 [&_a]:no-underline [&_a_svg]:size-[18px]"
  @radius %{"pill" => "[&_a]:rounded-full"}
  @on %{
    {"link", "primary"} =>
      "[&_a[data-state=on]]:font-medium [&_a[data-state=on]]:text-accent-content",
    {"link", "neutral"} => "[&_a[data-state=on]]:font-medium [&_a[data-state=on]]:text-ink",
    {"solid", "primary"} =>
      "[&_a[data-state=on]]:bg-accent [&_a[data-state=on]]:text-accent-foreground",
    {"solid", "neutral"} => "[&_a[data-state=on]]:bg-ink [&_a[data-state=on]]:text-on-inverse",
    {"pill", "primary"} =>
      "[&_a[data-state=on]]:bg-accent-soft [&_a[data-state=on]]:text-accent-content",
    {"pill", "neutral"} => "[&_a[data-state=on]]:bg-selected [&_a[data-state=on]]:text-ink",
    {"gradient", "primary"} =>
      "[&_a[data-state=on]]:bg-[linear-gradient(90deg,var(--color-accent),var(--lu-accent-400))] [&_a[data-state=on]]:text-white",
    {"gradient", "neutral"} =>
      "[&_a[data-state=on]]:bg-[linear-gradient(90deg,var(--lu-ink),var(--lu-ink-2))] [&_a[data-state=on]]:text-page",
    {"bordered", "primary"} =>
      "[&_a[data-state=on]]:text-accent-content [&_a[data-state=on]]:shadow-[inset_0_0_0_1px_var(--lu-accent-500)]",
    {"bordered", "neutral"} =>
      "[&_a[data-state=on]]:text-ink [&_a[data-state=on]]:shadow-[inset_0_0_0_1px_var(--lu-line-strong)]"
  }

  # a row of the canvas list: a flex row, a rule between rows, hover and focus ring when it acts
  @row "flex items-center gap-3 border-b border-line px-3 py-2.5 text-inherit no-underline last:border-b-0 " <>
         "focus-visible:outline-0 focus-visible:shadow-[inset_0_0_0_2px_var(--lu-accent-500)] " <>
         "[&:is(a,button,[role=button])]:hover:bg-hover"

  @demo "[&_a]:animate-[mo-mlhl_6s_infinite] [&_a]:[animation-delay:var(--dl)]"

  defp list_classes(variant, color, class, demo? \\ false) do
    cx([
      demo? && @demo,
      @list,
      @radius[variant] || "[&_a]:rounded-[9px]",
      @on[{variant, color}],
      variant == "static" && "[&_a]:pointer-events-none",
      class
    ])
  end

  # ---------------------------------------------------------------------------------------
  # menu_list

  attr :id, :string, default: nil
  attr :variant, :string, default: "link", values: @variants
  attr :color, :string, default: "primary", values: @colors
  attr :on_select, :any, default: nil
  attr :target, :any, default: nil
  attr :rows, :any, default: nil, doc: "A list or a stream rendered by `:row`."
  attr :row_id, :any, default: nil

  attr :demo, :boolean,
    default: false,
    doc:
      "The animated mock: the highlight walks over the links (stagger them with `style=\"--dl:1.5s\"`)."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :item do
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
    attr :active, :boolean
    attr :value, :string
    attr :count, :any
    attr :class, :any
    attr :style, :string
    attr :id, :string
    attr :title, :string
    attr :"phx-click", :any
    attr :"phx-target", :any
    attr :"phx-value-id", :any
  end

  slot :row

  def menu_list(%{variant: "static", rows: rows} = assigns) when not is_nil(rows) do
    assigns =
      assign(
        assigns,
        :classes,
        cx([
          "flex flex-col overflow-hidden rounded-lg border border-line bg-panel",
          assigns.class
        ])
      )

    ~H"""
    <div
      id={@id}
      data-part="menu-rows"
      class={@classes}
      phx-update={stream?(@rows) && "stream"}
      {@rest}
    >
      <%= for row <- stream_rows(@rows) do %>
        {render_slot(@row, row)}
      <% end %>
    </div>
    """
  end

  def menu_list(assigns) do
    assigns =
      assigns
      |> assign(
        :classes,
        list_classes(assigns.variant, assigns.color, assigns.class, assigns.demo)
      )
      |> assign(
        :items,
        Enum.map(assigns.item, &item_attrs(&1, assigns.on_select, assigns.target))
      )

    ~H"""
    <nav
      id={@id}
      data-part="menu-list"
      class={@classes}
      phx-update={stream?(@rows) && "stream"}
      {@rest}
    >
      <%= if @rows do %>
        <%= for row <- stream_rows(@rows) do %>
          {render_slot(@row, row)}
        <% end %>
      <% end %>
      <%= for item <- @items do %>
        <.link
          :if={item.link?}
          data-part="menu-item"
          data-state={item.on? && "on"}
          class={item.class}
          aria-current={item.current}
          {item.rest}
        >
          {render_slot(item.slot)}
          <.badge
            :if={item.count != nil}
            data-part="menu-item-count"
            canvas
            size="sm"
            class="ml-auto"
          >
            {item.count}
          </.badge>
        </.link>
        <a
          :if={!item.link?}
          data-part="menu-item"
          data-state={item.on? && "on"}
          class={item.class}
          href="#"
          role="button"
          {item.rest}
        >
          {render_slot(item.slot)}
          <.badge
            :if={item.count != nil}
            data-part="menu-item-count"
            canvas
            size="sm"
            class="ml-auto"
          >
            {item.count}
          </.badge>
        </a>
      <% end %>
    </nav>
    """
  end

  defp stream?(%Phoenix.LiveView.LiveStream{}), do: true
  defp stream?(_), do: false

  defp stream_rows(nil), do: []
  defp stream_rows(rows), do: rows

  defp item_attrs(item, on_select, target) do
    link? = Enum.any?([:href, :navigate, :patch], &item[&1])
    link_keys = [:href, :navigate, :patch]

    rest =
      Map.drop(item, [:__slot__, :inner_block, :active, :value, :count, :class])

    rest = if link?, do: rest, else: Map.drop(rest, link_keys)
    rest = click(rest, link?, item[:value], on_select, target)

    %{
      link?: link?,
      on?: item[:active] == true,
      class: cx([item[:class]]),
      current: link? && item[:active] == true && "page",
      count: item[:count],
      rest: rest,
      slot: [item]
    }
  end

  # An item without a destination pushes `on_select` with its value.
  defp click(rest, false, value, on_select, target)
       when not is_nil(value) and not is_nil(on_select) do
    Map.put_new(rest, :"phx-click", select_js(on_select, value, target))
  end

  defp click(rest, _, _, _, _), do: rest

  defp select_js(%JS{} = js, _value, _target), do: js

  defp select_js(event, value, target) when is_binary(event) do
    opts = [value: %{value: value}]
    opts = if target, do: Keyword.put(opts, :target, target), else: opts
    JS.push(event, opts)
  end

  # ---------------------------------------------------------------------------------------
  # menu_item

  attr :variant, :string, default: nil, values: [nil | @item_variants]
  attr :color, :string, default: nil, values: [nil | @colors]
  attr :active, :boolean, default: false
  attr :value, :string, default: nil
  attr :on_select, :any, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method download replace)

  slot :count
  slot :icon
  slot :inner_block, required: true

  def menu_item(assigns) do
    link? = Enum.any?([:href, :navigate, :patch], &Map.get(assigns.rest, &1))

    rest =
      if link? or is_nil(assigns.value) or is_nil(assigns.on_select),
        do: assigns.rest,
        else:
          Map.put_new(
            assigns.rest,
            :"phx-click",
            select_js(assigns.on_select, assigns.value, assigns.target)
          )

    assigns =
      assigns
      |> assign(:link?, link?)
      |> assign(:rest, rest)
      |> assign(:classes, cx([assigns.class]))
      |> assign(:current, link? && assigns.active && "page")
      |> assign(
        :nav_class,
        list_classes(assigns.variant, assigns.color || "primary", nil)
      )

    ~H"""
    <nav :if={@variant} data-part="menu-list" class={@nav_class}>
      <.menu_link
        link?={@link?}
        on?={@active}
        classes={@classes}
        current={@current}
        rest={@rest}
        icon={@icon}
        count={@count}
      >
        {render_slot(@inner_block)}
      </.menu_link>
    </nav>
    <.menu_link
      :if={!@variant}
      link?={@link?}
      on?={@active}
      classes={@classes}
      current={@current}
      rest={@rest}
      icon={@icon}
      count={@count}
    >
      {render_slot(@inner_block)}
    </.menu_link>
    """
  end

  attr :link?, :boolean, required: true
  attr :on?, :boolean, default: false
  attr :classes, :any, required: true
  attr :current, :any, default: nil
  attr :rest, :map, required: true
  attr :icon, :list, required: true
  attr :count, :list, required: true
  slot :inner_block, required: true

  defp menu_link(assigns) do
    ~H"""
    <.link
      :if={@link?}
      data-part="menu-item"
      data-state={@on? && "on"}
      class={@classes}
      aria-current={@current}
      {@rest}
    >
      {render_slot(@icon)}{render_slot(@inner_block)}<span
        :if={@count != []}
        data-part="menu-item-count"
        class="ml-auto"
      >{render_slot(@count)}</span>
    </.link>
    <a
      :if={!@link?}
      data-part="menu-item"
      data-state={@on? && "on"}
      class={@classes}
      href="#"
      role="button"
      {@rest}
    >
      {render_slot(@icon)}{render_slot(@inner_block)}<span
        :if={@count != []}
        data-part="menu-item-count"
        class="ml-auto"
      >{render_slot(@count)}</span>
    </a>
    """
  end

  # ---------------------------------------------------------------------------------------
  # menu_row

  attr :title, :string, default: nil
  attr :sub, :string, default: nil
  attr :unread, :boolean, default: false
  attr :unread_label, :string, default: "Unread"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method download replace)

  slot :icon
  slot :value
  slot :inner_block

  def menu_row(assigns) do
    assigns =
      assigns
      |> assign(:classes, cx([@row, assigns.class]))
      |> assign(:link?, Enum.any?([:href, :navigate, :patch], &Map.get(assigns.rest, &1)))

    ~H"""
    <.link :if={@link?} data-part="menu-row" class={@classes} {@rest}>
      <.row_body {assigns} />
    </.link>
    <div :if={!@link?} data-part="menu-row" class={@classes} {@rest}>
      <.row_body {assigns} />
    </div>
    """
  end

  defp row_body(assigns) do
    ~H"""
    {render_slot(@icon)}
    <div
      :if={@title || @sub || @inner_block != []}
      data-part="menu-row-body"
      class="min-w-0 flex-1"
    >
      <div :if={@title} data-part="menu-row-title" class="font-medium">{@title}</div>
      <div :if={@sub} data-part="menu-row-sub" class="text-[12.5px] text-muted">{@sub}</div>
      {render_slot(@inner_block)}
    </div>
    {render_slot(@value)}
    <span
      :if={@unread}
      data-part="menu-row-unread"
      role="img"
      aria-label={@unread_label}
      class="size-2 flex-none rounded-full bg-accent-500"
    ></span>
    """
  end

  attr :id, :string, default: nil

  attr :variant, :string,
    default: "link",
    values: ["link", "solid", "pill", "gradient", "bordered", "static"]

  attr :color, :string, default: "primary", values: ["primary", "neutral"]
  attr :on_select, :any, default: nil
  attr :target, :any, default: nil
  attr :rows, :any, default: nil, doc: "A list or a stream rendered by `:row`."
  attr :row_id, :any, default: nil

  attr :demo, :boolean,
    default: false,
    doc: "The animated mock: the highlight walks over the links."

  attr :class, :any, default: nil
  attr :rest, :global

  slot :item do
    attr :href, :string
    attr :navigate, :string
    attr :patch, :string
    attr :active, :boolean
    attr :value, :string
    attr :count, :any
    attr :class, :any
    attr :style, :string
    attr :id, :string
    attr :title, :string
    attr :"phx-click", :any
    attr :"phx-target", :any
    attr :"phx-value-id", :any
  end

  slot :row

  @doc "Same as `menu_list/1` (same attributes and slots), under the name the design vitrine uses."
  def menu(assigns), do: menu_list(assigns)
end
