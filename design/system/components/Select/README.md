# Select

Seleção de uma opção numa lista curta, com gatilho no formato de input.

**Grupo:** 04 · Formulários — seleção  
**Resumo visual:** variant outline/filled · size · shape · múltiplo com overflow count/wrap · busca control/panel/none

## Uso (Phoenix / HEEx)

```heex
<.select field={@form[:plan]} options={["Pro", "Scale", "Starter"]} />
```

## Regras

- Até ~10 opções; acima disso use Autocomplete.
- Opção escolhida em 500 com check teal à direita.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: select)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's selects: the styled native `<select>` of the Select page and the searchable
listbox of the Tom Select page, with chips, groups, a clear button and created options.

    <.select native label="What type of event is it?" options={~w(Wedding Birthday Other)} />
    <.select native variant="filled" shape="pill" size="sm" field={@form[:kind]} options={@kinds} />
    <.select native inline shape="pill" size="sm" name="period" options={~w(Week Month Year)} />

    <.select field={@form[:state]} options={[{"Alabama", "AL"}, {"Alaska", "AK"}]} multiple removable
             placeholder="Select a state..." />
    <.select field={@form[:author]} options={@authors} on_search="search_authors" target={@myself}>
      <:option :let={author}>{author.label} · {author.job}</:option>
    </.select>

Options are strings, `{label, value}` tuples, keyword entries, or maps with `:label` and
`:value` (other keys reach the `:option` and `:item` slots); `{group_label, [options]}` is a
group. See `LedgerUI.Components.Select.Options`.

### Pillbox

A `multiple` listbox is a pillbox by default (`overflow="count"`): it keeps one line, 38px high
(`sm` 32px, `lg` 48px), and the chips that do not fit are hidden behind a `+N` chip that
names them in its `title` and, for screen readers, in `aria-label` (`more_label` is its word:
`3 more: Pix, Boleto…`). The wrapper carries `data-overflow="count"`; the hook measures the
chips on mount, on every change and when the control is resized. `overflow="wrap"` lets the
chips break into more lines and the control grow instead.

    <.select field={@form[:methods]} options={@methods} multiple removable more_label="more" />
    <.select field={@form[:tags]} options={@tags} multiple overflow="wrap" />

The chosen option shows a check in a 16px slot before its label in the list.

The listbox submits through a hidden `<select>` named like the field (`name[]` when
`multiple`), and fires a bubbling `input` event when the person changes the choice, so a
surrounding `phx-change` runs. A value the server sends wins over the one in the browser;
re-rendering the same value does nothing.

### `<.select>`

Renders a select.

With `native` it is the browser's `<select>` in Ledger UI's look; otherwise the listbox.

### Fixed choices, no search

The listbox searches by default (see `search`). For a short, fixed list (a status, a period, a unit,
yes/no) use `native`: the browser's own `<select>`, with no hook and no search, that submits
like any input, opens the system picker on a phone and works with the keyboard as a plain
select does. `prompt` adds a first, empty option; `{group, options}` entries become
`<optgroup>`s; `inline` shrinks it to its content for a card header.

    <.select native field={@form[:status]} label="Status" prompt="Any status"
             options={[{"Open", "open"}, {"Paid", "paid"}, {"Canceled", "canceled"}]} />
    <form phx-change="period">
      <.select native inline shape="pill" size="sm" name="period" value={@period}
               options={[{"This week", "week"}, {"This month", "month"}]} />
    </form>

Only `variant`, `size`, `shape`, `inline` and `prompt` apply to it; `multiple` renders a
`form-multiselect` box. The listbox-only attrs (`removable`, `clearable`, `create`,
`on_search`, the slots...) are ignored.

### Search

`search` sets where the person searches the options of the listbox, always in the tonality of
the component:

  * `"control"` (default): types in the control itself, as in Ledger UI's Tom Select.
  * `"panel"`: the control is a plain trigger and the list opens with a search field on top
    (`search_placeholder` is its text). Arrow keys, Enter and Esc work from that field.
  * `"none"`: no search, the control is a plain trigger (a short list that fits the screen).

    <.select field={@form[:state]} options={@states} search="panel" search_placeholder="Find a state" />
    <.select field={@form[:status]} options={@statuses} search="none" placeholder="Any status" />

A narrow field makes a narrow list. `panel_min_width` gives the list a width of its own, aligned to the
field's left edge, and `panel_class` merges classes into it:

    <.select name="customer" options={@customers} class="w-56" search="panel" panel_min_width="26rem" />

### Size

The same `size` is the same height for every control: `sm` 32px, `md` 40px, `lg` 48px, for the native
select, the listbox and `multiple` pillbox, the input, the date picker and, with `control`, the button.
The tokens are `--ctl-h-sm`, `--ctl-h-md` and `--ctl-h-lg`.

Events: with `on_search` the listbox stops filtering on its own and pushes
`on_search` with `%{"id" => id, "query" => text}` as the person types (after `debounce`
ms), to `target` or to the LiveView/LiveComponent the select is in; the server answers by
re-rendering `options`.

Load more: with `on_load_more` and `has_more`, scrolling the list to within 48px of its end (or opening a
list too short to scroll) pushes `on_load_more` once, with `%{"id" => id, "query" => text, "offset" => n}`
(`n` is how many options are in the list), to `target` or the LiveView. The server appends the next page to
`options` and sets `has_more`; the list keeps its scroll position. While `has_more` is true a last
"Loading…" row (`loading_label`) shows; it is not an option. Nothing is pushed while `has_more` is false or
a request is waiting for its answer (it ends when the list is rendered again).

    def handle_event("load_more", %{"offset" => offset, "query" => query}, socket) do
      limit = 30
      page = Customers.search(query, limit: limit, offset: offset)
      {:noreply, assign(socket, options: socket.assigns.options ++ page, has_more: length(page) == limit)}
    end

A new search makes the server answer with page 1 (and `has_more`) again. A `load_more` answer that arrives
after the term changed is not dropped by the client: compare the `"query"` of the event with your current
term on the server and ignore it if they differ.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` |  | Defaults to the field id, then `name`, then a generated one. |
| `name` | `:string` |  | Defaults to the field name (with `[]` when several values). |
| `value` | `:any` |  | Defaults to the field value. |
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` | A form field: fills `id`, `name`, `value` and `errors`. |
| `label` | `:string` | `nil` |  |
| `label_hint` | `:string` | `nil` | Native only: a dimmed note at the right of the caption, as the canvas's "opcional". |
| `help` | `:string` | `nil` |  |
| `errors` | `:list` | `[]` |  |
| `options` | `:list` | `[]` | Options and groups, see the module doc. |
| `prompt` | `:string` | `nil` | Native only: a first option with an empty value. |
| `placeholder` | `:string` | `nil` |  |
| `multiple` | `:boolean` | `false` |  |
| `disabled` | `:boolean` | `false` |  |
| `native` | `:boolean` | `false` | The browser's own `<select>`. |
| `variant` | `:string` | `"outline"` | `outline`, `filled` — Native only: bordered or filled. |
| `size` | `:string` | `"md"` | `sm`, `md`, `lg` — Native: the height. Listbox: `sm` is the compact 32px control for filter bars. |
| `shape` | `:string` | `"rounded"` | `rounded`, `pill` — Native only. |
| `inline` | `:boolean` | `false` | Native only: the select is as wide as its content (`w-auto pr-9`) instead of filling its parent, for period pills in a card header. |
| `removable` | `:boolean` | `false` | A remove button on each chip. |
| `clearable` | `:boolean` | `false` | A button that removes every choice. |
| `clear_label` | `:string` | `"Clear"` |  |
| `remove_label` | `:string` | `"Remove"` |  |
| `create` | `:boolean` | `false` | What is typed can be added as a new option. |
| `create_label` | `:string` | `"Add"` | The text before the typed term in the create row. |
| `create_hint` | `:string` | `nil` | A key shown in the create row before the label (`"Enter"`); none by default. |
| `persist` | `:boolean` | `true` | A created option stays in the list after it is removed. |
| `restore_on_backspace` | `:boolean` | `false` | Backspace puts the last chip back into the input as text. |
| `max` | `:integer` | `nil` | How many options can be chosen. |
| `overflow` | `:string` | `"count"` | `count`, `wrap` — Listbox with `multiple` only: `count` (the default) keeps one line, a pillbox: the chips that do not fit are hidden and a `+N` chip tells how many; `wrap` lets the chips break into more lines and the control grow. |
| `footer` | `:boolean` | `false` | Listbox with `multiple` only: a line under the list with how many are chosen and a hint. |
| `footer_count` | `:string` | `"%{count} of %{total}"` | The footer's count; `%{count}` is what is chosen and `%{total}` the options. |
| `footer_hint` | `:string` | `"Esc to close"` | The footer's hint. |
| `more_label` | `:string` | `"more"` | Names the `+N` chip for screen readers (`3 more: Pix, Boleto…`). |
| `no_results` | `:string` | `"No results found"` | Shown when the search matches nothing; `%{query}` is replaced by what was typed. |
| `search` | `:string` | `"control"` | `control`, `panel`, `none` — Listbox only: `control` types in the control, `panel` opens the list with a search field on top, `none` has no search. |
| `search_placeholder` | `:string` | `"Search…"` | Listbox only: the placeholder of the `panel` search field. |
| `panel_min_width` | `:string` | `nil` | Listbox only: a CSS length (`"24rem"`), the minimum width of the open list, for a narrow field; it stays aligned to the field's left edge. |
| `panel_class` | `:any` | `nil` | Listbox only: classes merged into the open list. |
| `on_search` | `:string` | `nil` |  |
| `debounce` | `:integer` | `300` |  |
| `target` | `:any` | `nil` |  |
| `on_load_more` | `:string` | `nil` | Listbox only: the event pushed when the list is scrolled near its end (see the Events). |
| `has_more` | `:boolean` | `false` | Listbox only: the server has more options after the ones in `options`. |
| `loading_label` | `:string` | `"Loading…"` | Listbox only: the last row of the list while `has_more` and `on_load_more` are set. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `form`, `autocomplete`, `required`.

Slots:

- `<:below>` — Native only: content between the control and the help line.
- `<:item>` — How a chosen option shows in the control; gets the option map.
- `<:label_aside>` — Native only: content at the right of the caption (a link, a status word).
- `<:option>` — How an option shows in the list; gets the option map (`label`, `value`, `data`).
- `<:suffix>` — Native only: a chip inside the control, at the right and before the arrow. It lets clicks through; add right padding with `class` when the text is long.
