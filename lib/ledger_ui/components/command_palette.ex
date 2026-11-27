defmodule LedgerUI.Components.CommandPalette do
  @moduledoc """
  A dialog opened with Ctrl K (or `LedgerUI.open/1`) where the person types, narrows the results
  by scope and jumps to a page or runs an action from the keyboard (`<.command_palette>`).

      <.command_palette
        id="palette"
        scopes={[{"All", "all"}, {"Pages", "pages"}, {"Actions", "actions"}]}
        items={[
          %{group: "Go to", scope: "pages", label: "Orders", icon: "cart", navigate: "/orders", keys: ["G", "O"]},
          %{group: "Actions", scope: "actions", label: "New order", icon: "plus", value: "new-order"}
        ]}
        assistant={%{label: "Ask the assistant: “%{query}”", sub: "Answers with your data"}}
        on_select="palette-select"
      />

      <.button phx-click={LedgerUI.open("palette")}>Search</.button>

  The palette is a modal: `LedgerUI.open/close/toggle`, `open`, `on_open` and `on_close` work as for
  `LedgerUI.Components.Modal`, and `shortcut` toggles it from anywhere. The items are filtered in the
  browser by label, `sub` and `keywords` (ignoring case and accents) and by scope; with `on_search`
  the server filters instead. Arrows move the active row, Enter presses it, Ctrl Enter opens a link
  in a new tab and Esc closes. The behaviour comes from the `LedgerUI.Overlay` hook
  (`priv/static/ledger_ui/hooks/overlay.js`); the ARIA is rendered by the server: the card is a
  `role="dialog"` (`aria-modal`, `aria-label`), the input a `role="combobox"` with
  `aria-controls`/`aria-expanded`/`aria-autocomplete`, the list a `role="listbox"` and the rows
  `role="option"` with stable ids (`"\#{id}-opt-N"`); the hook only moves `aria-selected` and
  `aria-activedescendant`. The static previews (`inline`/`bare`) keep the design's `menuitem` rows.

  Each item is a map with `label` (required) and optionally `value` (what `on_select` receives),
  `sub`, `icon`, `avatar` (`%{initials: "CD", tint: "#d97a1e"}`), `keys` (key names on the right),
  `count` (a badge), `group`, `scope`, `keywords`, `style` and one of `navigate`, `patch` or `href`.

  Events (`on_select`: `%{"id", "value", "new_tab"}`, `on_assistant`: `%{"id", "query"}`,
  `on_search`: `%{"id", "query", "scope"}`, `on_open`/`on_close`: `%{"id"}`) take an event name or a
  `%JS{}` and go to `target` when given.

  ## `defer_items`: a lighter page

  The rows are the heaviest part of the palette (about 2.8 KB of HTML per item, sent in every mount
  even when the palette is closed; 40 items are ~116 KB). With `defer_items` the server sends only
  the shell, one compact JSON with the items (label, link, icon name, scope...) and one `<template>`
  per distinct icon (not per item); the hook builds the rows in the browser when the palette opens,
  so the filter, the keyboard and the highlight work as before. Use it when the palette sits in the
  layout and holds many items (a navigation index); a palette with a few items gains nothing.
  `item_icon` is not available in this mode (with the slot the rows are rendered by the server as
  usual). The default is `false` and renders exactly the same HTML as before.

      <.command_palette id="palette" items={@pages} defer_items />

  `inline` renders the dialog over its own in-page scrim (a static preview, always open, no hook);
  `bare` renders only the `lu-cmd` card.
  """
  use LedgerUI.Component
  alias LedgerUI.Components.Modal.Support

  # the backdrop: closed = `hidden`; open (the `open` class LedgerUI.open sets, or data-state="open") and
  # closing (the hook plays the leave animation while it is `closing`) are `flex`
  @scrim_hooked "fixed inset-0 z-[var(--ledger-z-modal,60)] hidden items-start justify-center overflow-hidden rounded-none bg-overlay px-7 pt-[12vh] pb-7 " <>
                  "data-[state=open]:flex data-[state=closing]:pointer-events-none data-[state=closing]:flex [&.open]:flex"
  @scrim_inline "relative flex items-center justify-center overflow-hidden rounded-lg bg-overlay p-7"
  @card "w-[560px] max-w-full overflow-hidden border border-line bg-panel shadow-lg"
  @input_row "flex h-[52px] items-center gap-2.5 border-b border-line px-4"
  @input "min-w-0 flex-1 border-0 bg-transparent px-0.5 py-px text-base outline-0"
  @kbd "inline-flex h-[22px] min-w-[22px] items-center justify-center rounded-sm border border-line-strong bg-panel px-1.5 font-mono text-[11.5px] leading-none text-ink-2 shadow-[inset_0_-1px_0_var(--lu-line)]"
  @chip "inline-flex h-[30px] cursor-pointer items-center gap-1.5 rounded-md border border-line-strong bg-panel px-[11px] text-[13px] font-medium text-ink-2 " <>
          "aria-[pressed=false]:hover:bg-hover aria-pressed:border-inverse aria-pressed:bg-inverse aria-pressed:text-on-inverse"
  @label "px-2.5 pt-2 pb-1 text-[11.5px] font-medium tracking-[.06em] text-muted uppercase"
  @item "flex h-[34px] w-full cursor-pointer items-center gap-2.5 rounded-md border-0 bg-transparent px-2.5 text-left text-sm text-ink-2 [&_svg]:size-4 [&_svg]:text-ink " <>
          "hover:bg-hover hover:text-ink data-[lu-hl]:bg-hover data-[lu-hl]:text-ink focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] focus-visible:outline-none"
  @keys "ml-auto flex items-center gap-1 text-[12px] text-muted"
  @count "inline-grid h-4 min-w-[18px] place-items-center rounded-[5px] bg-neg px-[5px] text-[11px] font-semibold text-white tabular-nums"
  @avatar "relative inline-grid size-6 flex-none place-items-center rounded-[30%] text-[calc(24px*.36)] font-semibold tracking-[-.01em] text-ink-2"
  @sub "ml-2 text-xs/4 text-muted"
  @footer "flex gap-3.5 border-t border-line bg-tray px-3.5 py-[9px] text-[12px] text-muted"

  attr :id, :string, required: true
  attr :open, :boolean, default: false
  attr :label, :string, default: nil
  attr :placeholder, :string, default: nil
  attr :scopes, :list, default: []
  attr :scopes_label, :string, default: nil
  attr :items, :list, default: []
  attr :empty, :string, default: nil
  attr :assistant, :map, default: nil
  attr :assistant_mode, :string, default: "no_match", values: ~w(no_match always)
  attr :on_select, :any, default: nil
  attr :on_assistant, :any, default: nil
  attr :on_search, :string, default: nil
  attr :debounce, :integer, default: 200
  attr :query, :string, default: ""
  attr :on_open, :any, default: nil
  attr :on_close, :any, default: nil
  attr :target, :any, default: nil
  attr :shortcut, :any, default: "Mod+k"
  attr :variant, :string, default: "canvas", values: ~w(canvas classic)
  attr :hints, :boolean, default: true
  attr :highlight, :string, default: "always", values: ~w(always typed)
  attr :hint_navigate, :string, default: nil
  attr :hint_open, :string, default: nil
  attr :hint_new_tab, :any, default: nil
  attr :hint_close, :string, default: nil

  attr :state, :string,
    default: nil,
    values: [nil, "no_match"],
    doc:
      "`\"no_match\"` draws only the empty-result card (the `empty` text and the assistant row, which the hook shows when nothing matches), a static preview."

  attr :class, :any, default: nil

  attr :list_style, :string,
    default: nil,
    doc: "Inline style of the list (replaces the variant padding)."

  attr :inline, :boolean,
    default: false,
    doc: "Static preview over an in-page scrim: always open, no hook."

  attr :bare, :boolean, default: false, doc: "Only the `lu-cmd` card, always open, no hook."

  attr :defer_items, :boolean,
    default: false,
    doc:
      "Opt-in: do not render the rows on the server (each one weighs ~2.8 KB of HTML in every mount, open or not); " <>
        "the hook builds them in the browser, the first time the palette opens, from a compact JSON and one `<template>` per distinct icon. " <>
        "Opening stays instant, the local filter, the keyboard and the highlight work as before. " <>
        "The `item_icon` slot is not available then (with the slot the rows are rendered by the server as usual); `inline` and `bare` ignore it. Default `false`: the HTML is unchanged."

  attr :rest, :global

  slot :footer
  slot :item_icon

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def command_palette(%{state: "no_match"} = assigns) do
    assigns =
      I18n.texts(assigns,
        label: "cmd.label",
        placeholder: "cmd.placeholder",
        scopes_label: "cmd.scopes",
        empty: "cmd.empty",
        hint_navigate: "cmd.navigate",
        hint_open: "cmd.open",
        hint_new_tab: "cmd.new_tab",
        hint_close: "common.close"
      )

    assistant = assigns.assistant
    label = assistant && String.replace(assistant[:label] || "", "%{query}", assigns.query)

    assigns =
      assigns
      |> assign(:item_class, @item)
      |> assign(:assistant_label, label)

    ~H"""
    <div
      id={@id}
      data-part="palette"
      data-state="no_match"
      role="group"
      aria-label={@label}
      class={[
        "min-w-[220px] w-[280px] max-w-full rounded-lg border border-line bg-panel p-3.5 shadow-popover",
        @class
      ]}
      {@rest}
    >
      <span data-part="palette-empty" class="block pt-0.5 text-[13px]/[18px] text-muted">{@empty}</span>
      <div :if={@assistant} class="mt-2">
        <button type="button" data-part="palette-item" class={@item_class} role="menuitem">
          <.icon name={assistant_icon(@assistant)} />{@assistant_label}<span
            :if={@assistant[:sub]}
            data-part="palette-sub"
            class={sub_class()}
          >{@assistant[:sub]}</span>
        </button>
      </div>
    </div>
    """
  end

  def command_palette(assigns) do
    assigns =
      I18n.texts(assigns,
        label: "cmd.label",
        placeholder: "cmd.placeholder",
        scopes_label: "cmd.scopes",
        empty: "cmd.empty",
        hint_navigate: "cmd.navigate",
        hint_open: "cmd.open",
        hint_new_tab: "cmd.new_tab",
        hint_close: "common.close"
      )

    static? = assigns.inline or assigns.bare

    cfg =
      if static?,
        do: %{},
        else:
          Support.cfg("palette",
            open: Support.flag(assigns.open),
            "lock-scroll": "true",
            "on-open": Support.handler(assigns.on_open),
            "on-close": Support.handler(assigns.on_close),
            "on-select": Support.handler(assigns.on_select),
            "on-assistant": Support.handler(assigns.on_assistant),
            "on-search": assigns.on_search,
            debounce: assigns.debounce,
            shortcut: assigns.shortcut,
            highlight: assigns.highlight,
            "assistant-mode": assigns.assistant_mode,
            empty: assigns.empty,
            query: assigns.query,
            target: assigns.target
          )

    assigns =
      assigns
      |> assign(:cfg, cfg)
      |> assign(:root_class, if(assigns.inline, do: @scrim_inline, else: @scrim_hooked))
      |> assign(:hook, if(static?, do: nil, else: "LedgerUI.Overlay"))
      |> assign(:overlay_attr, if(static?, do: nil, else: ""))
      |> assign(:defer, !static? and assigns.defer_items and assigns.item_icon == [])
      |> assign(:state, if(!static?, do: if(assigns.open, do: "open", else: "closed")))

    assigns = assign(assigns, :defer_data, if(assigns.defer, do: defer_payload(assigns)))

    # The card (the rows) takes the attributes one by one, raw, and derives its own values: a render
    # that only changes the state of the root (`open`) does not send the rows again.
    if assigns.defer, do: palette_deferred(assigns), else: palette_markup(assigns)
  end

  # `defer_items`: the same root, without the rows, plus the data the hook builds them from.
  defp palette_deferred(assigns) do
    ~H"""
    <div
      id={@id}
      data-part="palette-overlay"
      class={@root_class}
      phx-hook={@hook}
      data-lu-overlay={@overlay_attr}
      data-state={@state}
      {@cfg}
      {@rest}
    >
      <.card_body
        id={@id}
        label={@label}
        placeholder={@placeholder}
        query={@query}
        scopes={@scopes}
        scopes_label={@scopes_label}
        items={@items}
        assistant={@assistant}
        variant={@variant}
        class={@class}
        list_style={@list_style}
        inline={@inline}
        bare={@bare}
        highlight={@highlight}
        hints={@hints}
        hint_navigate={@hint_navigate}
        hint_open={@hint_open}
        hint_new_tab={@hint_new_tab}
        hint_close={@hint_close}
        footer={@footer}
        item_icon={@item_icon}
        defer={true}
        rest={@rest}
      />
      <.defer_box id={@id} data={@defer_data} />
    </div>
    """
  end

  defp palette_markup(assigns) do
    ~H"""
    <%= if @bare do %>
      <.card_body
        id={@id}
        label={@label}
        placeholder={@placeholder}
        query={@query}
        scopes={@scopes}
        scopes_label={@scopes_label}
        items={@items}
        assistant={@assistant}
        variant={@variant}
        class={@class}
        list_style={@list_style}
        inline={@inline}
        bare={@bare}
        highlight={@highlight}
        hints={@hints}
        hint_navigate={@hint_navigate}
        hint_open={@hint_open}
        hint_new_tab={@hint_new_tab}
        hint_close={@hint_close}
        footer={@footer}
        item_icon={@item_icon}
        defer={false}
        rest={@rest}
      />
    <% else %>
      <div
        id={@id}
        data-part="palette-overlay"
        class={@root_class}
        phx-hook={@hook}
        data-lu-overlay={@overlay_attr}
        data-state={@state}
        {@cfg}
        {@rest}
      >
        <.card_body
          id={@id}
          label={@label}
          placeholder={@placeholder}
          query={@query}
          scopes={@scopes}
          scopes_label={@scopes_label}
          items={@items}
          assistant={@assistant}
          variant={@variant}
          class={@class}
          list_style={@list_style}
          inline={@inline}
          bare={@bare}
          highlight={@highlight}
          hints={@hints}
          hint_navigate={@hint_navigate}
          hint_open={@hint_open}
          hint_new_tab={@hint_new_tab}
          hint_close={@hint_close}
          footer={@footer}
          item_icon={@item_icon}
          defer={false}
          rest={@rest}
        />
      </div>
    <% end %>
    """
  end

  # The card: all the attributes it uses, raw (`rest` only matters when `bare`).
  defp card_body(assigns) do
    static? = assigns.inline or assigns.bare
    canvas? = assigns.variant == "canvas"

    root_attrs = if assigns.bare, do: %{"id" => assigns.id}, else: %{}

    card_attrs = %{
      "role" => "dialog",
      "aria-modal" => if(!static?, do: "true"),
      "aria-label" => assigns.label
    }

    assigns =
      assigns
      |> assign(:root_attrs, root_attrs)
      |> assign(:card_attrs, card_attrs)
      |> assign(
        :card_class,
        cx([@card, if(canvas?, do: "rounded-lg", else: "rounded-xl"), assigns.class])
      )
      |> assign(
        :list_class,
        cx(["max-h-[300px] overflow-auto", if(canvas?, do: "p-1", else: "p-1.5")])
      )
      |> assign(
        :list_attrs,
        if(assigns.list_style, do: %{"style" => assigns.list_style}, else: %{})
      )
      |> assign(:groups, groups(assigns.items, assigns.highlight))
      |> assign(:row_role, if(static?, do: "menuitem", else: "option"))
      |> assign(
        :list_aria,
        if(static?,
          do: %{},
          else: %{
            "id" => assigns.id <> "-list",
            "role" => "listbox",
            "aria-label" => assigns.label
          }
        )
      )
      |> assign(
        :combo,
        if(static?,
          do: %{},
          else: %{
            "role" => "combobox",
            "aria-controls" => assigns.id <> "-list",
            "aria-autocomplete" => "list",
            "aria-expanded" => "true"
          }
        )
      )
      |> assign(:scope_list, Enum.map(assigns.scopes, &scope/1))
      |> assign(:ft?, assigns.hints or assigns.footer != [])
      |> assign(:both?, assigns.hints and assigns.footer != [])
      |> assign(:static?, static?)
      |> assign(:input_row, @input_row)
      |> assign(:input_class, @input)
      |> assign(:kbd_class, @kbd)
      |> assign(:chip_class, @chip)
      |> assign(:label_class, @label)
      |> assign(:footer_class, @footer)

    # deferred: no rows (and no assistant row) from the server; the hook builds them from the data
    assigns =
      if assigns.defer,
        do: assigns |> assign(:groups, []) |> assign(:assistant, nil),
        else: assigns

    card(assigns)
  end

  defp card(assigns) do
    ~H"""
    <div
      data-part="palette"
      class={@card_class}
      {@root_attrs}
      {@card_attrs}
      {if @bare, do: @rest, else: %{}}
    >
      <div data-part="palette-search" class={@input_row}>
        <.icon name="search" />
        <input
          data-part="palette-input"
          class={@input_class}
          placeholder={@placeholder}
          value={@query}
          {@combo}
        />
        <kbd data-part="palette-kbd" class={@kbd_class}>Esc</kbd>
      </div>
      <div
        :if={@scope_list != []}
        data-part="palette-scopes"
        class="flex flex-wrap items-center gap-1.5 px-3 pt-2"
        role="group"
        aria-label={@scopes_label}
      >
        <button
          :for={{{label, value}, i} <- Enum.with_index(@scope_list)}
          type="button"
          data-part="palette-scope"
          class={@chip_class}
          aria-pressed={Support.flag(i == 0)}
          data-lu-scope={value}
        >
          {label}
        </button>
      </div>
      <div
        data-part="palette-list"
        class={@list_class}
        phx-update={@defer && "ignore"}
        {@list_attrs}
        {@list_aria}
      >
        <%= for {group, rows} <- @groups do %>
          <div :if={group} data-part="palette-label" class={@label_class} role="presentation">
            {group}
          </div>
          <%= for {item, hl, i} <- rows do %>
            <.row
              item={item}
              hl={hl}
              item_icon={@item_icon}
              role={@row_role}
              opt_id={!@static? && @id <> "-opt-" <> Integer.to_string(i)}
            />
          <% end %>
        <% end %>
        <button
          :if={@assistant}
          type="button"
          data-part="palette-item"
          class={item_class()}
          role={@row_role}
          hidden
          data-lu-assistant=""
          data-lu-label={@assistant[:label]}
        >
          <.icon name={assistant_icon(@assistant)} />{@assistant[:label]}<span
            :if={@assistant[:sub]}
            data-part="palette-sub"
            class={sub_class()}
          >{@assistant[:sub]}</span>
        </button>
      </div>
      <div :if={@ft?} data-part="palette-footer" class={@footer_class}>
        <%= if @hints do %>
          <span data-part="palette-hint">↑↓ {@hint_navigate}</span>
          <span data-part="palette-hint">↵ {@hint_open}</span>
          <span :if={@hint_new_tab} data-part="palette-hint">⌃↵ {@hint_new_tab}</span>
          <span data-part="palette-hint">esc {@hint_close}</span>
        <% end %>
        <span :if={@both?} data-part="palette-spacer" class="min-w-0 flex-1"></span>
        {render_slot(@footer)}
      </div>
    </div>
    """
  end

  defp row(%{item: %{navigate: to}} = assigns) do
    assigns = assign(assigns, :to, to)

    ~H"""
    <.link
      navigate={@to}
      data-part="palette-item"
      data-lu-hl={@hl && ""}
      class={item_class()}
      role={@role}
      id={@opt_id}
      style={@item[:style]}
      {row_attrs(@item)}
    >
      <.row_body item={@item} item_icon={@item_icon} />
    </.link>
    """
  end

  defp row(%{item: %{patch: to}} = assigns) do
    assigns = assign(assigns, :to, to)

    ~H"""
    <.link
      patch={@to}
      data-part="palette-item"
      data-lu-hl={@hl && ""}
      class={item_class()}
      role={@role}
      id={@opt_id}
      style={@item[:style]}
      {row_attrs(@item)}
    >
      <.row_body item={@item} item_icon={@item_icon} />
    </.link>
    """
  end

  defp row(%{item: %{href: to}} = assigns) do
    assigns = assign(assigns, :to, to)

    ~H"""
    <.link
      href={@to}
      data-part="palette-item"
      data-lu-hl={@hl && ""}
      class={item_class()}
      role={@role}
      id={@opt_id}
      style={@item[:style]}
      {row_attrs(@item)}
    >
      <.row_body item={@item} item_icon={@item_icon} />
    </.link>
    """
  end

  defp row(assigns) do
    ~H"""
    <button
      data-part="palette-item"
      data-lu-hl={@hl && ""}
      class={item_class()}
      role={@role}
      id={@opt_id}
      {Support.st(@item[:style])}
      type="button"
      {row_attrs(@item)}
    >
      <.row_body item={@item} item_icon={@item_icon} />
    </button>
    """
  end

  defp row_body(assigns) do
    assigns =
      assign(assigns,
        avatar_class: @avatar,
        kbd_class: @kbd,
        count_class: @count,
        keys_class: @keys,
        sub_class: @sub
      )

    ~H"""
    <%= cond do %>
      <% @item[:icon] -> %>
        <.icon name={@item[:icon]} />
      <% @item[:avatar] -> %>
        <span
          data-part="palette-avatar"
          class={[@avatar_class, !@item.avatar[:tint] && "bg-sunken"]}
          {Support.st(@item.avatar[:tint] && "background:" <> to_string(@item.avatar[:tint]))}
        >{@item.avatar[:initials]}</span>
      <% @item_icon != [] -> %>
        {render_slot(@item_icon, @item)}
      <% true -> %>
    <% end %>
    {@item.label}<span :if={@item[:sub]} data-part="palette-sub" class={@sub_class}>{@item[:sub]}</span><span
      :if={@item[:keys] || @item[:count]}
      data-part="palette-keys"
      class={@keys_class}
    ><kbd :for={k <- List.wrap(@item[:keys])} data-part="palette-kbd" class={@kbd_class}>{k}</kbd><span
      :if={@item[:count]}
      data-part="palette-count"
      class={@count_class}
    >{@item[:count]}</span></span>
    """
  end

  defp defer_box(%{data: data} = assigns) do
    assigns =
      assign(assigns,
        icons: Enum.map(data.icons, &{&1, icon_inner(&1)}),
        json: data.json,
        attrs: data.attrs
      )

    # The JSON is a script (type application/json, never run): its text needs no attribute escaping
    # (the quotes would cost 6 bytes each). The icon templates have an id, so a patch replaces them
    # instead of diffing the content of a <template>.
    ~H"""
    <div hidden data-part="palette-data" {@attrs}>
      <script type="application/json" data-part="palette-items">
        <%= @json %>
      </script>
      <template :for={{name, inner} <- @icons} id={@id <> "-ic-" <> name} data-lu-icon={name}>{inner}</template>
    </div>
    """
  end

  # The shapes of an icon, without the `<svg>` (its class and viewBox are the same for every icon: the
  # hook clones the `<svg>` of the search field); one distinct icon costs only its paths.
  defp icon_inner(name) do
    assigns = %{name: name}

    html =
      ~H"<.icon name={@name} />" |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()

    case Regex.run(~r/<svg[^>]*>(.*)<\/svg>/s, html) do
      [_, inner] -> {:safe, inner}
      _ -> ""
    end
  end

  # `defer_items`: what the hook needs to build the rows in the browser. The JSON uses short keys
  # (l label, v value, s sub, i icon, a avatar [initials, tint], k keys, c count, sc scope,
  # kw keywords, st style, n/p/h navigate/patch/href, g group heading before the row) and omits
  # what is empty; the row classes go once in `data-lu-c-*`, the icons in one `<template>` each.
  defp defer_payload(assigns) do
    {rows, static_icons} =
      assigns.items
      |> groups("typed")
      |> Enum.flat_map(fn {group, list} ->
        list
        |> Enum.with_index()
        |> Enum.map(fn {{item, _hl, _i}, n} -> {item, n == 0 && group} end)
      end)
      |> Enum.map_reduce([], fn {item, group}, icons ->
        icon = item[:icon]
        {defer_row(item, group), if(icon, do: [icon | icons], else: icons)}
      end)

    assistant = assigns.assistant
    a_icon = assistant && assistant_icon(assistant)

    payload =
      if assistant,
        do: %{r: rows, a: compact(%{l: assistant[:label], s: assistant[:sub], i: a_icon})},
        else: %{r: rows}

    used = fn key -> Enum.any?(rows, &Map.has_key?(&1, key)) end

    # only the classes of the parts the items use
    attrs =
      [
        {"data-lu-c-item", @item},
        {"data-lu-c-label", used.(:g) && @label},
        {"data-lu-c-avatar", used.(:a) && @avatar},
        {"data-lu-c-kbd", used.(:k) && @kbd},
        {"data-lu-c-keys", (used.(:k) or used.(:c)) && @keys},
        {"data-lu-c-count", used.(:c) && @count},
        {"data-lu-c-sub", (used.(:s) or (assistant != nil and assistant[:sub] != nil)) && @sub}
      ]
      |> Enum.filter(&elem(&1, 1))
      |> Map.new()

    %{
      icons: Enum.uniq(if(a_icon, do: [a_icon | static_icons], else: static_icons)),
      # `</`, `<!--` and `&` as \u00XX: safe inside a <script>
      json: {:safe, Jason.encode_to_iodata!(payload, escape: :html_safe)},
      attrs: attrs
    }
  end

  defp defer_row(item, group) do
    {kind, to} =
      cond do
        Map.has_key?(item, :navigate) -> {:n, item.navigate}
        Map.has_key?(item, :patch) -> {:p, item.patch}
        Map.has_key?(item, :href) -> {:h, item.href}
        true -> {:n, nil}
      end

    %{
      g: group,
      l: to_string(item.label),
      v: if(item[:value], do: to_string(item[:value])),
      s: item[:sub],
      i: item[:icon],
      a: if(!item[:icon] && item[:avatar], do: [item.avatar[:initials], item.avatar[:tint]]),
      k: if(item[:keys], do: item[:keys] |> List.wrap() |> Enum.map(&to_string/1)),
      c: item[:count],
      sc: item[:scope],
      kw: item[:keywords],
      st: item[:style]
    }
    |> compact()
    |> then(&if(to, do: Map.put(&1, kind, to), else: &1))
  end

  defp compact(map), do: map |> Enum.reject(fn {_, v} -> v in [nil, false] end) |> Map.new()

  defp item_class, do: @item
  defp sub_class, do: @sub

  defp row_attrs(item) do
    %{
      "data-lu-value" => to_string(item[:value] || item.label),
      "data-lu-scope" => item[:scope],
      "data-lu-keywords" => item[:keywords]
    }
  end

  defp assistant_icon(a), do: a[:icon] || "sparkles"

  defp scope({label, value}), do: {label, value}
  defp scope(%{label: label, value: value}), do: {label, value}
  defp scope(label) when is_binary(label), do: {label, label}

  # Items without a group come first (no heading); the groups keep their first-seen order.
  # The first row is marked active unless `highlight="typed"`.
  defp groups(items, highlight) do
    {ungrouped, grouped} = Enum.split_with(items, &(!&1[:group]))

    named =
      grouped
      |> Enum.chunk_by(& &1.group)
      |> Enum.map(&{hd(&1).group, &1})

    all = if ungrouped == [], do: named, else: [{nil, ungrouped} | named]

    {rows, _} =
      Enum.map_reduce(all, {highlight == "always", 0}, fn {group, list}, acc ->
        {list, acc} =
          Enum.map_reduce(list, acc, fn item, {first?, i} ->
            {{item, first?, i}, {false, i + 1}}
          end)

        {{group, list}, acc}
      end)

    rows
  end

  attr :id, :string, required: true
  attr :open, :boolean, default: false
  attr :label, :string, default: nil
  attr :placeholder, :string, default: nil
  attr :scopes, :list, default: []
  attr :scopes_label, :string, default: nil
  attr :items, :list, default: []
  attr :empty, :string, default: nil
  attr :assistant, :map, default: nil
  attr :assistant_mode, :string, default: "no_match", values: ["no_match", "always"]
  attr :on_select, :any, default: nil
  attr :on_assistant, :any, default: nil
  attr :on_search, :string, default: nil
  attr :debounce, :integer, default: 200
  attr :query, :string, default: ""
  attr :on_open, :any, default: nil
  attr :on_close, :any, default: nil
  attr :target, :any, default: nil
  attr :shortcut, :any, default: "Mod+k"
  attr :variant, :string, default: "canvas", values: ["canvas", "classic"]
  attr :hints, :boolean, default: true
  attr :highlight, :string, default: "always", values: ["always", "typed"]
  attr :hint_navigate, :string, default: nil
  attr :hint_open, :string, default: nil
  attr :hint_new_tab, :any, default: nil
  attr :hint_close, :string, default: nil

  attr :state, :string,
    default: nil,
    values: [nil, "no_match"],
    doc:
      "`\"no_match\"` draws only the empty-result card (the `empty` text and the assistant row, which the hook shows when nothing matches), a static preview."

  attr :class, :any, default: nil

  attr :list_style, :string,
    default: nil,
    doc: "Inline style of the list (replaces the variant padding)."

  attr :inline, :boolean,
    default: false,
    doc: "Static preview over an in-page scrim: always open, no hook."

  attr :bare, :boolean, default: false, doc: "Only the `lu-cmd` card, always open, no hook."

  attr :defer_items, :boolean,
    default: false,
    doc: "See `command_palette/1`: the rows are built by the hook, not rendered by the server."

  attr :rest, :global
  slot :footer
  slot :item_icon

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  @doc "Same as `command_palette/1` (same attributes and slots), under the name the design vitrine uses."
  def command_palette_dialog(assigns), do: command_palette(assigns)
end
