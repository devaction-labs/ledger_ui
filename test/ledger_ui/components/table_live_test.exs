defmodule LedgerUI.Components.TableLiveTest do
  # The sort headers and the selection boxes of `Table` push events; the server re-renders the rows.
  use ExUnit.Case, async: false
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint LedgerUI.Components.TableLiveTest.Endpoint

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :ledger_ui
    @session_options [store: :cookie, key: "_ledger_ui_test", signing_salt: "salt"]
    socket "/live", Phoenix.LiveView.Socket,
      websocket: [connect_info: [session: @session_options]]

    plug Plug.Session, @session_options
  end

  defmodule Live do
    use Phoenix.LiveView
    use LedgerUI, only: [:table]

    @rows [%{id: 1, n: "b"}, %{id: 2, n: "a"}, %{id: 3, n: "c"}]

    def mount(_params, _session, socket),
      do: {:ok, assign(socket, rows: @rows, sort_by: "n", sort_dir: "asc", selected: [])}

    def handle_event("sort", %{"column" => col, "direction" => dir}, socket) do
      rows = Enum.sort_by(@rows, & &1.n, if(dir == "asc", do: :asc, else: :desc))
      {:noreply, assign(socket, rows: rows, sort_by: col, sort_dir: dir)}
    end

    def handle_event("sel", %{"id" => id, "selected" => "true"}, socket),
      do: {:noreply, update(socket, :selected, &Enum.uniq([id | &1]))}

    def handle_event("sel", %{"id" => id, "selected" => "false"}, socket),
      do: {:noreply, update(socket, :selected, &List.delete(&1, id))}

    def handle_event("all", %{"selected" => "true"}, socket),
      do: {:noreply, assign(socket, :selected, Enum.map(@rows, &to_string(&1.id)))}

    def handle_event("all", %{"selected" => "false"}, socket),
      do: {:noreply, assign(socket, :selected, [])}

    def render(assigns) do
      ~H"""
      <.table
        id="t"
        rows={@rows}
        row_id={&"r#{&1.id}"}
        row_key={&to_string(&1.id)}
        sort_by={@sort_by}
        sort_dir={@sort_dir}
        on_sort="sort"
        on_select="sel"
        on_select_all="all"
        selected={@selected}
      >
        <:col :let={r} label="N" sort_key="n">{r.n}</:col>
      </.table>
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
    {:ok, view, _html} = live_isolated(build_conn(), Live)
    {:ok, view: view}
  end

  defp order(view),
    do:
      view
      |> render()
      |> then(&Regex.scan(~r/<td[^>]*data-part="table-cell"[^>]*>\s*([abc])\s*<\/td>/, &1))
      |> Enum.map(&List.last/1)

  test "a sortable header flips the direction and the rows follow", %{view: view} do
    assert order(view) == ~w(b a c)
    assert render(view) =~ ~s(aria-sort="ascending")
    view |> element("th[phx-value-column=n]") |> render_click()
    assert order(view) == ~w(c b a)
    assert render(view) =~ ~s(aria-sort="descending")
    view |> element("th[phx-value-column=n]") |> render_click()
    assert order(view) == ~w(a b c)
  end

  test "rows and select-all toggle the selection and the dash of the header box", %{view: view} do
    refute render(view) =~ "data-ind"
    view |> element("#r1 input[type=checkbox]") |> render_click()
    html = render(view)
    assert html =~ ~r/ class="[^"]*\[--s:color-mix/
    assert html =~ ~s(data-ind="1")

    view |> element("#t-select-all") |> render_click()
    html = render(view)
    assert length(Regex.scan(~r/ class="[^"]*\[--s:color-mix/, html)) == 3
    refute html =~ ~s(data-ind="1")

    view |> element("#t-select-all") |> render_click()
    refute render(view) =~ ~r/ class="[^"]*\[--s:color-mix/
  end
end
