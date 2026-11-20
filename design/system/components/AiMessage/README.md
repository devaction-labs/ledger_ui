# AiMessage

Par de mensagens usuário/IA com ações de copiar, avaliar e regenerar.

**Grupo:** 15 · IA  
**Resumo visual:** Mensagem da IA com bloco de ação e reações; mensagem do usuário

## Uso (Phoenix / HEEx)

```heex
<.ai_message role={:assistant}>…</.ai_message>
```

## Regras

- Estado “pensando”: três pontos animados no lugar do corpo.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: ai)

Todos os function components, atributos, valores e slots que este componente cobre.

The assistant ("Assistente (IA)"): the conversation, its messages, the proposals the user approves, the
queries the assistant shows it made, the field to ask, the list of conversations and the starting suggestions.
The assistant proposes and the user approves; nothing changes without a confirmation.

    <.ai_chat id="assistente" messages={@messages} user={@current_user}
      on_send="send" on_approve="approve" on_reject="reject" />

Or piece by piece:

    <.ai_message role="user" name="Marina Costa">Quais pedidos têm linha sem produto?</.ai_message>

    <.ai_message>
      <:trace><.ai_tool_trace tools={@tools} duration_ms={3000} /></:trace>
      <p>Encontrei <b class="ink">1 pedido</b>.</p>
      <.ai_proposal id="p1" title="Sugestão: trocar o produto da linha" on_approve="approve" on_reject="reject">
        <:change label="Pedido">#2491 · Mercadinho Bom Preço</:change>
        <:change label="Linha 3" from="Cimento CP2 50" to="40011 · Cimento CP-II 50kg" />
      </.ai_proposal>
    </.ai_message>

    <.ai_composer field={@form[:pergunta]} context={[:pedidos]} phx-submit="send" />

    <.conversation_list conversations={@conversas} active={@conversa.id} on_select="open" />

    <.prompt_suggestions items={@sugestoes} on_pick="ask" />

A message of `ai_chat` is a map: `:id`, `:role` (`:user` or `:assistant`), `:text` (paragraphs separated by a
blank line, `**bold**` is bold), `:name` (of the user, for the avatar), `:trace` (`%{tools: [...],
duration_ms: 3000, running: false}`), `:proposal` (`%{id:, title:, status:, changes: [%{label:, from:, to:,
text:}], note:, editable:}`), `:streaming` and `:status`.

### `<.ai_tool_trace>`

What the assistant consulted: one chip per query, how many and how long. `running` shows the spinner and
"em andamento"; a tool with `failed: true` is marked in red; `expanded` lists each query with its filters.

    <.ai_tool_trace tools={[%{icon: "huge-invoice-01", label: "Pedidos", detail: "situação ≠ faturado · 14 linhas"}]} duration_ms={3000} />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `tools` | `:list` | `[]` | Maps `%{icon, label, title, detail, failed}`: the Hugeicons name, the name of the source (`title` is its name in the expanded list), what was asked and `failed: true` for a query that did not work. |
| `running` | `:boolean` | `false` | The queries are still going on. |
| `expanded` | `:boolean` | `false` | Lists each query with its filters under the chips. |
| `duration_ms` | `:integer` | `nil` | The total time, shown in seconds. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.ai_message>`

A message of the conversation. The user's is the dark bubble on the right with the avatar; the assistant's is
a card with the spark, the queries it made (`trace` slot) and the content. `variant="plain"` drops the card:
loose text beside the spark.

    <.ai_message role="user" name="Marina Costa">Quanto tenho para receber até sexta?</.ai_message>
    <.ai_message streaming><p>Os pedidos vencidos somam <b class="ink">R$ 12.300</b></p></.ai_message>
    <.ai_message variant="plain"><p>Os pedidos vencidos somam <b class="ink">R$ 12.300</b></p></.ai_message>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `role` | `:string` | `"assistant"` | `user`, `assistant` |
| `variant` | `:string` | `"card"` | `card`, `plain` — `card` frames the assistant's content (560px, border, padding); `plain` is loose text beside the spark. Not used by `user`. |
| `streaming` | `:boolean` | `false` | Shows the cursor after the last paragraph. |
| `status` | `:string` | `"ok"` | `ok`, `error` — `error` marks the message (`data-status`); the failed query itself is drawn by `ai_tool_trace`. |
| `name` | `:string` | `nil` | The user's name: the avatar of a `user` message shows its initials. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
- `<:trace>` — The queries the assistant made, above the content.

### `<.ai_proposal>`

An action the assistant proposes, which only happens when the user approves. `change` rows show the old
value struck through and the new one in green; a row with content and no `from`/`to` is a plain fact.

    <.ai_proposal id="p1" title="Sugestão: trocar o produto da linha" status={:pending}
      on_approve="approve" on_reject="reject">
      <:change label="Pedido">#2491 · Mercadinho Bom Preço</:change>
      <:change label="Linha 3" from="Cimento CP2 50" to="40011 · Cimento CP-II 50kg" />
    </.ai_proposal>

    <.ai_proposal id="p2" title="Atualizar o pedido" layout="definition" pending_label="Pendente"
      pending_note="Cada ação aprovada entra no rastreamento do pedido" on_approve="approve" on_reject="reject">
      <:change label="Status" from="Aberto" to="Faturado" />
    </.ai_proposal>

The events carry the proposal's `id` (`%{"id" => "p1"}`).

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `title` (required) | `:string` |  | What will be done. |
| `status` | `:any` | `"pending"` | `pending` (Aprovar and Recusar), `applying`, `approved`, `rejected` or `failed`, as an atom or a string. |
| `pending_label` | `:string` | `"Aguardando você"` | The text of the badge while the proposal is `pending`. |
| `pending_note` | `:string` | `nil` | A line in the footer of a `pending` proposal, beside the buttons. None unless given. |
| `layout` | `:string` | `"list"` | `list`, `definition` — How `change` rows with `from` and `to` read: `list` (old struck through, an arrow, the new in green) or `definition` (old struck through and a badge with the new value). |
| `editable` | `:boolean` | `false` | Shows Editar. |
| `note` | `:string` | `nil` | The line under the rows once decided. |
| `on_approve` | `:any` | `nil` | An event name or a `JS` command. |
| `on_reject` | `:any` | `nil` | An event name or a `JS` command. |
| `on_undo` | `:any` | `nil` | Shows Desfazer on an approved proposal. |
| `on_edit` | `:any` | `nil` | The event of Editar. |
| `target` | `:any` | `nil` | The `phx-target` of the events. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:action>` — A button in the line of a failed proposal.
- `<:change>` — attrs: `label`, `from`, `to` — A row: `label`, and `from` and `to` for a value that changes.
- `<:impact>` — attrs: `label` — The effect in numbers; `label` defaults to Impacto.
- `<:preview>` — attrs: `label` — A preview of the message or document; `label` defaults to Mensagem.

### `<.ai_composer>`

The field to ask the assistant: the context chips, the text, the attachment and send (which becomes Stop while
the assistant answers). It is a form: `phx-submit` and `phx-change` go on it.

    <.ai_composer field={@form[:pergunta]} context={[:pedidos]} phx-submit="send" phx-change="draft" />

Enter sends, Shift+Enter breaks the line.

`variant="canvas"` is the board's layout: the clip on the left, the text, the chips after it, the microphone
(`mic`) and a black send button with its label.

    <.ai_composer variant="canvas" mic context={[:pedidos]} send_label="Enviar" phx-submit="send" />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` | `nil` |  |
| `variant` | `:string` | `"default"` | `default`, `canvas` — `default` has the chips first, the clip on the right and a round send; `canvas` has the clip first, the chips after the text, the microphone and a black send with its label. |
| `send_label` | `:string` | `"Enviar"` | The text of the send button of the `canvas` variant (also its accessible name). |
| `mic` | `:boolean` | `false` | Shows the microphone button in the `canvas` variant. |
| `on_mic` | `:any` | `nil` | The event (or `JS`) of the microphone. |
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` | A form field; gives the name and value. |
| `name` | `:string` | `nil` | The name of the text without a `field`: `message`. |
| `value` | `:string` | `nil` |  |
| `context` | `:list` | `[]` | Where the assistant looks: `:pedidos`, `:catalogo`, `:clientes`, `:financeiro`, `:fiscal`, `:banco`, a string or `%{label, icon}`. One shows as "Contexto: Pedidos". |
| `attachments` | `:list` | `[]` | Files shown above the field: `%{name, size}` (`size` in bytes or text). |
| `upload` | `:any` | `nil` | A LiveView upload: the clip opens its file picker and its entries are the attachments. |
| `streaming` | `:boolean` | `false` | Swaps send for Parar. |
| `on_stop` | `:any` | `nil` | The event (or `JS`) of Parar. |
| `target` | `:any` | `nil` | The `phx-target` of `on_stop`. |
| `placeholder` | `:string` | `"Pergunte sobre pedidos, estoque, fiscal ou financeiro"` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `phx-submit`, `phx-change`, `phx-target`, `autocomplete`.

Slots:

- `<:chip>` — A custom chip, after the context ones (a slot cannot share the name of the `context` attr).

### `<.prompt_suggestions>`

The starting suggestions: cards (slightly tilted), pills or a grey 2x2 grid (`grid`, the title in mono capitals). Choosing one sends `on_pick` with the text as
`value` (and the `title`), for the app to fill the composer or ask.

    <.prompt_suggestions items={[%{title: "Resumo do dia", text: "Faça um resumo do dia."}]} on_pick="ask" />
    <.prompt_suggestions variant="pill" items={@next} on_pick="ask" />
    <.prompt_suggestions variant="grid" items={@next} on_pick="ask" />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `items` (required) | `:list` |  | Maps `%{title, text}`; a pill shows the `text`. |
| `tilt` | `:boolean` | `true` | Tilts the cards (decorative; turn it off in dense screens). |
| `variant` | `:string` | `"card"` | `card`, `pill`, `grid` |
| `on_pick` | `:any` | `nil` | An event name (payload `%{value, title}`) or a `JS` command. |
| `target` | `:any` | `nil` | The `phx-target` of `on_pick`. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.ai_greeting>`

The greeting of the assistant: the first line (the whole line) in a living gradient, whose colors drift
across the text (6s, back and forth; 12s under `prefers-reduced-motion`), and the question under it.
`tone="warm"` swaps the brand colors for pink, rose and orange.

    <.ai_greeting name="Marina" />
    <.ai_greeting name="Alex" tone="warm" greeting="Boa tarde, Alex" tagline="Vamos resolver o quê?" size="md" />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `name` | `:string` | `nil` | Who is greeted; `Bom dia` / `Boa tarde` / `Boa noite` by the hour. |
| `greeting` | `:string` | `nil` | Replaces the whole first line. |
| `tagline` | `:string` | `"Em que posso ajudar hoje?"` |  |
| `size` | `:string` | `"lg"` | `sm`, `md`, `lg` — 30px, 36px or 40px. |
| `tone` | `:string` | `"brand"` | `brand`, `warm` — `brand` (accent, blue, violet, pink) or `warm` (pink, rose, orange, fuchsia). |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.conversation_list>`

The conversations of the assistant, by day, with a button for a new one and a search. The open one is a
card; a teal dot marks a conversation with an action waiting. Each item is a link (`navigate`, `patch` or
`href`) or, with `on_select`, a button-like link that sends the id.

    <.conversation_list conversations={@conversas} active={@conversa.id} on_new="new" on_search="search" />

A conversation is a map: `:id`, `:title`, `:status` (the line under the title), `:day` (the group, as
"Hoje"), `:pending` (an action waits), `:content` (searched with the title) and the link.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `conversations` (required) | `:list` |  |  |
| `active` | `:any` | `nil` | The `id` of the open conversation. |
| `search` | `:string` | `""` | The text of the search: filters by title and content. |
| `group_by` | `:atom` | `:day` | `day` |
| `variant` | `:string` | `"card"` | `card`, `rail` — `rail` is a full-height column with a divider. |
| `title` | `:string` | `"Assistente"` |  |
| `shortcut` | `:string` | `"⌘ J"` | Shown on the new conversation button. |
| `on_new` | `:any` | `nil` | The event (or `JS`) of Nova conversa. |
| `on_search` | `:any` | `nil` | The `phx-change` event of the search field. |
| `on_select` | `:any` | `nil` | The event (or `JS`) of an item without a link; payload `%{id}`. |
| `target` | `:any` | `nil` | The `phx-target` of the events. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:item>` — attrs: `conversation` — The content of an item, in place of the title and status.

### `<.ai_chat>`

The whole conversation: greeting and suggestions before the first message, the messages with their proposals,
and the field to ask. Messages are a list or a stream (see the module doc for the map).

    <.ai_chat id="assistente" messages={@messages} user={@current_user} on_send="send"
      on_approve="approve" on_reject="reject" on_pick="ask">
      <:header>
        <b class="ink">Linha sem produto no #2491</b>
        <span class="faint">iniciada em Pedidos, hoje 14:20</span>
      </:header>
      <:suggestion title="Resumo do dia">Faça um resumo do dia.</:suggestion>
    </.ai_chat>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `messages` | `:any` | `[]` | A list of message maps or a stream of them. |
| `user` | `:any` | `nil` | The current user (a name or a map with `:name`): greeting and avatar. |
| `streaming` | `:boolean` | `false` | The answer is coming: the composer shows Parar. |
| `context` | `:list` | `[]` | The initial context chips of the composer, as `ai_composer`. |
| `variant` | `:string` | `"card"` | `card`, `bare`, `page` — `card` is framed with the header; `bare` is the content only; `page` fills a screen. |
| `draft` | `:string` | `nil` | The text in the composer. |
| `greeting` | `:string` | `nil` | Replaces the greeting line. |
| `footnote` | `:string` | `nil` | A small line under the composer (a notice about approvals, for instance). None unless given. |
| `composer` | `:boolean` | `true` | `false` leaves the composer out: a conversation shown as a record (an approved proposal). |
| `placeholder` | `:string` | `"Pergunte sobre pedidos, estoque, fiscal ou financeiro"` |  |
| `on_send` | `:any` | `nil` | The `phx-submit` event of the composer. |
| `on_change` | `:any` | `nil` | The `phx-change` event of the composer. |
| `on_stop` | `:any` | `nil` |  |
| `on_approve` | `:any` | `nil` |  |
| `on_reject` | `:any` | `nil` |  |
| `on_undo` | `:any` | `nil` |  |
| `on_pick` | `:any` | `nil` | The event of a suggestion; payload `%{value, title}`. |
| `target` | `:any` | `nil` | The `phx-target` of the events. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:empty>` — Shown above the messages in place of the greeting and suggestions.
- `<:header>` — The title and subtitle of the conversation, in the header of the `card`.
- `<:suggestion>` — attrs: `title`, `prompt` — A starting card; the content is its text.
