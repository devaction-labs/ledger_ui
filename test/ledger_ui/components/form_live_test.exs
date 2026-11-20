defmodule LedgerUI.Components.FormLiveTest do
  # `Form.field` renders its slots in place: a labeled control whose state the server changes must re-render.
  use ExUnit.Case, async: false
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint LedgerUI.Components.FormLiveTest.Endpoint

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :ledger_ui
    @session_options [store: :cookie, key: "_ledger_ui_test", signing_salt: "salt"]
    socket "/live", Phoenix.LiveView.Socket,
      websocket: [connect_info: [session: @session_options]]

    plug Plug.Session, @session_options
  end

  defmodule Live do
    use Phoenix.LiveView
    use LedgerUI, only: [:field]

    def mount(_params, _session, socket), do: {:ok, assign(socket, method: "pix", err: [])}

    def handle_event("set", %{"m" => m}, socket), do: {:noreply, assign(socket, method: m)}
    def handle_event("err", _, socket), do: {:noreply, assign(socket, err: ["required"])}

    def render(assigns) do
      ~H"""
      <button id="boleto" phx-click="set" phx-value-m="boleto">Boleto</button>
      <button id="err" phx-click="err">Err</button>
      <.field label="Method" errors={@err} help="Pick one">
        <span id="current" data-method={@method}>{@method}</span>
      </.field>
      <.field label="Inline" layout="inline" errors={@err} help="Pick one">
        <span id="inline-current">{@method}</span>
        <:aside><i id="aside">{@method}</i></:aside>
      </.field>
      """
    end
  end

  setup_all do
    Application.put_env(:ledger_ui, Endpoint,
      secret_key_base: String.duplicate("k", 64),
      live_view: [signing_salt: "lv_salt_0123456789"]
    )

    start_supervised!(Endpoint)
    :ok
  end

  test "a labeled control re-renders when the server changes its state" do
    {:ok, view, html} = live_isolated(build_conn(), Live)
    assert html =~ ~s(data-method="pix")
    assert has_element?(view, "#current", "pix")

    view |> element("#boleto") |> render_click()
    assert has_element?(view, "#current", "boleto")
    refute has_element?(view, "#current", "pix")
    refute render(view) =~ ~s(data-method="pix")
    assert has_element?(view, "#inline-current", "boleto")
    assert has_element?(view, "#aside", "boleto")

    view |> element("#err") |> render_click()
    assert render(view) =~ "required"
  end
end
