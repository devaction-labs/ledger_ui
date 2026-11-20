# ImageInput

Imagem única (logo, foto de perfil, capa): clica para escolher, mostra a prévia e o progresso do envio.

**Grupo:** 05 · Formulários — datas e valores  
**Resumo visual:** shape square · circle · wide × vazio · com imagem · passando o ponteiro · enviando

## Uso (Phoenix / HEEx)

```heex
<.image_input upload={@uploads.avatar} shape="circle" />
<.image_input upload={@uploads.capa} shape="wide" label="Capa" help="1200×400, até 2 MB" />
```

## Regras

- Vazio: tracejado com ícone. Com imagem: borda sólida; ao passar o ponteiro aparece Trocar.
- Enviando: anel de progresso por cima da prévia.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: image_input)

Todos os function components, atributos, valores e slots que este componente cobre.

An image field: the picture (an avatar, a logo) in a round or rounded frame with a camera strip at the bottom and a
small button to remove or revert it.

    <.image_input name="avatar" value={@user.avatar_url} size="lg" />

Clicking the picture opens the file picker. The chosen file shows at once (the hook `LedgerUI.ImageInput` reads it);
the button then puts the first picture back, and, with nothing chosen, empties the field and sets the hidden
`<name>_remove` input to `1` so the form can tell it was removed. The frame has a green edge while it holds a
picture and the field edge while it is empty.

### `<.image_input>`

Renders the image field.

    <.image_input name="logo" value="/images/logo.png" shape="rounded" />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` | `:string` | `nil` | Defaults to `name`. |
| `name` (required) | `:string` |  | The name of the file input; `<name>_remove` is the hidden one. |
| `value` | `:string` | `nil` | The address of the picture it holds now. |
| `accept` | `:string` | `".png,.jpg,.jpeg,.webp"` |  |
| `size` | `:string` | `"md"` | `sm`, `md`, `lg`, `xl` |
| `shape` | `:string` | `"circle"` | `circle`, `rounded` |
| `label` | `:string` | `"Choose a picture"` | The accessible name of the picker. |
| `remove_label` | `:string` | `"Remove or revert the picture"` |  |
| `disabled` | `:boolean` | `false` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.
