defmodule LedgerUI.Components.I18nLiveTest do
  @moduledoc """
  `on_mount {LedgerUI.I18n, :default}` sets the locale of the LiveView process (from the session, or a
  fixed one), for the first render and for the connected one; a `locale` attr still wins, and the
  text follows a `locale` that changes with the assigns.
  """
  use ExUnit.Case, async: false
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint LedgerUI.Components.I18nLiveTest.Endpoint

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :ledger_ui
    @session_options [store: :cookie, key: "_ledger_ui_i18n_test", signing_salt: "salt"]
    socket "/live", Phoenix.LiveView.Socket,
      websocket: [connect_info: [session: @session_options]]

    plug Plug.Session, @session_options
  end

  defmodule FromSession do
    use Phoenix.LiveView
    use LedgerUI, only: [:alert]
    on_mount {LedgerUI.I18n, :default}

    def mount(_params, _session, socket), do: {:ok, assign(socket, :attr, nil)}

    def handle_event("attr", %{"l" => l}, socket), do: {:noreply, assign(socket, :attr, l)}

    def render(assigns) do
      ~H"""
      <button id="go" phx-click="attr" phx-value-l="en">go</button>
      <.alert title="T" dismissible locale={@attr} />
      """
    end
  end

  defmodule Fixed do
    use Phoenix.LiveView
    use LedgerUI, only: [:alert]
    on_mount {LedgerUI.I18n, {:locale, "pt_BR"}}

    def mount(_params, _session, socket), do: {:ok, socket}

    def render(assigns) do
      ~H"""
      <.alert title="T" dismissible />
      <.alert title="T" dismissible locale="en" />
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

  setup do
    on_exit(fn -> LedgerUI.put_locale(nil) end)
  end

  test "the locale of the session, in the connected render and in the change of the attr" do
    {:ok, view, html} =
      live_isolated(build_conn(), FromSession, session: %{"locale" => "pt-BR"})

    assert html =~ ~s(aria-label="Fechar")
    assert render(view) =~ ~s(aria-label="Fechar")

    view |> element("#go") |> render_click()
    assert render(view) =~ ~s(aria-label="Close")
  end

  test "without a locale in the session the default stays English" do
    {:ok, _view, html} = live_isolated(build_conn(), FromSession, session: %{})
    assert html =~ ~s(aria-label="Close")
  end

  test "a fixed locale, and the attr wins over it" do
    {:ok, view, _} = live_isolated(build_conn(), Fixed)
    html = render(view)
    assert html =~ ~s(aria-label="Fechar")
    assert html =~ ~s(aria-label="Close")
  end
end
