# RangeSlider

Escolha um valor (ou um intervalo) arrastando. `canvas` (padrão): trilho de 4px e botão redondo branco.

**Grupo:** 05 · Formulários — datas e valores  
**Resumo visual:** variant canvas · classic × color (7) × size sm/md/lg · filled · show_value · value_format · marks · steppers · intervalo de dois · vertical

## Uso (Phoenix / HEEx)

```heex
<.range field={@form[:discount]} min={0} max={50} filled show_value value_format="%{value}%" />
<.range start_field={@form[:min]} end_field={@form[:max]} marks={[0, 250, 500, 1000]} />
<.range field={@form[:vol]} orientation="vertical" height="8rem" />
```

## Regras

- Arrastar: o botão ganha um anel na cor; o valor ao lado acompanha.
- Intervalo de dois: o trecho entre os botões fica pintado.
- `marks` clicáveis embaixo; `steppers` adicionam − e +.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: range)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's range slider: a rounded track with a round thumb in the theme color, in three sizes.

    <.range name="volume" value={50} color="primary" />
    <.range field={@form[:level]} label="Level" min={0} max={10} size="lg" />
    <.range name="opacity" phx-debounce="100" />

`variant="canvas"` (the default; `variant="classic"` is the old Ledger UI slider) draws the design canvas's slider (a 4px track filled in the accent, a 16px white thumb, the
value in bold mono, the marks as plain faint numbers):

    <.range name="discount" label="Desconto máximo" value={12} max={30} show_value value_format="%{value}%"
      filled variant="canvas" />

It is a native `<input type="range">`, so it submits with its form, fires `phx-change` as it is dragged
and takes the arrow keys, Home, End and Page Up and Down.

### Value, marks and steps

`show_value` writes the value beside the label, `filled` paints the track up to the thumb, `marks` puts
labels under the track (a click on one sets the value) and `steppers` adds minus and plus buttons:

    <.range
      field={@form[:markup]}
      label="Markup"
      min={0}
      max={200}
      step={5}
      show_value
      value_format="%{value}%"
      filled
      marks={[{0, "0%"}, {50, "50%"}, {100, "100%"}, {150, "150%"}, {200, "200%"}]}
    />

    <.range name="tolerance" min={0} max={3} marks={[{0, "R$ 0,00"}, {1, "R$ 0,01"}, {2, "R$ 0,10"}, {3, "R$ 1,00"}]} />

A mark is a value or a `{value, label}` pair. The browser keeps the value text, the fill and the marks
in step with the thumb without waiting for the server.

### A range of two values

Two thumbs on one track send two fields, as `date_picker` does for a period; the thumbs never cross:

    <.range start_field={@form[:price_from]} end_field={@form[:price_to]} min={0} max={500} step={10}
      label="Price" show_value value_format="R$ %{value}" />
    <.range start_name="from" end_name="to" value={{40, 280}} min={0} max={500} />

### Vertical

`orientation="vertical"` stands the slider up (the arrow keys still work, up raises the value); `height` sets its length.

    <.range name="weight" orientation="vertical" value={40} show_value value_format="%{value}%" steppers label="Price" />

### `<.range>`

Renders a range slider.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` |  |
| `id` | `:string` |  | Defaults to the field's id. |
| `name` | `:string` |  | Defaults to the field's name. |
| `value` | `:any` |  | A number, or `{from, to}` for a range of two values (then `start_name` and `end_name` or the fields name the inputs). |
| `min` | `:any` | `nil` |  |
| `max` | `:any` | `nil` |  |
| `step` | `:any` | `nil` |  |
| `color` | `:string` | `"neutral"` | `neutral`, `primary`, `secondary`, `info`, `success`, `warning`, `error` |
| `size` | `:string` | `"md"` | `sm`, `md`, `lg` |
| `fill` | `:string` | `nil` | Any CSS colour (`"#0d8f91"`, `"var(--c2)"`) for the filled part of the track, with `filled` or in a pair: a slider that takes the colour of what it sets, like the canvas `lu-slider` with `--c`. Without it the fill is the accent. |
| `variant` | `:string` | `"canvas"` | `canvas`, `classic` — `canvas` (the default) is the design canvas's `lu-slider`: a 4px sunken track filled in the accent, a 16px white thumb, the label at 13px medium, the value in bold mono and the marks as plain faint mono numbers. `color` and `size` do not apply. |
| `start_field` | `{:struct, Phoenix.HTML.FormField}` | `nil` | The field of the lower thumb of a range of two; with `end_field`. |
| `end_field` | `{:struct, Phoenix.HTML.FormField}` | `nil` | The field of the upper thumb of a range of two. |
| `start_name` | `:string` | `nil` | The input name of the lower thumb; with `end_name`. |
| `end_name` | `:string` | `nil` | The input name of the upper thumb. |
| `orientation` | `:string` | `"horizontal"` | `horizontal`, `vertical` — `vertical` is for a single value. |
| `height` | `:string` | `"8rem"` | The length of a vertical slider, any CSS length. |
| `filled` | `:boolean` | `false` | Paints the track from its start to the thumb in the color. |
| `show_value` | `:boolean` | `false` | The value written beside the label. |
| `value_format` | `:string` | `"%{value}"` | The text of the value, with `%{value}` where it goes: `"%{value}%"`, `"R$ %{value}"`. |
| `marks` | `:list` | `[]` | Labels under the track: values or `{value, label}` pairs. A click on one sets the value (the nearer thumb of a range of two). |
| `steppers` | `:boolean` | `false` | Minus and plus buttons that move by `step`. |
| `decrease_label` | `:string` | `"Decrease"` | The accessible name of the minus button. |
| `increase_label` | `:string` | `"Increase"` | The accessible name of the plus button. |
| `label` | `:string` | `nil` | The caption. |
| `label_class` | `:any` | `nil` | Classes of the caption text. |
| `help` | `:string` | `nil` | The small line under the control. |
| `errors` | `:list` | `[]` | Messages to show; `field` adds its own once the input was used. |
| `disabled` | `:boolean` | `false` |  |
| `wrapper_class` | `:any` | `nil` | Classes of the outer block (grid placement, spacing). |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `form`, `list`.
