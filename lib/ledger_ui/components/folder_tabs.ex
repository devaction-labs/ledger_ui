defmodule LedgerUI.Components.FolderTabs do
  @moduledoc """
  Folder tabs (Aurora): every tab is an SVG shaped like a folder tab (rounded top, the right side
  sloping down in a curve), overlapping the next one. The active tab takes the colour of the panel
  and merges with it (the panel loses its top-left corner); the inactive ones are solid colours that
  fade (`tab-1` for the first inactive, `tab-2` for the next ones, `tab-hov` on hover).

      <.folder_tabs id="painel" active={@tab} size="md" max={3} on_change="tab">
        <:tab id="geral" label="Visão geral" count={12} icon="map" />
        <:tab id="receita" label="Receita" />
        <:content>...</:content>
      </.folder_tabs>

  `active` is the id of the active tab (the first one when missing). The content is the one of the
  active tab, rendered by the server in the single `:content` slot (`role="tabpanel"`); the app
  changes it when `active` changes.

  ## Changing tab

    * `on_change` (an event name): each tab is a `button` with `phx-click` and `phx-value-tab=<id>`
      (the event arrives as `%{"tab" => id}`); `target` is the `phx-target`. A `%JS{}` raises, as in
      the other components: the event carries the id of the tab.
    * `patch` on the `:tab`: the tab is a link (`<a>`, live patch) and `active` follows the URL.

  Both can be used together. Switching never reloads the page.

  ## Size, overflow

    * `size="md"` (default): 270×54 tabs, overlap -46px, 52px of left padding. `size="sm"`: 220×44,
      -38px, 40px. The `sm` path is the one of the Aurora board (the same curve, narrower).
    * `max`: the number of tabs that show. The others go into a `+N` button that opens a
      `dropdown` of the remaining tabs. When the active tab is among them, it takes the place of the
      last visible tab (the tab it replaces goes to the menu), so the active tab is always seen.

  ## Markup, keyboard

  The ARIA is rendered by the server: `role="tablist"` with `role="tab"` children
  (`aria-selected`, roving `tabindex`, `aria-controls` when there is a `:content`) and a
  `role="tabpanel"` labelled by the active tab. The SVG is `aria-hidden`. The keyboard is the hook
  `LedgerUI.Tabs` (the one of `tabs/1`): ←/→ move and activate (`click` on the tab, which pushes the
  event or follows the link), Home and End go to the first and the last. A bubbling `ledger:change`
  event is dispatched as in `tabs/1`.

  Parts: `folder-tabs`, `folder-tabs-list`, `folder-tab`, `folder-tab-count`, `folder-tabs-more`,
  `folder-tabs-panel`. The colours are the tokens `tab-1`, `tab-2`, `tab-hov` and `bg-panel`.
  """
  use LedgerUI.Component
  @ledger_ui_event_guard true

  import LedgerUI.Components.Dropdown, only: [dropdown: 1, dropdown_item: 1]

  @sizes ~w(md sm)

  # the tab outline, per size (viewBox == the box of the tab)
  @paths %{
    "md" => "M0 54 L0 18 Q0 0 18 0 L200 0 C218 0 224 5 231 16 L250 45 C256 52 261 54 270 54 Z",
    "sm" => "M0 44 L0 18 Q0 0 18 0 L150 0 C168 0 174 5 181 16 L200 35 C206 42 211 44 220 44 Z"
  }
  @boxes %{"md" => "0 0 270 54", "sm" => "0 0 220 44"}

  @tab_dims %{
    "md" => "h-[54px] w-[270px] -mr-[46px] pl-[52px] text-[15.5px]",
    "sm" => "h-11 w-[220px] -mr-[38px] pl-10 text-[14px]"
  }
  @label_max %{"md" => "max-w-[150px]", "sm" => "max-w-[125px]"}
  @more_gap %{"md" => "ml-[58px]", "sm" => "ml-[50px]"}

  @tab_base "group/ft relative flex shrink-0 cursor-pointer items-center border-0 bg-transparent p-0 text-left font-medium " <>
              "text-muted no-underline z-(--z) not-data-[state=on]:hover:text-ink-2 data-[state=on]:z-10 data-[state=on]:text-ink " <>
              "focus-visible:outline-none"

  @path "stroke-transparent stroke-2 group-focus-visible/ft:stroke-ink-2 " <>
          "group-data-[state=on]/ft:fill-panel group-[:not([data-state=on]):hover]/ft:fill-tab-hov"
  @tone %{1 => "fill-tab-1", 2 => "fill-tab-2"}

  @count "ml-0.5 inline-grid h-5 min-w-5 place-items-center rounded-[7px] bg-sunken px-1.5 text-[11.5px] font-medium text-ink-2 " <>
           "group-data-[state=on]/ft:bg-ink group-data-[state=on]/ft:text-panel"

  attr :id, :string, required: true

  attr :active, :string,
    default: nil,
    doc: "The id of the active tab (the first one when `nil` or unknown)."

  attr :size, :string,
    default: "md",
    values: @sizes,
    doc: "`md`: 270×54 tabs. `sm`: 220×44."

  attr :max, :integer,
    default: nil,
    doc:
      "How many tabs show; the rest go into the `+N` menu (the active tab always shows, in the place of the last visible one). `nil`: all of them."

  attr :on_change, :string,
    default: nil,
    doc:
      "Event name sent on click, with `phx-value-tab=<id>` (`%{\"tab\" => id}`). Not a `%JS{}`: the event carries the id."

  attr :target, :any, default: nil, doc: "The `phx-target` of the `on_change` event."

  attr :label, :string,
    default: nil,
    doc: "The accessible name of the tab list (`aria-label`)."

  attr :class, :any, default: nil, doc: "Merged into the root."
  attr :rest, :global

  slot :tab, required: true do
    attr :id, :string, required: true, doc: "The id of the tab (`active`, `phx-value-tab`)."
    attr :label, :string, required: true
    attr :count, :any, doc: "A counter after the label (a number or a string)."
    attr :icon, :string, doc: "An icon name (see `icon/1`) before the label."
    attr :patch, :string, doc: "A live patch: the tab is a link."
  end

  slot :content, doc: "The content of the active tab (the `tabpanel`)."

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def folder_tabs(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, more_label: "folder_tabs.more")
    view = view(assigns)

    assigns =
      assigns
      |> assign(:root_class, cx(["flex flex-col", assigns.class]))
      |> assign(:visible, view.visible)
      |> assign(:overflow, view.overflow)
      |> assign(:more_gap, @more_gap[assigns.size])
      |> assign(:path_d, @paths[assigns.size])
      |> assign(:box, @boxes[assigns.size])
      |> assign(:active_id, view.active)
      |> assign(:panel_id, assigns.id <> "-panel")

    assigns =
      settle(assigns, changed0,
        root_class: [:class],
        visible: [:tab, :active, :max, :size, :id, :on_change, :target],
        overflow: [:tab, :active, :max, :id, :on_change, :target],
        more_gap: [:size],
        path_d: [:size],
        box: [:size],
        active_id: [:tab, :active, :max],
        panel_id: [:id]
      )

    ~H"""
    <div id={@id} data-part="folder-tabs" class={@root_class} phx-hook="LedgerUI.Tabs" {@rest}>
      <div class="flex items-end">
        <div
          data-part="folder-tabs-list"
          role="tablist"
          aria-label={@label}
          class="flex items-end"
        >
          <%= for t <- @visible do %>
            <a
              :if={t.link?}
              :key={t.id}
              id={t.dom_id}
              data-part="folder-tab"
              data-state={t.on? && "on"}
              class={t.class}
              style={t.style}
              role="tab"
              aria-selected={to_string(t.on?)}
              aria-controls={@content != [] && t.on? && @panel_id}
              tabindex={if(t.on?, do: "0", else: "-1")}
              {t.link_rest}
              {t.attrs}
            >
              <.shape box={@box} d={@path_d} class={t.path_class} />
              <.label_inner t={t} />
            </a>
            <button
              :if={!t.link?}
              :key={t.id}
              id={t.dom_id}
              type="button"
              data-part="folder-tab"
              data-state={t.on? && "on"}
              class={t.class}
              style={t.style}
              role="tab"
              aria-selected={to_string(t.on?)}
              aria-controls={@content != [] && t.on? && @panel_id}
              tabindex={if(t.on?, do: "0", else: "-1")}
              {t.attrs}
            >
              <.shape box={@box} d={@path_d} class={t.path_class} />
              <.label_inner t={t} />
            </button>
          <% end %>
        </div>
        <.dropdown
          :if={@overflow != []}
          id={@id <> "-more"}
          anchor_class={["z-10 self-center", @more_gap]}
          placement="bottom-start"
        >
          <:toggle :let={trig}>
            <button
              type="button"
              data-part="folder-tabs-more"
              aria-label={@more_label}
              class="inline-flex h-8 cursor-pointer items-center gap-1 rounded-[10px] border border-line bg-panel px-2.5 text-[13px] text-ink-2 hover:text-ink focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] focus-visible:outline-none"
              {trig}
            >
              +{length(@overflow)}
              <.icon name="chevron-down" size="sm" />
            </button>
          </:toggle>
          <.dropdown_item :for={t <- @overflow} :key={t.id} {t.item_attrs}>
            {t.label}
            <:trailing :if={t.count != nil}>{t.count}</:trailing>
          </.dropdown_item>
        </.dropdown>
      </div>
      <div
        :if={@content != []}
        id={@panel_id}
        data-part="folder-tabs-panel"
        role="tabpanel"
        aria-labelledby={@id <> "-tab-" <> @active_id}
        class="rounded-2xl rounded-tl-none bg-panel p-6"
      >
        {render_slot(@content)}
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------------------
  # which tabs show, which go to the menu

  defp view(a) do
    tabs = a.tab
    first = tabs |> List.first() |> Map.fetch!(:id)
    active = if Enum.any?(tabs, &(&1.id == a.active)), do: a.active, else: first
    {shown, hidden} = split(tabs, active, a.max)
    n = length(shown)

    {visible, _} =
      shown
      |> Enum.with_index()
      |> Enum.map_reduce(0, fn {t, i}, inactive ->
        on? = t.id == active
        tone = if on?, do: nil, else: if(inactive == 0, do: 1, else: 2)
        {visible_tab(t, a, on?, tone, max(n - i, 1)), if(on?, do: inactive, else: inactive + 1)}
      end)

    %{active: active, visible: visible, overflow: Enum.map(hidden, &overflow_tab(&1, a))}
  end

  # more tabs than `max`: the first `max` show; an active tab in the rest takes the last place
  defp split(tabs, _active, max) when not is_integer(max) or max < 1 or length(tabs) <= max,
    do: {tabs, []}

  defp split(tabs, active, max) do
    {head, rest} = Enum.split(tabs, max)

    if Enum.any?(head, &(&1.id == active)) do
      {head, rest}
    else
      current = Enum.find(rest, &(&1.id == active))
      shown = Enum.take(head, max - 1) ++ [current]
      {shown, Enum.reject(tabs, &(&1 in shown))}
    end
  end

  defp visible_tab(t, a, on?, tone, z) do
    link? = is_binary(t[:patch])

    %{
      id: t.id,
      dom_id: "#{a.id}-tab-#{t.id}",
      link?: link?,
      on?: on?,
      class: [@tab_base, @tab_dims[a.size]],
      style: "--z:#{z}",
      path_class: [@path, @tone[tone]],
      label_class: ["truncate", @label_max[a.size]],
      count_class: @count,
      label: t.label,
      count: t[:count],
      icon: t[:icon],
      link_rest: if(link?, do: LedgerUI.LinkAttrs.resolve(%{patch: t.patch}), else: %{}),
      attrs: event_attrs(t, a)
    }
  end

  defp overflow_tab(t, a) do
    item =
      if is_binary(t[:patch]), do: %{patch: t.patch}, else: %{}

    %{id: t.id, label: t.label, count: t[:count], item_attrs: Map.merge(item, event_attrs(t, a))}
  end

  # the click that asks the server for the tab: `phx-click` + `phx-value-tab`
  defp event_attrs(_t, %{on_change: nil}), do: %{}

  defp event_attrs(t, a) do
    %{"phx-click": a.on_change, "phx-value-tab": t.id}
    |> then(fn m -> if a.target, do: Map.put(m, :"phx-target", a.target), else: m end)
  end

  attr :box, :string, required: true
  attr :d, :string, required: true
  attr :class, :string, required: true

  defp shape(assigns) do
    ~H"""
    <svg
      class="pointer-events-none absolute inset-0 size-full overflow-visible"
      viewBox={@box}
      aria-hidden="true"
      focusable="false"
    >
      <path d={@d} class={@class} />
    </svg>
    """
  end

  attr :t, :map, required: true

  defp label_inner(assigns) do
    ~H"""
    <span class="relative inline-flex items-center gap-2">
      <.icon :if={@t.icon} name={@t.icon} size="md" />
      <span class={@t.label_class}>{@t.label}</span>
      <span :if={@t.count != nil} data-part="folder-tab-count" class={@t.count_class}>{@t.count}</span>
    </span>
    """
  end
end
