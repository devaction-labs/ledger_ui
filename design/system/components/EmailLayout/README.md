# EmailLayout

Layout de e-mail (resumo semanal, alertas) com a mesma linguagem visual.

**Grupo:** 13 · Estrutura e shell  
**Resumo visual:** theme auto/light/dark · button accent/ink · footer panel/plain · variant panel/table

## Uso (Phoenix / HEEx)

```heex
<.email_layout title="Resumo de outubro">…</.email_layout>
```

## Regras

- Largura 600, tabelas para compatibilidade; cores em hex fixo do tema claro.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: email)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's transactional e-mail: one layout for the e-mails a system sends (a sign-in code, a reset link, an
order update): the logo, a card with an icon badge, an eyebrow, a title, text, a block of code, facts or steps,
a main button with its address spelled out, a note (with an optional 16px `icon` image) and a footer, set
16px under the card. 520px wide.

    <.email_layout subject="Your code" preheader="Valid for 10 minutes" brand="Acme" logo_url="https://acme.com/logo.png"
                   eyebrow="Confirm your access" title="Your verification code">
      <:badge><img src="https://acme.com/mail/envelope.png" width="24" height="24" alt="" /></:badge>
      <:body>
        <p>Hi <b>Ana</b>. Type this code on the sign-in screen. It is valid for 10 minutes.</p>
        <.email_code value="482913" />
      </:body>
      <:action href="https://app.acme.com/confirm?token=7f3a9c">Sign in</:action>
      <:note>Not you? Ignore this e-mail: nobody signs in without the code.</:note>
      <:footer>Acme Ltda · Main Street, 100</:footer>
    </.email_layout>

It renders a whole HTML document built for mail clients: tables for the structure, every style inline,
web-safe font stacks, no script and no stylesheet that matters. The only `<style>` carries the resets, the
mobile padding and the dark mode: with `theme={:auto}` (the default) the e-mail follows the reader's
`prefers-color-scheme`, `:light` and `:dark` fix it. Every color is also on a hook class (`em-*`) that the
dark block overrides with `!important`.

Icons and logos are images (`<img>` with an absolute URL): mail clients do not draw SVG or icon fonts.

### Helpers

  * `email_code/1`: a verification code, one box per character.
  * `email_facts/1`: label and value rows in a panel; a row can be `:mono` (a tracking number) or `:total`.
  * `email_steps/1`: a row of steps, done or to come (paid, shipped, delivered).

Use them inside the `:body` slot, with `email_p/1` for the paragraphs. They draw the light palette and the
dark block restyles them; when the layout has a fixed `theme={:dark}`, pass `theme={:dark}` to them too.

Deliver it as the `html_body` of your mailer (`Phoenix.HTML.Safe.to_iodata/1` of the rendered component, or
`Phoenix.Template.render_to_string/4` with a template that calls it).

### `<.email_layout>`

The e-mail: a whole HTML document.

`eyebrow` is the short tag above the title. The `:action` slot is the main button (`href` required) and the
address is spelled out under it, for the clients that block buttons. `alt_text` introduces that address;
`alt_text={nil}` leaves the address out.

The canvas look of a short notice: `button="ink"` (a black pill with no arrow), `footer_style="plain"`
(centered small print under the card), `title_size={18}` and `compact` (tighter padding).

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `subject` (required) | `:string` |  | The `<title>`, and what the inbox shows. |
| `preheader` | `:string` | `nil` | The line next to the subject in the inbox. |
| `brand` | `:string` | `nil` | The name beside the logo. |
| `logo_url` | `:string` | `nil` | Absolute URL of the logo. |
| `logo_dark_url` | `:string` | `nil` | Absolute URL of the logo for dark backgrounds. |
| `eyebrow` | `:string` | `nil` |  |
| `title` (required) | `:string` |  |  |
| `theme` | `:atom` | `:auto` | `auto`, `light`, `dark` |
| `lang` | `:string` | `"en"` |  |
| `alt_text` | `:any` | `"If the button does not work, copy and paste this address into your browser:"` | The line before the spelled-out address (a string); `nil` leaves both out. |
| `button` | `:string` | `"accent"` | `accent`, `ink` — `accent` is the teal button with an arrow; `ink` the black pill of the canvas, no arrow. |
| `footer_style` | `:string` | `"panel"` | `panel`, `plain` — `panel` is a grey box under the card; `plain` centered faint small print. |
| `title_size` | `:integer` | `22` | The title's size in pixels. |
| `compact` | `:boolean` | `false` | Tighter padding around and inside the card (20px and 22px). |

Slots:

- `<:action>` — attrs: `href` — The main button; the label is the content.
- `<:badge>` — The inside of the icon tile: an `<img>` of 24px.
- `<:body>` (required) — The text and the helpers.
- `<:footer>` — Under the card: who sends this and why.
- `<:note>` — attrs: `icon` — A line of small print in a panel: the validity, or what to do if it was not you.
- `<:secondary>` — attrs: `href` — A quiet outlined button beside the main one ("View order" next to "Track delivery"); the label is the content.

### `<.email_p>`

A paragraph of the body, styled for the e-mail. Give the same `theme` as the layout when it is fixed.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `theme` | `:atom` | `:auto` | `auto`, `light`, `dark` |
| `muted` | `:boolean` | `false` | The canvas's quiet summary line: 13.5px in the muted color. |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.email_code>`

A verification code, one box per character.

    <.email_code value="482913" hint="Or sign in with one tap:" />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `value` (required) | `:string` |  |  |
| `hint` | `:string` | `nil` |  |
| `theme` | `:atom` | `:auto` | `auto`, `light`, `dark` |

### `<.email_facts>`

Rows of label and value in a panel. A row is `{label, value}`, or `{label, value, :mono}` for a code or a
tracking number, or `{label, value, :total}` for the highlighted last line.

    <.email_facts rows={[{"Estimate", "Thu, Oct 29"}, {"Tracking", "BR482913077XY", :mono}, {"Total", "R$ 1.284,90", :total}]} />

`variant="table"` is the canvas table: no panel, a rule between rows, the label in the body color and the
value in ink, with an optional `header` row of column names in faint small print.

    <.email_facts variant="table" header={{"Indicator", "Value"}} rows={[{"Sales", "R$ 41,2 mil", :mono}]} />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `rows` (required) | `:list` |  |  |
| `theme` | `:atom` | `:auto` | `auto`, `light`, `dark` |
| `variant` | `:string` | `"panel"` | `panel`, `table` — `panel` is the grey box; `table` the open table of the canvas. |
| `header` | `:any` | `nil` | A `{label, value}` pair of column names, a header row over the rows. |

### `<.email_steps>`

A row of steps: `{label, done?}` pairs, in order. Done ones are filled with a check.

    <.email_steps steps={[{"Paid", true}, {"Shipped", true}, {"Delivered", false}]} />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `steps` (required) | `:list` |  |  |
| `theme` | `:atom` | `:auto` | `auto`, `light`, `dark` |
