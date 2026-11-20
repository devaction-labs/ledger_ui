# Illustration

Ilustrações leves feitas com as cores do tema para estados vazios e telas de resultado.

**Grupo:** 01 · Fundamentos  
**Resumo visual:** ilustrações de estado vazio, sucesso, erro e busca em traço da marca

## Uso (Phoenix / HEEx)

```heex
<.illustration name="empty-inbox" />
<.illustration name="success" />
```

## Regras

- Sempre acompanhada de título e frase; nunca sozinha.
- Usa só tokens, então muda com o tema.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: illustration)

Todos os function components, atributos, valores e slots que este componente cobre.

The Ledger UI illustrations, drawn inline so the package needs no static images.

    <.empty_box class="h-28" />

`empty_box` is the girl with a box that `notification_center` and `kanban_column` show when empty.
`summit` is the landscape of `hero_card` and the auth screen (mountain ridges, sun, trail); it
fills its box, cropping the sides, so give it a width and a height.

### `<.summit>`

Renders the canvas landscape (`svg.lu-summit`: sky, sun, stars, three ridges, a dotted trail), painted with the
`--hero-*` tokens and cropped to fill its box. Those tokens are defined by `.lu-hero`, `.lu-auth .art` and
`.lu-summit-host`: put the last on a parent when you use it elsewhere. `hero_card`'s `hero_summit/1` and
`auth_art/1` render this same component.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |
| `tone` | `:string` | `"teal"` | Modifier of `lu-summit` (the palette). |
| `id` | `:string` | `"hs"` | The prefix of the SVG's gradient ids (`hs-sky`...). Give each summit on a page its own when more than one may render, for example one hidden on mobile. |

### `<.scene>`

Renders one of the portrait scenes for the picture half of `auth_split` (or any tall picture), cropped to
fill its box:

  * `voyage` — a sailing ship on the sea, clouds and palm leaves;
  * `lighthouse` — a lighthouse on a cliff at dusk, its beam over the sea;
  * `balloons` — hot air balloons over green hills in the morning;
  * `aurora` — the northern lights over snowy mountains and a cabin with its window lit.

`position` is where the crop holds (`preserveAspectRatio`): `xMidYMid` (default), `xMidYMax` to keep the
bottom, `xMinYMid` to keep the left. `label` is read by screen readers; leave it empty when the picture is
only decoration.

    <.auth_split …><:art><.scene name="voyage" /></:art></.auth_split>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `name` (required) | `:string` |  | `voyage`, `lighthouse`, `balloons`, `aurora` |
| `position` | `:string` | `"xMidYMid"` |  |
| `label` | `:string` | `""` |  |
| `class` | `:any` | `"h-full w-full"` |  |

### `<.empty_box>`

Renders the girl with a box, for an empty area.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `"h-36"` | Sets the size; the width follows the height. |
