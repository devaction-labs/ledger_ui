# PillSelect

Escolha (única ou múltipla) entre poucas opções exibidas como chips.

**Grupo:** 04 · Formulários — seleção  
**Resumo visual:** Opções lado a lado como chips selecionáveis

## Uso (Phoenix / HEEx)

```heex
<.pill_select field={@form[:range]} options={~w(7d 30d 90d 12m)} />
```

## Regras

- Formato de cantos arredondados, não pílula; o escolhido fica `inverse`.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: pill_select)

Todos os function components, atributos, valores e slots que este componente cobre.

A quick filter of pills: a row of 26px tags where the chosen ones take the accent tint. One choice by default,
several with `multiple`.

    <.pill_select field={@form[:canal]} options={["Todos", "Balcão", "Online"]} />

    <.pill_select
      field={@form[:categorias]}
      multiple
      options={["Tintas", "Básico", "Ferramentas", "Acessórios"]}
    />

    <.pill_select
      name="canal"
      value="todos"
      options={[%{label: "Todos", value: "todos", count: 128}, %{label: "Balcão", value: "balcao", count: 64}]}
    />

Options are strings, `{label, value}` tuples or maps with `:label`, `:value`, and optionally `:count` (a faint
number after the label) and `:disabled`.

Each pill is a native radio (or checkbox with `multiple`) inside its label, so the choice is made in the browser,
the keyboard works as in any radio group or set of checkboxes, and a surrounding form's `phx-change` gets the
value under `name` (a list under `name[]` with `multiple`; a hidden empty entry keeps an empty choice
submittable, and it is dropped from `value`).

### `<.pill_select>`

Renders the pills.

Events: inside a form, choosing fires the inputs' `change`, so `phx-change` runs. Without a form, `on_change`
is pushed on each click with `%{"id" => id, "value" => value}` (the clicked option's value) to `target` when
given.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` |  | Defaults to the field id, then `name`, then a generated one. |
| `name` | `:string` |  | Defaults to the field name. `multiple` appends `[]`. |
| `value` | `:any` |  | The chosen value, or a list of them with `multiple`. Defaults to the field value. |
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` | A form field: fills `id`, `name`, `value` and `errors`. |
| `options` (required) | `:list` |  | The pills, see the module doc. |
| `multiple` | `:boolean` | `false` | Several pills can be chosen (checkboxes). |
| `label` | `:string` | `nil` | The caption above the pills; also the group's name. |
| `help` | `:string` | `nil` |  |
| `errors` | `:list` | `[]` |  |
| `disabled` | `:boolean` | `false` |  |
| `on_change` | `:string` | `nil` | An event pushed when a pill is clicked, for use outside a form. |
| `target` | `:any` | `nil` | The `phx-target` of `on_change`. |
| `wrapper_class` | `:any` | `nil` | Classes of the outer block. |
| `class` | `:any` | `nil` | Merged into the row of pills. |

Any other HTML/phx attribute goes to the root element, including `form`.
