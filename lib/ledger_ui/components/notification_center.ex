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

  Each item is a map: `title` (required), `body`, `text`, `at`, `group` (day heading shared by consecutive
  items), `type` (`info success warning error primary`), `tone` (`lime`...), `icon`, `avatar`
  (`%{initials: "FP", tint: "t2"}`), `category` (a tab id), `read`, `id`, and `navigate`, `patch` or `href`.

  `body` may be rich (a `Phoenix.HTML.raw/1` string or a rendered `~H` template); in the canvas
  rows `text` replaces the whole sentence (bold title, then body) with your own, so a part in the
  middle can be bold: `text: raw("Payment received from <b>Acme</b> · $ 3,120.50")`. Only pass
  trusted markup there.

  The panel is a popover (`LedgerUI.Float` hook, `priv/static/ledger_ui/hooks/float.js`): it closes on a click
  outside and on Esc, opens with `LedgerUI.open(socket, id)` and the tabs filter in the browser. Marking as
  read is up to the server: change `read` and the dot, the count and the bell follow. `on_read`
  pushes `%{"id" => id, "item" => item_id}`, `on_read_all` `%{"id" => id}`, `on_change` the tab
  `%{"id" => id, "tab" => tab_id}`; each takes an event name (to `target`) or a `%JS{}`.

  `variant="canvas"` is the compact panel (rows only); `classic` has a title bar, tabs and footer.
  `count_tone` (or `count_tone` in a tab map) turns the tab counters neutral and highlights only the
  one on the selected tab; it is `group-aria-selected:` utilities on the tab, so it follows the
  selection without JS and the server-rendered HTML is already right.

  `inline` renders only the panel, in the page flow (no bell, no hook).

  ## Streams

  `items` may be a stream (`items={@streams.notifications}`): the rows go in a container with
  `phx-update="stream"`, a new notification is one insert and marking one as read patches only
  that row. The list can no longer be counted, so `unread` is required and, in the `classic`
  variant, so is the `count` of every tab other than `"all"` (which shows none) and `"unread"`
  (which takes `unread`); an `ArgumentError` says what is missing. With a stream the rows have no
  `group` heading (it depends on the previous row) and the empty card is not drawn (draw your own
  when the list has no rows). Each row needs a stream `id` (`dom_id`), so use `id` in the items.

  The `classic` header takes an `:actions` slot (controls after "mark all as read") and `closable`, a
  close button that closes the popover and returns focus to the bell (`close_label` is its `aria-label`).
  """
  use LedgerUI.Component
  alias LedgerUI.Components.Modal.Support
  alias Phoenix.LiveView.LiveStream

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
    "info" => "text-info",
    "success" => "text-pos",
    "warning" => "text-warn",
    "error" => "text-neg",
    "primary" => "text-(--lu-accent)"
  }
  # the avatar tints of the design (`t1` is the accent's tint)
  @tints %{
    "t1" => "bg-accent-100 text-accent-800",
    "t2" => "bg-[#fde3c7] text-[#7a3d0c] dark:bg-[#3a2410] dark:text-[#f6c99a]",
    "t3" => "bg-[#e3e6fb] text-[#2b3577] dark:bg-[#1d2346] dark:text-[#b9c3f5]",
    "t4" => "bg-[#fbe0e6] text-[#7f1f33] dark:bg-[#3a1820] dark:text-[#f3b3c0]",
    "t5" => "bg-[#e2f6c6] text-[#355a0c] dark:bg-[#1f2c10] dark:text-[#c4e78f]"
  }

  @pop "rounded-lg border border-line bg-panel shadow-popover min-w-[220px]"
  @bell "relative inline-grid size-9 place-items-center rounded-md border border-line-strong bg-panel"
  @bell_badge "absolute -top-[5px] -right-[5px] grid h-[18px] min-w-[18px] place-items-center rounded-full border-2 border-page bg-neg px-[5px] text-[11px] text-white"
  @label "px-2.5 pt-2 pb-1 text-[11.5px] font-medium tracking-[.06em] text-muted uppercase"
  @link "inline-flex cursor-pointer items-center justify-center gap-1.5 px-2.5 text-[13px] leading-none font-medium whitespace-nowrap text-accent-content hover:underline hover:underline-offset-[3px]"
  @icon_link "inline-flex size-[30px] cursor-pointer items-center justify-center rounded-md border border-transparent bg-transparent text-ink-2 hover:bg-hover hover:text-ink [&_svg]:size-4"
  @tab "relative inline-flex h-10 cursor-pointer items-center gap-[7px] border-0 bg-transparent p-0 text-sm font-medium text-muted hover:text-ink " <>
         "after:absolute after:inset-x-0 after:-bottom-px after:hidden after:h-0.5 after:rounded-[2px] after:bg-ink after:content-[''] " <>
         "aria-selected:text-ink aria-selected:after:block"
  @tab_group @tab <> " group"
  @tab_badge "inline-flex h-[18px] items-center gap-[5px] rounded-sm bg-accent-soft px-1.5 text-[11px] leading-none font-medium whitespace-nowrap text-accent-content tabular-nums"
  # `count_tone`: the badge is neutral and takes the tone only on the selected tab, through
  # `group-aria-selected:` on the tab button (no JS: the hook already flips `aria-selected`).
  @tab_badge_idle "inline-flex h-[18px] items-center gap-[5px] rounded-sm bg-sunken px-1.5 text-[11px] leading-none font-medium whitespace-nowrap text-muted tabular-nums"
  @tab_badge_on %{
    "acc" => "group-aria-selected:bg-accent group-aria-selected:text-accent-foreground",
    "pos" => "group-aria-selected:bg-pos group-aria-selected:text-white",
    "neg" => "group-aria-selected:bg-neg group-aria-selected:text-white",
    "warn" => "group-aria-selected:bg-[#f59e0b] group-aria-selected:text-[#1b1300]",
    "info" => "group-aria-selected:bg-info group-aria-selected:text-white",
    "lime" => "group-aria-selected:bg-lime-soft group-aria-selected:text-lime"
  }
  @tab_badge_alias %{
    "primary" => "acc",
    "success" => "pos",
    "error" => "neg",
    "warning" => "warn"
  }
  @empty_icon "grid size-11 place-items-center rounded-[12px] bg-(--c-soft) text-(--c-ink)"

  attr :id, :string, required: true

  attr :items, :any,
    default: [],
    doc:
      "A list of maps or a stream (`@streams.x`): with a stream `unread` (and the `count` of the `classic` tabs) is required."

  attr :tabs, :list, default: nil

  attr :unread, :integer, default: nil
  attr :title, :string, default: nil
  attr :bell_label, :string, default: nil
  attr :read_all_label, :string, default: nil
  attr :preferences_label, :string, default: nil
  attr :close_label, :string, default: nil
  attr :all_label, :string, default: nil
  attr :unread_label, :string, default: nil
  attr :empty, :string, default: nil
  attr :empty_text, :string, default: nil
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

  attr :count_tone, :string,
    default: nil,
    values: [nil | ~w(acc pos neg warn info lime primary success error warning)],
    doc:
      "`classic`: the tone of the tab counters. The highlight follows the selected tab (the others stay neutral). Without it every counter keeps the accent look. A tab can override it with its own `count_tone`."

  attr :size, :string,
    default: "md",
    values: ~w(md sm),
    doc:
      "The bell: `md` is 36px, `sm` the 32px button of the top bar (like `navbar_bell size=\"sm\"`)."

  attr :open, :boolean, default: false

  attr :placement, :string,
    default: "bottom-end",
    values: LedgerUI.Components.Dropdown.placements(),
    doc: "Where the panel opens, as in `dropdown`."

  attr :arrow, :boolean, default: false
  attr :class, :any, default: nil, doc: "Merged into the panel."

  attr :inline, :boolean,
    default: false,
    doc: "Only the panel, in the page flow: no bell, no hook."

  attr :closable, :boolean,
    default: false,
    doc:
      "`classic`: a close button at the end of the header (closes the popover, focus goes back to the bell). Ignored when `inline`."

  attr :rest, :global

  slot :empty_action

  slot :actions,
    doc:
      "`classic`: extra controls at the end of the header, after \"mark all as read\" and before the close button."

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def notification_center(assigns) do
    changed0 = assigns.__changed__

    assigns =
      if assigns.tabs == nil,
        do: %{
          assigns
          | tabs: [
              %{id: "all", label: I18n.tp("notification_center.tab_all", assigns.locale)},
              %{id: "unread", label: I18n.tp("notification_center.tab_unread", assigns.locale)}
            ]
        },
        else: assigns

    assigns =
      I18n.texts(assigns,
        title: {:pt, "notification_center.title"},
        bell_label: {:pt, "notification_center.title"},
        read_all_label: {:pt, "notification_center.read_all"},
        preferences_label: {:pt, "notification_center.preferences"},
        close_label: {:pt, "common.close"},
        all_label: {:pt, "notification_center.all"},
        unread_label: {:pt, "notification_center.unread"},
        empty: {:pt, "notification_center.empty"},
        empty_text: {:pt, "notification_center.empty_text"}
      )

    items = assigns.items
    unread = unread(assigns.unread, items)

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
      |> assign(:fl_class, Support.float_class())
      |> assign(:panel_id, assigns.id <> "-panel")
      |> assign(:badge, if(unread > 99, do: "99+", else: to_string(unread)))
      |> assign(:bell_class, bell_class(assigns.size))
      |> assign(:badge_class, @bell_badge)

    assigns =
      settle(assigns, changed0,
        cfg: [
          :placement,
          :arrow,
          :open,
          :empty,
          :on_read,
          :on_read_all,
          :on_change,
          :target
        ],
        unread_n: [:unread, :items],
        fl_class: [],
        panel_id: [:id],
        badge: [:unread, :items],
        bell_class: [:size],
        badge_class: []
      )

    # The panel takes the attributes one by one, raw, and works out the rows itself: a render that
    # only changes the state of the bell or of the float (`open`) does not send the rows again.
    ~H"""
    <%= if @inline do %>
      <.panel_body
        id={@id}
        items={@items}
        tabs={@tabs}
        unread={@unread}
        variant={@variant}
        count_tone={@count_tone}
        empty_tone={@empty_tone}
        empty_icon={@empty_icon}
        all_href={@all_href}
        preferences_href={@preferences_href}
        title={@title}
        bell_label={@bell_label}
        read_all_label={@read_all_label}
        preferences_label={@preferences_label}
        close_label={@close_label}
        all_label={@all_label}
        unread_label={@unread_label}
        empty={@empty}
        empty_text={@empty_text}
        class={@class}
        closable={@closable}
        inline={@inline}
        on_read_all={@on_read_all}
        actions={@actions}
        empty_action={@empty_action}
      />
    <% else %>
      <span
        id={@id}
        data-part="notification-center"
        class="relative inline-flex"
        phx-hook="LedgerUI.Float"
        {@cfg}
        {@rest}
      >
        <button
          type="button"
          data-part="notification-bell"
          class={@bell_class}
          aria-label={@bell_label}
          aria-haspopup="dialog"
          aria-expanded="false"
          aria-controls={@panel_id}
        >
          <.icon name="bell" /><b
            :if={@unread_n > 0}
            data-part="notification-badge"
            class={@badge_class}
          >{@badge}</b>
        </button>
        <span
          data-part="notification-float"
          data-lu-fl=""
          data-lu-placement={@placement}
          class={@fl_class}
          hidden={!@open}
        >
          <.panel_body
            id={@id}
            items={@items}
            tabs={@tabs}
            unread={@unread}
            variant={@variant}
            count_tone={@count_tone}
            empty_tone={@empty_tone}
            empty_icon={@empty_icon}
            all_href={@all_href}
            preferences_href={@preferences_href}
            title={@title}
            bell_label={@bell_label}
            read_all_label={@read_all_label}
            preferences_label={@preferences_label}
            close_label={@close_label}
            all_label={@all_label}
            unread_label={@unread_label}
            empty={@empty}
            empty_text={@empty_text}
            class={@class}
            closable={@closable}
            inline={@inline}
            on_read_all={@on_read_all}
            actions={@actions}
            empty_action={@empty_action}
          />
        </span>
      </span>
    <% end %>
    """
  end

  # The panel: the attributes it uses, raw; the rows, tabs and counters are worked out here.
  defp panel_body(assigns) do
    changed0 = assigns.__changed__
    items = assigns.items
    stream? = match?(%LiveStream{}, items)
    unread = unread(assigns.unread, items)
    tabs = if assigns.variant == "classic", do: assigns.tabs, else: []

    assigns =
      assigns
      |> assign(:root_attrs, %{
        "id" => if(assigns.inline, do: assigns.id, else: assigns.id <> "-panel")
      })
      |> assign(:unread_n, unread)
      |> assign(:tab_list, Enum.map(tabs, &tab(&1, items, assigns.count_tone, unread)))
      |> assign(:stream_rows, if(stream?, do: items))
      |> assign(:rows, if(stream?, do: [], else: rows(items)))
      |> assign(:empty_c, LedgerUI.Color.vars(assigns.empty_tone))
      |> assign(:empty_name, assigns.empty_icon || "check-circle")
      |> assign(:footer?, assigns.all_href != nil or assigns.preferences_href != nil)

    assigns =
      settle(assigns, changed0,
        root_attrs: [:inline, :id],
        unread_n: [:unread, :items],
        tab_list: [:variant, :tabs, :items, :count_tone, :unread],
        stream_rows: [:items],
        rows: [:items],
        empty_c: [:empty_tone],
        empty_name: [:empty_icon],
        footer?: [:all_href, :preferences_href]
      )

    panel(assigns)
  end

  # `sm` reuses the top bar button of `navbar_bell` (`Shell.tbtn_classes/1`)
  defp bell_class("sm"), do: LedgerUI.Components.Shell.tbtn_classes(size: :sm)
  defp bell_class(_), do: @bell

  defp panel(%{items: []} = assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, pop: @pop, icon_class: @empty_icon)
    assigns = settle(assigns, changed0, pop: [], icon_class: [])

    ~H"""
    <div
      data-part="notification-panel"
      class={
        cx([@pop, @empty_c, "flex w-[220px] flex-col items-center gap-2 p-3.5 text-center", @class])
      }
      role="dialog"
      aria-label={@bell_label}
      {@root_attrs}
    >
      <span data-part="notification-empty-icon" class={@icon_class}><.icon
        name={@empty_name}
        size="md"
      /></span>
      <b data-part="notification-empty-title" class="text-[13.5px]">{@empty}</b>
      <span data-part="notification-empty-text" class="text-xs/4 text-muted">{@empty_text}</span>
      {render_slot(@empty_action)}
    </div>
    """
  end

  defp panel(%{variant: "classic"} = assigns) do
    changed0 = assigns.__changed__

    assigns =
      assign(assigns,
        pop: @pop,
        link: @link,
        icon_link: @icon_link,
        close_js:
          LedgerUI.close(assigns.id)
          |> Phoenix.LiveView.JS.focus(to: "#" <> assigns.id <> " [data-part=notification-bell]")
      )

    assigns = settle(assigns, changed0, pop: [], link: [], icon_link: [], close_js: [:id])

    ~H"""
    <div
      data-part="notification-panel"
      class={cx([@pop, "w-[380px] p-0", @class])}
      role="dialog"
      aria-label={@title}
      {@root_attrs}
    >
      <div data-part="notification-header" class="flex flex-wrap items-center gap-2.5 px-3.5 pt-3">
        <b data-part="notification-heading">{@title}</b>
        <span data-part="notification-spacer" class="min-w-0 flex-1"></span>
        <button
          :if={@on_read_all}
          data-part="notification-read-all"
          class={@link}
          type="button"
          data-lu-read-all=""
        >
          {@read_all_label}
        </button>
        {render_slot(@actions)}
        <button
          :if={@closable and not @inline}
          data-part="notification-close"
          class={@icon_link}
          type="button"
          aria-label={@close_label}
          phx-click={@close_js}
        >
          <.icon name="x" />
        </button>
      </div>
      <div :if={@tab_list != []} data-part="notification-tabs-wrap" class="px-3.5">
        <div
          data-part="notification-tabs"
          class="flex gap-[22px] border-b border-line"
          data-lu-single=""
          role="tablist"
        >
          <button
            :for={{t, i} <- Enum.with_index(@tab_list)}
            data-part="notification-tab"
            class={t.class}
            role="tab"
            aria-selected={Support.flag(i == 0)}
            type="button"
            data-lu-tab={t.id}
            data-lu-empty={t.empty}
          >
            {t.label}
            <span :if={t.count > 0} data-part="notification-tab-badge" class={t.badge_class}>{t.count}</span>
          </button>
        </div>
      </div>
      <div
        :if={@stream_rows}
        id={@id <> "-rows"}
        data-part="notification-rows"
        phx-update="stream"
      >
        <.classic_row :for={{dom_id, item} <- @stream_rows} id={dom_id} item={item} first?={false} />
      </div>
      <.classic_row :for={{item, _, first?, key} <- @rows} :key={key} item={item} first?={first?} />
      <div
        :if={@footer?}
        data-part="notification-footer"
        class="flex flex-wrap items-center gap-2.5 border-t border-line px-3.5 py-2.5"
      >
        <span data-part="notification-unread" class="text-xs/4 text-muted">{@unread_n} {@unread_label}</span>
        <span data-part="notification-spacer" class="min-w-0 flex-1"></span>
        <a :if={@all_href} data-part="notification-link" class={@link} href={@all_href}>{@all_label}</a>
        <a
          :if={@preferences_href}
          data-part="notification-link"
          class={@icon_link}
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
    changed0 = assigns.__changed__
    assigns = assign(assigns, pop: @pop, label_class: @label)
    assigns = settle(assigns, changed0, pop: [], label_class: [])

    ~H"""
    <div
      data-part="notification-panel"
      class={cx([@pop, "w-[360px] p-1.5", @class])}
      role="dialog"
      aria-label={@bell_label}
      {@root_attrs}
    >
      <div :if={@stream_rows} id={@id <> "-rows"} data-part="notification-rows" phx-update="stream">
        <.canvas_row
          :for={{dom_id, item} <- @stream_rows}
          id={dom_id}
          item={item}
          group={nil}
          label_class={@label_class}
        />
      </div>
      <.canvas_row
        :for={{item, group, _, key} <- @rows}
        :key={key}
        item={item}
        group={group}
        label_class={@label_class}
      />
    </div>
    """
  end

  attr :id, :string, default: nil
  attr :item, :map, required: true
  attr :group, :any, default: nil
  attr :label_class, :string, required: true

  defp canvas_row(assigns) do
    ~H"""
    <div :if={@group} data-part="notification-group" class={@label_class} role="presentation">
      {@group}
    </div>
    <.row_tag
      id={@id}
      item={@item}
      class={
        cx([
          "flex items-start gap-2.5 rounded-md px-3 py-2.5",
          !@item[:read] && "bg-[color-mix(in_oklab,var(--lu-accent-soft)_60%,transparent)]"
        ])
      }
    >
      <span
        data-part="notification-dot"
        class={["mt-1.5 inline-block size-[7px] flex-none rounded-full bg-current", dot_class(@item)]}
      ></span>
      <span
        data-part="notification-text"
        class="min-w-0 flex-1 text-[13px]/[18px] text-ink-2 [&_b]:font-semibold [&_b]:text-ink"
      ><%= if @item[:text] do %>
        {@item[:text]}
      <% else %>
        <b data-part="notification-strong">{@item.title}</b> {@item[:body]}
      <% end %></span>
      <time
        :if={@item[:at]}
        data-part="notification-time"
        class="font-mono text-[11.5px] whitespace-nowrap text-muted"
      >{@item[:at]}</time>
    </.row_tag>
    """
  end

  attr :id, :string, default: nil
  attr :item, :map, required: true
  attr :first?, :boolean, required: true

  defp classic_row(assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :tints, @tints)
    assigns = settle(assigns, changed0, tints: [])

    ~H"""
    <.row_tag
      id={@id}
      item={@item}
      class={
        cx([
          "flex flex-nowrap items-start gap-3 px-3.5 py-3",
          if(@first?, do: "border-t-0", else: "border-t border-line"),
          @id && "first:border-t-0"
        ])
      }
    >
      <span
        data-part="notification-dot"
        class={[
          "mt-3.5 size-1.5 rounded-full",
          if(@item[:read], do: "bg-transparent", else: "bg-(--lu-accent)")
        ]}
      ></span>
      <%= cond do %>
        <% @item[:avatar] -> %>
          <span
            data-part="notification-avatar"
            class={[
              "relative inline-grid size-8 flex-none place-items-center rounded-full text-[calc(32px*.36)] font-semibold tracking-[-.01em]",
              @tints[to_string(@item.avatar[:tint] || "t1")] || "bg-sunken text-ink-2"
            ]}
          >{@item.avatar[:initials]}</span>
        <% tile(@item) -> %>
          <.icon name={tile(@item)} size="md" boxed tone={tone(@item) || "neutral"} />
        <% true -> %>
      <% end %>
      <div data-part="notification-body" class="flex min-w-0 flex-1 flex-col gap-0.5">
        <span
          data-part="notification-title"
          class={["text-[13px]/[18px]", if(@item[:read], do: "font-normal", else: "font-semibold")]}
        >{@item.title}</span>
        <span :if={@item[:body]} data-part="notification-text-body" class="text-xs/4 text-muted">{@item[
          :body
        ]}</span>
        <span data-part="notification-at" class="text-xs/4 text-muted">{@item[:at]}</span>
      </div>
    </.row_tag>
    """
  end

  attr :id, :string, default: nil
  attr :item, :map, required: true
  attr :class, :any, default: nil
  slot :inner_block, required: true

  defp row_tag(%{item: %{navigate: to}} = assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :link_attrs, LedgerUI.LinkAttrs.resolve(%{navigate: to}))
    assigns = settle(assigns, changed0, link_attrs: [:item])

    ~H"""
    <a
      id={@id}
      data-part="notification-item"
      class={@class}
      {@link_attrs}
      {item_attrs(@item)}
    >{render_slot(@inner_block)}</a>
    """
  end

  defp row_tag(%{item: %{patch: to}} = assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :link_attrs, LedgerUI.LinkAttrs.resolve(%{patch: to}))
    assigns = settle(assigns, changed0, link_attrs: [:item])

    ~H"""
    <a
      id={@id}
      data-part="notification-item"
      class={@class}
      {@link_attrs}
      {item_attrs(@item)}
    >{render_slot(@inner_block)}</a>
    """
  end

  defp row_tag(%{item: %{href: to}} = assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :link_attrs, LedgerUI.LinkAttrs.resolve(%{href: to}))
    assigns = settle(assigns, changed0, link_attrs: [:item])

    ~H"""
    <a
      id={@id}
      data-part="notification-item"
      class={@class}
      {@link_attrs}
      {item_attrs(@item)}
    >{render_slot(@inner_block)}</a>
    """
  end

  defp row_tag(assigns) do
    ~H"""
    <div id={@id} data-part="notification-item" class={@class} {item_attrs(@item)}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp item_attrs(item) do
    %{
      "data-lu-item" => item[:id],
      "data-lu-cat" => item[:category],
      "data-lu-read" => Support.flag(item[:read])
    }
  end

  defp tab(%{id: id} = t, items, default_tone, unread) do
    count = t[:count] || count_of(id, items, unread)

    tone = t[:count_tone] || default_tone
    tone = @tab_badge_alias[tone] || tone

    {class, badge_class} =
      case @tab_badge_on[tone] do
        nil -> {@tab, @tab_badge}
        on -> {@tab_group, [@tab_badge_idle, on]}
      end

    %{
      id: id,
      label: t.label,
      empty: t[:empty],
      count: count,
      class: class,
      badge_class: badge_class
    }
  end

  defp tone(item), do: item[:tone] || @tones[item[:type]]

  defp tile(item), do: item[:icon] || @type_icons[item[:type]]

  defp dot_class(item), do: [@dot_colors[item[:type]], item[:read] && "opacity-0"]

  # What a tab counts when its map has no `count`: from the list, or (a stream) from `unread`.
  defp count_of(id, %LiveStream{}, unread) do
    case id do
      "all" ->
        0

      "unread" ->
        unread

      other ->
        raise ArgumentError,
              "notification_center with a stream needs the `count` of the tab #{inspect(other)}"
    end
  end

  defp count_of("all", _items, _unread), do: 0
  defp count_of("unread", items, _unread), do: Enum.count(items, &(!&1[:read]))

  defp count_of(cat, items, _unread),
    do: Enum.count(items, &(!&1[:read] and &1[:category] == cat))

  defp unread(nil, %LiveStream{}) do
    raise ArgumentError,
          "notification_center with a stream (`items={@streams.x}`) needs `unread`: " <>
            "the list cannot be counted"
  end

  defp unread(nil, items), do: Enum.count(items, &(!&1[:read]))
  defp unread(unread, _items), do: unread

  # `{item, group, first?, key}` for each row. `group` is the day heading drawn before the row (when it
  # differs from the previous row's); `key` is the `id` of the item (its position when the ids are
  # missing or repeat), for `:key`.
  defp rows(items) do
    {rows, _} =
      items
      |> Enum.with_index()
      |> Enum.map_reduce(:none, fn {item, i}, prev ->
        g = item[:group]
        {{item, if(g != nil and g != prev, do: g), i == 0, item[:id] || {:row, i}}, g || prev}
      end)

    keys = Enum.map(rows, &elem(&1, 3))

    if keys == Enum.uniq(keys),
      do: rows,
      else: rows |> Enum.with_index() |> Enum.map(fn {row, i} -> put_elem(row, 3, {:row, i}) end)
  end
end
