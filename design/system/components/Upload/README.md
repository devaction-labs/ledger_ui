# Upload

Envio de arquivos: zona de soltar + lista com progresso por arquivo.

**Grupo:** 05 · Formulários — datas e valores  
**Resumo visual:** zona de soltar (normal, arrastando, erro) · lista com progresso, concluído e falha · compacto · botão

## Uso (Phoenix / HEEx)

```heex
<.upload upload={@uploads.notas} label="Notas fiscais" accept=".pdf,.xml" max_entries={10} />
<.upload upload={@uploads.logo} variant="button" />
```

## Regras

- Arrastando por cima: borda teal e fundo suave.
- Cada arquivo mostra a barra até concluir; falha fica vermelha e pede para tentar de novo.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: upload)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's file uploads, built on LiveView uploads: the drop panel of its FilePond demos
(bordered, filled, in a grid, or a round avatar drop) with each file's progress, errors and
cancel button, and the styled "Choose File" buttons of its Input File demo.

    # mount
    socket |> allow_upload(:photos, accept: ~w(.jpg .png), max_entries: 4)

    <.form for={@form} phx-change="validate" phx-submit="save">
      <.upload upload={@uploads.photos} on_cancel="cancel-upload" bordered columns={2} />
    </.form>

    def handle_event("cancel-upload", %{"ref" => ref}, socket),
      do: {:noreply, cancel_upload(socket, :photos, ref)}

The component renders `live_file_input` itself, so it must be inside the form that has the
`phx-change` LiveView uploads need.

`variant="canvas"` (the default; `variant="pond"` is the old Ledger UI FilePond panel) is the Signetum canvas look: a dashed drop area (icon, `drop_label`, `hint`),
each file as a card with its icon, name, size, a progress meter and a remove button, and a
red drop area with the error when a file is refused. `layout="thumbs"` shows 96px image
thumbnails followed by a small dashed "+" tile.

    <.upload upload={@uploads.docs} variant="canvas" on_cancel="cancel-upload"
      drop_label="Arraste arquivos aqui" hint="XML, PDF ou imagens · até 10 MB" />

### `<.upload>`

Renders the drop panel and the list of chosen files.

    <.upload upload={@uploads.avatar} layout="circle" bordered class="w-28" on_cancel="cancel">
      <:label><svg>…</svg></:label>
    </.upload>

Events: the remove button of a file pushes `on_cancel` with `%{"ref" => entry_ref}` (to
`target` when given); answer with `cancel_upload/3`.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `upload` (required) | `{:struct, Phoenix.LiveView.UploadConfig}` |  | `@uploads.name`. |
| `id` | `:string` | `nil` | Defaults to `<upload ref>-pond`. |
| `bordered` | `:boolean` | `false` | A dashed border (Ledger UI's `fp-bordered`). |
| `filled` | `:boolean` | `false` | A filled panel (Ledger UI's `fp-bg-filled`). |
| `columns` | `:integer` | `1` | `1`, `2`, `3`, `4` — Files side by side, as Ledger UI's Two/Three/Four Grid. |
| `variant` | `:string` | `"canvas"` | `canvas`, `pond` — `canvas` (the default) is the Signetum canvas drop area and file cards; `pond` is the old Ledger UI FilePond panel. |
| `layout` | `:string` | `"panel"` | `panel`, `circle`, `thumbs` — `circle` is the round single-file drop of Ledger UI's Circle Filepond; size it with `class`. `thumbs` (canvas) shows image thumbnails and a "+" tile. |
| `hint` | `:string` | `nil` | Canvas: the line under `drop_label` (formats, size), also shown under an error. |
| `browse` | `:string` | `nil` | Canvas: a small outlined button with the upload icon inside the drop area, under the hint (`Escolher arquivo`). Clicking it opens the chooser like the rest of the area. |
| `icon_path` | `:string` | `nil` | Canvas: the `d` of the SVG path drawn over the drop label, instead of the upload arrow. |
| `drop_class` | `:any` | `nil` | Canvas: classes of the drop area itself (its padding, for one). |
| `on_cancel` | `:any` | `nil` | Event (or `%JS{}`) of the remove button. |
| `target` | `:any` | `nil` |  |
| `previews` | `:boolean` | `true` | A thumbnail for image files. |
| `error_texts` | `:map` | `%{too_large: "File is too large", too_many_files: "Too many files", external_client_failure: "Upload failed", not_accepted: "File of invalid type"}` | The text of each upload error atom. `%{max}` in a text is replaced by the `max_entries` of the upload ("Only %{max} files"). |
| `browse_label` | `:string` | `"Browse"` |  |
| `drop_label` | `:string` | `"Drag & Drop your files or"` |  |
| `remove_label` | `:string` | `"Remove"` |  |
| `uploading_label` | `:string` | `"Uploading"` |  |
| `complete_label` | `:string` | `"Upload complete"` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:label>` — Replaces the text of the drop panel (the circle layout shows an icon).

### `<.upload_button>`

A button that opens the file chooser: kit CSS's `btn` on a `<label>` holding an invisible file input.

    <.upload_button upload={@uploads.avatar}>Choose File</.upload_button>
    <.upload_button name="doc" color="info" variant="glow" icon shape="pill" aria-label="Upload">
      <svg>…</svg>
    </.upload_button>

With `upload` it renders `live_file_input`; otherwise a plain `<input type="file" name>`. The
button shows a 2px primary outline (half opaque, as the other focus rings) while its input has
keyboard focus.

It takes the same `size`, `variant`, `color` and `shape` as `LedgerUI.Components.Button`, and gets the same classes:

    <.upload_button upload={@uploads.files} id="attach-button" size="sm" variant="ghost">Attach</.upload_button>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `upload` | `{:struct, Phoenix.LiveView.UploadConfig}` | `nil` |  |
| `name` | `:string` | `nil` | Name of the plain file input, without `upload`. |
| `multiple` | `:boolean` | `false` | Plain input only. |
| `accept` | `:string` | `nil` | Plain input only. |
| `disabled` | `:boolean` | `false` | Disables the input and dims the button (no pointer events). |
| `color` | `:string` | `"neutral"` | `neutral`, `primary`, `secondary`, `info`, `success`, `warning`, `error`, `white`, `current`, `mono` — As `<.button color>`. |
| `variant` | `:string` | `"solid"` | `solid`, `glow`, `outline`, `soft`, `bordered`, `flat`, `glass`, `ghost`, `dim` — As `<.button variant>`. |
| `size` | `:string` | `nil` | ``, `xs`, `sm`, `md`, `lg`, `xl` — As `<.button size>`; `nil` is `md`. |
| `shape` | `:string` | `"rounded"` | `rounded`, `pill`, `square` |
| `icon` | `:boolean` | `false` | A square button that holds only an icon. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
