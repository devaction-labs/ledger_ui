# LandingNav

Barra de navegação do site (landing), com menu de produtos em cartões.

**Grupo:** 13 · Estrutura e shell  
**Resumo visual:** variant default · float · clear · mobile · tone default/tint/dark · menu de produtos (mega) · open_on hover/click

## Uso (Phoenix / HEEx)

```heex
<.landing_nav variant="float">
  <:menu label="Produto" variant="cards">…</:menu>
  <:cta navigate={~p"/cadastro"}>Começar grátis</:cta>
</.landing_nav>
```

## Regras

- `float` descola do topo com sombra; `clear` fica transparente sobre o herói.
- No celular vira o botão de menu.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: landing_nav)

Todos os function components, atributos, valores e slots que este componente cobre.

The marketing-site top bar of the canvas "Navbar" board (the "Landing" examples): the logo on the left, the links
in the center (one may open a mega menu), Entrar and the primary button on the right.

    <.landing_nav id="site-nav" brand={%{name: "Linea", logo: "L", navigate: ~p"/"}}>
      <:link label="Produto">
        <.landing_mega>
          <.landing_feature icon="huge-kanban" title="Projetos" description="Kanban, prazos e responsáveis" navigate={~p"/projetos"} />
          <.landing_feature icon="huge-shield-01" title="Segurança" description="2FA, sessões e auditoria" navigate={~p"/seguranca"} />
          <:side>
            <.landing_mega_side eyebrow="Novidade" title="Projetos com kanban" thumb link_label="Ver novidades" navigate={~p"/novidades"}>
              Arraste tarefas entre colunas.
            </.landing_mega_side>
          </:side>
        </.landing_mega>
      </:link>
      <:link label="Preços" navigate={~p"/precos"} active />
      <:link label="Docs" href="https://docs.example.com" />
      <:actions>
        <.landing_login navigate={~p"/entrar"}>Entrar</.landing_login>
        <.landing_cta navigate={~p"/cadastro"} icon="huge-arrow-right-01">Começar grátis</.landing_cta>
      </:actions>
    </.landing_nav>

### Variants

  * `default` - the classic bar, in the page flow.
  * `float` - a detached, centered pill of frosted glass (wrapped in `.lu-lp-floatwrap`).
  * `clear` - transparent over a hero image (white text); with `sticky` it turns solid, with border and shadow,
    once the page scrolls. Put the bar over the hero yourself (a negative margin on the hero, say).
  * `mobile` - the phone layout at any width: logo, Entrar and the menu button.

`sticky` pins the bar to the top of the page (`position: sticky`) and mounts the `LedgerUI.LandingNav` hook (register
the kit's hooks), which sets `data-stuck` on the bar after `stuck_after` px of scroll (default 8); the CSS makes
the bar solid while it is set. The server never resets that attribute.

### Links and the mega menu

A `:link` with `href`, `navigate` or `patch` is a link (`active` marks the current page with `aria-current`). A
`:link` with inner content is a trigger instead: a button with `aria-expanded` and `aria-controls` that opens the
content as the mega menu under the bar, built with `Phoenix.LiveView.JS` (no round trip). A click outside the
bar, or Escape, closes it. Fill it with `landing_mega/1`, `landing_feature/1` and `landing_mega_side/1`.

With `open_on="hover"` (the default) it opens like laravel.com's: a mouse resting on the trigger opens the
panel, the panel stays open while the pointer goes down into it, so its cards and links can be reached, and it
closes once the pointer has left both (switching to another trigger swaps panels at once). A click or a tap
opens it too; outside, Escape or leaving closes it. `open_on="click"` keeps it to clicks (a second click closes).
In both, ArrowDown on a trigger opens the panel and focuses its first item, the arrows walk the items, Escape
gives the focus back to the trigger and tabbing out of the bar closes it. Hover and keys come from the
`LedgerUI.LandingNav` hook, mounted when there is a trigger or `sticky` (register the kit's hooks).

### Phone

Below 768px (or with `variant="mobile"`) the links and the primary button leave the bar and a menu button
(a kit CSS `btn`) appears; it opens a panel under the bar listing every `:link` as a row (a trigger row goes to its
`href`, `"#"` when it has none) and the `:actions` again, stacked and full width. So `:actions` is rendered twice:
do not put an `id` on what is inside it. The mega menu is not shown on a phone.

### Announcement

`landing_announcement/1` is the thin strip to put above the bar. The slot of the actions is `:actions`
(not `:end`, which is a reserved word).

The brand is the `brand` map or, for something else, the `:logo` slot.

Styles: `canvas-landing-nav.css` (`lu-lp-*`).

### `<.landing_nav>`

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  | The root id; the menu toggles and the hook use it. |
| `variant` | `:string` | `"default"` | `default`, `float`, `clear`, `mobile` |
| `open_on` | `:string` | `"hover"` | `hover`, `click` — How a mega menu opens: on hover (and click), like laravel.com, or on click only. |
| `sticky` | `:boolean` | `false` | Pin to the top and mount the scroll hook (`data-stuck`). |
| `stuck_after` | `:integer` | `8` | The scroll in px after which the bar is stuck. |
| `brand` | `:map` | `nil` | `%{name:, logo:, src:, href:, navigate:}`: `logo` is a letter in the box, `src` an image. |
| `label` | `:string` | `"Main"` | The accessible name of the links. |
| `menu_label` | `:string` | `"Menu"` | The accessible name of the phone menu button. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:actions>` — Entrar and the primary button (`landing_login/1`, `landing_cta/1`).
- `<:link>` — attrs: `label`, `href`, `navigate`, `patch`, `active` — A link; with inner content, a trigger of the mega menu.
- `<:logo>` — The brand, instead of the `brand` map.

### `<.landing_login>`

The "Entrar" link of the bar.

    <.landing_login navigate={~p"/entrar"}>Entrar</.landing_login>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `href` | `:string` | `"#"` |  |
| `navigate` | `:string` | `nil` |  |
| `patch` | `:string` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.landing_cta>`

The primary button of the bar. A link when it has `href`, `navigate` or `patch`, else a `button`.
`size="lg"` is the hero button, `block` makes it full width, `icon` a Hugeicons name after the text.

    <.landing_cta navigate={~p"/cadastro"} icon="huge-arrow-right-01">Começar grátis</.landing_cta>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `size` | `:string` | `"md"` | `md`, `lg` |
| `block` | `:boolean` | `false` |  |
| `icon` | `:string` | `nil` |  |
| `href` | `:string` | `nil` |  |
| `navigate` | `:string` | `nil` |  |
| `patch` | `:string` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `disabled`, `form`, `name`, `value`, `phx-click`.

Slots:

- `<:inner_block>` (required)

### `<.landing_mega>`

The mega menu content (inside a `:link` of `landing_nav/1`): the features in two columns and, optionally, a
highlighted panel on the side.

    <.landing_mega>
      <.landing_feature icon="huge-kanban" title="Projetos" description="Kanban" navigate={~p"/projetos"} />
      <:side><.landing_mega_side title="Novidade" /></:side>
    </.landing_mega>

`variant="cards"` lays out large product cards side by side instead (`landing_product/1`), one per product, as
the "Products" menu of laravel.com does; `columns` sets how many fit in a row (default: one per card, up to 3).

    <.landing_mega variant="cards">
      <.landing_product name="Linea Cloud" logo="huge-cloud" title="O jeito mais rápido de publicar" link_label="Publicar agora" navigate={~p"/cloud"} mock />
      <.landing_product name="Linea Forge" logo="huge-server-stack-01" title="Servidores sob controle" link_label="Gerenciar servidores" navigate={~p"/forge"} tone="tint" mock />
      <.landing_product name="Linea Watch" logo="huge-activity-01" title="Observe o app inteiro" link_label="Plano grátis" navigate={~p"/watch"} tone="dark" mock />
    </.landing_mega>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `variant` | `:string` | `"default"` | `default`, `cards` |
| `columns` | `:integer` | `nil` | Cards per row in the `cards` variant (default: the card count, up to 3). |

Slots:

- `<:inner_block>` (required) — The `landing_feature/1` items, or `landing_product/1` cards.
- `<:side>` — A `landing_mega_side/1` (the default variant).

### `<.landing_product>`

A product card of `landing_mega variant="cards"`: the product's logo and name, a large title, a link with an
arrow and a preview of the product that runs off the bottom of the card. The whole card is the link.

`tone` is `default` (a soft glow of the accent from a corner), `tint` (a wash of the accent under thin diagonal
lines) or `dark` (a near-black card, the same in light and dark pages); `accent` gives the card a color of its own
(each product its brand color, as laravel.com does). The preview is the `:preview` slot (an `<img>` of the product, say) or, with
`mock`, a drawn placeholder of an app screen. The logo is a Hugeicons name (`logo`) or the `:logo` slot.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `title` (required) | `:string` |  |  |
| `name` | `:string` | `nil` | The product name beside the logo. |
| `logo` | `:string` | `nil` | A Hugeicons name for the logo tile. |
| `link_label` | `:string` | `nil` |  |
| `tone` | `:string` | `"default"` | `default`, `tint`, `dark` |
| `accent` | `:string` | `nil` | The card's own accent (a CSS color): the link, the logo and the wash take it. |
| `mock` | `:boolean` | `false` | Draw a placeholder app screen when there is no `:preview`. |
| `href` | `:string` | `"#"` |  |
| `navigate` | `:string` | `nil` |  |
| `patch` | `:string` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:mark>` — The logo, instead of `logo` (an `<img>` or an `<svg>`).
- `<:preview>` — The picture of the product under the link.

### `<.landing_feature>`

One feature of the mega menu: an icon in a box, the title and a line of description.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `icon` | `:string` | `nil` | A Hugeicons name. |
| `title` (required) | `:string` |  |  |
| `description` | `:string` | `nil` |  |
| `href` | `:string` | `"#"` |  |
| `navigate` | `:string` | `nil` |  |
| `patch` | `:string` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.landing_mega_side>`

The highlighted panel beside the features: an eyebrow, the title, the text (inner content), an optional thumbnail
and a link.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `eyebrow` | `:string` | `nil` |  |
| `title` (required) | `:string` |  |  |
| `thumb` | `:boolean` | `false` | Draw the small placeholder picture. |
| `link_label` | `:string` | `nil` |  |
| `href` | `:string` | `"#"` |  |
| `navigate` | `:string` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>`

### `<.landing_announcement>`

The thin announcement strip above the bar: an eyebrow tag, the text (inner content), a link and a close button
that hides it (`JS.hide`, no round trip) when `dismissible`.

    <.landing_announcement id="ann" eyebrow="Novo" link_label="Ver novidades" navigate={~p"/novidades"}>
      Projetos com kanban chegaram ao Linea
    </.landing_announcement>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `eyebrow` | `:string` | `nil` |  |
| `link_label` | `:string` | `nil` |  |
| `href` | `:string` | `"#"` |  |
| `navigate` | `:string` | `nil` |  |
| `dismissible` | `:boolean` | `true` |  |
| `close_label` | `:string` | `"Close"` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
