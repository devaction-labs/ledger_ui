defmodule LedgerUI.Components.ConnectionBanner do
  @moduledoc """
  The notice of a lost connection, as a toast: while the LiveView socket is down the toaster shows
  a `loading` toast with the ring of light (`aura`), and removes it when the socket is back.

      <.connection_banner />
      <.connection_banner title="Sem conexão" description="Tentando reconectar..." />

  Put it once in the root layout, next to the `<.toaster>` (it needs one on the page). It draws
  nothing by itself and has no JavaScript of its own: `phx-disconnected` runs `show_toast/2` and
  `phx-connected` runs `dismiss_toast/1` (see `LedgerUI.Components.Toast`).
  """
  use LedgerUI.Component

  import LedgerUI.Components.Toast, only: [show_toast: 2, dismiss_toast: 1]

  attr :id, :string, default: "ledger-connection-banner"
  attr :title, :string, default: "Connection lost"
  attr :description, :string, default: "Trying to reconnect..."

  attr :color, :string,
    default: "warning",
    values: ~w(assistant primary secondary info success warning error),
    doc: "The light of the ring."

  attr :rest, :global

  def connection_banner(assigns) do
    assigns =
      assigns
      |> assign(
        :on_disconnected,
        show_toast(assigns.title,
          id: assigns.id,
          kind: :loading,
          description: assigns.description,
          aura: true,
          aura_color: assigns.color,
          duration: :infinity
        )
      )
      |> assign(:on_connected, dismiss_toast(assigns.id))

    ~H"""
    <span
      id={@id}
      data-part="connection-banner"
      hidden
      phx-disconnected={@on_disconnected}
      phx-connected={@on_connected}
      {@rest}
    ></span>
    """
  end
end
