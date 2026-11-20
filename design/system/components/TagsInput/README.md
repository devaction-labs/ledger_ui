# TagsInput

Campo livre onde cada termo confirmado com Enter ou vírgula vira uma tag.

**Grupo:** 04 · Formulários — seleção  
**Resumo visual:** create_position top/bottom · Enter cria · Backspace remove

## Uso (Phoenix / HEEx)

```heex
<.tags_input field={@form[:tags]} />
```

## Regras

- Valide duplicados e mostre erro inline.
- Cole lista separada por vírgula para criar várias.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: tags_input)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's tag input (the Tom Select page's Input Tags demos): what is typed becomes a chip
on Enter, Tab or the delimiter, chips are removed with Backspace or their remove button.

    <.tags_input label="Enter Tags:" placeholder="Enter tags" field={@form[:tags]} />
    <.tags_input name="tags" value={["awesome", "neat"]} removable restore_on_backspace />
    <.tags_input name="tags" value="clear,items" clearable persist={false} max={5} />

`value` is a list of strings or a comma separated string. The tags are submitted as
`name[]` (plus an empty `name[]` so an empty list still reaches the server) through a
hidden `<select multiple>`, and each change fires a bubbling `input` event for `phx-change`.
`suggestions` are offered in the list while typing. The `:option` and `:item` slots draw an
option in the list and a tag in the field, as in `LedgerUI.Components.Select`.

With `max`, the input is disabled at the limit, its placeholder becomes `limit_placeholder`
and a `3 / 3` counter appears under the field (on the right of the `help` line when there is one);
`counter={false}` leaves it out.
A suggestion given as a map can carry a `hint` (`%{label: "Priority", value: "Priority", hint: "12 uses"}`),
a dimmed note on the right of its row. A disabled field draws its tags without remove buttons. The row that creates a tag reads
`Enter Add “pri”`: `create_label` and `create_hint` are its words.

### Picking from a server-searched list

With `create={false}` only listed options can be chosen, and with `on_search` the server
does the search: the typed text is pushed (debounced) and the LiveView answers by
re-rendering `options`. Chips show the labels; the form gets the values as `name[]`.
`selected_options` gives the labels of the chosen values that are not in the current
`options` (after a search narrowed them).

    <.tags_input
      field={@form[:tag_ids]}
      options={@tag_results}
      selected_options={@chosen_tags}
      create={false}
      on_search="search_tags"
      target={@myself}
      removable
      placeholder="Search tags"
    />

    def handle_event("search_tags", %{"query" => query}, socket),
      do: {:noreply, assign(socket, :tag_results, Tags.search(query))}

### `<.tags_input>`

Renders a tag input.

Events: with `on_search`, `%{"id" => id, "query" => text}` is pushed to `target` (or the
LiveView) as the person types, `debounce` ms after the last key; the list then shows the
`options` the server renders, unfiltered.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` |  | Defaults to the field id, or a generated one. |
| `name` | `:string` |  | Defaults to the field name (with `[]` when several values). |
| `value` | `:any` |  | Defaults to the field value. |
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` |  |
| `label` | `:string` | `nil` |  |
| `help` | `:string` | `nil` |  |
| `errors` | `:list` | `[]` |  |
| `placeholder` | `:string` | `nil` |  |
| `suggestions` | `:list` | `[]` | Options offered while typing, in any select option shape. |
| `options` | `:list` | `nil` | The options to pick from (any select option shape); `suggestions` by another name. |
| `selected_options` | `:list` | `[]` | Options whose labels the chips of chosen values use when they are not in `options`. |
| `create` | `:boolean` | `true` | Typed text becomes a tag; `false` allows only listed options (option-picking mode). |
| `on_search` | `:string` | `nil` | Event pushed with the typed text; the server then renders `options`. |
| `debounce` | `:integer` | `300` | Milliseconds between the last key and `on_search`. |
| `removable` | `:boolean` | `false` | A remove button on each tag. |
| `clearable` | `:boolean` | `false` | A button that removes every tag. |
| `clear_label` | `:string` | `"Clear"` |  |
| `remove_label` | `:string` | `"Remove"` |  |
| `create_label` | `:string` | `"Add"` |  |
| `persist` | `:boolean` | `true` | A removed tag stays in the list of suggestions. |
| `restore_on_backspace` | `:boolean` | `false` |  |
| `create_hint` | `:string` | `"Enter"` | The key shown in the create row (`Enter Add “pri”`); `nil` hides it. |
| `max` | `:integer` | `nil` | How many tags can be added. At the limit the input is disabled, shows `limit_placeholder` and a `3 / 3` counter appears under the field. |
| `counter` | `:boolean` | `true` | The `3 / 3` counter under the field at `max`; `false` hides it (say the limit in `help` instead). |
| `limit_placeholder` | `:string` | `"Limit reached"` | The placeholder of the disabled input at `max`. |
| `create_position` | `:string` | `"top"` | `top`, `bottom` — Where the row that creates the typed tag sits: above the suggestions or under them. |
| `compact` | `:boolean` | `false` | The design canvas look: suggestion rows without the check column, the create row in plain text, the clear button always visible while there are tags and a focus ring. |
| `no_results` | `:string` | `"No results found"` |  |
| `disabled` | `:boolean` | `false` |  |
| `target` | `:any` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `form`.

Slots:

- `<:item>` — How a chosen tag shows in the control; gets the option map.
- `<:option>` — How an option shows in the list; gets the option map (`label`, `value`, `data`).
