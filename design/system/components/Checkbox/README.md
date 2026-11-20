# Checkbox

Caixa de seleção com os eixos da API: `color`, `size`, `shape`, `filled`, `indeterminate`, `label`, `description`, `disabled`.

**Grupo:** 04 · Formulários — seleção  
**Resumo visual:** color (7) × estado · size xs–lg · shape square/circle · filled · indeterminate · description · disabled

## Uso (Phoenix / HEEx)

```heex
<.checkbox field={@form[:terms]} label="Aceito os termos" />
<.checkbox field={@form[:all]} indeterminate color="primary" />
<.checkbox name="x" shape="circle" size="lg" filled description="Envia uma cópia por e-mail" />
```

## Regras

- Marcar: fundo na cor + tique branco, 120ms.
- `indeterminate` desenha o traço da seleção parcial.
- `filled` dá um fundo leve enquanto desmarcado.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: checkbox)

Todos os function components, atributos, valores e slots que este componente cobre.

kit CSS's checkbox (`checkbox`, `checkbox-primary`, `checkbox-sm`…), on a plain or a filled box, square or
circle, in every theme color.

    <.checkbox name="terms" label="I agree" />
    <.checkbox field={@form[:remember]} label="Remember me" color="primary" />
    <.checkbox name="news" color="success" variant="outline" shape="circle" filled />
    <.checkbox name="pro" label="Pro plan" description="Billed yearly" color="primary" checked />
    <.checkbox name="all" label="Select all (3 of 8)" indeterminate />

`checkbox_group` renders one checkbox per option for a list field:

    <.checkbox_group field={@form[:roles]} label="Roles" options={[{"Admin", "admin"}, {"Editor", "editor"}]} />

It takes `variant="card"` (a bordered card per option) and `variant="chip"` (a pill per
option, with an optional count), with a real checkbox underneath:

    <.checkbox_group field={@form[:channels]} variant="chip" color="primary" options={[
      %{label: "E-mail", value: "email", count: 3},
      %{label: "WhatsApp", value: "whatsapp"}
    ]} />

### `<.checkbox>`

Renders a checkbox with its label. Inside a form it sends `unchecked_value` when unchecked,
through a hidden input, so the field is always present in the params.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` |  |
| `id` | `:string` |  | Defaults to the field's id. |
| `name` | `:string` |  | Defaults to the field's name. |
| `value` | `:any` |  |  |
| `checked` | `:boolean` |  | Defaults to whether `value` (or the field's value) is true. |
| `indeterminate` | `:boolean` | `nil` | `true` draws the dash of a partial selection (`aria-checked="mixed"`, the `indeterminate` property set by the `LedgerUI.Indeterminate` hook, so it needs an `id`, taken from the name or label when missing). Pass `false` too when the box can leave that state, so the hook stays. A click clears the dash; leave `nil` to skip the hook. |
| `checked_value` | `:string` | `"true"` |  |
| `unchecked_value` | `:string` | `"false"` |  |
| `hidden_input` | `:boolean` | `true` | Renders the hidden unchecked input. |
| `color` | `:string` | `"neutral"` | `neutral`, `primary`, `secondary`, `info`, `success`, `warning`, `error` |
| `variant` | `:string` | `"basic"` | `basic`, `outline` — Kept for compatibility: both draw kit CSS's checkbox. |
| `filled` | `:boolean` | `false` | A tinted box while unchecked. |
| `shape` | `:string` | `"square"` | `square`, `circle` |
| `size` | `:string` | `"md"` | `xs`, `sm`, `md`, `lg` |
| `label` | `:string` | `nil` | The caption. |
| `label_class` | `:any` | `nil` | Classes of the caption text. |
| `description` | `:string` | `nil` | A smaller grey line under the label. |
| `errors` | `:list` | `[]` | Messages to show; `field` adds its own once the input was used. |
| `disabled` | `:boolean` | `false` |  |
| `wrapper_class` | `:any` | `nil` | Classes of the outer block (grid placement, spacing). |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `form`, `required`.

Slots:

- `<:inner_block>` — Label content, instead of `label`.

### `<.checkbox_group>`

Renders one checkbox per option, for a field that holds a list. Options are `{label, value}`
tuples, plain values, maps with `:label`, `:value` and optionally `:description`, `:count`,
`:icon`, `:color`, `:disabled`, or `:checkbox` slots (which may set the same keys).

`variant` picks the look: `basic`/`outline` checkboxes, `card` cards, `chip` pill chips.
Each toggle fires the form's `phx-change`; the field gets `name[]` with every checked value
(and an empty one, so an empty choice still reaches the server).

    <.checkbox_group name="days[]" value={["mon"]} options={[{"Monday", "mon"}, {"Tuesday", "tue"}]} />

    <.checkbox_group field={@form[:roles]} label="Roles" class="flex flex-col space-y-2">
      <:checkbox value="admin" color="primary">Admin</:checkbox>
      <:checkbox value="editor" color="success">Editor</:checkbox>
    </.checkbox_group>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` |  |
| `id` | `:string` |  | Defaults to the field's id. |
| `name` | `:string` |  | Defaults to the field's name. |
| `value` | `:any` |  |  |
| `options` | `:list` | `[]` |  |
| `color` | `:string` | `"neutral"` | `neutral`, `primary`, `secondary`, `info`, `success`, `warning`, `error` |
| `variant` | `:string` | `"basic"` | `basic`, `outline`, `card`, `chip` — `basic`/`outline` checkboxes, `card` cards, `chip` pill chips. |
| `filled` | `:boolean` | `false` |  |
| `shape` | `:string` | `"square"` | `square`, `circle` |
| `size` | `:string` | `"md"` | `xs`, `sm`, `md`, `lg` |
| `label` | `:string` | `nil` | The caption. |
| `label_class` | `:any` | `nil` | Classes of the caption text. |
| `help` | `:string` | `nil` | The small line under the control. |
| `errors` | `:list` | `[]` | Messages to show; `field` adds its own once the input was used. |
| `disabled` | `:boolean` | `false` |  |
| `wrapper_class` | `:any` | `nil` | Classes of the outer block (grid placement, spacing). |
| `class` | `:any` | `nil` | Classes of the container that lays the options out. |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:checkbox>` — attrs: `value`, `label`, `color`, `disabled`, `description`, `count`, `icon`
