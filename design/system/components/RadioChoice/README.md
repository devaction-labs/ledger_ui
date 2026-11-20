# RadioChoice

Escolha única entre opções visíveis, em seis formas: radio simples, contorno, cartões, chips, segmentado e ladrilhos.

**Grupo:** 04 · Formulários — seleção  
**Resumo visual:** variant basic · outline · card (control start/end) · chip · segmented · tile × color × size xs–lg × shape circle/squircle

## Uso (Phoenix / HEEx)

```heex
<.radio field={@form[:plan]} options={[{"Mensal", "m"}, {"Anual", "a"}]} />
<.radio field={@form[:plan]} variant="card" control="end" options={@plans} />
<.radio field={@form[:size]} variant="tile" options={~w(P M G GG)} />
```

## Regras

- `card` para escolhas com preço ou descrição; `segmented` para 2 a 4 opções curtas.
- `tile`: quadrados de 52px para tamanhos, números ou letras.
- Selecionado: borda e anel de 1px na cor, fundo suave.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: radio)

Todos os function components, atributos, valores e slots que este componente cobre.

kit CSS's radios (`radio`, `radio-primary`, `radio-sm`…), in a group that shares one `name`: plain or filled
box, circle or squircle, in every theme color.

    <.radio_group field={@form[:plan]} options={[{"Free", "free"}, {"Pro", "pro"}]} color="primary" />

    <.radio_group name="basic" value="primary" class="grid grid-cols-2 gap-6 sm:grid-cols-3">
      <:radio value="default">Default</:radio>
      <:radio value="primary" color="primary">Primary</:radio>
      <:radio value="error" color="error" disabled>Error</:radio>
    </.radio_group>

The sizes are kit CSS's (`radio-xs`, `radio-sm`, `radio-lg`; `md` is its default).

`variant="segmented"` renders the look of `segmented`: a row of toggle buttons on one track, where exactly one
is chosen. The buttons are real radios (visually hidden), so the form submits the choice, `field` and its errors
work, the arrow keys move the choice and the chosen segment is the one the radio checks, with a focus ring around
the segment that has the focus. `count` shows a small number after the label and `disabled` dims a segment;
`color` and `filled` do not apply. `size` follows `segmented` (`xs` and `sm` are its `sm`). Unlike `segmented`,
the choice is a form value, so the server learns of it with the form's `phx-change`.

    <.radio_group field={@form[:period]} variant="segmented" options={[
      %{label: "Day", value: "day"},
      %{label: "Week", value: "week", count: 3},
      %{label: "Month", value: "month", disabled: true}
    ]} />

`variant="tile"` draws each option as a 52px square with a 1px border that turns to a 2px ink border when chosen,
dimmed to 35% when `disabled`; the content of the option is free (an SVG, an emoji) and, having no text, each
option takes an `aria_label`.

    <.radio_group field={@form[:mark]} variant="tile" label="Mark" label_hint="optional">
      <:radio value="a" aria_label="Segment A"><svg viewBox="0 0 24 24">…</svg></:radio>
      <:radio value="b" aria_label="Segment B" disabled><svg viewBox="0 0 24 24">…</svg></:radio>
    </.radio_group>

`variant="card"` lays each option out as the canvas card (`lu-choice`): white, 14px of padding, a 1px line
that turns to a 1.5px ink line when chosen (or the `color`, when not `neutral`), the title, the description,
an optional icon in a 36px square that takes the accent tint when chosen, and `count` as a big figure between
the title and the description (a price). `control="end"` puts the radio at the right; `variant="chip"` renders pill chips, the
status filter of a list, with an optional count. Both keep a real radio underneath, so the
arrow keys, the form and `phx-change` work as with plain radios.

    <.radio_group field={@form[:status]} variant="chip" color="primary" options={[
      %{label: "Todos", value: "all", count: 128},
      %{label: "Rascunho", value: "draft", count: 4},
      %{label: "Confirmado", value: "confirmed", count: 12}
    ]} />

    <.radio_group field={@form[:remember]} variant="card" color="primary">
      <:radio value="yes" description="Stay signed in for 30 days" icon="huge-laptop">This device</:radio>
      <:radio value="no" description="Sign out when the browser closes">Just this time</:radio>
    </.radio_group>

### `<.radio_group>`

Renders a set of radios. Options are `{label, value}` tuples, plain values, maps with
`:label`, `:value` and optionally `:description`, `:count`, `:icon`, `:color`, `:disabled`,
or `:radio` slots, which may override `color`, `disabled`, `description`, `count` and `icon`
one by one.

`variant` picks the look: `basic` and `outline` are Ledger UI's radios, `card` a bordered card
per option, `chip` a pill per option, `segmented` a segmented control of radios. Choosing one fires the form's `phx-change` like any
radio; on its own (outside a form) put `phx-click` or `phx-change` in `rest`.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` |  |
| `id` | `:string` |  | Defaults to the field's id. |
| `name` | `:string` |  | Defaults to the field's name. |
| `value` | `:any` |  | The value of the checked radio. |
| `options` | `:list` | `[]` |  |
| `color` | `:string` | `"neutral"` | `neutral`, `primary`, `secondary`, `info`, `success`, `warning`, `error` |
| `variant` | `:string` | `"basic"` | `basic`, `outline`, `card`, `chip`, `segmented`, `tile` — `basic`/`outline` radios, `card` cards, `chip` pill chips, `segmented` a segmented control, `tile` a 52px square holding the option's own content. |
| `control` | `:string` | `"start"` | `start`, `end` — `variant="card"`: the side of the card the radio sits on, `start` (before the text) or `end` (at the right). |
| `filled` | `:boolean` | `false` |  |
| `shape` | `:string` | `"circle"` | `circle`, `squircle` |
| `size` | `:string` | `"md"` | `xs`, `sm`, `md`, `lg` |
| `label` | `:string` | `nil` | The caption. |
| `label_class` | `:any` | `nil` | Classes of the caption text. |
| `label_hint` | `:string` | `nil` | A dimmed note at the right of the caption, as the canvas's "opcional". |
| `help` | `:string` | `nil` | The small line under the control. |
| `errors` | `:list` | `[]` | Messages to show; `field` adds its own once the input was used. |
| `disabled` | `:boolean` | `false` |  |
| `wrapper_class` | `:any` | `nil` | Classes of the outer block (grid placement, spacing). |
| `radio_class` | `:any` | `nil` | Extra classes of every radio input. |
| `class` | `:any` | `nil` | Classes of the container that lays the radios out. |

Any other HTML/phx attribute goes to the root element, including `form`, `required`.

Slots:

- `<:radio>` — attrs: `value`, `label`, `color`, `disabled`, `aria_label`, `description`, `count`, `icon`, `class`
