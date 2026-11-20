# PhoneInput

Telefone com seletor de país e máscara pelo DDI.

**Grupo:** 03 · Formulários — texto  
**Resumo visual:** variant outlined/filled · size sm/md/lg · shape rounded/pill · país

## Uso (Phoenix / HEEx)

```heex
<.phone_input field={@form[:phone]} default_country="BR" />
```

## Regras

- O seletor mostra bandeira por sigla de texto (BR, US) para não depender de emoji.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: phone_input)

Todos os function components, atributos, valores e slots que este componente cobre.

A phone number field with a country picker: a button at the left with the ISO code and the calling code
(`BR +55`), and the number input. The number is written in the national format of the country as it is typed
(`(11) 91234-5678`), and what the form submits is the E.164 number (`+5511912345678`).

    <.phone_input field={@form[:phone]} label="Phone number" />
    <.phone_input name="phone" country="US" label="Phone number" />
    <.phone_input field={@form[:phone]} country="PT" country_order={~w(PT BR)} />
    <.phone_input field={@form[:phone]} countries={~w(BR PT AR UY)} clearable />
    <.phone_input field={@form[:phone]} except={~w(KP)} locale="en" />
    <.phone_input name="phone" value="+5511912345678" size="lg" variant="filled" />

`country` is the country the field starts with, an ISO 3166-1 alpha-2 code. It is `"BR"` unless said otherwise,
because Ledger UI's users are Brazilian; set it to the country of your own audience, or use `value` with an
international number, which selects its own country.

### The picker

The button opens a list with a search field, as wide as the field (at least 16rem), and a 1px divider separates
the button from the number. Each entry shows the ISO code (in mono type), the country name and its calling code (`PT Portugal +351`); a country that
shares its code with others and has its own area codes shows them after it (`+1 787, 939` for Puerto Rico).
Typing narrows the list by name (in Portuguese or English, and common names such as `usa`), by ISO code (`br`) and
by calling code (`55` or `+55`), ignoring case and accents. The arrows move, Enter chooses, Esc closes and gives the
focus back to the button. The names are in the language of `locale`.

`country_order` lists the countries to show first, in that order; the rest follow by name. `countries` limits the
picker to a set and `except` removes some from it. The look is ISO codes because flag emoji do not render
on Windows, which draws two letters in their place. `flags` brings the emoji back, in the button and in the rows,
for apps whose users are on platforms that draw them.

### Typing and pasting

The field shows the number in the national format as it is typed: the separators appear when a digit follows them,
so a number that is still being typed stays as typed (`(11) 9`), and digits past the usual length are kept. Typing
or pasting an international number (`+55 11 91234-5678`) switches the country to the one the calling code belongs
to, and the field shows the rest in that country's format. Countries that share a calling code are told apart by
the first digits: `+1 876` is Jamaica, `+1 416` is Canada, `+44 7911` is Guernsey. The trunk prefix people dial
before a national number (`0` in Brazil, `1` in the United States) is not part of the number and is dropped.

### What the form submits

A hidden input with the field's name carries the E.164 number (empty while there are no digits), and the visible
input has no name. When the number changes the hidden input fires a bubbling `input` event, so the surrounding
`phx-change` runs and gets `%{"phone" => "+5511912345678"}`; it does not fire again when the server only echoes
the same value. `phx-debounce` and `phx-throttle` go to the hidden input.

The value the server sends wins over the one in the browser, and re-rendering the same value does nothing. `value`
is an E.164 number (its country is read from the calling code) or a national number (read as the number of
`country`).

### Formatting is not validation

The format only helps the person read what they typed. A person can submit anything, so the server must validate
the value it gets. `LedgerUI.Components.PhoneInput.Format` reads a submitted number the way the field does:

    case LedgerUI.Components.PhoneInput.Format.e164(params["phone"], "BR") do
      {:ok, e164} -> e164
      {:error, reason} -> reason
    end

It normalizes to E.164 and rejects what cannot be a number, but it does not know which numbers a carrier
issues. For that, check the E.164 string with a library that has number metadata.

The behavior lives in the `LedgerUI.PhoneInput` hook, so the field needs a stable `id` (it gets one from `field` or
`name`).

### `<.phone_input>`

Renders the phone input.

Events: the hidden input dispatches a bubbling `input` event when the E.164 value changes, so the form's
`phx-change` receives `%{"phone" => "+5511912345678"}` (`""` when the field is emptied). With `on_country_change`,
choosing a country (or typing an international number of another one) also pushes that event with
`%{"id" => id, "country" => "US", "code" => "1"}` to `target` or to the LiveView/LiveComponent the field is in.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` |  | The visible input's id. Defaults to the field id, then `name`. |
| `name` | `:string` |  | Defaults to the field name. |
| `value` | `:any` |  | An E.164 number or a national number (read as `country`). Defaults to the field value. |
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` | A form field: fills `id`, `name`, `value` and `errors`. |
| `country` | `:string` | `"BR"` | The country the field starts with, an ISO 3166-1 alpha-2 code (`"BR"`, `"US"`, `"PT"`). Brazil by default, because Ledger UI's users are Brazilian. A `value` in E.164 selects its own country. A country the picker does not offer is replaced by the first of `country_order` it does, else by the first of its countries. |
| `country_order` | `:list` | `[]` | ISO codes shown first in the picker, in this order, before the rest by name. |
| `countries` | `:list` | `[]` | ISO codes the picker is limited to; empty offers every country. |
| `except` | `:list` | `[]` | ISO codes removed from the picker. |
| `locale` | `:string` | `"pt-BR"` | The language of the country names and their order: `pt-BR` (or any `pt`) for Portuguese, anything else for English. Both languages are searched. |
| `flags` | `:boolean` | `false` | Show the flag emoji of the country instead of its ISO code, in the button and in the picker. Off by default, because Windows does not draw flag emoji. |
| `label` | `:string` | `nil` | The caption. |
| `label_class` | `:any` | `nil` | Classes of the caption text. |
| `help` | `:string` | `nil` | The small line under the control. |
| `errors` | `:list` | `[]` | Messages to show; `field` adds its own. |
| `disabled` | `:boolean` | `false` |  |
| `variant` | `:string` | `"outlined"` | `outlined`, `filled` — The input's look, as in `input`. |
| `size` | `:string` | `"md"` | `sm`, `md`, `lg` |
| `shape` | `:string` | `"rounded"` | `rounded`, `pill` |
| `clearable` | `:boolean` | `false` | A button that empties the number and keeps the country. |
| `clear_label` | `:string` | `"Clear"` |  |
| `picker_label` | `:string` | `"Country"` | The accessible name of the picker button. |
| `search_placeholder` | `:string` | `"Search…"` | The placeholder of the picker's search field. |
| `no_results` | `:string` | `"No results found"` | Shown when the search matches no country; `%{query}` is replaced by what was typed. |
| `on_country_change` | `:string` | `nil` | An event pushed when the country changes in the browser, see above. |
| `target` | `:any` | `nil` | The `phx-target` of `on_country_change`. |
| `wrapper_class` | `:any` | `nil` | Classes of the block around the field. |
| `class` | `:any` | `nil` | Classes of the visible input. |

Any other HTML/phx attribute goes to the root element, including `autocomplete`, `autofocus`, `form`, `placeholder`, `readonly`, `required`.
