# Switch

Liga/desliga de efeito imediato. Padrão do kit: trilho com cantos arredondados (squircle); `pill` só como opção.

**Grupo:** 04 · Formulários — seleção  
**Resumo visual:** color (7) × on/off · size sm/md/lg · shape squircle/pill · thumb_inset 2–6 · variant basic/outline · filled · label_position · description · disabled

## Uso (Phoenix / HEEx)

```heex
<.switch field={@form[:active]} label="Ativo" />
<.switch name="auto" color="success" size="lg" thumb_inset={4} />
<.switch name="x" variant="outline" filled label_position="left" description="Notificar no WhatsApp" />
```

## Regras

- O botão desliza em 180ms; o trilho troca de cor junto.
- `thumb_inset` afasta o botão da borda: quanto maior, menor o botão.
- Use para efeito imediato; para escolha que só vale ao salvar, use checkbox.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: switch)

Todos os function components, atributos, valores e slots que este componente cobre.

kit CSS's toggle (`toggle`, `toggle-primary`, `toggle-sm`…): solid or outline (plain or filled track), pill or
squircle, three sizes, in every theme color.

    <.switch name="notify" label="Notifications" color="primary" />
    <.switch field={@form[:public]} label="Public" variant="outline" color="success" />
    <.switch name="dense" size="sm" shape="squircle" thumb_inset={4} checked />
    <.switch name="email" label="Email" label_position="left" wrapper_class="w-full justify-between" />

### `<.switch>`

Renders a switch: a checkbox drawn as a track and thumb. Like `checkbox`, it sends
`unchecked_value` through a hidden input when off.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` |  |
| `id` | `:string` |  | Defaults to the field's id. |
| `name` | `:string` |  | Defaults to the field's name. |
| `value` | `:any` |  |  |
| `checked` | `:boolean` |  | Defaults to whether `value` (or the field's value) is true. |
| `checked_value` | `:string` | `"true"` |  |
| `unchecked_value` | `:string` | `"false"` |  |
| `hidden_input` | `:boolean` | `true` |  |
| `color` | `:string` | `"neutral"` | `neutral`, `primary`, `secondary`, `info`, `success`, `warning`, `error` |
| `variant` | `:string` | `"basic"` | `basic`, `outline` |
| `filled` | `:boolean` | `false` | A tinted track, for `outline`. |
| `shape` | `:string` | `"pill"` | `pill`, `squircle` |
| `size` | `:string` | `"md"` | `sm`, `md`, `lg` — kit CSS's `toggle-sm`, default and `toggle-lg`. |
| `thumb_inset` | `:integer` | `2` | `2`, `3`, `4`, `5`, `6` — Pixels between the thumb and the track edge: the higher, the smaller the thumb. |
| `label` | `:string` | `nil` | The caption. |
| `label_position` | `:string` | `"right"` | `right`, `left` — Which side of the switch the caption sits on. `left` puts the caption before the switch; add `wrapper_class="w-full justify-between"` to push them to opposite ends. |
| `label_class` | `:any` | `nil` | Classes of the caption text. |
| `description` | `:string` | `nil` | A smaller grey line under the label. |
| `errors` | `:list` | `[]` | Messages to show; `field` adds its own once the input was used. |
| `disabled` | `:boolean` | `false` | Dims the whole row (switch, label and description) and ignores the pointer. |
| `wrapper_class` | `:any` | `nil` | Classes of the outer block (grid placement, spacing). |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `form`, `required`.

Slots:

- `<:inner_block>` — Label content, instead of `label`.
