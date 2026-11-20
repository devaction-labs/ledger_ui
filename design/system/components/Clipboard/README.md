# Clipboard

Copia um valor para a área de transferência e confirma no próprio botão (e por toast opcional).

**Grupo:** 02 · Ações  
**Resumo visual:** Botão copiar (color × variant × size, icon_only, copied) + ClipboardInput

## Uso (Phoenix / HEEx)

```heex
<.clipboard value="LDG-2026-1043" variant="soft" size="sm" />
<.clipboard from="#api-key" icon_only />
<.clipboard_input value={@api_key} label="Chave de API" />
```

## Regras

- Confirme a cópia no botão (“Copiado”) e, se `toast` estiver ligado, com um toast curto.
- `from` copia o valor de outro elemento; `icon_only` vira só o ícone com `aria-label`.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: clipboard)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's copy to clipboard: a button that copies a text, and a field with a copy button
joined to it.

    <.clipboard value="mix phx.new demo">Copy</.clipboard>
    <.clipboard from="#invite-link" size="xs">Copy</.clipboard>
    <.clipboard_input id="share" value={@url} />

`from` is a selector: a field gives its value, any other element its text. After a copy the
toaster shows `toast` (by default "Text Copied", or "Texto copiado" with `locale="pt_BR"`, in the
success color, as Ledger UI does), the button keeps `data-copied` for two seconds (style it with
`data-copied:`) and `on_copy` runs; a copy that fails shows `error_toast`. With `copied_label` the
button says it ("Copiado") for those two seconds:

    <.clipboard value="mix phx.new demo" copied_label="Copied">Copy</.clipboard>
    <.clipboard value={@pix} locale="pt_BR" variant="soft" icon copied_label="Copiado">Copiar Pix</.clipboard>

`icon` puts a copy icon before the text (a check while copied) and `icon_only` makes the round
canvas icon button (`lu-ib`) of it, for a value already on screen:

    <.clipboard value="mix phx.new demo" icon copied_label="Copied">Copy</.clipboard>
    <.clipboard from="#cmd" icon_only variant="flat" size="sm" aria-label="Copy command" />

`copied` renders the button already in its copied state (until the next copy ends), to show it.

With `on_copy` as an event name the LiveView (or `target`) gets
`handle_event(name, %{"id" => id}, socket)`.

### `<.clipboard>`

A button that copies `value`, or what `from` points at.

Events: `on_copy` pushes `%{"id" => id}` when it is an event name.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  | Needed by the hook. |
| `value` | `:string` | `nil` | The text to copy. |
| `from` | `:string` | `nil` | A selector of the field or element whose text is copied. |
| `locale` | `:string` | `"en"` | `en`, `pt_BR` — The language of the default `toast`, `error_toast` and label. |
| `toast` | `:any` | `:default` | Shown after a copy; `nil` or `""` for none. By default the `locale`'s "Text Copied" / "Texto copiado". |
| `error_toast` | `:string` | `nil` | Shown when the copy fails; by default the `locale`'s "Error" / "Erro ao copiar". |
| `copied` | `:boolean` | `false` | Renders the button in its copied state (`data-copied`), as after a copy. |
| `on_copy` | `:any` | `nil` | An event name or a `%JS{}`. |
| `target` | `:any` | `nil` |  |
| `copied_label` | `:string` | `nil` | The text the button shows for the two seconds after a copy (the canvas's "Copiado" state, with the check when `icon`); `nil` leaves the button as it is, for you to style with `data-copied:`. |
| `icon` | `:boolean` | `false` | A copy icon before the text, which becomes a check for the two seconds after a copy. |
| `icon_only` | `:boolean` | `false` | Just the icon, the round canvas icon button (`lu-ib`; `size` `xs`/`sm` is the small one, `flat` the borderless one); give it an `aria-label`. After a copy it shows the check. |
| `color` | `:string` | `"primary"` | `neutral`, `primary`, `secondary`, `info`, `success`, `warning`, `error` |
| `variant` | `:string` | `"solid"` | `solid`, `glow`, `outline`, `soft`, `bordered`, `flat` |
| `size` | `:string` | `"md"` | `xs`, `sm`, `md`, `lg`, `xl` |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>`

### `<.clipboard_input>`

Ledger UI's "Advanced Usage": a text field with a copy button joined to its end. The field is a
real input (`name`, `value`, `phx-change` work), and the button copies what it holds.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `name` | `:string` | `nil` |  |
| `value` | `:string` | `nil` |  |
| `placeholder` | `:string` | `nil` |  |
| `label` | `:string` | `nil` | The button's text; by default the `locale`'s "Copy" / "Copiar". |
| `copied_label` | `:string` | `nil` | What the button says, in the success color, for the two seconds after a copy. |
| `icon` | `:boolean` | `false` | A copy icon before the label. |
| `locale` | `:string` | `"en"` | `en`, `pt_BR` — The language of the default `label`, `toast` and `error_toast`. |
| `toast` | `:any` | `:default` | Shown after a copy; `nil` or `""` for none. By default the `locale`'s text. |
| `error_toast` | `:string` | `nil` |  |
| `on_copy` | `:any` | `nil` |  |
| `target` | `:any` | `nil` |  |
| `class` | `:any` | `nil` | Merged into the wrapper. |

Any other HTML/phx attribute goes to the root element, including `readonly`, `disabled`, `phx-debounce`, `autocomplete`, `form`.
