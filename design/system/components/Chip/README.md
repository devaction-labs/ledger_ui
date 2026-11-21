# Chip

Chip interativo para filtros rápidos; alterna ao clicar.

**Grupo:** 04 · Formulários — seleção  
**Resumo visual:** Filtros rápidos: selecionável, com contagem, adicionar

## Uso (Phoenix / HEEx)

```heex
<.chip selected={@pro?} phx-click="toggle" value="pro">Pro</.chip>
```

## Regras

- Raio 10, como botão pequeno; o ativo fica `inverse`.
- Chip tracejado “+ Filtro” abre o FilterMenu.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: chip)

Todos os function components, atributos, valores e slots que este componente cobre.

The chip, a kit CSS `badge`: a small pill for an applied filter or a selected person, with an optional
avatar and a plain x that removes it.

    <.chip label="Situação: Aprovação" on_remove={JS.hide(to: "#c1")} id="c1" />
    <.chip avatar="Marina Costa" avatar_color="#8a5cd6" on_remove="remove_person" id="p-1">
      Marina Costa
    </.chip>
    <.chip label="Matriz" />

With `href`, `navigate` or `patch` the chip itself is a link (`<.link class="badge">`), for filters that
live in the URL; a link chip has no x. A removable chip whose x is a patch takes `remove_patch`:

    <.chip patch={~p"/extract?account=1"} label="Conta 1" />
    <.chip label="Aberta" remove_patch={~p"/tasks"} />

Without `on_remove` it is read only (no x). An event name in `on_remove` is pushed with
`%{"id" => id}`; a `JS` command runs as is.

### `<.chip>`

Renders a chip, with `label` or the inner block as its text.

    <.chip label="Vendedor: Rafael" on_remove="clear_seller" />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `label` | `:string` | `nil` | The text; the inner block replaces it when given. |
| `size` | `:string` | `"md"` | `sm`, `md`, `lg` — The height: 24px (`sm`, for chips inside a field), 30px (`md`) or 32px (`lg`); padding, font and icon stay the same. |
| `avatar` | `:string` | `nil` | A person's name: draws a 24px avatar with its initials before the text. |
| `avatar_color` | `:string` | `nil` | A CSS color for the avatar's background; without it the avatar takes one from the name. |
| `avatar_src` | `:string` | `nil` | A picture for the avatar instead of the initials. |
| `on_remove` | `:any` | `nil` | An event name or a `JS` command: adds the x button. The event's payload is `%{"id" => id}`. |
| `remove_patch` | `:string` | `nil` | A path: the x becomes a `<.link patch>` to it (the filter's URL without this chip) instead of a button; `on_remove` is then not used. |
| `id` | `:string` | `nil` |  |
| `target` | `:any` | `nil` | The `phx-target` of `on_remove` when it is an event name. |
| `remove_label` | `:string` | `"Remove"` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `href`, `navigate`, `patch`, `method`, `download`.

Slots:

- `<:inner_block>`
