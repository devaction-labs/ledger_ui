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

  Without a `name` it is only the frame: `initials` draws a filled
  frame with letters, `hover` forces the edit overlay and `progress` draws the upload ring.

  Deviations from the README: `size` has no default (`nil` is the design's 88px frame with a
  large icon, same as `md`) and `shape` accepts `square` (the design's default radius) and
  `wide` too.
  """
  use LedgerUI.Component

  @sizes %{
    "sm" => "size-[56px]",
    "md" => "size-[88px]",
    "lg" => "size-[108px]",
    "xl" => "size-[128px]"
  }

  # the frame: dashed and empty; with a picture (`data-state` has `has`, set by the hook too) it is solid and
  # the accent gradient behind the initials; `hover` there shows the edit overlay
  @frame "group relative grid flex-none place-items-center overflow-hidden border-[1.5px] border-dashed border-line-strong bg-sunken text-muted " <>
           "data-[state~=has]:border-solid data-[state~=has]:border-line data-[state~=has]:bg-[linear-gradient(135deg,var(--lu-accent-300),var(--lu-accent-600))] data-[state~=has]:text-[24px] data-[state~=has]:font-semibold data-[state~=has]:text-white"

  @radius %{
    "circle" => "rounded-full",
    "rounded" => "rounded-lg",
    "square" => "rounded-xl",
    "wide" => "rounded-lg"
  }

  @overlay "absolute inset-0 grid place-items-center bg-black/45 text-white opacity-0 group-data-[state~=hover]:opacity-100"
  @ring "absolute inset-1.5 rounded-full bg-[conic-gradient(#fff_var(--lu-sp,0%),rgba(255,255,255,.25)_0)] [-webkit-mask:radial-gradient(farthest-side,transparent_80%,#000_82%)] [mask:radial-gradient(farthest-side,transparent_80%,#000_82%)]"
  @cover "absolute inset-0 size-full object-cover"
  @reset "absolute -right-1.5 -bottom-1.5 inline-flex size-[30px] cursor-pointer items-center justify-center rounded-full border border-line-strong bg-panel text-ink shadow-xs " <>
           "transition-[background,border-color,box-shadow] duration-150 hover:bg-hover focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] focus-visible:outline-none disabled:cursor-not-allowed disabled:opacity-45 disabled:shadow-none [&_svg]:size-4"

  attr :id, :string, default: nil

  attr :name, :string,
    default: nil,
    doc: "The name of the file input; `<name>_remove` is the hidden one."

  attr :value, :string, default: nil, doc: "The address of the picture it holds now."
  attr :accept, :string, default: ".png,.jpg,.jpeg,.webp"
  attr :size, :string, default: nil, values: [nil | Map.keys(@sizes)]
  attr :shape, :string, default: "circle", values: ~w(circle rounded square wide)
  attr :label, :string, default: nil
  attr :remove_label, :string, default: nil

  attr :initials, :string,
    default: nil,
    doc: "Letters on a filled frame when there is no picture."

  attr :hover, :boolean, default: false, doc: "Draws the edit overlay (the hover state)."

  attr :loop, :string,
    default: nil,
    values: [nil, "hover", "ring"],
    doc: "Animated demo of a state: `hover` loops the edit overlay, `ring` loops the upload ring."

  attr :progress, :integer, default: nil, doc: "An upload ring, 0 to 100."
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global

  @doc "Renders the image field."
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def image_input(assigns) do
    assigns = I18n.texts(assigns, label: "image_input.choose", remove_label: "image_input.remove")

    has? = assigns.value != nil or assigns.initials != nil

    box =
      cond do
        assigns.size -> @sizes[assigns.size]
        assigns.shape == "wide" -> "h-[88px] w-[200px]"
        true -> "size-[88px]"
      end

    assigns =
      assigns
      |> assign(:id, assigns.id || assigns.name || "image-input")
      |> assign(:has?, has?)
      |> assign(
        :state,
        case {has?, assigns.hover} do
          {true, true} -> "has hover"
          {true, _} -> "has"
          {_, true} -> "hover"
          _ -> nil
        end
      )
      |> assign(:interactive?, assigns.name != nil)
      |> assign(:icon_size, if(assigns.size || assigns.shape == "rounded", do: "md", else: "lg"))
      |> assign(:cls, [@frame, box, @radius[assigns.shape], assigns.class])
      |> assign(:overlay, [
        @overlay,
        assigns.loop == "hover" && "animate-[lu-ovloop_4s_ease-in-out_infinite]"
      ])
      |> assign(:ring_cls, [
        @ring,
        assigns.loop == "ring" && "animate-[lu-slloop2_4s_linear_infinite]"
      ])
      |> assign(:ring, assigns.progress && "--lu-sp:#{assigns.progress}%")
      |> assign(:cover, @cover)
      |> assign(:reset, @reset)

    ~H"""
    <%= if @interactive? do %>
      <div
        id={@id}
        data-part="image-input"
        phx-hook="LedgerUI.ImageInput"
        class="relative inline-flex"
        {@rest}
      >
        <div
          data-part="image-input-frame"
          class={@cls}
          data-state={@state}
          keep-data-state
        >
          <img :if={@value} data-part="image-input-image" src={@value} alt="" class={@cover} />
          <.icon :if={!@has?} data-part="image-input-placeholder" name="image" size={@icon_size} />
          <span :if={@initials && !@value} data-part="image-input-initials">{@initials}</span>
          <span data-part="image-input-overlay" class={@overlay}><.icon name="edit" /></span>
          <span :if={@ring} data-part="image-input-ring" class={@ring_cls} style={@ring}></span>
          <input
            type="file"
            name={@name}
            accept={@accept}
            aria-label={@label}
            disabled={@disabled}
            data-part="image-input-file"
            class="absolute inset-0 size-full cursor-pointer opacity-0"
          />
        </div>
        <input type="hidden" name={@name <> "_remove"} value="" data-image-remove />
        <button
          type="button"
          data-part="image-input-reset"
          class={@reset}
          aria-label={@remove_label}
          hidden={!@has?}
          disabled={@disabled}
          data-image-reset
        >
          <.icon name="x" />
        </button>
      </div>
    <% else %>
      <div
        data-part="image-input"
        id={@id}
        class={@cls}
        data-state={@state}
        {@rest}
      >
        <img :if={@value} data-part="image-input-image" src={@value} alt="" class={@cover} />
        <.icon :if={!@has?} name="image" size={@icon_size} />
        {@initials}
        <span :if={@hover or @loop == "hover"} data-part="image-input-overlay" class={@overlay}>
          <.icon name="edit" />
        </span>
        <span :if={@ring} data-part="image-input-ring" class={@ring_cls} style={@ring}></span>
        <span :if={@loop == "ring" and !@ring} data-part="image-input-ring" class={@ring_cls}></span>
      </div>
    <% end %>
    """
  end
end
