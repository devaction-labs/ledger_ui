# SignaturePad

Captura de assinatura à mão em contratos.

**Grupo:** 05 · Formulários — datas e valores  
**Resumo visual:** mode draw/type · variant canvas/classic · limpar/desfazer

## Uso (Phoenix / HEEx)

```heex
<.signature_pad field={@form[:signature]} />
```

## Regras

- Linha-base tracejada; botões Limpar e Confirmar abaixo.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: signature_pad)

Todos os function components, atributos, valores e slots que este componente cobre.

A signature field: sign with a finger, a pen or the mouse (pointer events), or type a name that is set in
a handwriting font. The signature leaves as SVG text.

    <.signature_pad field={@form[:signature]} label="Signature" />
    <.signature_pad name="receipt" mode="type" text="Marcos Oliveira" locale="pt_BR" />
    <.signature_pad name="sign" modes={["draw"]} height={220} />

The form gets the SVG (`<svg xmlns=... viewBox="0 0 300 170"><path .../></svg>`, `""` while the pad is
empty) through a hidden input named like the field. Every stroke, typed letter or Clear fires a bubbling `input`
event from it, so `phx-change` runs. Give the field a stored SVG as `value` and the pad shows it; the server
sending another value (or an empty one) replaces what is in the pad, re-rendering the same one changes
nothing. Show a saved signature elsewhere as an image, never as raw markup:

    <img src={"data:image/svg+xml;base64," <> Base.encode64(@signature)} alt="Signature" />

`variant="canvas"` (the default; `variant="classic"` is the old Ledger UI pad) draws the design canvas's pad (a card with the dashed line and the hint under it, at the
left), and `footer={false}` drops the status and Clear line under the pad:

    <.signature_pad name="sign" modes={["draw"]} variant="canvas" footer={false} height={150} />

Drawing needs a pointer, so the `type` mode is the keyboard and screen reader way to sign; keep both
modes unless the signature must be drawn. The pad is a white surface in the light theme and a navy one in
the dark theme (the ink and the typed name are inverted to stay readable there); the SVG it exports always
has dark ink on a transparent background.

The behavior lives in the `LedgerUI.SignaturePad` hook, so the pad needs a stable `id`.

### `<.signature_pad>`

Renders the signature pad.

Events: `on_change` is pushed with `%{"id" => id, "value" => svg}` each time the signature changes, to `target` or
to the LiveView/LiveComponent the pad is in.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` |  | Defaults to the field id, or a generated one. |
| `name` | `:string` |  | Defaults to the field name. |
| `value` | `:string` |  | The saved signature as SVG text. Defaults to the field value. |
| `field` | `{:struct, Phoenix.HTML.FormField}` | `nil` |  |
| `label` | `:string` | `nil` |  |
| `label_class` | `:any` | `nil` |  |
| `help` | `:string` | `nil` |  |
| `errors` | `:list` | `[]` |  |
| `mode` | `:string` | `"draw"` | `draw`, `type` — The mode the pad starts in. |
| `modes` | `:list` | `["draw", "type"]` | The modes offered, `["draw"]` or `["type"]` for just one (the switch is then hidden). |
| `text` | `:string` | `""` | The name the `type` mode starts with. |
| `ink` | `:string` | `"#0F172A"` | The color of the exported ink, as hex. |
| `height` | `:integer` | `170` | The height of the pad in pixels. |
| `locale` | `:string` | `"en"` | `en`, `pt_BR` |
| `labels` | `:map` | `%{}` | Single texts: `:signature_draw`, `:signature_type`, `:signature_clear`, `:signature_area`, `:signature_hint`, `:signature_name`, `:signature_ready` and `:signature_empty`. |
| `disabled` | `:boolean` | `false` |  |
| `variant` | `:string` | `"canvas"` | `canvas`, `classic` — `canvas` (the default) is the design canvas's pad: a 16px card with the dashed line near its foot and the hint under it, at the left (always shown, like a caption), without the × mark. |
| `footer` | `:boolean` | `true` | The line under the pad with the status ("No signature") and the Clear button. |
| `on_change` | `:string` | `nil` |  |
| `target` | `:any` | `nil` |  |
| `wrapper_class` | `:any` | `nil` | Classes of the block around the pad. |
| `class` | `:any` | `nil` | Classes of the drawing surface. |

Any other HTML/phx attribute goes to the root element.
