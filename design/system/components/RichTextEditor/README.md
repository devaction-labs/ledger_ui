# RichTextEditor

Editor de texto rico com barra de formatação compacta.

**Grupo:** 03 · Formulários — texto  
**Resumo visual:** variant default/comment · barra · links · listas

## Uso (Phoenix / HEEx)

```heex
<.rich_text_editor field={@form[:body]} toolbar={[:bold, :italic, :list, :link]} />
```

## Regras

- Barra com ícones de 30px; estado ativo em `bg-selected`.
- Rodapé opcional com anexos e ação de envio.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: text_editor)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's rich text editor (Quill's snow toolbar in Ledger UI's skin) on a plain
`contenteditable`: bold, italic, underline, strike, quote, code, headings, lists,
sub/superscript, indent, text direction, size, font, colors, alignment, links and clean.

    <.text_editor field={@form[:body]} placeholder="Enter your content..." />
    <.text_editor name="note" toolbar={[~w(bold italic underline), ~w(list-ordered list-bullet header-1 background)]} />
    <.text_editor name="post" filled content_class="h-72" />

The HTML of the text is submitted through a hidden input named like the field, and each edit
fires a bubbling `input` event, so `phx-change` runs. The editor cleans the HTML it is given
and the HTML it pastes (only formatting tags and safe links stay), but the server should still
sanitize what it stores. A value sent by the server replaces the text; the same value echoed
back does not touch it.

### Commands, variables, the assistant and a footer

`slash` opens a menu of blocks when "/" is typed at the start of a word (text, headings, lists,
quote, code, divider) and `variables` adds the placeholders of a template to it: `{cliente}` is
drawn as a chip in the editor and goes to the server as the plain text `{cliente}`. The `:ai` slot
is a button at the end of the toolbar (`on_ai` is pushed with the HTML and the selected text; answer
with `insert_html/3`), and `footer` draws a bar with a hint and the word count:

    <.text_editor field={@form[:description]} slash variables={~w(cliente preço)} footer
      hint="Markdown shortcuts work. / opens the commands" on_ai="write">
      <:ai>Write with the assistant</:ai>
    </.text_editor>

The menu takes commands of your own: an entry of `slash_items` whose `key` is not one of the blocks
is pushed to `on_slash` with that key (the "/" text is removed first), and `hint` is the line after its label:

    <.text_editor name="post" slash on_slash="slash"
      slash_items={[%{key: "paragraph", label: "Text"}, %{key: "image", label: "Image", hint: "Upload a picture", icon: "▣"}]} />

    def handle_event("slash", %{"id" => id, "key" => "image"}, socket), do: ...

### Image, variable and highlight buttons

Three toolbar buttons are opt-in (the default toolbar does not have them), added to a group of `toolbar`:

    <.text_editor name="post" variables={~w(cliente preço)}
      toolbar={[~w(bold italic mark), ~w(link image variable)]} />

  * `mark` toggles a `<mark>` around the selection (the highlight; pressed while the caret is in one).
    It is styled by `.ql-editor mark`, so rendering the saved HTML inside a `ql-editor` element draws it too,
    in dark mode as well.
  * `variable` opens a menu of `variables` at the caret and inserts the chosen `{name}` as a chip, like the
    "/" menu does; it is disabled while `variables` is empty.
  * `image` opens a small field for the address and the description of a picture and inserts an `<img src alt>`.
    With `on_image` set no field opens: the event is pushed with `%{"id" => id}` so the app can upload the file,
    and answers with `insert_image/4`:

        <.text_editor id="post" name="post" on_image="image" toolbar={[~w(bold image)]} />

        def handle_event("image", %{"id" => id}, socket),
          do: {:noreply, TextEditor.insert_image(socket, id, ~p"/uploads/photo.png", "A photo")}

An `<img>` is kept by the HTML cleaning only in an editor with the image button, `on_image` or `images`, and
only with an `http(s)` or relative `src` (never `data:`, `javascript:` or `//host`), a `width` and `height` of
1 to 4000 pixels and an `alt` of up to 300 characters. `<mark>` is kept everywhere. The names of the buttons
come from `tool_labels` (`%{"image" => "Imagem", "variable" => "Variável", "mark" => "Destacar"}`).

### Showing saved text

`text_editor_content/1` draws saved HTML read-only, in the editor's type (14px on 22px lines, lists and marks
as in the editor), for a page that shows what someone wrote. It takes the markup as its inner block, or `value`:
a string is escaped and shown as text; pass `{:safe, html}` (or `Phoenix.HTML.raw/1`) only for HTML your server
has sanitized.

    <.text_editor_content value={Phoenix.HTML.raw(@sanitized_body)} />
    <.text_editor_content><p>Olá, <strong>Joel</strong>!</p></.text_editor_content>

### Comments

`variant="comment"` is the compact editor of a thread: no toolbar, a bar with a "mention" button,
the `:actions` slot (an attach button) and the submit button; Ctrl+Enter (or Cmd+Enter) submits,
and "@" opens the list of `mentions`, each drawn as a chip and sent as `@handle`:

    <.text_editor name="comment" variant="comment" on_submit="comment"
      mentions={[%{handle: "juliana-moraes", label: "Juliana Moraes"}]}
      placeholder="Write a comment" />

    def handle_event("comment", %{"value" => html, "mentions" => handles}, socket), do: ...

### `<.text_editor>`

Renders a rich text editor.

    <.text_editor id="post" name="post[body]" placeholder="Enter your content..." filled />

`toolbar` is a list of groups, each a list of tools: `bold italic underline strike blockquote
code-block code header-1 header-2 list-ordered list-bullet script-sub script-super
indent-minus1 indent-plus1 direction-rtl link image variable mark clean` (buttons) and `size
header color background font align` (pickers). The default is Ledger UI's full toolbar, without
`image`, `variable` and `mark`: those are buttons you add yourself.

Events: `on_change` is pushed with `%{"id" => id, "value" => html}` after edits (debounced by
`debounce` ms), to `target` or to the LiveView/LiveComponent the editor is in.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` |  | Defaults to the field id, or a generated one. |
| `name` | `:string` |  | Defaults to the field name. |
| `value` | `:string` |  | The HTML of the text; defaults to the field value. |
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` |  |
| `label` | `:string` | `nil` |  |
| `help` | `:string` | `nil` |  |
| `errors` | `:list` | `[]` |  |
| `placeholder` | `:string` | `nil` |  |
| `toolbar` | `:list` | `[["bold", "italic", "underline", "strike"], ["blockquote", "code-block"], ["header-1", "header-2"], ["list-ordered", "list-bullet"], ["script-sub", "script-super"], ["indent-minus1", "indent-plus1"], ["direction-rtl"], ["size"], ["header"], ["color", "background"], ["font"], ["align"], ["clean"]]` | Groups of tool names, see above. |
| `filled` | `:boolean` | `false` | The toolbar on a filled background (Ledger UI's Filled Header). |
| `content_class` | `:any` | `"h-48"` | Classes of the text area, its height above all. |
| `link_label` | `:string` | `"Enter link:"` |  |
| `tool_labels` | `:map` | `%{}` | The accessible names of the buttons by tool, e.g. `%{"mark" => "Destacar"}`; the others keep their English name. |
| `on_image` | `:string` | `nil` | The event the `image` button pushes, with `%{"id" => id}`, instead of opening the address field; answer with `insert_image/4`. |
| `images` | `:boolean` | `false` | Keeps `<img>` in the HTML the editor loads and pastes. On by itself with the `image` button or `on_image`. |
| `image_label` | `:string` | `"Image URL:"` |  |
| `image_alt_label` | `:string` | `"Description"` |  |
| `image_save_label` | `:string` | `"Insert"` |  |
| `save_label` | `:string` | `"Save"` |  |
| `disabled` | `:boolean` | `false` |  |
| `on_change` | `:string` | `nil` |  |
| `debounce` | `:integer` | `300` |  |
| `target` | `:any` | `nil` |  |
| `variant` | `:string` | `"default"` | `default`, `comment` — `comment` is the compact editor of a thread: no toolbar, a bar under the text with the mention button, the `:actions` and the submit button. |
| `slash` | `:boolean` | `false` | Typing "/" at the start of a word opens the menu of blocks (and the `variables`). |
| `slash_items` | `:list` | `[%{label: "Text", key: "paragraph", hint: "Plain paragraph", icon: "¶"}, %{label: "Heading 1", key: "h1", hint: "Big section title", icon: "H1"}, %{label: "Heading 2", key: "h2", hint: "Medium section title", icon: "H2"}, %{label: "Bulleted list", key: "bullet", hint: "A simple list", icon: "•"}, %{label: "Numbered list", key: "ordered", hint: "A list with order", icon: "1."}, %{label: "Quote", key: "quote", hint: "Highlight a passage", icon: "❝"}, %{label: "Code block", key: "code", hint: "Monospaced text", icon: "</>"}, %{label: "Divider", key: "divider", hint: "A horizontal rule", icon: "—"}]` | The entries of the menu: maps with `key` (`paragraph h1 h2 bullet ordered quote code divider`), `label`, and optionally `hint` (a line after the label) and `icon` (a short text). Any other `key` is a custom command: choosing it removes the typed "/…" and pushes `on_slash` with that key. |
| `on_slash` | `:string` | `nil` | The event a custom entry of the "/" menu pushes, with `%{"id" => id, "key" => key}`; answer with `insert_html/3` if the command inserts something. |
| `slash_title` | `:string` | `"Insert"` | The caption of the "/" menu. |
| `variables` | `:list` | `[]` | Names of the placeholders of a template (`["cliente"]`): `{cliente}` is shown as a chip, sent as plain text, and offered in the "/" menu. |
| `variable_label` | `:string` | `"Variable"` | The hint of a variable in the menu. |
| `variable_title` | `:string` | `"Insert variable"` | The caption of the menu the `variable` button opens. |
| `mentions` | `:list` | `[]` | People that "@" can mention: maps with `handle` and `label`. A mention is a chip, sent as `@handle`. |
| `mention_title` | `:string` | `"Mention someone"` | The caption of the "@" menu. |
| `mention_button` | `:boolean` | `true` | The "@" button of a comment's bar (when there are `mentions`); typing "@" works without it. |
| `mention_label` | `:string` | `"Mention"` | The label of the mention button of a comment. |
| `on_ai` | `:string` | `nil` | The event the `:ai` button pushes, with `%{"id" => id, "value" => html, "selection" => text}`; answer with `insert_html/3`. |
| `on_submit` | `:string` | `nil` | The event Ctrl+Enter (and a comment's button) pushes, with `%{"id" => id, "value" => html, "mentions" => handles}`. |
| `submit_label` | `:string` | `"Comment"` |  |
| `bar` | `:boolean` | `true` | A comment's bar (mention, `:actions`, submit). `false` leaves only the text box, as a reply field in a thread; Ctrl+Enter still submits. |
| `submit_key` | `:any` | `"Ctrl ↵"` | The shortcut shown next to a comment's button (a string); `nil` hides it. |
| `clear_on_submit` | `:boolean` | `true` | Empties the editor after it submits. |
| `footer` | `:boolean` | `false` | A bar under the text with the `hint` and the word count. |
| `hint` | `:string` | `nil` | The text at the start of the footer. |
| `words_label` | `:string` | `"words"` | The word after the count in the footer. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:actions>` — The buttons of a comment's bar, before the submit button (attach...).
- `<:ai>` — The content of a button at the end of the toolbar that asks the assistant (`on_ai`).
- `<:attachments>` — What a comment carries (files as `<.chip>`), between the text and the bar.

### `<.text_editor_content>`

Renders saved rich text, read-only. See "Showing saved text" above: `value` is escaped unless it is already
marked safe, so only sanitized HTML should be passed as `{:safe, html}`.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `value` | `:any` | `nil` | The text: a string (escaped) or sanitized HTML marked safe. The inner block wins. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>`
