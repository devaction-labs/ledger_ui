defmodule LedgerUI.PageTrail do
  @moduledoc """
  The server side of `<.page_trail>` (`LedgerUI.Components.PageTrail`): the screen tabs of the
  navbar. An `on_mount` that records the screens a person opens and lets them pin the ones they
  use most, `put_page/2` and `put_state/2` for the LiveViews, and the sanitizing of everything
  that comes back from the browser.

  ## Setup

      # router
      live_session :app, on_mount: [MyAppWeb.UserAuth, {LedgerUI.PageTrail, :default}] do
        live "/clientes", ClientsLive
      end

      # a LiveView
      socket |> assign(:page_title, "Clientes") |> LedgerUI.PageTrail.put_page(icon: "users")

      # layout
      <.page_trail id="trail" trail={@page_trail} max={4} max_pinned={6} />

  `on_mount` assigns `:page_trail` (`%{pinned: [item], recent: [item], current: path, state: map | nil}`),
  attaches a `handle_params` hook that registers the current screen, and `handle_event` hooks for
  `"lu:trail:pin"`, `"lu:trail:unpin"`, `"lu:trail:clear"`, `"lu:trail:restore"` and
  `"lu:trail:state"` (all halted: no code in your LiveViews). An item is
  `%{path: "/clientes", href: "/clientes?status=open", label: "Clientes", icon: "users"}`.

  ## What is remembered

    * An item is identified by its **base path** (no query string) and keeps the **last full URL**
      visited (`href`: path and query). The link of an item is `<.link navigate={item.href}>`, so
      the filters you kept in the URL come back through your own `handle_params`. A pinned item
      opens in its last state too: visiting `/clientes?status=open` updates the `href` of the
      pinned `/clientes`.
    * Recents are most recent first, deduplicated by base path; the current screen is a recent
      unless it is pinned. Pinning moves a recent to the pinned list, unpinning moves it back to
      the recents. Pins stop at `max_pinned` (the `max_pinned` attr of the component, at most 20).
    * The label of an item is `put_page(label: ...)`, else `@page_title` (read when the screen is
      registered, so assign it before `put_page/2`), else the last segment of the path.
    * The trail lives in the browser (`localStorage`, the `key` attr, `"lu:trail"` by default) and
      is pushed back on mount (`"lu:trail:restore"`). Every item is validated, see "Sanitizing".

  > #### Not a place for secrets {: .warning}
  > The trail (paths, query strings, labels), the per-screen snapshot and the scroll positions stay
  > in the browser: readable by any script of the page and by the user, and in `localStorage` they
  > outlive the tab. A query string is saved too, so do not keep tokens, e-mails or other personal data in
  > the URL of a screen you want in the trail, and never put secrets in `put_state/2`. On a shared
  > machine scope the key per user (`key={"lu:trail:\#{@current_user.id}"}`) so one person never gets the
  > trail of another. Everything that comes back is user input and is validated here.

  ## Sanitizing (restore is untrusted input)

  Every item that arrives (`"lu:trail:restore"`, connect params, `put_trail/2`, `sanitize/2`) is
  dropped unless:

    * `href` is a relative URL that starts with a single `/` (no `//`, scheme, host, backslash,
      `#`, control character or invalid UTF-8), at most 1024 bytes, and `path` is its path
      without the query (at most 512 bytes);
    * the path matches a route of `socket.router` (`Phoenix.Router.route_info/4`, GET), so a page
      that no longer exists, or a made-up URL, never reaches a `navigate`;
    * `icon` is a known icon (otherwise `"file"`); `label` is cut to 60 characters, trimmed and
      stripped of control characters (blank: the path decides it).

  At most 50 raw items per list are looked at and 20 are kept. A router with a catch-all route
  accepts every path: validate beyond that in your own code if it matters.

  ## Per-screen snapshot (state that is not in the URL)

  Filters belong in the URL. What does not (expanded rows, an inner tab, a draft) can be
  saved with `put_state/2`:

      def mount(_params, _session, socket) do
        {:ok, LedgerUI.PageTrail.put_state(socket, %{"tab" => "notes", "open" => [3, 7]})}
      end

      @behaviour LedgerUI.PageTrail

      @impl LedgerUI.PageTrail
      def page_trail_restore(%{"tab" => tab}, socket), do: assign(socket, :tab, tab)
      def page_trail_restore(_state, socket), do: socket

  Call `put_state/2` again whenever that state changes. The hook writes it as JSON to
  `sessionStorage` (the tab; `state_storage="local"` for `localStorage`) under
  `lu:trail:state:<base path>`. On the next mount of that same base path, if the LiveView called
  `put_state/2` (the rendered element carries the state), the hook pushes `"lu:trail:state"` and
  `on_mount` calls the optional callback `c:page_trail_restore/2` of the LiveView with the saved
  map and returns the socket you return. The callback is synchronous, so nothing is ever sent to
  `handle_info`; a LiveView that never calls `put_state/2`, or has no callback, is not touched.
  The state is user input: validate it (it is capped at 32 KB and must be a map).

  ## Scroll position

  The hook saves the scroll position of the current base path when a navigation starts and puts
  it back after the next mount of that path (the window, or the element of the `scroll_container`
  attr). `scroll={false}` turns it off.

  ## Prefs and `on_change`

  `on_change="trail_changed"` pushes that event on every change with `%{"trail" => %{"pinned" => [...],
  "recent" => [...]}}` so the app can keep it in the user preferences:

      def handle_event("trail_changed", %{"trail" => trail}, socket) do
        trail = LedgerUI.PageTrail.sanitize(socket, trail)   # it came from the browser
        Accounts.save_pref(socket.assigns.current_user, :trail, trail)
        {:noreply, socket}
      end

  To seed from them, call `put_trail/2` in your own `on_mount` or `mount` (before this
  hook's `handle_params` runs it is merged: the screen is registered afterwards). A seeded trail wins
  over the browser's: the saved copy of `localStorage` is then ignored, so a pin removed on another
  device does not come back.

  ## Without flicker (optional)

  Navigating to another LiveView mounts a new process, so the trail is empty for the first
  render and the hook restores it a moment later. Give the saved trail to the server at connect time
  and it is there from the first connected render:

      // app.js
      new LiveSocket("/live", Socket, {
        params: () => ({_csrf_token: csrfToken, lu_trail: safeGet("lu:trail")})  // localStorage.getItem in a try
      })

  `lu_trail` is sanitized like any restore.
  """

  alias Phoenix.LiveView.Socket

  @max_pinned 20
  @max_recent 20
  @raw_limit 50
  @max_label 60
  @max_path 512
  @max_href 1024
  @max_state 32_768
  @default_max_pinned 6
  @default_icon "file"

  @type item :: %{
          path: String.t(),
          href: String.t(),
          label: String.t(),
          icon: String.t()
        }

  @type t :: %{
          pinned: [item()],
          recent: [item()],
          current: String.t() | nil,
          state: map() | nil
        }

  @doc """
  Called with the map the screen saved by `put_state/2` when it mounts again (user input: validate
  it). Return the socket.
  """
  @callback page_trail_restore(state :: map(), socket :: Socket.t()) :: Socket.t()
  @optional_callbacks page_trail_restore: 2

  @doc "The hard cap of pinned items (the `max_pinned` attr never goes above it)."
  @spec max_pinned_cap() :: pos_integer()
  def max_pinned_cap, do: @max_pinned

  @doc "The hard cap of recent items."
  @spec max_recent_cap() :: pos_integer()
  def max_recent_cap, do: @max_recent

  # ---------------------------------------------------------------------------------------
  # on_mount

  @doc false
  def on_mount(:default, _params, _session, socket) do
    socket =
      socket
      |> init()
      |> attach_hooks()

    {:cont, socket}
  end

  defp attach_hooks(socket) do
    socket =
      if socket.router,
        do:
          Phoenix.LiveView.attach_hook(
            socket,
            :lu_page_trail_params,
            :handle_params,
            &handle_params/3
          ),
        else: socket

    Phoenix.LiveView.attach_hook(socket, :lu_page_trail_events, :handle_event, &handle_event/3)
  end

  defp init(socket) do
    trail =
      case socket.assigns do
        %{page_trail: %{} = t} -> normalize(t)
        _ -> empty()
      end

    socket = Phoenix.Component.assign(socket, :page_trail, trail)

    if Phoenix.LiveView.connected?(socket) do
      case connect_trail(socket) do
        nil -> socket
        saved -> update_trail(socket, &merge(&1, sanitize(socket, saved)))
      end
    else
      socket
    end
  end

  defp connect_trail(socket) do
    case Phoenix.LiveView.get_connect_params(socket) do
      %{"lu_trail" => json} when is_binary(json) and byte_size(json) <= 65_536 ->
        case Phoenix.json_library().decode(json) do
          {:ok, %{} = map} -> map
          _ -> nil
        end

      %{"lu_trail" => %{} = map} ->
        map

      _ ->
        nil
    end
  end

  defp empty,
    do: %{pinned: [], recent: [], current: nil, state: nil, href: nil, meta: %{}, seeded: false}

  defp normalize(t) do
    Map.merge(empty(), %{
      pinned: Map.get(t, :pinned, []),
      recent: Map.get(t, :recent, []),
      current: Map.get(t, :current),
      state: Map.get(t, :state),
      meta: Map.get(t, :meta, %{}),
      seeded: Map.get(t, :seeded, false)
    })
  end

  # ---------------------------------------------------------------------------------------
  # handle_params: register the current screen

  defp handle_params(_params, uri, socket) do
    case location(uri) do
      nil ->
        {:cont, update_trail(socket, &%{&1 | href: nil, current: nil})}

      href ->
        # a new screen starts without the snapshot of the previous one (the first one keeps
        # what `mount/3` put)
        socket =
          update_trail(socket, fn t ->
            if t.href && path_of(t.href) != path_of(href),
              do: %{t | href: href, state: nil, meta: %{}},
              else: %{t | href: href}
          end)

        {:cont, register(socket)}
    end
  end

  defp location(uri) do
    %URI{path: path, query: query} = URI.parse(uri)
    href = (path || "/") <> if(query in [nil, ""], do: "", else: "?" <> query)
    if shape_ok?(href), do: href
  end

  defp register(%{assigns: %{page_trail: %{href: nil}}} = socket), do: socket

  defp register(%{assigns: %{page_trail: t}} = socket) do
    path = path_of(t.href)
    meta = t.meta

    item = %{
      path: path,
      href: t.href,
      label: label_for(socket, meta, path),
      icon: icon_for(meta[:icon])
    }

    {pinned, recent} =
      if Enum.any?(t.pinned, &(&1.path == path)) do
        {Enum.map(t.pinned, fn p -> if p.path == path, do: item, else: p end),
         Enum.reject(t.recent, &(&1.path == path))}
      else
        {t.pinned, [item | Enum.reject(t.recent, &(&1.path == path))] |> Enum.take(@max_recent)}
      end

    Phoenix.Component.assign(socket, :page_trail, %{
      t
      | pinned: pinned,
        recent: recent,
        current: path
    })
  end

  defp label_for(socket, meta, path) do
    candidate =
      case meta do
        %{label: l} when is_binary(l) -> l
        _ -> if is_binary(socket.assigns[:page_title]), do: socket.assigns.page_title
      end

    clean_label(candidate) || humanize(path)
  end

  defp humanize("/"), do: LedgerUI.I18n.t("page_trail.home")

  defp humanize(path) do
    path
    |> String.split("/", trim: true)
    |> List.last()
    |> to_string()
    |> URI.decode()
    |> String.replace(~r/[-_]+/, " ")
    |> clean_label()
    |> case do
      nil -> LedgerUI.I18n.t("page_trail.home")
      text -> String.capitalize(text)
    end
  end

  defp icon_for(icon) when is_binary(icon) and byte_size(icon) <= 40 do
    LedgerUI.Components.Icon.resolve(icon) || @default_icon
  end

  defp icon_for(_), do: @default_icon

  # ---------------------------------------------------------------------------------------
  # events

  defp handle_event("lu:trail:pin", params, socket) do
    max = clamp(params["max_pinned"], @default_max_pinned)

    socket =
      with path when is_binary(path) <- params["path"],
           %{pinned: pinned, recent: recent} <- socket.assigns.page_trail,
           true <- length(pinned) < max,
           %{} = item <- Enum.find(recent, &(&1.path == path)) do
        update_trail(socket, fn t ->
          %{t | pinned: t.pinned ++ [item], recent: Enum.reject(t.recent, &(&1.path == path))}
        end)
      else
        _ -> socket
      end

    {:halt, socket}
  end

  defp handle_event("lu:trail:unpin", params, socket) do
    socket =
      with path when is_binary(path) <- params["path"],
           %{} = item <- Enum.find(socket.assigns.page_trail.pinned, &(&1.path == path)) do
        update_trail(socket, fn t ->
          %{
            t
            | pinned: Enum.reject(t.pinned, &(&1.path == path)),
              recent: Enum.take([item | Enum.reject(t.recent, &(&1.path == path))], @max_recent)
          }
        end)
      else
        _ -> socket
      end

    {:halt, socket}
  end

  defp handle_event("lu:trail:clear", _params, socket) do
    {:halt,
     update_trail(socket, fn t ->
       %{t | recent: Enum.filter(t.recent, &(&1.path == t.current))}
     end)}
  end

  defp handle_event("lu:trail:restore", params, socket) do
    if socket.assigns.page_trail.seeded do
      {:halt, socket}
    else
      saved = sanitize(socket, params["trail"])
      {:halt, update_trail(socket, &merge(&1, saved))}
    end
  end

  defp handle_event("lu:trail:state", params, socket) do
    t = socket.assigns.page_trail

    with %{} = state <- params["state"],
         true <- is_binary(t.current) and params["path"] == t.current,
         true <- is_map(t.state),
         true <- state_ok?(state),
         view = socket.view,
         true <- Code.ensure_loaded?(view) and function_exported?(view, :page_trail_restore, 2) do
      {:halt, view.page_trail_restore(state, socket)}
    else
      _ -> {:halt, socket}
    end
  end

  defp handle_event(_event, _params, socket), do: {:cont, socket}

  defp clamp(value, default) do
    n =
      case value do
        n when is_integer(n) -> n
        s when is_binary(s) -> parse_int(s, default)
        _ -> default
      end

    n |> min(@max_pinned) |> max(1)
  end

  defp parse_int(s, default) do
    case Integer.parse(s) do
      {n, ""} -> n
      _ -> default
    end
  end

  # The saved trail joins the current one: what the server already knows (the current screen,
  # its fresh `href`) wins; saved items fill the rest.
  defp merge(t, %{pinned: saved_pinned, recent: saved_recent}) do
    fresh = fn item, list -> Enum.find(list, &(&1.path == item.path)) || item end

    pinned =
      (Enum.map(saved_pinned, &fresh.(&1, t.pinned)) ++ t.pinned)
      |> uniq()
      |> Enum.take(@max_pinned)

    pinned_paths = MapSet.new(pinned, & &1.path)

    recent =
      (t.recent ++ saved_recent)
      |> Enum.reject(&MapSet.member?(pinned_paths, &1.path))
      |> uniq()
      |> Enum.take(@max_recent)

    %{t | pinned: pinned, recent: recent}
  end

  defp uniq(items), do: Enum.uniq_by(items, & &1.path)

  defp update_trail(socket, fun) do
    Phoenix.Component.assign(socket, :page_trail, fun.(socket.assigns.page_trail))
  end

  # ---------------------------------------------------------------------------------------
  # API for LiveViews

  @doc """
  Sets the label and the icon of the current screen (call it from `mount/3` or `handle_params/3`).

  Options: `:label` (default: `@page_title`, then the last segment of the path) and `:icon` (a
  name of `<.icon>`, default `"file"`). Needs `{LedgerUI.PageTrail, :default}` in `on_mount`.
  """
  @spec put_page(Socket.t(), keyword()) :: Socket.t()
  def put_page(%Socket{} = socket, opts \\ []) do
    meta = %{label: opts[:label], icon: opts[:icon]}
    socket |> ensure_trail() |> update_trail(&%{&1 | meta: meta}) |> register()
  end

  @doc """
  Puts a snapshot of the state of this screen (a JSON-encodable map, at most 32 KB) on the trail.
  The browser keeps it per base path and gives it back through `c:page_trail_restore/2` the next
  time the screen mounts. A map that does not encode, or is too big, is ignored.
  """
  @spec put_state(Socket.t(), map()) :: Socket.t()
  def put_state(%Socket{} = socket, state) when is_map(state) do
    if state_ok?(state) do
      socket |> ensure_trail() |> update_trail(&%{&1 | state: state})
    else
      socket
    end
  end

  @doc """
  Seeds the trail from saved preferences (the map `on_change` sent, with string or atom keys).
  Sanitized like a restore. The trail is then the source of truth: the browser's copy is ignored.
  """
  @spec put_trail(Socket.t(), map() | nil) :: Socket.t()
  def put_trail(%Socket{} = socket, raw) do
    socket = ensure_trail(socket)
    saved = sanitize(socket, raw)

    socket
    |> update_trail(fn t ->
      %{merge(%{t | pinned: [], recent: []}, saved) | seeded: true}
    end)
    |> register()
  end

  @doc """
  Validates a trail that comes from outside (the browser, preferences): returns
  `%{pinned: [item], recent: [item]}` with only the items that pass the rules of the moduledoc.

  The first argument is the socket (or a router module).
  """
  @spec sanitize(Socket.t() | module() | nil, term()) :: %{pinned: [item()], recent: [item()]}
  def sanitize(%Socket{router: router, host_uri: host_uri}, raw),
    do: sanitize(router, host(host_uri), raw)

  def sanitize(router, raw), do: sanitize(router, "", raw)

  defp sanitize(router, host, raw) do
    %{
      pinned: raw |> field("pinned") |> items(router, host) |> Enum.take(@max_pinned),
      recent: raw |> field("recent") |> items(router, host) |> Enum.take(@max_recent)
    }
    |> dedupe()
  end

  # a path is either pinned or recent
  defp dedupe(%{pinned: pinned, recent: recent}) do
    pinned = uniq(pinned)
    paths = MapSet.new(pinned, & &1.path)
    %{pinned: pinned, recent: recent |> Enum.reject(&MapSet.member?(paths, &1.path)) |> uniq()}
  end

  defp host(%URI{host: host}) when is_binary(host), do: host
  defp host(_), do: ""

  defp items(list, router, host) when is_list(list) do
    list
    |> Enum.take(@raw_limit)
    |> Enum.flat_map(fn raw ->
      case item(raw, router, host) do
        nil -> []
        item -> [item]
      end
    end)
  end

  defp items(_, _router, _host), do: []

  defp item(%{} = raw, router, host) do
    href = field(raw, "href") || field(raw, "path")
    path = field(raw, "path") || (is_binary(href) && path_of(href))

    with true <- is_binary(href) and is_binary(path),
         true <- shape_ok?(href),
         true <- path == path_of(href),
         true <- route?(router, path, host) do
      %{
        path: path,
        href: href,
        label: clean_label(field(raw, "label")) || humanize(path),
        icon: icon_for(field(raw, "icon"))
      }
    else
      _ -> nil
    end
  end

  defp item(_, _router, _host), do: nil

  defp field(%{} = map, key), do: Map.get(map, key) || Map.get(map, String.to_existing_atom(key))
  defp field(_, _), do: nil

  defp path_of(href), do: href |> String.split("?", parts: 2) |> hd()

  # A relative path that starts with one "/", with a query at most; nothing else.
  defp shape_ok?(href) when is_binary(href) do
    byte_size(href) <= @max_href and String.valid?(href) and
      String.starts_with?(href, "/") and not String.starts_with?(href, "//") and
      not String.contains?(href, ["\\", "#"]) and
      not Regex.match?(~r/[\x00-\x1f\x7f]/, href) and
      byte_size(path_of(href)) <= @max_path and
      match?(%URI{scheme: nil, host: nil, userinfo: nil}, URI.parse(href))
  end

  defp route?(nil, _path, _host), do: false

  defp route?(router, path, host) do
    Phoenix.Router.route_info(router, "GET", path, host) != :error
  rescue
    _ -> false
  end

  defp clean_label(label) when is_binary(label) do
    if String.valid?(label) do
      label
      |> String.replace(~r/[\x00-\x1f\x7f]/u, " ")
      |> String.trim()
      |> String.slice(0, @max_label)
      |> String.trim()
      |> case do
        "" -> nil
        text -> text
      end
    end
  end

  defp clean_label(_), do: nil

  defp state_ok?(state) when is_map(state) do
    case Phoenix.json_library().encode(state) do
      {:ok, json} -> byte_size(json) <= @max_state
      _ -> false
    end
  end

  defp ensure_trail(%{assigns: %{page_trail: %{}}} = socket), do: socket
  defp ensure_trail(socket), do: Phoenix.Component.assign(socket, :page_trail, empty())

  @doc false
  # The JSON the browser keeps: only what is needed to rebuild the trail.
  def to_json(%{} = trail, recent_limit \\ @max_recent) do
    %{
      pinned: trail |> Map.get(:pinned, []) |> Enum.map(&slim/1),
      recent: trail |> Map.get(:recent, []) |> Enum.take(recent_limit) |> Enum.map(&slim/1)
    }
  end

  defp slim(item), do: Map.take(item, [:path, :href, :label, :icon])
end
