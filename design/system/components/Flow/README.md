# Flow

Editor visual de fluxo com nós e conectores para automações e aprovações.

**Grupo:** 09 · Fluxo de trabalho  
**Resumo visual:** Nós ligados por conectores (automação, aprovação)

## Uso (Phoenix / HEEx)

```heex
<.flow nodes={@nodes} edges={@edges} />
```

## Regras

- Nó selecionado com borda teal e anel de foco.
- Conectores em `line-strong` com pontas arredondadas.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: flow)

Todos os function components, atributos, valores e slots que este componente cobre.

A workflow editor: steps (a trigger, an agent, an action, a human approval) on a dotted board, joined by
connections that carry the condition of each branch, with a bar of actions at the bottom and the
configuration panel of a step on the right. It is the canvas's `Flow`.

    <.flow id="triage" edges={@edges} on_add="add_node" aria-label="Exception triage">
      <:node id="in" kind="Trigger" kind_icon="huge-flash" icon="huge-mail-01" title="Invoice received"
             metrics={[%{label: "runs", value: "1,284/wk", href: ~p"/runs/in"}]}>
        <.flow_section label="Event">An invoice arrives at the inbox or by the ERP webhook.</.flow_section>
      </:node>
      <:node id="match" kind="Agent" kind_icon="huge-sparkles" icon="huge-sparkles" title="Check and match">
        <.flow_section label="Tools">
          <.flow_chips><.flow_chip>erp.lookup</.flow_chip><.flow_chip>ocr.extract</.flow_chip></.flow_chips>
        </.flow_section>
      </:node>
      <:node id="post" kind="Action" kind_icon="huge-sent" icon="huge-file-01" title="Post to finance" />
      <:node id="gate" kind="Approval" kind_icon="huge-user" icon="huge-security-check" title="Approval" selected />

      <:actions :let={id}>
        <.button icon size="sm" aria-label="Delete" phx-click="delete" phx-value-id={id}>
          <.icon name="huge-delete-02" />
        </.button>
      </:actions>

      <:toolbar>
        <.button color="primary" variant="solid"><.icon name="huge-add-01" /> Add node</.button>
        <.button><.icon name="huge-shield-01" /> Guardrails</.button>
      </:toolbar>

      <:panel label="Approval">
        <.flow_panel_head icon="huge-security-check" title="Approval" on_close="close_panel" />
        <.flow_panel_tabs><.tabs ...>...</.tabs></.flow_panel_tabs>
        <.flow_panel_body>...fields...</.flow_panel_body>
        <.flow_panel_foot>
          <span>Edited 4 min ago</span><span class="sp"></span>
          <.button>Discard</.button> <.button color="primary" variant="solid">Save node</.button>
        </.flow_panel_foot>
      </:panel>
    </.flow>

### Layout

The server lays the steps out (no JavaScript, no measuring): `edges` is a list of maps with `from` and `to`
(node ids) and, optionally, `label` and `status`. A node's row is its depth along the edges; a parent is
centred over its children, the children stand side by side and every connection is an SVG path drawn in
the gap above its target, with the `label` on it. A gap with a branch or a label is taller than a plain one.
Edges are expected to join one row to the next; an edge that skips rows is drawn in the gap above its
target, from the column of its source. A flow with no `edges` is a free grid: the nodes in the order given, four to a row.

`status: "done"` paints a traversed edge green and `"error"` red; an edge into the `selected` node takes the
accent colour. An edge with no status is the neutral line, which is how the branch not taken of a run reads.

### Nodes

A `:node` has a `kind` tab (text in `kind`, glyph in `kind_icon`) joined to a card with the `title`, the
`icon`, the sections (`flow_section/1`, the content of the slot) and a footer of `metrics`. `status` is
`running`, `done`, `waiting`, `error` or `skipped` and the tab gets its dot; `selected` takes the accent
colour and renders the `:actions` slot beside the card (with the node id as the slot argument). With
`on_add` set, the nodes with no outgoing edge get the + button under them; it pushes `on_add` (an event
name or a `%JS{}`) with `phx-value-id` of the node.

The `:hint` slot is a floating note on the board (`<:hint title="Comece pelo gatilho">Depois use o +…</:hint>`):
the title in bold above the text, placed at `left`/`top` (372 and 92 px of the stage, to the right of a
first node) and `width` (240).

The `:toolbar` slot is the bar at the bottom of the board. The `:panel` slot is the aside on the right,
composed with `flow_panel_head/1`, `flow_panel_tabs/1`, `flow_panel_body/1` and `flow_panel_foot/1` and the
rest of the kit (`tabs`, `input`, `select`, `button`...); without it the board takes the whole width.
Give the board a height (`class="h-[640px]"`) and an `aria-label`.

### `<.flow>`

Renders the board: the nodes, the connections, the toolbar and the panel.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `edges` | `:list` | `[]` | Connections: maps with `from` and `to` (node ids) and optionally `label` and `status` (`done` or `error`). |
| `on_add` | `:any` | `nil` | An event name or a `%JS{}`; draws the + button under the nodes with no outgoing edge and pushes with `phx-value-id`. |
| `add_label` | `:string` | `"Add step after"` | The accessible name of the + button. |
| `node_width` | `:integer` | `300` | The width of a node card in px. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:actions>` — Buttons shown beside the selected node; the node id is the slot argument (`:let={id}`).
- `<:hint>` — attrs: `title`, `left`, `top`, `width`, `class` — A floating note on the board, for an empty or new flow: a title in bold, then the text. Free-positioned in the stage.
- `<:node>` (required) — attrs: `id`, `title`, `icon`, `kind`, `kind_icon`, `status`, `selected`, `class`, `metrics` — A step; its content is the sections of the card.
- `<:panel>` — attrs: `label` — The aside on the right, for the selected node.
- `<:toolbar>` — The bar at the bottom of the board, centred.

### `<.flow_section>`

A tinted section of a node's card, with a label in mono capitals.

    <.flow_section label="Instructions">Extract the items and match them to the order.</.flow_section>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `label` (required) | `:string` |  |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.flow_chips>`

The row of chips of a section (the tools of an agent).

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.flow_chip>`

A chip of `flow_chips/1`, in mono type.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.flow_panel_head>`

The head of the panel: the icon in its box, the title and, with `on_close`, a close button.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `title` (required) | `:string` |  |  |
| `icon` | `:string` | `nil` | The icon of the box (`huge-security-check`). |
| `on_close` | `:any` | `nil` | An event name or a `%JS{}`; draws the close button. |
| `close_label` | `:string` | `"Close"` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.flow_panel_tabs>`

The strip under the head that holds the `tabs` of the panel.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.flow_panel_body>`

The scrolling body of the panel, where the fields go.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.flow_panel_foot>`

The foot of the panel: a note on the left and the buttons on the right.

A `<span class="sp"></span>` between them pushes the buttons to the end.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
