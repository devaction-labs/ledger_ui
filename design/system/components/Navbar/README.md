# Navbar

Barra superior do app: breadcrumb à esquerda, atalhos de IA, notificações e tema à direita.

**Grupo:** 13 · Estrutura e shell  
**Resumo visual:** variant default · float · clear · dense · mobile · size md/sm · usuário avatar/ring/named · status ok/warn

## Uso (Phoenix / HEEx)

```heex
<.navbar breadcrumb={@crumbs}>
  <:actions><.ai_insights_button count={3} /></:actions>
</.navbar>
```

## Regras

- Altura 64px, borda inferior `line`.
- Botões quadrados 40×40 raio 12 (`lu-tbtn`).
- Variante com busca ⌘K centralizada para apps de operação.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: navbar)

Todos os function components, atributos, valores e slots que este componente cobre.

The app top bar of the canvas "Navbar" board: one container, `navbar/1`, and small pieces to put in it. The right
side is always the same vocabulary (search, notifications, theme, language and the user); the variants change what
goes on the left and the visual weight.

    <.navbar>
      <.navbar_crumbs items={[%{label: "Início", navigate: ~p"/"}, %{label: "Projetos", navigate: ~p"/projetos"}, %{label: "Site novo"}]} />
      <:end>
        <.navbar_search placeholder="Buscar ou ir para…" phx-click={JS.exec("data-show", to: "#palette")} />
        <.navbar_bell dot />
        <.theme_switch id="theme" variant="icons" size="sm" />
        <.navbar_lang locales={["PT", "EN"]} current="PT" />
        <.navbar_sep />
        <.navbar_user id="me" user={@user}>
          <:menu>
            <.navbar_menu_head user={@user}><:badge><.badge color="primary">Admin</.badge></:badge></.navbar_menu_head>
            <.navbar_menu_item icon="huge-user" navigate={~p"/perfil"}>Perfil</.navbar_menu_item>
            <hr />
            <.navbar_menu_item icon="huge-logout-01" danger href={~p"/sair"} method="delete">Sair</.navbar_menu_item>
          </:menu>
        </.navbar_user>
      </:end>
    </.navbar>

`variant` is `"default"` (60px, a line under it), `"float"` (a frosted pill detached from the top, for apps with no
side menu), `"clear"` (transparent, over a hero or a cover; the icon buttons get a glass background), `"dense"` (44px)
or `"mobile"` (56px: menu, title, bell and user). The slots are `inner_block` (the left side), `:center` (between the
two, such as `navbar_links/1` or a wide `navbar_search/1`), `:end` (the right side) and `:tabs`, which makes the bar two
rows: the content on top and the tabs (`navbar_tabs/1`) under it.

### Your own components in the bar

The pieces are optional: `:center` and `:end` take any markup, in the same `.lu-nb-end` wrapper, so an app can
put a `live_component` (the ⌘K palette, the notifications bell, the account menu) in place of `navbar_search/1`,
`navbar_bell/1` and `navbar_user/1` and the bar keeps the same markup around it:

    <.navbar>
      <.navbar_crumbs items={@crumbs} />
      <:center><.live_component module={MyAppWeb.PaletteTrigger} id="palette" /></:center>
      <:end>
        <.live_component module={MyAppWeb.BellLive} id="bell" user={@user} />
        <.live_component module={MyAppWeb.AccountMenu} id="me" user={@user} />
      </:end>
    </.navbar>

Inside the `:topbar` slot of `shell/1` it is the top of the page:

    <.shell nav={...} user={@user} footer="version">
      <:topbar><.navbar>...</.navbar></:topbar>
    </.shell>

### The pieces

  * `navbar_brand/1`, `navbar_workspace/1`, `navbar_chip/1`, `navbar_slash/1` and `navbar_crumbs/1` are the left side.
  * `navbar_links/1`, `navbar_tabs/1` and `navbar_title/1` are the middle (and the tabs row).
  * `navbar_search/1`, `navbar_bell/1`, `navbar_icon/1`, `navbar_lang/1`, `navbar_sep/1`, `navbar_env/1`, `navbar_sync/1`
    and `navbar_avatars/1` are the right side. The theme choice is `theme_switch/1` (`variant="icons" size="sm"`), a
    button is `button/1`.
  * `navbar_user/1` is the avatar and, with the `:menu` slot, the account menu; `navbar_menu_head/1`,
    `navbar_menu_status/1`, `navbar_menu_row/1` and `navbar_menu_item/1` are what goes in it.

Icons are Hugeicons: write each name in full (`huge-search-01`) so Tailwind sees it. The bar is a kit CSS
`navbar`; its pieces are kit CSS too (`menu-horizontal` links, `tabs-border` tabs, `breadcrumbs`, `btn`, `join`,
`indicator`, `badge`, `status`, `kbd`), painted by the theme. `canvas-navbar.css` (`lu-nb`) only lays them out.

### `<.navbar>`

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `variant` | `:string` | `"default"` | `default`, `float`, `clear`, `dense`, `mobile` |
| `id` | `:string` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:center>` — Between the left and the right: `navbar_links/1`, a wide `navbar_search/1`.
- `<:end>` — The right side (inside `.lu-nb-end`).
- `<:inner_block>` — The left side.
- `<:tabs>` — `navbar_tabs/1`: makes the bar two rows (`tall`).

### `<.navbar_brand>`

The logo and the name of the app.

    <.navbar_brand name="Linea" />
    <.navbar_brand name="Linea" logo="L" />
    <.navbar_brand name="Linea" src={~p"/images/logo.svg"} />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `name` | `:string` | `nil` |  |
| `logo` | `:string` | `nil` | The letter in the logo (default: the first of `name`). |
| `src` | `:string` | `nil` | A picture for the logo instead of the letter. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.navbar_crumbs>`

The path to the page. Each item is `%{label: "...", navigate: path}` (or `href` / `patch`); the last one, the page
itself, is bold, and an item with no link is plain text.

    <.navbar_crumbs items={[%{label: "Início", navigate: ~p"/"}, %{label: "Site novo"}]} />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `items` (required) | `:list` |  |  |
| `label` | `:string` | `"Breadcrumb"` | The `aria-label` of the `nav`. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.navbar_workspace>`

The workspace (company) switcher at the left of the bar: the logo, the name, a line under it and a chevron. It is a
button: `phx-click` opens your menu. It brings its own `.lu-nb-start` column, which keeps a wide search centered.

    <.navbar_workspace name="Loja Bom Fim" sub="Plano Pro" phx-click={...} />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `name` (required) | `:string` |  |  |
| `sub` | `:string` | `nil` |  |
| `logo` | `:string` | `nil` | The letter (default: the first of `name`). |
| `src` | `:string` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.navbar_chip>`

A selector in a path of selectors (organization, project): a colored square with a short text, the name, a tag and a
chevron. A button: `phx-click` opens the list.

    <.navbar_slash /><.navbar_chip label="Loja Bom Fim" square="LB" color="#1a7f4b" tag="Pro" phx-click={...} />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `label` (required) | `:string` |  |  |
| `square` | `:string` | `nil` | The text in the square (2 or 3 letters). |
| `color` | `:string` | `nil` | The CSS color of the square. |
| `tag` | `:string` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.navbar_slash>`

The `/` between two selectors.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.navbar_links>`

The main links, centered. Each item is `%{label: "...", navigate: path, active: boolean}` (`href` / `patch` work
too). The active one is the item with `active: true` or the one whose link equals `current`; it gets `on` and
`aria-current="page"`.

    <.navbar_links current={@current_path} items={[%{label: "Início", navigate: ~p"/"}, %{label: "Projetos", navigate: ~p"/projetos"}]} />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `items` (required) | `:list` |  |  |
| `current` | `:string` | `nil` | The current path: the item with this link is the active one. |
| `label` | `:string` | `nil` | An `aria-label` for the `nav`. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.navbar_tabs>`

The tabs of the page, in the second row of a `tabs` bar. The items are those of `navbar_links/1` plus an optional
`count`, a small mono number after the label.

    <:tabs><.navbar_tabs current={@current_path} items={[%{label: "Quadro", patch: ~p"/p/1"}, %{label: "Arquivos", patch: ~p"/p/1/files", count: 12}]} /></:tabs>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `items` (required) | `:list` |  |  |
| `current` | `:string` | `nil` |  |
| `label` | `:string` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.navbar_title>`

The centered title of the mobile bar.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.navbar_search>`

The search field of the bar. It is a trigger, not an input: a button that looks like one, whose `phx-click` opens the
command palette. `wide` is the bigger one for the center of the bar; `width` is a CSS width.

    <.navbar_search placeholder="Buscar ou ir para…" phx-click={...} />
    <:center><.navbar_search wide placeholder="Buscar pedidos, clientes…" phx-click={...} /></:center>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `placeholder` | `:string` | `"Search"` |  |
| `kbd` | `:string` | `"⌘K"` | The shortcut shown at the end; `nil` hides it. |
| `wide` | `:boolean` | `false` |  |
| `size` | `:string` | `"md"` | `md`, `sm` — `md` is 38px tall; `sm` is the compact field: 32px, 8px radius and `px-2.5`. |
| `width` | `:string` | `nil` | A CSS width (`"240px"`, `"100%"`). |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.navbar_bell>`

The notifications button; `dot` shows the orange dot of something unread. `phx-click` (or `navigate`/`href`) is yours.

    <.navbar_bell dot phx-click={...} />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `dot` | `:boolean` | `false` | There is something unread. |
| `label` | `:string` | `"Notifications"` |  |
| `size` | `:string` | `"md"` | `md`, `sm` |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `href`, `navigate`, `patch`.

### `<.navbar_icon>`

An icon button of the bar (search on a small screen, help, the menu of the mobile bar): the kit's round icon button
with the icon you name. The label is its accessible name.

    <.navbar_icon name="huge-search-01" label="Buscar" phx-click={...} />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `name` (required) | `:string` |  | A Hugeicons name, written in full (`huge-menu-01`). |
| `label` (required) | `:string` |  |  |
| `size` | `:string` | `"md"` | `md`, `sm` |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `href`, `navigate`, `patch`.

### `<.navbar_lang>`

The language switcher: a small segmented group. `locales` is a list of codes (`["PT", "EN"]`, with `current`) or of
maps `%{code: "PT", navigate: path, active: true}` (`href` / `patch`, or `click`, the `phx-click` value, work too,
and `label` is the title).

    <.navbar_lang locales={[%{code: "PT", href: "?locale=pt"}, %{code: "EN", href: "?locale=en"}]} current="PT" />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `locales` (required) | `:list` |  |  |
| `current` | `:string` | `nil` |  |
| `label` | `:string` | `"Language"` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.navbar_sep>`

The thin vertical line between the icons and the user.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.navbar_env>`

The environment pill (`Produção`, `Homologação`); `tone` is `ok` (green) or `warn` (amber).

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `label` (required) | `:string` |  |  |
| `tone` | `:string` | `"ok"` | `ok`, `warn` |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.navbar_sync>`

The save state: a green check and a muted text (`Salvo há 2 min`).

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `text` (required) | `:string` |  |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.navbar_avatars>`

The people on the page, as overlapping avatars. `users` are maps with `name`, `initials`, `avatar` and `color`; `max`
of them are shown and the rest is a `+N` bubble (`total` when the list you pass is already cut).

    <.navbar_avatars users={@members} max={3} />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `users` (required) | `:list` |  |  |
| `max` | `:integer` | `3` |  |
| `total` | `:integer` | `nil` | How many people there are (default: the length of `users`). |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.navbar_user>`

The user of the bar: the avatar (`variant="avatar"`), with a status ring (`"ring"`) or with the name and the role
(`"named"`). `user` is `%{name, email, role, initials, avatar, color}`, the shape the sidebar uses.

Without the `:menu` slot it is a button for your own `phx-click`. With it, the button opens a raised panel (`role="menu"`,
hidden at first; `id` is then required) toggled by `Phoenix.LiveView.JS`, so no round trip: a click on the button toggles
it and a click outside or Escape closes it.

    <.navbar_user id="me" user={@user} variant="named">
      <:menu>
        <.navbar_menu_head user={@user} />
        <.navbar_menu_item icon="huge-user" navigate={~p"/perfil"}>Perfil</.navbar_menu_item>
      </:menu>
    </.navbar_user>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `user` (required) | `:map` |  |  |
| `variant` | `:string` | `"avatar"` | `avatar`, `ring`, `named` |
| `id` | `:string` | `nil` | Required with a `:menu`. |
| `label` | `:string` | `"Account menu"` | The accessible name of the button. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:menu>` — The content of the panel: `navbar_menu_*` pieces, links with `role="menuitem"`, `<hr />`.

### `<.navbar_menu_head>`

The head of the user menu: the avatar, the name and the email, and a `:badge` (the role) at the end.

    <.navbar_menu_head user={@user}><:badge><.badge color="primary">Admin</.badge></:badge></.navbar_menu_head>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `user` (required) | `:map` |  |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:badge>`

### `<.navbar_menu_status>`

The status line of the menu: a green dot, the label and an `:action` at the end (a text or a button).

    <.navbar_menu_status label="Disponível"><:action>Mudar</:action></.navbar_menu_status>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `label` (required) | `:string` |  |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:action>`

### `<.navbar_menu_row>`

A row of the menu with a label and a control at the end: `theme_switch/1`, `navbar_lang/1`.

    <.navbar_menu_row label="Tema"><.theme_switch id="theme-menu" variant="icons" size="sm" /></.navbar_menu_row>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `label` (required) | `:string` |  |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.navbar_menu_item>`

An item of the menu: a link (`navigate`, `href`, `patch`, with `method="delete"` for a sign-out) or, with only
`phx-click`, an action. `icon` is a Hugeicons name, `kbd` a shortcut at the end, `danger` the red one.

    <.navbar_menu_item icon="huge-settings-02" navigate={~p"/config"} kbd="⌘,">Configurações</.navbar_menu_item>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `icon` | `:string` | `nil` |  |
| `kbd` | `:string` | `nil` |  |
| `danger` | `:boolean` | `false` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `href`, `navigate`, `patch`, `method`, `download`, `target`, `rel`.

Slots:

- `<:inner_block>` (required)
