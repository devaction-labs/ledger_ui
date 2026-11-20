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

  `inline` renders the dialog over its own in-page scrim (a static preview, always open, no hook);
  `bare` renders only the `lu-cmd` card.
  """
  use LedgerUI.Component
  alias LedgerUI.Components.Modal.Support

  attr :id, :string, required: true
  attr :open, :boolean, default: false
  attr :label, :string, default: "Command palette"
  attr :placeholder, :string, default: "Search or type a command"
  attr :scopes, :list, default: []
  attr :scopes_label, :string, default: "Where to search"
  attr :items, :list, default: []
  attr :empty, :string, default: "Nothing found"
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
  attr :hint_navigate, :string, default: "Navigate"
  attr :hint_open, :string, default: "Open"
  attr :hint_new_tab, :any, default: "Open in new tab"
  attr :hint_close, :string, default: "Close"
  attr :class, :any, default: nil

  attr :list_style, :string,
    default: nil,
    doc: "Inline style of the list (replaces the variant padding)."

  attr :inline, :boolean,
    default: false,
    doc: "Static preview over an in-page scrim: always open, no hook."

  attr :bare, :boolean, default: false, doc: "Only the `lu-cmd` card, always open, no hook."
  attr :rest, :global

  slot :footer
  slot :item_icon

  def command_palette(assigns) do
    static? = assigns.inline or assigns.bare
    user_style = assigns.rest[:style]
    canvas? = assigns.variant == "canvas"

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

    card_attrs = %{
      "role" => "dialog",
      "aria-modal" => if(!static?, do: "true"),
      "aria-label" => assigns.label
    }

    root_style =
      cond do
        assigns.bare ->
          nil

        assigns.inline ->
          user_style

        true ->
          Support.style([
            "position:fixed;inset:0;z-index:var(--ledger-z-modal,60);border-radius:0;align-items:flex-start;padding-top:12vh",
            user_style
          ])
      end

    card_style =
      if assigns.bare,
        do: Support.style([canvas? && "border-radius:10px", user_style]),
        else: Support.style([canvas? && "border-radius:10px"])

    assigns =
      assigns
      |> assign(:rest, Map.delete(assigns.rest, :style))
      |> assign(:cfg, cfg)
      |> assign(:card_attrs, card_attrs)
      |> assign(:root_style, root_style)
      |> assign(:card_style, card_style)
      |> assign(:card_class, cx(["lu-cmd", assigns.class]))
      |> assign(:list_attrs, list_attrs(assigns.list_style, canvas?))
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
      |> assign(:hook, if(static?, do: nil, else: "LedgerUI.Overlay"))
      |> assign(:overlay_attr, if(static?, do: nil, else: ""))
      |> assign(:state, if(!static?, do: if(assigns.open, do: "open", else: "closed")))
      |> assign(:ft?, assigns.hints or assigns.footer != [])
      |> assign(:both?, assigns.hints and assigns.footer != [])
      |> assign(:static?, static?)

    ~H"""
    <%= if @bare do %>
      <.card {assigns} root_attrs={%{"id" => @id}} />
    <% else %>
      <div
        id={@id}
        class="lu-scrim"
        {Support.st(@root_style)}
        phx-hook={@hook}
        data-lu-overlay={@overlay_attr}
        data-state={@state}
        {@cfg}
        {@rest}
      >
        <.card {assigns} root_attrs={%{}} />
      </div>
    <% end %>
    """
  end

  defp card(assigns) do
    ~H"""
    <div
      class={@card_class}
      {Support.st(@card_style)}
      {@root_attrs}
      {@card_attrs}
      {if @bare, do: @rest, else: %{}}
    >
      <div class="q">
        <.icon name="search" />
        <input placeholder={@placeholder} value={@query} {@combo} />
        <kbd class="lu-kbd">Esc</kbd>
      </div>
      <div
        :if={@scope_list != []}
        class="lu-row"
        style="padding:8px 12px 0;gap:6px"
        role="group"
        aria-label={@scopes_label}
      >
        <button
          :for={{{label, value}, i} <- Enum.with_index(@scope_list)}
          type="button"
          class={if i == 0, do: "lu-chip on", else: "lu-chip"}
          aria-pressed={Support.flag(i == 0)}
          data-lu-scope={value}
        >
          {label}
        </button>
      </div>
      <div class="list" {@list_attrs} {@list_aria}>
        <%= for {group, rows} <- @groups do %>
          <div :if={group} class="lu-menu-label" role="presentation">{group}</div>
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
          class="lu-menu-item"
          role={@row_role}
          hidden
          data-lu-assistant=""
          data-lu-label={@assistant[:label]}
        >
          <.icon name={assistant_icon(@assistant)} />{@assistant[:label]}<span
            :if={@assistant[:sub]}
            class="lu-xs lu-muted"
            style="margin-left:8px"
          >{@assistant[:sub]}</span>
        </button>
      </div>
      <div :if={@ft?} class="ft">
        <%= if @hints do %>
          <span>↑↓ {@hint_navigate}</span>
          <span>↵ {@hint_open}</span>
          <span :if={@hint_new_tab}>⌃↵ {@hint_new_tab}</span>
          <span>esc {@hint_close}</span>
        <% end %>
        <span :if={@both?} class="lu-grow"></span>
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
      class={row_class(@hl)}
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
      class={row_class(@hl)}
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
      class={row_class(@hl)}
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
      class={row_class(@hl)}
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
    ~H"""
    <%= cond do %>
      <% @item[:icon] -> %>
        <.icon name={@item[:icon]} />
      <% @item[:avatar] -> %>
        <span
          class="lu-av sq"
          {Support.st("--s:24px;background:" <> to_string(@item.avatar[:tint] || "var(--bg-sunken)"))}
        >{@item.avatar[:initials]}</span>
      <% @item_icon != [] -> %>
        {render_slot(@item_icon, @item)}
      <% true -> %>
    <% end %>
    {@item.label}<span :if={@item[:sub]} class="lu-xs lu-muted" style="margin-left:8px">{@item[:sub]}</span><span
      :if={@item[:keys] || @item[:count]}
      class="r"
    ><kbd :for={k <- List.wrap(@item[:keys])} class="lu-kbd">{k}</kbd><span
      :if={@item[:count]}
      class="lu-count"
      style="height:16px"
    >{@item[:count]}</span></span>
    """
  end

  defp row_class(hl), do: if(hl, do: "lu-menu-item hl", else: "lu-menu-item")

  defp row_attrs(item) do
    %{
      "data-lu-value" => to_string(item[:value] || item.label),
      "data-lu-scope" => item[:scope],
      "data-lu-keywords" => item[:keywords]
    }
  end

  defp list_attrs(nil, true), do: %{"style" => "padding:4px"}
  defp list_attrs(nil, false), do: %{}
  defp list_attrs(style, _), do: %{"style" => style}

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

  component_alias(:command_palette_dialog, :command_palette)
end
