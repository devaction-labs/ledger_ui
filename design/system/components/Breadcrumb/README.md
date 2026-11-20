# Breadcrumb

Trilha de localização no topo da página.

**Grupo:** 11 · Navegação  
**Resumo visual:** variant canvas · plain · bordered · truncamento do meio

## Uso (Phoenix / HEEx)

```heex
<.breadcrumb><:item navigate={~p"/"}>Orbit Cloud</:item><:item>Overview</:item></.breadcrumb>
```

## Regras

- Separador “/” em `line-strong`; item atual em 500 `ink`.
- Truncar o meio com “…” acima de 4 níveis.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: breadcrumb)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's breadcrumb: the links to the pages above the current one, then the current page.

    <.breadcrumb>
      <:item navigate={~p"/"}>Home</:item>
      <:item navigate={~p"/elements"}>Elements</:item>
      <:item>Breadcrumb</:item>
    </.breadcrumb>

An item with `href`, `navigate` or `patch` is a link; one with `phx-click` is a button that
looks like a link, so a crumb can navigate through a server event; the others are plain text
(the current page is the last one). Any other attribute of the item (`phx-target`,
`phx-value-*`, `id`, `data-*`, `aria-*`) is passed on to the link or button.

    <.breadcrumb>
      <:item :for={folder <- @path} phx-click="open_folder" phx-value-id={folder.id}>
        {folder.name}
      </:item>
    </.breadcrumb>

`href`, `navigate` and `patch` that are `nil` or `false` count as absent, so a step built with
`<:item :for={step <- @steps} navigate={step.to}>` is plain text when it has no destination.

The current page is in the soft text color and a long label is cut with an ellipsis; give the
item a `title` for the full label.

A long trail collapses with `max_items`: it keeps the first step and the last ones, and the steps
in between become a single "…" button that opens them in a dropdown (links and `phx-click`
steps keep working there). `max_items` counts the "…" as a step, so `max_items={4}` shows the
first step, "…" and the last two. Give the breadcrumb an `id`: the dropdown's is `"<id>-more"`.

    <.breadcrumb id="path" max_items={4}>
      <:item navigate={~p"/finance"}>Finance</:item>
      <:item navigate={~p"/finance/reconciliation"}>Reconciliation</:item>
      <:item navigate={~p"/finance/reconciliation/statements"}>Statements</:item>
      <:item>October</:item>
    </.breadcrumb>

It is kit CSS's `breadcrumbs`, whose own separator goes between the steps unless a `:separator` is given:

    <.breadcrumb variant="bordered">
      <:separator><span class="text-xs font-light">/</span></:separator>
      <:item href="/"><svg>…</svg></:item>
      <:item>Calendar</:item>
    </.breadcrumb>

`variant="canvas"` (the default; `variant="plain"` is the old Ledger UI trail) is the design canvas trail: muted
13px links, faint `/` separators and the current page in the ink, inside a `<b>` with `aria-current="page"` on
its wrapper.

    <.breadcrumb>
      <:item navigate={~p"/customers"}>Customers</:item>
      <:item>Casa das Tintas</:item>
    </.breadcrumb>

### `<.breadcrumb>`

Renders a breadcrumb trail; the last `:item` is the current page.

    <.breadcrumb>
      <:item navigate={~p"/"}>Home</:item>
      <:item>Settings</:item>
    </.breadcrumb>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `variant` | `:string` | `"canvas"` | `canvas`, `plain`, `bordered` — `canvas` (the default) is the design canvas pill trail with `/` separators; `plain` is the old Ledger UI trail. `bordered` draws a rounded border around each link; `canvas` is the design canvas pill trail with `/` separators. |
| `label` | `:string` | `"Breadcrumb"` | The `aria-label` of the navigation. |
| `max_items` | `:integer` | `nil` | With more steps than this, the middle ones collapse into a "…" dropdown, keeping the first step and the last `max_items - 2` (the "…" counts as a step; below 3 it is 3). |
| `more_label` | `:string` | `"Show hidden steps"` | The accessible name of the "…" button. |
| `id` | `:string` | `nil` | The id of the `<nav>`; it prefixes the id of the "…" dropdown (`breadcrumb-more` without one), so set it when a page has several. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:item>` (required) — attrs: `href`, `navigate`, `patch`, `class`, `phx-click`, `phx-target`, `phx-value-id`, `id`, `title` — A step of the trail.
- `<:separator>` — What goes between two steps, kit CSS's (or `/` in the canvas variant) by default.
