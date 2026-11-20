defmodule LedgerUI.Components.DataTable do
  @moduledoc """
  A table with a search box, sortable headers, a pagination footer and row selection, in the two
  looks of Ledger UI: `advanced` (title bar, the table as a card, summary and pager underneath)
  and `grid` (search at the right, the gridjs table, summary and pager).

  The LiveView owns the state: it filters, sorts and slices the rows and gives the component the
  current page; the component renders it and sends events back.

      <.data_table
        id="users"
        rows={@users}
        search={@search}
        on_search="search"
        sort_by={@sort_by}
        sort_dir={@sort_dir}
        on_sort="sort"
        page={@page}
        page_size={10}
        total={@total}
        on_page="paginate"
      >
        <:title>Users</:title>
        <:col :let={user} label="Name" sort_key="name">{user.name}</:col>
        <:col :let={user} label="Email">{user.email}</:col>
      </.data_table>

      def handle_event("search", %{"search" => q}, socket), do: ...
      def handle_event("sort", %{"column" => col, "direction" => dir}, socket), do: ...
      def handle_event("paginate", %{"page" => page}, socket), do: ...

  Rows may be a stream (`rows={@streams.users}`): the body renders with `phx-update="stream"` and
  `total` drives the footer. `:col`, `:action`, `:expand`, `:empty`, `:foot`, `row_id`, `row_key`,
  `row_item`, `row_click`, selection and columns that leave by `priority` work as in
  `LedgerUI.Components.Table.table/1`, which renders the table.

  ## Events

  `on_search` (`%{"search" => q}`), `on_sort` (`%{"column" => c, "direction" => d}`), `on_page`
  (`%{"page" => "3"}`), `on_page_size` (`%{"page_size" => "30"}`), `on_select`
  (`%{"id" => key, "selected" => "true" | "false"}`), `on_select_all` (`%{"selected" => ..}`).
  With `page_path` (a function of the page number) the pager renders `patch` links instead.

  ## Extras over the README

  A `:toolbar` slot (a row with a rule under it, for a search and buttons written by hand),
  `body="card"` (the table directly in a card body instead of the bordered wrapper of the table)
  and the pager looks `canvas` (plain) and `pages` (buttons, with previous arrow). Styled only
  with Tailwind utilities.

  ## Not implemented

  `peek` and `peek_label` are accepted; `peek` draws nothing yet. The pager pages are not
  focusable (they carry `phx-click` only).
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Button
  alias LedgerUI.Components.Table
  alias LedgerUI.Components.Typography

  @tray "flex min-w-0 flex-col rounded-xl border border-line bg-tray p-1.5"
  @bar "flex items-center gap-2.5 pt-2 pr-2.5 pb-2.5 pl-3.5 min-h-11"
  @row "flex flex-wrap items-center gap-2.5"
  @title "inline-flex items-center gap-2 font-display text-xs leading-4 font-medium tracking-[.08em] text-ink-2 uppercase"
  @footer "flex items-center gap-2 pt-2.5 pr-3 pb-1.5 pl-3.5 text-[13px] text-muted"

  # the pager `lu-pg2`: a page, the current page and the arrow of each look
  @pg_page "grid h-[26px] min-w-[26px] place-items-center px-1.5 text-ink-2 text-[12px]"
  @pg_look %{
    "rounded" => %{
      page: "rounded-[8px]",
      on:
        "bg-panel font-semibold text-ink shadow-[0_0_0_1px_var(--lu-line-strong),var(--lu-shadow-xs)]",
      arrow: "rounded-[8px]"
    },
    "pill" => %{
      page: "rounded-full",
      on: "bg-accent-600 font-semibold text-accent-foreground",
      arrow: "rounded-full"
    },
    "circle" => %{
      page: "rounded-[8px]",
      on: "bg-ink font-semibold text-on-inverse",
      arrow: "rounded-full"
    },
    "canvas" => %{
      page: "rounded-[8px]",
      on: "bg-ink font-semibold text-on-inverse",
      arrow: "rounded-full"
    }
  }

  # the pager `lu-pages`: buttons
  @pages_btn "inline-grid h-8 min-w-8 cursor-pointer place-items-center rounded-[8px] border-0 bg-transparent px-2 text-[13.5px] text-ink-2 tabular-nums hover:bg-hover"
  @pages_on "bg-panel font-semibold text-ink shadow-[0_0_0_1px_var(--lu-line-strong),var(--lu-shadow-xs)] hover:bg-panel"

  # -- data_table -------------------------------------------------------------------------------

  attr :id, :string, required: true
  attr :rows, :any, required: true, doc: "The rows of the current page, a list or a stream."
  attr :variant, :string, default: "advanced", values: ~w(advanced grid)
  attr :body, :string, default: "wrap", values: ~w(wrap card)
  attr :row_id, :any, default: nil
  attr :row_key, :any, default: nil
  attr :row_item, :any, default: &Function.identity/1
  attr :row_click, :any, default: nil
  attr :row_class, :any, default: nil
  attr :row_attrs, :any, default: nil
  attr :hoverable, :boolean, default: nil
  attr :search, :string, default: ""
  attr :search_placeholder, :string, default: nil
  attr :on_search, :any, default: nil
  attr :sort_by, :string, default: nil
  attr :sort_dir, :string, default: "asc", values: ~w(asc desc)
  attr :on_sort, :any, default: nil
  attr :page, :integer, default: 1
  attr :page_size, :integer, default: 10
  attr :total, :integer, default: nil
  attr :on_page, :any, default: nil
  attr :page_path, :any, default: nil
  attr :footer, :boolean, default: true
  attr :compact, :boolean, default: false
  attr :sticky_header, :boolean, default: false
  attr :scroll_label, :string, default: nil
  attr :peek, :boolean, default: false
  attr :peek_label, :string, default: "Hidden columns"
  attr :sort_label, :string, default: nil
  attr :row_label, :any, default: nil
  attr :headless, :boolean, default: false
  attr :borderless, :boolean, default: false
  attr :page_sizes, :list, default: []
  attr :on_page_size, :any, default: nil

  attr :pager, :string,
    default: "rounded",
    values: ~w(rounded pill circle canvas pages),
    doc: "The pager look: `rounded`, `pill`, `circle`, `canvas` (plain) or `pages` (buttons)."

  attr :pager_siblings, :integer, default: 1
  attr :pager_arrows, :boolean, default: true
  attr :loading, :boolean, default: false
  attr :loading_rows, :integer, default: 3
  attr :show_label, :string, default: "Show"
  attr :entries_label, :string, default: "entries"
  attr :prev_label, :string, default: "Previous"
  attr :next_label, :string, default: "Next"
  attr :page_label, :string, default: "Page %{page}"
  attr :filter_label, :string, default: "Filter"

  attr :summary_label, :string,
    default: nil,
    doc: "Summary text with `%{from}`, `%{to}` and `%{total}`."

  attr :select_all_label, :string, default: "Select all rows"
  attr :select_label, :string, default: "Select row"
  attr :selected, :list, default: []
  attr :all_selected, :boolean, default: nil
  attr :on_select, :any, default: nil
  attr :on_select_all, :any, default: nil
  attr :expand_label, :string, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :wrapper_class, :any, default: nil
  attr :select_attrs, :any, default: nil
  attr :body_class, :any, default: nil
  attr :rest, :global

  slot :action
  slot :actions, doc: "Buttons at the right of the title bar."

  slot :col, required: true do
    attr :label, :string
    attr :class, :any
    attr :head_class, :any
    attr :align, :string, values: ~w(left center right)
    attr :sort_key, :string
    attr :priority, :integer
    attr :style, :string
  end

  slot :empty
  slot :expand

  slot :filters,
    doc: "A filter panel the title bar's filter button opens. Receives the `JS` that toggles it."

  slot :foot do
    attr :class, :any
    attr :align, :string
    attr :colspan, :any
    attr :priority, :integer
  end

  slot :summary, doc: "Replaces the summary text; receives `%{first: n, last: n, total: n}`."
  slot :title, doc: "The `advanced` heading."
  slot :toolbar, doc: "A row above the table, written by hand."
  slot :bulk, doc: "Rendered under the table (a `bulk_bar`)."

  def data_table(assigns) do
    total = assigns.total || total_of(assigns.rows)
    pages = max(ceil_div(total, assigns.page_size), 1)
    first = if total == 0, do: 0, else: (assigns.page - 1) * assigns.page_size + 1
    last = min(assigns.page * assigns.page_size, total)
    footer? = assigns.footer and (assigns.on_page != nil or assigns.page_path != nil)
    search? = assigns.on_search != nil or assigns.search_placeholder != nil
    bar? = assigns.title != [] or search? or assigns.filters != [] or assigns.actions != []
    toggle = JS.toggle(to: "#" <> assigns.id <> "-filters")

    assigns =
      assigns
      |> assign(:total_n, total)
      |> assign(:pages, pages)
      |> assign(:first, first)
      |> assign(:last, last)
      |> assign(:footer?, footer?)
      |> assign(:search?, search?)
      |> assign(:bar?, bar?)
      |> assign(:grid?, assigns.variant == "grid")
      |> assign(:toggle, toggle)
      |> assign(:table_variant, if(assigns.variant == "grid", do: "grid"))
      |> assign(:summary_text, summary_text(assigns, first, last, total))
      |> assign(:pager_shape, assigns.pager)
      |> assign(:tray, @tray)
      |> assign(:bar_class, @bar)
      |> assign(:line_class, @row)
      |> assign(:title_class, @title)
      |> assign(:footer_class, @footer)

    ~H"""
    <div id={@id} class={[@tray, @class]} data-part="data-table" {@rest}>
      <div
        :if={@toolbar != []}
        data-part="data-table-toolbar"
        class={[@line_class, "border-b border-line px-3 py-2.5"]}
      >
        {render_slot(@toolbar)}
      </div>
      <div :if={@bar? and not @grid?} data-part="data-table-header" class={@bar_class}>
        <span :if={@title != []} data-part="data-table-title" class={@title_class}>{render_slot(
          @title
        )}</span>
        <div class="ml-auto flex items-center gap-1.5">
          <.table_search
            :if={@search?}
            id={@id}
            value={@search}
            on_search={@on_search}
            target={@target}
            placeholder={@search_placeholder}
          />
          <Button.button :if={@filters != []} canvas size="sm" phx-click={@toggle}>
            <.icon name="filter" size="md" />{@filter_label}
          </Button.button>
          {render_slot(@actions)}
        </div>
      </div>
      <div
        :if={@bar? and @grid?}
        data-part="data-table-header"
        class={[@line_class, "justify-end px-3 py-2.5"]}
      >
        <.table_search
          :if={@search?}
          id={@id}
          value={@search}
          on_search={@on_search}
          target={@target}
          placeholder={@search_placeholder}
        />
        {render_slot(@actions)}
      </div>
      <div
        :if={@filters != []}
        id={@id <> "-filters"}
        data-part="data-table-filters"
        class="hidden border-b border-line px-3 py-2.5"
      >
        {render_slot(@filters, @toggle)}
      </div>
      <%= if @body == "card" do %>
        <div
          data-part="data-table-body"
          class="relative min-w-0 flex-1 overflow-auto rounded-lg border border-line bg-panel p-0"
        >
          <.data_table_body {assigns} wrapper={false} />
        </div>
      <% else %>
        <.data_table_body {assigns} wrapper={true} />
      <% end %>
      {render_slot(@bulk)}
      <div :if={@footer?} data-part="data-table-footer" class={@footer_class}>
        <span :if={@summary == []}>{@summary_text}</span>
        <span :if={@summary != []}>
          {render_slot(@summary, %{first: @first, last: @last, total: @total_n})}
        </span>
        <span class="min-w-0 flex-1"></span>
        <form
          :if={@page_sizes != [] and @on_page_size}
          id={@id <> "-page-size"}
          phx-change={@on_page_size}
          phx-target={@target}
        >
          <label class="text-xs leading-4 text-muted">
            {@show_label}
            <select
              name="page_size"
              class="h-8 rounded-[8px] border border-line-strong bg-panel px-2.5 text-ink"
            >
              <option :for={n <- @page_sizes} value={n} selected={n == @page_size}>{n}</option>
            </select>
            {@entries_label}
          </label>
        </form>
        <.data_table_pager
          page={@page}
          pages={@pages}
          shape={@pager_shape}
          on_page={@on_page}
          page_path={@page_path}
          target={@target}
          page_label={@page_label}
          prev_label={@prev_label}
          next_label={@next_label}
          siblings={@pager_siblings}
          arrows={@pager_arrows}
        />
      </div>
    </div>
    """
  end

  # The table, with the data table's slots forwarded to `Table.table/1`.
  defp data_table_body(assigns) do
    ~H"""
    <%= if @loading do %>
      <Table.table_skeleton
        id={@id <> "-table"}
        rows={@loading_rows}
        columns={Enum.map(@col, &(&1[:label] || ""))}
        variant={@table_variant}
        compact={@compact}
        headless={@headless}
      />
    <% else %>
      <Table.table
        id={@id <> "-table"}
        rows={@rows}
        wrapper={@wrapper}
        row_id={@row_id}
        row_key={@row_key}
        row_item={@row_item}
        row_click={@row_click}
        row_class={@row_class}
        row_attrs={@row_attrs}
        variant={@table_variant}
        hoverable={@hoverable}
        sort_by={@sort_by}
        sort_dir={@sort_dir}
        on_sort={@on_sort}
        selected={@selected}
        all_selected={@all_selected}
        on_select={@on_select}
        on_select_all={@on_select_all}
        compact={@compact}
        headless={@headless}
        borderless={@borderless}
        sticky_header={@sticky_header}
        scroll_label={@scroll_label}
        sort_label={@sort_label}
        row_label={@row_label}
        select_all_label={@select_all_label}
        select_label={@select_label}
        expand_label={@expand_label}
        peek={@peek}
        peek_label={@peek_label}
        target={@target}
        wrapper_class={@wrapper_class}
        select_attrs={@select_attrs}
        body_class={@body_class}
      >
        <:col
          :let={row}
          :for={c <- @col}
          label={c[:label]}
          class={c[:class]}
          head_class={c[:head_class]}
          align={c[:align]}
          sort_key={c[:sort_key]}
          priority={c[:priority]}
          style={c[:style]}
        >
          {render_slot(c, row)}
        </:col>
        <:action :let={row} :for={a <- @action}>{render_slot(a, row)}</:action>
        <:empty :if={@empty != []}>{render_slot(@empty)}</:empty>
        <:expand :let={ctx} :for={e <- @expand}>{render_slot(e, ctx)}</:expand>
        <:foot
          :for={f <- @foot}
          class={f[:class]}
          align={f[:align]}
          colspan={f[:colspan]}
          priority={f[:priority]}
        >
          {render_slot(f)}
        </:foot>
      </Table.table>
    <% end %>
    """
  end

  defp total_of(rows) when is_list(rows), do: length(rows)
  defp total_of(_), do: 0

  defp ceil_div(a, b), do: div(a + b - 1, b)

  defp summary_text(%{summary_label: nil, variant: "grid"}, first, last, total),
    do: "Showing #{first} to #{last} of #{total} results"

  defp summary_text(%{summary_label: nil}, first, last, total),
    do: "#{first} - #{last} of #{total} entries"

  defp summary_text(%{summary_label: label}, first, last, total) do
    label
    |> String.replace("%{from}", to_string(first))
    |> String.replace("%{to}", to_string(last))
    |> String.replace("%{total}", to_string(total))
  end

  # -- pager ------------------------------------------------------------------------------------

  attr :page, :integer, required: true
  attr :pages, :integer, required: true, doc: "How many pages there are."

  attr :shape, :string,
    default: "rounded",
    values: ~w(rounded pill circle canvas pages)

  attr :on_page, :any, default: nil, doc: "Event or `%JS{}` sent with `%{\"page\" => \"3\"}`."

  attr :page_path, :any,
    default: nil,
    doc: "Function of a page number returning a path (patch links)."

  attr :target, :any, default: nil
  attr :page_label, :string, default: "Page %{page}"
  attr :prev_label, :string, default: "Previous"
  attr :next_label, :string, default: "Next"
  attr :siblings, :integer, default: 1
  attr :arrows, :boolean, default: true
  attr :class, :any, default: nil
  attr :rest, :global

  @doc """
  The pager of the data table footer: the page numbers (`rounded`, `pill`, `circle`, `canvas`) or
  the buttons of `pages`. Pages near the current one, the first and the last, with `…` between.
  """
  def data_table_pager(%{shape: "pages"} = assigns) do
    assigns =
      assigns
      |> assign(:items, page_items(assigns.page, assigns.pages, assigns.siblings))
      |> assign(:btn, @pages_btn)
      |> assign(:on_class, @pages_on)

    ~H"""
    <div
      data-part="data-table-pager"
      class={["flex items-center gap-1", @class]}
      data-lu-single=""
      {@rest}
    >
      <button
        :if={@arrows}
        data-part="data-table-page"
        aria-label={@prev_label}
        class={@btn}
        type="button"
        phx-click={@page > 1 && @on_page}
        phx-value-page={@page - 1}
        phx-target={@target}
      >
        <.icon name="chevron-left" size="md" />
      </button>
      <%= for item <- @items do %>
        <button
          :if={item != :gap}
          data-part="data-table-page"
          class={[@btn, item == @page && @on_class]}
          type="button"
          aria-label={String.replace(@page_label, "%{page}", to_string(item))}
          aria-current={item == @page && "page"}
          phx-click={@on_page}
          phx-value-page={item}
          phx-target={@target}
        >
          {item}
        </button>
        <button :if={item == :gap} data-part="data-table-page" class={@btn} type="button">…</button>
      <% end %>
      <button
        :if={@arrows}
        data-part="data-table-page"
        aria-label={@next_label}
        class={@btn}
        type="button"
        phx-click={@page < @pages && @on_page}
        phx-value-page={@page + 1}
        phx-target={@target}
      >
        <.icon name="chevron-right" size="md" />
      </button>
    </div>
    """
  end

  def data_table_pager(assigns) do
    look = @pg_look[assigns.shape]

    assigns =
      assigns
      |> assign(:items, page_items(assigns.page, assigns.pages, assigns.siblings))
      |> assign(:page_class, [@pg_page, look.page])
      |> assign(:on_class, look.on)
      |> assign(:arrow_class, [
        "grid h-[26px] min-w-[26px] place-items-center border border-line-strong px-1.5 text-ink-2",
        look.arrow
      ])

    ~H"""
    <div
      data-part="data-table-pager"
      class={["flex items-center gap-1 font-mono text-[13px]", @class]}
      {@rest}
    >
      <%= for item <- @items do %>
        <%= cond do %>
          <% item == :gap -> %>
            <span data-part="data-table-page" class={@page_class}>…</span>
          <% @page_path -> %>
            <.link
              patch={@page_path.(item)}
              data-part="data-table-page"
              class={[@page_class, item == @page && @on_class]}
              aria-label={String.replace(@page_label, "%{page}", to_string(item))}
              aria-current={item == @page && "page"}
            >
              {item}
            </.link>
          <% true -> %>
            <span
              data-part="data-table-page"
              class={[@page_class, item == @page && @on_class]}
              aria-label={String.replace(@page_label, "%{page}", to_string(item))}
              aria-current={item == @page && "page"}
              phx-click={@on_page}
              phx-value-page={item}
              phx-target={@target}
            >
              {item}
            </span>
        <% end %>
      <% end %>
      <span
        :if={@arrows and @page < @pages}
        data-part="data-table-page"
        class={@arrow_class}
        aria-label={@next_label}
        phx-click={@on_page}
        phx-value-page={@page + 1}
        phx-target={@target}
      >
        <.icon name="chevron-right" size="sm" />
      </span>
    </div>
    """
  end

  # Page numbers to draw: first, last and the ones around `page`, with `:gap` where pages are skipped.
  defp page_items(_page, pages, _sib) when pages <= 1, do: [1]

  defp page_items(page, pages, sib) do
    keep = Enum.uniq([1, pages | Enum.filter((page - sib)..(page + sib), &(&1 in 1..pages))])

    keep
    |> Enum.sort()
    |> Enum.flat_map_reduce(nil, fn n, prev ->
      cond do
        prev == nil -> {[n], n}
        n - prev == 2 -> {[prev + 1, n], n}
        n - prev > 2 -> {[:gap, n], n}
        true -> {[n], n}
      end
    end)
    |> elem(0)
  end

  # -- search -----------------------------------------------------------------------------------

  attr :id, :string, required: true
  attr :value, :string, default: ""
  attr :on_search, :any, default: nil, doc: "Event name or `%JS{}` for the query changes."
  attr :target, :any, default: nil
  attr :placeholder, :string, default: nil
  attr :width, :string, default: "220px"
  attr :shortcut, :string, default: nil, doc: "A key hint (`/`) drawn at the right."
  attr :class, :any, default: nil
  attr :rest, :global

  @doc """
  The search field of the title bar (a sunken box, 32px). With `on_search`, the field sits in a
  form (`<id>-search-form`, input `<id>-search`) that sends `%{"search" => query}` on every change
  (debounced 300ms) and on submit.
  """
  def table_search(%{on_search: nil} = assigns) do
    assigns = assign(assigns, :box, search_box(assigns.class))

    ~H"""
    <span data-part="table-search" class={@box} style={"width:" <> @width} {@rest}>
      <.icon name="search" size="md" class="text-muted" />
      <input
        class={search_input()}
        placeholder={@placeholder || "Search here..."}
        value={@value != "" && @value}
      />
      <Typography.kbd :if={@shortcut}>{@shortcut}</Typography.kbd>
    </span>
    """
  end

  def table_search(assigns) do
    assigns = assign(assigns, :box, search_box(assigns.class))

    ~H"""
    <form
      id={@id <> "-search-form"}
      phx-change={@on_search}
      phx-submit={@on_search}
      phx-target={@target}
      class="contents"
    >
      <span data-part="table-search" class={@box} style={"width:" <> @width} {@rest}>
        <.icon name="search" size="md" class="text-muted" />
        <input
          id={@id <> "-search"}
          class={search_input()}
          name="search"
          type="search"
          autocomplete="off"
          placeholder={@placeholder || "Search here..."}
          aria-label={@placeholder || "Search here..."}
          value={@value}
          phx-debounce="300"
        />
        <Typography.kbd :if={@shortcut}>{@shortcut}</Typography.kbd>
      </span>
    </form>
    """
  end

  defp search_box(class) do
    [
      "flex h-8 min-w-0 items-center gap-2 rounded-[8px] border border-transparent bg-sunken px-2.5 text-ink transition-[border-color,box-shadow] duration-150",
      "focus-within:border-accent-500 focus-within:bg-panel focus-within:shadow-[0_0_0_3px_var(--lu-focus)]",
      class
    ]
  end

  defp search_input do
    "h-full min-w-0 flex-1 appearance-none border-0 bg-transparent p-0 text-[14px] text-ink outline-0 placeholder:text-muted placeholder:opacity-85 focus:outline-0 [&::-webkit-search-cancel-button]:appearance-none"
  end

  # -- toolbar ----------------------------------------------------------------------------------

  attr :id, :string, default: "table-toolbar"

  attr :search, :string,
    default: nil,
    doc: "The current query; the search field shows when `on_search` or `search` is given."

  attr :on_search, :any, default: nil
  attr :search_placeholder, :string, default: nil
  attr :search_width, :string, default: "260px"
  attr :shortcut, :string, default: nil

  attr :filters, :list,
    default: [],
    doc: "Applied filters as chips: `[%{id: \"plan\", label: \"Plano: Pro\"}]`."

  attr :on_remove_filter, :any,
    default: nil,
    doc: "Sent with `%{\"id\" => id}` by a chip's remove button."

  attr :on_clear, :any, default: nil
  attr :filters_label, :string, default: "Filtros:"
  attr :clear_label, :string, default: "Limpar tudo"
  attr :remove_label, :string, default: "Remover"
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :start, doc: "Controls right after the search (a filter button, a view switch)."
  slot :actions, doc: "Buttons at the right end."

  @doc """
  The toolbar above a table: search, controls, actions, and the row of applied filters as
  removable chips.
  """
  def table_toolbar(assigns) do
    assigns =
      assigns
      |> assign(
        :search?,
        assigns.on_search != nil or assigns.search != nil or assigns.search_placeholder != nil
      )
      |> assign(:chips?, assigns.filters != [])
      |> assign(:line_class, @row)

    ~H"""
    <div
      :if={@chips?}
      data-part="table-toolbar"
      class={["flex flex-col gap-2.5", @class]}
      {@rest}
    >
      <.toolbar_row {assigns} />
      <div class={@line_class}>
        <span class="text-xs leading-4 text-muted">{@filters_label}</span>
        <span
          :for={f <- @filters}
          data-part="table-filter-chip"
          class="inline-flex h-[26px] items-center gap-1.5 rounded-sm border border-line-strong bg-panel pr-1.5 pl-[9px] text-[13px] text-ink-2"
        >
          {f.label}<button
            aria-label={@remove_label}
            data-lu-remove=""
            type="button"
            class="grid size-[18px] cursor-pointer place-items-center rounded-[4px] border-0 bg-transparent p-0 text-muted hover:bg-hover hover:text-ink"
            phx-click={@on_remove_filter}
            phx-value-id={f.id}
            phx-target={@target}
          ><.icon name="x" size="sm" /></button>
        </span>
        <button
          :if={@on_clear}
          data-part="table-clear"
          class="inline-flex cursor-pointer items-center justify-center gap-1.5 border-0 bg-transparent px-2.5 py-0 text-[13px] leading-none font-medium whitespace-nowrap text-accent-content hover:underline hover:underline-offset-[3px]"
          type="button"
          phx-click={@on_clear}
          phx-target={@target}
        >
          {@clear_label}
        </button>
      </div>
    </div>
    <.toolbar_row :if={!@chips?} {assigns} />
    """
  end

  defp toolbar_row(assigns) do
    ~H"""
    <div
      data-part="table-toolbar"
      class={[@line_class, !@chips? && @class]}
      {if @chips?, do: [], else: @rest}
    >
      <.table_search
        :if={@search?}
        id={@id}
        value={@search || ""}
        on_search={@on_search}
        target={@target}
        placeholder={@search_placeholder}
        width={@search_width}
        shortcut={@shortcut}
      />
      {render_slot(@start)}
      <span :if={@actions != []} class="min-w-0 flex-1"></span>
      {render_slot(@actions)}
    </div>
    """
  end
end
