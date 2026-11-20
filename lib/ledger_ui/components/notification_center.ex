defmodule LedgerUI.Components.NotificationCenter do
  @moduledoc """
  A bell with a count when something is unread and, under it, a panel with the notifications
  (`<.notification_center>`).

      <.notification_center
        id="notifications"
        items={@notifications}
        on_read="read"
        on_read_all="read_all"
      />

      <.notification_center id="inbox" variant="classic" items={@notifications}
        tabs={[%{id: "all", label: "All"}, %{id: "unread", label: "Unread"}, %{id: "orders", label: "Orders"}]}
        all_href={~p"/notifications"} />

  Each item is a map: `title` (required), `body`, `at`, `group` (day heading shared by consecutive
  items), `type` (`info success warning error primary`), `tone` (`lime`...), `icon`, `avatar`
  (`%{initials: "FP", tint: "t2"}`), `category` (a tab id), `read`, `id`, and `navigate`, `patch` or `href`.

  The panel is a popover (`LedgerUI.Float` hook, `priv/static/ledger_ui/hooks/float.js`): it closes on a click
  outside and on Esc, opens with `LedgerUI.open(socket, id)` and the tabs filter in the browser. Marking as
  read is up to the server: change `read` and the dot, the count and the bell follow. `on_read`
  pushes `%{"id" => id, "item" => item_id}`, `on_read_all` `%{"id" => id}`, `on_change` the tab
  `%{"id" => id, "tab" => tab_id}`; each takes an event name (to `target`) or a `%JS{}`.

  `variant="canvas"` is the compact panel (rows only); `classic` has a title bar, tabs and footer.
  `inline` renders only the panel, in the page flow (no bell, no hook).
  """
  use LedgerUI.Component
  alias LedgerUI.Components.Modal.Support

  @tones %{
    "info" => "info",
    "success" => "pos",
    "warning" => "warn",
    "error" => "neg",
    "primary" => "acc"
  }
  @type_icons %{
    "info" => "info",
    "success" => "check-circle",
    "warning" => "alert",
    "error" => "alert",
    "primary" => "bell"
  }
  @dot_colors %{
    "info" => "var(--info)",
    "success" => "var(--pos)",
    "warning" => "var(--warn)",
    "error" => "var(--neg)",
    "primary" => "var(--accent)"
  }
  @empty_style "display:flex;flex-direction:column;align-items:center;gap:8px;text-align:center"

  attr :id, :string, required: true
  attr :items, :list, default: []

  attr :tabs, :list, default: [%{id: "all", label: "Todas"}, %{id: "unread", label: "Não lidas"}]

  attr :unread, :integer, default: nil
  attr :title, :string, default: "Notificações"
  attr :bell_label, :string, default: "Notificações"
  attr :read_all_label, :string, default: "Marcar todas como lidas"
  attr :preferences_label, :string, default: "Preferências de notificação"
  attr :all_label, :string, default: "Ver todas as notificações"
  attr :unread_label, :string, default: "não lidas"
  attr :empty, :string, default: "Nenhuma notificação"
  attr :empty_text, :string, default: "Quando houver novidades, elas aparecem aqui."
  attr :variant, :string, default: "canvas", values: ~w(canvas classic)
  attr :empty_icon, :string, default: nil

  attr :empty_tone, :string,
    default: "success",
    values: ~w(neutral primary info success warning error)

  attr :all_href, :string, default: nil
  attr :preferences_href, :string, default: nil
  attr :on_read_all, :any, default: nil
  attr :on_read, :any, default: nil
  attr :on_change, :any, default: nil
  attr :target, :any, default: nil
  attr :open, :boolean, default: false
  attr :placement, :string, default: "bottom-end"
  attr :arrow, :boolean, default: false
  attr :class, :any, default: nil, doc: "Merged into the panel."

  attr :inline, :boolean,
    default: false,
    doc: "Only the panel, in the page flow: no bell, no hook."

  attr :rest, :global

  slot :empty_action

  def notification_center(assigns) do
    items = assigns.items
    unread = assigns.unread || Enum.count(items, &(!&1[:read]))
    tabs = if assigns.variant == "classic", do: assigns.tabs, else: []

    cfg =
      Support.cfg("popover",
        trigger: "click",
        placement: assigns.placement,
        fallbacks: "bottom,top",
        offset: 8,
        arrow: Support.flag(assigns.arrow),
        open: Support.flag(assigns.open),
        notifications: "true",
        empty: assigns.empty,
        "on-read": Support.handler(assigns.on_read),
        "on-read-all": Support.handler(assigns.on_read_all),
        "on-change": Support.handler(assigns.on_change),
        target: assigns.target
      )

    assigns =
      assigns
      |> assign(:cfg, cfg)
      |> assign(:unread_n, unread)
      |> assign(:tab_list, Enum.map(tabs, &tab(&1, items)))
      |> assign(:rows, rows(items))
      |> assign(:fl_class, "fl p-" <> assigns.placement)
      |> assign(:panel_id, assigns.id <> "-panel")
      |> assign(:empty_c, "c-" <> assigns.empty_tone)
      |> assign(:empty_name, assigns.empty_icon || "check-circle")
      |> assign(:empty_style, @empty_style)
      |> assign(:footer?, assigns.all_href != nil or assigns.preferences_href != nil)
      |> assign(:badge, if(unread > 99, do: "99+", else: to_string(unread)))

    ~H"""
    <%= if @inline do %>
      <.panel {assigns} root_attrs={%{"id" => @id}} />
    <% else %>
      <span id={@id} class="lu-anc" phx-hook="LedgerUI.Float" {@cfg} {@rest}>
        <button
          type="button"
          class="lu-bell"
          aria-label={@bell_label}
          aria-haspopup="dialog"
          aria-expanded="false"
          aria-controls={@panel_id}
        >
          <.icon name="bell" /><b :if={@unread_n > 0}>{@badge}</b>
        </button>
        <span class={@fl_class} hidden={!@open} keep-hidden keep-style keep-class>
          <.panel {assigns} root_attrs={%{"id" => @panel_id}} />
        </span>
      </span>
    <% end %>
    """
  end

  defp panel(%{items: []} = assigns) do
    ~H"""
    <div
      class={cx(["lu-pop pad", @empty_c, @class])}
      {Support.st("width:220px;" <> @empty_style)}
      role="dialog"
      aria-label={@bell_label}
      {@root_attrs}
    >
      <span class="lu-empty-ic"><.icon name={@empty_name} size="md" /></span>
      <b style="font-size:13.5px">{@empty}</b>
      <span class="lu-xs lu-muted">{@empty_text}</span>
      {render_slot(@empty_action)}
    </div>
    """
  end

  defp panel(%{variant: "classic"} = assigns) do
    ~H"""
    <div
      class={cx(["lu-pop", @class])}
      style="width:380px;padding:0"
      role="dialog"
      aria-label={@title}
      {@root_attrs}
    >
      <div class="lu-row" style="padding:12px 14px 0">
        <b>{@title}</b>
        <span class="lu-grow"></span>
        <button :if={@on_read_all} class="lu-btn link sm" type="button" data-lu-read-all="">
          {@read_all_label}
        </button>
      </div>
      <div :if={@tab_list != []} style="padding:0 14px">
        <div class="lu-tabs" data-lu-single="" role="tablist">
          <button
            :for={{t, i} <- Enum.with_index(@tab_list)}
            class={if i == 0, do: "lu-tab on", else: "lu-tab"}
            role="tab"
            aria-selected={Support.flag(i == 0)}
            type="button"
            data-lu-tab={t.id}
            data-lu-empty={t.empty}
          >
            {t.label} <span :if={t.count > 0} class="lu-badge acc">{t.count}</span>
          </button>
        </div>
      </div>
      <%= for {item, first?} <- @rows do %>
        <.classic_row item={item} first?={first?} />
      <% end %>
      <div
        :if={@footer?}
        class="lu-row"
        style="padding:10px 14px;border-top:1px solid var(--line)"
      >
        <span class="lu-xs lu-muted">{@unread_n} {@unread_label}</span>
        <span class="lu-grow"></span>
        <a :if={@all_href} class="lu-btn link sm" href={@all_href}>{@all_label}</a>
        <a
          :if={@preferences_href}
          class="lu-btn icon ghost sm"
          href={@preferences_href}
          aria-label={@preferences_label}
        >
          <.icon name="settings" />
        </a>
      </div>
    </div>
    """
  end

  defp panel(assigns) do
    ~H"""
    <div
      class={cx(["lu-pop", @class])}
      style="width:360px;padding:6px"
      role="dialog"
      aria-label={@bell_label}
      {@root_attrs}
    >
      <%= for {{item, _first?}, group} <- Enum.zip(@rows, groups(@rows)) do %>
        <div :if={group} class="lu-menu-label" role="presentation">{group}</div>
        <.canvas_row item={item} />
      <% end %>
    </div>
    """
  end

  defp canvas_row(assigns) do
    ~H"""
    <.row_tag item={@item} class={cx(["lu-ntf", !@item[:read] && "unread"])}>
      <span
        class="lu-dot"
        {Support.st(dot_style(@item))}
      ></span>
      <span class="tx"><b>{@item.title}</b> {@item[:body]}</span>
      <time :if={@item[:at]}>{@item[:at]}</time>
    </.row_tag>
    """
  end

  defp classic_row(assigns) do
    ~H"""
    <.row_tag
      item={@item}
      class="lu-row top"
      style={"padding:12px 14px;gap:12px;flex-wrap:nowrap;border-top:" <> if(@first?, do: "0", else: "1px solid var(--line)")}
    >
      <span {Support.st("width:6px;height:6px;border-radius:50%;margin-top:14px;background:" <> if(@item[:read], do: "transparent", else: "var(--accent)"))}></span>
      <%= cond do %>
        <% @item[:avatar] -> %>
          <span class={"lu-av " <> to_string(@item.avatar[:tint] || "t1")} style="--s:32px">{@item.avatar[
            :initials
          ]}</span>
        <% tile(@item) -> %>
          <span class={cx(["lu-ic", tone(@item)])}><.icon name={tile(@item)} size="md" /></span>
        <% true -> %>
      <% end %>
      <div class="lu-col lu-grow" style="gap:2px">
        <span
          class="lu-small"
          {Support.st(if(@item[:read], do: "font-weight:400", else: "font-weight:600"))}
        >{@item.title}</span>
        <span :if={@item[:body]} class="lu-xs lu-muted">{@item[:body]}</span>
        <span class="lu-xs lu-muted">{@item[:at]}</span>
      </div>
    </.row_tag>
    """
  end

  attr :item, :map, required: true
  attr :class, :string, default: nil
  attr :style, :string, default: nil
  slot :inner_block, required: true

  defp row_tag(%{item: %{navigate: to}} = assigns) do
    assigns = assign(assigns, :to, to)

    ~H"""
    <.link navigate={@to} class={@class} style={@style} {item_attrs(@item)}>{render_slot(@inner_block)}</.link>
    """
  end

  defp row_tag(%{item: %{patch: to}} = assigns) do
    assigns = assign(assigns, :to, to)

    ~H"""
    <.link patch={@to} class={@class} style={@style} {item_attrs(@item)}>{render_slot(@inner_block)}</.link>
    """
  end

  defp row_tag(%{item: %{href: to}} = assigns) do
    assigns = assign(assigns, :to, to)

    ~H"""
    <.link href={@to} class={@class} style={@style} {item_attrs(@item)}>{render_slot(@inner_block)}</.link>
    """
  end

  defp row_tag(assigns) do
    ~H"""
    <div class={@class} {Support.st(@style)} {item_attrs(@item)}>{render_slot(@inner_block)}</div>
    """
  end

  defp item_attrs(item) do
    %{
      "data-lu-item" => item[:id],
      "data-lu-cat" => item[:category],
      "data-lu-read" => Support.flag(item[:read])
    }
  end

  defp tab(%{id: id} = t, items) do
    count =
      t[:count] ||
        case id do
          "all" -> 0
          "unread" -> Enum.count(items, &(!&1[:read]))
          cat -> Enum.count(items, &(!&1[:read] and &1[:category] == cat))
        end

    %{id: id, label: t.label, empty: t[:empty], count: count}
  end

  defp tone(item), do: item[:tone] || @tones[item[:type]]

  defp tile(item), do: item[:icon] || @type_icons[item[:type]]

  defp dot_style(item) do
    Support.style([
      "margin-top:6px",
      @dot_colors[item[:type]] && "color:" <> @dot_colors[item[:type]],
      item[:read] && "opacity:0"
    ])
  end

  # `{item, first?}` pairs for the rows.
  defp rows(items) do
    items |> Enum.with_index() |> Enum.map(fn {item, i} -> {item, i == 0} end)
  end

  # The day heading of each row: shown when it differs from the previous row's.
  defp groups(rows) do
    {list, _} =
      Enum.map_reduce(rows, :none, fn {item, _}, prev ->
        g = item[:group]
        {if(g != nil and g != prev, do: g), g || prev}
      end)

    list
  end
end
