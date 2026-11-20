# Fab

Botão de ação flutuante que se retrai: pílula com o ícone num disco e o rótulo, que encolhe para só a bolha quando não está em uso.

**Grupo:** 02 · Ações  
**Resumo visual:** Retrátil: retract hover · auto · never · always · expanded · color assistant/primary/dark/light · size · badge · position · variant canvas

## Uso (Phoenix / HEEx)

```heex
<.fab id="ask" label="Pergunte ao assistente" phx-click="open_assistant" />
<.fab id="help" label="Precisa de ajuda?" retract="auto" retract_after={6000} />
<.fab id="new" label="Nova fatura" retract="never" color="primary" />
<.fab id="chat" label="Chat" retract="always" color="light" position="bottom-left" badge={3} />
<.fab id="new" label="Novo pedido" variant="canvas" offset={18} />
```

## Regras

- `hover` (padrão): bolha em repouso, expande no hover e no foco do teclado.
- `auto`: começa expandido e recolhe depois de `retract_after` ms (4000) ou ao rolar; expande de novo no hover.
- `never`: sempre expandido. `always`: sempre bolha; o rótulo vira `aria-label` e tooltip nativo.
- `expanded` força a pílula aberta (dica de onboarding). Em touch, todo modo menos `never` é bolha e o toque executa direto.
- `variant="canvas"` é o botão sólido `inverse` raio 18 com rótulo sempre visível; `variant="pill"` é a pílula retrátil.
- Fica abaixo de modais/drawers e acima da página (`--ledger-z-fab`, 90).

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: fab)

Todos os function components, atributos, valores e slots que este componente cobre.

A floating action button that retracts: a navy pill holding a round icon tile and a label, which shrinks to
just the round bubble when it is not in use.

    <.fab id="ask" label="Ask the assistant" phx-click="open_assistant" />

The label is always in the DOM and is the button's `aria-label`. `color` picks the look (`assistant` is the
indigo to purple tile on navy, `primary`, `dark`, `light`), `position` the corner, `size` `md` or `lg`. Extra
offset goes in `class` (`class="bottom-24"`). With `href`, `navigate` or `patch` it renders a link.

### Retracting

`retract` says when the pill shows its label. On a device without hover (touch) every mode but `never` is
the bubble, and a tap runs the action directly.

`hover` (default) is the bubble at rest; it expands on pointer hover and keyboard focus:

    <.fab id="ask" label="Ask the assistant" phx-click="open_assistant" />

`auto` starts expanded, retracts after `retract_after` ms (4000 by default) or as soon as the page scrolls,
and expands again on hover or focus:

    <.fab id="help" label="Need a hand?" retract="auto" retract_after={6000} navigate={~p"/help"} />

`never` is always expanded:

    <.fab id="new" label="New invoice" retract="never" color="primary" patch={~p"/invoices/new"}>
      <:icon><.icon name="hero-plus" class="size-5" /></:icon>
    </.fab>

`always` is always the bubble; the label is only the `aria-label` and the native tooltip:

    <.fab id="chat" label="Chat with us" retract="always" color="light" position="bottom-left" badge={3} />

`expanded` lets the server force the pill open whatever `retract` says, for a hint or an onboarding step:

    <.fab id="ask" label="Ask the assistant" expanded={@show_hint} phx-click="open_assistant" />

A button with several actions is a speed-dial, `fab_dial/1`.

### The canvas look

`variant="canvas"` (the default; `variant="pill"` is the old retracting pill) is the design canvas's FAB: the solid ink button (kit CSS `btn btn-neutral btn-lg`) with 18px corners,
the icon and the label always shown (`retract`, `color`, `size` and `badge` do not apply). `offset` moves
it from the corner, in pixels, in either variant:

    <.fab id="new" label="New order" variant="canvas" offset={18} phx-click="new_order">
      <:icon><.icon name="huge-add-01" class="size-4" /></:icon>
    </.fab>

On `fab_dial/1`, `variant="canvas"` (the default; `pill` is the old one) is the 56px solid square (a `btn btn-neutral btn-square`) and its actions are a
kit CSS surface of ghost `btn` rows (icon and label).

The button sits under modals and drawers and above the page (`--ledger-z-fab`, 90 by default; an app raises it in
its own CSS like the other `--ledger-z-*` layers).

### `<.fab>`

Renders the floating button, or a link when `href`, `navigate` or `patch` is given.

The server action is the usual `phx-click` (it comes through the global attributes):

    <.fab id="ask" label="Ask the assistant" phx-click="open_assistant" />
    <.fab id="ask" label="Ask the assistant" retract="auto" position="bottom-left" size="lg" navigate={~p"/assistant"} />

`data-state` (`expanded` or `collapsed`) tells which shape it has; with `retract="auto"` the `LedgerUI.Fab`
hook owns it, so a server patch does not undo a retraction.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `label` (required) | `:string` |  | Always rendered, and the `aria-label`. |
| `position` | `:string` | `"bottom-right"` | `bottom-right`, `bottom-left`, `top-right`, `top-left` — The viewport corner; add offset with `class`, e.g. `class="bottom-24"`. |
| `color` | `:string` | `"assistant"` | `assistant`, `primary`, `dark`, `light` — `assistant` is the indigo to purple icon tile on navy; `primary` the theme color; `dark` navy with a quiet tile; `light` a white pill. |
| `size` | `:string` | `"md"` | `md`, `lg` |
| `variant` | `:string` | `"canvas"` | `canvas`, `pill` — `canvas` (the default) is the canvas's solid ink button with the label always shown; `pill` is the old Ledger UI retracting navy pill. |
| `offset` | `:integer` | `nil` | The distance from the corner, in pixels (24 by default). |
| `retract` | `:string` | `"hover"` | `hover`, `auto`, `never`, `always` — `hover`: the bubble at rest, expanded on hover or keyboard focus. `auto`: expanded at first, retracts after `retract_after` or on scroll, expands on hover or focus. `never`: always expanded. `always`: always the bubble. Touch devices show the bubble in every mode but `never`. |
| `retract_after` | `:integer` | `4000` | Milliseconds before `retract="auto"` retracts. |
| `expanded` | `:boolean` | `false` | `true` forces the pill open, whatever `retract` says. |
| `badge` | `:any` | `nil` | A count or short text in a dot on the bubble's corner; `nil` shows none. |
| `type` | `:string` | `"button"` |  |
| `disabled` | `:boolean` | `false` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `href`, `navigate`, `patch`, `method`, `download`, `target`, `rel`, `form`, `name`, `value`.

Slots:

- `<:icon>` — The glyph in the tile; the sparkle of the assistant by default.
- `<:inner_block>` — Replaces the visible label text (`label` stays the `aria-label`).

### `<.fab_dial>`

A speed-dial: a round button that opens a column of mini actions, each with its label beside it. The button
turns its plus into a cross while it is open.

    <.fab_dial id="quick" label="Quick actions">
      <:action label="New contact" phx-click="new_contact"><.icon name="hero-user-plus" class="size-4.5" /></:action>
      <:action label="Upload a file" phx-click={JS.push("upload")}><.icon name="hero-arrow-up-tray" class="size-4.5" /></:action>
      <:action label="New proposal" navigate={~p"/proposals/new"}><.icon name="hero-document-plus" class="size-4.5" /></:action>
    </.fab_dial>

Each `:action` takes `label` (the visible text and the item's name), the icon as its content, and one of
`phx-click` (an event name or a `%JS{}`, with `phx-target`), `href`, `navigate` or `patch` (a link);
`disabled` turns it off. The first action is the one nearest the button.

It opens and closes by click. Escape closes it and gives the focus back to the button; with the dial open the
up and down arrows walk the actions (from the button, down is the first and up the last, both wrap; Home and
End go to the ends), a click on an action, a click outside or the focus leaving close it, and the arrows on the
closed button open it. The button has `aria-expanded`, `aria-haspopup="menu"` and `aria-controls`; the actions
are the `menuitem`s of a `menu` named after `label`. `open` sets the initial state only (the `LedgerUI.FabDial`
hook owns `data-state`, so a server patch does not undo the person's choice). The motion is off under
`prefers-reduced-motion`.

`color`, `size` and `position` are the ones of `fab/1`; `class` adds offset (`class="bottom-24"`).

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `label` (required) | `:string` |  | The button's `aria-label` and the name of the menu. |
| `position` | `:string` | `"bottom-right"` | `bottom-right`, `bottom-left`, `top-right`, `top-left` — The viewport corner; the actions open away from it. |
| `color` | `:string` | `"primary"` | `assistant`, `primary`, `dark`, `light` |
| `size` | `:string` | `"md"` | `md`, `lg` |
| `variant` | `:string` | `"canvas"` | `canvas`, `pill` — `canvas` (the default) is the canvas's 56px solid square with the actions on a kit CSS surface of ghost buttons; `pill` is the old round button with labelled mini actions. |
| `offset` | `:integer` | `nil` | The distance from the corner, in pixels (24 by default). |
| `open` | `:boolean` | `false` | The initial state; after mount the hook owns it. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:action>` (required) — attrs: `label`, `href`, `navigate`, `patch`, `phx-click`, `phx-target`, `disabled`, `class` — A mini action: the icon is its content.
- `<:icon>` — The glyph of the button, a plus by default; it turns 45 degrees (a cross) while open.
