# StepGroup

Checklist de passos com progresso, para onboarding e configuração.

**Grupo:** 06 · Exibição  
**Resumo visual:** status ok · running · waiting · failed · skipped · canceled · tone dim/err/ok

## Uso (Phoenix / HEEx)

```heex
<.step_group steps={@steps} />
```

## Regras

- Passo concluído: check em teal e texto em `muted` riscado leve; atual em destaque.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: step_group)

Todos os function components, atributos, valores e slots que este componente cobre.

A framed card for processes in steps (a build, a deploy, issuing an invoice, an import).

The header sits on the frame with the overall status, the title, the duration and a button that
collapses the card; inside, a raised panel lists the steps, each with a status, a result in mono
type and a chevron that opens its log.

    <.step_group id="deploy" title="Deploy logs" status={:running} duration="1m 04s">
      <:step title="Preparing environment" status={:ok} result="12s" />
      <:step title="Updating the stack" status={:running} result="Running…" open>
        <.step_group_line n={1} at="09:41:02" tone="dim">Connecting</.step_group_line>
        <.step_group_line n={2} at="09:41:04" tone="err">Rejected</.step_group_line>
      </:step>
      <:step title="Routing traffic" status={:waiting} result="Waiting" />
    </.step_group>

`status` is one of `:ok`, `:running`, `:waiting`, `:failed`, `:skipped` and `:canceled`.

The content of a `:step` is its log (`step_group_line/1` lines). A step with a log is a
`<button>` that opens and closes the log; a step without one is a plain row, with no chevron.
A `canceled` step has no status icon, as in the canvas.

Collapsing the card and opening a log happen in the browser (`Phoenix.LiveView.JS`), with no
round trip. The browser owns that state: `collapsed` and `open` set where it starts, and a
patch does not undo what the user toggled.

### `<.step_group>`

Renders the card: the header, and the steps in the panel under it.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `title` (required) | `:string` |  |  |
| `status` | `:atom` | `:waiting` | `ok`, `running`, `waiting`, `failed`, `skipped`, `canceled` — The overall status. |
| `duration` | `:string` | `nil` | Shown at the end of the header, e.g. `1m 04s`. |
| `collapsed` | `:boolean` | `false` | Starts with the panel hidden. The user's toggling wins afterwards. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:step>` — attrs: `title`, `status`, `result`, `open`, `id`, `class` — One step; its content is its log.

### `<.step_group_line>`

A line of a step's log: its number, the time and the text.

    <.step_group_line n={3} at="09:41:04" tone="err">cStat 539: duplicate invoice</.step_group_line>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `n` (required) | `:integer` |  | The line number. |
| `at` | `:string` | `nil` | The time of the line, e.g. `09:41:02`. |
| `tone` | `:string` | `nil` | ``, `dim`, `err`, `ok` — `dim` for a quiet line, `err` for an error, `ok` for a success. |

Slots:

- `<:inner_block>` (required)
