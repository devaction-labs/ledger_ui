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
  `push_event(socket, "linea:carousel", %{id: "gallery", index: 2})` moves it.

  The component renders the track and, as its siblings, the pagination and the thumbnails.
  The bullets are `<i role="button" tabindex="0" aria-label=...>` rendered by the server; the hook only moves `aria-current` and the slides' `aria-hidden`.
  Configuration that is not the default travels in `data-*` attributes of the track's root, which
  carries `phx-hook="LedgerUI.Carousel"`.
  """
  use LedgerUI.Component

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
      |> assign(:attrs, root_attrs(assigns))
      |> assign(:nav, assigns.navigation in [true, "inside", "outside"])
      |> assign(:dots, count > 0 and assigns.pagination == "bullets")
      |> assign(:fraction, count > 0 and assigns.pagination == "fraction")
      |> assign(:bar, count > 0 and assigns.pagination in ["progress", "scrollbar"])
      |> assign(:numbers, if(count > 0, do: Enum.to_list(0..(count - 1)), else: []))

    ~H"""
    <div id={@id} data-part="carousel" class={@classes} phx-hook="LedgerUI.Carousel" {@attrs}>
      {render_slot(@background)}
      <div class="tr">{render_slot(@inner_block)}</div>
      <button
        :if={@nav}
        type="button"
        class="lu-btn icon sm"
        aria-label={@prev_label}
        aria-controls={@id}
        data-carousel-prev
        style="position:absolute;top:50%;left:8px;transform:translateY(-50%);z-index:2"
      >
        <.icon name="chevron-left" />
      </button>
      <button
        :if={@nav}
        type="button"
        class="lu-btn icon sm"
        aria-label={@next_label}
        aria-controls={@id}
        data-carousel-next
        style="position:absolute;top:50%;right:8px;transform:translateY(-50%);z-index:2"
      >
        <.icon name="chevron-right" />
      </button>
      <span
        :if={@fraction}
        class="mono lu-xs"
        data-carousel-fraction
        style="position:absolute;top:8px;right:10px;z-index:2;color:#fff"
      >{@index + 1}/{@count}</span>
      <i
        :if={@bar}
        data-carousel-bar
        style="position:absolute;left:0;top:0;height:3px;width:0;background:var(--ink);z-index:2"
      ></i>
    </div>
    <div :if={@dots} id={"#{@id}-dots"} class="lu-cdots">
      <i
        :for={n <- @numbers}
        role="button"
        tabindex="0"
        aria-label={"#{@bullet_label} #{n + 1}"}
        aria-current={to_string(n == @index)}
        style={"--dl:#{n * 3}s"}
      ></i>
    </div>
    <div
      :if={@thumb != []}
      id={"#{@id}-thumbs"}
      class="lu-row"
      style="margin-top:10px;gap:8px"
    >
      <button
        :for={{t, n} <- Enum.with_index(@thumb)}
        type="button"
        aria-label={"#{@thumb_label} #{n + 1}"}
        style="width:64px;height:64px;border:0;padding:0;border-radius:10px;overflow:hidden;cursor:pointer"
      >
        {render_slot(t)}
      </button>
    </div>
    """
  end

  defp classes(a) do
    cx([
      "lu-carousel2",
      a.effect == "fade" && "fade",
      a.effect not in ["slide", "fade"] && "fx-#{a.effect}",
      a.variant == "classic" && "classic",
      a.direction == "vertical" && "vertical",
      a.class
    ])
  end

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
    ~H"""
    <div data-part="carousel-slide" class={@class} {@rest}>{render_slot(@inner_block)}</div>
    """
  end
end
