defmodule LedgerUI.Components.TableViewportTest do
  # `on_viewport_top` / `on_viewport_bottom` (#101): `phx-viewport-*` on the element that holds the
  # stream, so the LiveView watches the rows and not the `<thead>`.
  use ExUnit.Case, async: false
  use Phoenix.Component
  use LedgerUI

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint LedgerUI.Components.TableViewportTest.Endpoint

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :ledger_ui
    @session_options [store: :cookie, key: "_ledger_ui_vp", signing_salt: "salt"]
    socket "/live", Phoenix.LiveView.Socket,
      websocket: [connect_info: [session: @session_options]]

    plug Plug.Session, @session_options
  end

  defmodule Live do
    use Phoenix.LiveView
    use LedgerUI, only: [:table]

    defp page(n), do: for(i <- (n * 3 - 2)..(n * 3), do: %{id: i, n: "item #{i}"})

    def mount(_params, _session, socket),
      do: {:ok, socket |> assign(page: 1) |> stream(:items, page(1))}

    def handle_event("next-page", _params, socket) do
      n = socket.assigns.page + 1
      {:noreply, socket |> assign(page: n) |> stream(:items, page(n), at: -1, limit: -6)}
    end

    def render(assigns) do
      ~H"""
      <.table id="t" rows={@streams.items} on_viewport_bottom="next-page">
        <:col :let={{_id, r}} label="N">{r.n}</:col>
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

  defp stream_rows, do: Phoenix.LiveView.LiveStream.new(:items, 0, [%{id: 1, n: "a"}], [])

  defp html(assigns, fun),
    do: assigns |> fun.() |> rendered_to_string()

  defp t(assigns) do
    ~H"""
    <.table id="t" rows={@rows} on_viewport_top={@top} on_viewport_bottom={@bottom} {@extra}>
      <:col :let={{_id, r}} label="N">{r.n}</:col>
    </.table>
    """
  end

  defp tag(html, name), do: Regex.run(~r/<#{name}\b[^>]*>/s, html) |> hd()

  defp base(extra \\ %{}),
    do: %{rows: stream_rows(), top: "prev", bottom: %Phoenix.LiveView.JS{}, extra: extra}

  test "the attributes go on the <tbody> that holds the stream, not on the <table>" do
    html = html(base(), &t/1)
    body = tag(html, "tbody")
    assert body =~ ~s(phx-update="stream")
    assert body =~ ~s(phx-viewport-top="prev")
    assert body =~ "phx-viewport-bottom="
    assert body =~ ~s(phx-viewport-overrun-target="t-wrap")
    refute tag(html, "table") =~ "phx-viewport"
    assert tag(html, "div") =~ ~s(id="t-wrap")
  end

  test "with row_groups they go on the <table> that holds the stream" do
    html = html(base(%{row_groups: true}), &t/1)
    table = tag(html, "table")
    assert table =~ ~s(phx-update="stream")
    assert table =~ ~s(phx-viewport-top="prev")
    assert table =~ ~s(phx-viewport-overrun-target="t-wrap")
    refute html =~ ~r/<tbody[^>]*phx-viewport/
  end

  test "without a wrapper there is no overrun target" do
    html = html(base(%{wrapper: false}), &t/1)
    assert tag(html, "tbody") =~ "phx-viewport-top"
    refute html =~ "overrun-target"
  end

  test "without the attributes the HTML has no viewport attribute and the wrapper has no id" do
    html = html(%{base() | top: nil, bottom: nil}, &t/1)
    refute html =~ "phx-viewport"
    refute html =~ "t-wrap"
  end

  defp dt(assigns) do
    ~H"""
    <.data_table id="d" rows={@rows} on_viewport_bottom="more" page_size={10} total={1}>
      <:col :let={{_id, r}} label="N">{r.n}</:col>
    </.data_table>
    """
  end

  defp ct(assigns) do
    ~H"""
    <.card_table id="c" rows={@rows} on_viewport_bottom="more">
      <:col :let={{_id, r}} label="N">{r.n}</:col>
    </.card_table>
    """
  end

  test "data_table and card_table pass them to the stream" do
    for f <- [&dt/1, &ct/1] do
      html = html(%{rows: stream_rows()}, f)
      assert tag(html, "tbody") =~ ~s(phx-viewport-bottom="more")
    end
  end

  defp wrap_class(html), do: Regex.run(~r/<div[^>]*data-part="table-wrap"[^>]*>/s, html) |> hd()

  describe "the wrapper and the LiveView's scroll container (#101)" do
    test "with the attributes and no height the wrapper scrolls only on x, so the page is the scroller" do
      html = html(base(), &t/1)
      assert wrap_class(html) =~ ~s(class="overflow-x-auto overflow-y-clip rounded-lg border)
      refute wrap_class(html) =~ "overflow-auto"
    end

    test "a wrapper_class with a height or an overflow says the wrapper is the scroller" do
      for wc <- ["max-h-[400px]", "h-96", "overflow-auto", "md:max-h-80 p-1", ["x", "max-h-10"]] do
        html = html(base(%{wrapper_class: wc}), &t/1)
        assert wrap_class(html) =~ ~s(class="overflow-auto rounded-lg border), wc
        refute wrap_class(html) =~ "overflow-y-clip"
      end
    end

    test "without the attributes, or on a list, the wrapper is the one it always was" do
      for assigns <- [%{base() | top: nil, bottom: nil}, %{base() | rows: [%{id: 1, n: "a"}]}] do
        html = html(assigns, &t_list/1)

        assert wrap_class(html) =~
                 ~s(class="overflow-auto rounded-lg border border-line bg-panel")
      end
    end

    test "bleed keeps the same overflow rule" do
      html = html(base(%{bleed: true}), &t/1)
      assert wrap_class(html) =~ ~s(class="overflow-x-auto overflow-y-clip")
    end

    test "the card body of a data_table follows the same rule" do
      assigns = %{rows: stream_rows()}
      html = html(assigns, &dtc/1)
      assert html =~ ~r/data-part="data-table-body"\s+class="[^"]*overflow-x-auto overflow-y-clip/

      html = html(assigns, &dtc_h/1)
      assert html =~ ~r/data-part="data-table-body"\s+class="[^"]*overflow-auto bg-panel/
    end
  end

  describe "the kit's hook next to the LiveView's (#101)" do
    # the LiveView puts `Phoenix.InfiniteScroll` on the element with `phx-viewport-*` and that
    # replaces its `phx-hook`: the kit's hook goes to another element
    test "no row_groups: on the <table>, none on the <tbody>" do
      html = html(base(), &t/1)
      assert tag(html, "table") =~ ~s(phx-hook="LedgerUI.TableSelect")
      refute tag(html, "tbody") =~ "phx-hook"
    end

    test "row_groups: on the <thead>, none on the <table> that has the viewport attributes" do
      html = html(base(%{row_groups: true}), &t/1)
      refute tag(html, "table") =~ "phx-hook"
      assert tag(html, "thead") =~ ~s(phx-hook="LedgerUI.TableSelect")
    end

    test "row_groups and headless: on the wrapper" do
      html = html(base(%{row_groups: true, headless: true}), &t/1)
      refute tag(html, "table") =~ "phx-hook"
      assert wrap_class(html) =~ ~s(phx-hook="LedgerUI.TableSelect")
    end

    test "the panel hook (details or copy) takes the place on the table or the thead" do
      html = html(base(), &tc/1)
      assert tag(html, "table") =~ ~s(phx-hook="LedgerUI.CardTable")
      refute tag(html, "tbody") =~ "phx-hook"

      html = html(base(%{row_groups: true}), &tc/1)
      assert tag(html, "thead") =~ ~s(phx-hook="LedgerUI.CardTable")
      refute tag(html, "table") =~ "phx-hook"
    end

    test "without the attributes the hooks are where they always were" do
      html = html(%{base() | top: nil, bottom: nil}, &tc/1)
      assert tag(html, "tbody") =~ ~s(phx-hook="LedgerUI.CardTable")
      refute tag(html, "table") =~ "phx-hook"
      refute tag(html, "thead") =~ "phx-hook"
    end
  end

  defp t_list(assigns) do
    ~H"""
    <.table id="t" rows={@rows} on_viewport_top={@top} on_viewport_bottom={@bottom}>
      <:col :let={r} label="N">{if is_map(r), do: r.n}</:col>
    </.table>
    """
  end

  defp tc(assigns) do
    ~H"""
    <.table id="t" rows={@rows} on_viewport_top={@top} on_viewport_bottom={@bottom} {@extra}>
      <:col :let={{_id, r}} label="N" copy={fn {_id, r} -> r.n end}>{r.n}</:col>
    </.table>
    """
  end

  defp dtc(assigns) do
    ~H"""
    <.data_table id="d" body="card" rows={@rows} on_viewport_bottom="more" page_size={10} total={1}>
      <:col :let={{_id, r}} label="N">{r.n}</:col>
    </.data_table>
    """
  end

  defp dtc_h(assigns) do
    ~H"""
    <.data_table
      id="d"
      body="card"
      rows={@rows}
      on_viewport_bottom="more"
      wrapper_class="max-h-96"
      page_size={10}
      total={1}
    >
      <:col :let={{_id, r}} label="N">{r.n}</:col>
    </.data_table>
    """
  end

  test "the viewport event loads the next page and the limit prunes the first" do
    {:ok, view, html} = live_isolated(build_conn(), Live)
    assert html =~ "item 1" and html =~ "item 3"

    view |> element("#t-body") |> render_hook("next-page", %{})
    html = render(view)
    assert html =~ "item 4" and html =~ "item 6"

    view |> element("#t-body") |> render_hook("next-page", %{})
    html = render(view)
    assert html =~ "item 9"
    refute html =~ "item 1<"
  end
end
