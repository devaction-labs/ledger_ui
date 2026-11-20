# Spinner

Indicador de carregamento curto, com cinco desenhos, cinco tamanhos e as cores do sistema.

**Grupo:** 10 · Feedback  
**Resumo visual:** variant canvas/border/soft/grow/svg × size xs–xl × color · elastic · rótulo acessível

## Uso (Phoenix / HEEx)

```heex
<.spinner variant="canvas" size="md" color="primary" label="Carregando" />
```

## Regras

- Sempre com `label` (lido por leitor de tela).
- Acima de 1s mostre o que acontece; acima de 4s, progresso.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: spinner)

Todos os function components, atributos, valores e slots que este componente cobre.

kit CSS's loading indicator (`loading loading-spinner`, `loading-ring`, `loading-ball`), in every size and
theme color.

    <.spinner />
    <.spinner color="primary" variant="soft" elastic />
    <.spinner color="success" variant="grow" size="lg" />
    <.spinner color="error" variant="svg" />

`size` is kit CSS's `loading-xs` to `loading-xl`. In a button, a `current` spinner takes the text color of the
button and sits before its label:

    <.button disabled>
      <.spinner color="current" size="xs" label="Saving" /> Saving
    </.button>

Over a block that loads, the spinner is centered on a veil that covers it:

    <div class="relative">
      …the content…
      <div class="absolute inset-0 grid place-items-center bg-base-100/70">
        <.spinner color="primary" size="md" />
      </div>
    </div>

### `<.spinner>`

Renders a spinner (`role="status"`, labelled by `label`).

    <.spinner color="primary" variant="soft" size="md" elastic />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `color` | `:string` | `"neutral"` | `neutral`, `primary`, `secondary`, `info`, `success`, `warning`, `error`, `white`, `current` — `white` and `current` (the text color) are for spinners inside filled buttons. |
| `variant` | `:string` | `"canvas"` | `canvas`, `border`, `soft`, `grow`, `svg` — kit CSS's `loading`: `canvas`, `border` and `soft` are `loading-spinner`, `grow` is `loading-ring` and `svg` is `loading-ball`; the color is the text color (`current` keeps the parent's). |
| `size` | `:string` | `"sm"` | `xs`, `sm`, `md`, `lg`, `xl` — kit CSS's `loading-xs` to `loading-xl`. |
| `elastic` | `:boolean` | `false` | Ledger UI's elastic timing function. |
| `label` | `:string` | `"Loading"` |  |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.
