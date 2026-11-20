# Carousel

Faixa horizontal de cards com navegação por setas e indicadores.

**Grupo:** 06 · Exibição  
**Resumo visual:** effect slide/fade/flip/cube/cards/coverflow/creative · direction · navigation · pagination bullets/fraction/progress/scrollbar · variant

## Uso (Phoenix / HEEx)

```heex
<.carousel id="tips" items={@tips} />
```

## Regras

- Indicadores são traços retangulares (raio 2), o atual mais largo.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: carousel)

Todos os function components, atributos, valores e slots que este componente cobre.

Ledger UI's Swiper carousels, without Swiper: slides on a CSS scroll-snap track, and the
`LedgerUI.Carousel` hook for arrows, pagination, autoplay, keyboard, swipe and effects.

    <.carousel id="gallery" navigation class="rounded-lg">
      <.carousel_slide><img class="h-full w-full object-cover" src="/a.jpg" alt="" /></.carousel_slide>
      <.carousel_slide><img class="h-full w-full object-cover" src="/b.jpg" alt="" /></.carousel_slide>
    </.carousel>

    <.carousel id="beside" navigation="outside">…</.carousel>
    <.carousel id="promo" pagination="bullets" autoplay={2000} loop>…</.carousel>
    <.carousel id="tall" direction="vertical" pagination="bullets" class="h-64">…</.carousel>
    <.carousel id="flip" effect="flip" navigation pagination="bullets">…</.carousel>
    <.carousel id="peek" gap={30} pagination="bullets">
      <.carousel_slide class="w-10/12">…</.carousel_slide>
    </.carousel>

`effect` is one of Ledger UI's: `slide` (the scrolling track), `fade`, `flip`, `cube`,
`cards`, `coverflow` and `creative` (slides stacked and moved with CSS transforms).
`pagination` is `bullets` (clickable), `fraction`, `progress` (the bar on top) or
`scrollbar` (a draggable bar at the bottom). `zoom={4}` zooms a slide on double click.
A `:background` slot with `data-carousel-parallax="-23%"` on it, and elements inside slides
with `data-carousel-parallax="-300"`, move at their own pace while the track scrolls.

The previous arrow comes before the next one in the DOM (the tab order), and both point
to the track with `aria-controls`.

### Canvas look and thumbnails

`variant="canvas"` (the default; `variant="classic"` is the old Ledger UI carousel) is the design canvas carousel: a 16px rounded track, round white arrows (the
canvas `lu-ib`), the fraction as a small mono `1/3` at the top right, and bullets under the track
(the active one a long ink pill). `:thumb` slots draw a row of 64px thumbnails under the track,
one per slide, that pick the slide and ring the active one:

    <.carousel id="photos" variant="canvas" label="Fotos do produto" class="h-[200px]">
      <.carousel_slide :for={src <- @photos}><img src={src} alt="" class="size-full object-cover" /></.carousel_slide>
      <:thumb :for={src <- @photos}><img src={src} alt="" class="size-full object-cover" /></:thumb>
    </.carousel>

The bullets and the thumbnails hang below the carousel's box (the box keeps the slide height) and
the carousel reserves their room with a bottom margin.

### State

`index` is the server's slide. The person can move freely in the browser, and their slide
survives patches; when the server changes `index`, the carousel goes there.

### Events

`on_change` (an event name or `%JS{}`) runs when the active slide changes; an event name is
pushed with `%{"id" => id, "index" => index}` (zero-based) to `target`, or to the LiveView.

From the server, `push_event(socket, "linea:carousel", %{id: "gallery", index: 2})` moves it.

### `<.carousel>`

Renders the carousel. Its children are `carousel_slide/1`s.

`on_change` is pushed with `%{"id" => id, "index" => index}` (zero-based) when the active
slide changes; a `%JS{}` is executed instead. The server moves it by changing `index`, or with
`push_event(socket, "linea:carousel", %{id: id, index: n})`.

    <.carousel id="gallery" index={@slide} on_change="slid" navigation pagination="bullets">
      <.carousel_slide :for={src <- @images}>
        <img class="h-full w-full object-cover" src={src} alt="" />
      </.carousel_slide>
    </.carousel>

    def handle_event("slid", %{"index" => index}, socket), do: {:noreply, assign(socket, slide: index)}

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `index` | `:integer` | `0` | The active slide, zero-based. |
| `effect` | `:string` | `"slide"` | `slide`, `fade`, `flip`, `cube`, `cards`, `coverflow`, `creative` — `slide` scrolls a snap track; the others stack the slides and animate them like Swiper's effects. |
| `direction` | `:string` | `"horizontal"` | `horizontal`, `vertical` |
| `navigation` | `:any` | `false` | `true`, `false`, `inside`, `outside` — The previous and next arrows. `true` or `"inside"` lays them over the track; `"outside"` pads the carousel and puts them beside the track (the `slide` effect). |
| `pagination` | `:string` | `nil` | ``, `bullets`, `fraction`, `progress`, `scrollbar` — `bullets` (clickable dots), `fraction` (`2 / 4`), `progress` (bar on top), `scrollbar` (draggable bar). |
| `autoplay` | `:integer` | `nil` | Milliseconds between slides; pauses on hover. |
| `loop` | `:boolean` | `false` | Wrap around past the last and first slides. |
| `gap` | `:integer` | `nil` | Pixels between slides (Ledger UI's `spaceBetween`). |
| `zoom` | `:integer` | `nil` | Double-click zoom ratio. |
| `on_change` | `:any` | `nil` | Event name or `%JS{}`; pushed with `%{"id" => id, "index" => index}`. |
| `target` | `:any` | `nil` | The `phx-target` `on_change` goes to. |
| `prev_label` | `:string` | `"Previous slide"` |  |
| `next_label` | `:string` | `"Next slide"` |  |
| `bullet_label` | `:string` | `"Go to slide"` |  |
| `label` | `:string` | `nil` | The carousel's `aria-label`. |
| `variant` | `:string` | `"canvas"` | `canvas`, `classic` — `canvas` (the default) is the design canvas look: a rounded track, round white arrows, a mono `1/3` fraction at the top right and the bullets below the track. |
| `thumb_label` | `:string` | `"Show slide"` | The thumbnails' label, before the number. |
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:background>` — Behind the track, for the parallax background.
- `<:inner_block>` (required)
- `<:thumb>` — A thumbnail per slide, in order: a row under the track that picks the slide.

### `<.carousel_slide>`

Renders one slide. Its content fills it; with `zoom` on the carousel, the first child is
what double click zooms. Give it a width (`class="w-10/12"`) to show the next slide peeking.

    <.carousel_slide class="w-10/12">
      <img class="h-full w-full rounded-lg object-cover" src="/a.jpg" alt="" />
    </.carousel_slide>

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `class` | `:any` | `nil` |  |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:inner_block>` (required)
