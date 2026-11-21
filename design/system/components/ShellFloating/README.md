# ShellFloating

Shell de duas colunas de navegação: trilho de módulos, subnavegação com filtros e contadores e o conteúdo num painel flutuante de cantos arredondados.

**Grupo:** 13 · Estrutura e shell  
**Resumo visual:** Trilho de ícones + subnavegação com filtros + main flutuante arredondado · linhas destacando em loop

## Uso (Phoenix / HEEx)

```heex
<.shell variant="floating">
  <:rail>…</:rail>
  <:subnav title="Cases">…</:subnav>
  …
</.shell>
```

## Regras

- Main flutuante: `bg-page`, borda `line`, raio 18, sombra sm, 8px de respiro do shell.
- Trilho de 64px só com ícones (42×42, raio 11); contador âmbar no canto para pendências.
- Subnav de 248px: grupos recolhíveis (Status, Department), contagem em mono, “+ Add” em `muted`.
- Funciona em claro e escuro só com tokens; no escuro o main fica um passo acima do shell.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: app_shell)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's application shell: the page frame, the main sidebar (the icon rail), the sidebar panel with its
collapsible groups, the minimized panel, the sideblock and the horizontal navigation, the header, the right
sidebar, the page header and the dark mode and monochrome toggles.

    <.app_shell id="shell" sidebar_open={@sidebar_open} on_toggle="sidebar">
      <:sidebar>
        <.main_sidebar current={@current_path}>
          <:logo navigate={~p"/"} src={~p"/images/logo.svg"} />
          <:item navigate={~p"/dashboards"} label="Dashboards"><.icon name="home" /></:item>
          <:bottom>
            <.sidebar_profile id="profile" src={@user.avatar} name={@user.name} subtitle="Designer">
              <:item navigate={~p"/profile"} color="warning" title="Profile" description="Your profile setting">
                <.icon name="user" />
              </:item>
            </.sidebar_profile>
          </:bottom>
        </.main_sidebar>
        <.sidebar_panel title="Layouts">
          <.sidebar_nav>
            <.sidebar_nav_group label="Starter" current={@current_path}>
              <:item navigate={~p"/starter/blurred"}>Blurred Header</:item>
            </.sidebar_nav_group>
          </.sidebar_nav>
        </.sidebar_panel>
      </:sidebar>
      <:header>
        <.header right_sidebar="right-sidebar">
          <:notifications>…</:notifications>
        </.header>
      </:header>
      <:aside>
        <.right_sidebar id="right-sidebar">…</.right_sidebar>
      </:aside>
      <.page_header title="Avatar">
        <:crumb navigate={~p"/elements"}>Elements</:crumb>
        <:crumb>Avatar</:crumb>
      </.page_header>
      …
    </.app_shell>

The state Ledger UI keeps in `<body>` classes lives on the shell's root element: `is-sidebar-open`,
`has-min-sidebar` (`layout="minimal"`), `navigation:sideblock` and `navigation:horizontal`,
`is-header-blur` and `is-header-not-sticky`.

### LiveView

`sidebar_open` is the server's state; the browser toggles without a round trip and tells the server through
`on_toggle`. A choice made in the browser survives patches and live navigation (`navigate` between LiveViews
rendering the same shell id) unless the server changes `sidebar_open`; at `xl` and up it is also kept in
`localStorage["linea-sidebar"]` (`persist`). Below `xl` the sidebar closes, as in Ledger UI.
`LedgerUI.open/close/toggle(socket_or_js, "shell")` drive it from the server or a JS pipeline.

Active items come from `active` on each item or from `current` (the current path, compared with the item's
`navigate`, `patch` or `href`), so they follow live navigation.

Dark mode (`<html class="dark">`, `localStorage["dark-mode"]`) and monochrome mode (`<body class="is-monochrome">`,
`localStorage["monochrome-mode"]`) are client state; put `<.theme_script />` in the root layout's `<head>`
so the first paint already has them.

### Setup

The hooks (`LedgerUI.AppShell`, `LedgerUI.SidebarGroup`, `LedgerUI.ShellPopper`, `LedgerUI.ShellTooltips`,
`LedgerUI.RightSidebar`, `LedgerUI.ThemeToggle`, `LedgerUI.MonochromeToggle`) come with Ledger UI's `Hooks`.
Render the shell in the app layout of a `live_session` and give it the current path from an `on_mount`
hook, so the active items follow `navigate`:

    def on_mount(:current_path, _params, _session, socket) do
      {:cont,
       Phoenix.LiveView.attach_hook(socket, :current_path, :handle_params, fn _params, url, socket ->
         {:cont, assign(socket, :current_path, URI.parse(url).path)}
       end)}
    end

### Layouts

`layout="sidebar"` (the default) takes a `main_sidebar/1` and a `sidebar_panel/1`; `"minimal"` adds a
`sidebar_panel_min/1`; `"sideblock"` takes a `sideblock/1`; `"horizontal"` keeps the main sidebar and panel
for phones and puts `horizontal_nav_menu/1`s in the `:nav` slot of `header/1`; `"framed"` is the app
frame described below.

### The framed shell

`layout="framed"` is an app in a frame: the menu sits on the grey frame, 10px from the edges, and the page
is a rounded white panel beside it. The menu is `framed_sidebar/1` with `rail_link/1`s and `rail_module/1`s
(a module opens the pages under it; the module of the current page starts open). It collapses to a 60px rail
of icons (tooltips on hover, badges turned into dots; a click on a module opens it again) and the choice is
kept per person. Below 768px the menu becomes a top bar with a hamburger. The page's title block is
`page_header/1` with `variant="page"`.

    <.app_shell id="shell" layout="framed">
      <:sidebar>
        <.framed_sidebar id="menu" collapsed={@collapsed} on_collapse="collapse" label="Main menu">
          <:brand><img src={~p"/images/mark.svg"} class="size-5" alt="" /></:brand>
          <:wordmark>Signetum</:wordmark>
          <:workspace>
            <.avatar size="2xs" initials="FS" color="primary" />
            <span class="flex-1 text-sm">My Company Ltd</span>
          </:workspace>
          <:search>
            <.icon name="huge-search-01" class="size-4 shrink-0" />
            <span class="flex-1">Search</span>
            <.kbd>Ctrl K</.kbd>
          </:search>
          <.rail_link navigate={~p"/today"} label="Today" current={@current_path}><.icon name="huge-home-01" /></.rail_link>
          <.rail_module id="sales" label="Sales" badge="3" current={@current_path}>
            <:icon><.icon name="huge-shopping-cart-01" /></:icon>
            <:item navigate={~p"/orders"}>Orders</:item>
            <:item navigate={~p"/products"}>Products</:item>
          </.rail_module>
          <.rail_link navigate={~p"/chat"} label="Chat" badge="2" current={@current_path}><.icon name="huge-message-01" /></.rail_link>
          <:bottom>
            <.rail_link navigate={~p"/settings"} label="Settings" current={@current_path}><.icon name="huge-settings-02" /></.rail_link>
            <.rail_user name="Ana Souza" subtitle="Admin"><.avatar name="Ana Souza" color="auto" size="32" /></.rail_user>
          </:bottom>
        </.framed_sidebar>
      </:sidebar>

      <.page_header variant="page" title="Order PV-1283" description="Clinica Santa Monica" clock bell>
        <:leading><.rail_toggle for="menu" label="Collapse menu" /></:leading>
        <:crumb navigate={~p"/orders"}>Orders</:crumb>
        <:crumb>PV-1283</:crumb>
        <:badge><.badge variant="soft" color="info">Approved</.badge></:badge>
        <:actions>
          <.button variant="outline">Duplicate</.button>
          <.button color="primary">Issue NF-e</.button>
        </:actions>
        <:tabs>
          <.tabs id="order-tabs" selected={@tab} on_change="tab">
            <:tab name="items">Items</:tab>
            <:tab name="payment">Payment</:tab>
          </.tabs>
        </:tabs>
      </.page_header>

      <div class="grid flex-1 gap-4 lg:grid-cols-3">…the page…</div>
    </.app_shell>

Rules the markup needs, each one a thing that renders wrong when missed:

  * The collapse button is `rail_toggle/1` in the `:leading` slot of the page header (the corner of the
    panel), not inside the menu. It finds the menu by its `id`. `on_collapse` receives `%{"id" => id,
    "collapsed" => boolean}`; assign `collapsed` back so the server knows, or leave it out and let the
    browser keep the choice.
  * The children of `:search` are laid out as the direct children of the search box: the icon first, then
    the text and the shortcut. In the rail only the first child stays, centered. Do not wrap them in one
    element, and put `class="rail-label"` on anything else that must disappear in the rail (the workspace
    block does it by itself).
  * `rail_module/1` is highlighted only when the current page is one of its items (pass `current` or mark
    one `:item` `active`); opening a module by hand only shows its pages. Give every link `current={@current_path}`
    or `active` so the right one is selected.
  * `:bottom` is for what stays at the foot of the menu: settings and the person.
  * Use `layout="framed"` on `app_shell` and put the page content after `page_header/1`; the panel is a
    flex column, so a child with `flex-1` fills the rest.

### `<.app_shell>`

The page frame: the sidebar, the header, the drawers and the `<main>` content, with Ledger UI's body classes.

`on_toggle` runs when the browser opens or closes the sidebar (a toggle button, a close button, a breakpoint
change, or a remembered choice applied on mount). An event name is pushed with
`%{"id" => id, "open" => boolean}`; a `%JS{}` is executed.

    <.app_shell id="shell" layout="minimal" sidebar_open={@sidebar_open} on_toggle="sidebar">
      <:sidebar>…</:sidebar>
      <:header><.header /></:header>
      <.page_header title="Orders" />
    </.app_shell>

    def handle_event("sidebar", %{"open" => open}, socket),
      do: {:noreply, assign(socket, :sidebar_open, open)}

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` | `"app-shell"` |  |
| `layout` | `:string` | `"sidebar"` | `sidebar`, `minimal`, `sideblock`, `horizontal`, `framed` — `sidebar` is the main sidebar with its panel, `minimal` shows the minimized panel while the panel is closed, `sideblock` is one wide sidebar, `horizontal` puts the navigation in the header, `framed` is the grey frame with a `framed_sidebar/1` and a rounded main panel. |
| `sidebar_open` | `:boolean` | `nil` | Whether the sidebar is open; defaults to open for `sidebar` and `sideblock`. |
| `header_blur` | `:boolean` | `true` | Ledger UI's `is-header-blur`. |
| `header_sticky` | `:boolean` | `true` | `false` is Ledger UI's `is-header-not-sticky`. |
| `persist` | `:boolean` | `true` | Keep the sidebar choice in `localStorage`. |
| `preloader` | `:boolean` | `false` | Ledger UI's app preloader, faded out on mount. |
| `on_toggle` | `:any` | `nil` | An event name or a `%JS{}`. |
| `target` | `:any` | `nil` | The `phx-target` of `on_toggle`. |
| `main_class` | `:any` | `nil` | Merged into the classes of `<main class="main-content">`. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:aside>` — Fixed parts: the right sidebar, drawers.
- `<:header>` — The `header/1`.
- `<:inner_block>`
- `<:sidebar>` — The main sidebar and its panel, or the sideblock.
- `<:tab_bar>` — A bottom bar of tabs for phones (`layout="framed"`), under the panel and hidden from 768px: a `tab_bar/1`.

### `<.main_sidebar>`

The main sidebar: Ledger UI's icon rail with the logo, the section links (with a tooltip on the right and an
active state) and the bottom links.

    <.main_sidebar current={@current_path}>
      <:logo navigate={~p"/"} src={~p"/images/app-logo.svg"} />
      <:item navigate={~p"/forms"} label="Forms"><svg>…</svg></:item>
      <:bottom><.main_sidebar_link navigate={~p"/settings"}><svg>…</svg></.main_sidebar_link></:bottom>
    </.main_sidebar>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` | `"main-sidebar"` |  |
| `current` | `:string` | `nil` | The current path; an item whose link matches it is active. |
| `centered` | `:boolean` | `false` | Centers the links between the logo and the bottom. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:bottom>`
- `<:item>` — attrs: `href`, `navigate`, `patch`, `label`, `active`
- `<:logo>` — attrs: `href`, `navigate`, `patch`, `src`, `alt`

### `<.main_sidebar_link>`

One icon link of the main sidebar. With `label` it gets Ledger UI's tooltip on its right (inside a
`main_sidebar/1`, which positions it) and that accessible name.

    <.main_sidebar_link navigate={~p"/settings"} label="Settings" current={@current_path}>
      <svg class="size-7">…</svg>
    </.main_sidebar_link>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `label` | `:string` | `nil` | The tooltip and the accessible name. |
| `active` | `:boolean` | `false` |  |
| `current` | `:string` | `nil` | The current path; the link is active when it matches. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `href`, `navigate`, `patch`, `method`, `replace`.

Slots:

- `<:inner_block>` (required) — The icon.

### `<.sidebar_profile>`

The avatar at the bottom of the main sidebar and the profile box it opens on its right: the person, a list
of links with a colored icon, and a footer (Ledger UI's logout button).

    <.sidebar_profile id="profile" src={@user.avatar} name="Travis Fuller" subtitle="Product Designer">
      <:item navigate={~p"/profile"} color="warning" title="Profile" description="Your profile setting">
        <svg>…</svg>
      </:item>
      <:footer><.button color="primary" class="h-9 w-full">Logout</.button></:footer>
    </.sidebar_profile>

A link of the box closes it.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `src` (required) | `:string` |  |  |
| `alt` | `:string` | `"avatar"` |  |
| `name` (required) | `:string` |  |  |
| `subtitle` | `:string` | `nil` |  |
| `status` | `:string` | `"success"` | ``, `success`, `warning`, `error`, `info`, `neutral` |
| `href` | `:string` | `nil` |  |
| `navigate` | `:string` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:footer>`
- `<:item>` — attrs: `href`, `navigate`, `patch`, `method`, `color`, `title`, `description`

### `<.sidebar_panel>`

The sidebar panel next to the main sidebar: its title, the close button Ledger UI shows below `xl`, and the
scrolling body (`sidebar_nav/1`, `sidebar_nav_divider/1`).

    <.sidebar_panel title="Elements">
      <.sidebar_nav>
        <.sidebar_nav_link navigate={~p"/avatar"} current={@current_path}>Avatar</.sidebar_nav_link>
      </.sidebar_nav>
      <.sidebar_nav_divider />
      <.sidebar_nav>…</.sidebar_nav>
    </.sidebar_panel>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `title` (required) | `:string` |  |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.sidebar_nav>`

A list of the sidebar panel (or the sideblock): `sidebar_nav_link/1` and `sidebar_nav_group/1`.

    <.sidebar_nav>
      <.sidebar_nav_link navigate={~p"/orders"} current={@current_path}>Orders</.sidebar_nav_link>
    </.sidebar_nav>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.sidebar_nav_link>`

A plain link of the sidebar panel, active with `active` or when its path is `current`.

    <.sidebar_nav_link navigate={~p"/orders"} current={@current_path}>Orders</.sidebar_nav_link>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `active` | `:boolean` | `false` |  |
| `current` | `:string` | `nil` | The current path; the link is active when it matches. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `href`, `navigate`, `patch`, `method`, `replace`.

Slots:

- `<:inner_block>` (required)

### `<.sidebar_nav_group>`

A collapsible group of the sidebar panel. It opens when one of its items is active (or with `open`); the
groups that share `name` open one at a time, like Ledger UI's accordion. A group opened or closed in the browser
stays so across patches unless the server changes `open`.

    <.sidebar_nav_group label="Starter" current={@current_path}>
      <:item navigate={~p"/starter/1"}>Blurred Header</:item>
      <:item navigate={~p"/starter/2"}>Unblurred Header</:item>
    </.sidebar_nav_group>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` | `nil` | Defaults to `sidebar-group-<label>`. |
| `label` (required) | `:string` |  |  |
| `open` | `:boolean` | `nil` | Defaults to whether an item is active. |
| `name` | `:string` | `"sidebar-nav"` | Groups with the same name open one at a time. |
| `current` | `:string` | `nil` | The current path; the matching item is active. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:item>` (required) — attrs: `href`, `navigate`, `patch`, `active`

### `<.sidebar_nav_divider>`

The line between the lists of the sidebar panel.

    <.sidebar_nav_divider />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

### `<.sidebar_panel_min>`

Ledger UI's minimized sidebar panel (`layout="minimal"`): shown next to the main sidebar while the panel is
closed. A header (an avatar), the icon links (`sidebar_min_group/1`, `sidebar_min_link/1`,
`sidebar_min_divider/1`) and a footer.

    <.sidebar_panel_min>
      <:header><div class="lu-avatar size-10">…</div></:header>
      <.sidebar_min_group>
        <.sidebar_min_link navigate={~p"/inbox"} label="Inbox" current={@current_path}><svg>…</svg></.sidebar_min_link>
        <.sidebar_min_link navigate={~p"/trash"} label="Trash" color="error"><svg>…</svg></.sidebar_min_link>
      </.sidebar_min_group>
      <.sidebar_min_divider />
      <.sidebar_min_group>…</.sidebar_min_group>
      <:footer><.button variant="outline" shape="pill" icon aria-label="More">…</.button></:footer>
    </.sidebar_panel_min>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:footer>`
- `<:header>`
- `<:inner_block>` (required)

### `<.sidebar_min_group>`

A list of icon links of the minimized panel; the first one keeps Ledger UI's top margin.

    <.sidebar_min_group>
      <.sidebar_min_link href="#" label="Home"><svg>…</svg></.sidebar_min_link>
    </.sidebar_min_group>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Slots:

- `<:inner_block>` (required)

### `<.sidebar_min_link>`

An icon link of the minimized panel. Active links are primary soft, the others take `color`.

    <.sidebar_min_link navigate={~p"/starred"} label="Starred" color="warning"><svg>…</svg></.sidebar_min_link>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `label` | `:string` | `nil` | The accessible name. |
| `color` | `:string` | `"neutral"` | `neutral`, `primary`, `secondary`, `info`, `success`, `warning`, `error` |
| `active` | `:boolean` | `false` |  |
| `current` | `:string` | `nil` | The current path; the link is active when it matches. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `href`, `navigate`, `patch`, `method`, `replace`.

Slots:

- `<:inner_block>` (required)

### `<.sidebar_min_divider>`

The line between the lists of the minimized panel.

    <.sidebar_min_divider />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

### `<.sideblock>`

Ledger UI's sideblock (`layout="sideblock"`): one wide sidebar with the logo, the close button and the
navigation (`sidebar_nav/1`). It goes in the `:sidebar` slot of `<.app_shell layout="sideblock">`.

    <.sideblock>
      <:logo navigate={~p"/"} src={~p"/images/app-logo.svg"} />
      <.sidebar_nav>
        <.sidebar_nav_group label="Orders" current={@current_path}>
          <:item navigate={~p"/orders"}>All orders</:item>
        </.sidebar_nav_group>
      </.sidebar_nav>
    </.sideblock>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
- `<:logo>` — attrs: `href`, `navigate`, `patch`, `src`, `alt`

### `<.header>`

The header: Ledger UI's animated sidebar toggle, the search bar (and the full screen search of phones), the
dark mode and monochrome toggles, the notifications, the right sidebar toggle and a profile slot.

With a `:nav` slot it is Ledger UI's horizontal navigation header: the toggle only on phones, the `:brand`
on larger screens and the navigation row (`horizontal_nav_menu/1`) below.

    <.header right_sidebar="right-sidebar">
      <:start><.page_header title="Orders" class="py-0 lg:py-0" /></:start>
      <:search_results>…</:search_results>
      <:notifications>…</:notifications>
    </.header>

The search input takes `search_input` (a map of attributes: `name`, `value`, `phx-change`, `phx-debounce`…).

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` | `"app-header"` |  |
| `toggle` | `:boolean` | `true` | The sidebar toggle. |
| `search` | `:boolean` | `true` |  |
| `search_placeholder` | `:string` | `"Search here..."` |  |
| `search_input` | `:map` | `%{}` |  |
| `theme_toggle` | `:boolean` | `true` |  |
| `monochrome_toggle` | `:boolean` | `true` |  |
| `right_sidebar` | `:string` | `nil` | The id of the `right_sidebar/1` its button toggles. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:actions>` — Buttons before the theme toggle.
- `<:brand>` — attrs: `href`, `navigate`, `src`, `label` — The logo and name of a horizontal header.
- `<:mobile_search>` — What the full screen search of phones shows under its input.
- `<:nav>` — The navigation row of a horizontal header.
- `<:notifications>` — attrs: `dot`, `label` — The notification box; the bell opens it.
- `<:profile>` — Content at the end, such as an avatar menu.
- `<:search_results>` — The box under the search bar, shown while it has the focus.
- `<:start>` — Content after the toggle: a title, a breadcrumb.

### `<.sidebar_toggle>`

Ledger UI's animated hamburger: three bars that turn into an arrow while the sidebar is open. Inside an
`app_shell/1` it toggles the sidebar; `header/1` already renders one.

    <.sidebar_toggle />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.horizontal_nav_menu>`

A dropdown of the horizontal navigation (the `:nav` slot of `header/1`): an icon and a label, and a box of
links (`:item` slots, or `horizontal_nav_link/1` and `horizontal_nav_divider/1` as content). It is active
with `active`, or when one of its items is active or matches `current`.

    <.horizontal_nav_menu id="nav-pages" label="Pages" current={@current_path}>
      <:icon><svg>…</svg></:icon>
      <:item navigate={~p"/pages/blank"}>Blank</:item>
    </.horizontal_nav_menu>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `label` (required) | `:string` |  |  |
| `active` | `:boolean` | `false` |  |
| `current` | `:string` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:icon>`
- `<:inner_block>`
- `<:item>` — attrs: `href`, `navigate`, `patch`, `active`

### `<.horizontal_nav_link>`

A link of a horizontal navigation box (inside `horizontal_nav_menu/1`). A click closes the box.

    <.horizontal_nav_link navigate={~p"/reports"} current={@current_path}>Reports</.horizontal_nav_link>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `active` | `:boolean` | `false` |  |
| `current` | `:string` | `nil` | The current path; the link is active when it matches. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `href`, `navigate`, `patch`, `method`, `replace`.

Slots:

- `<:inner_block>` (required)

### `<.horizontal_nav_divider>`

The line between the links of a horizontal navigation box.

    <.horizontal_nav_divider />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

### `<.right_sidebar>`

Ledger UI's right sidebar: a drawer from the right with an overlay, a top row (`:title` and the close button),
the content and a `:footer` (Ledger UI's floating tab bar).

Opened with `open`, `right_sidebar_toggle/1`, or `LedgerUI.open/close/toggle(id)` (also from the server with
a socket). Esc, the overlay and the close button close it. `on_open` and `on_close` take an event name,
pushed with `%{"id" => id}`, or a `%JS{}`.

    <.right_sidebar id="right-sidebar" open={@panel_open} on_close="panel-closed">
      <:title><span class="text-xs">25 May, 2022</span></:title>
      <div class="px-3">…</div>
    </.right_sidebar>

### Remembering the panel

A drawer with several panels (Ledger UI's floating tab bar in the `:footer`) switches them in the
browser, with `JS` commands on its buttons. `persist_tab` makes the drawer remember the panel the
person chose, for the session (`sessionStorage`), so it opens on it again after a live navigation
replaces the page. Mark each control that selects a panel with `data-tab="name"`; clicking one
saves `name`, and when the drawer mounts it clicks the saved control, which runs the control's own
`phx-click`. The key is derived from the drawer's `id`, so two drawers do not share a choice.

    <.right_sidebar id="right-sidebar" persist_tab>
      <.panel id="panel-home" />
      <.panel id="panel-activity" />
      <:footer>
        <button data-tab="home" phx-click={show_panel("home")}>Home</button>
        <button data-tab="activity" phx-click={show_panel("activity")}>Activity</button>
      </:footer>
    </.right_sidebar>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `open` | `:boolean` | `false` |  |
| `label` | `:string` | `"Sidebar"` |  |
| `persist_tab` | `:boolean` | `false` | Remembers, for the session, the control with `data-tab` that was clicked last, and clicks it again when the drawer mounts. |
| `on_open` | `:any` | `nil` |  |
| `on_close` | `:any` | `nil` |  |
| `target` | `:any` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:footer>`
- `<:inner_block>`
- `<:title>`

### `<.right_sidebar_toggle>`

The header button (Ledger UI's grid icon) that toggles a `right_sidebar/1`; `header/1` renders one with
`right_sidebar="id"`.

    <.right_sidebar_toggle target="right-sidebar" />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `target` (required) | `:string` |  |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.framed_sidebar>`

The menu of the framed shell (`<.app_shell layout="framed">`): the brand, an optional workspace and search,
the navigation (`rail_link/1`, `rail_module/1`) and the bottom items. It collapses to a 60px rail of
icons: the labels (any element with the class `rail-label`) go away, badges become dots and a tooltip shows
the label on hover. The choice is kept in `localStorage` (`persist`); a `collapsed` the server changes wins
over it. Below 768px it is a top bar with a hamburger that opens the menu under it.

    <.framed_sidebar id="menu" collapsed={@collapsed} on_collapse="collapse">
      <:brand><img src={~p"/images/mark.svg"} alt="" class="size-5" /></:brand>
      <:wordmark>Signetum</:wordmark>
      <.rail_link navigate={~p"/today"} label="Today"><svg>…</svg></.rail_link>
    </.framed_sidebar>

    def handle_event("collapse", %{"collapsed" => collapsed}, socket),
      do: {:noreply, assign(socket, :collapsed, collapsed)}

Put `<.rail_toggle for="menu" />` anywhere (the header, the bottom of the menu) for the button that collapses it.

The width of the collapsed rail comes from the CSS variable `--lu-rail-collapsed` (60px when it is not set; the menu reads it as
`data-[collapsed]:w-(--lu-rail-collapsed,60px)`). `collapsed_width={72}` sets it, in px, on the menu; the variable can also be set in
your CSS, on the menu or on an ancestor (`--lu-rail-collapsed: 72px`).

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `collapsed` | `:boolean` | `false` | Whether the menu starts as a rail. |
| `collapsed_width` | `:integer` | `nil` | The width of the collapsed rail in px (60 when not given). Sets `--lu-rail-collapsed` on the menu; see the note above. |
| `persist` | `:boolean` | `true` | Keep the choice in `localStorage["linea-rail"]`. |
| `on_collapse` | `:string` | `nil` | An event pushed with `%{"id" => id, "collapsed" => boolean}` when the choice changes. |
| `shortcut` | `:string` | `"b"` | Ctrl/⌘ + this key collapses and expands the menu (opens it on a phone); `nil` turns it off. |
| `target` | `:any` | `nil` | The `phx-target` of `on_collapse`. |
| `label` | `:string` | `"Main menu"` | The accessible name of the menu. |
| `mobile_label` | `:string` | `"Menu"` | The accessible name of the hamburger. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:bottom>` — Items under the navigation: settings, the person.
- `<:brand>` — The mark in its rounded box (a logo image). With no `:brand` and no `:wordmark` the brand row and its rule are left out on wide screens (phones keep the bar for the hamburger).
- `<:inner_block>` (required) — The navigation: `rail_link/1` and `rail_module/1`.
- `<:search>` — attrs: `id`, `class`, `title`, `aria-label`, `phx-click`, `phx-target` — The search box; mark what the rail hides with `rail-label`. With `phx-click` (or `id`, `aria-label`...) it is a button that opens your search or command palette, so the whole box is the target.
- `<:wordmark>` — The name next to the mark; hidden in the rail.
- `<:workspace>` — The workspace switcher under the brand; hidden in the rail.

### `<.tab_bar>`

A phone's bottom bar of tabs: one icon per section, the current one in the accent color. Put it in the
`:tab_bar` slot of `<.app_shell layout="framed">`, or at the foot of any phone-sized frame.

    <.tab_bar>
      <:tab navigate={~p"/today"} label="Today" active><.icon name="huge-home-01" /></:tab>
      <:tab navigate={~p"/orders"} label="Orders"><.icon name="huge-shopping-cart-01" /></:tab>
    </.tab_bar>

`variant="canvas"` is the bar of the canvas "Celular" board, a kit CSS `dock` (`dock-label`, `dock-active`) placed inside the board: a bar with the icon and the label
visible under it, the current tab highlighted (`<nav class="dock"><a class="dock-active">…<span class="dock-label">…</span></a></nav>`). The `class`
of a tab is added to its link, so the app can mark its own states.

    <.tab_bar variant="canvas" current={@current_path} match="prefix">
      <:tab navigate={~p"/app"} label="Início" match="exact"><.icon name="huge-home-01" /></:tab>
      <:tab navigate={~p"/app/tasks"} label="Tarefas" class="tasks"><.icon name="huge-task-01" /></:tab>
    </.tab_bar>

The current tab is the one whose link is `current` (`match="exact"`, the default, compares the path). With
`match="prefix"` (on the bar for every tab, or on a tab to override it) `/app/tasks/NXP-1` also lights the tab
of `/app/tasks`: the tab path or any path under it. The home path `/` is always compared exactly. `active` on a
tab forces it.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `label` | `:string` | `"Sections"` | The accessible name of the bar. |
| `current` | `:string` | `nil` | The current path; the tab whose link matches it is active. |
| `variant` | `:string` | `"default"` | `default`, `canvas` — `canvas` draws a kit CSS `dock` with the label visible under each icon; `default` keeps the icon-only `linea-tabbar`. |
| `match` | `:string` | `"exact"` | `exact`, `prefix` — How `current` is compared with the tabs: `exact` (the path) or `prefix` (the path or what is under it). A tab can override it. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:tab>` (required) — attrs: `href`, `navigate`, `patch`, `label`, `active`, `class`, `match` — The icon; `label` is its accessible name.

### `<.rail_toggle>`

A button that collapses and expands the `framed_sidebar/1` with that id, from anywhere on the page. It is
pressed (`aria-pressed`) while the menu is a rail.

    <.rail_toggle for="menu" label="Collapse menu" />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `for` (required) | `:string` |  | The id of the `framed_sidebar/1`. |
| `label` | `:string` | `"Collapse menu"` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` — The icon; the default is a panel with its sidebar.

### `<.rail_link>`

A page of the framed menu: the icon, the label, an optional badge and a tooltip with the label for the rail.

    <.rail_link navigate={~p"/today"} label="Today" current={@current_path}><svg>…</svg></.rail_link>
    <.rail_link navigate={~p"/chat"} label="Chat" badge="2">…</.rail_link>
    <.rail_link navigate={~p"/search"} label="Search"><svg>…</svg><:trailing><.kbd>⌘K</.kbd></:trailing></.rail_link>
    <.rail_link navigate={~p"/orders/open"} label="Open orders" variant="sub" />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `label` (required) | `:string` |  |  |
| `badge` | `:string` | `nil` | A count; a red dot in the rail. |
| `variant` | `:string` | `"default"` | `default`, `sub` — `sub` is a sub-link: 32px tall and indented, with the icon optional; hidden in the rail. |
| `active` | `:boolean` | `false` |  |
| `current` | `:string` | `nil` | The current path; the link is active when it matches. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `href`, `navigate`, `patch`, `method`, `replace`.

Slots:

- `<:inner_block>` — The icon (optional in the `sub` variant).
- `<:trailing>` — Right-aligned content, such as a `<.kbd>⌘K</.kbd>` hint; hidden when the rail collapses.

### `<.rail_heading>`

A small uppercase title over a group of `rail_link/1`s in the framed menu ("Operations"); hidden in the rail.

    <.rail_heading>Operations</.rail_heading>
    <.rail_heading variant="sans">Operations</.rail_heading>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `variant` | `:string` | `"mono"` | `mono`, `sans` — `mono` is the default title; `sans` is 11.5px, uppercase, weight 500. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.rail_module>`

A module of the framed menu: a button that opens the pages under it. The module of the current page
starts open; opening and closing it needs no round trip, and a patch keeps what the person chose. In the
rail a click on it expands the menu and opens the module.

    <.rail_module id="sales" label="Sales" badge="3" current={@current_path}>
      <:icon><svg>…</svg></:icon>
      <:item navigate={~p"/orders"}>Orders</:item>
      <:item navigate={~p"/products"}>Products</:item>
    </.rail_module>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `label` (required) | `:string` |  |  |
| `badge` | `:string` | `nil` | A count; a red dot in the rail. |
| `open` | `:boolean` | `nil` | Defaults to whether one of the pages is active. |
| `current` | `:string` | `nil` | The current path; the matching page is active. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:icon>` (required)
- `<:item>` (required) — attrs: `navigate`, `patch`, `href`, `active`, `badge` — A page: `navigate`, `patch` or `href`, `active`, and an optional `badge` (a count beside the page).

### `<.rail_workspace>`

The workspace switcher under the brand of the framed menu: the workspace's initials (or your own picture),
its name and a line under it, with the up-down chevrons. It is a button, so `phx-click` (or a dropdown
around it) opens your list of workspaces. It goes in the `:workspace` slot of `framed_sidebar/1` and is
hidden in the rail.

    <:workspace>
      <.rail_workspace name="Acme Ltda" subtitle="HQ · Professional plan" phx-click="workspaces" />
    </:workspace>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `name` (required) | `:string` |  |  |
| `subtitle` | `:string` | `nil` |  |
| `initials` | `:string` | `nil` | Defaults to the first letters of the name. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` — Replaces the initials, a picture for the workspace.

### `<.rail_user>`

The person at the bottom of the framed menu: their picture and, outside the rail, their name and subtitle.

    <.rail_user name="Ana Souza" subtitle="Admin"><.avatar name="Ana Souza" color="auto" size="32" /></.rail_user>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `name` (required) | `:string` |  |  |
| `subtitle` | `:string` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required) — The picture.

### `<.page_header>`

The title of a page with Ledger UI's breadcrumb next to it: the crumbs with a link are followed by a
chevron, the last one is plain text.

    <.page_header title="Avatar">
      <:crumb navigate={~p"/elements"}>Elements</:crumb>
      <:crumb>Avatar</:crumb>
      <:actions><.button color="primary">New</.button></:actions>
    </.page_header>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `title` (required) | `:string` |  |  |
| `show_heading` | `:boolean` | `true` | `false` does not render the `h1` (the title, the `:heading` slot and the inline badge); the crumbs, the description and the actions stay. |
| `density` | `:string` | `"default"` | `default`, `compact` — The top padding: `default` is 26px, `compact` is 24px. |
| `variant` | `:string` | `"inline"` | `inline`, `page` — `inline` is Ledger UI's row, the title with its crumbs beside it. `page` is the framed shell's title block: the crumbs with the clock and the bell on top (left out when there is none of them), or a `back` link, then the badge, the 34px title with a context line and the actions, and the tabs. |
| `description` | `:string` | `nil` | The context line under the title (`variant="page"`). |
| `back` | `:string` | `nil` | A path to go back to: a "‹ label" link above the title, in place of the top row (`variant="page"`). |
| `back_label` | `:string` | `nil` | The text of the `back` link. |
| `badge_position` | `:string` | `"above"` | `above`, `inline` — The `:badge` above the title, or `inline` beside it (`variant="page"`). |
| `clock` | `:boolean` | `false` | The date and time at the end of the top row, kept current (`variant="page"`). |
| `locale` | `:string` | `nil` | The language of the clock (`pt-BR`); the browser's when not given. |
| `bell` | `:boolean` | `false` | A bell button at the end of the top row (`variant="page"`). |
| `bell_label` | `:string` | `"Notifications"` |  |
| `on_bell` | `:any` | `nil` | An event name or a `%JS{}` for the bell's click. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:actions>` — Buttons or filters at the right end of the row.
- `<:badge>` — The status badge above the title (`variant="page"`).
- `<:crumb>` — attrs: `href`, `navigate`, `patch`
- `<:icon>` — A tile or avatar before the title and the description, e.g. a project's colored square (`variant="page"`).
- `<:inner_block>` — Content after the breadcrumb.
- `<:leading>` — Before the breadcrumb on the top row, where `rail_toggle/1` goes to collapse the menu (`variant="page"`).
- `<:notifications>` — Replaces the bell with your own button or menu (`variant="page"`).
- `<:tabs>` — The page's tabs under the title, full width: a `tabs/1`, which draws its rule (`variant="page"`).

### `<.theme_toggle>`

Ledger UI's dark mode button: a moon in dark mode, a sun in light mode. It toggles the `dark` class of `<html>`
and keeps it in `localStorage["dark-mode"]` (and the choice in `localStorage["theme"]`, as `theme_switch/1` does, so
the two stay in step). `on_change` gets `%{"dark" => boolean}` (an event name) or runs
(a `%JS{}`).

    <.theme_toggle id="theme" on_change="theme-changed" />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` | `"theme-toggle"` |  |
| `on_change` | `:any` | `nil` |  |
| `target` | `:any` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.monochrome_toggle>`

Ledger UI's monochrome mode: the palette button of the header (`variant="button"`) or the switch of its
monochrome page (`variant="switch"`, the label as content). It toggles the `is-monochrome` class of `<body>`
and keeps it in `localStorage["monochrome-mode"]`; every toggle on the page follows. `on_change` gets
`%{"monochrome" => boolean}` or runs.

    <.monochrome_toggle id="mono" />
    <.monochrome_toggle id="mono-switch" variant="switch">Toggle Monochrome Mode</.monochrome_toggle>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` | `"monochrome-toggle"` |  |
| `variant` | `:string` | `"button"` | `button`, `switch` |
| `on_change` | `:any` | `nil` |  |
| `target` | `:any` | `nil` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>`

### `<.theme_script>`

The script for the root layout's `<head>` that applies the stored dark mode before the first paint (Ledger UI's
"prevent flickering" script) and the stored monochrome mode as soon as `<body>` exists.

It reads the `theme_switch` choice (`localStorage["theme"]`: `"light"`, `"dark"` or `"system"`, which follows
`prefers-color-scheme`) and, when there is none, the `localStorage["dark-mode"]` flag the `theme_toggle` always kept.

    <head>
      <.theme_script />
    </head>

It also puts the named theme `theme_picker/1` keeps (`localStorage["linea-theme"]`) on `<html data-theme>`, or
`theme` (default `config :ledger_ui, :theme`) when nothing is stored, so the palette is on before the first paint.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `theme` | `:string` | `nil` | The named theme when the user chose none (default `config :ledger_ui, :theme`). |

Any other HTML/phx attribute goes to the root element.
