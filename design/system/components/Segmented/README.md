# Segmented

Controle segmentado para alternar entre poucas opções sempre visíveis (Day · Month · Year).

**Grupo:** 04 · Formulários — seleção  
**Resumo visual:** Trilha cinza, escolhido em branco · com contagem, ícones, pequeno, bloco

## Uso (Phoenix / HEEx)

```heex
<.segmented id="range" value="month" options={~w(day month year)} />
```

## Regras

- Padrão do sistema: trilha `bg-sunken`, escolhido `bg-panel` com sombra xs e anel de 1px.
- Até 5 opções; mais que isso vira Tabs ou Select.
- Pílula só como opção de API (`shape="pill"`), nunca padrão.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: segmented)

Todos os function components, atributos, valores e slots que este componente cobre.

A segmented control: a row of toggle buttons where exactly one is chosen, for filters, periods, views and
two-way choices that do not deserve a select.

    <.segmented
      id="status"
      label="Order status"
      value={@status}
      on_change="set-status"
      options={[
        %{label: "All", value: "all", count: 128},
        %{label: "Draft", value: "draft", count: 9},
        %{label: "Approved", value: "approved", count: 31}
      ]}
    />

    <.segmented field={@form[:regime]} options={["Simples Nacional", "Regime normal"]} />

Options are strings, `{label, value}` tuples or maps with `:label`, `:value`, and optionally `:icon` (a `huge-*`
icon before the label), `:count` (a mono number in a small box after the label) and `:disabled`.

    <.segmented id="view" value="board" options={[
      %{label: "Quadro", value: "board", icon: "huge-kanban"},
      %{label: "Lista", value: "list", icon: "huge-list-view"}
    ]} />

The chosen segment is white on a gray track, both with rounded corners; `shape="pill"` gives round ends
(or `data-shape="pill"` on the `<html>`, for the whole app).

It is a `role="group"` of buttons with `aria-pressed`. The choice is made in the browser, without a round trip;
a new `value` from the server wins, and a patch that does not change it leaves the person's choice alone. Arrow
keys, Home and End move the focus between the segments (one segment is in the Tab order).

Inside a form the control submits through a hidden input named like the field, which fires an `input` event
when the choice changes, so `phx-change` runs (and not again when the server only echoes the same value):

    <.form for={@form} phx-change="validate">
      <.segmented field={@form[:view]} options={["List", "Kanban"]} />
    </.form>

### `<.segmented>`

Renders the segmented control.

Events: `on_change` pushes `%{"id" => id, "value" => value}` (to `target` when given) after the person chooses
another segment. A form's `phx-change` hears the hidden input of a control that has a `name` (or a `field`).

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` |  | Defaults to the field id, then `name`, then a generated one. |
| `name` | `:string` |  | Defaults to the field name; with it the control submits through a hidden input. |
| `value` | `:any` |  | The chosen value. Defaults to the field value. |
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` | A form field: fills `id`, `name`, `value` and `errors`. |
| `options` (required) | `:list` |  | The segments, see the module doc. |
| `label` | `:string` | `nil` | The caption above the control; also its accessible name. |
| `help` | `:string` | `nil` |  |
| `errors` | `:list` | `[]` |  |
| `size` | `:string` | `"md"` | `sm`, `md`, `lg` |
| `shape` | `:string` | `"rounded"` | `rounded`, `pill` — `rounded` (a track with 11px corners and the chosen segment at 8px, the default) or `pill` (round ends, opt-in). |
| `full` | `:boolean` | `false` | Stretches the control over the width, the segments sharing it. |
| `disabled` | `:boolean` | `false` |  |
| `on_change` | `:any` | `nil` | An event name or a `%JS{}`, run when another segment is chosen. |
| `target` | `:any` | `nil` | The `phx-target` of the `on_change` event. |
| `wrapper_class` | `:any` | `nil` | Classes of the outer block (caption, control and messages). |
| `class` | `:any` | `nil` | Merged into the group of buttons. |

Any other HTML/phx attribute goes to the root element, including `form`.
