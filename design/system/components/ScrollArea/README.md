# ScrollArea

Contêiner com rolagem e barra discreta, com sombra indicando mais conteúdo.

**Grupo:** 13 · Estrutura e shell  
**Resumo visual:** orientation both/horizontal/vertical · scrollbar always/hover/hidden

## Uso (Phoenix / HEEx)

```heex
<.scroll_area class="h-64">…</.scroll_area>
```

## Regras

- Barra de 6px em `line-strong`; sombra de borda só quando há rolagem.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: scroll_area)

Todos os function components, atributos, valores e slots que este componente cobre.

A box that scrolls with Ledger UI's thin scrollbar (`scrollbar-sm`): 6px, no arrows, a transparent
track and a thumb that shows when the pointer or the focus is inside. For long menus, lists in
a card, the body of a panel.

    <.scroll_area class="max-h-64">
      <.dropdown_item :for={city <- @cities}>{city}</.dropdown_item>
    </.scroll_area>

The height comes from `class` (`max-h-64`, `h-full`...). Without the component, the same
scrollbar is the `scrollbar-sm` class on any box that overflows; `scrollbar-sm scrollbar-always`
keeps the thumb shown, and Ledger UI's `is-scrollbar-hidden` hides it.

`focusable` lets the keyboard scroll the box and draws a 2px focus ring around it. A focusable box
needs a name, so give it a `label`:

    <.scroll_area focusable label="Release notes" class="max-h-64">…</.scroll_area>

### Pinned to the bottom

`stick_bottom` keeps a list that grows at its end, a chat or a stream of replies, scrolled to its
last item: the `LedgerUI.ScrollBottom` hook scrolls down when the box mounts and each time the
server patches it, unless the reader scrolled up to read (within 32px of the end counts as the
end; scrolling back down pins it again). It needs a stable `id`.

    <.scroll_area id="messages" stick_bottom class="h-96 px-4 py-5">
      <.message :for={message <- @messages} message={message} />
    </.scroll_area>

### `<.scroll_area>`

Renders a scrolling box.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `orientation` | `:string` | `"vertical"` | `both`, `horizontal`, `vertical` — The directions it scrolls in. |
| `scrollbar` | `:string` | `"hover"` | `always`, `hidden`, `hover` — `hover` shows the thumb under the pointer or the focus, `always` keeps it, `hidden` hides it. |
| `focusable` | `:boolean` | `false` | Makes the box reachable with Tab, so the keyboard can scroll it (when nothing inside takes focus). |
| `label` | `:string` | `nil` | With `focusable`, the box becomes a `role="region"` named by this `aria-label`, so a screen reader says what the focus landed on. Ignored when it is not focusable. |
| `id` | `:string` | `nil` | Required with `stick_bottom`, and it must not change. |
| `stick_bottom` | `:boolean` | `false` | Keeps the box scrolled to its end when content is added, unless the reader scrolled up. |
| `class` | `:any` | `nil` | Its size (`max-h-64`, `h-full`) and padding. |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
