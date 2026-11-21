# NotificationCenter

Central de notificações aberta pelo sino da barra superior.

**Grupo:** 12 · Sobreposições  
**Resumo visual:** variant canvas · classic · não lidas · vazio com 6 tons · chegada de nova

## Uso (Phoenix / HEEx)

```heex
<.notification_center notifications={@notifications} />
```

## Regras

- Não lida: ponto teal à esquerda e título em 600.
- Ação “Marcar todas como lidas” no topo.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: notification_center)

Todos os function components, atributos, valores e slots que este componente cobre.

A notification center: a bell with a dot when something is unread, and, under it, a panel with a
title and the count of unread, tabs, the notifications grouped by day, a footer and an empty state.

    <.notification_center
      id="notifications"
      items={@notifications}
      tabs={[
        %{id: "all", label: "Todas"},
        %{id: "unread", label: "Não lidas"},
        %{id: "orders", label: "Pedidos", empty: "Nenhum pedido novo"}
      ]}
      on_read_all="read_all"
      on_read="read"
      all_href={~p"/notifications"}
      preferences_href={~p"/settings/notifications"}
    />

Each item is a map:

    %{
      id: 41,
      title: "Pedido aguardando aprovação",
      body: "Pedido 2483, Clínica Vida Plena",
      at: "há 4 min",
      group: "Hoje",
      type: "warning",
      category: "orders",
      read: false,
      navigate: "/orders/2483"
    }

`title` is the only required key. `group` is the heading of the day (items with the same `group` in a
row share it, so keep the list in order); `type` is one of `info success warning error primary` and
gives the icon and the tone (`icon`, a Hugeicons name, replaces the icon); `category` is the `id` of a
tab and is shown after `at`; `navigate`, `patch` or `href` turn the item into a link.

The tabs are filtered in the browser, without a round trip: `all` shows everything, `unread` the items
that are not `read`, and any other id the items with that `category`. The number beside a tab is how
many unread items it holds. Without `tabs` the panel has no tab bar. `count_tone` (on the component or, with the same values, in a
tab's map) keeps those numbers neutral and gives the tone only to the one on the selected tab (`variant="classic"`); a tab's own
`count_tone` wins over the component's.

`variant="canvas"` (the default; `variant="classic"` is the old Ledger UI panel with title bar, tabs and footer) is the compact panel of the design canvas: no title bar, tabs or footer, only the
list grouped by day, each row with its icon tile, the title, the body and the time at the right, the
unread ones on the accent tint; its empty state is an icon tile (`empty_icon`, `empty_tone`) over
the text.

    <.notification_center id="notifications" variant="canvas" items={@notifications} on_read="read" />

The panel is a `LedgerUI.Components.Popover`: it closes on a click outside and on Esc, and opens from
the server with `LedgerUI.open(socket, "notifications")`. Marking as read is up to the server: change
`read` and the dot, the count and the bell follow.

### `<.notification_center>`

Renders the bell and its panel.

Events: `on_read_all` pushes `%{"id" => id}`; `on_read` pushes `%{"id" => id, "item" => item_id}`
when an item is clicked. Both take an event name (sent to `target` when given) or a `%JS{}`.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  | Needed by the popover and the tabs. |
| `items` | `:list` | `[]` | The notifications, newest first, see the module doc. |
| `tabs` | `:list` | `[%{id: "all", label: "Todas"}, %{id: "unread", label: "Não lidas"}]` | `%{id, label}` maps, with an optional `empty` (the text of the empty state of that tab). `all` and `unread` filter by read; any other id by `category`. `[]` hides the tab bar. |
| `unread` | `:integer` | `nil` | How many are unread. Defaults to the items that are not `read`; pass it when `items` is a page. |
| `title` | `:string` | `"Notificações"` |  |
| `bell_label` | `:string` | `"Notificações"` | The accessible name of the bell. |
| `size` | `:string` | `"md"` | `md`, `sm` — The bell: `md` is 36px, `sm` is the 32px button of the top bar (like `navbar_bell size="sm"`). |
| `count_tone` | `:string` | `nil` | `acc`, `pos`, `neg`, `warn`, `info`, `lime`, `primary`, `success`, `error`, `warning` — `classic`: the tone of the tab counters. The counters stay neutral and only the one on the selected tab takes the tone (it follows the tab with no JS). Without it every counter keeps the accent look. A tab can override it with its own `count_tone`. |
| `closable` | `:boolean` | `false` | `classic`: a close button at the end of the header; it closes the popover and returns focus to the bell. Ignored with `inline`. |
| `close_label` | `:string` | `"Fechar"` | The accessible name of the close button. |
| `read_all_label` | `:string` | `"Marcar todas como lidas"` |  |
| `preferences_label` | `:string` | `"Preferências de notificação"` |  |
| `all_label` | `:string` | `"Ver todas as notificações"` |  |
| `unread_label` | `:string` | `"não lidas"` | The word after the count in the footer. |
| `empty` | `:string` | `"Nenhuma notificação"` | The empty state of a tab without an `empty`. |
| `empty_text` | `:string` | `"Quando houver novidades, elas aparecem aqui."` |  |
| `variant` | `:string` | `"canvas"` | `canvas`, `classic` — `canvas` (the default): the compact canvas panel (no title bar, tabs or footer; the time at the right; unread rows tinted). |
| `empty_icon` | `:string` | `nil` | An icon for the empty state, in a tile, instead of the illustration. The `canvas` variant draws `huge-tick-02` when none is given. |
| `empty_tone` | `:string` | `"success"` | `neutral`, `primary`, `info`, `success`, `warning`, `error` — The tint of the `empty_icon` tile. |
| `all_href` | `:string` | `nil` | Where "see all" goes (a regular link). Without it the footer link is not drawn. |
| `preferences_href` | `:string` | `nil` | Where the preferences button goes. Without it the button is not drawn. |
| `on_read_all` | `:any` | `nil` | An event name or a `%JS{}` for "mark all as read". Without it the button is not drawn. |
| `on_read` | `:any` | `nil` | An event name or a `%JS{}`, run when an item is clicked. |
| `on_change` | `:any` | `nil` | An event name or a `%JS{}`, run when another tab is chosen. |
| `target` | `:any` | `nil` | The `phx-target` of the events. |
| `open` | `:boolean` | `false` |  |
| `placement` | `:string` | `"bottom-end"` |  |
| `arrow` | `:boolean` | `false` |  |
| `class` | `:any` | `nil` | Merged into the panel. |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:actions>` — `classic`: extra controls at the end of the header, after "mark all as read" and before the close button.
- `<:empty_action>` — A next step under the text of the empty state.
