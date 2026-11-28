defmodule LedgerUI.Components.Persist do
  @moduledoc """
  `persist/1`: keeps a piece of LiveView state in the browser and gives it back when it mounts.

      <.persist
        id="agent-widget"
        key="agent_widget"
        storage="session"
        value={%{open: @open?, conversation_id: @cid}}
        on_restore="aw_restore"
      />

      def handle_event("aw_restore", %{"value" => %{"open" => open?, "conversation_id" => cid}}, socket),
        do: {:noreply, assign(socket, open?: open?, cid: cid)}

  Renders a hidden element; the hook `LedgerUI.Persist` (`priv/static/ledger_ui/hooks/persist.js`)
  writes `value` (as JSON) under `key` in `sessionStorage` or `localStorage` (`storage`) on every
  `mounted` and `updated`, unless it did not change.

  On mount, when something is saved under `key` and it differs from the current `value`, the hook
  pushes `on_restore` with `%{"value" => saved}` **before** writing, and does not write the current
  value over it (the server's reply, `updated`, writes the restored one). So the saved value
  survives a `push_navigate`: the next mount restores it. A value that is not valid JSON is
  ignored (and overwritten by the next write). Storage that is blocked or full is ignored too.

  > #### Not a place for secrets {: .warning}
  > The value stays in the browser (readable by any script of the page and by the user, and in
  > `localStorage` it outlives the tab). Do not put tokens, passwords or personal data in it, and
  > do not trust it: it is user input when it comes back through `on_restore`, so validate it in
  > the `handle_event`.

  `target` is the `phx-target` of `on_restore` (a selector or `@myself`). Give each persisted state
  its own `id` and `key`.
  """
  use LedgerUI.Component

  @ledger_ui_event_guard true

  attr :id, :string, required: true, doc: "Needed by the hook."
  attr :key, :string, required: true, doc: "The storage key."
  attr :value, :any, required: true, doc: "Anything that encodes to JSON."
  attr :storage, :string, default: "session", values: ~w(session local)
  attr :on_restore, :string, default: nil, doc: "Event pushed with `%{\"value\" => saved}`."
  attr :target, :any, default: nil, doc: "`phx-target` of `on_restore`."
  attr :rest, :global

  def persist(assigns) do
    changed0 = assigns.__changed__
    assigns = assign(assigns, :json, Phoenix.json_library().encode!(assigns.value))
    assigns = settle(assigns, changed0, json: [:value])

    ~H"""
    <span
      id={@id}
      data-part="persist"
      hidden
      aria-hidden="true"
      data-lu-key={@key}
      data-lu-storage={@storage}
      data-lu-value={@json}
      data-lu-on-restore={@on_restore}
      data-lu-target={@target}
      phx-hook="LedgerUI.Persist"
      {@rest}
    ></span>
    """
  end
end
