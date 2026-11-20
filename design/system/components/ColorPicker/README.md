# ColorPicker

Escolha de cor entre amostras do sistema ou valor hex.

**Grupo:** 05 · Formulários — datas e valores  
**Resumo visual:** variant full/swatches · swatch_size sm/md/lg · hex

## Uso (Phoenix / HEEx)

```heex
<.color_picker field={@form[:color]} swatches={@palette} />
```

## Regras

- Ofereça primeiro as cores do sistema; hex livre é avançado.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: color_picker)

Todos os function components, atributos, valores e slots que este componente cobre.

A color picker that outputs hex text: a saturation and brightness area to drag, a hue slider, an
optional opacity slider, a hex field and a row of preset swatches.

    <.color_picker field={@form[:color]} label="Stage color" />
    <.color_picker name="tag" value="#4C3FE0" presets={~w(#EB3B2F #F5A214 #18996E)} />
    <.color_picker field={@form[:overlay]} alpha locale="pt_BR" />

The form gets `#6366F1` (upper case, `#RRGGBB`; with `alpha`, a color that is not fully opaque is
`#RRGGBBAA`) through a hidden input named like the field. Every change fires a bubbling `input`
event from it, so `phx-change` runs; the server re-rendering the same color changes nothing, a
different color replaces the one in the browser. `phx-debounce` and `phx-throttle` go to the hidden input.

The area is a slider: drag it, or use the arrow keys (Shift moves ten points). The hex field takes
`#RGB`, `#RRGGBB` or `#RRGGBBAA` and applies it as soon as it is a color. `locale="pt_BR"` names the
controls in Portuguese; `labels` overrides single texts.

`variant="swatches"` is the canvas's brand palette: only the row of `presets`, the chosen one
ringed in ink; `hex_field` adds the hex field under it (captioned `hex_label`):

    <.color_picker name="brand" value="#8A5CD6" variant="swatches"
                   presets={~w(#0D8F91 #2F5FD0 #8A5CD6)} />
    <.color_picker name="stage" value="#0D8F91" variant="swatches" hex_field swatch_size="md"
                   presets={~w(#0D8F91 #2F5FD0 #8A5CD6)} />

The behavior lives in the `LedgerUI.ColorPicker` hook, so the picker needs a stable `id`.

### `<.color_picker>`

Renders the color picker.

Events: `on_change` is pushed with `%{"id" => id, "value" => "#6366F1"}` each time the color changes,
to `target` or to the LiveView/LiveComponent the picker is in.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` |  | Defaults to the field id, or a generated one. |
| `name` | `:string` |  | Defaults to the field name. |
| `value` | `:string` |  | The color as hex text. Defaults to the field value, then `default`. |
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` |  |
| `default` | `:string` | `"#4C3FE0"` | The color shown while there is no valid value. |
| `label` | `:string` | `nil` |  |
| `label_class` | `:any` | `nil` |  |
| `help` | `:string` | `nil` |  |
| `errors` | `:list` | `[]` |  |
| `alpha` | `:boolean` | `false` | Adds the opacity slider; the output has eight digits when the color is not opaque. |
| `presets` | `:list` | `["#4C3FE0", "#2763E6", "#1693CC", "#18996E", "#31A35B", "#F5A214", "#F06B0C", "#EB3B2F", "#DB428F", "#606A78"]` | Swatches under the area, as hex text. `[]` hides them. |
| `locale` | `:string` | `"en"` | `en`, `pt_BR` — The language of the control names. |
| `labels` | `:map` | `%{}` | Single texts: `:color_area`, `:color_area_text` (with `%{s}` and `%{v}`), `:color_hue`, `:color_alpha`, `:color_hex` and `:color_presets`. |
| `variant` | `:string` | `"full"` | `full`, `swatches` — `swatches` shows only the presets (and the hex field with `hex_field`). |
| `hex_field` | `:boolean` | `false` | With `variant="swatches"`: the hex field under the swatches. |
| `hex_label` | `:string` | `"Hex"` | The caption of the hex field of `swatches`. |
| `swatch_size` | `:string` | `nil` | ``, `sm`, `md`, `lg` — The swatches: `sm` 26px (the full picker's default), `md` 30px, `lg` 34px (the default of `swatches`). |
| `disabled` | `:boolean` | `false` |  |
| `on_change` | `:string` | `nil` |  |
| `target` | `:any` | `nil` |  |
| `wrapper_class` | `:any` | `nil` | Classes of the block around the picker. |
| `class` | `:any` | `nil` | Classes of the picker. |

Any other HTML/phx attribute goes to the root element.
