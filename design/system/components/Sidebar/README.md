# Sidebar

Sidebar do exemplo: seletor de workspace, navegação principal com contadores, pastas de visões, card de IA e usuário no rodapé.

**Grupo:** 13 · Estrutura e shell  
**Resumo visual:** format sections · rail · tree · variant floating · sidebar · inset · recolher · match exact/prefix · badges

## Uso (Phoenix / HEEx)

```heex
<.sidebar workspace={@workspace} current={:overview}>
  <:item icon="dashboard-square-01" navigate={~p"/"}>Overview</:item>
  <:item icon="user-remove-01" badge={23} tone="neg">Churn</:item>
  <:view icon="folder-01">Board packs</:view>
</.sidebar>
```

## Regras

- Largura 260, fundo `bg-shell`. Item 38px, raio 10; ativo em `bg-selected` com ícone teal.
- Contadores à direita em `muted`; alerta vira ponto + número em `neg` (Churn 23).
- Visões salvas (pastas) com seta → abrem submenu; “Create view” por último.
- Card de IA fixo acima de Settings; usuário com troca de conta no rodapé.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: sidebar)

Todos os function components, atributos, valores e slots que este componente cobre.

The side menu of the Shell, in three formats that read the same data (the canvas "Sidebar" board):

  * `sections` (the default): the brand with a company switcher, groups with an uppercase mono label,
    "settings and help" at the foot and the plan card.
  * `rail`: a 58px rail of icons (logo, home, the person, one icon per group, extra apps in coloured circles,
    the foot items) beside the raised panel of the active module: its title, a create button, its items, a
    coloured tree, the "try" shortcuts and the trial card.
  * `tree`: the brand with a collapse button, groups with a label and a chevron, children joined by a line,
    square coloured icons, a notice dot and the user card at the foot (see "The foot" for the version line instead).

    <.sidebar format="rail" nav={MyAppWeb.Nav.items(assigns)} current={@current_path}
      brand={%{name: "Linea", logo: "S"}} user={%{name: "Marina Costa", email: "marina@linea.com"}} />

Put it inside a `.sg` root (the framed `shell/1` is one). Changing `format` changes how the menu is drawn,
never the items.

### The nested format

`format="nested"` is the shadcn/ui sidebar: the brand as a team switcher (logo tile, `brand.name` and
`brand.plan`, ↕), groups under a quiet label, items whose `children` open under a thin line with a chevron that
turns, and the user at the foot (avatar, name, e-mail, ↕). With `brand.menu` and `user.menu` both rows open a
menu beside the sidebar (`dropdown/1`, ids `"#{id}-team"` and `"#{id}-user"`); the user menu starts with the
avatar, name and e-mail. A menu is a list of maps (`label`, `icon`, `navigate` / `patch` / `href` with an
optional `method`, `click` for a `phx-click`, `hint` at the end, `danger: true` in red, `heading: true` for a
label) and `:separator` for a line:

    user={%{name: "Marina Costa", email: "marina@linea.com", menu: [
      %{label: "Upgrade to Pro", icon: "spark", navigate: ~p"/billing/upgrade"},
      :separator,
      %{label: "Account", icon: "user", navigate: ~p"/account"},
      %{label: "Billing", icon: "card", navigate: ~p"/billing"},
      :separator,
      %{label: "Log out", icon: "huge-logout-03", href: ~p"/users/log-out", method: "delete"}
    ]}}

Put `<.rail_toggle for="sidebar" />` at the top of the main area for the panel button of the shadcn layout;
collapsed, the menu keeps its icons, the switcher's logo and the avatar, with tooltips.

### Variants

`variant="floating"` (the default) is the card with corners and a shadow; `"sidebar"` sits flush, on the page
background with a line at its edge; `"inset"` drops the card too, for a main area drawn as a card beside it.

### The menu data

`nav` is a list of maps, in the order of the menu. A map with `group` is a group, any other is an item.

Item keys:

  * `label`: the text (also the tooltip of the collapsed menu and the accessible name of an icon).
  * `icon`: see "Icons" below.
  * `navigate`, `patch` or `href`: where it goes (`#` when none).
  * `count`: a number at the right, in mono. A dot when the menu is collapsed.
  * `badge`: a notice dot at the right (the bell of the rail). A string is its accessible name.
  * `color`: a colour for the icon: a round chip in the rail's tree (children), a square chip in the `tree`
    format (items). A name (`blue`, `green`, `rose`, `violet`, `orange`, `ink`) or any CSS colour.
  * `children`: items under it, joined by a line (`tree`), a coloured tree (`rail`) or a plain tree.
  * `collapsible`: in the `tree` format an item with `children` gets a chevron at the right that closes and
    opens them, and the row itself toggles too when it has no destination (`navigate`, `patch` or `href`);
    with a destination, clicking the link also opens them. `false` takes it away. It is `true` when left out. It starts open only when it holds the
    active item (itself or a child), closed otherwise.
  * `open`: `true` or `false` forces a collapsible item open or closed at first, whatever the route.
  * `active`: marks it active; `current` marks the item whose `navigate`/`patch`/`href` is the current
    path (path and query are compared). The active item has `aria-current="page"`.
  * `match`: `"exact"` (the default, or the `match` of the component) or `"prefix"`: the item is also active
    on a path under its own (`navigate: "/app/tasks"` lights up on `/app/tasks/NXP-1`; only the path is
    compared, and `/` is always exact).
  * `disabled`: a "coming soon" item: a `span` (not a link) with `aria-disabled="true"` and `class="lu-sb-item dis"` inside an `li.menu-disabled`,
    never active and never toggling. `title` is its tooltip (a string `disabled` works as the title too).
  * `formats`: a list of formats that show it (`["rail"]`: only the rail); every format when left out.

Group keys:

  * `group`: the label.
  * `icon`: the icon of the group in the `rail`.
  * `items`: its items (and, in the `rail` panel, nested groups with a `collapsible` header).
  * `collapsible`: the whole header row is the toggle (not just the chevron); `false` takes the chevron (and the toggle) away and the group is always shown; it is
    `true` when left out. A collapsible group starts open only when it holds the active item.
  * `open`: `true` or `false` forces a collapsible group open or closed at first, whatever the route.
  * `navigate`, `patch`, `href`: where the group's icon goes in the rail (the first item's when left out).
  * `footer: true`: the group is the foot of the menu ("settings and help"): in `sections` under its label,
    in `tree` without it, in the `rail` as icons at the bottom.
  * `action`: `%{label, navigate, icon}`, the create button at the top of the rail panel.
  * `try`: `%{label, items}`, the shortcuts at the foot of the rail panel ("Try").

The first item that is not in a group is the home of the rail (above the person); the other items without
a group come after the group icons. The module open in the rail panel is the group that holds the active
item (the first group when none does).

### Icons

`icon` is a short name of the table below, drawn as the Hugeicons icon the canvas uses, or any class name
(`huge-…`, `fa-solid fa-house`) that goes through as it is.

  | Name | Icon |
  |---|---|
  | `add` | `huge-add-01` |
  | `bank` | `huge-bank` |
  | `bell` | `huge-notification-03` |
  | `box` | `huge-package` |
  | `calendar` | `huge-calendar-03` |
  | `cancel` | `huge-cancel-circle` |
  | `card` | `huge-credit-card` |
  | `cart` | `huge-shopping-cart-01` |
  | `chart` | `huge-chart-histogram` |
  | `clock` | `huge-clock-01` |
  | `doc` | `huge-file-01` |
  | `filter` | `huge-filter-horizontal` |
  | `flash` | `huge-flash` |
  | `globe` | `huge-globe-02` |
  | `goal` | `huge-flag-02` |
  | `heart` | `huge-favourite` |
  | `help` | `huge-information-circle` |
  | `home` | `huge-home-01` |
  | `invoice` | `huge-invoice-01` |
  | `kanban` | `huge-kanban` |
  | `message` | `huge-message-01` |
  | `money` | `huge-money-03` |
  | `pin` | `huge-location-01` |
  | `settings` | `huge-settings-02` |
  | `sidebar` | `huge-sidebar-left` |
  | `spark` | `huge-sparkles` |
  | `tag` | `huge-tag-01` |
  | `trend` | `huge-chart-line-data-01` |
  | `truck` | `huge-delivery-truck-01` |
  | `user` | `huge-user` |
  | `users` | `huge-user-multiple` |
  | `wallet` | `huge-wallet-01` |

### Configuration

    config :ledger_ui, :shell, sidebar: :sections, nav: {MyAppWeb.Nav, :items}

`sidebar` (an atom or a string) is the format when `format` is left out and `nav` is `{module, function}`,
called with the assigns of the component, when `nav` is left out. `footer: :version` and `version: "v1.4.2"`
(or a map) are the foot (see "The foot"). What you pass always wins.

### The foot

The foot of the menu is a choice (`footer`, in the three formats):

  * `"user"`: the person. The user card in the `tree` and in `sections` (the same `.lu-sb-user` card, in place
    of the plan card), the avatar in the `rail`.
  * `"version"`: the version line of the canvas (a status dot, `v1.4.2`, the build and the "What's new" link)
    in place of the user (`tree`, `rail`) or of the plan card (`sections`). The line is at the foot of the
    panel in the `rail`, so a `rail` collapsed to icons (which hides the panel) does not show it.
  * `"none"`: nothing, for an app that already shows the user in its topbar.
  * left out: each format as it was, the user card in the `tree`, the plan card in `sections`, the avatar in
    the `rail`.

`version` is a string or a map; only `version` is required:

    version="v1.4.2"
    version=%{version: "v1.4.2", build: "2a9f1c3", navigate: "/changelog", label: "Novidades",
              title: "Updated today", status: :ok}

  * `build`: the short hash after the version.
  * `navigate`, `patch` or `href`: where the link goes; without one there is no link.
  * `label`: the text of the link (`"What's new"` when left out). `title`: its tooltip.
  * `status`: `:ok` (default, green dot), `:warning` or `:down`.

`footer: :version` without a `version` draws nothing. A `version` without `footer` shows the version line (as
in 0.15). `show_user={false}` is deprecated: it is `footer="none"`, or `"version"` when there is a `version`.
Collapsed to icons the line is the dot, centred, with the version and the build in its `title` and
`aria-label` (`"Version v1.4.2 (2a9f1c3)"`).

The kit does not read the version of your app: pass it, from `Application.spec/2`, in the layout.

    <.shell footer="version" version={%{version: "v" <> to_string(Application.spec(:my_app, :vsn)),
      build: "2a9f1c3", navigate: ~p"/changelog", label: "Novidades"}} …>

### The canvas "Painel" menu

Every format draws its items as a kit CSS `menu` (`ul.menu.menu-sm`, `li.menu-title` for labels, `menu-active`
on the active item, `menu-disabled` on a "soon" one), so the look follows the kit CSS theme. The `tree` format
has collapsible groups with a chevron (`aria-expanded`, `aria-controls`), items with `children` in a nested
`ul` (kit CSS's indent and line), `disabled` "soon" items and the mono `count` (a `badge`). Groups open and close in the browser; `persist_groups` keeps
which ones are open in `localStorage` (`linea-sidebar-groups:<id>`), so the next visit restores them.

    <.sidebar id="menu" format="tree" persist_groups match="prefix" current={@current_path}
      nav={[
        %{group: "Gestão", items: [
          %{label: "Tarefas", icon: "kanban", navigate: ~p"/app/tasks", count: 12,
            children: [%{label: "Minhas", navigate: ~p"/app/tasks/mine"}]},
          %{label: "Relatórios", icon: "chart", disabled: true, title: "Em breve"}
        ]}
      ]}>
      <:sidebar_footer>
        <button type="button" class="btn btn-ghost btn-sm justify-start" data-rail-toggle="menu">Recolher menu</button>
      </:sidebar_footer>
      <:mobile_drawer>
        <.link navigate={~p"/settings"} class="btn btn-ghost btn-sm justify-start">Configurações</.link>
        <.link href={~p"/sair"} method="delete" class="btn btn-ghost btn-sm justify-start">Sair</.link>
      </:mobile_drawer>
    </.sidebar>

The `:sidebar_footer` slot is in the foot of the menu, above the version line (`footer="version"`), so a
"Recolher menu" button (any element with `data-rail-toggle="<id of the menu>"`) and the version live together.
The `:mobile_drawer` slot (`.lu-sb-drawer`) is in the menu body and shows only below 768px, when the menu is
the top bar with a hamburger: put the search, settings, theme and logout there.

### Collapsing

In every format the menu collapses to icons (tooltips with the label, counts turn into dots). It uses the
`LedgerUI.ShellRail` hook of the framed menu: `collapsed` is the start, `on_collapse` is pushed with
`%{"id" => id, "collapsed" => boolean}`, the choice is kept in `localStorage` (`persist`) and
`<.rail_toggle for="sidebar" />` collapses it from anywhere, and so does Ctrl/⌘+B (`shortcut`, any key, or
`nil` to turn it off; it is left to fields and editors, where Ctrl+B is bold). The `tree` button, the panel button of the `rail`
(and a click on a module icon of a collapsed rail) do it by themselves; `sections` has no button of its own.
Below 768px the menu is a top bar with a hamburger that opens it under the bar.

### `<.sidebar>`

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` | `"sidebar"` |  |
| `format` | `:any` | `nil` | `sections`, `rail`, `tree` or `nested` (an atom works too). The `:shell` config `sidebar` when left out, else `sections`. |
| `nav` | `:list` | `nil` | The menu: a list of item and group maps. The `{module, function}` of the config when left out. |
| `current` | `:string` | `nil` | The current path; the item that goes there is active. |
| `brand` | `:map` | `nil` | `%{name, logo}` (`logo` is a letter, or `src` is an image URL); `switch: false` takes the company switcher out of `sections`, `switch: %{label, click}` gives it a label and a `phx-click`. In `nested`, `plan` is the line under the name and `menu` (a list, see "The nested format") makes the header open a team menu. |
| `user` | `:map` | `nil` | `%{name, email, initials, avatar, color}`: the avatar of the rail and the user card of the `tree`. `avatar` is an image URL, `color` the background of the initials. In `nested`, `menu` makes the user row at the foot open a menu. |
| `footer` | `:any` | `nil` | What the foot of the menu shows: `"user"`, `"version"` or `"none"` (an atom works too). The `:shell` config `footer` when left out, else each format's own (the user card of the `tree`, the plan card of `sections`, the avatar of the `rail`). |
| `show_user` | `:boolean` | `nil` | Deprecated, use `footer`. `false` is `footer="none"` (or `"version"` when there is a `version`). The `:shell` config `show_user` when left out. |
| `version` | `:any` | `nil` | The version of the system: a string (`"v1.4.2"`) or `%{version, build, href \| navigate \| patch, label, title, status}` (see "The foot"). The `:shell` config `version` when left out. |
| `plan` | `:map` | `nil` | `%{name, badge}`: the plan card of `sections`. |
| `trial` | `:map` | `nil` | `%{title, label, text, value, action, navigate}`: the trial card of the `rail` (`value` is the percentage of the bar; `action` is the link, to `navigate`, `patch` or `href`). |
| `rail_extra` | `:list` | `[]` | Extra apps of the rail, in coloured circles: `%{label, icon, color, navigate}` (`color` as in the items). |
| `collapsible` | `:boolean` | `true` | Shows the collapse button of the `tree` and of the `rail` panel. |
| `match` | `:string` | `"exact"` | `exact`, `prefix` — How `current` is compared with the items: `exact` (path and query) or `prefix` (the path or what is under it). An item's own `match` wins. |
| `persist_groups` | `:boolean` | `false` | Keeps which groups and items with children are open in `localStorage["linea-sidebar-groups:<id>"]` and restores them on the next visit. |
| `collapsed` | `:boolean` | `false` | Whether the menu starts collapsed to icons. |
| `persist` | `:boolean` | `true` | Keeps the choice in `localStorage["linea-rail"]`. |
| `on_collapse` | `:string` | `nil` | An event pushed with `%{"id" => id, "collapsed" => boolean}` when the choice changes. |
| `target` | `:any` | `nil` | The `phx-target` of `on_collapse`. |
| `shortcut` | `:string` | `"b"` | Ctrl/⌘ + this key collapses and expands the menu (opens it on a phone); `nil` turns it off. |
| `variant` | `:string` | `"floating"` | `floating`, `sidebar`, `inset` — `floating` is the card with corners and a shadow; `sidebar` sits flush with a line at its edge; `inset` sits on the page background, for a main area drawn as a card. |
| `label` | `:string` | `"Main menu"` | The accessible name of the menu. |
| `collapse_label` | `:string` | `"Collapse menu"` |  |
| `mobile_label` | `:string` | `"Menu"` | The accessible name of the hamburger. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:brand_mark>` — Replaces the logo and the name of the brand. (Not `:brand`: Phoenix does not allow a slot and an attribute with the same name, and `brand` is the map.)
- `<:mobile_drawer>` — Content of the menu body shown only below 768px (`.lu-sb-drawer`): search, settings, theme, logout.
- `<:sidebar_footer>` — At the end of the foot of the menu (the end of the panel in the `rail`).
