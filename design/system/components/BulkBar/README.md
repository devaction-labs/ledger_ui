# BulkBar

Substitui a toolbar pela barra de ações em massa enquanto há linhas selecionadas.

**Grupo:** 08 · Tabelas  
**Resumo visual:** Barra inline no topo da tabela durante a seleção

## Uso (Phoenix / HEEx)

```heex
<.bulk_bar count={3} total={1096} />
```

## Regras

- Ofereça “selecionar todas as 1.096” quando a página inteira estiver marcada.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: bulk_bar)

Todos os function components, atributos, valores e slots que este componente cobre.

A floating bar of bulk actions for a table with selection: the count of what is selected in a badge, a
field to change one attribute (a status, an owner, a label), buttons for the actions and a close that
clears the selection. It appears only while `count` is above zero.

    <.bulk_bar
      id="orders-bulk"
      count={@count}
      label="order selected"
      label_plural="orders selected"
      total={@total}
      on_select_all="select_all"
      on_clear="clear_selection"
    >
      <:field>
        <.select name="status" options={@statuses} value={@status} search="none" placeholder="Change status" />
      </:field>
      <:action variant="primary" disabled={is_nil(@status)} phx-click="apply">Apply to {@count}</:action>
      <:action variant="danger" icon="huge-delete-02" phx-click="delete">Delete</:action>
    </.bulk_bar>

The texts come from outside: `label` and `label_plural` (the part after the badge), `select_all_label`
(`%{total}` is replaced) and `clear_label`. Nothing is pluralized here, so any language works.

### Looks

`variant="inverse"` (default) is the opposite of the page: a dark bar on a light page, a light one on a dark
page. `soft` is the page's own surface with a ring, for when the inverted bar weighs too much. `solid` is the
canvas bar: the `--solid` surface, the count written in bold ("3 selecionados") instead of a badge, no
separators, rounded `sm` buttons (`soft`, `ghost`, `danger`...), and a close button only when there is an
`on_clear`. `floating`
(default) pins the bar to the bottom center of the viewport above the page; `floating={false}` lays it out
where it is, for a bar inside a card or a toolbar.

### Slots

`:field` holds a control (a `select`, an `input`); it is skinned as a quiet field the height of the buttons,
and a listbox inside it opens upwards when the bar is floating. `:action` is a button: `variant` is
`default`, `primary` (the one main action, `disabled` until there is something to apply) or `danger` (last,
in red; it only looks the part, so confirm in your handler or with `data-confirm`); `icon` is a Hugeicons
name; every other attribute (`phx-click`, `phx-value-*`, `data-*`) goes to the button. A `disabled` action
keeps the focus (it is `aria-disabled`, not a native `disabled`) and does nothing: its `phx-*` attributes
are not rendered.

### Progress

While a bulk action runs, `progress` (done) and `progress_max` (all) turn the bar into a progress bar: the
`label` in bold as it is given (no count before it), a meter and the "5/12" fraction.

    <.bulk_bar id="emit" count={12} variant="solid" label="Emitindo 12 notas…" progress={5} progress_max={12} />

### Confirm

An `:action` with `confirm` (a title) asks first: the button opens a small card under the bar (above it when
floating) with `confirm_text`, a cancel and a confirm button; only the confirm button runs the action's
`phx-click`.

    <:action variant="danger" icon="huge-delete-02" phx-click="delete" confirm="Excluir 3 pedidos?"
      confirm_text="Os rascunhos somem para todos." confirm_label="Excluir" cancel_label="Cancelar">
      Excluir
    </:action>

### Keyboard

Esc clears the selection (it presses the close button), unless it was meant for an open list or another
control. `show_esc` writes the key as a chip in the close button. The bar is a labelled region and announces the count as it changes.

### `<.bulk_bar>`

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `count` (required) | `:integer` |  | How many are selected; the bar shows only above zero. |
| `label` | `:string` | `"selected"` | The text after the badge, for one selected. |
| `label_plural` | `:string` | `nil` | The text after the badge for several; `label` when it is `nil`. |
| `total` | `:integer` | `nil` | How many there are in all (every page); with `on_select_all`, offers to select them all. |
| `select_all_label` | `:string` | `"Select all %{total}"` | The select all link; `%{total}` is replaced. |
| `on_clear` | `:any` | `nil` | An event name or a `%JS{}` run by the close button and Esc. |
| `on_select_all` | `:any` | `nil` | An event name or a `%JS{}` run by the select all link. |
| `target` | `:any` | `nil` | The `phx-target` of both. |
| `clear_label` | `:string` | `"Clear selection"` |  |
| `show_esc` | `:boolean` | `false` | Writes a visible `Esc` key chip in the close button (the button is always labelled with it). |
| `variant` | `:string` | `"inverse"` | `inverse`, `soft`, `solid` |
| `floating` | `:boolean` | `true` | Pin the bar to the bottom center of the viewport. |
| `progress` | `:integer` | `nil` | How many are done, for a running bulk action: shows a meter and `progress/progress_max`. |
| `progress_max` | `:integer` | `nil` | How many there are to do, with `progress`. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:action>` — attrs: `variant`, `disabled`, `icon`, `confirm`, `confirm_text`, `confirm_label`, `cancel_label`, `id`, `title`, `aria-label`, `phx-click`, `phx-target`, `phx-disable-with`, `phx-value-id` — A button.
- `<:field>` — A control, skinned as a quiet field.
