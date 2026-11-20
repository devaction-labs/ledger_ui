# MiniCard

Card pequeno de atalho ou entidade, clicável inteiro.

**Grupo:** 06 · Exibição  
**Resumo visual:** tone neutral/accent/success/warning/error/info

## Uso (Phoenix / HEEx)

```heex
<.mini_card icon="invoice-01" title="Board packs" meta="4 relatórios" navigate={~p"/reports"} />
```

## Regras

- Área clicável inteira; seta aparece no hover.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: mini_card)

Todos os function components, atributos, valores e slots que este componente cobre.

The canvas's mini card: a small card (14px padding) for a shortcut, an icon box over a bold label, or for a
short figure, a faint label over a mono value.

    <div class="grid grid-cols-3 gap-2.5">
      <.mini_card icon="huge-invoice-01" tone="accent" label="Novo pedido" navigate={~p"/pedidos/novo"} />
      <.mini_card icon="huge-file-01" label="Emitir NF-e" />
    </div>

    <.mini_card label="A receber" value="R$ 41,2 mil" />

With `href`, `navigate` or `patch` the card is a link.

### `<.mini_card>`

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `label` (required) | `:string` |  |  |
| `value` | `:string` | `nil` | A short figure: the label turns into a faint caption over it. |
| `icon` | `:string` | `nil` | A Hugeicons name, drawn in the canvas icon box. |
| `tone` | `:string` | `"neutral"` | `neutral`, `accent`, `success`, `warning`, `error`, `info` — The colour of the icon box. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `href`, `navigate`, `patch`, `method`.

Slots:

- `<:inner_block>` — Extra content under the label.
