# Icon

Conjunto de ícones do kit: Hugeicons Stroke Rounded, traço 1,5 px, herdando a cor do texto.

**Grupo:** 01 · Fundamentos  
**Resumo visual:** tone neutral/accent/success/warning/error/info

## Uso (Phoenix / HEEx)

```heex
<.icon name="hugeicons:analytics-up" class="size-[18px]" />
<!-- HTML puro --> <i data-i="trend-up"></i> + LedgerUI.hydrate()
```

## Regras

- Fonte oficial: hugeicons.com/icons/stroke-rounded (pacote @hugeicons/core-free-icons).
- Tamanho padrão 18px em navegação, 16px dentro de botões, 14px em badges.
- Ícones herdam `currentColor`; ícone decorativo fica `aria-hidden`, botão só-ícone recebe `aria-label`.
- Em caixa (`.lu-ic`) o fundo segue o estado: acc, pos, neg, warn, info, lime.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: icon)

Todos os function components, atributos, valores e slots que este componente cobre.

Icons: Hugeicons Stroke Rounded by name, and the small glyphs Ledger UI's own components draw (the cross of a
toast, the chevron of a select, the check of a checkbox, the tools of the text editor).

    <.icon name="huge-search-01" class="size-4" />
    <.glyph name={:chevron_down} class="size-4" />

`boxed` puts the icon in the canvas icon box (`lu-ic`, 36px with 11px corners), `tone` colours the box by state:

    <.icon name="huge-tick-02" boxed tone="success" />
    <.icon name="huge-file-01" boxed box_size="sm" />

A box can hold an SVG of its own (the inner block replaces `name`), in any size in pixels and with the
canvas tone names (`acc`, `pos`, `neg`, `warn`, `info`):

    <.icon boxed tone="acc" box_size="30">
      <svg viewBox="0 0 24 24" class="size-4"><path d="M5 12l5 5 9-10" /></svg>
    </.icon>

`icon/1` draws `huge-*` classes from Hugeicons (the free Stroke Rounded set, which the app vendors with
`mix ledger_ui.icons sync` (or `get NAME`, `search TERM`, `update`; `--dir`, `--ref`) and
`assets/css/hugeicons.cjs` turns into classes; see the README) and passes any other class name through, so
`name="fa-solid fa-house"` works with Font Awesome. Write the name in full, never interpolated, or Tailwind
cannot see the class.

`glyph/1` is for the components: it draws Ledger UI's own SVG by default and the matching Hugeicons icon when the
app sets

    config :ledger_ui, :icons, :hugeicons

The setting is read when the page renders; the hooks that draw glyphs in the browser read it from the
`data-icons` attribute of their element (see `icon_set/0`). The table below is mirrored in
`assets/js/ledger_ui/lib/glyphs.js` for the glyphs those hooks draw, and a test keeps the two equal.

The big two-tone icons of the sidebar, the arrows of tooltips and popovers and the spinner are artwork, not
glyphs, and stay as they are in every set.

### `<.icon>`

A Hugeicons icon by class name, or any other icon font class.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `name` | `:string` | `nil` | `huge-search-01`, or any class such as `fa-solid fa-house`. Not needed when the inner block draws the icon. |
| `class` | `:any` | `nil` | Classes of the icon itself; `size-5` when none is given (`size-4` inside a box). |
| `boxed` | `:boolean` | `false` | Draws the icon in the canvas icon box: 36px, 11px corners, the sunken fill with a 1px line. |
| `tone` | `:string` | `nil` | ``, `neutral`, `accent`, `success`, `warning`, `error`, `info`, `acc`, `pos`, `neg`, `warn` — Colours the box (and boxes the icon): the tint of that state with the icon in its colour. `acc`, `pos`, `neg` and `warn` are the canvas names of `accent`, `success`, `error` and `warning`. |
| `box_size` | `:any` | `"lg"` | The box: `lg` 36px (11px corners), `md` 28px (9px corners, a timeline point), `sm` 24px (a tree row), or any size in pixels (`"30"`, `32`) with corners of 30% of it. |
| `box_class` | `:any` | `nil` | More classes of the box. |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` — Your own icon (an SVG) inside the box, instead of `name`.

### `<.glyph>`

One of the glyphs Ledger UI's components draw, in the icon set of the app.

    <.glyph name={:chevron_down} class="size-4" />
    <.glyph name={:calendar} class="size-5" stroke_width="1.5" />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `name` (required) | `:atom` |  | `close`, `bell`, `check`, `editor_align_justify`, `editor_picker_color`, `editor_underline`, `calendar`, `editor_picker_align`, `carousel_arrow`, `editor_align_left`, `apps`, `editor_mark`, `angle_right`, `chevron_right_solid`, `chevron_down`, `editor_clean`, `editor_script_super`, `editor_indent_minus1`, `editor_header_1`, `angle_left`, `editor_code`, `moon`, `error_circle`, `close_solid`, `editor_variable`, `chevron_right`, `editor_bold`, `chevron_up`, `check_circle`, `chevron_down_solid`, `editor_direction_active`, `editor_strike`, `editor_script_sub`, `dots_horizontal`, `editor_list_bullet`, `editor_direction`, `editor_list_ordered`, `editor_image`, `editor_dropdown`, `chevron_left`, `sun`, `minus`, `editor_header_2`, `info_circle`, `editor_blockquote`, `dots_vertical`, `editor_italic`, `editor_code_block`, `filter`, `search_solid`, `search`, `editor_align_center`, `editor_link`, `warning`, `plus`, `editor_indent_plus1`, `clock`, `editor_align_right`, `editor_picker_background` |
| `class` | `:any` | `"size-4"` |  |
| `stroke_width` | `:any` | `"2"` | Only for Ledger UI's stroked SVGs; Hugeicons draw their own. |

Any other HTML/phx attribute goes to the root element.
