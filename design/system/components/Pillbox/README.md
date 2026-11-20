# Pillbox

Seleção múltipla que mostra os escolhidos como tags removíveis dentro do campo.

**Grupo:** 04 · Formulários — seleção  
**Resumo visual:** size sm/md/lg · overflow one/wrap

## Uso (Phoenix / HEEx)

```heex
<.pillbox field={@form[:segments]} options={@segments} multiple />
```

## Regras

- Tags com raio 6 (sem formato pílula).
- Backspace remove a última tag.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: pillbox)

Todos os function components, atributos, valores e slots que este componente cobre.

A multiple (or, with `multiple={false}`, single) choice from a list, drawn as the design canvas's Pillbox: the chosen options become pills inside
the field, and the list opens under it with a search on top and a check box on every option.

    <.pillbox field={@form[:categories]} label="Categories" options={@categories} />

    <.pillbox
      name="categories"
      value={["tintas", "acessorios"]}
      options={[
        %{label: "Tintas", value: "tintas", count: 128},
        %{label: "Ferramentas", value: "ferramentas", count: 86},
        %{label: "Acessórios", value: "acessorios", count: 54}
      ]}
      clear
    />

    <.pillbox name="tags" options={@tags} value={@chosen} create create_label="Create" />
    <.pillbox name="branches" options={@branches} value={@chosen} overflow="wrap" />
    <.pillbox name="people" options={@people} value={@chosen} />
    <.pillbox name="branches" options={@branches} value={@chosen} readonly label="Branches (read only)" />

Options are strings, `{label, value}` tuples or maps with `:label` and `:value`, as in
`LedgerUI.Components.Select.Options`. A map can also carry

  * `:count`: a faint mono number on the right of its row;
  * `:color` and `:initials`: a person. Its pill gets a 22px avatar with that background; the initials
    default to the first letters of the first and last word of the label.

### Single choice

`multiple={false}` is a searchable single choice with the same look: the chosen option is one pill in the field,
the list opens with the search on top, choosing a row replaces the pill and closes the list (no check boxes),
and the value is submitted as `name` (not `name[]`). `clear` and `readonly` work as in the multiple one.

    <.pillbox name="product_id" value={@product_id} options={@products} multiple={false} label="Product" />

### Size

`size` (`sm` 32px, `md` 36px, `lg` 48px) is the height of an input of that size, so a row of fields lines up.

### Panel width

The list is as wide as the field. In a narrow field, `panel_min_width` (a CSS length: `"22rem"`, `"360px"`)
gives it a minimum width of its own, still aligned to the field's left edge, and `panel_class` merges classes into
the list.

    <.pillbox name="customer" options={@customers} multiple={false} class="w-56" panel_min_width="26rem" />

### Overflow

By default the field keeps to the width the layout gave it and stays on one line (`overflow="one"`): the pills
that do not fit are hidden and a `+N` pill takes their place. Its `title` lists the hidden names and its
`aria-label` is `hidden_label` (`"3 hidden"`; `%{count}` is the number). The hook measures on mount, on every
change and when the field is resized. `overflow="wrap"` lets the pills break into more lines and the field
grow; use it only where the height can vary.

### The list

It opens on click, Enter or the arrow keys. The search field on top (`search_placeholder`) filters the options
ignoring case and accents and shows what matched in bold. Arrow keys move, Enter or a click toggles the option
(the list stays open), Backspace on an empty search takes the last pill back and Esc closes. With `create` a
typed term that is not an option is offered as a last row (`create_label` before the term in curly quotes, and
`create_hint`, the key, on the right); choosing it adds a pill and an option. When nothing matches,
`empty_label` (`%{query}` is the term) is said above that row.

### Form

The pills are submitted as `name[]`, with an empty `name[]` first so that an emptied field still reaches the
server, and each change fires a bubbling `input` event for `phx-change`. `readonly` keeps the values in the form
but takes the x, the chevron and the list away; `disabled` does that and leaves them out of the form.

It is the `LedgerUI.Components.Select` listbox (`multiple`, `search="panel"`), so it shares its hook
(`LedgerUI.Select`), the options and the server-side search (`on_search`, `target`, `debounce`).

### `<.pillbox>`

Renders a pillbox.

Events: with `on_search`, `%{"id" => id, "query" => text}` is pushed to `target` (or the LiveView) as the person
searches, `debounce` ms after the last key; the server answers by re-rendering `options`.

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
| `name` | `:string` |  | Defaults to the field name; `[]` is appended. |
| `value` | `:any` |  | The chosen values (a list). Defaults to the field value. |
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` | A form field: fills `id`, `name`, `value` and `errors`. |
| `options` | `:list` | `[]` | Options and groups, see the module doc. |
| `selected_options` | `:list` | `[]` | Options for chosen values that are not in `options` (after a server search narrowed it). |
| `label` | `:string` | `nil` |  |
| `help` | `:string` | `nil` |  |
| `errors` | `:list` | `[]` |  |
| `multiple` | `:boolean` | `true` | `false` is a single choice (see the module doc): one pill, the list closes on choosing and `value` is one value. |
| `size` | `:string` | `"md"` | `sm`, `md`, `lg` — The height of the field: `sm` 32px, `md` 36px, `lg` 48px, as an input of that size. |
| `panel_min_width` | `:string` | `nil` | A CSS length, the minimum width of the open list (`"24rem"`), for a narrow field; it stays aligned to the field's left edge. |
| `panel_class` | `:any` | `nil` | Classes merged into the open list. |
| `placeholder` | `:string` | `nil` | Shown in the empty field. |
| `search_placeholder` | `:string` | `"Search…"` |  |
| `overflow` | `:string` | `"one"` | `one`, `wrap` — `one` keeps one line and sums the pills that do not fit in a `+N` pill; `wrap` breaks lines. |
| `create` | `:boolean` | `false` | A typed term that is not an option can be added. |
| `create_label` | `:string` | `"Create"` | The text before the typed term. |
| `create_hint` | `:string` | `"↵"` | The key shown on the right of the create row. |
| `empty_label` | `:string` | `"No results found"` | Said when the search matches nothing; `%{query}` is replaced by the term. |
| `clear` | `:boolean` | `false` | A button that takes every pill back. |
| `clear_label` | `:string` | `"Clear"` |  |
| `remove_label` | `:string` | `"Remove"` |  |
| `hidden_label` | `:string` | `"%{count} hidden"` | The `aria-label` of the `+N` pill; `%{count}` is how many are hidden. |
| `readonly` | `:boolean` | `false` | Values are shown and submitted but cannot change. |
| `disabled` | `:boolean` | `false` |  |
| `on_search` | `:string` | `nil` |  |
| `debounce` | `:integer` | `300` |  |
| `target` | `:any` | `nil` |  |
| `on_load_more` | `:string` | `nil` | the event pushed when the list is scrolled near its end (see the Events). |
| `has_more` | `:boolean` | `false` | the server has more options after the ones in `options`. |
| `loading_label` | `:string` | `"Loading…"` | the last row of the list while `has_more` and `on_load_more` are set. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `form`, `required`.
