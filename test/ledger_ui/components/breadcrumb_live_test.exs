defmodule LedgerUI.Components.BreadcrumbLiveTest do
  # Regression (#2): dynamic content of the `:item` slot must follow the assigns of the LiveView.
  use ExUnit.Case, async: false
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint LedgerUI.Components.BreadcrumbLiveTest.Endpoint

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :ledger_ui
    @session_options [store: :cookie, key: "_ledger_ui_bc_test", signing_salt: "salt"]
    socket "/live", Phoenix.LiveView.Socket,
      websocket: [connect_info: [session: @session_options]]

    plug Plug.Session, @session_options
  end

  defmodule Live do
    use Phoenix.LiveView
    use LedgerUI, only: [:breadcrumb]

    def mount(_params, session, socket),
      do: {:ok, assign(socket, titulo: "antigo", max: session["max"])}

    def handle_event("rename", %{"t" => t}, socket), do: {:noreply, assign(socket, :titulo, t)}

    def render(assigns) do
      ~H"""
      <button id="go" phx-click="rename" phx-value-t="novo">go</button>
      <.breadcrumb id="bc" max_items={@max}>
        <:item navigate="/a">{@titulo}-a</:item>
        <:item navigate="/b">{@titulo}-b</:item>
        <:item>{@titulo}-c</:item>
        <:item navigate="/d">{@titulo}-d</:item>
        <:item>{@titulo}-e</:item>
      </.breadcrumb>
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

  defp mount_with(max) do
    {:ok, view, _} = live_isolated(build_conn(), Live, session: %{"max" => max})
    view
  end

  test "current step, linked steps follow the assign" do
    view = mount_with(nil)
    html = render(view)
    assert html =~ "antigo-a" and html =~ "antigo-e"
    view |> element("#go") |> render_click()
    html = render(view)

    for s <- ~w(a b c d e), do: assert(html =~ "novo-#{s}")
    refute html =~ "antigo"
  end

  test "with max_items, hidden steps (dropdown) and shown ones follow the assign" do
    view = mount_with(4)
    html = render(view)
    assert html =~ ~s(data-part="breadcrumb-more")
    assert html =~ "antigo-b" and html =~ "antigo-e"
    view |> element("#go") |> render_click()
    html = render(view)

    for s <- ~w(a b c d e), do: assert(html =~ "novo-#{s}")
    refute html =~ "antigo"
  end
end
