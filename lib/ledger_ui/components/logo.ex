defmodule LedgerUI.Components.Logo do
  @moduledoc """
  The Ledger UI mark: a drop inside a hexagon. The ring follows the page ink (`currentColor`), the
  body stays near-black and the drop takes the theme accent (`var(--accent)`); `tone="mono"` draws
  the drop in light silver instead.

      <.linea_logo />
      <.linea_logo size={28} wordmark />
      <.linea_logo id="hero-logo" size={96} tone="mono" />

  When an `id` is given the drop gets a soft gradient named after it (`<id>-drop`); without one the
  drop is flat, so the markup stays deterministic and logos never borrow each other's gradient.
  """
  use LedgerUI.Component

  @hex "M24 2.5 42.6 13.25v21.5L24 45.5 5.4 34.75v-21.5Z"
  @drop "M24 12.5c3.4 4.3 9 10.2 9 16.1a9 9 0 0 1-18 0c0-5.9 5.6-11.8 9-16.1Z"
  @accent "var(--accent, var(--teal-600))"
  @silver "#d9dde0"

  attr :id, :string,
    default: nil,
    doc: "Names the gradient of the drop; without one the drop is flat."

  attr :size, :integer, default: 32, doc: "The side of the mark, in px."
  attr :tone, :string, default: "accent", values: ~w(accent mono)
  attr :wordmark, :boolean, default: false, doc: ~s(Adds "Ledger UI" after the mark.)

  attr :word_size, :integer,
    default: nil,
    doc: "Size of the word in px (default 0.6 x size, at most 30)."

  attr :label, :string, default: "Ledger UI", doc: "The accessible name."
  attr :class, :any, default: nil
  attr :rest, :global

  def linea_logo(assigns) do
    color = if assigns.tone == "mono", do: @silver, else: @accent
    word = assigns.word_size || min(round(assigns.size * 0.6), 30)

    assigns =
      assigns
      |> assign(:hex, @hex)
      |> assign(:drop, @drop)
      |> assign(:color, color)
      |> assign(:fill, if(assigns.id, do: "url(##{assigns.id}-drop)", else: color))
      |> assign(
        :word_style,
        "font-size:#{word}px;font-weight:600;letter-spacing:-.02em;line-height:1"
      )

    ~H"""
    <span
      data-part="logo"
      class={cx(["lu-logo", @class])}
      style="display:inline-flex;align-items:center;gap:.4em"
      role="img"
      aria-label={@label}
      {@rest}
    >
      <svg
        width={@size}
        height={@size}
        viewBox="0 0 48 48"
        aria-hidden="true"
        style="flex:none;color:var(--ink)"
      >
        <defs :if={@id}>
          <linearGradient id={"#{@id}-drop"} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stop-color={@color} stop-opacity=".78" />
            <stop offset="1" stop-color={@color} />
          </linearGradient>
        </defs>
        <path
          d={@hex}
          fill="#141514"
          stroke="currentColor"
          stroke-width="2.4"
          stroke-linejoin="round"
        />
        <path d={@drop} fill={@fill} />
      </svg>
      <span :if={@wordmark} {style_attr(@word_style)}>Ledger UI</span>
    </span>
    """
  end

  defp style_attr(nil), do: []
  defp style_attr(false), do: []
  defp style_attr(""), do: []
  defp style_attr(style), do: [style: style]
end
