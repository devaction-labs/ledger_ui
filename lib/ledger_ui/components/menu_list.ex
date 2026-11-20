defmodule LedgerUI.Components.MenuList do
  @moduledoc """
  Menu lists: a vertical list of links with one active entry (`lu-ml`), plus `menu_item` and
  `menu_row`.

      <.menu_list variant="solid" color="primary">
        <:item navigate={~p"/orders"} active><.icon name="cart" />Orders</:item>
        <:item navigate={~p"/clients"} count={12}>Clients</:item>
      </.menu_list>

      <.menu_list variant="pill" on_select="pick">
        <:item value="shipping" active={@tab == "shipping"}>Shipping</:item>
      </.menu_list>

  Items with a destination (`href`, `navigate`, `patch`) are links; items with a `value` push
  `on_select` with `%{"value" => value}` (a `%JS{}` runs instead). `variant="static"` with
  `:item` slots is the read-only list (`lu-ml static`); with `rows` and `:row` it is the canvas
  list of `menu_row`s (a `div`).

  Streams: `<.menu_list id="pages" rows={@streams.pages}><:row :let={{_id, page}}>...`.

  ## Notes

    * An `active` link item (or `menu_item`) carries `aria-current="page"`.
    * Each `:item` accepts any attribute (`style`, `phx-click`, `id`...).
    * `menu_item`'s `variant`/`color` default to `nil`: the item is then a bare `<a>` meant for a
      `menu_list` `:row`; with a variant it is wrapped in its own `lu-ml` navigation.
  """
  use LedgerUI.Component

  @variants ~w(link solid pill gradient bordered static)
  @item_variants ~w(link solid pill gradient bordered)
  @colors ~w(primary neutral)

  # ---------------------------------------------------------------------------------------
  # menu_list

  attr :id, :string, default: nil
  attr :variant, :string, default: "link", values: @variants
  attr :color, :string, default: "primary", values: @colors
  attr :on_select, :any, default: nil
  attr :target, :any, default: nil
  attr :rows, :any, default: nil, doc: "A list or a stream rendered by `:row`."
  attr :row_id, :any, default: nil
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
    assigns = assign(assigns, :classes, cx(["lu-list", assigns.class]))

    ~H"""
    <div id={@id} class={@classes} phx-update={stream?(@rows) && "stream"} {@rest}>
      <%= for row <- stream_rows(@rows) do %>
        {render_slot(@row, row)}
      <% end %>
    </div>
    """
  end

  def menu_list(assigns) do
    assigns =
      assigns
      |> assign(:classes, cx(["lu-ml", assigns.variant, "c-" <> assigns.color, assigns.class]))
      |> assign(
        :items,
        Enum.map(assigns.item, &item_attrs(&1, assigns.on_select, assigns.target))
      )

    ~H"""
    <nav id={@id} class={@classes} phx-update={stream?(@rows) && "stream"} {@rest}>
      <%= if @rows do %>
        <%= for row <- stream_rows(@rows) do %>
          {render_slot(@row, row)}
        <% end %>
      <% end %>
      <%= for item <- @items do %>
        <.link :if={item.link?} class={item.class} aria-current={item.current} {item.rest}>
          {render_slot(item.slot)}<span
            :if={item.count != nil}
            class="lu-badge sm"
            style="margin-left:auto"
          >{item.count}</span>
        </.link>
        <a :if={!item.link?} class={item.class} href="#" role="button" {item.rest}>
          {render_slot(item.slot)}<span
            :if={item.count != nil}
            class="lu-badge sm"
            style="margin-left:auto"
          >{item.count}</span>
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
      class: cx([item[:active] && "on", item[:class]]),
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
      |> assign(:classes, cx([assigns.active && "on", assigns.class]))
      |> assign(:current, link? && assigns.active && "page")
      |> assign(
        :nav_class,
        cx(["lu-ml", assigns.variant, assigns.color && "c-" <> assigns.color])
      )

    ~H"""
    <nav :if={@variant} class={@nav_class}>
      <.menu_link
        link?={@link?}
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
  attr :classes, :string, required: true
  attr :current, :any, default: nil
  attr :rest, :map, required: true
  attr :icon, :list, required: true
  attr :count, :list, required: true
  slot :inner_block, required: true

  defp menu_link(assigns) do
    ~H"""
    <.link :if={@link?} class={@classes} aria-current={@current} {@rest}>
      {render_slot(@icon)}{render_slot(@inner_block)}<span :if={@count != []} style="margin-left:auto">{render_slot(
        @count
      )}</span>
    </.link>
    <a :if={!@link?} class={@classes} href="#" role="button" {@rest}>
      {render_slot(@icon)}{render_slot(@inner_block)}<span :if={@count != []} style="margin-left:auto">{render_slot(
        @count
      )}</span>
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
      |> assign(:classes, cx(["lu-list-row", assigns.class]))
      |> assign(:link?, Enum.any?([:href, :navigate, :patch], &Map.get(assigns.rest, &1)))

    ~H"""
    <.link :if={@link?} class={@classes} {@rest}>
      <.row_body {assigns} />
    </.link>
    <div :if={!@link?} class={@classes} {@rest}>
      <.row_body {assigns} />
    </div>
    """
  end

  defp row_body(assigns) do
    ~H"""
    {render_slot(@icon)}
    <div :if={@title || @sub || @inner_block != []} style="flex:1;min-width:0">
      <div :if={@title} class="t" style="font-weight:500">{@title}</div>
      <div :if={@sub} class="s lu-muted" style="font-size:12.5px">{@sub}</div>
      {render_slot(@inner_block)}
    </div>
    {render_slot(@value)}
    <span
      :if={@unread}
      role="img"
      aria-label={@unread_label}
      style="width:8px;height:8px;border-radius:50%;background:var(--accent);flex:none"
    ></span>
    """
  end
end
