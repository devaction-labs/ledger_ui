# ThemeSwitch

Alterna entre tema claro, escuro e o do sistema.

**Grupo:** 14 · Temas e marca  
**Resumo visual:** variant segmented · icons · switch · size md/sm

## Uso (Phoenix / HEEx)

```heex
<.theme_switch />
<!-- grava em localStorage "phx:theme" e aplica data-theme no <html> -->
```

## Regras

- Na barra: botão quadrado lua/sol. Em configurações: segmentado com 3 opções.
- Todas as cores vêm de tokens; nada de `dark:` por componente.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: theme_switch)

Todos os function components, atributos, valores e slots que este componente cobre.

The light / dark / system choice of the canvas "ThemeSwitch" board, wired to the kit's dark mode.

    <.theme_switch id="theme" />
    <.theme_switch id="theme" variant="icons" size="sm" />
    <.theme_switch id="theme" variant="switch" />
    <.theme_switch id="theme" system={false} light_label="Claro" dark_label="Escuro" />

`variant` is `"segmented"` (icon and label in kit CSS's `tabs tabs-box`: a grey track with the choice in white),
`"icons"` (the same with the labels visually hidden, for a top bar) or `"switch"` (kit CSS's `toggle` with a sun
and a moon: on is dark). `size="sm"` is the compact
one; `system={false}` leaves only light and dark.

The segmented and icons variants are a `radiogroup` of `radio` buttons (arrow keys move the choice); the switch is
one `switch` button. The labels are the accessible names (`label` names the group or the switch).

### What it does

The `LedgerUI.ThemeSwitch` hook (register the kit's hooks) reads the stored choice, puts the `dark` class on
`<html>` and keeps `data-value` / `aria-checked` in step. A click stores the choice in `localStorage["theme"]`
(`"light"`, `"dark"` or `"system"`) and the dark mode it resolves to in `localStorage["dark-mode"]`, the key
`theme_toggle/1` uses, so both agree. "System" follows `prefers-color-scheme` live. Every `theme_switch` and
`theme_toggle` on the page listens to the same `change:darkmode` window event and follows. Put `<.theme_script />`
in the root layout's `<head>` so the first paint already has the theme.

The server renders the light choice; the hook owns `data-value`, `aria-checked` and `tabindex`, and
`phx-mounted={JS.ignore_attributes(...)}` keeps a LiveView patch from resetting them.

### `<.theme_switch>`

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `variant` | `:string` | `"segmented"` | `segmented`, `icons`, `switch` — `segmented` (icons and labels), `icons` (icons only) or `switch` (sun/moon). |
| `size` | `:string` | `"md"` | `md`, `sm` |
| `system` | `:boolean` | `true` | Offer "system"; `false` leaves light and dark. |
| `light_label` | `:string` | `"Light"` |  |
| `dark_label` | `:string` | `"Dark"` |  |
| `system_label` | `:string` | `"System"` |  |
| `label` | `:string` | `nil` | Names the group (default `"Theme"`) or the switch (default `"Dark mode"`). |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.
