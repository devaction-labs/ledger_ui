# Pagination

Paginação de listas e tabelas.

**Grupo:** 11 · Navegação  
**Resumo visual:** shape canvas · rounded · pill × size sm/md/lg · contagem e itens por página

## Uso (Phoenix / HEEx)

```heex
<.pagination page={@page} total_pages={44} />
```

## Regras

- Página atual com anel e sombra xs (mesma lógica do segmentado).
- Mostre “1–25 de 1.096” à esquerda.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: pagination)

Todos os function components, atributos, valores e slots que este componente cobre.

The pagination: the design canvas pager by default (`shape="canvas"`), or Ledger UI's joined bar or
`divided` buttons, `rounded` or `pill` (`shape="rounded"` is the old default), in three sizes.

    <.pagination page={@page} total_pages={10} patch={&"/orders?page=#{&1}"} />
    <.pagination page={@page} total_pages={10} navigate={&"/orders?page=#{&1}"} divided shape="rounded" />
    <.pagination page={@page} total_pages={10} on_change="paginate" shape="pill" />

Each page is a link when `patch`, `navigate` or `href` is given: a function from the page
number to the path. Otherwise it is a button pushing `on_change` with `%{"page" => "3"}`
(to `target` when given). Pages far from the current one collapse into an ellipsis:
`siblings` pages are kept on each side of the current one and `boundaries` at each end.

A list footer: `total_entries` and `page_size` add the "Showing 1–15 of 128" summary on
the left (and work out `total_pages`), `page_sizes` a rows-per-page select pushing
`on_page_size`.

    <.pagination
      page={@page}
      page_size={@per_page}
      total_entries={@total}
      page_sizes={[15, 30, 50]}
      on_change="paginate"
      on_page_size="per_page"
      summary="Mostrando %{first}–%{last} de %{total}"
      page_size_label="%{size} / página"
    />

`%{shown}` is the rows on the current page (`6 of 14 charges`), and an `:aside` slot puts
content at the right of the pages, or in place of them when there is a single page. With
`class="lu-pager"` the footer takes the canvas pager look:

    <.pagination class="lu-pager" page={@page} page_size={10} total_entries={14}
      summary="%{shown} de %{total} cobranças" on_change="paginate">
      <:aside>Webhook recebido há 2 min</:aside>
    </.pagination>

### `<.pagination>`

Renders the page links between a previous and a next arrow.

    <.pagination page={@page} total_pages={@total} patch={&"/orders?page=#{&1}"} />
    <.pagination page={@page} total_pages={@total} on_change="paginate" target={@myself} />

With `on_change="paginate"` every page and arrow is a button pushing
`"paginate"` with `%{"page" => "3"}` (the page as a string):

    def handle_event("paginate", %{"page" => page}, socket),
      do: {:noreply, assign(socket, page: String.to_integer(page))}

The arrow at either end and the ellipsis (`…`) are inert `<span>`s.

With `total_entries` or `page_sizes` the bar becomes a footer row: the summary
(`role="status"`) on the left, the select and the pages on the right. The select sits in
its own `<form>` and pushes `on_page_size` with `%{"page_size" => "30"}` (to `target`),
so do not put the pagination inside another form.

    def handle_event("per_page", %{"page_size" => size}, socket),
      do: {:noreply, assign(socket, per_page: String.to_integer(size), page: 1)}

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `page` (required) | `:integer` |  | The current page, from 1. |
| `total_pages` | `:integer` | `nil` | How many pages there are. Worked out from `total_entries` and `page_size` when not given. |
| `total_entries` | `:integer` | `nil` | Rows across every page; shows the summary. |
| `page_size` | `:integer` | `nil` | Rows per page; the select's current value. |
| `page_sizes` | `:list` | `[]` | Options of the rows-per-page select. |
| `on_page_size` | `:any` | `nil` | Event name or `%JS{}` of the select's form, pushed with `%{"page_size" => "30"}`. |
| `summary` | `:string` | `"Showing %{first}–%{last} of %{total}"` | The summary text; `%{first}`, `%{last}`, `%{shown}` (the rows on the current page) and `%{total}` are replaced. |
| `page_size_label` | `:string` | `"%{size} / page"` | Text of each select option; `%{size}` is replaced. |
| `page_size_aria` | `:string` | `"Rows per page"` | `aria-label` of the select. |
| `siblings` | `:integer` | `1` | Pages kept on each side of the current one. |
| `boundaries` | `:integer` | `1` | Pages kept at each end. |
| `patch` | `:any` | `nil` | A function from a page number to a path to patch to. |
| `navigate` | `:any` | `nil` | A function from a page number to a path to navigate to. |
| `href` | `:any` | `nil` | A function from a page number to a URL. |
| `on_change` | `:any` | `nil` | Used when no link function is given: an event name pushed with `%{"page" => "3"}`, or a `%JS{}` run on click (its `JS.push` carries the same `page` value).  |
| `target` | `:any` | `nil` | The `phx-target` of `on_change`. |
| `divided` | `:boolean` | `false` | Separate buttons instead of one joined bar. |
| `shape` | `:string` | `"canvas"` | `canvas`, `rounded`, `pill` — `canvas` (the default) is the design canvas pager: square-ish ink current page, mono numbers, the arrows as 28px bordered circles after the pages (not dimmed at either end). The old Ledger UI look is `rounded` (or `pill`). |
| `size` | `:string` | `"md"` | `sm`, `md`, `lg` |
| `arrows` | `:boolean` | `true` | Show the previous and next arrows. |
| `prev_label` | `:string` | `"Previous page"` |  |
| `next_label` | `:string` | `"Next page"` |  |
| `page_label` | `:string` | `"Page %{page}"` | `aria-label` of each page; `%{page}` is replaced. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:aside>` — Content at the right of the pages (before them); with a single page it takes the place of the pages.
