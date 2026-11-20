# ConnectionBanner

Faixa que avisa quando a conexão com o servidor cai, tenta reconectar e volta.

**Grupo:** 10 · Feedback  
**Resumo visual:** offline · reconectando · reconectado · posição topo/base

## Uso (Phoenix / HEEx)

```heex
<.connection_banner />
```

## Regras

- Aparece só depois de 2 s sem conexão para não piscar em quedas curtas.
- Ao reconectar mostra verde por 2 s e some.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: connection_banner)

Todos os function components, atributos, valores e slots que este componente cobre.

The notice of a lost connection, as a toast: while the LiveView socket is down the toaster shows a
`loading` toast with the ring of light (`aura`), and it removes it when the socket is back.

    <.connection_banner />
    <.connection_banner title="Sem conexão" description="Tentando reconectar..." />

Put it once in the root layout, next to the `<.toaster>` (it needs one on the page). It draws nothing
by itself and has no JavaScript: `phx-disconnected` runs `show_toast/2` and `phx-connected` runs
`dismiss_toast/2`.

### `<.connection_banner>`

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` | `"linea-connection-banner"` |  |
| `title` | `:string` | `"Connection lost"` |  |
| `description` | `:string` | `"Trying to reconnect..."` |  |
| `color` | `:string` | `"warning"` | The light of the ring: `assistant primary secondary info success warning error`. |

Any other HTML/phx attribute goes to the root element.
