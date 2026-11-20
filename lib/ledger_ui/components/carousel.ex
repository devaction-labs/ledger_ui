defmodule LedgerUI.Components.Carousel do
  @moduledoc """
  Carousels without Swiper: slides on a track, and the `LedgerUI.Carousel` hook for arrows,
  pagination, autoplay, keyboard, swipe and effects.

      <.carousel id="gallery" navigation slides={3}>
        <.carousel_slide><img class="h-full w-full object-cover" src="/a.jpg" alt="" /></.carousel_slide>
        <.carousel_slide>...</.carousel_slide>
        <.carousel_slide>...</.carousel_slide>
      </.carousel>

      <.carousel id="promo" pagination="bullets" slides={3} autoplay={2000} loop>...</.carousel>
      <.carousel id="flip" effect="flip" navigation>...</.carousel>

  `effect` is `slide` (the scrolling track), `fade`, `flip`, `cube`, `cards`, `coverflow` or
  `creative`. `pagination` is `bullets`, `fraction`, `progress` or `scrollbar`; it is rendered
  on the server, so give the number of `slides` (or one `:thumb` slot per slide). `:thumb` slots
  draw a row of thumbnails under the track that pick the slide.

  The server's slide is `index`; the person moves freely in the browser, and their slide survives
  patches. `on_change` (an event name or `%JS{}`) runs when the slide changes; an event name is
  pushed with `%{"id" => id, "index" => index}` to `target`. From the server,
  `push_event(socket, "ledger:carousel", %{id: "gallery", index: 2})` moves it.

  The component renders the track and, as its siblings, the pagination and the thumbnails.
  The bullets are `<i role="button" tabindex="0" aria-label=...>` rendered by the server; the hook only moves `aria-current` and the slides' `aria-hidden`.
  Configuration that is not the default travels in `data-*` attributes of the track's root, which
  carries `phx-hook="LedgerUI.Carousel"` (`data-lu-effect` and `data-lu-direction` say what to draw). Styled
  only with Tailwind utilities; the bullets and thumbnails read `aria-current`.
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Button

  @root "relative overflow-hidden rounded-[14px]"
  @arrow "absolute z-[2] top-[calc(50%-15px)]"
  @slide "flex flex-none items-end rounded-[12px] p-3 font-semibold text-white [:where(&)]:h-[130px] [:where(&)]:w-[260px]"
  @dot "h-1 w-[18px] cursor-pointer rounded-[2px] bg-line-strong aria-[current=true]:bg-ink"
  @thumb "size-16 cursor-pointer overflow-hidden rounded-[10px] border-0 p-0 aria-[current=true]:shadow-[0_0_0_2px_var(--lu-bg-page),0_0_0_4px_var(--lu-accent-500)]"

  @effects ~w(slide fade flip cube cards coverflow creative)

  attr :id, :string, required: true
  attr :index, :integer, default: 0, doc: "The active slide, zero-based."
  attr :effect, :string, default: "slide", values: @effects
  attr :direction, :string, default: "horizontal", values: ~w(horizontal vertical)

  attr :navigation, :any,
    default: false,
    values: [true, false, "inside", "outside"],
    doc: "The previous and next arrows."

  attr :pagination, :string,
    default: nil,
    values: [nil, "bullets", "fraction", "progress", "scrollbar"]

  attr :slides, :integer,
    default: nil,
    doc: "How many slides there are, for the pagination (the `:thumb` count when omitted)."

  attr :autoplay, :integer, default: nil, doc: "Milliseconds between slides; pauses on hover."
  attr :loop, :boolean, default: false
  attr :gap, :integer, default: nil, doc: "Pixels between slides."
  attr :zoom, :integer, default: nil, doc: "Double-click zoom ratio."
  attr :on_change, :any, default: nil
  attr :target, :any, default: nil
  attr :prev_label, :string, default: "Previous slide"
  attr :next_label, :string, default: "Next slide"
  attr :bullet_label, :string, default: "Go to slide"
  attr :label, :string, default: nil
  attr :variant, :string, default: "canvas", values: ~w(canvas classic)
  attr :thumb_label, :string, default: "Show slide"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :background, doc: "Behind the track, for a parallax background."
  slot :inner_block, required: true
  slot :thumb, doc: "A thumbnail per slide, in order."

  def carousel(assigns) do
    count = assigns.slides || length(assigns.thumb)

    assigns =
      assigns
      |> assign(:count, count)
      |> assign(:classes, classes(assigns))
      |> assign(:track_class, track_class(assigns))
      |> assign(:arrow_class, arrow_class())
      |> assign(:dot_class, @dot)
      |> assign(:thumb_class, @thumb)
      |> assign(:attrs, root_attrs(assigns))
      |> assign(:nav, assigns.navigation in [true, "inside", "outside"])
      |> assign(:dots, count > 0 and assigns.pagination == "bullets")
      |> assign(:fraction, count > 0 and assigns.pagination == "fraction")
      |> assign(:bar, count > 0 and assigns.pagination in ["progress", "scrollbar"])
      |> assign(:numbers, if(count > 0, do: Enum.to_list(0..(count - 1)), else: []))

    ~H"""
    <div
      id={@id}
      data-part="carousel"
      class={@classes}
      phx-hook="LedgerUI.Carousel"
      data-lu-effect={@effect}
      data-lu-direction={@direction}
      data-lu-variant={@variant}
      {@attrs}
    >
      {render_slot(@background)}
      <div data-part="carousel-track" class={@track_class}>{render_slot(@inner_block)}</div>
      <button
        :if={@nav}
        type="button"
        data-part="carousel-prev"
        class={[@arrow_class, "left-2"]}
        aria-label={@prev_label}
        aria-controls={@id}
        data-carousel-prev
      >
        <.icon name="chevron-left" />
      </button>
      <button
        :if={@nav}
        type="button"
        data-part="carousel-next"
        class={[@arrow_class, "right-2"]}
        aria-label={@next_label}
        aria-controls={@id}
        data-carousel-next
      >
        <.icon name="chevron-right" />
      </button>
      <span
        :if={@fraction}
        data-part="carousel-fraction"
        class="absolute top-2 right-2.5 z-[2] font-mono text-xs/4 text-white"
        data-carousel-fraction
      >{@index + 1}/{@count}</span>
      <i
        :if={@bar}
        data-part="carousel-bar"
        data-carousel-bar
        class="absolute top-0 left-0 z-[2] h-[3px] w-0 bg-ink"
      ></i>
    </div>
    <div
      :if={@dots}
      id={"#{@id}-dots"}
      data-part="carousel-dots"
      class="mt-2.5 flex justify-center gap-1.5"
    >
      <i
        :for={n <- @numbers}
        data-part="carousel-dot"
        class={@dot_class}
        role="button"
        tabindex="0"
        aria-label={"#{@bullet_label} #{n + 1}"}
        aria-current={to_string(n == @index)}
      ></i>
    </div>
    <div
      :if={@thumb != []}
      id={"#{@id}-thumbs"}
      data-part="carousel-thumbs"
      class="mt-2.5 flex flex-wrap items-center gap-2"
    >
      <button
        :for={{t, n} <- Enum.with_index(@thumb)}
        type="button"
        data-part="carousel-thumb"
        class={@thumb_class}
        aria-label={"#{@thumb_label} #{n + 1}"}
        aria-current={to_string(n == @index)}
      >
        {render_slot(t)}
      </button>
    </div>
    """
  end

  defp classes(a), do: cx([@root, a.class])

  # The icon arrows: canvas buttons set over the track, centred on its height.
  defp arrow_class, do: [Button.canvas_classes("sm", "default", true), @arrow]

  defp track_class(%{effect: "slide", direction: dir}),
    do: ["flex gap-3", dir == "vertical" && "flex-col"]

  defp track_class(_), do: "grid"

  # Only what is not the default is written, so the markup stays the canvas one.
  defp root_attrs(a) do
    on_change =
      case a.on_change do
        nil -> nil
        %Phoenix.LiveView.JS{} = js -> Phoenix.json_library().encode!(js.ops)
        name -> name
      end

    attrs = %{
      "data-index" => a.index != 0 && a.index,
      "data-autoplay" => a.autoplay,
      "data-loop" => a.loop && "true",
      "data-gap" => a.gap,
      "data-zoom" => a.zoom,
      "data-on-change" => on_change,
      "data-target" => a.target && target_attr(a.target),
      "data-nav" => a.navigation == "outside" && "outside",
      "aria-label" => a.label,
      "role" => "region",
      "aria-roledescription" => "carousel",
      "tabindex" => "0"
    }

    attrs |> Enum.filter(fn {_k, v} -> v end) |> Map.new() |> Map.merge(a.rest)
  end

  defp target_attr(%Phoenix.LiveComponent.CID{cid: cid}), do: cid
  defp target_attr(target), do: target

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def carousel_slide(assigns) do
    assigns = assign(assigns, :slide_class, @slide)

    ~H"""
    <div data-part="carousel-slide" class={[@slide_class, @class]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
