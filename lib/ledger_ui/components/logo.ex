defmodule LedgerUI.Components.Logo do
  @moduledoc """
  The Ledger UI mark. By default the chart glyph of the design canvas (an axis with a rising
  line) on a rounded tile: `tone="accent"` is a tile of the theme accent, `tone="mono"` the `inverse` tile.
  `mark="hexagon"` draws the README mark instead: a drop inside a hexagon (the ring follows the
  page ink, the drop takes the theme accent, or silver with `tone="mono"`).

      <.logo />
      <.logo size={28} wordmark />
      <.logo tone="mono" size={56} />
      <.logo mark="hexagon" id="hero-logo" size={96} />

  The tile is only utilities (`--s` is its side, set inline). With `mark="hexagon"`
  and an `id` the drop gets a soft gradient named after it (`<id>-drop`); without one it is flat,
  so the markup stays deterministic and logos never borrow each other's gradient.
  """
  use LedgerUI.Component

  @hex "M24 2.5 42.6 13.25v21.5L24 45.5 5.4 34.75v-21.5Z"
  @drop "M24 12.5c3.4 4.3 9 10.2 9 16.1a9 9 0 0 1-18 0c0-5.9 5.6-11.8 9-16.1Z"
  @tones %{
    "accent" => %{
      tile: "bg-accent text-white",
      fill: "fill-accent-500",
      stop: "[stop-color:var(--lu-accent-500)]"
    },
    "mono" => %{
      tile: "bg-inverse text-on-inverse",
      fill: "fill-gray-300",
      stop: "[stop-color:var(--color-gray-300)]"
    }
  }

  attr :id, :string,
    default: nil,
    doc: "Names the gradient of the drop; without one the drop is flat."

  attr :mark, :string, default: "chart", values: ~w(chart hexagon)
  attr :size, :integer, default: 32, doc: "The side of the mark, in px."
  attr :tone, :string, default: "accent", values: ~w(accent mono)
  attr :wordmark, :boolean, default: false, doc: ~s(Adds "Ledger UI" after the mark.)

  attr :word_size, :integer,
    default: nil,
    doc: "Size of the word in px (default 0.6 x size, at most 30)."

  attr :name, :string,
    default: nil,
    doc:
      "Your brand's name, written after the mark (it implies `wordmark`) and used as its accessible name."

  attr :context, :string,
    default: nil,
    doc: "A muted line under the `name`: the workspace or the product line."

  attr :label, :string, default: nil, doc: "The accessible name (the `name`, or \"Ledger UI\")."
  attr :class, :any, default: nil
  attr :rest, :global

  def logo(assigns) do
    assigns
    |> assign(:label, assigns.label || assigns.name || "Ledger UI")
    |> assign(:wordmark, assigns.wordmark or assigns.name != nil)
    |> render_logo()
  end

  attr :name, :string, default: nil
  attr :context, :string, default: nil
  attr :style, :string, required: true

  defp word(%{context: nil} = assigns) do
    ~H"""
    <span data-part="logo-word" class="font-semibold leading-none tracking-[-.02em]" style={@style}>
      {@name || "Ledger UI"}
    </span>
    """
  end

  defp word(assigns) do
    ~H"""
    <span data-part="word-span" class="flex flex-col leading-[1.25]">
      <b data-part="logo-word" class="font-semibold leading-none tracking-[-.02em]" style={@style}>
        {@name || "Ledger UI"}
      </b>
      <span data-part="word-span-2" class="text-[13px] leading-[18px] text-muted">{@context}</span>
    </span>
    """
  end

  defp render_logo(%{mark: "chart"} = assigns) do
    word = assigns.word_size || min(round(assigns.size * 0.6), 30)

    assigns =
      assigns
      |> assign(:glyph, round(assigns.size * 0.45))
      |> assign(:tones, @tones[assigns.tone])
      |> assign(:word_style, "font-size:#{word}px")

    ~H"""
    <span
      data-part="logo"
      class={cx(["inline-flex items-center gap-[.4em]", @class])}
      role="img"
      aria-label={@label}
      {@rest}
    >
      <span
        data-part="logo-mark"
        class={[
          "inline-grid size-(--s) flex-none place-items-center rounded-[calc(var(--s)*.3)]",
          @tones.tile
        ]}
        style={"--s:#{@size}px"}
        aria-hidden="true"
      >
        <svg
          data-part="render-logo-svg"
          width={@glyph}
          height={@glyph}
          viewBox="0 0 24 24"
          aria-hidden="true"
          class="fill-none stroke-current stroke-2 [stroke-linecap:round] [stroke-linejoin:round]"
        >
          <path d="M4 19V5" />
          <path d="M4 19h16" />
          <path d="m8 14 3.5-4 3 2.5L19 7" />
        </svg>
      </span>
      <.word :if={@wordmark} name={@name} context={@context} style={@word_style} />
    </span>
    """
  end

  defp render_logo(assigns) do
    tones = @tones[assigns.tone]
    word = assigns.word_size || min(round(assigns.size * 0.6), 30)

    assigns =
      assigns
      |> assign(:hex, @hex)
      |> assign(:drop, @drop)
      |> assign(:tones, tones)
      |> assign(:fill, if(assigns.id, do: "url(##{assigns.id}-drop)"))
      |> assign(
        :word_style,
        "font-size:#{word}px"
      )

    ~H"""
    <span
      data-part="logo"
      class={cx(["inline-flex items-center gap-[.4em]", @class])}
      role="img"
      aria-label={@label}
      {@rest}
    >
      <svg
        data-part="render-logo-svg-2"
        width={@size}
        height={@size}
        viewBox="0 0 48 48"
        aria-hidden="true"
        class="flex-none text-ink"
      >
        <defs :if={@id}>
          <linearGradient id={"#{@id}-drop"} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" class={@tones.stop} stop-opacity=".78" />
            <stop offset="1" class={@tones.stop} />
          </linearGradient>
        </defs>
        <path
          d={@hex}
          class="fill-gray-950 stroke-current"
          stroke-width="2.4"
          stroke-linejoin="round"
        />
        <path d={@drop} fill={@fill} class={!@fill && @tones.fill} />
      </svg>
      <.word :if={@wordmark} name={@name} context={@context} style={@word_style} />
    </span>
    """
  end
end
