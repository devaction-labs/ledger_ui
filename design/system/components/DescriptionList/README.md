# DescriptionList

Lista de pares rótulo e valor para detalhes de uma entidade.

**Grupo:** 06 · Exibição  
**Resumo visual:** cols 1–4 · layout stacked/inline

## Uso (Phoenix / HEEx)

```heex
<.list><:item title="Plano">Pro</:item>…</.list>
```

## Regras

- Rótulo em `muted` 13px; valor em `ink`; números tabulares.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: description_list)

Todos os function components, atributos, valores e slots que este componente cobre.

Label and value pairs in a grid, as the canvas `lu-dl`: the label small and faint, the value in
the ink color. For the short data of a detail (an order, a client).

    <.description_list cols={2}>
      <:item label="Razão social">Mercadinho Bom Preço Ltda</:item>
      <:item label="CNPJ" mono>12.345.678/0001-90</:item>
    </.description_list>

`cols` is 1 to 4. `layout="inline"` puts the label at the left and the value at the right, one
pair per line, for a narrow drawer. An item with no content shows "—" (`empty`).

An item takes `id`, `class` and `style` for its `<dd>` (a test hook, a long e-mail that must
wrap), and `wrapper_id` and `wrapper_class` for the `<div>` around the pair:

    <.description_list cols={1}>
      <:item label="E-mail" id="mail" style="overflow-wrap:anywhere">ana@example.com</:item>
    </.description_list>

### `<.description_list>`

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `cols` | `:integer` | `2` | `1`, `2`, `3`, `4` |
| `layout` | `:string` | `"stacked"` | `stacked`, `inline` — `stacked` puts the value under the label; `inline` the label left and the value right. |
| `empty` | `:string` | `"—"` | Shown for an item with no content. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:item>` (required) — attrs: `label`, `mono`, `id`, `class`, `style`, `wrapper_id`, `wrapper_class` — A pair: `label`, and the value as content.
