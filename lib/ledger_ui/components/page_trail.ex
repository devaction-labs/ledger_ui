defmodule LedgerUI.Components.PageTrail do
  @moduledoc """
  `page_trail/1`: the screen tabs of the navbar. Pinned screens first (pin icon), a divider, then
  the recent ones (clock icon, lighter text); the current screen gets the panel surface and an
  accent stroke. A recent item has a pin button, a pinned one an `x` to unpin (the space is always reserved; the button shows on hover, on focus and on touch screens). What does
  not fit goes into a `+N` button that opens a menu with everything ("Pinned (2 of 6)", "Recent"
  with "Clear").

      <.page_trail id="trail" trail={@page_trail} max={4} max_pinned={6} />

  Put `{LedgerUI.PageTrail, :default}` in the `on_mount` of the `live_session` of your router and,
  in a LiveView, call `LedgerUI.PageTrail.put_page(socket, icon: "users")` after assigning the
  `:page_title`.

  The data and the events are handled by the `on_mount` of `LedgerUI.PageTrail`: pin, unpin, clear
  and restore need no code in your LiveViews. Read that module for what is remembered (the last full
  URL of each screen, so a pinned tab opens in its last state), the per-screen snapshot
  (`put_state/2`), the scroll position, the validation of what comes back from the browser and
  `on_change`.

  The hook `LedgerUI.PageTrail` (`priv/static/ledger_ui/hooks/page_trail.js`) keeps the trail in
  `localStorage` under `key` (default `"lu:trail"`), the snapshot and the scroll position of each
  screen in `sessionStorage` (`state_storage="local"` for `localStorage`) and gives them back on mount.

  > #### Not a place for secrets {: .warning}
  > Paths, query strings, labels, snapshots and scroll positions stay in the browser (readable by any
  > script of the page and by the user; in `localStorage` they outlive the tab). Never put tokens or
  > personal data in the URL of a screen or in `put_state/2`, and on a shared machine scope `key` per
  > user (`key={"lu:trail:\#{@current_user.id}"}`). What comes back is user input and the server
  > validates every item (relative path, a route of the router, capped lengths).

  ## Look

    * `variant="compact"`: icons only (the icon of each page, `put_page(icon:)`), the label is the
      `title` and an `sr-only` text.
    * `recent={0}` hides (and does not store) the recents.
    * `max` is how many items the bar shows (the current one always among them); the rest is the `+N` menu.
    * `max_pinned` (default 6) is the limit of pins: at the limit the pin buttons disappear and the
      menu says "Unpin one to pin another".
    * With nothing pinned and at most one recent, the bar shows the current page and the hint "Pin the
      pages you use most"; with no page at all it shows "Home".

  `demo` draws the same markup without the hook and without events, for documentation pages that are not
  inside a LiveView with the `on_mount`.

  Styled only with Tailwind utilities; elements carry `data-part` (`page-trail`, `page-trail-item`,
  `page-trail-action`, `page-trail-sep`, `page-trail-hint`, `page-trail-more`, `page-trail-menu`...).
  """
  use LedgerUI.Component

  @ledger_ui_event_guard true

  alias LedgerUI.Components.Dropdown

  @item "group relative inline-flex h-8 items-center rounded-md border text-[13.5px] font-medium whitespace-nowrap"
  @tone %{
    {:pinned, false} => "border-transparent text-ink-2 hover:bg-hover",
    {:recent, false} => "border-transparent text-muted hover:bg-hover",
    {:pinned, true} =>
      "border-line bg-panel text-ink shadow-xs after:absolute after:inset-x-2.5 after:-bottom-[9px] after:h-0.5 after:rounded-xs after:bg-accent after:content-['']",
    {:recent, true} =>
      "border-line bg-panel text-ink shadow-xs after:absolute after:inset-x-2.5 after:-bottom-[9px] after:h-0.5 after:rounded-xs after:bg-accent after:content-['']"
  }
  @action "mr-1 grid size-5 shrink-0 cursor-pointer place-items-center rounded-xs border-0 bg-transparent p-0 text-muted opacity-0 hover:bg-tray hover:text-ink focus-visible:opacity-100 group-focus-within:opacity-100 group-hover:opacity-100 pointer-coarse:opacity-100"
  @menu_row "group flex h-[34px] items-center rounded-md pr-1 text-[13.5px] text-ink hover:bg-hover"
  @menu_head "flex items-center justify-between px-2 pt-2 pb-1 text-[12px] font-medium text-muted"

  attr :id, :string, required: true, doc: "Needed by the hook."

  attr :trail, :any,
    default: nil,
    doc:
      "The `@page_trail` assign (`%{pinned: [item], recent: [item], current: path, state: map}`)."

  attr :max, :integer, default: 4, doc: "Items shown in the bar; the rest goes into `+N`."
  attr :max_pinned, :integer, default: 6, doc: "Limit of pinned items (at most 20)."
  attr :recent, :integer, default: 8, doc: "How many recents to show and keep; `0` hides them."
  attr :variant, :string, default: "default", values: ~w(default compact)
  attr :key, :string, default: "lu:trail", doc: "`localStorage` key; scope it per user."
  attr :state_storage, :string, default: "session", values: ~w(session local)
  attr :scroll, :boolean, default: true, doc: "Save and restore the scroll position."
  attr :scroll_container, :string, default: nil, doc: "CSS selector of the scrolling element."

  attr :on_change, :string,
    default: nil,
    doc: "Event pushed with `%{\"trail\" => trail}` on every change (sanitize it on arrival)."

  attr :demo, :boolean, default: false, doc: "No hook and no events (documentation)."

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  attr :label, :string, default: nil, doc: "`aria-label` of the bar."
  attr :home_label, :string, default: nil, doc: "Text of the empty bar."
  attr :hint, :string, default: nil, doc: "Hint of the empty bar."
  attr :pinned_label, :string, default: nil, doc: "Heading of the pinned group of the menu."
  attr :recent_label, :string, default: nil, doc: "Heading of the recent group of the menu."
  attr :clear_label, :string, default: nil, doc: "The \"Clear\" action."

  attr :pin_label, :string,
    default: nil,
    doc: "Pin button (`title` and start of the `aria-label`)."

  attr :unpin_label, :string, default: nil, doc: "Unpin button."
  attr :limit_hint, :string, default: nil, doc: "Hint shown at `max_pinned`."
  attr :saved_label, :string, default: nil, doc: "Footer of the menu."
  attr :more_label, :string, default: nil, doc: "`aria-label` of the `+N` button."
  attr :class, :any, default: nil, doc: "Layout only."
  attr :rest, :global

  def page_trail(assigns) do
    changed0 = assigns.__changed__

    assigns =
      I18n.texts(assigns,
        label: "page_trail.label",
        home_label: "page_trail.home",
        hint: "page_trail.hint",
        pinned_label: "page_trail.pinned",
        recent_label: "page_trail.recent",
        clear_label: "page_trail.clear",
        pin_label: "page_trail.pin",
        unpin_label: "page_trail.unpin",
        limit_hint: "page_trail.limit",
        saved_label: "page_trail.saved",
        more_label: "page_trail.more"
      )

    trail = assigns.trail || %{}
    max_pinned = assigns.max_pinned |> max(1) |> min(LedgerUI.PageTrail.max_pinned_cap())
    limit = assigns.recent |> max(0) |> min(LedgerUI.PageTrail.max_recent_cap())
    current = Map.get(trail, :current)
    pinned = Map.get(trail, :pinned, [])
    recent = trail |> Map.get(:recent, []) |> Enum.take(limit)
    all = Enum.map(pinned, &{:pinned, &1}) ++ Enum.map(recent, &{:recent, &1})
    visible = visible(all, max(assigns.max, 1), current)
    bar_pinned = for {:pinned, _} = e <- visible, do: e
    bar_recent = for {:recent, _} = e <- visible, do: e
    at_limit? = length(pinned) >= max_pinned

    assigns =
      assigns
      |> assign(:current, current)
      |> assign(:pinned, pinned)
      |> assign(:recent_items, recent)
      |> assign(:bar_pinned, bar_pinned)
      |> assign(:bar_recent, bar_recent)
      |> assign(:overflow, length(all) - length(visible))
      |> assign(:at_limit?, at_limit?)
      |> assign(:compact?, assigns.variant == "compact")
      |> assign(:max_pinned, max_pinned)
      |> assign(:empty?, all == [])
      |> assign(:home_class, [@item, @tone[{:recent, true}], "gap-[7px] px-2.5"])
      |> assign(:menu_head, @menu_head)
      |> assign(:menu_sep, Dropdown.separator_classes())
      |> assign(:hint?, pinned == [] and length(recent) <= 1)
      |> assign(
        :count_label,
        I18n.t("page_trail.pinned_count", assigns.locale, count: length(pinned), max: max_pinned)
      )
      |> assign(:json, Phoenix.json_library().encode!(LedgerUI.PageTrail.to_json(trail, limit)))
      |> assign(:state_json, state_json(Map.get(trail, :state)))
      |> assign(:hook, if(assigns.demo, do: nil, else: "LedgerUI.PageTrail"))
      |> assign(
        :storage,
        if(assigns.state_storage == "local", do: "local")
      )

    # `count_label` reads the process locale when `locale` is not given: it is not listed then.
    trail_src = [:trail, :recent]

    assigns =
      settle(
        assigns,
        changed0,
        [
          current: [:trail],
          pinned: [:trail],
          recent_items: trail_src,
          bar_pinned: [:trail, :recent, :max],
          bar_recent: [:trail, :recent, :max],
          overflow: [:trail, :recent, :max],
          at_limit?: [:trail, :max_pinned],
          compact?: [:variant],
          max_pinned: [],
          empty?: trail_src,
          home_class: [],
          menu_head: [],
          menu_sep: [],
          hint?: trail_src,
          json: trail_src,
          state_json: [:trail],
          hook: [:demo],
          storage: [:state_storage]
        ] ++
          if(assigns.locale,
            do: [count_label: [:trail, :recent, :max_pinned, :locale]],
            else: []
          )
      )

    ~H"""
    <nav
      id={@id}
      data-part="page-trail"
      aria-label={@label}
      phx-hook={@hook}
      data-lu-key={!@demo && @key}
      data-lu-trail={!@demo && @json}
      data-lu-path={!@demo && @current}
      data-lu-state={!@demo && @state_json}
      data-lu-state-storage={!@demo && @storage}
      data-lu-scroll={!@demo && !@scroll && "false"}
      data-lu-scroll-container={!@demo && @scroll_container}
      data-lu-on-change={!@demo && @on_change}
      class={cx(["flex min-w-0 items-center gap-0.5", @class])}
      {@rest}
    >
      <.trail_item
        :for={{kind, item} <- @bar_pinned}
        kind={kind}
        item={item}
        current={item.path == @current}
        compact={@compact?}
        at_limit={@at_limit?}
        max_pinned={@max_pinned}
        demo={@demo}
        pin_label={@pin_label}
        unpin_label={@unpin_label}
      />
      <span
        :if={@bar_pinned != [] and @bar_recent != []}
        data-part="page-trail-sep"
        aria-hidden="true"
        class="mx-1.5 h-[18px] w-px shrink-0 bg-line-strong"
      ></span>
      <.trail_item
        :for={{kind, item} <- @bar_recent}
        kind={kind}
        item={item}
        current={item.path == @current}
        compact={@compact?}
        at_limit={@at_limit?}
        max_pinned={@max_pinned}
        demo={@demo}
        pin_label={@pin_label}
        unpin_label={@unpin_label}
      />
      <span
        :if={@empty?}
        data-part="page-trail-item"
        data-kind="recent"
        aria-current="page"
        class={@home_class}
      >
        <.icon name="home" size="sm" class="shrink-0 text-muted" />
        <span :if={!@compact?}>{@home_label}</span>
        <span :if={@compact?} class="sr-only">{@home_label}</span>
      </span>
      <span
        :if={@hint? and !@compact?}
        data-part="page-trail-hint"
        class="ml-1.5 inline-flex h-8 items-center gap-[7px] rounded-md border border-dashed border-line-strong px-3 text-[13px] whitespace-nowrap text-muted"
      >
        <.icon name="pin" size="sm" class="shrink-0" />{@hint}
      </span>
      <Dropdown.dropdown
        :if={@overflow > 0}
        id={@id <> "-more"}
        placement="bottom-end"
        menu_style="width:330px"
        anchor_class="ml-0.5"
        locale={@locale}
      >
        <:toggle :let={t}>
          <button
            type="button"
            data-part="page-trail-more"
            aria-label={@more_label}
            class="inline-flex h-8 cursor-pointer items-center gap-1 rounded-md border border-line bg-transparent px-2 font-mono text-[12.5px] font-medium text-muted hover:bg-hover aria-expanded:border-line-strong aria-expanded:bg-panel aria-expanded:text-ink"
            {t}
          >
            +{@overflow}<.icon :if={!@compact?} name="chevron-down" size="sm" />
          </button>
        </:toggle>
        <div data-part="page-trail-menu-head" role="presentation" class={@menu_head}>
          <span>{@pinned_label}</span>
          <span>{@count_label}</span>
        </div>
        <div
          :if={@at_limit?}
          data-part="page-trail-limit"
          role="presentation"
          class="px-2 pb-1 text-[11.5px] text-muted"
        >
          {@limit_hint}
        </div>
        <.menu_row
          :for={item <- @pinned}
          kind={:pinned}
          item={item}
          at_limit={@at_limit?}
          max_pinned={@max_pinned}
          demo={@demo}
          pin_label={@pin_label}
          unpin_label={@unpin_label}
        />
        <div role="separator" class={@menu_sep}></div>
        <div data-part="page-trail-menu-head" role="presentation" class={@menu_head}>
          <span>{@recent_label}</span>
          <button
            :if={@recent_items != []}
            type="button"
            role="menuitem"
            data-part="page-trail-clear"
            phx-click={!@demo && "lu:trail:clear"}
            class="inline-flex cursor-pointer items-center gap-1 rounded-xs border-0 bg-transparent p-0 text-[12px] text-muted hover:text-ink"
          >
            <.icon name="trash" size="sm" />{@clear_label}
          </button>
        </div>
        <.menu_row
          :for={item <- @recent_items}
          kind={:recent}
          item={item}
          at_limit={@at_limit?}
          max_pinned={@max_pinned}
          demo={@demo}
          pin_label={@pin_label}
          unpin_label={@unpin_label}
        />
        <div role="separator" class={@menu_sep}></div>
        <div
          data-part="page-trail-saved"
          role="presentation"
          class="flex items-center gap-1.5 px-2 pt-1.5 pb-1 text-[11.5px] text-muted"
        >
          <.icon name="clock" size="sm" class="shrink-0" />{@saved_label}
        </div>
      </Dropdown.dropdown>
    </nav>
    """
  end

  # `all` is `[{kind, item}]`: the first `max` of them, with the current one always among them.
  defp visible(all, max, current) do
    if length(all) <= max do
      all
    else
      shown = Enum.take(all, max)

      with true <- current != nil,
           false <- Enum.any?(shown, fn {_, i} -> i.path == current end),
           {_, _} = cur <- Enum.find(all, fn {_, i} -> i.path == current end) do
        List.replace_at(shown, -1, cur)
      else
        _ -> shown
      end
    end
  end

  defp state_json(nil), do: nil

  defp state_json(state) do
    case Phoenix.json_library().encode(state) do
      {:ok, json} -> json
      _ -> nil
    end
  end

  attr :kind, :atom, required: true
  attr :item, :map, required: true
  attr :current, :boolean, required: true
  attr :compact, :boolean, required: true
  attr :at_limit, :boolean, required: true
  attr :max_pinned, :integer, required: true
  attr :demo, :boolean, required: true
  attr :pin_label, :string, required: true
  attr :unpin_label, :string, required: true

  defp trail_item(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:class, [
        @item,
        @tone[{assigns.kind, assigns.current}]
      ])
      |> assign(:lead, lead_icon(assigns))
      |> assign(:text, action_label(assigns.kind, assigns))
      |> assign(:event, action_event(assigns.kind))
      |> assign(:action_class, @action)
      |> assign(
        :lead_class,
        if(assigns.kind == :pinned and !assigns.current, do: "text-ink", else: "text-current")
      )

    assigns =
      settle(assigns, changed0,
        class: [:kind, :current],
        lead: [:compact, :kind, :item],
        text: [:kind, :unpin_label, :pin_label],
        event: [:kind],
        action_class: [],
        lead_class: [:kind, :current]
      )

    ~H"""
    <div data-part="page-trail-item" data-kind={@kind} class={@class}>
      <.link
        navigate={@item.href}
        aria-current={@current && "page"}
        title={@compact && @item.label}
        class="flex h-full items-center gap-[7px] rounded-md px-2.5 text-inherit no-underline outline-none focus-visible:ring-2 focus-visible:ring-accent"
      >
        <.icon name={@lead} size="sm" class={["shrink-0", @lead_class]} />
        <span :if={!@compact}>{@item.label}</span>
        <span :if={@compact} class="sr-only">{@item.label}</span>
      </.link>
      <button
        :if={@kind == :pinned or !@at_limit}
        type="button"
        data-part="page-trail-action"
        aria-label={@text <> " " <> @item.label}
        title={@text}
        phx-click={!@demo && @event}
        phx-value-path={!@demo && @item.path}
        phx-value-max_pinned={!@demo && @kind == :recent && @max_pinned}
        class={@action_class}
      >
        <.icon name={if @kind == :pinned, do: "x", else: "pin"} size="sm" />
      </button>
    </div>
    """
  end

  # normal variant: the pin / the clock; compact: the icon of the page itself
  defp lead_icon(%{compact: true, item: item}), do: item.icon
  defp lead_icon(%{kind: :pinned}), do: "pin"
  defp lead_icon(_), do: "clock"

  defp action_label(:pinned, a), do: a.unpin_label
  defp action_label(_, a), do: a.pin_label

  defp action_event(:pinned), do: "lu:trail:unpin"
  defp action_event(_), do: "lu:trail:pin"

  attr :kind, :atom, required: true
  attr :item, :map, required: true
  attr :at_limit, :boolean, required: true
  attr :max_pinned, :integer, required: true
  attr :demo, :boolean, required: true
  attr :pin_label, :string, required: true
  attr :unpin_label, :string, required: true

  defp menu_row(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:text, action_label(assigns.kind, assigns))
      |> assign(:event, action_event(assigns.kind))
      |> assign(:row_class, @menu_row)

    assigns =
      settle(assigns, changed0,
        text: [:kind, :unpin_label, :pin_label],
        event: [:kind],
        row_class: []
      )

    ~H"""
    <div data-part="page-trail-menu-row" data-kind={@kind} role="none" class={@row_class}>
      <.link
        navigate={@item.href}
        role="menuitem"
        class="flex h-full min-w-0 flex-1 items-center gap-[9px] rounded-md pl-2 text-inherit no-underline outline-none"
      >
        <.icon name={@item.icon} size="md" class="shrink-0 text-ink-2" />
        <span class="truncate">{@item.label}</span>
        <span class="ml-auto truncate pl-2 font-mono text-[11.5px] text-muted">{@item.path}</span>
      </.link>
      <button
        :if={@kind == :pinned or !@at_limit}
        type="button"
        role="menuitem"
        data-part="page-trail-action"
        aria-label={@text <> " " <> @item.label}
        title={@text}
        phx-click={!@demo && @event}
        phx-value-path={!@demo && @item.path}
        phx-value-max_pinned={!@demo && @kind == :recent && @max_pinned}
        class="ml-1.5 grid size-[22px] shrink-0 cursor-pointer place-items-center rounded-sm border-0 bg-transparent p-0 text-muted hover:bg-tray hover:text-ink"
      >
        <.icon name={if @kind == :pinned, do: "x", else: "pin"} size="sm" />
      </button>
    </div>
    """
  end
end
