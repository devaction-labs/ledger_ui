# Rating

Nota em estrelas: só leitura (aceita meio ponto) ou interativa, com radios por baixo.

**Grupo:** 05 · Formulários — datas e valores  
**Resumo visual:** variant solid · outline × size sm/md/lg × valor (inteiro e fracionário) · show_value · count · interativo · resumo por nota

## Uso (Phoenix / HEEx)

```heex
<.rating value={4.5} show_value count={38} />
<.rating field={@form[:grade]} variant="outline" size="lg" />
<.rating_breakdown counts={[276, 69, 23, 8, 7]} />
```

## Regras

- Interativo: as estrelas acendem até onde o ponteiro está; clicar fixa.
- `solid` âmbar sobre cinza; `outline` linhas âmbar com as vazias apagadas.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: rating)

Todos os function components, atributos, valores e slots que este componente cobre.

A star rating: read-only, with a fractional value and the count of reviews, or interactive, as a group of
native radios; and `rating_distribution`, the summary with the average and a bar per grade.

    <.rating value={4.5} />
    <.rating value={4.2} show_value count={38} />
    <.rating value={3} size="lg" />

    <.rating id="service" name="service" label="Como foi o atendimento?" value={@grade}
      on_change="rate" />
    <.rating field={@form[:grade]} label="Nota" />
    <.rating value={3} disabled show_value />

    <.rating_distribution average={4.5} counts={[800, 310, 110, 40, 24]} />

`variant="outline"` draws the canvas stars: amber line stars, the empty ones faded, the grade in bold mono.

    <.rating value={4.2} variant="outline" size="sm" show_value count={86} />

A value is drawn star by star: each one is filled by the proportion left, so `4.5` has four full
stars and half of the fifth. The read-only rating is one `role="img"` with the text
`4,5 de 5 estrelas`; pass `aria_label` for another language.

It is read-only unless it gets a `field`, a `name` or an `on_change` (or `interactive`). Then it is a
`radiogroup` of native radios, `max` of them: Tab enters the group, the arrow keys choose, and the
hover previews the grade. The choice is made in the browser; a new `value` from the server wins.
Inside a form the radios submit with the field's `name` and the form's `phx-change` runs as with
plain radios:

    <.form for={@form} phx-change="validate">
      <.rating field={@form[:grade]} label="Como foi o atendimento?" />
    </.form>

### `<.rating>`

Renders a rating.

Events: `on_change` is run when a grade is chosen. An event name is pushed with
`%{"id" => id, "value" => "4"}` (to `target` when given); a `%JS{}` is executed.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` |  | Defaults to the field id, then `name`, then a generated one. |
| `name` | `:string` |  | Defaults to the field name; the interactive radios submit with it. |
| `value` | `:any` |  | The grade, `0` to `max`; fractional when read-only. Defaults to the field value. |
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` | A form field: fills `id`, `name`, `value` and `errors`. |
| `max` | `:integer` | `5` | How many stars. |
| `variant` | `:string` | `"solid"` | `solid`, `outline` — `solid` stars filled in yellow on grey, or `outline`, the canvas look: amber line stars, the empty ones faded. |
| `size` | `:string` | `"md"` | `sm`, `md`, `lg` |
| `count` | `:integer` | `nil` | How many reviews, shown as `(38)` after the stars. |
| `show_value` | `:boolean` | `false` | The grade as a number, `4,2`, before the count. |
| `decimal` | `:string` | `","` | The decimal separator of the number shown. |
| `interactive` | `:boolean` | `nil` | Radios instead of an image. Defaults to true with a `field`, a `name` or an `on_change`. |
| `label` | `:string` | `nil` | The caption above the interactive group; also its accessible name. |
| `aria_label` | `:string` | `nil` | The text a read-only rating gives a screen reader. Defaults to `4,5 de 5 estrelas`. |
| `help` | `:string` | `nil` |  |
| `errors` | `:list` | `[]` |  |
| `disabled` | `:boolean` | `false` | Keeps the grade visible and ignores the pointer. |
| `on_change` | `:any` | `nil` | An event name or a `%JS{}`, run when a grade is chosen. |
| `target` | `:any` | `nil` | The `phx-target` of the `on_change` event. |
| `class` | `:any` | `nil` | Merged into the row of stars. |

Any other HTML/phx attribute goes to the root element.

### `<.rating_distribution>`

Renders the summary of a rating: the average, its stars, the total and a bar per grade.

    <.rating_distribution average={4.5} counts={[800, 310, 110, 40, 24]} />
    <.rating_distribution counts={%{5 => 62, 4 => 24, 3 => 9, 2 => 3, 1 => 2}} unit="votos" />

`counts` is how many reviews each grade got: a list from the best grade to the worst, or a map
keyed by the grade. The bars are the share of the total; `average` and `total` are worked out from
the counts unless given.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `counts` (required) | `:any` |  | A list, best grade first, or a map `%{grade => count}`. |
| `average` | `:any` | `nil` | Defaults to the weighted average of `counts`. |
| `total` | `:integer` | `nil` | Defaults to the sum of `counts`. |
| `unit` | `:string` | `"avaliações"` | The word after the total. |
| `decimal` | `:string` | `","` | The decimal separator of the average. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.
