# Stepper

Indicador de etapas de um fluxo (wizard).

**Grupo:** 11 · Navegação  
**Resumo visual:** color (8) · size xs–lg · horizontal/vertical · estados done/current/error/todo · variant canvas

## Uso (Phoenix / HEEx)

```heex
<.stepper steps={~w(Conta Plano Pagamento Revisão)} current={2} />
```

## Regras

- Concluído: teal com check; atual: borda `ink` com halo; futuro: neutro.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: steps)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's steps: numbered or plain points joined by a line, horizontal or vertical.

    <.steps>
      <:step label="Cart">1</:step>
      <:step label="Shipping">2</:step>
      <:step label="Payment">3</:step>
    </.steps>

    <.steps color="primary" orientation="vertical" line_space>
      <:step label="Ordered">1</:step>
      <:step label="Shipped">2</:step>
    </.steps>

    <.steps size="xs" line_space>
      <:step label="Done" color="primary" />
      <:step label="Now" color="secondary" ping />
      <:step label="Next" />
    </.steps>

`color` paints every point and the line between them; a step's own `color` paints only its
point. The content of a step is what its point shows (a number, an icon or nothing). A step's
`state` (`done`, `current`, `error`, `todo`) picks its color and marks the current one.

`stepper/1` is the progress version for wizards and checklists: states drawn as a bar and a
numbered, checked or flagged dot, with a sub line and room for an action.

    <.stepper current={1}>
      <:step label="Company" sub="Tax id and address" />
      <:step label="Certificate" sub="File and password" />
      <:step label="Tax profile" sub="Regime and operations" />
    </.stepper>

    <.stepper orientation="vertical" current={3}>
      <:step label="Company data" sub="Signetum Ltda" />
      <:step label="Register products" sub="12 registered">
        <.button size="sm" color="primary">Import sheet</.button>
      </:step>
    </.stepper>

`variant="canvas"` (the default; `variant="classic"` is the old Ledger UI stepper) is the design canvas look on kit CSS `steps` (`step-primary` for done and current, `step-error`, the marker in a `step-icon`): horizontal, numbered circles joined by
1px lines (done in the accent tint with a check, the current one solid); vertical, 26px round
tiles (done green, current in the accent tint) joined by a line, each able to show an `icon`.

    <.stepper variant="canvas" current={3}>
      <:step label="Customer" />
      <:step label="Items" />
      <:step label="Payment" />
    </.stepper>

    <.stepper variant="canvas" orientation="vertical" current={1}>
      <:step label="Company" sub="Done" />
      <:step label="Certificate" sub="In progress" icon="huge-file-02" />
    </.stepper>

### `<.steps>`

Renders kit CSS's steps (`steps`, `step`, `step-primary`…, `steps-vertical`). Each `:step` is a point
(showing the slot's content in a `step-icon`, else its number) with an optional `label` under it, or beside it
when vertical.

    <.steps color="primary">
      <:step label="Cart">1</:step>
      <:step label="Shipping" current>2</:step>
      <:step label="Payment">3</:step>
    </.steps>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `color` | `:string` | `"neutral"` | `neutral`, `primary`, `secondary`, `accent`, `info`, `success`, `warning`, `error` — Paints every point and the line between them. |
| `orientation` | `:string` | `"horizontal"` | `horizontal`, `vertical` |
| `size` | `:string` | `"md"` | `xs`, `sm`, `md`, `lg` — `xs` and `sm` are bare dots with small labels. |
| `line_space` | `:boolean` | `false` | Kept for compatibility: kit CSS's steps draw the line under the points. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:step>` (required) — attrs: `label`, `color`, `ping`, `current`, `state`, `class` — One step; its content is what the point shows.

### `<.stepper>`

Renders a stepper: the steps of a wizard or a checklist, each `done`, `current`, `error` or `todo`.

Give `current` (the index of the step being worked on, from 0) and the others follow: the ones before are done,
the ones after are to do, and with `error` the current one is flagged. A `:step` can also carry its own `state`.
The current step (and a flagged one) has `aria-current="step"`; every step has its state as hidden text for
screen readers.

    <.stepper current={@step} error={@failed}>
      <:step label="Company" sub="Tax id and address" />
      <:step label="Certificate" sub="File and password" />
    </.stepper>

`horizontal` draws a bar over each step; `vertical` joins the dots with a line, and a step's content (a button, a
link) sits at its right end.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `orientation` | `:string` | `"horizontal"` | `horizontal`, `vertical` |
| `current` | `:integer` | `nil` | The index of the current step, from 0. The steps before it are `done`, the ones after `todo`. |
| `error` | `:boolean` | `false` | Flags the current step as `error`. |
| `variant` | `:string` | `"canvas"` | `canvas`, `classic` — `canvas` (the default): the design canvas steps (small numbered circles and 1px lines; vertical, round tiles joined by a line). |
| `state_names` | `:map` | `%{"current" => "Current", "done" => "Completed", "error" => "Needs attention", "todo" => "Upcoming"}` | The hidden text read for each state, by `done`, `current`, `error` and `todo`; translate it with this. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:step>` (required) — attrs: `label`, `sub`, `state`, `marker`, `icon`, `class` — One step; its content is shown after its text.
