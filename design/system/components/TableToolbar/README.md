# TableToolbar

Barra acima de tabelas com busca, filtros rápidos, troca de visão e ações.

**Grupo:** 08 · Tabelas  
**Resumo visual:** Busca, chips de filtro, visualização e ações

## Uso (Phoenix / HEEx)

```heex
<.table_toolbar search={@q} filters={@filters} view={@view} />
```

## Regras

- Filtros aplicados aparecem como chips removíveis.
- Ação primária à direita.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: data_table)

Todos os function components, atributos, valores e slots que este componente cobre.

A table with a search box, sortable headers, a pagination footer and row selection, in the
two looks Ledger UI shows: `advanced` (the Table Advanced page: a title bar with a search
that slides open, the table as a card, "Show 10 entries" and a pager underneath) and `grid`
(the Grid Table page: a search box on the right, sort arrows, "Showing 1 to 10 of 15
results" and Previous/Next).

The LiveView owns the state: it filters, sorts and slices the rows and gives the component
the current page; the component only renders it and sends events back.

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
      <:title>Users Table</:title>
      <:col :let={user} label="Name" sort_key="name">{user.name}</:col>
      <:col :let={user} label="Email">{user.email}</:col>
    </.data_table>

    def handle_event("search", %{"search" => q}, socket), do: ...
    def handle_event("sort", %{"column" => col, "direction" => dir}, socket), do: ...
    def handle_event("paginate", %{"page" => page}, socket), do: ...

Rows may be a stream (`rows={@streams.users}`); the body then renders with
`phx-update="stream"` and `total` drives the footer. `:col`, `:action`, `:expand`,
`:empty`, `row_id`, `row_key`, `row_item`, `row_click` and selection work as in
`LedgerUI.Components.Table.table/1`, and so do the columns that leave by `priority` when the
box gets narrow, and `peek` to read them in a panel.

### `<.data_table>`

Renders a data table. The LiveView passes the rows of the current page and handles the
events below.

    <.data_table
      id="contacts"
      variant="grid"
      rows={@rows}
      total={@total}
      page={@page}
      on_page="paginate"
      search={@search}
      on_search="search"
      sort_by={@sort_by}
      sort_dir={@sort_dir}
      on_sort="sort"
      row_key={& &1.id}
      selected={@selected}
      on_select="select"
      on_select_all="select_all"
    >
      <:col :let={c} label="Name" sort_key="name">{c.name}</:col>
      <:col :let={c} label="Email" sort_key="email">{c.email}</:col>
    </.data_table>

Events, each an event name or a `%JS{}` (sent to `target` when given):

* `on_search` — the search input changed or was submitted: `%{"search" => query}`.
* `on_sort` — a sortable header was clicked: `%{"column" => sort_key, "direction" => "asc" | "desc"}`,
  the direction to sort by next.
* `on_page` — a page was chosen: `%{"page" => "3"}` (a string, as every `phx-value-*`).
  With `page_path` (a function of the page number) the pager renders `patch` links instead.
* `on_page_size` — the "Show N entries" select changed: `%{"page_size" => "30"}`.
* `on_select` — a row checkbox: `%{"id" => key, "selected" => "true" | "false"}`.
* `on_select_all` — the header checkbox: `%{"selected" => "true" | "false"}`.

The footer shows when `on_page` or `page_path` is given (unless `footer={false}`); the search
when `on_search` is. The `advanced` title bar shows only when there is something in it (a
`:title`, the search, `:filters` or `:actions`). `pager="canvas"` is the design canvas footer and
`loading` draws skeleton rows for the first load.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `rows` (required) | `:any` |  | The rows of the current page, a list or a stream. |
| `variant` | `:string` | `"advanced"` | `advanced`, `grid` |
| `row_id` | `:any` | `nil` | A function giving each row's DOM id; streams default to the stream id. |
| `row_key` | `:any` | `nil` | A function giving a row's selection key; defaults to its DOM id. |
| `row_item` | `:any` | `&Function.identity/1` | Maps each row before the slots get it. |
| `row_click` | `:any` | `nil` | A function of the row returning a `JS` or an event name. |
| `hoverable` | `:boolean` | `nil` | Highlights the hovered row; on by default, off for expandable rows. |
| `search` | `:string` | `""` | The current query. |
| `search_placeholder` | `:string` | `nil` | Placeholder of the search input. |
| `on_search` | `:any` | `nil` | See the events above. |
| `sort_by` | `:string` | `nil` | The `sort_key` of the sorted column. |
| `sort_dir` | `:string` | `"asc"` | `asc`, `desc` — Direction of `sort_by`. |
| `on_sort` | `:any` | `nil` | See the events above. |
| `page` | `:integer` | `1` | The current page, from 1. |
| `page_size` | `:integer` | `10` | Rows per page. |
| `total` | `:integer` | `nil` | Rows across every page. Defaults to the row count. |
| `on_page` | `:any` | `nil` | See the events above. |
| `page_path` | `:any` | `nil` | A function of the page number returning a path. |
| `footer` | `:boolean` | `true` | `false` leaves out the footer (pager, summary and page-size select) even when `on_page` is given, for a table with only a search. |
| `compact` | `:boolean` | `false` | Tighter cells, see `table/1`. |
| `row_class` | `:any` | `nil` | Extra classes of a row's `<tr>`, see `table/1`. |
| `row_attrs` | `:any` | `nil` | Extra attributes of a row's `<tr>`, see `table/1`. |
| `sticky_header` | `:boolean` | `false` | Sticky header row, see `table/1`. |
| `scroll_label` | `:string` | `nil` | Names the scrolling wrapper, see `table/1`. |
| `peek` | `:boolean` | `false` | Rows show the columns hidden by `priority` in a panel on hover and focus, see `table/1`. |
| `peek_label` | `:string` | `"Hidden columns"` | `aria-label` of the panel. |
| `sort_label` | `:string` | `nil` | `aria-label` of the sort buttons, a prefix or a `%{label}` template, see `table/1`. |
| `row_label` | `:any` | `nil` | Label of a row's checkbox, see `table/1`. |
| `headless` | `:boolean` | `false` | No `<thead>`, see `table/1`. |
| `borderless` | `:boolean` | `false` | No row rules, see `table/1`. |
| `page_sizes` | `:list` | `[]` | Options of the "Show N entries" select. |
| `on_page_size` | `:any` | `nil` | See the events above. |
| `pager` | `:string` | `"rounded"` | `rounded`, `pill`, `circle`, `canvas` — The pager look of the `advanced` variant; `canvas` is the design canvas footer (`lu-pager`): the summary at the left, `pagination/1` with `shape="canvas"` at the right. |
| `pager_siblings` | `:integer` | `1` | With `pager="canvas"`, the pages kept on each side of the current one (`2` shows "1 2 3 … 10"). |
| `pager_arrows` | `:boolean` | `true` | With `pager="canvas"`, the previous and next arrows after the pages. |
| `loading` | `:boolean` | `false` | Draws `loading_rows` skeleton rows under the headers instead of the rows (the first load), and marks the table `aria-busy`. |
| `loading_rows` | `:integer` | `3` | How many skeleton rows `loading` draws. |
| `show_label` | `:string` | `"Show"` | Text before the page-size select. |
| `entries_label` | `:string` | `"entries"` | Text after the page-size select. |
| `prev_label` | `:string` | `"Previous"` | Text of the `grid` pager's first button. |
| `next_label` | `:string` | `"Next"` | Text of the `grid` pager's last button. |
| `page_label` | `:string` | `"Page %{page}"` | `aria-label` of each page button; `%{page}` is replaced. |
| `summary_label` | `:string` | `nil` | The summary text, `%{from}`, `%{to}` and `%{total}` being replaced (the `grid` variant shows them in bold): "Showing 1 to 10 of 15 results" in `grid`, "1 - 10 of 15 entries" in `advanced`. The `:summary` slot replaces it. |
| `select_all_label` | `:string` | `"Select all rows"` | `aria-label` of the header checkbox. |
| `select_label` | `:string` | `"Select row"` | `aria-label` of each row checkbox. |
| `selected` | `:list` | `[]` | Keys of the selected rows. |
| `all_selected` | `:boolean` | `nil` | Whether the header checkbox is checked; computed for lists. |
| `on_select` | `:any` | `nil` | See the events above. |
| `on_select_all` | `:any` | `nil` | See the events above. |
| `expand_label` | `:string` | `nil` | Header of the expand column. |
| `target` | `:any` | `nil` | `phx-target` of every event. |
| `class` | `:any` | `nil` |  |
| `wrapper_class` | `:any` | `nil` | Merged into the box that scrolls the table, e.g. `max-h-60` to scroll the rows under a `sticky_header`. |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:action>` — Cells appended to every row.
- `<:actions>` — Buttons at the right of the `advanced` title bar.
- `<:col>` (required) — attrs: `label`, `class`, `head_class`, `align`, `sort_key`, `priority` — A column; receives the row (after `row_item`).
- `<:empty>` — Shown when `rows` is an empty list.
- `<:expand>` — Detail under each row, see `LedgerUI.Components.Table.table/1`.
- `<:filters>` — A filter panel the `advanced` title bar's filter button opens. Receives the `JS` that toggles it.
- `<:foot>` — attrs: `class`, `align`, `colspan`, `priority` — A cell of the totals row, see `table/1`.
- `<:summary>` — Replaces the "1 - 10 of 15 entries" text; receives `%{first: n, last: n, total: n}`.
- `<:title>` — The `advanced` variant's heading.

### `<.table_search>`

Ledger UI's collapsing search: a magnifier button that slides a borderless input open, as in the
title bar of the Table Advanced page. `data_table/1` uses it, and it works on its own next to
any title.

    <div class="flex items-center justify-between">
      <h2>Users</h2>
      <.table_search id="users" value={@search} on_search="search" />
    </div>

Events: `on_search` (an event name or `%JS{}`, sent to `target` when given) receives
`%{"search" => query}` on every change (debounced 300ms) and on submit. The input has the
DOM id `#{id}-search` and the form `#{id}-search-form`. The input starts open when `value`
is not empty.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `value` | `:string` | `""` | The current query. |
| `on_search` | `:any` | `nil` | Event name or `%JS{}` for the query changes. |
| `target` | `:any` | `nil` | `phx-target` of `on_search`. |
| `placeholder` | `:string` | `nil` | Placeholder and label; "Search here..." by default. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.
