# CodeBlock

Bloco de código com linguagem, copiar e realce de sintaxe na paleta da marca.

**Grupo:** 15 · IA  
**Resumo visual:** Bloco de código escuro com cabeçalho, copiar e realce

## Uso (Phoenix / HEEx)

```heex
<.code_block language="elixir" code={@code} />
```

## Regras

- Fundo escuro fixo nos dois temas; números de linha opcionais.
- Diff: linhas adicionadas/removidas em verde/rosa translúcido.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: code_block)

Todos os function components, atributos, valores e slots que este componente cobre.

Code, terminal output, logs and diffs in a quiet card: an optional header with a title and a copy button,
line numbers, wrapping, added, removed and highlighted lines, and a small size for tool output inside a
`trace/1`. It is the canvas's `CodeBlock`, in the spirit of the shadcn/ui Code Block.

    <.code_block id="install" title="Terminal" icon="huge-command-line" code={@output} line_numbers wrap />

### The code

`code` is a string, split into lines. `lines` is a list instead, each a string or a map with `:text` and
`:variant` (`"added"`, `"removed"` or `"highlighted"`), for a diff:

    <.code_block id="diff" title="mix.exs" lines={[
      "defp deps do",
      %{text: ~s(  {:phoenix, "~> 1.7"},), variant: "removed"},
      %{text: ~s(  {:phoenix, "~> 1.8"},), variant: "added"},
      "end"
    ]} />

`highlight` marks lines by number (`highlight={[2, 3]}`). A line's text is escaped; to show syntax colors pass
safe HTML, such as `Phoenix.HTML.raw(Makeup.highlight_inner_html(source))`, as the block: the block is drawn
as is, without line numbers.

Added and removed lines carry a `+` or `−` before the text, and line numbers sit in a gutter that grows
with the largest number (`start_line` is the first one). Both are drawn by CSS, so a selection copies the
code alone. The code itself always runs left to right.

### Header and actions

`title` (with an optional `icon`) puts a header above the code; it truncates. `copy` adds a copy button
(to the header, or floating at the top end on hover when there is no header) that copies the code without
the markers. The `:actions` slot adds buttons next to it and the `:footer` slot a row under the code (a
"Show more", say).

`size="sm"` is tighter and 12px, for tool output; `variant="destructive"` tints the card for errors and
failed output. A long block caps its height with `class="[&_pre]:max-h-64"` or `max_height`.

### `<.code_block>`

Renders the code block.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  | Needed by the copy button and to point at the code. |
| `code` | `:string` | `nil` | The code, split into lines. |
| `lines` | `:list` | `nil` | The lines: strings or maps with `:text` and `:variant` (added, removed, highlighted). |
| `highlight` | `:list` | `[]` | Line numbers drawn highlighted. |
| `title` | `:string` | `nil` | A filename or a label in the header. |
| `icon` | `:string` | `nil` | A `huge-*` icon before the title. |
| `copy` | `:boolean` | `false` | Adds a copy button. |
| `copy_label` | `:string` | `"Copy"` | The accessible name of the copy button. |
| `line_numbers` | `:boolean` | `false` |  |
| `start_line` | `:integer` | `1` | The number of the first line. |
| `wrap` | `:boolean` | `false` | Wraps long lines instead of scrolling. |
| `max_height` | `:integer` | `nil` | Caps the height of the code, in px; it scrolls past it. |
| `size` | `:string` | `"default"` | `default`, `sm` |
| `variant` | `:string` | `"default"` | `default`, `destructive` |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:actions>` — Buttons next to the copy button.
- `<:footer>` — A row under the code.
- `<:inner_block>` — Code as safe HTML (highlighted), drawn as is.
