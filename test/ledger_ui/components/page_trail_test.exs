defmodule LedgerUI.Components.PageTrailTest do
  use ExUnit.Case, async: false
  import Phoenix.Component
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import LedgerUI.Components.PageTrail

  alias LedgerUI.PageTrail

  @endpoint LedgerUI.Components.PageTrailTest.Endpoint

  # ---------------------------------------------------------------------------------------
  # a tiny app: endpoint, router with the on_mount, two LiveViews

  defmodule ClientsLive do
    use Phoenix.LiveView
    use LedgerUI, only: [:page_trail]
    @behaviour LedgerUI.PageTrail

    @impl true
    def mount(_params, _session, socket) do
      {:ok,
       socket
       |> assign(:page_title, "Clientes")
       |> assign(:tab, "list")
       |> PageTrail.put_page(icon: "users")
       |> PageTrail.put_state(%{"tab" => "list"})}
    end

    @impl true
    def handle_params(_params, _uri, socket), do: {:noreply, socket}

    @impl PageTrail
    def page_trail_restore(%{"tab" => tab}, socket) when is_binary(tab),
      do: socket |> assign(:tab, tab) |> PageTrail.put_state(%{"tab" => tab})

    def page_trail_restore(_state, socket), do: socket

    @impl true
    def render(assigns) do
      ~H"""
      <span id="tab">{@tab}</span>
      <.page_trail id="trail" trail={@page_trail} max={4} max_pinned={2} />
      """
    end
  end

  defmodule PlainLive do
    # no put_page, no put_state, no callback
    use Phoenix.LiveView
    use LedgerUI, only: [:page_trail]

    @impl true
    def mount(_params, _session, socket), do: {:ok, assign(socket, :page_title, "Painel")}
    @impl true
    def handle_params(_params, _uri, socket), do: {:noreply, socket}

    @impl true
    def render(assigns) do
      ~H"""
      <.page_trail id="trail" trail={@page_trail} />
      """
    end
  end

  defmodule SeededLive do
    use Phoenix.LiveView
    use LedgerUI, only: [:page_trail]

    @impl true
    def mount(_params, _session, socket) do
      {:ok,
       socket
       |> assign(:page_title, "Semente")
       |> PageTrail.put_trail(%{
         "pinned" => [%{"path" => "/plain", "href" => "/plain", "label" => "Painel"}],
         "recent" => [%{"path" => "/nope", "href" => "/nope", "label" => "Sumiu"}]
       })}
    end

    @impl true
    def handle_params(_params, _uri, socket), do: {:noreply, socket}

    @impl true
    def render(assigns) do
      ~H"""
      <.page_trail id="trail" trail={@page_trail} />
      """
    end
  end

  defmodule Router do
    use Phoenix.Router
    # the test module imports LiveViewTest, whose `live/2,3` would clash
    import Phoenix.LiveViewTest, only: []
    import Phoenix.LiveView.Router

    live_session :app, on_mount: [{LedgerUI.PageTrail, :default}] do
      live "/clientes", ClientsLive
      live "/clientes/:id", ClientsLive
      live "/plain", PlainLive
      live "/semente", SeededLive
      live "/pedidos/:id", PlainLive, :show
    end
  end

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :ledger_ui
    @session_options [store: :cookie, key: "_ledger_ui_pt_test", signing_salt: "salt"]
    socket "/live", Phoenix.LiveView.Socket,
      websocket: [connect_info: [session: @session_options]]

    plug Plug.Session, @session_options
    plug Router
  end

  @moduletag capture_log: true

  setup_all do
    Application.put_env(:ledger_ui, Endpoint,
      secret_key_base: String.duplicate("k", 64),
      live_view: [signing_salt: "lv_salt_0123456789"]
    )

    start_supervised!(Endpoint)
    :ok
  end

  defp open(path) do
    {:ok, view, _html} = live(Plug.Test.init_test_session(build_conn(), %{}), path)
    view
  end

  # the trail as the browser would store it (`data-lu-trail` of the rendered bar)
  defp stored(view) do
    view
    |> render()
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("#trail")
    |> LazyHTML.attribute("data-lu-trail")
    |> hd()
    |> Jason.decode!()
  end

  defp paths(list), do: Enum.map(list, & &1["path"])

  defp item(path, label \\ nil, extra \\ %{}),
    do:
      Map.merge(
        %{"path" => path, "href" => path, "label" => label || path, "icon" => "file"},
        extra
      )

  # ---------------------------------------------------------------------------------------
  # rendering

  defp it(path, label, icon \\ "file"), do: %{path: path, href: path, label: label, icon: icon}

  defp trail(extra \\ %{}) do
    Map.merge(
      %{
        pinned: [it("/analytics", "Analytics"), it("/kanban", "Kanban")],
        recent: [it("/clientes", "Clientes", "users"), it("/pedidos/4812", "Pedido #4812")],
        current: "/clientes",
        state: nil
      },
      extra
    )
  end

  defp html(assigns) do
    assigns = Map.put_new(assigns, :trail, trail())

    ~H"""
    <.page_trail id="trail" trail={@trail} max={@max} />
    """
    |> rendered_to_string()
    # the labels of `data-lu-trail` would match every text assertion
    |> String.replace(~r/ data-lu-trail="[^"]*"/, "")
  end

  test "pinned first, a divider, then the recents; the current page carries aria-current and the accent stroke" do
    html = html(%{max: 6})

    {pinned, rest} =
      String.split(html, ~s(data-part="page-trail-sep"), parts: 2) |> List.to_tuple()

    assert pinned =~ "Analytics" and pinned =~ "Kanban" and not (pinned =~ "Clientes")
    assert rest =~ "Clientes" and rest =~ "Pedido #4812"
    assert html =~ ~s(data-kind="pinned") and html =~ ~s(data-kind="recent")
    assert html =~ ~s(aria-current="page")
    assert html =~ "after:bg-accent"
    assert html =~ ~s(href="/clientes") and html =~ ~s(data-phx-link="redirect")
    assert html =~ ~s(phx-hook="LedgerUI.PageTrail")
    assert html =~ ~s(data-lu-key="lu:trail") and html =~ ~s(data-lu-path="/clientes")
    refute html =~ "data-lu-state="
  end

  test "a pinned item offers unpin, a recent one pin" do
    html = html(%{max: 6})
    assert html =~ ~s(phx-click="lu:trail:unpin") and html =~ ~s(phx-value-path="/kanban")
    assert html =~ ~s(phx-click="lu:trail:pin") and html =~ ~s(phx-value-path="/pedidos/4812")
    assert html =~ ~s(phx-value-max_pinned="6")
    assert html =~ ~s(aria-label="Pin Pedido #4812")
  end

  test "the action button keeps its space (no layout shift) and shows on hover, focus and touch" do
    html = html(%{max: 6})
    [_, button] = String.split(html, ~s(data-part="page-trail-action"), parts: 2)
    [classes | _] = Regex.run(~r/class="([^"]*)"/, button, capture: :all_but_first)

    assert classes =~ "grid" and classes =~ "opacity-0"
    assert classes =~ "group-hover:opacity-100" and classes =~ "group-focus-within:opacity-100"
    assert classes =~ "pointer-coarse:opacity-100"
    refute classes =~ ~r/(^| )hidden( |$)/
  end

  test "a pinned page that is also the current one is highlighted in the pinned group" do
    html = html(%{max: 6, trail: trail(%{current: "/analytics"})})
    [pinned, _recent] = String.split(html, ~s(data-part="page-trail-sep"), parts: 2)
    assert pinned =~ "after:bg-accent"
  end

  test "first visit: the current page and the hint" do
    html =
      html(%{
        max: 4,
        trail: trail(%{pinned: [], recent: [it("/inicio", "Início")], current: "/inicio"})
      })

    assert html =~ "Início"
    assert html =~ ~s(data-part="page-trail-hint") and html =~ "Pin the pages you use most"
    refute html =~ ~s(data-part="page-trail-sep")
  end

  test "no page at all: Home and the hint" do
    html = html(%{max: 4, trail: nil})
    assert html =~ "Home" and html =~ "Pin the pages you use most"
    assert html =~ ~s(aria-current="page")
  end

  test "compact: icons only, the page icon, the label as title and sr-only" do
    assigns = %{trail: trail()}

    html =
      rendered_to_string(~H"""
      <.page_trail id="trail" trail={@trail} variant="compact" max={6} />
      """)

    assert html =~ ~s(title="Clientes")
    assert html =~ ~s(<span class="sr-only">Clientes</span>)
    refute html =~ ~s(<span>Clientes</span>)
    refute html =~ "Pin the pages you use most"
  end

  test "recent={0} hides the recents and does not store them" do
    assigns = %{trail: trail()}

    html =
      rendered_to_string(~H"""
      <.page_trail id="trail" trail={@trail} recent={0} max={6} />
      """)

    assert html =~ "Analytics" and html =~ "Kanban"
    refute html =~ "Clientes"
    refute html =~ ~s(data-part="page-trail-sep")
    assert html =~ "&quot;recent&quot;:[]"
  end

  test "overflow: max items in the bar (the current one among them), +N and the menu" do
    html = html(%{max: 2, trail: trail(%{current: "/pedidos/4812"})})
    # visible: Analytics + the current (replaces the last slot); 2 hidden
    [bar, menu] = String.split(html, ~s(data-part="page-trail-more"), parts: 2)
    assert bar =~ "Analytics" and bar =~ "Pedido #4812"
    refute bar =~ "Kanban"
    assert menu =~ "+2"
    assert menu =~ "Pinned" and menu =~ "2 of 6"
    assert menu =~ "Recent" and menu =~ ~s(phx-click="lu:trail:clear") and menu =~ "Clear"
    assert menu =~ "/kanban" and menu =~ "/pedidos/4812"
    assert menu =~ "Saved in this browser · comes back without reloading"
    assert menu =~ ~s(role="menuitem")
  end

  test "no +N without overflow" do
    refute html(%{max: 6}) =~ "page-trail-more"
  end

  test "at max_pinned the pin goes away and the hint shows" do
    assigns = %{trail: trail()}

    html =
      rendered_to_string(~H"""
      <.page_trail id="trail" trail={@trail} max={2} max_pinned={2} />
      """)

    assert html =~ "Unpin one to pin another" and html =~ "2 of 2"
    refute html =~ ~s(phx-click="lu:trail:pin")
    assert html =~ ~s(phx-click="lu:trail:unpin")
  end

  test "state, storage, scroll options and on_change reach the hook as data-lu-*" do
    assigns = %{trail: trail(%{state: %{"tab" => "notes"}})}

    html =
      rendered_to_string(~H"""
      <.page_trail
        id="trail"
        trail={@trail}
        key="lu:trail:7"
        state_storage="local"
        scroll_container="#main"
        on_change="trail_changed"
      />
      """)

    assert html =~ ~s(data-lu-key="lu:trail:7")
    assert html =~ ~s(data-lu-state-storage="local")
    assert html =~ ~s(data-lu-scroll-container="#main")
    assert html =~ ~s(data-lu-on-change="trail_changed")
    assert html =~ "data-lu-state=\"{&quot;tab&quot;:&quot;notes&quot;}\""

    off =
      rendered_to_string(~H"""
      <.page_trail id="trail" trail={@trail} scroll={false} />
      """)

    assert off =~ ~s(data-lu-scroll="false")
  end

  test "demo: no hook and no events" do
    assigns = %{trail: trail()}

    html =
      rendered_to_string(~H"""
      <.page_trail id="trail" trail={@trail} demo max={2} />
      """)

    refute html =~ ~s(phx-hook="LedgerUI.PageTrail")
    refute html =~ "data-lu-trail"
    refute html =~ ~s(phx-click="lu:trail)
    assert html =~ "Analytics"
  end

  test "texts follow the locale; a given text wins" do
    assigns = %{
      trail: trail(%{pinned: [], recent: [it("/inicio", "Início")], current: "/inicio"})
    }

    html =
      rendered_to_string(~H"""
      <.page_trail id="trail" trail={@trail} locale="pt_BR" />
      """)

    assert html =~ "Fixe as páginas que você mais usa" and html =~ ~s(aria-label="Páginas")

    html =
      rendered_to_string(~H"""
      <.page_trail id="trail" trail={@trail} hint="Pin it" />
      """)

    assert html =~ "Pin it"
  end

  # ---------------------------------------------------------------------------------------
  # on_mount hooks

  test "registers the current page: base path, last full URL, label from page_title, icon from put_page" do
    view = open("/clientes?status=open")
    assert %{"pinned" => [], "recent" => [recent]} = stored(view)

    assert recent == %{
             "path" => "/clientes",
             "href" => "/clientes?status=open",
             "label" => "Clientes",
             "icon" => "users"
           }

    html = render(view)
    assert html =~ ~s(data-lu-path="/clientes")
    assert html =~ ~s(href="/clientes?status=open")
  end

  test "a page without put_page gets its label from page_title; without both, from the path" do
    assert %{"recent" => [%{"label" => "Painel", "icon" => "file"}]} = stored(open("/plain"))
    view = open("/pedidos/12")
    assert [%{"label" => "Painel"}] = stored(view)["recent"]
  end

  test "patching the same base path updates the href and does not duplicate" do
    view = open("/clientes")
    render_patch(view, "/clientes?status=paid&page=2")
    assert %{"recent" => [item]} = stored(view)
    assert item["href"] == "/clientes?status=paid&page=2"
  end

  test "recents are most recent first and deduplicated by base path" do
    view = open("/clientes")
    render_patch(view, "/clientes/7")
    render_patch(view, "/clientes")
    render_patch(view, "/clientes/7?tab=x")
    assert %{"recent" => recent} = stored(view)
    assert paths(recent) == ["/clientes/7", "/clientes"]
    assert hd(recent)["href"] == "/clientes/7?tab=x"
  end

  test "pin moves a recent to the pinned list; revisiting updates its href; the page is not a recent" do
    view = open("/clientes")
    render_patch(view, "/clientes/7")
    render_hook(view, "lu:trail:pin", %{"path" => "/clientes", "max_pinned" => "6"})

    assert %{"pinned" => [%{"path" => "/clientes"}], "recent" => recent} = stored(view)
    assert paths(recent) == ["/clientes/7"]

    render_patch(view, "/clientes?status=late")
    assert %{"pinned" => [pinned], "recent" => recent} = stored(view)
    assert pinned["href"] == "/clientes?status=late"
    assert paths(recent) == ["/clientes/7"]
  end

  test "pin stops at max_pinned and ignores unknown paths and junk" do
    view = open("/clientes")
    render_patch(view, "/clientes/1")
    render_patch(view, "/clientes/2")
    render_patch(view, "/clientes/3")
    render_hook(view, "lu:trail:pin", %{"path" => "/clientes/1", "max_pinned" => 2})
    render_hook(view, "lu:trail:pin", %{"path" => "/clientes/2", "max_pinned" => 2})
    render_hook(view, "lu:trail:pin", %{"path" => "/clientes/3", "max_pinned" => 2})
    render_hook(view, "lu:trail:pin", %{"path" => "/nunca-visto", "max_pinned" => 9})
    render_hook(view, "lu:trail:pin", %{"path" => ["x"], "max_pinned" => "abc"})
    render_hook(view, "lu:trail:pin", %{})

    assert paths(stored(view)["pinned"]) == ["/clientes/1", "/clientes/2"]
  end

  test "unpin sends the item back to the front of the recents" do
    view = open("/clientes")
    render_patch(view, "/clientes/1")
    render_hook(view, "lu:trail:pin", %{"path" => "/clientes"})
    render_patch(view, "/clientes/2")
    render_hook(view, "lu:trail:unpin", %{"path" => "/clientes"})
    render_hook(view, "lu:trail:unpin", %{"path" => "/clientes"})
    render_hook(view, "lu:trail:unpin", %{"path" => 5})

    assert %{"pinned" => [], "recent" => recent} = stored(view)
    assert paths(recent) == ["/clientes", "/clientes/2", "/clientes/1"]
  end

  test "clear empties the recents but keeps the current page and the pinned ones" do
    view = open("/clientes")
    render_hook(view, "lu:trail:pin", %{"path" => "/clientes"})
    render_patch(view, "/clientes/1")
    render_patch(view, "/clientes/2")
    render_hook(view, "lu:trail:clear", %{})

    assert %{"pinned" => [%{"path" => "/clientes"}], "recent" => [%{"path" => "/clientes/2"}]} =
             stored(view)
  end

  test "pin and unpin work from the buttons (no LiveView code)" do
    view = open("/clientes")
    render_patch(view, "/clientes/1")

    view
    |> element(~s(#trail [data-part="page-trail-item"] [phx-value-path="/clientes"]))
    |> render_click()

    assert paths(stored(view)["pinned"]) == ["/clientes"]
  end

  # ---------------------------------------------------------------------------------------
  # restore: untrusted input

  defp restore(view, trail), do: render_hook(view, "lu:trail:restore", %{"trail" => trail})

  test "restore merges the saved trail: the current page stays first, saved items fill the rest" do
    view = open("/clientes?status=open")

    restore(view, %{
      "pinned" => [item("/plain", "Painel", %{"icon" => "home"})],
      "recent" => [
        item("/clientes", "Clientes (velho)", %{"href" => "/clientes?old=1"}),
        item("/pedidos/9", "Pedido 9")
      ]
    })

    assert %{"pinned" => [pinned], "recent" => recent} = stored(view)
    assert pinned == item("/plain", "Painel", %{"icon" => "home"})
    assert paths(recent) == ["/clientes", "/pedidos/9"]
    assert hd(recent)["href"] == "/clientes?status=open"
  end

  test "restore drops bad paths, schemes, hosts, backslashes and unknown routes" do
    view = open("/clientes")

    bad = [
      item("//evil.test/clientes"),
      item("https://evil.test/clientes"),
      item("javascript:alert(1)"),
      item("clientes"),
      item("/clientes", nil, %{"href" => "//evil.test"}),
      item("/clientes", nil, %{"href" => "/\\evil.test"}),
      item("/clientes", nil, %{"href" => "/clientes#frag"}),
      item("/clientes", nil, %{"href" => "/clientes\r\nSet-Cookie: a=b"}),
      item("/clientes", nil, %{"href" => "/plain?x=1"}),
      item("/plain", nil, %{"href" => "http://evil.test/plain"}),
      item("/nao-existe"),
      item("/plain/extra"),
      item("/plain", nil, %{"href" => "/plain?" <> String.duplicate("a", 2000)}),
      item("/" <> String.duplicate("a", 600)),
      %{"label" => "no path"},
      %{"path" => 3},
      "string",
      nil,
      [1, 2]
    ]

    restore(view, %{"pinned" => bad, "recent" => bad})
    assert %{"pinned" => [], "recent" => [%{"path" => "/clientes"}]} = stored(view)
  end

  test "restore accepts a valid item with a query and a dynamic path" do
    view = open("/clientes")

    restore(view, %{
      "recent" => [item("/pedidos/4812", "Pedido", %{"href" => "/pedidos/4812?tab=2"})]
    })

    assert %{"recent" => [_, %{"href" => "/pedidos/4812?tab=2"}]} = stored(view)
  end

  test "restore sanitizes labels and icons" do
    view = open("/clientes")

    restore(view, %{
      "recent" => [
        item("/plain", String.duplicate("x", 500) <> "\u0007", %{"icon" => "no-such-icon"}),
        item("/pedidos/1", "   \u0000 ", %{"icon" => 5})
      ]
    })

    assert %{"recent" => [_, a, b]} = stored(view)
    assert String.length(a["label"]) == 60 and a["icon"] == "file"
    assert b["label"] == "1"
    assert b["icon"] == "file"
  end

  test "restore caps the sizes of the lists" do
    view = open("/clientes")
    many = for i <- 1..500, do: item("/pedidos/#{i}", "P#{i}")
    restore(view, %{"pinned" => many, "recent" => many})
    %{"pinned" => pinned, "recent" => recent} = stored(view)
    assert length(pinned) <= PageTrail.max_pinned_cap()
    assert length(recent) <= PageTrail.max_recent_cap()
    # a path is either pinned or a recent
    assert MapSet.disjoint?(MapSet.new(paths(pinned)), MapSet.new(paths(recent)))
  end

  test "restore of junk shapes does nothing" do
    view = open("/clientes")
    before = stored(view)

    for junk <- [nil, "x", 3, [], %{"pinned" => "no", "recent" => %{"a" => 1}}],
        do: restore(view, junk)

    assert stored(view) == before
  end

  test "a trail seeded with put_trail is sanitized and wins over the browser copy" do
    view = open("/semente")

    assert %{"pinned" => [%{"path" => "/plain"}], "recent" => [%{"path" => "/semente"}]} =
             stored(view)

    restore(view, %{"pinned" => [item("/pedidos/1")], "recent" => [item("/pedidos/2")]})

    assert %{"pinned" => [%{"path" => "/plain"}], "recent" => [%{"path" => "/semente"}]} =
             stored(view)
  end

  test "sanitize/2 with a router or a socket" do
    raw = %{
      "pinned" => [
        %{"path" => "/clientes", "href" => "/clientes?a=1", "label" => "C", "icon" => "users"}
      ],
      "recent" => [%{path: "/plain", href: "/plain", label: "P"}, item("/x/y")]
    }

    assert %{pinned: [%{href: "/clientes?a=1", icon: "users"}], recent: [%{path: "/plain"}]} =
             PageTrail.sanitize(Router, raw)

    assert %{pinned: [], recent: []} = PageTrail.sanitize(nil, raw)

    assert %{pinned: [_], recent: [_]} =
             PageTrail.sanitize(%Phoenix.LiveView.Socket{router: Router}, raw)
  end

  # ---------------------------------------------------------------------------------------
  # per-screen snapshot

  defp state_attr(view) do
    view
    |> render()
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("#trail")
    |> LazyHTML.attribute("data-lu-state")
  end

  test "put_state puts the snapshot on the bar; a page that never calls it has none" do
    assert [~s({"tab":"list"})] = state_attr(open("/clientes"))
    assert [] = state_attr(open("/plain"))
  end

  test "the saved snapshot reaches page_trail_restore of the LiveView" do
    view = open("/clientes")
    render_hook(view, "lu:trail:state", %{"path" => "/clientes", "state" => %{"tab" => "notes"}})
    assert render(view) =~ ~s(<span id="tab">notes</span>)
    assert [~s({"tab":"notes"})] = state_attr(view)
  end

  test "a snapshot for another path, a non-map or an oversized one is ignored" do
    view = open("/clientes")
    render_hook(view, "lu:trail:state", %{"path" => "/plain", "state" => %{"tab" => "x"}})
    render_hook(view, "lu:trail:state", %{"path" => "/clientes", "state" => "x"})

    render_hook(view, "lu:trail:state", %{
      "path" => "/clientes",
      "state" => %{"tab" => String.duplicate("a", 40_000)}
    })

    assert render(view) =~ ~s(<span id="tab">list</span>)
  end

  test "a screen that did not opt in (no put_state, no callback) is not touched or broken" do
    view = open("/plain")
    render_hook(view, "lu:trail:state", %{"path" => "/plain", "state" => %{"tab" => "x"}})
    assert render(view) =~ "page-trail"
  end

  test "the snapshot of a screen is not carried to the next one when patching" do
    view = open("/clientes")
    assert [_] = state_attr(view)
    render_patch(view, "/clientes/3")
    assert [] = state_attr(view)
  end
end
