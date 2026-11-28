defmodule LedgerUI.Components.MissingFormIdLiveTest do
  # #108: the LiveView 1.2 test client warns about a `<form phx-change>` without `id` (form recovery
  # does not work without it). `conversation_list` with `on_search` and `auth_page` with `on_change`
  # must not trigger it, with or without an `id`. The tests run with the warning set to `:raise`, so a
  # form of the kit without `id` (or `phx-ignore-missing-id`) fails them.
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint LedgerUI.Components.MissingFormIdLiveTest.Endpoint

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :ledger_ui
    @session_options [store: :cookie, key: "_ledger_ui_test", signing_salt: "salt"]
    socket "/live", Phoenix.LiveView.Socket,
      websocket: [connect_info: [session: @session_options]]

    plug Plug.Session, @session_options
  end

  defmodule Live do
    use Phoenix.LiveView
    use LedgerUI, only: [:conversation_list, :auth_page]

    def mount(_params, session, socket) do
      {:ok, assign(socket, :which, session["which"])}
    end

    def handle_event(_event, _params, socket), do: {:noreply, socket}

    def render(%{which: "list_id"} = assigns) do
      ~H"""
      <.conversation_list
        id="convs"
        on_search="search"
        conversations={[%{id: "1", title: "A", day: "Today"}]}
      />
      """
    end

    def render(%{which: "list_no_id"} = assigns) do
      ~H"""
      <.conversation_list on_search="search" conversations={[%{id: "1", title: "A", day: "Today"}]} />
      """
    end

    def render(%{which: "auth_id"} = assigns) do
      ~H"""
      <.auth_page id="auth" on_change="validate">
        <input name="email" />
      </.auth_page>
      """
    end

    def render(%{which: "auth_form_id"} = assigns) do
      ~H"""
      <.auth_page form_id="login-form" on_change="validate">
        <input name="email" />
      </.auth_page>
      """
    end

    def render(%{which: "auth_no_id"} = assigns) do
      ~H"""
      <.auth_page on_change="validate">
        <input name="email" />
      </.auth_page>
      """
    end

    # a control: the very warning the tests below must not see
    def render(%{which: "control"} = assigns) do
      ~H"""
      <form phx-change="x"><input name="q" /></form>
      """
    end
  end

  setup_all do
    Application.put_env(:ledger_ui, Endpoint,
      secret_key_base: String.duplicate("k", 64),
      live_view: [signing_salt: "lu_form_id_salt_01234"]
    )

    start_supervised!(Endpoint)
    :ok
  end

  defp mount_with(which, on_error) do
    conn = Plug.Test.init_test_session(build_conn(), %{"which" => which})

    {:ok, view, html} =
      live_isolated(conn, Live, session: %{"which" => which}, on_error: on_error)

    _ = render(view)
    html
  end

  # The warning goes to stderr, from the proxy process.
  defp warnings(which) do
    capture_io(:stderr, fn ->
      mount_with(which, missing_form_id: :warn)
      Process.sleep(50)
    end)
  end

  test "the control form without id does produce the warning (the tests below can fail)" do
    assert warnings("control") =~ "Detected a form with phx-change but missing id"
  end

  test "with :raise the control form crashes the mount (so :raise is a real guard)" do
    Process.flag(:trap_exit, true)

    capture_io(:stderr, fn ->
      result = catch_exit(mount_with("control", missing_form_id: :raise))
      assert inspect(result) =~ "missing id"
    end)
  end

  for which <- ~w(list_id list_no_id auth_id auth_form_id auth_no_id) do
    test "#{which}: no missing_form_id warning" do
      refute warnings(unquote(which)) =~ "missing id"
      # and with `:raise` the mount does not crash
      html = mount_with(unquote(which), missing_form_id: :raise)
      assert html =~ "phx-change"
    end
  end
end
