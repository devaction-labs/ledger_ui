defmodule LedgerUI.Components.ConnectionBanner do
  @moduledoc """
  The notice of a lost connection, as a toast: while the LiveView socket is down the toaster shows
  a `loading` toast with the ring of light (`aura`), and removes it when the socket is back.

      <.connection_banner />
      <.connection_banner title="Sem conexão" description="Tentando reconectar..." />

  `position="top"` or `"bottom"` puts that toast at the top or the bottom centre (the toaster's own place
  when omitted).

  Put it once in the root layout, next to the `<.toaster>` (it needs one on the page). It draws
  nothing by itself and has no JavaScript of its own: `phx-disconnected` runs `show_toast/2` and
  `phx-connected` runs `dismiss_toast/1` (see `LedgerUI.Components.Toast`).

  With `preview` it draws the strip of each state instead (for docs and design reviews; it has no
  behaviour): `state` is `off` (no connection), `re` (reconnecting, with a turning ring), `on`
  (connected) or `cycle` (the three in turn, in a 9s loop).

      <.connection_banner preview state="off" label="Sem conexão" />
      <.connection_banner preview state="cycle" />
  """
  use LedgerUI.Component

  import LedgerUI.Components.Toast, only: [show_toast: 2, dismiss_toast: 1]

  attr :id, :string, default: "ledger-connection-banner"
  attr :title, :string, default: nil
  attr :description, :string, default: nil

  attr :color, :string,
    default: "warning",
    values: ~w(assistant primary secondary info success warning error),
    doc: "The light of the ring."

  attr :position, :string,
    default: nil,
    values: [nil, "top", "bottom"],
    doc:
      "Where the toast sits: `top` (`center-top`) or `bottom` (`center-bottom`); the toaster's own when `nil`."

  attr :preview, :boolean,
    default: false,
    doc: "Draw the strip of `state` where it is written (no hooks, no toast)."

  attr :state, :string,
    default: "off",
    values: ~w(off re on cycle),
    doc: "Only with `preview`: lost, reconnecting, connected, or all three in a loop."

  attr :label, :string,
    default: nil,
    doc: "Only with `preview`: the text of the strip (default by state; not for `cycle`)."

  attr :cycle_labels, :list,
    default: nil,
    doc: "Only with `preview` and `state=\"cycle\"`: the three texts, in order."

  attr :class, :any, default: nil
  attr :rest, :global

  @strip "flex items-center gap-2.5 rounded-[12px] px-3.5 py-[9px] text-[13.5px]"
  @states %{
    "off" => "bg-neg-soft text-neg",
    "re" => "bg-warn-soft text-warn",
    "on" => "bg-pos-soft text-pos",
    "cycle" => "animate-[mo-conn_9s_steps(1)_infinite] bg-neg-soft text-neg"
  }
  @cycle_span [
    "animate-[mo-connt_9s_steps(1)_infinite]",
    "animate-[mo-connt2_9s_steps(1)_infinite]",
    "animate-[mo-connt3_9s_steps(1)_infinite]"
  ]

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def connection_banner(%{preview: true} = assigns) do
    changed0 = assigns.__changed__

    assigns =
      I18n.texts(assigns,
        title: "connection_banner.title",
        description: "connection_banner.description",
        cycle_labels: {:list, "connection_banner.cycle"}
      )

    assigns =
      assigns
      |> assign(:strip_cls, [@strip, @states[assigns.state]])
      |> assign(:text, assigns.label || state_text(assigns))
      |> assign(:cycle, Enum.zip(@cycle_span, assigns.cycle_labels))

    # `text` also reads the process locale (`state_text/1` with no `locale`): it follows `locale`
    assigns =
      settle(assigns, changed0,
        strip_cls: [:state],
        text: [:label, :state, :locale],
        cycle: [:cycle_labels]
      )

    ~H"""
    <div data-part="connection-banner" role="status" class={[@strip_cls, @class]} {@rest}>
      <.icon :if={@state in ["off", "cycle"]} name="wifi" size="md" />
      <span
        :if={@state == "re"}
        data-part="connection-banner-ring"
        class="size-4 flex-none animate-[lu-spin_.9s_linear_infinite] rounded-full border-2 border-current border-r-transparent"
      ></span>
      <.icon :if={@state == "on"} name="check-circle" size="md" />
      <span :if={@state != "cycle"} data-part="connection-banner-text" class="block flex-1">{@text}</span>
      <span :if={@state == "cycle"} data-part="connection-banner-text" class="flex-1">
        <span :for={{anim, text} <- @cycle} class={["hidden", anim]}>{text}</span>
      </span>
    </div>
    """
  end

  def connection_banner(assigns) do
    changed0 = assigns.__changed__

    assigns =
      I18n.texts(assigns,
        title: "connection_banner.title",
        description: "connection_banner.description",
        cycle_labels: {:list, "connection_banner.cycle"}
      )

    assigns =
      assigns
      |> assign(
        :on_disconnected,
        show_toast(
          assigns.title,
          [
            id: assigns.id,
            kind: :loading,
            description: assigns.description,
            aura: true,
            aura_color: assigns.color,
            duration: :infinity
          ] ++ position_opt(assigns.position)
        )
      )
      |> assign(:on_connected, dismiss_toast(assigns.id))

    assigns =
      settle(assigns, changed0,
        on_disconnected: [:title, :description, :id, :color, :position],
        on_connected: [:id]
      )

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

  defp position_opt("top"), do: [position: "center-top"]
  defp position_opt("bottom"), do: [position: "center-bottom"]
  defp position_opt(_), do: []

  defp state_text(%{state: state, locale: locale}) when state in ["off", "re", "on"],
    do: I18n.t("connection_banner.#{state}", locale)

  defp state_text(_), do: nil
end
