defmodule LedgerUI.Components.Hotkey do
  @moduledoc """
  `hotkey/1`: a global keyboard shortcut that pushes an event to the LiveView or runs a `%JS{}`.

      <.hotkey id="aw-hotkey" keys="Mod+j" on_press={JS.push("aw_toggle")} />
      <.hotkey id="new-chat" keys="Mod+Shift+k, Alt+n" on_press="new_conversation" target={@myself} />
      <.hotkey id="save" keys="Mod+s" on_press="save" in_inputs />

  Renders a hidden element; the hook `LedgerUI.Hotkey` (`priv/static/ledger_ui/hooks/hotkey.js`)
  listens to `keydown` on the document and removes the listener when the element leaves the DOM.

  `keys` is one or more combinations separated by commas. A combination is modifiers and a key
  joined by `+`: `Mod`, `Ctrl`, `Cmd` (or `Meta`), `Alt`, `Shift`, then the key (`j`, `Enter`,
  `Escape`, `ArrowUp`, `/`, `Space`...). `Mod` is Cmd on macOS and Ctrl elsewhere. The modifiers
  must match exactly (`Mod+j` does not fire on `Mod+Shift+j`).

  A press while the focus is in an `input`, `select`, `textarea` or `contenteditable` element is
  ignored, unless `in_inputs` is set. A matching press calls `preventDefault`, so the browser's own
  shortcut (Ctrl+J opens the downloads in Chrome) does not run.

  `on_press` is an event name, pushed with `%{"key" => combination}` (to `target` when given: a
  selector or a component id, as for `phx-target`), or a `%JS{}` run on the element
  (`JS.push("evt", target: @myself)` carries its own target).
  """
  use LedgerUI.Component

  attr :id, :string, required: true, doc: "Needed by the hook."

  attr :keys, :string,
    required: true,
    doc: ~s(Combinations separated by commas, e.g. `"Mod+j, Mod+Shift+k"`.)

  attr :on_press, :any, required: true, doc: "An event name or a `%JS{}`."

  attr :target, :any,
    default: nil,
    doc: "`phx-target` of the event name (a selector or `@myself`)."

  attr :in_inputs, :boolean, default: false, doc: "Also fires while typing in a field."
  attr :rest, :global

  def hotkey(assigns) do
    changed0 = assigns.__changed__

    assigns =
      assigns
      |> assign(:on_event, if(is_binary(assigns.on_press), do: assigns.on_press))
      |> assign(:on_js, if(is_struct(assigns.on_press, JS), do: assigns.on_press))

    assigns = settle(assigns, changed0, on_event: [:on_press], on_js: [:on_press])

    ~H"""
    <span
      id={@id}
      data-part="hotkey"
      hidden
      aria-hidden="true"
      data-lu-keys={@keys}
      data-lu-on-press={@on_event}
      data-lu-on-press-js={@on_js}
      data-lu-target={@target}
      data-lu-in-inputs={@in_inputs && "true"}
      phx-hook="LedgerUI.Hotkey"
      {@rest}
    ></span>
    """
  end
end
