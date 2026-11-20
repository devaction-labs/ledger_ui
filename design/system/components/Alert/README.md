# Alert

Aviso inline persistente com cor, variante, forma, faixa de destaque, ação e botão de fechar.

**Grupo:** 10 · Feedback  
**Resumo visual:** color (8) × variant canvas/solid/outline/soft/bordered · shape pill · accent · ação · dismissible

## Uso (Phoenix / HEEx)

```heex
<.alert color="warning" variant="soft" title="Pagamento pendente">…<:action>…</:action></.alert>
<.alert color="error" variant="canvas" dismissible on_dismiss="hide">…</.alert>
```

## Regras

- `canvas` (padrão): painel branco com ícone na cor; `soft`/`bordered`: fundo tonal; `solid`: fundo cheio; `outline`: só contorno.
- `shape="pill"` para uma linha só; `accent` adiciona a faixa de cor (no topo, sem borda lateral).
- Título curto + uma frase + no máximo uma ação.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: alert)

Todos os function components, atributos, valores e slots que este componente cobre.

kit CSS's alert (`alert`, `alert-soft`, `alert-outline`, `alert-{color}`): filled, outlined, soft and
bordered, with an icon, an accent bar or a close button.

    <.alert>This is simple alert</.alert>
    <.alert color="primary" variant="soft" shape="pill">Saved</.alert>
    <.alert color="secondary" variant="soft" accent="left">With a bar</.alert>
    <.alert color="info" variant="outline">
      <:icon boxed><svg>…</svg></:icon>
      This is simple alert
    </.alert>
    <.alert id="notice" color="info" variant="outline" dismissible>Closable</.alert>

The `canvas` variant (the default) is a soft `alert` tinted by `color` (`primary`, `warning`, `error`, `info`,
`success`; `neutral` is kit CSS's plain one), the icon at the top left, the content growing beside it (write it
as `<b>` and `<p>`), the `:action` buttons in a row under the text and a ghost round close button
(`variant="solid"`, `outline`, `soft` and `bordered` give the other kit CSS styles):

    <.alert variant="canvas" color="warning">
      <:icon><.icon name="huge-alert-02" class="size-4" /></:icon>
      <b>Certificate expires in 12 days</b>
      <p>Renew it to keep issuing invoices.</p>
      <:action><.button color="mono" size="sm">Renew now</.button></:action>
    </.alert>

`dismiss_alert/1` fades out and hides the alert around the element that runs it, for close
buttons placed by hand:

    <.button phx-click={dismiss_alert()}>Remind me later</.button>

### `<.alert>`

Renders an alert.

With `accent` or a boxed `:icon` the alert is split into parts and its padding moves to the
content; otherwise the content sits in the padded alert itself, after an inline icon.

    <.alert id="saved" color="success" variant="soft" dismissible on_dismiss="hide_notice">
      <:icon><svg class="size-5">…</svg></:icon>
      Changes saved.
    </.alert>

With `on_dismiss="hide_notice"` the server gets `handle_event("hide_notice", %{"id" => "saved"}, socket)`.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` | `nil` |  |
| `color` | `:string` | `"neutral"` | `neutral`, `primary`, `secondary`, `info`, `success`, `warning`, `error`, `dark` |
| `variant` | `:string` | `"canvas"` | `canvas`, `solid`, `outline`, `soft`, `bordered` — `canvas` (the default) is the soft alert with the icon, body and actions laid out (see the module doc); `solid`, `outline`, `soft` and `bordered` are kit CSS's styles. |
| `shape` | `:string` | `"rounded"` | `rounded`, `pill` |
| `accent` | `:string` | `nil` | ``, `left`, `right` — A colored bar on one side of the alert. |
| `dismissible` | `:boolean` | `false` | Adds Ledger UI's close button, which fades the alert out. |
| `on_dismiss` | `:any` | `nil` | An event name or a `JS` command run when the close button is pressed. The event's payload is `%{"id" => id}`. |
| `target` | `:any` | `nil` | The `phx-target` of `on_dismiss`. |
| `close_label` | `:string` | `"Close"` | The `aria-label` of the close button. |
| `open` | `:boolean` | `true` | `false` renders the alert hidden; the close button hides it in the browser. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:action>` — Controls after the content, such as a menu or a button (under the text, in a row, in the `canvas` variant).
- `<:icon>` — attrs: `boxed` — An icon before the content.
- `<:inner_block>` (required)
