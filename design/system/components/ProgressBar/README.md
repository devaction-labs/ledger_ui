# ProgressBar

Barra de progresso com cor, variante, tamanho, rótulo e estados animados; `progress_stack` empilha segmentos.

**Grupo:** 10 · Feedback  
**Resumo visual:** color × variant solid/soft/gradient · size sm–xl · active · indeterminate · shine · label · progress_stack

## Uso (Phoenix / HEEx)

```heex
<.progress value={64} color="primary" />
<.progress value={92} size="xl" label="92%" />
<.progress indeterminate />
<.progress_stack><:segment value={52} color="primary" />…</.progress_stack>
```

## Regras

- `active` anima listras; `indeterminate` corre sem valor; `shine` passa um brilho.
- `size="xl"` comporta o rótulo dentro da barra.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: progress)

Todos os function components, atributos, valores e slots que este componente cobre.

kit CSS's progress bar (`<progress class="progress progress-{color}">`), solid or soft, in every size, with
the indeterminate slide when there is no value.

    <.progress value={42} />
    <.progress value={70} color="success" variant="soft" />
    <.progress value={50} color="primary" active />
    <.progress indeterminate color="info" size="sm" />
    <.progress indeterminate shine color="primary" />
    <.progress value={30} color="warning" variant="soft" height="1.5" />
    <.progress value={60} color="white" />
    <.progress value={72} variant="gradient" />

`value` is read against `max` (100 by default) and updates with the assign.

The color is kit CSS's (`progress-primary`, `progress-success`…; `neutral` is the ink bar); `gradient` keeps the
kit's thin gradient meter.

`progress_stack/1` is the canvas's stacked bar (`lu-stack`), the parts of a total side by side:

    <.progress_stack label="Sales by channel">
      <:segment value={46} label="Counter" />
      <:segment value={33} label="Online" />
      <:segment value={21} label="Reps" />
    </.progress_stack>

### `<.progress>`

Renders a progress bar.

    <.progress value={@uploaded} max={@total} color="success" variant="soft" active />

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `value` | `:any` | `0` | A number between 0 and `max`. |
| `max` | `:any` | `100` |  |
| `color` | `:string` | `"neutral"` | `neutral`, `primary`, `secondary`, `info`, `success`, `warning`, `error`, `white` — The bar's color; `white` is a white bar on a translucent track, for colored cards. |
| `variant` | `:string` | `"solid"` | `solid`, `soft`, `gradient` — `soft` tints the track with the bar's color (`bg-{color}/15`); `solid` uses the gray track; `gradient` fills the bar with the app gradient (`--grad`, the accent to info one when unset) and ignores `color`: the thin hours bar of the design (`dh-meter`, 6px). |
| `size` | `:string` | `"md"` | `sm`, `md`, `lg`, `xl` |
| `height` | `:string` | `nil` | ``, `1`, `1.5`, `2`, `3`, `4` — A Tailwind height step (`h-1`, `h-1.5`...) that wins over `size`; `1.5` is the one `size` lacks. |
| `active` | `:boolean` | `false` | A light sweeping over the bar. |
| `indeterminate` | `:boolean` | `false` | A bar sliding across the track, when the end is not known. |
| `shine` | `:boolean` | `false` | With `indeterminate`, a light of the bar's color runs over the track instead of the bar sliding across it. |
| `label` | `:string` | `nil` | The `aria-label` of the progress bar. |
| `class` | `:any` | `nil` |  |
| `bar_class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

### `<.progress_stack>`

Renders the canvas's stacked bar (`lu-stack`): one segment per part, its width the part's share of `max`
(100 by default), in the chart colors `--c1`, `--c2`... in order unless a segment sets `color`.

    <.progress_stack label="Sales by channel: counter 46%, online 33%, reps 21%">
      <:segment value={46} />
      <:segment value={33} />
      <:segment value={21} color="c4" />
    </.progress_stack>

It is one image for screen readers (`role="img"`), named by `label`; a segment's `label` is its `title`.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `max` | `:any` | `100` | The total the segments are read against. |
| `label` | `:string` | `nil` | The `aria-label`: say the parts and their values. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:segment>` (required) — attrs: `value`, `color`, `label` — A part of the total.
