defmodule LedgerUI.Components.SlotForwardingLiveTest do
  # Issue #23: `card_table`/`data_table` re-wrapped every `:col` in a new closure that captured the
  # whole `assigns` (which holds the previous list of slots), so each layer of slot forwarding
  # multiplied the *flat* size of the LiveView state (what a copy between processes, e.g. a crash
  # report, sees) by the number of columns, while the heap size stayed small (shared terms).
  use ExUnit.Case, async: false
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint LedgerUI.Components.SlotForwardingLiveTest.Endpoint

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :ledger_ui
    @session_options [store: :cookie, key: "_ledger_ui_sf", signing_salt: "salt"]
    socket "/live", Phoenix.LiveView.Socket,
      websocket: [connect_info: [session: @session_options]]

    plug Plug.Session, @session_options
  end

  defmodule Live do
    use Phoenix.LiveView
    use LedgerUI, only: [:card_table, :data_table]

    @cols ~w(a b c d)

    def mount(_params, session, socket) do
      rows = for i <- 1..4, do: Map.new(@cols, &{&1, "#{&1}#{i}"}) |> Map.put(:id, i)
      {:ok, assign(socket, rows: rows, layers: session["layers"], kind: session["kind"])}
    end

    # Baseline: the same slots rendered by plain markup, with no library component in between.
    attr :rows, :list, required: true

    slot :col, required: true do
      attr :label, :string
    end

    def plain_table(assigns) do
      ~H"""
      <table id="t">
        <tr :for={r <- @rows}>
          <td :for={c <- @col}>{render_slot(c, r)}</td>
        </tr>
      </table>
      """
    end

    # An app component that forwards its columns (a new `<:col>` per column, as the issue
    # describes), `layers` times before it reaches the table.
    attr :layers, :integer, required: true
    attr :kind, :string, required: true
    attr :rows, :list, required: true

    slot :col do
      attr :label, :string
    end

    def layer(%{layers: 1, kind: "card"} = assigns) do
      ~H"""
      <.card_table id="t" rows={@rows} row_id={&"r#{&1.id}"}>
        <:col :let={r} :for={c <- @col} label={c.label}>{render_slot(c, r)}</:col>
      </.card_table>
      """
    end

    def layer(%{layers: 1, kind: "data"} = assigns) do
      ~H"""
      <.data_table id="t" rows={@rows} row_id={&"r#{&1.id}"}>
        <:col :let={r} :for={c <- @col} label={c.label}>{render_slot(c, r)}</:col>
      </.data_table>
      """
    end

    def layer(%{layers: 1, kind: "plain"} = assigns) do
      ~H"""
      <.plain_table rows={@rows}>
        <:col :let={r} :for={c <- @col} label={c.label}>{render_slot(c, r)}</:col>
      </.plain_table>
      """
    end

    def layer(assigns) do
      ~H"""
      <.layer layers={@layers - 1} kind={@kind} rows={@rows}>
        <:col :let={r} :for={c <- @col} label={c.label}>{render_slot(c, r)}</:col>
      </.layer>
      """
    end

    # No layer: the columns are declared right on the table.
    def render(%{layers: 0, kind: "card"} = assigns) do
      ~H"""
      <.card_table id="t" rows={@rows} row_id={&"r#{&1.id}"}>
        <:col :let={r} label="A">{r["a"]}</:col>
        <:col :let={r} label="B">{r["b"]}</:col>
        <:col :let={r} label="C">{r["c"]}</:col>
        <:col :let={r} label="D">{r["d"]}</:col>
      </.card_table>
      """
    end

    def render(%{layers: 0, kind: "data"} = assigns) do
      ~H"""
      <.data_table id="t" rows={@rows} row_id={&"r#{&1.id}"}>
        <:col :let={r} label="A">{r["a"]}</:col>
        <:col :let={r} label="B">{r["b"]}</:col>
        <:col :let={r} label="C">{r["c"]}</:col>
        <:col :let={r} label="D">{r["d"]}</:col>
      </.data_table>
      """
    end

    def render(%{layers: 0, kind: "plain"} = assigns) do
      ~H"""
      <.plain_table rows={@rows}>
        <:col :let={r} label="A">{r["a"]}</:col>
        <:col :let={r} label="B">{r["b"]}</:col>
        <:col :let={r} label="C">{r["c"]}</:col>
        <:col :let={r} label="D">{r["d"]}</:col>
      </.plain_table>
      """
    end

    def render(assigns) do
      ~H"""
      <.layer layers={@layers} kind={@kind} rows={@rows}>
        <:col :let={r} label="A">{r["a"]}</:col>
        <:col :let={r} label="B">{r["b"]}</:col>
        <:col :let={r} label="C">{r["c"]}</:col>
        <:col :let={r} label="D">{r["d"]}</:col>
      </.layer>
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

  # `size` (shared terms counted once) and `flat_size` (what a copy sees) of the fingerprints,
  # measured inside the view process so that nothing big is copied to the test process (the view
  # is left without fingerprints afterwards, and only lives until the end of the test).
  defp sizes(kind, layers) do
    {:ok, view, html} =
      live_isolated(build_conn(), Live, session: %{"layers" => layers, "kind" => kind})

    assert html =~ "a1"
    me = self()

    :sys.replace_state(view.pid, fn st ->
      send(
        me,
        {:sizes, :erts_debug.size(st.fingerprints), :erts_debug.flat_size(st.fingerprints)}
      )

      # `:sys.replace_state/2` returns the new state to the caller (a copy): leave out the big part
      %{st | fingerprints: nil}
    end)

    assert_receive {:sizes, size, flat}
    {size, flat}
  end

  # `layers` is the number of times the *app* forwards the columns before the table (that
  # re-wrapping is app code and costs what it costs, in the plain markup too); with 0 the columns
  # are declared right on the table. The library must add no re-wrapping of its own: measured
  # against the same slots rendered by plain markup, before the fix `flat_size` was ~18-21x the
  # plain one (one extra hop through the whole chain, 5.9e6 vs 3.0e5 words at 1 layer); now it is
  # ~2x (the table's own, heavier markup), at every depth.
  for kind <- ~w(card data), layers <- 0..3 do
    test "#{kind}_table with #{layers} app layers: flat size is close to plain markup's" do
      {size, flat} = sizes(unquote(kind), unquote(layers))
      {_, plain_flat} = sizes("plain", unquote(layers))

      assert flat < 3 * plain_flat,
             "flat_size #{flat} (size #{size}) is #{Float.round(flat / plain_flat, 1)}x that of plain markup (#{plain_flat})"
    end
  end
end
