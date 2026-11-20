# Modal

Diálogo modal para tarefas curtas e confirmações.

**Grupo:** 12 · Sobreposições  
**Resumo visual:** animation fade · scale · sheet · shift-down · shift-up · size xs–full · placement top/center/bottom · origin · close_variant · alertdialog

## Uso (Phoenix / HEEx)

```heex
<.modal id="export" show={@show}>
  <:title>Exportar relatório</:title>
  …
  <:actions>…</:actions>
</.modal>
```

## Regras

- Largura 440 (sm), 560 (md), 720 (lg). Raio 20, sombra lg, véu `bg-overlay`.
- Rodapé com fundo `bg-tray`: secundário à esquerda do primário.
- Esc e clique no véu fecham; foco preso dentro.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: modal)

Todos os function components, atributos, valores e slots que este componente cobre.

A modal in kit CSS's look: a centered `base-100` box with the theme's `rounded-box` corners over a dark
backdrop, with its enter and leave animations.

    <.button phx-click={LedgerUI.open("edit-pin")}>Edit</.button>

    <.modal id="edit-pin" animation="scale" origin="top">
      <:header>Edit Pin</:header>
      <p>Lorem ipsum dolor sit amet.</p>
      <:footer>
        <.button phx-click={LedgerUI.close("edit-pin")}>Cancel</.button>
      </:footer>
    </.modal>

It opens and closes in the browser (`LedgerUI.open/close/toggle("id")`), from the server
(`LedgerUI.open(socket, "id")`) or from an assign:

    <.modal id="confirm" open={@confirming} on_close="cancel-confirm">…</.modal>

`on_close` runs however the modal closed (Esc, the backdrop, the close button, a command), so
the server can keep `@confirming` in sync. With an event name the LiveView (or `target`) gets
`handle_event("cancel-confirm", %{"id" => "confirm"}, socket)`; a `%JS{}` is run as is.
Without a `:header` the close × sits in the card's corner above the content; give wide content
(an image) a `close_variant="chip"` so the button keeps a backdrop.

`title` (with `description`) gives it the header of a sheet instead (the design canvas modal): the
19px title over a muted line with the round × at the end, the body under it, and the `:footer`
buttons aligned to the end over a line, like a `LedgerUI.Components.Drawer` sheet:

    <.modal id="delete-customer" title="Delete customer?" description="Casa das Tintas" class="max-w-[440px]">
      <p>The orders stay in the history.</p>
      <:footer>
        <.button variant="ghost" phx-click={LedgerUI.close("delete-customer")}>Cancel</.button>
        <.button color="error">Delete customer</.button>
      </:footer>
    </.modal>

`prevent_close` keeps Esc and the backdrop from closing it.

A modal opened from a drawer (or from another modal) is drawn above it, and Esc closes only
the one on top; render it next to the drawer, not inside its markup. Its layer is the CSS
custom property `--ledger-z-modal` (see the README).

### `<.modal>`

Renders a modal, closed unless `open`.

Events: `on_open` and `on_close` push `%{"id" => id}` when they are event names.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `open` | `:boolean` | `false` | The server's state; the browser can still open and close it. |
| `animation` | `:string` | `"fade"` | `fade`, `scale`, `sheet`, `shift-down`, `shift-up` — Ledger UI's transitions: the backdrop always fades, the card shifts, scales or slides up. |
| `size` | `:string` | `"lg"` | `full`, `lg`, `md`, `sm`, `xl`, `xs` — The card's maximum width. |
| `placement` | `:string` | `"center"` | `bottom`, `center`, `top` |
| `origin` | `:string` | `"center"` | `bottom`, `center`, `top` — Where the `scale` animation grows from. |
| `blur` | `:boolean` | `false` | Blurs the page behind the backdrop. |
| `backdrop_class` | `:any` | `nil` | Merged into the backdrop (`bg-black/20` for a lighter one than the default `bg-black/40`). |
| `prevent_close` | `:boolean` | `false` | Esc and the backdrop do not close it. |
| `close_button` | `:boolean` | `true` | The × in the header; without a header it sits in the card's corner. |
| `close_variant` | `:string` | `"plain"` | `plain`, `chip` — The corner × of a modal without a header: `plain` is a bare icon button, `chip` gives it a translucent backdrop so it stays legible over wide content such as an image. |
| `on_open` | `:any` | `nil` | An event name or a `%JS{}`. |
| `on_close` | `:any` | `nil` | An event name or a `%JS{}`. |
| `target` | `:any` | `nil` | The `phx-target` of `on_open` / `on_close` events. |
| `close_label` | `:string` | `"Close"` |  |
| `role` | `:string` | `"dialog"` | `dialog`, `alertdialog` — `alertdialog` for confirmations that interrupt the user (a destructive action); point `aria-describedby` at the message. |
| `title` | `:string` | `nil` | A sheet's header (the canvas modal): the title, `description` under it and the × (unless `close_button` is false); the `:footer` becomes the sheet's footer. |
| `description` | `:string` | `nil` | The line under `title`. |
| `body_class` | `:any` | `nil` | Merged into the body under a `:header` (`px-4 py-4 sm:px-5` by default) or a `title` (the sheet body). |
| `class` | `:any` | `nil` | Merged into the card. |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:footer>` — attrs: `class`
- `<:header>` — attrs: `variant`, `class`
- `<:inner_block>` (required)
