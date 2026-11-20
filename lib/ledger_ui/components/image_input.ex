defmodule LedgerUI.Components.ImageInput do
  @moduledoc """
  An image field: the picture (an avatar, a logo) in a round or rounded frame, with an edit
  overlay and a small button to remove or revert it.

      <.image_input name="avatar" value={@user.avatar_url} size="lg" />
      <.image_input name="logo" value="/images/logo.png" shape="rounded" />

  With a `name` the frame is a file picker: clicking the picture opens the chooser, the chosen
  file shows at once and the button puts the first picture back or, with nothing chosen, empties
  the field and sets the hidden `<name>_remove` input to `1`. The behaviour lives in the
  `LedgerUI.ImageInput` hook (`priv/static/ledger_ui/hooks/image_input.js`).

  Without a `name` it is only the frame (the design's `lu-imgin`): `initials` draws a filled
  frame with letters, `hover` forces the edit overlay and `progress` draws the upload ring.

  Deviations from the README: `size` has no default (`nil` is the design's 88px frame with a
  large icon, same as `md`) and `shape` accepts `square` (the design's default radius) and
  `wide` too.
  """
  use LedgerUI.Component

  @sizes %{"sm" => 56, "md" => 88, "lg" => 108, "xl" => 128}

  attr :id, :string, default: nil

  attr :name, :string,
    default: nil,
    doc: "The name of the file input; `<name>_remove` is the hidden one."

  attr :value, :string, default: nil, doc: "The address of the picture it holds now."
  attr :accept, :string, default: ".png,.jpg,.jpeg,.webp"
  attr :size, :string, default: nil, values: [nil | Map.keys(@sizes)]
  attr :shape, :string, default: "circle", values: ~w(circle rounded square wide)
  attr :label, :string, default: "Choose a picture"
  attr :remove_label, :string, default: "Remove or revert the picture"

  attr :initials, :string,
    default: nil,
    doc: "Letters on a filled frame when there is no picture."

  attr :hover, :boolean, default: false, doc: "Draws the edit overlay (the hover state)."
  attr :progress, :integer, default: nil, doc: "An upload ring, 0 to 100."
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "Renders the image field."
  def image_input(assigns) do
    has? = assigns.value != nil or assigns.initials != nil
    interactive? = assigns.name != nil
    px = @sizes[assigns.size]

    style =
      [
        px && "width:#{px}px;height:#{px}px",
        assigns.shape == "rounded" && "border-radius:14px"
      ]
      |> Enum.filter(& &1)
      |> Enum.join(";")

    assigns =
      assigns
      |> assign(:id, assigns.id || assigns.name || "image-input")
      |> assign(:has?, has?)
      |> assign(:interactive?, interactive?)
      |> assign(:attrs, if(style == "", do: %{}, else: %{style: style}))
      |> assign(:icon_size, if(assigns.size || assigns.shape == "rounded", do: "md", else: "lg"))
      |> assign(
        :cls,
        cx([
          "lu-imgin",
          assigns.shape == "circle" && "circle",
          assigns.shape == "wide" && "wide",
          has? && "has",
          assigns.hover && "hover",
          assigns.class
        ])
      )
      |> assign(:ring, assigns.progress && "--sp:#{assigns.progress}%")

    ~H"""
    <%= if @interactive? do %>
      <div
        id={@id}
        data-part="image-input"
        phx-hook="LedgerUI.ImageInput"
        style="position:relative;display:inline-flex"
        {@rest}
      >
        <div class={@cls} keep-class {@attrs}>
          <img
            :if={@value}
            src={@value}
            alt=""
            style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover"
          />
          <.icon :if={!@has?} name="image" size={@icon_size} />
          <span :if={@initials && !@value}>{@initials}</span>
          <span class="ov"><.icon name="edit" /></span>
          <span :if={@ring} class="rg" style={@ring}></span>
          <input
            type="file"
            name={@name}
            accept={@accept}
            aria-label={@label}
            disabled={@disabled}
            style="position:absolute;inset:0;width:100%;height:100%;opacity:0;cursor:pointer"
          />
        </div>
        <input type="hidden" name={@name <> "_remove"} value="" data-image-remove />
        <button
          type="button"
          class="lu-btn icon sm"
          aria-label={@remove_label}
          hidden={!@has?}
          disabled={@disabled}
          data-image-reset
          style="position:absolute;right:-6px;bottom:-6px;border-radius:50%"
        >
          <.icon name="x" />
        </button>
      </div>
    <% else %>
      <div data-part="image-input" id={@id} class={@cls} {@attrs} {@rest}>
        <img
          :if={@value}
          src={@value}
          alt=""
          style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover"
        />
        <.icon :if={!@has?} name="image" size={@icon_size} />
        {@initials}
        <span :if={@hover} class="ov"><.icon name="edit" /></span>
        <span :if={@ring} class="rg" style={@ring}></span>
      </div>
    <% end %>
    """
  end
end
