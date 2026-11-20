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

  A `:toolbar` slot (a `lu-row` with a rule under it, for a search and buttons written by hand),
  `body="card"` (the table directly in a `lu-card-b` instead of a `lu-tablewrap`) and the pager
  looks `canvas` (plain) and `pages` (buttons, with previous arrow).

  ## Not implemented

  `peek`, `peek_label` and `pager_siblings`/`pager_arrows` for the `lu-pager` footer are accepted;
  `peek` draws nothing yet. The pager spans are not focusable (they carry `phx-click` only).
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Table

  @shapes %{
    "rounded" => "rounded",
    "pill" => "pill",
    "circle" => nil,
    "canvas" => nil,
    "pages" => nil
  }

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
      |> assign(:shape_class, @shapes[assigns.pager])

    ~H"""
    <div id={@id} class={cx(["lu-card", @class])} data-part="data-table" {@rest}>
      <div
        :if={@toolbar != []}
        class="lu-row"
        style="padding:10px 12px;border-bottom:1px solid var(--line)"
      >
        {render_slot(@toolbar)}
      </div>
      <div :if={@bar? and not @grid?} class="lu-card-h">
        <span :if={@title != []} class="lu-card-t">{render_slot(@title)}</span>
        <div class="act">
          <.table_search
            :if={@search?}
            id={@id}
            value={@search}
            on_search={@on_search}
            target={@target}
            placeholder={@search_placeholder}
          />
          <button :if={@filters != []} class="lu-btn sm" type="button" phx-click={@toggle}>
            <.icon name="filter" />{@filter_label}
          </button>
          {render_slot(@actions)}
        </div>
      </div>
      <div
        :if={@bar? and @grid?}
        class="lu-row"
        style="padding:10px 12px;justify-content:flex-end"
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
        style="display:none;padding:10px 12px;border-bottom:1px solid var(--line)"
      >
        {render_slot(@filters, @toggle)}
      </div>
      <%= if @body == "card" do %>
        <div class="lu-card-b" style="padding:0;overflow:auto">
          <.data_table_body {assigns} wrapper={false} />
        </div>
      <% else %>
        <.data_table_body {assigns} wrapper={true} />
      <% end %>
      {render_slot(@bulk)}
      <div :if={@footer?} class="lu-card-f">
        <span :if={@summary == []}>{@summary_text}</span>
        <span :if={@summary != []}>
          {render_slot(@summary, %{first: @first, last: @last, total: @total_n})}
        </span>
        <span class="lu-grow"></span>
        <form
          :if={@page_sizes != [] and @on_page_size}
          id={@id <> "-page-size"}
          phx-change={@on_page_size}
          phx-target={@target}
        >
          <label class="lu-xs lu-muted">
            {@show_label}
            <select name="page_size" class="lu-input sm">
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
  The pager of the data table footer: `lu-pg2` (`rounded`, `pill`, `circle`, `canvas`) or the
  `lu-pages` buttons. Pages near the current one, the first and the last, with `…` between.
  """
  def data_table_pager(%{shape: "pages"} = assigns) do
    assigns = assign(assigns, :items, page_items(assigns.page, assigns.pages, assigns.siblings))

    ~H"""
    <div class={cx(["lu-pages", @class])} data-lu-single="" {@rest}>
      <button
        :if={@arrows}
        aria-label={@prev_label}
        class="lu-btn icon ghost sm"
        type="button"
        phx-click={@page > 1 && @on_page}
        phx-value-page={@page - 1}
        phx-target={@target}
      >
        <.icon name="chevron-left" />
      </button>
      <%= for item <- @items do %>
        <button
          :if={item != :gap}
          class={item == @page && "on"}
          type="button"
          aria-label={String.replace(@page_label, "%{page}", to_string(item))}
          aria-current={item == @page && "page"}
          phx-click={@on_page}
          phx-value-page={item}
          phx-target={@target}
        >
          {item}
        </button>
        <button :if={item == :gap} class="" type="button">…</button>
      <% end %>
      <button
        :if={@arrows}
        aria-label={@next_label}
        class="lu-btn icon ghost sm"
        type="button"
        phx-click={@page < @pages && @on_page}
        phx-value-page={@page + 1}
        phx-target={@target}
      >
        <.icon name="chevron-right" />
      </button>
    </div>
    """
  end

  def data_table_pager(assigns) do
    assigns =
      assigns
      |> assign(:items, page_items(assigns.page, assigns.pages, assigns.siblings))
      |> assign(:classes, cx(["lu-pg2 s-sm", @shapes[assigns.shape], assigns.class]))
      |> assign(:style, if(assigns.shape == "circle", do: "--r:50%", else: ""))

    ~H"""
    <div class={@classes} style={@style} {@rest}>
      <%= for item <- @items do %>
        <%= cond do %>
          <% item == :gap -> %>
            <span>…</span>
          <% @page_path -> %>
            <.link
              patch={@page_path.(item)}
              class={item == @page && "on"}
              aria-label={String.replace(@page_label, "%{page}", to_string(item))}
            >
              {item}
            </.link>
          <% true -> %>
            <span
              class={item == @page && "on"}
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
        class="ar"
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
  The search field of the title bar (`lu-input sm search`). With `on_search`, the field sits in a
  form (`<id>-search-form`, input `<id>-search`) that sends `%{"search" => query}` on every change
  (debounced 300ms) and on submit.
  """
  def table_search(%{on_search: nil} = assigns) do
    assigns = assign(assigns, :classes, cx(["lu-input sm search", assigns.class]))

    ~H"""
    <span class={@classes} style={"width:" <> @width} {@rest}>
      <.icon name="search" size="md" />
      <input placeholder={@placeholder || "Search here..."} value={@value != "" && @value} />
      <kbd :if={@shortcut} class="lu-kbd">{@shortcut}</kbd>
    </span>
    """
  end

  def table_search(assigns) do
    assigns = assign(assigns, :classes, cx(["lu-input sm search", assigns.class]))

    ~H"""
    <form
      id={@id <> "-search-form"}
      phx-change={@on_search}
      phx-submit={@on_search}
      phx-target={@target}
      style="display:contents"
    >
      <span class={@classes} style={"width:" <> @width} {@rest}>
        <.icon name="search" size="md" />
        <input
          id={@id <> "-search"}
          name="search"
          type="search"
          autocomplete="off"
          placeholder={@placeholder || "Search here..."}
          aria-label={@placeholder || "Search here..."}
          value={@value}
          phx-debounce="300"
        />
        <kbd :if={@shortcut} class="lu-kbd">{@shortcut}</kbd>
      </span>
    </form>
    """
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

    ~H"""
    <div :if={@chips?} class={cx(["lu-col", @class])} style="gap:10px" {@rest}>
      <.toolbar_row {assigns} />
      <div class="lu-row">
        <span class="lu-xs lu-muted">{@filters_label}</span>
        <span :for={f <- @filters} class="lu-tag">
          {f.label}<button
            aria-label={@remove_label}
            data-lu-remove=""
            type="button"
            phx-click={@on_remove_filter}
            phx-value-id={f.id}
            phx-target={@target}
          ><.icon name="x" size="sm" /></button>
        </span>
        <button
          :if={@on_clear}
          class="lu-btn link sm"
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
    <div class={cx(["lu-row", !@chips? && @class])} {if @chips?, do: [], else: @rest}>
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
      <span :if={@actions != []} class="lu-grow"></span>
      {render_slot(@actions)}
    </div>
    """
  end
end
