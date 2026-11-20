# Trace

Visualização de spans de execução com duração relativa, para depuração de agentes e jobs.

**Grupo:** 15 · IA  
**Resumo visual:** Linha do tempo de execução (spans) com barras de duração

## Uso (Phoenix / HEEx)

```heex
<.trace spans={@spans} />
```

## Regras

- Barra em teal para sucesso, `neg` para erro; indentação por nível.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: trace)

Todos os function components, atributos, valores e slots que este componente cobre.

What an agent did, one line per step: an icon, a title that truncates, an optional description (a count, a
duration, a diff) and a status. A step can open to show its output, link somewhere, or group the steps under
it. It is the canvas's `Trace`, in the spirit of the shadcn/ui Trace.

    <.trace>
      <.trace_line icon="huge-ai-idea" title="Thought for 5s" />
      <.trace_line icon="huge-command-line" description="0.4s">Ran <code>pnpm --version</code></.trace_line>
      <.trace_step icon="huge-command-line" title="Ran node --version" open>
        <pre class="linea-trace-code">v24.18.0</pre>
      </.trace_step>
      <.trace_line icon="huge-command-line" status="error">Failed to run <code>pnpm install</code></.trace_line>
    </.trace>

### Lines

`trace_line/1` takes the title as `title` or as its block (so it can hold `<b>` and `<code>`). `status` is
`nil` (done), `"running"` (the title shimmers, still for readers who prefer reduced motion), `"error"` (red,
with an alert icon in place of `icon`) or `"pending"` (faded). With `href`, `navigate` or `patch` the line is a
link, and `end_icon` puts an icon after it (an arrow, say).

### Steps that open

`trace_step/1` is a native `<details>`: the line is its summary, with a chevron that turns when open, and the
block is what shows under it, behind a thin line. Put a `<pre class="linea-trace-code">` there for output, or
another `<.trace>` to group steps (sources, a chain of thought, the files of a commit). `open` starts it open.

### `<.trace>`

The list of steps.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.trace_line>`

One step: icon, title, description and status; a link with `href`, `navigate` or `patch`.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `icon` | `:string` | `nil` | A `huge-*` icon name. |
| `title` | `:string` | `nil` | The title; or pass it as the block. |
| `description` | `:any` | `nil` | Secondary text after the title: a count, a duration, a diff. |
| `status` | `:string` | `nil` | ``, `running`, `error`, `pending` |
| `end_icon` | `:string` | `nil` | An icon after the line, such as an arrow on a link. |
| `href` | `:string` | `nil` |  |
| `navigate` | `:string` | `nil` |  |
| `patch` | `:string` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `target`, `rel`.

Slots:

- `<:inner_block>`

### `<.trace_step>`

A step that opens: the line is the summary and the block shows under it.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `icon` | `:string` | `nil` |  |
| `title` | `:string` | `nil` |  |
| `description` | `:any` | `nil` |  |
| `status` | `:string` | `nil` | ``, `running`, `error`, `pending` |
| `open` | `:boolean` | `false` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
- `<:summary>` — The title with markup, in place of `title`.
