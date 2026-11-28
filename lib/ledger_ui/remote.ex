defmodule LedgerUI.Remote do
  @moduledoc """
  Optional helper for `select`, `autocomplete` and `pillbox` whose options come from a search on
  the server (#106). Without it the caller keeps, per field, the options, the typed text, the
  "no more pages" flag and the labels of what is chosen, plus two `handle_event` clauses.
  With it the field is declared once in `mount/3`:

      def mount(_params, _session, socket) do
        socket =
          socket
          |> LedgerUI.Remote.attach(:customers,
            search: fn query, page -> Customers.options(query, page) end,
            per_page: 15
          )
          |> LedgerUI.Remote.attach(:staff, search: &Staff.options/2)

        {:ok, socket}
      end

  and used with the opt-in attr `remote`:

      <.pillbox name="customer_ids" value={@customer_ids} remote={@remote.customers} />
      <.select name="staff_id" value={@staff_id} remote={@remote.staff} />

  `search` receives the typed text (`""` when nothing is typed) and the page (from 1) and returns
  `{options, has_more?}`; `options` are in any shape of `LedgerUI.Components.Select.Options`.

  `remote` fills `options`, `selected_options` (the labels of the chosen values), `on_search`,
  `on_load_more`, `has_more` and `debounce` of the component. It is read by `select`,
  `autocomplete` (`options`, `on_search`, `debounce` and `display_value`) and `pillbox`. Without
  `remote` the components render and behave as before.

  ## What it does

    * `attach/3` stores the state in `socket.assigns.remote[name]` and attaches, with
      `Phoenix.LiveView.attach_hook/4`, a `:handle_event` hook for the two events the field pushes
      (`"lu_remote:search:<name>"` and `"lu_remote:more:<name>"`) and a `:handle_async` hook for
      the answers. The search runs in `start_async/3`, so the LiveView process is not held by it,
      and an answer that is no longer the latest one is dropped.
    * Every option the search returns is remembered by value: a chosen value keeps its label
      after a new search no longer returns it. A value that was never searched (an edit form)
      is given with `put_selected/3`.
    * The events are handled by the LiveView that attached them: the helper does not work inside
      a LiveComponent (`attach_hook/4` is not available there) and the field must not have a
      `target`.

  ## Options of `attach/3`

    * `:search` (required): `fn query, page -> {options, has_more?} end`.
    * `:per_page`: size of a page, default `15` (the helper counts pages; `search` applies the
      size, so pass the same number to your query).
    * `:preload`: `true` loads page 1 of `""` as soon as the socket is connected (never on the
      disconnected render). Default `false`: the first search runs when the field is opened and
      typed in.
    * `:debounce`: milliseconds, default `300`.
    * `:async`: `true` (default) runs `search` in `start_async/3`; `false` runs it in the
      LiveView process, so the reply of the event and the new options reach the browser together.

  ## Complete example

      defmodule MyAppWeb.OrderFormLive do
        use MyAppWeb, :live_view

        def mount(_params, _session, socket) do
          order = Orders.get_order!(socket.assigns.current_scope, 1)

          socket =
            socket
            |> LedgerUI.Remote.attach(:customers,
              search: fn query, page -> Customers.search(query, page, 15) end,
              preload: true
            )
            |> LedgerUI.Remote.attach(:staff,
              search: fn query, page -> Staff.search(query, page, 15) end
            )
            |> LedgerUI.Remote.attach(:items,
              search: fn query, page -> Items.search(query, page, 15) end
            )
            # an edit form: the labels of what is already chosen
            |> LedgerUI.Remote.put_selected(:customers, Customers.options_for(order.customer_ids))
            |> assign(order: order)

          {:ok, socket}
        end

        def render(assigns) do
          ~H\"\"\"
          <.pillbox
            name="customer_ids"
            label="Customers"
            value={@order.customer_ids}
            remote={@remote.customers}
          />
          <.select name="staff_id" label="Staff" value={@order.staff_id} remote={@remote.staff} />
          <.autocomplete name="item" label="Item" value={@order.item} remote={@remote.items} />
          \"\"\"
        end
      end

  No `handle_event` for the search or the pages is written by the caller.
  """

  require Phoenix.LiveView
  alias LedgerUI.Components.Select.Options

  @doc """
  Declares the remote field `name` (an atom). See the module doc for the options.

  The state is `socket.assigns.remote[name]`, a map to hand to the `remote` attr of the component.
  """
  def attach(socket, name, opts) when is_atom(name) do
    search = Keyword.fetch!(opts, :search)

    unless is_function(search, 2) do
      raise ArgumentError,
            "LedgerUI.Remote.attach/3: `search` must be a function of arity 2 " <>
              "(fn query, page -> {options, has_more?} end)"
    end

    config = %{
      name: name,
      search: search,
      per_page: Keyword.get(opts, :per_page, 15),
      async: Keyword.get(opts, :async, true)
    }

    state = %{
      options: [],
      selected_options: [],
      seen: %{},
      query: "",
      page: 0,
      has_more: false,
      seq: 0,
      on_search: "lu_remote:search:#{name}",
      on_load_more: "lu_remote:more:#{name}",
      debounce: Keyword.get(opts, :debounce, 300)
    }

    socket =
      socket
      |> Phoenix.Component.assign(:remote, Map.put(remote_map(socket), name, state))
      |> Phoenix.LiveView.attach_hook(
        :"lu_remote_event_#{name}",
        :handle_event,
        &handle_event(config, &1, &2, &3)
      )
      |> Phoenix.LiveView.attach_hook(
        :"lu_remote_async_#{name}",
        :handle_async,
        &handle_async(config, &1, &2, &3)
      )

    if Keyword.get(opts, :preload, false) and Phoenix.LiveView.connected?(socket),
      do: run(socket, config, "", 1),
      else: socket
  end

  @doc """
  Remembers options (any shape of `LedgerUI.Components.Select.Options`) so a value chosen before the
  first search (an edit form) shows its label. They are not added to the list of options.
  """
  def put_selected(socket, name, options) when is_atom(name) and is_list(options) do
    update_state(socket, name, fn state -> %{state | seen: remember(state.seen, options)} end)
  end

  @doc false
  # Used by `select`, `autocomplete` and `pillbox` when they get `remote`: lays the state over the
  # attrs of the component. The labels of the chosen values are the ones remembered by `attach/3`.
  def apply(%{remote: %{} = remote} = assigns) do
    values = chosen_values(assigns)
    selected = for v <- values, o = remote.seen[v], do: o

    assigns
    |> Phoenix.Component.assign(:options, remote.options)
    |> Phoenix.Component.assign(:selected_options, selected)
    |> Phoenix.Component.assign(:on_search, remote.on_search)
    |> Phoenix.Component.assign(:on_load_more, remote.on_load_more)
    |> Phoenix.Component.assign(:has_more, remote.has_more)
    |> Phoenix.Component.assign(:debounce, remote.debounce)
  end

  def apply(assigns), do: assigns

  @doc false
  # An autocomplete shows the label of its value: the one remembered when the options no longer have it.
  def display_value(%{remote: %{seen: seen}} = assigns) do
    case chosen_values(assigns) do
      [value | _] -> if o = seen[value], do: label_of(o)
      _ -> nil
    end
  end

  def display_value(_), do: nil

  defp chosen_values(assigns) do
    value =
      case assigns do
        %{value: nil, field: %Phoenix.HTML.FormField{value: v}} -> v
        %{value: v} -> v
        _ -> nil
      end

    Options.values(value)
  end

  # ---- events ---------------------------------------------------------------

  defp handle_event(%{name: name} = config, event, params, socket) do
    search_event = "lu_remote:search:#{name}"
    more_event = "lu_remote:more:#{name}"

    case event do
      ^search_event ->
        {:halt, run(socket, config, query_of(params), 1)}

      ^more_event ->
        state = socket.assigns.remote[name]
        query = query_of(params)

        if state.has_more and query == state.query,
          do: {:halt, run(socket, config, query, state.page + 1)},
          else: {:halt, socket}

      _ ->
        {:cont, socket}
    end
  end

  defp query_of(%{"query" => q}) when is_binary(q), do: q
  defp query_of(_), do: ""

  # Starts the search; `seq` tells which answer is the latest.
  defp run(socket, %{name: name, search: search, async: async} = config, query, page) do
    socket = update_state(socket, name, fn s -> %{s | seq: s.seq + 1} end)
    seq = socket.assigns.remote[name].seq

    if async do
      Phoenix.LiveView.start_async(socket, {:lu_remote, name}, fn ->
        {seq, query, page, call!(search, config, query, page)}
      end)
    else
      answer(socket, name, {seq, query, page, call!(search, config, query, page)})
    end
  end

  defp call!(search, config, query, page) do
    case search.(query, page) do
      {options, more} when is_list(options) and is_boolean(more) ->
        {options, more}

      other ->
        raise ArgumentError,
              "LedgerUI.Remote #{inspect(config.name)}: `search` must return " <>
                "{options, has_more?} (a list and a boolean), got: #{inspect(other)}"
    end
  end

  defp handle_async(%{name: name}, {:lu_remote, name}, {:ok, answer}, socket),
    do: {:halt, answer(socket, name, answer)}

  defp handle_async(%{name: name}, {:lu_remote, name}, {:exit, reason}, socket) do
    require Logger
    Logger.error("LedgerUI.Remote #{inspect(name)}: the search failed: #{inspect(reason)}")
    {:halt, socket}
  end

  defp handle_async(_config, _name, _result, socket), do: {:cont, socket}

  defp answer(socket, name, {seq, query, page, {options, more}}) do
    update_state(socket, name, fn
      %{seq: ^seq} = state ->
        options = if page == 1, do: options, else: merge(state.options, options)

        %{
          state
          | options: options,
            seen: remember(state.seen, options),
            query: query,
            page: page,
            has_more: more
        }

      state ->
        state
    end)
  end

  defp merge(old, new) do
    have = MapSet.new(old, &value_of/1)
    old ++ Enum.reject(new, &(value_of(&1) in have))
  end

  defp remember(seen, options) do
    Enum.reduce(options, seen, fn
      {group, list}, acc when is_list(list) and is_binary(group) -> remember(acc, list)
      o, acc -> Map.put(acc, value_of(o), o)
    end)
  end

  defp value_of(o), do: o |> then(&Options.normalize([&1])) |> hd() |> Map.get(:value)
  defp label_of(o), do: o |> then(&Options.normalize([&1])) |> hd() |> Map.get(:label)

  defp remote_map(socket), do: Map.get(socket.assigns, :remote, %{})

  defp update_state(socket, name, fun) do
    remote = remote_map(socket)

    case remote do
      %{^name => state} ->
        Phoenix.Component.assign(socket, :remote, %{remote | name => fun.(state)})

      _ ->
        raise ArgumentError, "LedgerUI.Remote: #{inspect(name)} was not attached (attach/3)"
    end
  end
end
