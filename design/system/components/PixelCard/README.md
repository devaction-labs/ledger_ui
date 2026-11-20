# PixelCard

Card de escolha (modelo, módulo, integração) que acende uma matriz de pixels no canto superior direito, na cor do card, ao passar o mouse ou focar.

**Grupo:** 06 · Exibição  
**Resumo visual:** 8 cores · pixels piscam em quadros de 0,3s no hover/foco · seta · cor livre via --px

## Uso (Phoenix / HEEx)

```heex
<.pixel_card navigate={~p"/novo/loja"} color="red" icon="huge-shopping-cart-01" title="Loja" description="PDV, estoque, NFC-e" />
<.pixel_card title="Marca" style="--px: #f97316" />
```

## Regras

- Os pixels piscam em quadros (o padrão muda a cada 0,3s) e somem em direção ao centro para o texto continuar legível.
- Sem JavaScript no produto: três máscaras de padrões trocadas por keyframe `steps(1)`; desligado com `prefers-reduced-motion`.
- Com `href`/`navigate`/`patch` é link; sem, é `<button>`. Foco de teclado faz o mesmo que o hover.
- Grade de 3 colunas (`lu-px-grid`).

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: pixel_card)

Todos os function components, atributos, valores e slots que este componente cobre.

The canvas's pixel card: a card to choose from (a model, a module, an integration) that, on hover or keyboard
focus, lights up a matrix of pixels in its top right corner, in the card's colour. The pixels blink in frames
(the pattern changes every 0.3s) and fade towards the centre, so the text stays readable.

    <.pixel_card navigate={~p"/novo/loja"} color="red" icon="huge-shopping-cart-01"
      title="Loja" description="PDV, estoque, NFC-e" />

    <div class="grid grid-cols-3 gap-2.5">
      <.pixel_card navigate={~p"/novo/loja"} color="red" icon="huge-shopping-cart-01"
        title="Loja" description="PDV, estoque, NFC-e" />
      <.pixel_card phx-click="pick" phx-value-id="agenda" color="ink" icon="huge-calendar-03"
        title="Agenda" description="Horários e lembretes" />
    </div>

With `href`, `navigate` or `patch` the card is a link (`<a>`); with none it is a `<button type="button">` that
takes `phx-click` and the other events through `rest`. Both are focusable, and the keyboard focus does what the
hover does: the pixels, the stronger outline and the arrow (`arrow={false}` leaves the arrow out).

`color` takes a palette name (`red`, `rose`, `green`, `teal`, `blue`, `violet`, `amber`, `ink`); without it the
card takes the accent. Any other colour goes through the `--px` custom property:

    <.pixel_card title="Marca" description="--px: var(--accent)" style="--px: #f97316" />

The cards sit in a 3-column grid of the canvas with `lu-px-grid`, and `lu-px-sec` is the heading of a section of
them (a bold name over a muted line); both are plain classes.

### How the pixels blink

There is no JavaScript. The card's `::before` is masked by a 60px tile of 2.6px squares (three tiles, `--pxa`,
`--pxb` and `--pxc`, each with its own random pattern and opacities) intersected with a radial gradient from the
top right corner. A stepped keyframe (`lu-px-twinkle`, `.9s steps(1)`) swaps the tile every 0.3s. Under
`prefers-reduced-motion: reduce` the animation is off: the first tile stays drawn, lit on hover and focus.

### `<.pixel_card>`

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `title` (required) | `:string` |  | The bold name of the option. |
| `description` | `:string` | `nil` | The muted line under the name. |
| `icon` | `:string` | `nil` | A Hugeicons name, drawn white in a round chip of the card's colour. |
| `color` | `:string` | `nil` | ``, `red`, `rose`, `green`, `teal`, `blue`, `violet`, `amber`, `ink` — A palette name; any other colour goes in `style="--px: …"`. The accent when none. |
| `arrow` | `:boolean` | `true` | The arrow that appears at the bottom right on hover and focus. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element, including `href`, `navigate`, `patch`, `method`, `disabled`.

Slots:

- `<:inner_block>` — Extra content under the description.
