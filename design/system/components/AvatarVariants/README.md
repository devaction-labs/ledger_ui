# AvatarVariants

Combinações de avatar com texto: linha de pessoa, usuário do rodapé da sidebar.

**Grupo:** 06 · Exibição  
**Resumo visual:** Pessoa com nome e função; cartão de usuário do rodapé

## Uso (Phoenix / HEEx)

```heex
<.person name="Ikram Sakib" role="Head of Finance" />
```

## Regras

- Nome em 600, função em `muted`; truncar com reticências.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: avatar)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's avatars: an image or initials in a circle, a square, a squircle or any mask shape,
with a status dot, a gradient ring, and stacked in groups.

    <.avatar src="/images/jane.jpg" alt="Jane" />
    <.avatar initials="jd" color="primary" size="md" shape="square" />
    <.avatar initials="jd" color="info" variant="soft" />
    <.avatar src="/images/jane.jpg" size="lg" status="success" />
    <.avatar initials="jd" status="primary" status_position="bottom-left" ping />
    <.avatar src="/images/jane.jpg" gradient="sky-blue" size="lg" />

    <.avatar_group>
      <.avatar :for={user <- @users} src={user.photo} size="xs" ring />
    </.avatar_group>

    <.avatar src="/images/jane.jpg" size="2xs" ring={1} ring_color="primary" />
    <.avatar src="/images/jane.jpg" size="lg" face_class="border-2 border-white" />
    <.avatar src="/images/jane.jpg" status="success" status_position="bottom-right" />

The inner block, when given, replaces the initials (an icon, a counter). `icon` draws an icon on
the sunken face, for a record with no name or photo:

    <.avatar icon="huge-building-03" alt="Empresa" size="32" />

### People, companies and the assistant

`name` gives the initials (first and last word) and, with `color="auto"`, a color that is always
the same for the same name; `status` also takes the presence of a person, drawn at the bottom
right; `kind` draws a company, a customer, a supplier, the assistant or the "invite" placeholder;
`size` also takes the pixels, `"24"`, `"32"`, `"40"`, `"48"` and `"64"`:

    <.avatar name="Ana Souza" color="auto" size="40" status="online" />
    <.avatar kind="company" name="Farmácia Signetum" size="48" />
    <.avatar kind="assistant" size="32" />
    <.avatar kind="invite" size="40" />

    <.avatar_group more={3} size="32">
      <.avatar :for={user <- @users} name={user.name} color="auto" size="32" ring />
    </.avatar_group>

### `<.avatar>`

Renders an avatar.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `src` | `:string` | `nil` |  |
| `alt` | `:string` | `"avatar"` | The picture's text; the `name` when not given. |
| `initials` | `:string` | `nil` | Shown (upper-cased) when there is no `src`. |
| `name` | `:string` | `nil` | A person or company name: its first and last word give the initials when there are none, and `color="auto"` picks a color from it. |
| `icon` | `:string` | `nil` | A `LedgerUI.Components.Icon.icon/1` name drawn on the sunken face, for a record with no name or photo (a person, a company, a carrier). |
| `kind` | `:string` | `nil` | ``, `company`, `customer`, `supplier`, `assistant`, `invite` — `company`, `customer` and `supplier` are rounded squares in the navy, green and amber of their lists, with the initials; `assistant` is the indigo to purple gradient with a sparkle; `invite` is the dashed "add a person" placeholder. |
| `size` | `:string` | `"sm"` | `3xs`, `2xs`, `xs`, `xs-plus`, `sm`, `sm-plus`, `md`, `lg`, `xl`, `2xl`, `24`, `26`, `30`, `32`, `40`, `44`, `48`, `64` — `3xs` is size-6, `2xs` size-7, `xs` size-8, `xs-plus` size-9, `sm` size-10 (default), `md` size-12, `lg` size-16, `xl` size-20, `2xl` size-24. The pixel sizes are aliases: `24` is `3xs`, `32` is `xs`, `40` is `sm`, `48` is `md`, `64` is `lg`. `30` and `26` are the canvas `lu-av` (30px, 12px initials) and `lu-av sm` (26px, 10px initials), both semibold. |
| `shape` | `:string` | `"circle"` | `circle`, `square`, `rounded`, `squircle`, `reuleaux-triangle`, `diamond`, `hexagon`, `hexagon-2`, `octagon`, `star`, `star-2`, `heart` — `square` is Ledger UI's `rounded-lg`, `rounded` its `rounded-xl`; the others are masks. |
| `tint` | `:string` | `nil` | A CSS color for the initials' background (white text), for a person or company that keeps its own color; it wins over `color`. |
| `background` | `:string` | `nil` | Any CSS `background` for the initials' face (a gradient such as `"var(--grad)"`, or a colour), with white text like the canvas `lu-av`; it wins over `tint` and `color`. Put another text colour in `face_class`. |
| `color` | `:string` | `"neutral"` | `auto`, `neutral`, `primary`, `secondary`, `info`, `success`, `warning`, `error` — The initials' color; `auto` takes one of eight from the `name`, always the same for the same name (solid only). |
| `variant` | `:string` | `"solid"` | `solid`, `soft`, `bordered`, `skeleton` — How the initials are painted; `skeleton` is the grey placeholder. |
| `status` | `:any` | `nil` | ``, `false`, `neutral`, `primary`, `secondary`, `info`, `success`, `warning`, `error`, `online`, `away`, `busy`, `offline` — A status dot's color; `nil` or `false` shows no dot. Works the same on an image and on initials. `online` (green), `away` (amber), `busy` (red) and `offline` (grey) are a person's presence, at the bottom right unless `status_position` says otherwise. |
| `status_position` | `:string` | `nil` | ``, `top-right`, `top-left`, `bottom-right`, `bottom-left` — `top-right`, or `bottom-right` for a presence. |
| `ping` | `:boolean` | `false` | Animates the status dot with a ping. |
| `ring` | `:any` | `false` | `true`, `false`, `1`, `2`, `4`, `1`, `2`, `4` — The ring avatars wear inside a group. `true` is a 2px ring; `1`, `2` or `4` pick the width. |
| `ring_color` | `:string` | `"white"` | `white`, `panel`, `neutral`, `primary`, `secondary`, `info`, `success`, `warning`, `error` — `white` is white in light mode and the card color in dark mode; `panel` is the canvas surface color (`--panel`) in both. |
| `face_class` | `:any` | `nil` | Classes merged into the picture or initials face itself (a border, a shadow), while `class` goes on the wrapper. |
| `gradient` | `:string` | `nil` | ``, `sky-blue`, `amber-orange`, `pink-rose`, `purple-orange`, `green-fuchsia`, `purple-indigo`, `fuchsia-pink` — A gradient border around the avatar. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>`

### `<.avatar_group>`

Stacks avatars so they overlap, as Ledger UI's avatar group. Give the avatars `ring` so each
one is outlined against the next. The avatar under the pointer lifts 2px above its neighbors.

    <.avatar_group>
      <.avatar src="/a.jpg" size="xs" ring />
      <.avatar initials="jd" color="info" size="xs" ring />
    </.avatar_group>

`overlap="auto"` overlaps by a fifth of the `size`. Given the people that did not fit as
`hidden`, the "+N" avatar is a button that opens a popover listing them (the group needs an `id`):

    <.avatar_group id="team" size="32" overlap="auto" hidden={[%{name: "Carla Lima"}, %{name: "Bruno Melo"}]}>
      <.avatar name="Ana Souza" size="32" ring />
    </.avatar_group>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `pulse` | `:boolean` | `false` | Pulses the whole group, for skeletons. |
| `overlap` | `:string` | `"2"` | `2`, `3`, `7`, `auto` — How far the avatars overlap: `2` is `-space-x-2`, `3` is `-space-x-3`, `7` the canvas 7px, `auto` a fifth of the `size`. |
| `more` | `:integer` | `nil` | How many more people there are than avatars: draws a "+N" avatar at the end. |
| `hidden` | `:list` | `nil` | The people that did not fit, maps with `:name` and optionally `:src`: sets `more` to their number and the "+N" avatar opens a list of them. Needs the group's `id`. |
| `id` | `:string` | `nil` | Required with `hidden`. |
| `size` | `:string` | `"xs"` | `3xs`, `2xs`, `xs`, `xs-plus`, `sm`, `sm-plus`, `md`, `lg`, `xl`, `2xl`, `24`, `32`, `40`, `44`, `48`, `64` — The size of the "+N" avatar; give it the same `size` as the avatars. |
| `spread` | `:boolean` | `false` | The avatars move apart on hover or focus, so each one can be read (the group takes focus with the keyboard). |
| `ring_color` | `:string` | `"white"` | `white`, `panel` — The ring of the "+N" avatar; give it the same `ring_color` as the avatars. |
| `label` | `:string` | `nil` | The group's `aria-label` ("7 people"); it also makes the group a `role="group"`. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
