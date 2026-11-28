defmodule LedgerUI.Components.Rail do
  @moduledoc """
  `rail/1`: the floating navigation rail of the Aurora look, with a preview card on each item, and
  `rail_user_menu/1`, the account menu for its bottom group.

      <.rail id="rail" current={@current_path} variant="compact" shape="rounded">
        <:top><.logo /></:top>
        <:item path="/contatos" icon="users" label="Contatos" count={214} alert={true}
               preview_title="Contatos" preview_description="Clientes e pessoas">
          <div class="grid h-full place-items-center"><.icon name="users" size="xl" /></div>
        </:item>
        <:item path="/relatorios" icon="chart" label="Relatorios" disabled={true} />
        <:bottom>
          <.rail_user_menu id="rail-user" name="Ana Souza" email="ana@example.com"
                           profile_path="/perfil" settings_path="/config" sign_out_path="/sair" />
        </:bottom>
      </.rail>

  ## Why the preview is not a nested slot

  HEEx has no slots inside slots, so `<:item><:preview>` cannot be written. The preview of an item is
  described on the `:item` itself: the attrs `preview_title` and `preview_description` are its texts and
  **the body of the `:item` is its thumbnail** (96px high, free drawing). An item with neither a title
  nor a description has no preview.

  ## Look

  Three floating groups (top, navigation, bottom) of glass (panel at 50% + blur), 1px light border,
  radius 18, padding 6. `variant="compact"` is 64px wide (icons); `"expanded"` is 232px with the label
  and the `count`. An item is 40x40, radius 12, icon 20px; the active one is the panel surface with a
  line ring; `alert` draws a 7px red dot with a ring; `disabled` is dimmed (`opacity-35`), not
  navigable and `aria-disabled`. `shape="pill"` makes the items fully round and the groups a capsule (radius 27, half the width of a compact
  group; fixed, so an expanded group is a stadium and not an ellipse).

  Below `md` the rail becomes a floating bottom bar (glass, radius 20, 64px high): the `:top` group
  and the labels go away, the previews are off.

  ## Active item

  `current` (the path of the page, a query string is ignored) activates the item whose `path` equals it
  or is a prefix of it on a segment boundary (`/contatos` is active on `/contatos/3`, not on
  `/contatos-2`; `/` only on the root). With two matches the longest path wins. The item is a
  `<.link navigate>` with `aria-current="page"`.

  ## Preview

  Every preview is in the DOM, hidden, and the item points at it with `aria-describedby`. The hook
  `LedgerUI.RailPreview` (`priv/static/ledger_ui/hooks/rail_preview.js`) only shows and positions it:
  it opens after `preview_delay` ms (150) of hover or keyboard focus, moves to the next item
  without delay and without animating again, closes when the pointer leaves the rail, when the focus
  leaves it and on Esc. It keeps no listener on `document` or `window` while closed. With reduced
  motion there is no animation.

  Styled only with Tailwind utilities; elements carry `data-part` (`rail`, `rail-group`, `rail-item`,
  `rail-alert`, `rail-preview`, `rail-user-menu`...).
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Avatar
  alias LedgerUI.Components.Popover
  alias LedgerUI.Components.ThemeSwitch

  @root "relative flex h-full flex-col justify-between max-md:fixed max-md:inset-x-3.5 max-md:bottom-3.5 max-md:z-40 max-md:h-16 max-md:w-auto max-md:flex-row max-md:items-center max-md:justify-around max-md:rounded-xl max-md:border max-md:border-white/85 max-md:bg-panel/50 max-md:px-2 max-md:shadow-xs max-md:backdrop-blur-[14px] dark:max-md:border-white/7"
  @width %{"compact" => "w-16 items-center", "expanded" => "w-[232px] items-stretch"}
  @group "flex flex-col gap-1 border border-white/85 bg-panel/50 p-1.5 shadow-xs backdrop-blur-[14px] max-md:contents dark:border-white/7"
  # 27px = half the width of a compact group (a capsule); a fixed radius keeps the expanded one a stadium, not an ellipse
  @group_shape %{"rounded" => "rounded-[18px]", "pill" => "rounded-[27px]"}
  @stack "flex flex-col max-md:contents"
  @stack_gap %{"compact" => "items-center gap-3.5", "expanded" => "gap-3"}

  @item "relative flex-none no-underline outline-none transition-colors [&_svg]:size-5 focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] max-md:size-11 max-md:justify-center max-md:px-0"
  @item_variant %{
    "compact" => "grid size-10 place-items-center",
    "expanded" => "flex h-10 w-full items-center gap-3 px-2.5 text-[14px] font-medium"
  }
  @item_shape %{"rounded" => "rounded-md", "pill" => "rounded-full"}
  @item_on "cursor-pointer bg-panel text-ink shadow-[0_0_0_1px_var(--lu-line),var(--lu-shadow-xs)]"
  @item_off "cursor-pointer text-ink-2 hover:bg-hover hover:text-ink"
  @item_disabled "cursor-not-allowed text-ink-2 opacity-35"

  @dot "size-[7px] flex-none rounded-full bg-neg ring-2 ring-panel"

  @preview "pointer-events-none fixed top-0 left-0 z-50 hidden w-[236px] flex-col gap-2.5 rounded-[18px] bg-tip-glass p-2.5 text-white shadow-popover backdrop-blur-[18px] before:absolute before:top-(--ay) before:-left-1.5 before:size-3 before:rotate-45 before:rounded-[3px] before:bg-inherit before:content-[''] data-[side=left]:before:right-[-6px] data-[side=left]:before:left-auto md:data-[open]:flex"

  attr :id, :string,
    required: true,
    doc: "Needed by the hook; the ids of the previews derive from it."

  attr :current, :string,
    default: nil,
    doc: "Path of the current page; picks the active item (see \"Active item\")."

  attr :variant, :string,
    default: "compact",
    values: ~w(compact expanded),
    doc: "`compact`: 64px, icons only. `expanded`: 232px with the label and the count."

  attr :shape, :string,
    default: "rounded",
    values: ~w(rounded pill),
    doc: "`rounded`: radius 18 groups and 12 items. `pill`: fully round."

  attr :preview_delay, :integer,
    default: 150,
    doc: "Milliseconds of hover or focus before a preview opens."

  attr :label, :string,
    default: nil,
    doc: "`aria-label` of the `nav` (default: \"Main navigation\")."

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  attr :class, :any, default: nil, doc: "Layout only."
  attr :rest, :global

  slot :top, doc: "Group above the navigation: the brand, a search button."
  slot :bottom, doc: "Group below: sign out, `rail_user_menu/1`."

  slot :item,
    doc: "A navigation item. Its body is the thumbnail of the preview (96px high)." do
    attr :path, :string,
      required: true,
      doc: "Destination (`<.link navigate>`) and what `current` is matched against."

    attr :icon, :string, required: true, doc: "Icon name (`users` or `huge-users`)."

    attr :label, :string,
      required: true,
      doc: "The name; shown in `expanded`, otherwise only for screen readers."

    attr :alert, :boolean, doc: "A red dot with a ring: something needs attention."
    attr :disabled, :boolean, doc: "Dimmed, not navigable, `aria-disabled`."
    attr :count, :integer, doc: "A number shown at the end of the item in `expanded`."
    attr :preview_title, :string, doc: "Title of the preview card (15px, white)."
    attr :preview_description, :string, doc: "Text of the preview card (13px, white 62%)."
  end

  def rail(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, label: "rail.label")

    assigns =
      assigns
      |> assign(:root_class, cx([@root, @width[assigns.variant], assigns.class]))
      |> assign(:group_class, cx([@group, @group_shape[assigns.shape]]))
      |> assign(:stack_class, cx([@stack, @stack_gap[assigns.variant]]))
      |> assign(:entries, entries(assigns.id, assigns.item, assigns.current))

    assigns =
      settle(assigns, changed0,
        root_class: [:variant, :class],
        group_class: [:shape],
        stack_class: [:variant]
      )

    ~H"""
    <nav
      id={@id}
      aria-label={@label}
      phx-hook="LedgerUI.RailPreview"
      data-part="rail"
      data-variant={@variant}
      data-shape={@shape}
      data-lu-delay={@preview_delay}
      class={@root_class}
      {@rest}
    >
      <div data-part="rail-stack" class={@stack_class}>
        <div
          :if={@top != []}
          data-part="rail-group"
          data-group="top"
          class={[@group_class, "max-md:hidden"]}
        >
          {render_slot(@top)}
        </div>
        <div :if={@entries != []} data-part="rail-group" data-group="nav" class={@group_class}>
          <.rail_item
            :for={e <- @entries}
            :key={e.path}
            path={e.path}
            icon={e.icon}
            label={e.label}
            variant={@variant}
            shape={@shape}
            on={e.on}
            alert={e.alert}
            disabled={e.disabled}
            count={e.count}
            describedby={e.pv_id}
            alert_label={I18n.t("rail.alert", @locale)}
          />
        </div>
      </div>
      <div :if={@bottom != []} data-part="rail-group" data-group="bottom" class={@group_class}>
        {render_slot(@bottom)}
      </div>
      <.rail_preview
        :for={e <- @entries}
        :if={e.pv_id}
        :key={e.pv_id}
        id={e.pv_id}
        title={e.pv_title}
        description={e.pv_description}
        slot={e.slot}
      />
    </nav>
    """
  end

  # The data of each item, computed once per render of the rail (the active one is the longest match).
  defp entries(id, items, current) do
    active = active_path(items, current)

    items
    |> Enum.with_index()
    |> Enum.map(fn {item, i} ->
      title = item[:preview_title]
      desc = item[:preview_description]
      preview? = title != nil or desc != nil

      %{
        path: item.path,
        icon: item.icon,
        label: item.label,
        on: item.path == active,
        alert: item[:alert] == true,
        disabled: item[:disabled] == true,
        count: item[:count],
        pv_id: if(preview?, do: "#{id}-pv-#{i}"),
        pv_title: title,
        pv_description: desc,
        slot: item
      }
    end)
  end

  defp active_path(_items, nil), do: nil

  defp active_path(items, current) do
    cp = path_of(current)

    items
    |> Enum.reject(&(&1[:disabled] == true))
    |> Enum.map(& &1.path)
    |> Enum.filter(fn p ->
      pp = path_of(p)
      pp == cp or (pp != "/" and String.starts_with?(cp, String.trim_trailing(pp, "/") <> "/"))
    end)
    |> Enum.max_by(&byte_size(path_of(&1)), fn -> nil end)
  end

  defp path_of(url), do: url |> String.split(["?", "#"]) |> hd()

  attr :path, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :variant, :string, required: true
  attr :shape, :string, required: true
  attr :on, :boolean, default: false
  attr :alert, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :count, :integer, default: nil
  attr :describedby, :string, default: nil
  attr :alert_label, :string, required: true

  defp rail_item(%{disabled: true} = assigns) do
    ~H"""
    <span
      role="link"
      aria-disabled="true"
      aria-describedby={@describedby}
      data-part="rail-item"
      data-rail-item
      data-disabled
      class={item_class(@variant, @shape, false, true)}
    >
      <.item_body
        icon={@icon}
        label={@label}
        variant={@variant}
        alert={@alert}
        count={@count}
        alert_label={@alert_label}
      />
    </span>
    """
  end

  defp rail_item(assigns) do
    ~H"""
    <.link
      navigate={@path}
      aria-current={@on && "page"}
      aria-describedby={@describedby}
      data-part="rail-item"
      data-rail-item
      class={item_class(@variant, @shape, @on, false)}
    >
      <.item_body
        icon={@icon}
        label={@label}
        variant={@variant}
        alert={@alert}
        count={@count}
        alert_label={@alert_label}
      />
    </.link>
    """
  end

  defp item_class(variant, shape, on, disabled) do
    cx([
      @item,
      @item_variant[variant],
      @item_shape[shape],
      cond do
        disabled -> @item_disabled
        on -> @item_on
        true -> @item_off
      end
    ])
  end

  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :variant, :string, required: true
  attr :alert, :boolean, required: true
  attr :count, :integer, default: nil
  attr :alert_label, :string, required: true

  defp item_body(%{variant: "expanded"} = assigns) do
    ~H"""
    <.icon name={@icon} />
    <span class="max-md:sr-only min-w-0 flex-1 truncate">{@label}</span>
    <span :if={@count || @alert} class="flex items-center gap-2 max-md:hidden">
      <span :if={@count} class="text-[12px] font-normal text-muted tabular-nums">{@count}</span>
      <span :if={@alert} data-part="rail-alert" class={dot()}></span>
    </span>
    <span :if={@alert} class="sr-only">{@alert_label}</span>
    """
  end

  defp item_body(assigns) do
    ~H"""
    <.icon name={@icon} />
    <span class="sr-only">{@label}<span :if={@count}> ({@count})</span></span>
    <span :if={@alert} data-part="rail-alert" class={[dot(), "absolute top-2 right-2"]}></span>
    <span :if={@alert} class="sr-only">{@alert_label}</span>
    """
  end

  defp dot, do: @dot

  attr :id, :string, required: true
  attr :title, :string, default: nil
  attr :description, :string, default: nil
  attr :slot, :any, required: true

  defp rail_preview(assigns) do
    ~H"""
    <div
      id={@id}
      role="tooltip"
      data-part="rail-preview"
      data-lu-rail-preview
      class={preview_class()}
    >
      <div
        :if={@slot.inner_block}
        data-part="rail-preview-art"
        class="relative h-24 overflow-hidden rounded-md bg-white/8"
      >
        {render_slot(@slot)}
      </div>
      <b :if={@title} class="px-1 text-[15px] leading-5 font-medium text-white">{@title}</b>
      <span
        :if={@description}
        class={["px-1 pb-1 text-[13px] leading-[18px] text-white/62", @title && "-mt-1.5"]}
      >
        {@description}
      </span>
    </div>
    """
  end

  defp preview_class, do: @preview

  # -- user menu -----------------------------------------------------------------------------------

  @menu_item "flex h-[38px] w-full cursor-pointer items-center gap-2.5 rounded-[10px] border-0 bg-transparent px-2 text-left text-[14px] text-ink no-underline outline-none hover:bg-hover focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] [&_svg]:size-[17px] [&_svg]:text-ink-2"

  attr :id, :string, required: true

  attr :name, :string,
    required: true,
    doc: "Shown in the header of the menu; gives the initials of the avatar."

  attr :email, :string, default: nil, doc: "Shown under the name."
  attr :src, :string, default: nil, doc: "Picture of the avatar."

  attr :profile_path, :string,
    default: nil,
    doc: "Destination of \"Profile\"; no item without it."

  attr :settings_path, :string,
    default: nil,
    doc: "Destination of \"Settings\"; no item without it."

  attr :sign_out_path, :string,
    default: nil,
    doc: "Destination of \"Sign out\"; no item without it."

  attr :sign_out_method, :string,
    default: "delete",
    doc: "HTTP method of the sign out link (`<.link method>`)."

  attr :theme, :boolean,
    default: true,
    doc:
      "The sun / moon / monitor choice (`theme_switch/1`, same hook and storage; its id is `<id>-theme`)."

  attr :placement, :string,
    default: "right-end",
    doc: "Where the menu opens (a `popover/1` placement); it flips when there is no room."

  attr :label, :string,
    default: nil,
    doc: "`aria-label` of the avatar button (default: \"Account menu\")."

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  attr :class, :any, default: nil
  attr :rest, :global

  @doc """
  The account menu of the rail: the avatar is the trigger of a 280px popover with the header (avatar,
  name, e-mail), Profile, Settings, Theme (`theme_switch/1`) and Sign out. Put it in the `:bottom` slot of
  `rail/1`.
  """
  def rail_user_menu(assigns) do
    assigns = I18n.texts(assigns, label: "rail.user_menu")

    ~H"""
    <Popover.popover
      id={@id}
      width="280px"
      placement={@placement}
      fallbacks={["top-end", "bottom-end", "left-end"]}
      label={@label}
      locale={@locale}
      class={@class}
      data-part="rail-user-menu"
      {@rest}
    >
      <:trigger :let={aria}>
        <button
          type="button"
          aria-label={@label}
          data-part="rail-user-trigger"
          class="grid size-10 cursor-pointer place-items-center rounded-md border-0 bg-transparent p-0 outline-none focus-visible:shadow-[0_0_0_3px_var(--lu-focus)]"
          {aria}
        >
          <Avatar.avatar name={@name} src={@src} size={36} shape="rounded" />
        </button>
      </:trigger>
      <div class="-m-1.5 flex flex-col gap-0.5">
        <div
          data-part="rail-user-head"
          class="mb-1.5 flex items-center gap-2.5 border-b border-line px-2 pt-2 pb-3"
        >
          <Avatar.avatar name={@name} src={@src} size={36} shape="rounded" />
          <div class="min-w-0">
            <b class="block truncate text-[14.5px] font-semibold text-ink">{@name}</b>
            <span :if={@email} class="block truncate text-[12.5px] text-muted">{@email}</span>
          </div>
        </div>
        <.link
          :if={@profile_path}
          navigate={@profile_path}
          data-part="rail-user-item"
          class={menu_item()}
        >
          <.icon name="user" />{I18n.t("rail.profile", @locale)}
        </.link>
        <.link
          :if={@settings_path}
          navigate={@settings_path}
          data-part="rail-user-item"
          class={menu_item()}
        >
          <.icon name="settings" />{I18n.t("rail.settings", @locale)}
        </.link>
        <div
          :if={@theme}
          data-part="rail-user-theme"
          class="flex h-[38px] items-center gap-2.5 px-2 text-[14px] text-ink"
        >
          <.icon name="palette" class="text-ink-2" />
          <span class="flex-1">{I18n.t("rail.theme", @locale)}</span>
          <ThemeSwitch.theme_switch id={@id <> "-theme"} size="sm" locale={@locale} />
        </div>
        <.link
          :if={@sign_out_path}
          href={@sign_out_path}
          method={@sign_out_method}
          data-part="rail-user-item"
          class={menu_item()}
        >
          <.icon name="logout" />{I18n.t("rail.sign_out", @locale)}
        </.link>
      </div>
    </Popover.popover>
    """
  end

  defp menu_item, do: @menu_item
end
