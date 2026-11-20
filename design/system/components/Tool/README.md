# Tool

Representa uma ferramenta ou integração que a IA pode usar, com status e escopo.

**Grupo:** 15 · IA  
**Resumo visual:** state running · waiting · done · error · denied

## Uso (Phoenix / HEEx)

```heex
<.tool name="Stripe" status={:connected} scopes={~w(read:subscriptions)} />
```

## Regras

- Escopos em mono; status com badge + switch para habilitar.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: tool)

Todos os function components, atributos, valores e slots que este componente cobre.

A tool call an agent makes (running a command, reading a file), from input to output, as a line of a
`trace/1`: a plain line while it runs, a step that opens on its output once it has one, red when it fails.
A call that waits for the user is a `tool_approval/1` card with Deny and Approve. It is the canvas's `Tool`,
in the spirit of the shadcn/ui AI Elements Tool, built on `trace/1` and `code_block/1`.

    <.trace>
      <.tool id="t1" state="running" subject="pnpm install" />
      <.tool id="t2" state="done" subject="node --version" output="v24.18.0" />
      <.tool id="t3" state="error" subject="pnpm lint" output={@stderr} />
    </.trace>

### States

`state` is where the call stands; it picks the status of the line and the verb before `subject`:

| `state`   | line                | title (en / pt_BR)             |
|-----------|---------------------|--------------------------------|
| `running` | `running` (shimmer) | Running … / Rodando …          |
| `waiting` | `pending` (faded)   | Waiting to run … / Aguardando … |
| `done`    | plain               | Ran … / Rodou …                |
| `error`   | `error` (red)       | Failed to run … / Falhou ao rodar … |
| `denied`  | plain               | Denied … / Negado …            |

`verbs` overrides them per state (`verbs={%{done: "Read", running: "Reading"}}` for a file tool) and `title`
replaces the whole title. `subject` is drawn as code. Map an AI SDK part with its state: `input-streaming`
and `input-available` are `running` while the chat streams (`error` once it stopped, or `waiting` for a tool
that runs on the client), `output-available` is `done`, `output-error` is `error` and `output-denied` is
`denied`.

### Output

With `output` (or `input`, shown above it) the line opens on a small `code_block/1` that wraps and caps at
256px; `open` starts it open. `description` sits after the title (a duration, say).

### Approval

    <.tool_approval id="a1" subject="rm -rf tmp" input={@args} on_approve="approve" on_deny="deny" value={@call_id} />

The card asks "Run `rm -rf tmp`?" (`title` replaces it), shows the input, and its buttons send `on_approve`
and `on_deny` with `%{"value" => value}`.

### `<.tool>`

One tool call, as a line of a `trace/1`.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  | Names the output block. |
| `state` | `:string` | `"done"` | `running`, `waiting`, `done`, `error`, `denied` |
| `subject` | `:string` | `nil` | What the tool acted on (a command, a file), drawn as code. |
| `title` | `:string` | `nil` | The whole title, in place of verb and subject. |
| `verbs` | `:map` | `%{}` | Verbs per state (atom keys), over the `locale` ones. |
| `locale` | `:string` | `"en"` | `en`, `pt_BR` |
| `icon` | `:string` | `"huge-command-line"` |  |
| `description` | `:any` | `nil` |  |
| `input` | `:string` | `nil` | The call's input, shown above the output. |
| `output` | `:string` | `nil` | What the tool returned, or its error text. |
| `open` | `:boolean` | `false` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.tool_approval>`

A tool call that waits for the user: the question, the input and Deny / Approve.

Events: `on_approve` and `on_deny` receive `%{"value" => value}`.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `subject` | `:string` | `nil` | What would run, drawn as code in the question. |
| `title` | `:string` | `nil` | The question, in place of "Run `subject`?". |
| `description` | `:string` | `nil` | A line under the question. |
| `input` | `:string` | `nil` | The call's input, in a small code block. |
| `icon` | `:string` | `"huge-command-line"` |  |
| `value` | `:any` | `nil` | Sent with both events. |
| `on_approve` | `:any` | `nil` | An event name or a `%JS{}`. |
| `on_deny` | `:any` | `nil` | An event name or a `%JS{}`. |
| `target` | `:any` | `nil` |  |
| `approve_label` | `:string` | `nil` |  |
| `deny_label` | `:string` | `nil` |  |
| `locale` | `:string` | `"en"` | `en`, `pt_BR` |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.
