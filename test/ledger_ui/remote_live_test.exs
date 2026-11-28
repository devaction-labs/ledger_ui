defmodule LedgerUI.RemoteLiveTest do
  # #106: select, autocomplete and pillbox with a search on the server, without a handle_event.
  use ExUnit.Case, async: false
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint LedgerUI.RemoteLiveTest.Endpoint

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :ledger_ui
    @session_options [store: :cookie, key: "_ledger_ui_test", signing_salt: "salt"]
    socket "/live", Phoenix.LiveView.Socket,
      websocket: [connect_info: [session: @session_options]]

    plug Plug.Session, @session_options
  end

  defmodule Data do
    @all for n <- 1..40, do: {"Customer #{n}", "c#{n}"}

    def search(query, page) do
      rows = Enum.filter(@all, fn {label, _} -> String.contains?(label, query) end)
      slice = rows |> Enum.drop((page - 1) * 15) |> Enum.take(15)
      {slice, length(rows) > page * 15}
    end
  end

  defmodule Live do
    use Phoenix.LiveView
    use LedgerUI, only: [:select, :autocomplete, :pillbox]

    def mount(_params, _session, socket) do
      socket =
        socket
        |> LedgerUI.Remote.attach(:customers, search: &Data.search/2, debounce: 10)
        |> LedgerUI.Remote.attach(:staff, search: &Data.search/2)
        |> LedgerUI.Remote.attach(:items, search: &Data.search/2)
        |> LedgerUI.Remote.put_selected(:customers, [{"Edited Customer", "c99"}])

      {:ok, assign(socket, ids: ["c99"], staff: nil, item: nil)}
    end

    def handle_event("choose", %{"ids" => ids}, socket), do: {:noreply, assign(socket, ids: ids)}

    def handle_event("pick", %{"item" => item}, socket),
      do: {:noreply, assign(socket, item: item)}

    def render(assigns) do
      ~H"""
      <.pillbox id="pb" name="ids" value={@ids} remote={@remote.customers} />
      <.select id="sel" name="staff" value={@staff} remote={@remote.staff} />
      <.autocomplete id="ac" name="item" value={@item} remote={@remote.items} />
      <.select id="plain" name="plain" options={["a", "b"]} />
      """
    end
  end

  setup_all do
    Application.put_env(:ledger_ui, Endpoint,
      secret_key_base: String.duplicate("k", 64),
      live_view: [signing_salt: "lu_remote_salt_0123456"]
    )

    start_supervised!(Endpoint)
    :ok
  end

  test "the field is wired to the helper's events, with no handle_event in the caller" do
    {:ok, _view, html} = live_isolated(build_conn(), Live)
    assert html =~ ~s(data-lu-on-search="lu_remote:search:customers")
    assert html =~ ~s(data-lu-on-search="lu_remote:search:staff")
    assert html =~ ~s(data-lu-on-search="lu_remote:search:items")
    assert html =~ ~s(data-lu-debounce="10")
    # the caller has no clause for the search events
    assert_raise FunctionClauseError, fn ->
      Live.handle_event("lu_remote:search:customers", %{}, %Phoenix.LiveView.Socket{})
    end
  end

  test "typing a search shows the answer; the other fields are untouched" do
    {:ok, view, _} = live_isolated(build_conn(), Live)
    refute render(view) =~ "Customer 3"

    render_hook(view, "lu_remote:search:customers", %{"id" => "pb", "query" => "Customer 3"})
    html = render_async(view)
    assert html =~ ~s(data-lu-value="c3")
    assert html =~ ~s(data-lu-value="c30")
    refute html =~ ~s(data-lu-value="c2")
    # `staff` has its own state
    assert state(view, :staff).options == []
  end

  test "load more appends the next page until there is no more" do
    {:ok, view, _} = live_isolated(build_conn(), Live)
    render_hook(view, "lu_remote:search:customers", %{"id" => "pb", "query" => ""})
    html = render_async(view)
    assert html =~ ~s(data-lu-value="c15")
    refute html =~ ~s(data-lu-value="c16")
    assert state(view, :customers).has_more
    assert html =~ ~s(data-lu-on-load-more="lu_remote:more:customers")

    render_hook(view, "lu_remote:more:customers", %{"id" => "pb", "query" => "", "offset" => 15})
    html = render_async(view)
    assert html =~ ~s(data-lu-value="c16")
    assert html =~ ~s(data-lu-value="c30")
    assert state(view, :customers).has_more

    render_hook(view, "lu_remote:more:customers", %{"id" => "pb", "query" => "", "offset" => 30})
    html = render_async(view)
    assert html =~ ~s(data-lu-value="c40")
    refute state(view, :customers).has_more

    # a load more with nothing left (or for another text) does not search again
    before = state(view, :customers)
    render_hook(view, "lu_remote:more:customers", %{"id" => "pb", "query" => "", "offset" => 40})
    render_async(view)
    assert state(view, :customers) == before
  end

  test "the label of a selected value survives a search that no longer returns it" do
    {:ok, view, _} = live_isolated(build_conn(), Live)
    # the edit form: c99 was never searched, `put_selected/3` gave its label
    assert render(view) =~ "Edited Customer"

    render_hook(view, "lu_remote:search:customers", %{"id" => "pb", "query" => ""})
    render_async(view)
    render_hook(view, "choose", %{"ids" => ["c99", "c2"]})
    assert render(view) =~ ~r/<option value="c2" selected[^>]*>Customer 2<\/option>/
    assert render(view) =~ ~r/<option value="c99" selected[^>]*>Edited Customer<\/option>/

    # a search with other results: the chosen ones keep their labels
    render_hook(view, "lu_remote:search:customers", %{"id" => "pb", "query" => "Customer 3"})
    html = render_async(view)
    refute Enum.any?(state(view, :customers).options, &match?({_, "c2"}, &1))
    assert html =~ ~r/<option value="c2" selected[^>]*>Customer 2<\/option>/
    assert html =~ ~r/<option value="c99" selected[^>]*>Edited Customer<\/option>/
  end

  test "an autocomplete keeps the label of its value when the options no longer have it" do
    {:ok, view, _} = live_isolated(build_conn(), Live)
    render_hook(view, "lu_remote:search:items", %{"query" => "Customer 7"})
    render_async(view)
    render_hook(view, "pick", %{"item" => "c7"})
    render_hook(view, "lu_remote:search:items", %{"query" => "Customer 3"})
    html = render_async(view)
    refute html =~ ~s(data-lu-value="c7")
    assert html =~ ~r/<input[^>]*value="Customer 7"/
  end

  test "a stale answer is dropped" do
    {:ok, view, _} = live_isolated(build_conn(), Live)
    render_hook(view, "lu_remote:search:staff", %{"query" => "Customer 1"})
    render_hook(view, "lu_remote:search:staff", %{"query" => "Customer 2"})
    render_async(view)
    assert state(view, :staff).query == "Customer 2"
  end

  test "without remote the HTML has no helper wiring" do
    {:ok, _view, html} = live_isolated(build_conn(), Live)
    plain = html |> String.split(~s(id="plain")) |> List.last()
    refute plain =~ "lu_remote"
  end

  defp state(view, name) do
    :sys.get_state(view.pid).socket.assigns.remote[name]
  end
end
