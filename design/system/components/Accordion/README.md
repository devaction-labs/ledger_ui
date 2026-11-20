# Accordion

Seções recolhíveis para FAQs e configurações longas.

**Grupo:** 12 · Sobreposições  
**Resumo visual:** variant advanced/basic/border-bottom/bordered/canvas/divided/primary · color (6)

## Uso (Phoenix / HEEx)

```heex
<.accordion id="faq"><:item title="…">…</:item></.accordion>
```

## Regras

- Use `<details>` nativo: teclado e leitor de tela de graça.
- Variante `sep` com cada item em seu painel.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: accordion)

Todos os function components, atributos, valores e slots que este componente cobre.

The accordion: a list of sections that open under their titles, in the design canvas look by default
(`variant="canvas"`). `variant="basic"` is the old Ledger UI default and the other Ledger UI styles are
border-bottom, bordered (full), divided items, primary and advanced.

    <.accordion id="faq" variant="bordered">
      <.accordion_item id="faq-1" title="Accordion Item 1" open>
        <p>Lorem ipsum dolor sit amet.</p>
      </.accordion_item>
      <.accordion_item id="faq-2" title="Accordion Item 2">…</.accordion_item>
    </.accordion>

    <.accordion id="help" variant="primary" color="warning">…</.accordion>

The `warning` header is too light for white text, so it uses a near-black text and chevron.

One section is open at a time; `multiple` lets them open independently (Ledger UI's Collapse
page). The `advanced` style puts a header of your own in each item, with the chevron button
at its end:

    <.accordion id="people" variant="advanced">
      <.accordion_item id="simon">
        <:header><.avatar …/> Simon Tods</:header>
        …
      </.accordion_item>
    </.accordion>

Each item is a `LedgerUI.Components.Collapse`: the browser owns which sections are open, the
server's `open` wins when it changes, `LedgerUI.open/close/toggle("faq-1")` work, and
`on_open` / `on_close` push `%{"id" => item_id}` when they are event names.

### `<.accordion>`

Groups accordion items and gives them their style.

    <.accordion id="faq" variant="divided" multiple>
      <.accordion_item id="q1" title="Question">Answer</.accordion_item>
    </.accordion>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `variant` | `:string` | `"canvas"` | `advanced`, `basic`, `border-bottom`, `bordered`, `canvas`, `divided`, `primary` — `canvas` (the default) is the design canvas accordion. The old Ledger UI look is `basic`; Ledger UI's sections: `basic`, `border-bottom`, `bordered` (full bordered), `divided` (items apart), `primary`, `advanced` (a header slot per item). |
| `color` | `:string` | `"primary"` | `primary`, `secondary`, `info`, `success`, `warning`, `error` — The `primary` style's frame, dividers and header fill: Ledger UI's blue by default, or any theme color (the Help page's yellow and sky frames). |
| `multiple` | `:boolean` | `false` | Sections open independently (Ledger UI's Collapse). |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)

### `<.accordion_item>`

A section of an accordion: its title (or `:header` in the `advanced` style) and its content.

    <.accordion_item id="q1" title="Accordion Item 1" on_open="q1-opened">
      <p>Lorem ipsum.</p>
    </.accordion_item>

Events: `on_open` and `on_close` push `%{"id" => id}` when they are event names.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `title` | `:string` | `nil` |  |
| `open` | `:boolean` | `false` |  |
| `on_open` | `:any` | `nil` | An event name or a `%JS{}`. |
| `on_close` | `:any` | `nil` | An event name or a `%JS{}`. |
| `target` | `:any` | `nil` |  |
| `toggle_label` | `:string` | `"Toggle"` | The accessible name of the `:header` chevron button. |
| `class` | `:any` | `nil` | Merged into the item. |
| `trigger_class` | `:any` | `nil` | Merged into the trigger (the `<summary>`), e.g. a smaller one in a narrow cell. |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:header>` — A header of your own, with the chevron button at its end (Ledger UI's Advanced).
- `<:inner_block>` (required)
