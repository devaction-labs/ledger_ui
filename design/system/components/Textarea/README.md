# Textarea

Texto de várias linhas com contador ao vivo, crescimento automático e variáveis de modelo destacadas.

**Grupo:** 03 · Formulários — texto  
**Resumo visual:** variant outlined · filled · plain × size · counter (normal, aviso, excedido, mínimo) · autogrow · resizable · tokens · header/footer · state

## Uso (Phoenix / HEEx)

```heex
<.textarea field={@form[:obs]} rows={4} maxlength={200} counter />
<.textarea field={@form[:msg]} tokens autogrow max_rows={8} />
<.textarea field={@form[:bio]} min_length={20} counter counter_format="%{count} de %{max}" />
```

## Regras

- Contador: avisa (âmbar) a partir de 90% do limite e fica vermelho ao passar.
- `autogrow` cresce com o texto até `max_rows`.
- `tokens` desenha `{{nome}}` em mono, apagado.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: textarea)

Todos os function components, atributos, valores e slots que este componente cobre.

kit CSS's textarea (`textarea`, `textarea-sm`, `textarea-lg`, `textarea-ghost`, `textarea-success`,
`textarea-error`): outlined or filled, fixed or resizable, and framed with a header or a footer (a title input,
a toolbar, a submit button).

    <.textarea name="bio" placeholder="Enter Text" />
    <.textarea field={@form[:bio]} label="Bio" variant="filled" resizable />

    <.textarea name="note" maxlength={200} counter autogrow max_rows={8} />
    <.textarea name="why" counter min_length={20} />

    <.textarea name="msg" tokens value="A fatura {{fatura.numero}} está {{diferenca.pct}} acima." />

    <.textarea name="post" rows={5} placeholder="Write the post">
      <:header>
        <.input name="title" variant="plain" class="p-3 text-lg font-medium" placeholder="Title" />
      </:header>
      <:footer>
        <span>…toolbar…</span>
        <.button color="primary" size="sm">Save Post</.button>
      </:footer>
    </.textarea>

### `<.textarea>`

Renders a `<textarea>`. With a `header` or `footer` slot it sits, borderless, inside a
bordered frame that lights up while it has focus.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` |  |
| `id` | `:string` |  | Defaults to the field's id. |
| `name` | `:string` |  | Defaults to the field's name. |
| `value` | `:any` |  |  |
| `rows` | `:integer` | `4` |  |
| `variant` | `:string` | `"outlined"` | `outlined`, `filled`, `plain` |
| `size` | `:string` | `"md"` | `sm`, `md`, `lg` — kit CSS's `textarea-sm`, default and `textarea-lg`. |
| `resizable` | `:boolean` | `false` |  |
| `counter` | `:boolean` | `false` | Shows a live character count under the text ("68 / 200" with `maxlength`, "2 / 20 mín." below `min_length`). It warns from 90% of the limit and turns red past it; it updates while typing, without the server. |
| `counter_format` | `:string` | `"%{count} / %{max}"` | The counter's text with a `maxlength`: `%{count}` and `%{max}` are replaced (`"%{count} de %{max}"` reads "58 de 300"). |
| `counter_align` | `:string` | `"end"` | `end`, `start` — `end` puts the counter at the right of the help line; `start` puts it right under the text, at the left, as a help line of its own. |
| `min_length` | `:integer` | `nil` | Minimum characters the counter asks for. Only the counter uses it: it blocks nothing. |
| `autogrow` | `:boolean` | `false` | The height follows the text, from `rows` up to `max_rows`. Not resizable by hand. |
| `max_rows` | `:integer` | `nil` | With `autogrow`, the most lines it grows to before it scrolls. |
| `tokens` | `:boolean` | `false` | Draws the `{{name}}` placeholders of the text in the mono face, muted (the template variables of a message). A mirror behind the same text, drawn on the server and kept by the `LedgerUI.TextareaTokens` hook, over a textarea whose own text is transparent: you type in a plain textarea. |
| `state` | `:string` | `nil` | ``, `success`, `error` |
| `label` | `:string` | `nil` | The caption. |
| `label_class` | `:any` | `nil` | Classes of the caption text. |
| `label_hint` | `:string` | `nil` | A dimmed note at the right of the caption, as the canvas's "opcional". |
| `help` | `:string` | `nil` | The small line under the control. |
| `errors` | `:list` | `[]` | Messages to show; `field` adds its own once the input was used. |
| `disabled` | `:boolean` | `false` |  |
| `wrapper_class` | `:any` | `nil` | Classes of the outer block (grid placement, spacing). |
| `frame_class` | `:any` | `nil` | Classes of the frame drawn around header/footer. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `autocomplete`, `autofocus`, `cols`, `form`, `maxlength`, `minlength`, `placeholder`, `readonly`, `required`, `wrap`.

Slots:

- `<:footer>` — Content below the text, laid out as a row with space between.
- `<:header>` — Content above the text, laid out as a row.
