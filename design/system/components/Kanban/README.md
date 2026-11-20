# Kanban

Quadro em colunas para fluxo de trabalho (renovações, casos, tarefas).

**Grupo:** 09 · Fluxo de trabalho  
**Resumo visual:** color neutral/info/warning/primary/teal/success · hint empty/always · arrastar entre colunas

## Uso (Phoenix / HEEx)

```heex
<.kanban columns={@stages} items={@deals} on_move="move" />
```

## Regras

- Coluna é uma bandeja (`lu-card` sem título overline); card arrastado inclina 2° com sombra md.
- Contagem e soma de valor no topo de cada coluna.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: kanban)

Todos os function components, atributos, valores e slots que este componente cobre.

A kanban board: a row of tinted columns (a stage of a sales funnel, a status of a task) holding cards that are
dragged between them, with a native drag and drop on pointer events and no library. It is the Signetum canvas's
`AppKanban`, and the same parts serve a plain task board.

    <.kanban id="funnel" event="move" group="orders" class="min-h-[600px]">
      <.kanban_column
        :for={stage <- @stages}
        id={"col-" <> stage.id}
        list={stage.id}
        label={stage.name}
        color={stage.color}
        count={length(stage.orders)}
        meta={"#{stage.chance}% chance"}
        total={brl(stage.total)}
        progress={stage.chance}
      >
        <:icon><.icon name={stage.icon} class="size-3.5" /></:icon>
        <:actions>
          <.button size="sm" variant="flat" icon class="size-[26px]" aria-label={"Options of " <> stage.name}>
            <.icon name="huge-more-horizontal" class="size-4" />
          </.button>
        </:actions>
        <.kanban_card :for={order <- stage.orders} id={"order-#{order.id}"} item={order.id} risk={order.idle > 7}>
          <b>{order.customer}</b>
        </.kanban_card>
        <:empty title="No orders here">Drag an order here when it stalls.</:empty>
        <:footer><.button variant="outline" size="sm" class="h-[34px] w-full border-dashed">New order</.button></:footer>
      </.kanban_column>
      <.kanban_lost label="Lost" count={3} meta="R$ 6.410,00" />
    </.kanban>

The board is a `role="group"`; give it an `aria-label` (`aria-label="Sales funnel"`) so it is announced.
A column with a `limit` (a work in progress limit) turns the pill and the bar red when the count goes over
it (`data-wip="exceeded"`); the text of the stats line is yours (`meta="limit of 3 in progress" total="4 of 3"`).
A `disabled` column is drawn at 60% opacity.

The board is one `LedgerUI.Sortable` hook: every column is a list (`data-list`), every card an item
(`data-id`), and all the columns of the board are in one group, so a card can be dropped on any of them or
reordered inside its own. Dropping pushes `event` (to `target` when given, else the LiveView) with the card's
and the columns' ids and the index the card takes there:

    def handle_event("move", %{"id" => id, "from" => from, "to" => to, "index" => index}, socket),
      do: {:noreply, update(socket, :orders, &Orders.move(&1, id, from, to, index))}

Nothing is moved in the browser, the server's render is the new order. While a card is dragged the original
stays as a quiet dashed placeholder (`data-dragging`), a lifted copy of the card follows the pointer (tilting
a little towards the movement, with a big soft shadow) and, on a drop, glides into its slot or flies back when
the drop is cancelled. The cards of the column under the pointer (`data-over`, which only tints the
column) slide out of the way as the copy crosses them, opening a gap with a dashed placeholder, and the board
and the columns scroll when the pointer is near their edges. A drop where the card already was pushes nothing.
A mouse, a pen and a finger share this: a mouse or a pen drags after moving a few pixels (a click on the card, a
link or a button in it still works), a finger holds the card for a moment first. Escape cancels. A button in the
card that pushes the same event with the next column (`phx-click`) is the alternative for the keyboard and for
screens where dragging is awkward.

### Another board

The old `kanban` of an admin template (columns that are reordered by a handle, free-form cards) needs no column:
put `phx-hook="LedgerUI.Sortable"` on your own list and the data attributes of the hook on it.

    <div id="columns" phx-hook="LedgerUI.Sortable" data-event="move_column" data-list="columns" data-handle=".grip" data-axis="x">
      <div :for={col <- @columns} data-id={col.id}>...</div>
    </div>

A list that holds the cards of a column in its own group does the same for the cards:

    <div id={"cards-#{col.id}"} phx-hook="LedgerUI.Sortable" data-group="cards" data-list={col.id} data-event="move_card">
      <.card :for={card <- col.cards} data-id={card.id}>...</.card>
    </div>

A single list with no group is a sortable list, e.g. a to-do list:

    <div id="todos" phx-hook="LedgerUI.Sortable" data-list="todos" data-event="reorder">
      <div :for={todo <- @todos} data-id={todo.id}>{todo.title}</div>
    </div>

The attributes of the hook, on a list or on the element that holds the lists (a list's own wins):

  * `data-event` - the server event to push on a drop.
  * `data-target` - its `phx-target`; without it the LiveView of the hook gets the event.
  * `data-group` - lists with the same group exchange items; without one an item stays in its list.
  * `data-list` - the list's id, sent as `from` and `to`.
  * `data-handle` - a CSS selector inside the item; only a drag that starts on it moves the item.
  * `data-axis` - `x` for items laid in a row, `y` (default) for items stacked.
  * `data-disabled` - the list neither gives nor takes items (any value but `false`).

Items carry `data-id`, the id the server gets as `id`. The default look comes from `parts/sortable.css`: a quiet
`[data-dragging]` item, the lifted `.linea-drag-ghost` and the dashed `.linea-drop-slot`, all zero-specificity
and easy to override with utilities.

### `<.kanban>`

Renders the board: a row of columns that scrolls sideways, and the drag and drop between them.

Dropping a card pushes `event` with `%{"id" => card_item, "from" => column_list, "to" => column_list, "index" => position}`
to `target`, or to the LiveView when there is none.

    <.kanban id="funnel" event="move" target={@myself} class="min-h-[600px]">
      <.kanban_column id="col-open" list="open" label="Open" count={length(@open)}>
        <.kanban_card :for={card <- @open} id={"card-#{card.id}"} item={card.id}>{card.title}</.kanban_card>
      </.kanban_column>
    </.kanban>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  | Required by the hook. |
| `event` | `:string` | `nil` | The event pushed when a card is dropped; without one nothing is pushed. |
| `target` | `:any` | `nil` | The `phx-target` of the event (a selector or `@myself`); the LiveView gets it when `nil`. |
| `group` | `:string` | `nil` | The group whose columns exchange cards. The board's `id` by default, so two boards on a page do not exchange. |
| `disabled` | `:boolean` | `false` | `true` stops the cards from being dragged or dropped, e.g. for a read-only viewer. |
| `fluid` | `:boolean` | `false` | `true` makes the columns share the width of the page (each `flex-1`, no fixed 272px, no sideways scroll) like the canvas `lu-kb`. The `kanban_lost` aside keeps its 52px. |
| `active` | `:string` | `nil` | The phone mode: sets `data-phone` on the board; below 640px only the column with `active` set shows (no header, no well), the others are hidden. Mark that column with `active` too. |
| `class` | `:any` | `nil` | Merged into the scrolling row, e.g. `min-h-[600px]` for a board that fills the screen. |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required) — The `kanban_column`s, then a `kanban_lost`.

### `<.kanban_column>`

Renders a column: a tinted well, 272px wide, that is the drop list of its cards.

The header has the `icon` tile in the color of the stage, the `label`, the number of cards (the canvas count,
pushed to the right end on the sunken fill) and the `actions` (a menu button). Under it a line with `meta` on the left and `total` on the right, and a 4px bar filled to
`progress`. The cards are the inner block; `empty` shows when `count` is `0`, and `footer` closes the column.

    <.kanban_column id="col-approved" list="approved" label="Approved" color="primary" count={2}
      meta="80% chance" total="R$ 2.158,80" progress={80}>
      <:icon><.icon name="huge-security-check" class="size-3.5" /></:icon>
      <.kanban_card id="order-2481" item="2481">...</.kanban_card>
      <.kanban_card id="order-2458" item="2458" risk>...</.kanban_card>
    </.kanban_column>

The column is the `data-list` of the board's hook: a drop on it pushes `to` with `list`.

An `empty` with no `title` is the canvas's compact hint, a dashed well with its text:

    <:empty>Arraste para cá</:empty>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  | The DOM id of the column. |
| `list` | `:string` | `nil` | The id the server gets as `from` and `to` (the hook's `data-list`); defaults to `id`. |
| `label` (required) | `:string` |  | The column's name, also its `aria-label`. |
| `count` | `:any` | `nil` | The number of cards (an integer or a text), in the pill by the label; `nil` shows no pill. `empty` needs it to be `0`. |
| `count_label` | `:string` | `nil` | The text of the pill instead of `count`, e.g. `"5 / 3"` for a work in progress counter. |
| `over_limit` | `:boolean` | `false` | `true` turns the pill and the bar red (`data-wip="exceeded"`) whatever `count` and `limit` say, for a `count_label` the kit cannot compare. |
| `hint` | `:string` | `"empty"` | `empty`, `always` — When the `empty` slot shows: `empty` only when `count` is `0`, `always` also under the cards of the column. |
| `active` | `:boolean` | `false` | The column the phone mode of the board (`active` of `kanban`) shows; sets `data-phone-active`. |
| `color` | `:string` | `"neutral"` | `neutral`, `info`, `warning`, `primary`, `teal`, `success` — The color of the icon tile and of the progress bar. |
| `limit` | `:integer` | `nil` | A work in progress limit: with a `count` above it the pill and the bar turn red (`data-wip="exceeded"`). The words of the limit go in `meta` and `total`. |
| `meta` | `:string` | `nil` | The text on the left of the stats line, e.g. `60% chance`. |
| `total` | `:string` | `nil` | The bold text on the right of the stats line, e.g. a sum. |
| `progress` | `:integer` | `nil` | 0 to 100: the fill of the 4px bar under the stats; `nil` shows no bar. |
| `disabled` | `:boolean` | `false` | `true` makes this column neither give nor take cards. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:actions>` — The header's menu button, at its right end.
- `<:empty>` — attrs: `title`, `icon` — Shown instead of cards when `count` is `0`: an illustration, `title` and the text; without a `title`, the compact dashed hint with the text.
- `<:footer>` — After the cards, e.g. the dashed add button.
- `<:icon>` — The glyph in the 26px tile of the header (`size-3.5`).
- `<:inner_block>` — The `kanban_card`s.

### `<.kanban_card>`

Renders a card: a white rounded surface with a hairline ring that is dragged between columns.

The content is yours, the inner block (the canvas's card is a number in mono, the customer, the value in bold,
tags and a dashed footer with a button that advances it). `risk` gives it the warning ring and `grip` the
drag handle that shows on hover.

    <.kanban_card id="order-2462" item="2462" risk>
      <span class="font-mono text-xs text-base-content/50">#2462</span>
      <a href="#" class="font-semibold">Hospital Santa Clara</a>
      <.button size="sm" variant="flat" icon phx-click="advance" phx-value-id="2462" aria-label="Move on">
        <.icon name="huge-arrow-right-02" class="size-4" />
      </.button>
    </.kanban_card>

A button inside is clickable as usual; the card is dragged by any other part of it, with a pointer that moves.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  | The DOM id of the card. |
| `item` | `:any` | `nil` | The id the server gets as `id` in the drop event (the hook's `data-id`); defaults to `id`. |
| `risk` | `:boolean` | `false` | The warning ring of a card that needs attention. |
| `dense` | `:boolean` | `false` | `true` tightens the card to 12px of padding and an 8px gap, for a long board. |
| `grip` | `:boolean` | `false` | A six dot handle in the top right corner that shows while the card is hovered or has the focus, the cue that it can be dragged. Keep the first line of the content clear of it. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:actions>` — A menu button in the top right corner, shown only while the card is hovered or has the focus (always on a touch screen).
- `<:inner_block>` (required)

### `<.kanban_lost>`

Renders the 52px vertical aside that closes the board: the lost cards, with their count and a vertical label.

    <.kanban_lost label="Lost" count={3} meta="R$ 6.410,00" />

With `list`, the aside is also a drop target: a card dropped on it pushes `to` with that id and index `0`.

    <.kanban_lost label="Lost" count={3} list="lost" />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `label` (required) | `:string` |  | The vertical text, also the `aria-label`. |
| `count` | `:integer` | `nil` | The number of lost cards, in the pill under the icon. |
| `meta` | `:string` | `nil` | Text after the label, separated by a dot (a sum). |
| `list` | `:string` | `nil` | Makes the aside a drop list with this id for the `to` of the event; `nil` for a plain aside. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:icon>` — The glyph on top; a red crossed circle by default (`size-5`).
