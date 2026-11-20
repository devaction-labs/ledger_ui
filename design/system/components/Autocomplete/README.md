# Autocomplete

Campo de busca que filtra uma lista longa enquanto o usuário digita.

**Grupo:** 04 · Formulários — seleção  
**Resumo visual:** size sm/md/lg · destaque do termo · criar novo

## Uso (Phoenix / HEEx)

```heex
<.autocomplete field={@form[:account]} search="search_accounts" />
```

## Regras

- Destaque o trecho que casou em 600.
- Mostre metadado à direita (plano, MRR) para desambiguar.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: autocomplete)

Todos os function components, atributos, valores e slots que este componente cobre.

A text input with a list of suggestions under it, in Ledger UI's Tom Select look: the person
types, the list narrows (or the server searches), and choosing a suggestion sets the field.

    <.autocomplete field={@form[:customer_id]} label="Customer" options={@customers}
                   on_search="search_customers" placeholder="Pick a customer" clearable />

    <.autocomplete field={@form[:product_id]} options={@products} on_search="search_products"
                   no_results="Nothing for \"%{query}\"" open_on_focus target={@myself}>
      <:option :let={product}>{product.label} <small>{product.data.sku}</small></:option>
    </.autocomplete>

    <.autocomplete field={@form[:city]} options={["Salvador", "Santos", "São Paulo"]} free_text />

Options are strings, `{label, value}` tuples or maps with `:label` and `:value` (other keys
reach the `:option` slot as `option.data`), as in `LedgerUI.Components.Select.Options`. A
`:hint` key (`%{label: "Ana Souza", value: "1", hint: "ana@exemplo.com"}`) draws a small dimmed
note on the right of the row without needing the `:option` slot, and a disabled option is dimmed.

The choice is submitted through a hidden input named like the field; the visible input only
shows the chosen option's label. A bubbling `input` event fires from the hidden input when
the value changes, so a surrounding `phx-change` runs. Leaving the input with text that is
not an option puts the chosen label back; leaving it empty clears the value.

With `free_text` the typed text itself is the value (the suggestions only complete it):
every keystroke updates the hidden input, and choosing a suggestion writes its value.

Without `on_search` the list filters itself on the client (ignoring case and accents). With
it, the hook pushes the query to the server, shows `loading_text` until the reply, and the
server answers by re-rendering `options`.

The text typed shows in bold primary colour inside each suggestion (no background). While the
server searches the list is `aria-busy`, the previous suggestions leave and `loading_text` shows with a 16px spinner as a
`role="status"`; "no results" is a status too. The clear button is a real button
(`clear_label` names it) that can be reached with `Tab` and pressed with `Enter` or `Space`.

The behavior lives in the `LedgerUI.Autocomplete` hook, so the field needs a stable `id` (it
gets one from `field` or `name`).

### `<.autocomplete>`

Renders the autocomplete.

Events: with `on_search`, typing pushes `on_search` with `%{"id" => id, "query" => text}`
(after `debounce` ms, once the query has `search_threshold` characters) to `target` or to the
LiveView/LiveComponent the field is in. Choosing, clearing or (with `free_text`) typing fires
the form's `phx-change` with the field's value.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` |  | Defaults to the field id, then `name`, then a generated one. |
| `name` | `:string` |  | Defaults to the field name. |
| `value` | `:any` |  | The chosen value. Defaults to the field value. |
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` | A form field: fills `id`, `name`, `value` and `errors`. |
| `label` | `:string` | `nil` |  |
| `help` | `:string` | `nil` |  |
| `errors` | `:list` | `[]` |  |
| `options` | `:list` | `[]` | The suggestions, see the module doc. |
| `placeholder` | `:string` | `nil` |  |
| `disabled` | `:boolean` | `false` |  |
| `display_value` | `:string` | `nil` | The text shown for `value` when it is not among `options` (a chosen customer the current search no longer returns). |
| `free_text` | `:boolean` | `false` | The typed text is the value; the suggestions only complete it. |
| `on_search` | `:string` | `nil` | The event pushed with the query: the server searches. |
| `debounce` | `:integer` | `300` | Milliseconds between the last keystroke and the push. |
| `search_threshold` | `:integer` | `0` | How many characters before searching. |
| `target` | `:any` | `nil` |  |
| `open_on_focus` | `:boolean` | `false` | Show the suggestions as soon as the input has focus. |
| `clearable` | `:boolean` | `false` | A button that empties the field. |
| `clear_label` | `:string` | `"Clear"` | The name of the clear button, for screen readers and its tooltip. |
| `no_results` | `:string` | `"No results found"` | Shown when nothing matches; `%{query}` is replaced by what was typed. |
| `loading_text` | `:string` | `"Searching…"` | Shown while the server searches. |
| `create` | `:string` | `nil` | A last row, under a line, offering to create what was typed (`"Cadastrar “%{query}”"`); `%{query}` is replaced by the text. Shows while there is a query, with or without results. |
| `on_create` | `:any` | `nil` | The event pushed (with `%{"id" => id, "query" => text}`) when the `create` row is chosen, or a `JS` command to run. |
| `size` | `:string` | `"md"` | `sm`, `md`, `lg` |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `autofocus`, `form`, `required`.

Slots:

- `<:option>` — How a suggestion shows in the list; gets the option map (`label`, `value`, `data`).
- `<:prefix>` — A plain icon inside the control, before the text (the canvas search glass).
