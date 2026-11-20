# Tabs

Abas para alternar seções de uma mesma página.

**Grupo:** 11 · Navegação  
**Resumo visual:** variant line · boxed · pill · text · segmented · nav × size xs/sm/md · color primary/neutral · vertical · transition left/up

## Uso (Phoenix / HEEx)

```heex
<.tabs id="account"><:tab id="overview" active>Visão geral</:tab>…</.tabs>
```

## Regras

- Abas trocam conteúdo da página; para filtrar dados use Segmented.
- Indicador de 2px em `ink`, não em teal.
- `transition` define como o painel entra: `left` (desliza da direita) ou `up` (sobe).

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: tabs)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's tabs: underlined (`line`), on a gray track (`boxed`), rounded (`pill`), plain text (`text`) and the design
canvas segmented control (`segmented`), laid out horizontally or vertically, with or without icons. A tab's `count`
draws the canvas count badge after its label.

    <.tabs id="profile-tabs" selected="home">
      <:tab name="home">Home</:tab>
      <:tab name="profile">Profile</:tab>
      <:panel name="home">…</:panel>
      <:panel name="profile">…</:panel>
    </.tabs>

    <.tabs id="boxed" variant="boxed">
      <:tab name="home"><svg class="size-4.5">…</svg><span>Home</span></:tab>
      <:panel name="home">…</:panel>
    </.tabs>

The selected tab comes from `selected` and switching happens in the browser (click, ←/→ or ↑/↓,
Home and End) without a round trip. A choice made in the browser survives patches; when the
server changes `selected`, the server wins.

`on_change` tells the server what was chosen:

    <.tabs id="server-tabs" selected={@tab} on_change="select_tab">…</.tabs>
    <.tabs id="period" variant="boxed" size="sm"><:tab name="month">Last month</:tab></.tabs>
    <.tabs id="range" variant="text"><:tab name="week">Last 7 days</:tab><:tab name="all">All time</:tab></.tabs>
    <.tabs id="view" variant="segmented"><:tab name="summary">Summary</:tab><:tab name="items">Items</:tab></.tabs>
    <.tabs id="status"><:tab name="all" count={128}>All</:tab><:tab name="late" count={4}>Late</:tab></.tabs>

    def handle_event("select_tab", %{"id" => "server-tabs", "value" => tab}, socket),
      do: {:noreply, assign(socket, tab: tab)}

Every selection also dispatches a bubbling `linea:change` DOM event with
`detail: %{id: id, value: name, tab: name}`.

### Navigation tabs

Tabs without `:panel`s switch routes instead of panels: give each `:tab` a `patch`,
`navigate` or `href` and it renders as a `<.link>`, so the browser goes there with no
`handle_event` round trip, and `selected` (the current route's tab) carries
`aria-current="page"`:

    <.tabs id="customer-tabs" variant="line" bordered selected={@live_action |> to_string()}>
      <:tab name="show" patch={~p"/customers/#{@customer}"}>Details</:tab>
      <:tab name="orders" patch={~p"/customers/#{@customer}/orders"}>Orders</:tab>
      <:tab name="history" navigate={~p"/customers/#{@customer}/history"}>History</:tab>
    </.tabs>

`variant="nav"` renders the canvas navigation tabs, a kit CSS `tabs tabs-border` of links (`<nav class="tabs tabs-border"><a class="tab tab-active">…</a></nav>`)
(14px links, a 2px underline on the current one). It is for routes only: no hook, no roles, no
panels, and `on_change` is never pushed. `selected` may be `nil` (none is current). A `:tab`
without `patch`, `navigate` or `href` (or with them `nil`/`false`) is never current: with
`phx-click` (and `phx-target`, `phx-value-*`) it is a clickable `<a role="button">`, with `soon`
or `disabled` it is a dimmed, non-clickable `<a aria-disabled="true">` titled with `soon_label`.

    <.tabs id="system-tabs" variant="nav" selected={@section}>
      <:tab name="overview" navigate={~p"/system"}>Overview</:tab>
      <:tab name="tasks" navigate={~p"/system/tasks"} count={12}>Tasks</:tab>
      <:tab name="finance" phx-click="soon">Finance</:tab>
      <:tab name="contracts" soon>Contracts</:tab>
    </.tabs>

A tab only points at a panel (`aria-controls`) when a `:panel` with its `name` exists, so
navigation tabs carry no dangling references. The arrow keys move the focus between link
tabs; Enter follows the focused one.

### `<.tabs>`

Renders a tab list and its panels. Each `:tab` is matched to the `:panel` with the same `name`.

    <.tabs id="settings" selected={@tab} variant="boxed" on_change="tab_changed">
      <:tab name="general">General</:tab>
      <:tab name="billing" disabled>Billing</:tab>
      <:panel name="general">…</:panel>
      <:panel name="billing">…</:panel>
    </.tabs>

Events: with `on_change="tab_changed"` the hook pushes `"tab_changed"` with
`%{"id" => "settings", "value" => "general", "tab" => "general"}` (to `target` or the closest LiveComponent)
after the browser switched; with `on_change={%JS{}}` the commands run on the tabs element.
Either way a bubbling `linea:change` DOM event carries `detail: %{id, value, tab}`; `tab` repeats `value`.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  | Needed by the hook and for the tab/panel ids. |
| `selected` | `:string` | `nil` | The `name` of the selected tab; the first one when not given. |
| `variant` | `:string` | `"line"` | `line`, `boxed`, `pill`, `text`, `segmented`, `nav` — `line` underlines the selected tab, `boxed` lifts it off a gray track, `pill` fills a rounded tab, `text` is plain text that only changes color (no border or background; spacing comes from `list_class`, `space-x-4` by default), `segmented` is the segmented control (kit CSS `tabs-box`: the selected tab raised on the track), `nav` is a `tabs-border` `nav` of links (see Navigation tabs). |
| `size` | `:string` | `"md"` | `xs`, `sm`, `md` — For `boxed`: `md` is `px-3 py-1.5`, `sm` is Ledger UI's compact `px-3 py-1 text-xs-plus`, `xs` is `px-2.5 py-0.5 text-xs`. |
| `color` | `:string` | `"primary"` | `primary`, `neutral` — The fill of the selected `pill` tab and the text color of the selected `text` tab. |
| `orientation` | `:string` | `"horizontal"` | `horizontal`, `vertical` |
| `bordered` | `:boolean` | `false` | For `line`: draws the gray rule the tabs sit on. |
| `overlap` | `:boolean` | `false` | For a `bordered` line: the selected tab's line covers the gray rule instead of sitting on it. |
| `grow` | `:boolean` | `false` | The tabs share the whole width of the list. |
| `transition` | `:string` | `"left"` | `left`, `up`, `none` — The way a panel comes in: sliding from the right (`left`) or from below (`up`). |
| `on_change` | `:any` | `nil` | Run when a tab is chosen in the browser. An event name is pushed with `%{"id" => id, "value" => name, "tab" => name}`; a `%JS{}` is executed on the tabs element.  |
| `soon_label` | `:string` | `"Em breve"` | For `nav`: the `title` of a `soon` tab that has none of its own. |
| `target` | `:any` | `nil` | The `phx-target` of `on_change`. |
| `list_class` | `:any` | `nil` | Extra classes for the tab list. |
| `panels_class` | `:any` | `nil` | Extra classes for the wrapper of the panels. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:panel>` — attrs: `name`, `class` — The content shown while the tab with the same `name` is selected.
- `<:tab>` (required) — attrs: `name`, `disabled`, `count`, `overdue`, `patch`, `navigate`, `href`, `replace`, `soon`, `phx-click`, `phx-target`, `phx-value-id`, `phx-value-name`, `title`, `id`, `class` — A tab button; its content is the label, icons included.
