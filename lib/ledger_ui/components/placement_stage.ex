defmodule LedgerUI.Components.PlacementStage do
  @moduledoc """
  An image (a rendered PDF page, a photo) with a dashed box on it that the user positions by
  clicking or dragging, and resizes from a corner handle.

      <.placement_stage
        id="pdf-stage"
        src={@image}
        alt="Page 1"
        box={%{left: 10, bottom: 20, width: 30, height: 8}}
        resizable
        on_place="place_signature"
        on_resize="resize_signature"
      >
        Signature appears here
      </.placement_stage>

  ## The box

  `box` is a map of percentages of the image: `left` (from the left edge), `bottom` (from the
  bottom edge), `width` and `height`, which is how the CSS is written (`left:10%;bottom:20%`). A
  `nil` box draws no box. The slot is the content of the box (a label, an icon).

  ## Events

  The `LedgerUI.PlacementStage` hook (`priv/static/ledger_ui/hooks/placement_stage.js`) moves the
  box at once, in the browser (optimistic), limited to the edges of the image, and tells the
  server at the end of the gesture (pointer up or click):

    * `on_place`, `%{"x" => x, "y" => y}`: the **centre** of the box, as fractions `0..1` of the
      image; `x` counts from the **left** edge and `y` from the **top** edge. The centre is the
      one of the box as it is shown, already limited so the box stays inside the image.
    * `on_resize`, `%{"width" => w}`: the new width, a fraction `0..1` of the image width. The
      handle keeps the centre and the proportions of the box (so the height follows), and the
      width is never less than 5% nor more than the image allows around the centre.

  Event names are strings; `phx-target` (for a live component) is read from the component.

  Pointer events cover mouse, pen and touch (`touch-action: none` on the stage, pointer capture).
  Pressing the image puts the centre of the box under the pointer. The box is focusable: the arrow
  keys move it by 1% of the image (Shift: 10%) and every key press pushes `on_place`. `label` is
  its `aria-label`.

  The server wins: a new `box` replaces what the browser shows, except in the middle of a gesture
  (it is ignored until the pointer is released) and while an event of this component has not been
  answered yet (an unchanged `box` does not undo a move that is on its way to the server).

  `resizable={false}` removes the handle; `disabled` shows the box and takes away the gestures.
  """
  use LedgerUI.Component

  @ledger_ui_event_guard true

  @stage "relative block w-full touch-none select-none"
  @image "pointer-events-none block w-full"
  @box "absolute flex items-center justify-center rounded-[5px] border border-dashed border-accent-500 bg-accent-soft text-xs text-accent-content " <>
         "shadow-[0_0_0_3px_color-mix(in_oklab,var(--lu-accent)_14%,transparent)] focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] focus-visible:outline-none"
  @handle "absolute -right-1.5 -bottom-1.5 size-3.5 cursor-nwse-resize touch-none rounded-sm border-2 border-panel bg-accent-500 shadow-sm before:absolute before:-inset-2 before:content-['']"

  attr :id, :string, required: true
  attr :src, :string, required: true
  attr :alt, :string, default: ""
  attr :box, :map, default: nil, doc: "`%{left, bottom, width, height}`, in % of the image."
  attr :resizable, :boolean, default: true
  attr :disabled, :boolean, default: false
  attr :on_place, :string, default: nil
  attr :on_resize, :string, default: nil
  attr :label, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(phx-target)
  slot :inner_block

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def placement_stage(assigns) do
    changed0 = assigns.__changed__
    assigns = I18n.texts(assigns, label: "placement.label")

    box = assigns.box

    assigns =
      assigns
      |> assign(:classes, cx([@stage, assigns.class]))
      |> assign(:box_style, box && box_style(box))
      |> assign(:box_data, box && box_data(box))
      |> assign(:interactive, not assigns.disabled)
      |> assign(:image_class, @image)
      |> assign(:box_class, @box)
      |> assign(:handle_class, @handle)

    assigns =
      settle(assigns, changed0,
        classes: [:class],
        box_style: [:box],
        box_data: [:box],
        interactive: [:disabled],
        image_class: [],
        box_class: [],
        handle_class: []
      )

    ~H"""
    <div
      id={@id}
      data-part="placement-stage"
      class={@classes}
      phx-hook="LedgerUI.PlacementStage"
      data-lu-box={@box_data}
      data-lu-on-place={@on_place}
      data-lu-on-resize={@on_resize}
      data-lu-disabled={@disabled && "true"}
      {@rest}
    >
      <img src={@src} alt={@alt} draggable="false" class={@image_class} />
      <div
        :if={@box}
        id={"#{@id}-box"}
        data-part="placement-box"
        role="group"
        tabindex={@interactive && "0"}
        aria-label={@label}
        class={@box_class}
        style={@box_style}
      >
        {render_slot(@inner_block)}
        <span
          :if={@resizable and @interactive}
          data-part="placement-handle"
          data-handle
          aria-hidden="true"
          class={@handle_class}
        ></span>
      </div>
    </div>
    """
  end

  defp box_style(box) do
    "left:#{num(box, :left)}%;bottom:#{num(box, :bottom)}%;width:#{num(box, :width)}%;height:#{num(box, :height)}%"
  end

  defp box_data(box),
    do: Enum.map_join([:left, :bottom, :width, :height], ",", &num(box, &1))

  defp num(box, key) do
    case Map.get(box, key, Map.get(box, to_string(key), 0)) do
      v when is_integer(v) -> Integer.to_string(v)
      v when is_float(v) -> v |> Float.round(3) |> Float.to_string() |> trim()
      _ -> "0"
    end
  end

  defp trim(s), do: s |> String.trim_trailing("0") |> String.trim_trailing(".")
end
