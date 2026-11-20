# ContextMenu

Menu aberto com o botão direito (ou Shift+F10) sobre uma linha, card ou área, na posição do ponteiro.

**Grupo:** 11 · Navegação  
**Resumo visual:** clique com o botão direito · na posição do ponteiro · atalhos · submenu · perigoso por último

## Uso (Phoenix / HEEx)

```heex
<.context_menu id="row-menu" target="#orders tr">
  <:item icon="huge-edit-02" shortcut="F2">Renomear</:item>
  <:item icon="huge-delete-02" danger>Excluir</:item>
</.context_menu>
```

## Regras

- Abre onde o ponteiro está; se não couber, vira para o outro lado.
- Mesmo conteúdo do ⋯ da linha: o menu de contexto é um atalho, nunca o único caminho.
- Esc fecha; setas navegam.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: context_menu)

Todos os function components, atributos, valores e slots que este componente cobre.

A menu that opens under the pointer on a right click.

    <.context_menu id="file-menu">
      <div class="rounded-lg border p-6">Right click here</div>
      <:item phx-click="rename">Rename</:item>
      <:item phx-click="copy">Copy</:item>
      <:item phx-click="delete" tone="danger" divider>Delete</:item>
    </.context_menu>

The hook `LedgerUI.ContextMenu` opens it at the pointer (kept inside the window), moves the focus to the first item and
closes it on a click outside, on `Escape`, on a scroll and when an item is chosen. The arrows and `Home` and `End` move
between the items.

### `<.context_menu>`

Renders the area and its menu.

    <.context_menu id="menu"><p>Area</p><:item>Open</:item></.context_menu>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `label` | `:string` | `"Actions"` | The accessible name of the menu. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required) — The area that answers to the right click.
- `<:item>` — attrs: `tone`, `divider`, `disabled`, `phx-click`, `phx-value-id`, `phx-target`
