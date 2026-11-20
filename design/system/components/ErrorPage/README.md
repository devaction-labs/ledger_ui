# ErrorPage

Página de erro com código vazado, explicação e saída.

**Grupo:** 10 · Feedback  
**Resumo visual:** tone neutral/error/warning/accent · 404/500/offline/403

## Uso (Phoenix / HEEx)

```heex
<.error_page code={404} />
```

## Regras

- Código grande vazado (`-webkit-text-stroke`), sem ilustrações.
- Sempre um caminho de volta (Início) e um de ajuda.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: error_page)

Todos os function components, atributos, valores e slots que este componente cobre.

The canvas's error screens: the whole page an `ErrorHTML` renders (404, 500, 403, 401/419, 429, 503 and offline)
and the error inside the app, under the shell.

    <.error_page code={404} request_id={@request_id}>
      <:brand><img src={~p"/images/logo.svg"} class="size-8.5" /> <b>Acme</b></:brand>
      <:status href="https://status.acme.com">All systems operational</:status>
      <:actions>
        <.button navigate={~p"/"} color="primary" size="lg">Back home</.button>
      </:actions>
      <.error_links title="Maybe you were looking for">
        <:link navigate={~p"/orders"} icon="huge-invoice-01" description="Every order">Orders</:link>
      </.error_links>
      <:card>Orders with a similar number…</:card>
      <:footer><a href="/help">Help center</a></:footer>
    </.error_page>

    <.error_state code={404} title="Order #2499 not found">
      It may have been deleted or belong to another branch.
      <:actions><.button navigate={~p"/orders"} color="primary">See every order</.button></:actions>
    </.error_state>

`code` is the HTTP status (an integer or text, `"OFF"` for offline). It picks the color of the big code
(`tone`: `neutral` for 404, `error` for 5xx, `warning` for 403, 429 and offline, `accent` for 401, 419 and 503)
and the English defaults of `label` (`error_page`), `title` and `description` (and of the `error_state` icon), all of which
you pass translated.

### The page

On the left, the code and its label, the title, the description, the `actions` and the inner block (the
canvas puts `error_links/1` or an `alert` there). On the right, the dotted panel with rings, the code in
230px mono fading down and the `card` slot floating over it (a search with similar records, the log line of
a 500, the permissions of a 403...). On top, the `brand` and the `status` link (a dot in the color of
`status`: `ok`, `warning` or `down`); at the bottom the `request_id` with a copy button, the `timestamp`
and the `footer` (help links). Under 1100px the panel goes below the text; on a phone it is hidden.

It is a whole page: render it as the `ErrorHTML` template, with the root layout that loads the CSS
(`render_errors: [formats: [html: MyAppWeb.ErrorHTML], root_layout: {MyAppWeb.Layouts, :root}]`).
The styles are `canvas-error-page.css` (`lu-err`).

### `<.error_page>`

Renders the whole error page.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `code` (required) | `:any` |  | The HTTP status (`404`) or a short text (`"OFF"`). |
| `tone` | `:string` | `nil` | ``, `neutral`, `error`, `warning`, `accent` — The color of the code; by `code` when `nil`. |
| `label` | `:string` | `nil` | The words after the code chip (`Page not found`). |
| `title` | `:string` | `nil` |  |
| `description` | `:string` | `nil` |  |
| `request_id` | `:string` | `nil` | Shown in the footer with a copy button. |
| `request_id_label` | `:string` | `"Request ID"` |  |
| `copy_label` | `:string` | `"Copy request ID"` |  |
| `copy` | `:boolean` | `true` | A copy button by the request id. It copies with an inline `onclick` (`navigator.clipboard`) and sets `data-copied` for two seconds, so it works on a plain `ErrorHTML` page with no LiveView or hook; a CSP that forbids inline handlers needs `unsafe-inline` for it, and the click on the id still selects it whole. |
| `back_label` | `:string` | `nil` | Adds a "previous page" button (`history.back()`, no LiveView needed) after the `actions`, with this text. |
| `timestamp` | `:string` | `nil` | When it happened, as text, after the request id. |
| `id` | `:string` | `"error-page"` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:actions>` — The buttons under the description.
- `<:brand>` — The logo and the name, top left.
- `<:card>` — The card floating over the big code.
- `<:footer>` — The links at the right end of the footer.
- `<:inner_block>` — Under the actions: `error_links/1`, an alert, a note.
- `<:status>` — attrs: `href`, `status` — The link to the status page, top right.

### `<.error_state>`

Renders the error inside the app: the code (150px) with the icon tile on it, the title, the description,
the actions and the inner block under them (a table of recent records, an alert), centered.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `code` (required) | `:any` |  |  |
| `tone` | `:string` | `nil` | ``, `neutral`, `error`, `warning`, `accent` |
| `icon` | `:string` | `nil` | A `huge-*` icon for the tile; by `code` when `nil`. |
| `title` | `:string` | `nil` |  |
| `description` | `:string` | `nil` |  |
| `id` | `:string` | `nil` | Derives the id of the title (`"#{id}-title"`); `err-<code>-title` when `nil`. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:actions>`
- `<:inner_block>` — The description, instead of `description`.
- `<:more>` — Under the actions, full width.

### `<.error_links>`

The list of links under the actions of an error page: a faint title and rows with an icon tile, a label,
a line of description and a chevron.

    <.error_links title="Who can grant it">
      <:link href="mailto:alex@acme.com" icon="huge-user" description="Account admin">Alex Nogueira</:link>
    </.error_links>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `title` | `:string` | `nil` |  |
| `class` | `:any` | `nil` |  |

Slots:

- `<:link>` (required) — attrs: `href`, `navigate`, `icon`, `description`
