# Drawer

Painel lateral para detalhes e edição sem sair da lista.

**Grupo:** 12 · Sobreposições  
**Resumo visual:** placement left · right · bottom · variant float/flush · size sm–xl · rodapé fixo

## Uso (Phoenix / HEEx)

```heex
<.drawer id="account" placement="right" floating>…</.drawer>
```

## Regras

- Padrão flutuante a 8px das bordas; `edge` cola na lateral.
- Largura 380–480; rodapé fixo com ações.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: drawer)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's drawer: a full-height panel that slides in from the left or the right over a dark
backdrop. Bare, it is a sliding frame for a menu; with a `title` (or a `:header`) and a `:footer`
it is a sheet, the panel a form or a detail opens in: a header with the title, its description
and the close ×, a body that scrolls, and a footer with the buttons.

    <.button phx-click={LedgerUI.toggle("menu")}>Menu</.button>

    <.drawer id="menu" side="right">
      <nav class="p-5">…</nav>
    </.drawer>

    <.drawer id="customer" placement="right" size="md" title="New customer"
      description="Who buys from you." on_close="cancel">
      <.form for={@form} id="customer-form" phx-submit="save">…</.form>
      <:footer>
        <.button variant="outline" phx-click={LedgerUI.close("customer")}>Cancel</.button>
        <.button type="submit" form="customer-form" color="primary">Save</.button>
      </:footer>
    </.drawer>

`size` sets the sheet's width (`sm` 400px, `md` 520px, `lg` 640px, `wide` 800px, `xl` 1080px), never wider
than the screen, so it is full width on a phone. Buttons in the header go in `:actions`, a back
arrow (a sheet opened from another) in `:back`.

A sheet is `variant="float"` by default: 12px from the screen's edges, 16px corners, always the
whole height, the footer fixed under the body. `variant="flush"` is the panel glued to the edge,
as Ledger UI draws it. `placement` is `left`, `right` or `bottom`; the bottom one is the phone's
sheet, a rounded panel with a grab handle, 78% of the screen's height and the full width.

The header, the body and the footer are also components of their own, for a sheet laid out by
hand (`variant` makes a bare drawer a sheet):

    <.drawer id="edit-customer" variant="float" size="lg" on_close={JS.patch(~p"/customers")}>
      <.sheet_header title="Edit customer" description="Since March 2025" />
      <.sheet_body>
        <.input field={@form[:legal_name]} label="Legal name" />
      </.sheet_body>
      <.sheet_footer>
        <.button variant="outline" phx-click={LedgerUI.close("edit-customer")}>Cancel</.button>
        <.button color="primary">Save</.button>
      </.sheet_footer>
    </.drawer>

Like the modal it opens from the browser (`LedgerUI.open/close/toggle("id")`), from the server
(`LedgerUI.open(socket, "id")`) or from `open`; `on_close` runs however it closed (Esc, the
backdrop, the ×, a command), so the server can follow. By default a drawer does not lock the
page's scroll, as in Ledger UI (`lock_scroll` locks it).

Drawers and modals stack in the order they open: a drawer opened from another (a detail, then
its edit form), or a modal opened from a drawer, is drawn above it; Esc and the backdrop close
only the one on top. The second overlay may sit next to the first or inside its markup (a
confirm rendered in the sheet's body or footer): the open drawer carries no CSS `transform`
(the slide is an animation that only runs while it enters and leaves, with no fill), so it
is not a containing block for `position: fixed` and a modal inside it still covers the whole
viewport, above the drawer. Keep `panel_class` and `class` free of `transform`, `filter`,
`backdrop-filter`, `perspective` and `contain` for the same reason. Nothing is moved out of
the LiveView's DOM, so patches reach the nested modal as usual.
The layers come from the CSS custom properties `--ledger-z-overlay` (drawers) and
`--ledger-z-modal` (modals), see the README.

### `<.drawer>`

Renders a drawer, closed unless `open`.

Events: `on_open` and `on_close` push `%{"id" => id}` when they are event names.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `open` | `:boolean` | `false` |  |
| `side` | `:string` | `"left"` | `left`, `right` |
| `placement` | `:string` | `nil` | ``, `left`, `right`, `bottom` — The same as `side`, which it overrides when given. `bottom` is the phone's sheet: full width, 78% of the height, with a grab handle. |
| `size` | `:string` | `nil` | ``, `sm`, `md`, `lg`, `wide`, `xl` — The sheet's width: `sm` 400px, `md` 520px, `lg` 640px, `wide` 800px, `xl` 1080px, full width on a phone. `nil` is Ledger UI's `w-72` frame. |
| `variant` | `:string` | `nil` | ``, `float`, `flush` — A sheet is `float` unless told otherwise: 12px from the edges, 16px corners, the whole height, a fixed footer. `flush` is glued to the edge. Giving it makes a drawer without title or footer a sheet, for `sheet_header`, `sheet_body` and `sheet_footer` laid out by hand. |
| `title` | `:string` | `nil` | The sheet's title; draws the header. |
| `description` | `:string` | `nil` | A line under the title. |
| `close_button` | `:boolean` | `true` | The × at the end of the header (only drawn when there is a header). |
| `close_label` | `:string` | `"Close"` |  |
| `overlay` | `:boolean` | `true` | The dark backdrop, which closes the drawer when clicked. |
| `lock_scroll` | `:boolean` | `false` | Locks the page's scroll while it is open, as a modal does. |
| `prevent_close` | `:boolean` | `false` | Esc and the backdrop do not close it. |
| `on_open` | `:any` | `nil` | An event name or a `%JS{}`. |
| `on_close` | `:any` | `nil` | An event name or a `%JS{}`. |
| `target` | `:any` | `nil` | The `phx-target` of `on_open` / `on_close` events. |
| `class` | `:any` | `nil` | Merged into the sliding frame: its width (`size`, or `w-72`; e.g. `class="w-96"`) and shadow. |
| `panel_class` | `:any` | `nil` | Merged into the white panel inside the frame. |
| `body_class` | `:any` | `nil` | Merged into the scrolling body of a sheet (`px-6 py-5`, a column with `gap-4`). |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:actions>` — Buttons at the end of the header, before the ×.
- `<:back>` — Before the title: the button back to the sheet this one was opened from (`phx-click={LedgerUI.close("this")}`).
- `<:footer>` — attrs: `class` — The buttons under the body, aligned to the end, on a tinted bar.
- `<:header>` — attrs: `class` — The header's content instead of `title` and `description`; the back arrow, the actions and the × still frame it.
- `<:inner_block>` (required)

### `<.sheet_header>`

The header of a sheet: the title with its description, a back arrow, buttons and the close ×.
A `drawer` with `title`, `:header`, `:back` or `:actions` draws it by itself; use this one to lay
a sheet out by hand.

    <.sheet_header title="Edit customer" description="Since March 2025">
      <:actions><.button size="sm">Archive</.button></:actions>
    </.sheet_header>

The × closes the drawer it is in (the closest one), or the `drawer` with that id.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` | `nil` | The id of the title, for the drawer's `aria-labelledby`. |
| `drawer` | `:string` | `nil` | The id of the drawer the × closes; the closest drawer when not given. |
| `title` | `:string` | `nil` |  |
| `description` | `:string` | `nil` | A line under the title. |
| `close_button` | `:boolean` | `true` |  |
| `close_label` | `:string` | `"Close"` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:actions>` — Buttons at the end of the header, before the ×.
- `<:back>` — Before the title: the button back to the sheet this one was opened from.
- `<:content>` — The header's content instead of `title` and `description`.

### `<.sheet_body>`

The scrolling body of a sheet: it takes the height the header and the footer leave and scrolls by
itself, so the footer stays in place.

    <.sheet_body>…the form…</.sheet_body>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.sheet_footer>`

The footer of a sheet: the buttons, aligned to the end on a tinted bar that never scrolls with the
body.

    <.sheet_footer>
      <.button variant="outline" phx-click={LedgerUI.close("customer")}>Cancel</.button>
      <.button color="primary">Save</.button>
    </.sheet_footer>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
