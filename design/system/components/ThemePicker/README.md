# ThemePicker

Galeria de temas nomeados com miniatura do layout; troca a paleta inteira.

**Grupo:** 14 · Temas e marca  
**Resumo visual:** variant menu · grid

## Uso (Phoenix / HEEx)

```heex
<.theme_picker themes={@themes} current="ledger" />
```

## Regras

- Cada tema redefine só tokens (superfícies, ink, accent, séries).
- Miniatura mostra sidebar, card e acento reais.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: theme_picker)

Todos os function components, atributos, valores e slots que este componente cobre.

Lets the user choose a named theme (`LedgerUI.Theme`), as kit CSS's theme controller does: a menu in the top bar
or a grid of previews on a settings page. Each option previews its own palette (its swatches carry the theme's
`data-theme`), in the light or dark mode the page is in.

    <.theme_picker id="palette" />
    <.theme_picker id="palette" variant="grid" />
    <.theme_picker id="palette" themes={~w(linea ocean forest)} label="Tema" />

The theme is a palette, apart from the mode: `theme_switch/1` still picks light, dark or system, and the picker
picks which palette is light or dark. So the two sit side by side.

### What it does

The `LedgerUI.ThemePicker` hook puts the chosen id on `<html data-theme>`, keeps it in
`localStorage["linea-theme"]`, marks the option (`aria-checked`) and tells every picker on the page through the
`change:theme` window event. `on_change` also sends the choice to the LiveView (`%{"theme" => id}`), to keep it on
the user's profile, say. Put `<.theme_script theme="..." />` in the root layout's `<head>` so the stored theme is
on before the first paint; `default` (or `config :ledger_ui, :theme`) is the one shown when nothing is stored.

`themes` takes ids or maps (`%{id, label}`) and defaults to `LedgerUI.Theme.all/0`: the kit's twelve plus the
app's (`config :ledger_ui, :themes, extra: [%{id: "acme", label: "Acme"}]`, CSS from
`mix ledger_ui.gen.theme`).

### `<.theme_picker>`

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `variant` | `:string` | `"menu"` | `menu`, `grid` — `menu` (a button that opens the list) or `grid` (previews to click, for a settings page). |
| `themes` | `:list` | `nil` | Ids or `%{id, label}` maps; default `LedgerUI.Theme.all/0`. |
| `default` | `:string` | `nil` | The theme shown when nothing is stored (default `config :ledger_ui, :theme`, else `"linea"`). |
| `label` | `:string` | `"Theme"` | Names the menu button and the group. |
| `placement` | `:string` | `"bottom-end"` | Where the menu opens (the `menu` variant). |
| `on_change` | `:string` | `nil` | An event pushed with `%{"theme" => id}`. |
| `target` | `:any` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.
