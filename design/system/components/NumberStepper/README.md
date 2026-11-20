# NumberStepper

Número com separadores do idioma (`1.234,56`) e botões − e + que somam o `step`.

**Grupo:** 05 · Formulários — datas e valores  
**Resumo visual:** stepper_style inset · round · joined × size sm/md/lg · prefix/suffix · locale pt-BR · decimals · min/max · filled · disabled

## Uso (Phoenix / HEEx)

```heex
<.number_input field={@form[:qty]} steppers min={1} max={99} />
<.number_input field={@form[:price]} decimals={2} prefix="R$" />
<.number_input field={@form[:discount]} suffix="%" max_decimals={1} stepper_style="round" />
```

## Regras

- `inset` (padrão): botões dentro do campo; `round`: dois botões redondos em volta do número; `joined`: botões colados com divisória.
- `decimals={2}` sempre mostra dois decimais (dinheiro); `pt-BR` escreve `1.234,56`.
- No limite (`min`/`max`) o botão fica desabilitado.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: number_input)

Todos os function components, atributos, valores e slots que este componente cobre.

A numeric field for money and quantities that shows the number the way the person's locale
writes it (`1.234,56` in pt-BR, `1,234.56` in en) and submits the plain machine value
(`1234.56`).

    <.number_input field={@form[:price]} label="Price" prefix="R$" decimals={2} min={0} />
    <.number_input field={@form[:quantity]} label="Quantity" steppers min={1} step={1} suffix="un" />
    <.number_input name="discount" value={Decimal.new("12.5")} suffix="%" max_decimals={2} max={100} />
    <.number_input field={@form[:amount]} locale="en" align="right" />

The visible input has no `name`: a hidden input named like the field carries the machine
value, and a bubbling `input` event fires from it whenever that value changes, so a
surrounding `phx-change` runs. `phx-debounce`/`phx-throttle` go to the hidden input.

`value` may be an integer, a float, a numeric string or a `Decimal`. The server formats it
for the first paint; a value the server sends later wins over the one in the browser, and
re-rendering the same value does nothing.

Typing keeps what the person writes (digits, the decimal separator, the grouping separator
and a leading `-` when negatives are allowed); leaving the field clamps it to `min`/`max`,
rounds it to `decimals`/`max_decimals` and writes it grouped. Arrow up and down (and the
steppers) move by `step`, Page up and down by ten steps.

With `steppers` the field is 40px high at `md` (`sm` 32px, `lg` 48px) and its value is set in
mono. The `suffix` then sits at the right edge, or, with `align="center"`, right after the
value (the hook keeps its distance in `--nlen`, the number of characters shown). A stepper
is `disabled` at `min` and `max`.

`stepper_style` picks how the steppers look: `inset` (the default, the canvas stepper) is one
field with plain `−` and `+` icon buttons inside its ends; `round` is the canvas's compact one
for cart rows, two round outlined buttons with the bare number between them; `joined` is
Ledger UI's, the buttons as boxes joined to the input.

    <.number_input name="qty" value={3} steppers stepper_style="round" min={0} />

The behavior lives in the `LedgerUI.NumberInput` hook, so the field needs a stable `id` (it
gets one from `field` or `name`).

### `<.number_input>`

Renders the number input.

Events: none of its own. The hidden input dispatches a bubbling `input` event when the
machine value changes, so the form's `phx-change` receives `%{"name" => "1234.56"}`
(`""` when the field is emptied; the typed text when it is not a number, so the server can
reject it).

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` |  | The visible input's id. Defaults to the field id, then `name`. |
| `name` | `:string` |  | Defaults to the field name. |
| `value` | `:any` |  | A number, a numeric string or a `Decimal`. Defaults to the field value. |
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` | A form field: fills `id`, `name`, `value` and `errors`. |
| `label` | `:string` | `nil` | The caption. |
| `label_class` | `:any` | `nil` | Classes of the caption text. |
| `help` | `:string` | `nil` | The small line under the control. |
| `errors` | `:list` | `[]` |  |
| `disabled` | `:boolean` | `false` |  |
| `locale` | `:string` | `"pt-BR"` | Picks the separators: `pt-BR` writes `1.234,56`, `en` writes `1,234.56`. |
| `decimal_separator` | `:string` | `nil` | Overrides the locale's decimal separator. |
| `thousands_separator` | `:string` | `nil` | Overrides the locale's grouping separator; `""` turns grouping off. |
| `decimals` | `:integer` | `nil` | Always this many decimals (`2` for money: `10` shows `10,00`). |
| `max_decimals` | `:integer` | `nil` | At most this many decimals; fewer are shown as typed. Ignored when `decimals` is set. |
| `min` | `:any` | `nil` | The lowest value; a negative sign can be typed only when it is below zero or absent. |
| `max` | `:any` | `nil` | The highest value. |
| `step` | `:any` | `1` | What the arrow keys and the steppers add or take away. |
| `steppers` | `:boolean` | `false` | `−` and `+` buttons on either side. |
| `stepper_style` | `:string` | `"inset"` | `inset`, `round`, `joined` — With `steppers`: `inset` plain icon buttons inside one field (canvas), `round` two round buttons around the bare number (canvas, compact), `joined` boxes joined to the input (Ledger UI). |
| `decrement_label` | `:string` | `"Decrease"` | The accessible name of `−`. |
| `increment_label` | `:string` | `"Increase"` | The accessible name of `+`. |
| `prefix` | `:string` | `nil` | A box before the input, like `R$`. |
| `suffix` | `:string` | `nil` | A box after the input, like `%` or `un`. |
| `variant` | `:string` | `"outlined"` | `outlined`, `filled` — The input's look, as in `input`. |
| `size` | `:string` | `"md"` | `sm`, `md`, `lg` |
| `shape` | `:string` | `"rounded"` | `rounded`, `pill` |
| `align` | `:string` | `"left"` | `left`, `right`, `center` |
| `wrapper_class` | `:any` | `nil` | Classes of the block around the field. |
| `class` | `:any` | `nil` | Classes of the visible input. |

Any other HTML/phx attribute goes to the root element, including `autocomplete`, `autofocus`, `form`, `placeholder`, `readonly`, `required`.
