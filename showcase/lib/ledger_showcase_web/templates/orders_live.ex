defmodule LedgerShowcaseWeb.Templates.OrdersLive do
  @moduledoc """
  The orders table template (`/templates/tabela`, `tabela-app`, `tabela-gaveta`, `tabela-modal`): tabs, search,
  a table with row selection that drives the floating bulk bar, the order detail in a drawer
  (`?pedido=2491`) and the "Novo pedido" form in a modal (`?novo=1`).

  The four slugs are the same LiveView: the plain `tabela` starts with three rows selected (as
  the canvas board), `tabela-app` ("Pedidos · interativa" of the vitrine) with none (a row opens
  the detail, the checkboxes raise the bulk bar, "Novo pedido" opens the modal, "Emitir NF-e"
  shows the progress toast), `tabela-gaveta` with the drawer of order 2495 open and `tabela-modal` with
  the modal open, both without a selection (so does a `?pedido=` / `?novo=` link).
  Opening and closing the overlays are patches, so the URL is shareable and Esc/back work.
  """
  use Phoenix.LiveView
  use LedgerUI

  alias LedgerShowcase.Templates, as: T
  alias Phoenix.LiveView.JS
  alias LedgerShowcaseWeb.Templates.Shell

  @initial_selection [2495, 2493, 2492]
  @channels ~w(Loja WhatsApp Site iFood)
  @payments ~w(Pix Boleto Cartão Dinheiro)
  @sortable ~w(id name total)

  @impl true
  def mount(params, _session, socket) do
    # Only the plain `/templates/tabela` starts with rows selected (the TTabela board): the
    # gaveta and modal boards, and a shared `?pedido=` / `?novo=` link, start with none.
    selected =
      if socket.assigns.live_action == :tabela and
           not (Map.has_key?(params, "pedido") or Map.has_key?(params, "novo")),
         do: @initial_selection,
         else: []

    {:ok,
     socket
     |> assign(
       page_title: "Pedidos · Templates",
       slug: slug(socket.assigns.live_action),
       tab: "todos",
       q: "",
       sort_by: nil,
       sort_dir: "asc",
       selected: MapSet.new(selected),
       order: nil,
       new_open: false,
       form: new_form(),
       items: initial_items(),
       notice: nil
     )}
  end

  defp slug(:tabela), do: "tabela"
  defp slug(:gaveta), do: "tabela-gaveta"
  defp slug(:modal), do: "tabela-modal"
  defp slug(:app), do: "tabela-app"

  @impl true
  def handle_params(params, _uri, socket) do
    action = socket.assigns.live_action

    # `?theme=` and other params do not count: only `pedido` and `novo` choose the overlay
    plain? = not (Map.has_key?(params, "pedido") or Map.has_key?(params, "novo"))

    order =
      cond do
        params["pedido"] -> T.order(params["pedido"])
        action == :gaveta and plain? -> T.order(2495)
        true -> nil
      end

    new_open = params["novo"] == "1" or (action == :modal and plain?)

    {:noreply,
     assign(socket,
       order: order,
       new_open: new_open && order == nil,
       slug: slug(action)
     )}
  end

  ## Events

  @impl true
  def handle_event("tab", %{"name" => tab}, socket) do
    {:noreply, assign(socket, tab: tab, selected: MapSet.new())}
  end

  def handle_event("search", %{"value" => q}, socket) do
    {:noreply, assign(socket, q: q)}
  end

  def handle_event("sort", %{"column" => column, "direction" => dir}, socket)
      when column in @sortable and dir in ~w(asc desc) do
    {:noreply, assign(socket, sort_by: column, sort_dir: dir)}
  end

  # The row checkbox of the table: the new state of that row.
  def handle_event("toggle", %{"id" => id, "selected" => on}, socket) do
    id = if is_binary(id), do: String.to_integer(id), else: id

    selected =
      if on == "true",
        do: MapSet.put(socket.assigns.selected, id),
        else: MapSet.delete(socket.assigns.selected, id)

    {:noreply, assign(socket, selected: selected)}
  end

  # The select-all checkbox: all the visible rows, or none of them.
  def handle_event("toggle_all", %{"selected" => on}, socket) do
    ids = visible(socket.assigns) |> Enum.map(& &1.id) |> MapSet.new()

    selected =
      if on == "true",
        do: MapSet.union(socket.assigns.selected, ids),
        else: MapSet.difference(socket.assigns.selected, ids)

    {:noreply, assign(socket, selected: selected)}
  end

  def handle_event("clear", _params, socket) do
    {:noreply, assign(socket, selected: MapSet.new())}
  end

  def handle_event("bulk", %{"id" => action}, socket) do
    n = MapSet.size(socket.assigns.selected)

    notice =
      case action do
        "nfe" -> "#{n} NF-e na fila de emissão."
        "ship" -> "#{n} pedidos enviados para a entrega."
        "export" -> "#{n} pedidos exportados."
        "cancel" -> "#{n} pedidos cancelados."
      end

    {:noreply, assign(socket, notice: notice, selected: MapSet.new())}
  end

  def handle_event("open_order", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: base(socket) <> "?pedido=#{id}")}
  end

  def handle_event("new_order", _params, socket) do
    {:noreply, push_patch(socket, to: base(socket) <> "?novo=1")}
  end

  def handle_event("close_overlay", _params, socket) do
    {:noreply, push_patch(socket, to: base(socket))}
  end

  # "Emitir NF-e" in the drawer (`data-tp-nfe` of the vitrine page): the drawer closes, the notice
  # says it is transmitting and, a moment later, that the invoice was authorized.
  def handle_event("issue_nfe", _params, socket) do
    id = socket.assigns.order && socket.assigns.order.id
    if connected?(socket), do: Process.send_after(self(), {:nfe_done, id}, 1600)

    {:noreply,
     socket
     |> assign(notice: "Emitindo NF-e… Transmitindo à SEFAZ-BA.")
     |> push_patch(to: base(socket))}
  end

  def handle_event("dismiss", _params, socket), do: {:noreply, assign(socket, notice: nil)}

  def handle_event("validate_order", %{"order" => params}, socket) do
    {:noreply,
     assign(socket,
       form: merge_form(socket.assigns.form, params),
       items: apply_qty(socket.assigns.items, params["qty"])
     )}
  end

  def handle_event("pay", %{"value" => p}, socket) when p in @payments do
    {:noreply, assign(socket, form: Map.put(socket.assigns.form, "payment", p))}
  end

  def handle_event("remove_item", %{"index" => i}, socket) do
    {:noreply, assign(socket, items: List.delete_at(socket.assigns.items, String.to_integer(i)))}
  end

  def handle_event("add_item", _params, socket) do
    used = Enum.map(socket.assigns.items, & &1.name)

    case Enum.find(T.catalog(), fn {name, _} -> name not in used end) do
      nil ->
        {:noreply, socket}

      {name, price} ->
        {:noreply,
         assign(socket, items: socket.assigns.items ++ [%{name: name, price: price, qty: 1}])}
    end
  end

  def handle_event("create_order", _params, socket) do
    if socket.assigns.items == [] do
      {:noreply, assign(socket, notice: "Adicione ao menos um item ao pedido.")}
    else
      {:noreply,
       socket
       |> assign(
         notice: "Pedido criado: #{T.money(total(socket.assigns.items))}.",
         items: initial_items()
       )
       |> push_patch(to: base(socket))}
    end
  end

  @impl true
  def handle_info({:nfe_done, id}, socket) do
    notice = "NF-e 48.212 autorizada · Pedido ##{id}."
    {:noreply, assign(socket, notice: notice)}
  end

  # The page the overlays patch back to: the one the visitor is on (`tabela-app` stays there).
  defp base(%{assigns: %{live_action: :app}}), do: "/templates/tabela-app"
  defp base(_socket), do: "/templates/tabela"

  ## Data

  defp visible(%{tab: tab, q: q} = assigns) do
    q = q |> String.trim() |> String.downcase()

    T.orders()
    |> Enum.filter(fn o ->
      T.in_tab?(o, tab) and
        (q == "" or String.contains?(String.downcase(o.name), q) or
           String.contains?(Integer.to_string(o.id), q))
    end)
    |> sort(assigns[:sort_by], assigns[:sort_dir])
  end

  defp sort(orders, nil, _dir), do: orders

  defp sort(orders, column, dir) do
    key = String.to_existing_atom(column)
    Enum.sort_by(orders, &Map.fetch!(&1, key), if(dir == "desc", do: :desc, else: :asc))
  end

  defp initial_items do
    [
      %{name: "Café torrado 500 g", price: 2390, qty: 12},
      %{name: "Açúcar cristal 1 kg", price: 499, qty: 24},
      %{name: "Óleo de soja 900 ml", price: 790, qty: 6}
    ]
  end

  defp new_form do
    %{
      "customer" => "Mercadinho Bom Preço · 12.345.678/0001-90",
      "delivery" => "Hoje, 16h–18h",
      "channel" => "WhatsApp",
      "payment" => "Pix",
      "note" => "Entregar pelo portão lateral, falar com Rita.",
      "notify" => "true"
    }
  end

  defp merge_form(form, params) do
    form
    |> Map.merge(Map.take(params, ~w(customer delivery channel payment note)))
    |> Map.put("notify", if(params["notify"] == "true", do: "true", else: "false"))
  end

  # The steppers (`order[qty][i]`) report the whole quantity of each line.
  defp apply_qty(items, %{} = qty) do
    items
    |> Enum.with_index()
    |> Enum.map(fn {it, i} ->
      case Integer.parse(Map.get(qty, Integer.to_string(i), "")) do
        {n, _} -> %{it | qty: max(n, 1)}
        :error -> it
      end
    end)
  end

  defp apply_qty(items, _), do: items

  defp total_for("todos", _), do: 1096

  defp total_for(tab, orders),
    do: Enum.find_value(T.tabs(), length(orders), fn {k, _, c} -> k == tab && c end)

  defp total(items), do: items |> Enum.map(&(&1.price * &1.qty)) |> Enum.sum()

  ## Render

  attr :order, :map, required: true

  defp order_drawer(assigns) do
    assigns = assign(assigns, :d, T.detail(assigns.order))

    ~H"""
    <.drawer
      id="order-drawer"
      layout="page"
      open
      on_close="close_overlay"
      close_label="Fechar"
      title={"Pedido ##{@order.id}"}
    >
      <:header>
        <div>
          <div class="flex items-center gap-2.5">
            <h3 id="order-drawer-title">Pedido #{@order.id}</h3>
            <.status_badge status={@order.status} />
          </div>
          <p>Criado {@d.created} por {@d.seller}</p>
        </div>
      </:header>
      <.stepper color="primary" current={elem(@d.steps, 0)} error={elem(@d.steps, 1)}>
        <:step
          :for={{label, i} <- Enum.with_index(T.stages(), 1)}
          label={label}
          marker={Integer.to_string(i)}
        />
      </.stepper>
      <p class={sec_h()}>Dados</p>
      <.description_list cols={2} class="my-3.5">
        <:item label="Cliente">{@order.name}</:item>
        <:item label={@d.doc_label}>{@d.doc}</:item>
        <:item label="Canal">{@order.channel}</:item>
        <:item label="Vendedor">{@d.seller}</:item>
        <:item label="Pagamento">{@d.payment}</:item>
        <:item label="Entrega">{@d.delivery}</:item>
      </.description_list>
      <p class={sec_h()}>Itens</p>
      <div class={lines()}>
        <div :for={l <- @d.lines} class={line()}>
          <span class={line_q()}>{l.qty}×</span>
          <span class={line_n()}>{l.name}</span>
          <span class={line_v()}>{T.money(l.cents)}</span>
        </div>
        <div :if={@d.rest_items > 0} class={[line(), "text-muted"]}>
          <span class={line_q()}></span>
          <span class={line_n()}>
            + {@d.rest_items} {if @d.rest_items == 1, do: "item", else: "itens"}
          </span>
          <span class={[line_v(), "text-muted"]}>{T.money(@d.rest_cents)}</span>
        </div>
      </div>
      <.totals items={@order.items} discount={@d.discount} total={@order.total} />
      <p class={sec_h()}>Histórico</p>
      <.timeline marker="icon">
        <.timeline_item
          :for={h <- @d.history}
          variant="icon"
          color={h.tone}
          title={h.title}
          description={h.sub}
          time={h.at}
        >
          <:point><.icon name={h.icon} size="sm" /></:point>
        </.timeline_item>
      </.timeline>
      <:footer>
        <.button variant="ghost"><.icon name="file" />Imprimir</.button>
        <span class="min-w-0 flex-1"></span>
        <.button variant="outline"><.icon name="edit" />Editar</.button>
        <.button color="mono" phx-click="issue_nfe" data-tp-nfe>
          <.icon name="invoice" />Emitir NF-e
        </.button>
      </:footer>
    </.drawer>
    """
  end

  attr :items, :integer, required: true
  attr :discount, :integer, required: true
  attr :total, :integer, required: true

  defp totals(assigns) do
    ~H"""
    <.stat_group variant="sunken">
      <.stat_item size="sm" label="Itens" value={Integer.to_string(@items)} />
      <.stat_item size="sm" label="Desconto" value={T.money(-@discount)} />
      <.stat_item size="sm" tone="accent" label="Total" value={T.money(@total)} />
    </.stat_group>
    """
  end

  attr :form, :map, required: true
  attr :items, :list, required: true
  attr :subtotal, :integer, required: true
  attr :channels, :list, required: true
  attr :payments, :list, required: true

  defp order_modal(assigns) do
    ~H"""
    <.modal
      id="order-modal"
      layout="page"
      open
      on_close="close_overlay"
      close_label="Fechar"
      title="Novo pedido"
      description="Os itens saem do estoque quando o pedido for pago."
      phx-change="validate_order"
      phx-submit="create_order"
    >
      <.select
        name="order[customer]"
        label="Cliente"
        icon="users"
        value={@form["customer"]}
        options={[@form["customer"], "Padaria Central · 98.765.432/0001-10"]}
        class="w-full"
      />
      <div class="grid grid-cols-2 gap-3">
        <.input name="order[delivery]" label="Entrega" value={@form["delivery"]} />
        <.input
          name="order[channel]"
          label="Canal"
          value={@form["channel"]}
        />
      </div>
      <div class="flex flex-wrap items-center justify-between gap-2.5">
        <span class="flex items-center gap-1.5 text-[13px] font-medium text-ink">Itens</span>
        <.button variant="ghost" size="sm" phx-click="add_item">
          <.icon name="plus" />Adicionar item
        </.button>
      </div>
      <div class={lines()}>
        <div :for={{it, i} <- Enum.with_index(@items)} class={line()}>
          <span class={line_n()}>{it.name}<br /><small class="text-[length:smaller] text-muted">{T.money(
            it.price
          )} / un</small></span>
          <.number_input
            id={"order-qty-#{i}"}
            name={"order[qty][#{i}]"}
            value={it.qty}
            canvas
            steppers
            size="sm"
            min={1}
            wrapper_class="w-[116px]"
          />
          <span class={[line_v(), "w-[92px] text-right"]}>{T.money(it.price * it.qty)}</span>
          <.icon_button
            icon="trash"
            label="Remover"
            variant="ghost"
            size="sm"
            phx-click="remove_item"
            phx-value-index={i}
          />
        </div>
      </div>
      <.segmented
        id="order-payment"
        label="Pagamento"
        stretch
        value={@form["payment"]}
        on_change="pay"
        options={@payments}
      />
      <.textarea name="order[note]" label="Observação" value={@form["note"]} />
      <.totals_new subtotal={@subtotal} />
      <:footer>
        <.checkbox
          name="order[notify]"
          color="primary"
          size={nil}
          class="mr-auto"
          checked={@form["notify"] == "true"}
          label="Avisar o cliente no WhatsApp"
        />
        <.button variant="outline" phx-click="close_overlay">Cancelar</.button>
        <.button color="mono" type="submit" data-tp-create>
          <.icon name="check" />Criar pedido
        </.button>
      </:footer>
    </.modal>
    """
  end

  attr :subtotal, :integer, required: true

  defp totals_new(assigns) do
    ~H"""
    <.stat_group variant="sunken">
      <.stat_item size="sm" label="Subtotal" value={T.money(@subtotal)} />
      <.stat_item size="sm" label="Desconto" value={T.money(0)} />
      <.stat_item size="sm" tone="accent" label="Total" value={T.money(@subtotal)} />
    </.stat_group>
    """
  end

  # The section title, the list of lines and one line of the drawer and the modal (layout of the page).
  defp sec_h, do: [Shell.sec_h(), "-mb-1.5"]

  # The board shows `1 2 3 … 92`: the pager's window has one more page (4), left out.
  defp pager_page(4), do: %{class: "hidden"}
  defp pager_page(_), do: %{}

  defp lines, do: "flex flex-col overflow-hidden rounded-[12px] border border-line"

  defp line,
    do:
      "flex items-center gap-2.5 border-t border-line px-3 py-2.5 text-[13.5px] first:border-t-0"

  defp line_q, do: "min-w-[34px] font-mono text-muted"
  defp line_n, do: "min-w-0 flex-1 text-ink"
  defp line_v, do: "font-medium tabular-nums text-ink"

  attr :status, :string, required: true

  defp status_badge(assigns) do
    {color, dot?} = T.status_badge(assigns.status)
    assigns = assign(assigns, color: color, dot?: dot?)

    ~H"""
    <.badge :if={@dot?} canvas color={@color} dot>{@status}</.badge>
    <.badge :if={!@dot?} canvas variant="outline">{@status}</.badge>
    """
  end

  @impl true
  def render(assigns) do
    orders = visible(assigns)
    all_ids = Enum.map(orders, & &1.id)
    n_sel = MapSet.size(assigns.selected)

    assigns =
      assign(assigns,
        orders: orders,
        n_sel: n_sel,
        all?: all_ids != [] and Enum.all?(all_ids, &MapSet.member?(assigns.selected, &1)),
        some?: n_sel > 0,
        tabs: T.tabs(),
        channels: @channels,
        payments: @payments,
        subtotal: total(assigns.items),
        # the sort arrows show on the sorted column only (the board draws none)
        idle_sort: "[&:not([aria-sort=ascending]):not([aria-sort=descending])_svg]:hidden"
      )

    ~H"""
    <Shell.frame slug={@slug} palette={@palette} notice={@notice}>
      <Shell.app rail="pedidos" panel="Pedidos" crumbs={["Vendas", "Pedidos"]}>
        <:panel_body>
          <.sidebar_nav_link active phx-click="tab" phx-value-name="todos">
            <.icon name="list" size="md" />Todos<Shell.nav_count>1.096</Shell.nav_count>
          </.sidebar_nav_link>
          <.sidebar_nav_link phx-click="tab" phx-value-name="abertos">
            <.icon name="clock" size="md" />Abertos<Shell.nav_count>48</Shell.nav_count>
          </.sidebar_nav_link>
          <.sidebar_nav_link phx-click="tab" phx-value-name="pagos">
            <.icon name="check-circle" size="md" />Pagos<Shell.nav_count>1.012</Shell.nav_count>
          </.sidebar_nav_link>
          <.sidebar_nav_link phx-click="tab" phx-value-name="atrasados">
            <.icon name="alert" size="md" />Atrasados<Shell.nav_count>36</Shell.nav_count>
          </.sidebar_nav_link>
          <Shell.nav_heading>Canal</Shell.nav_heading>
          <.sidebar_nav_link href="#">
            <.icon name="home" size="md" />Loja física<Shell.nav_count>512</Shell.nav_count>
          </.sidebar_nav_link>
          <.sidebar_nav_link href="#">
            <.icon name="message" size="md" />WhatsApp<Shell.nav_count>331</Shell.nav_count>
          </.sidebar_nav_link>
          <.sidebar_nav_link href="#">
            <.icon name="globe" size="md" />Site<Shell.nav_count>143</Shell.nav_count>
          </.sidebar_nav_link>
          <.sidebar_nav_link href="#">
            <.icon name="cart" size="md" />iFood<Shell.nav_count>110</Shell.nav_count>
          </.sidebar_nav_link>
          <Shell.nav_heading>Visões salvas</Shell.nav_heading>
          <.sidebar_nav_link href="#">
            <.icon name="star" size="md" />Grandes contas<Shell.nav_count>18</Shell.nav_count>
          </.sidebar_nav_link>
          <.sidebar_nav_link href="#">
            <.icon name="truck" size="md" />Entrega hoje<Shell.nav_count>27</Shell.nav_count>
          </.sidebar_nav_link>
        </:panel_body>

        <.page_header title="Pedidos">
          <:subtitle>
            <b class="font-mono text-ink">1.096</b> pedidos em novembro · R$ 184.320 faturados
          </:subtitle>
          <:actions>
            <.button variant="outline"><.icon name="download" />Exportar</.button>
            <.button color="mono" phx-click="new_order"><.icon name="plus" />Novo pedido</.button>
          </:actions>
        </.page_header>

        <.tabs id="orders-tabs" variant="line" selected={@tab} class="mx-7">
          <:tab :for={{key, label, count} <- @tabs} name={key} phx-click="tab" phx-value-name={key}>
            {label}
            <span class="ml-1 font-mono text-[12px] text-muted">{T.group(count)}</span>
          </:tab>
        </.tabs>

        <div class="flex flex-nowrap items-center gap-2 px-7 py-3.5">
          <.input
            size="sm"
            icon="search"
            value={@q}
            phx-keyup="search"
            phx-debounce="250"
            autocomplete="off"
            aria-label="Buscar pedido"
            placeholder="Buscar por cliente, pedido ou CPF/CNPJ"
            class="w-[280px] shrink-0 [&>svg]:size-4"
          />
          <.button canvas size="sm">
            <.icon name="filter" />Filtros
            <span class="ml-0.5 inline-grid h-[18px] min-w-[18px] place-items-center rounded-[5px] bg-neg px-[5px] text-[11px] font-semibold tabular-nums text-white">
              2
            </span>
          </.button>
          <.tag canvas as="span" class="inline-flex items-center gap-1.5">
            <span>Período: novembro</span><.icon name="x" size="sm" />
          </.tag>
          <.tag canvas as="span" class="inline-flex items-center gap-1.5">
            <span>Canal: todos exceto iFood</span><.icon name="x" size="sm" />
          </.tag>
          <span class="min-w-0 flex-1"></span>
          <.button canvas size="sm"><.icon name="columns" />Colunas</.button>
          <.button canvas size="sm"><.icon name="sort" />Mais recentes</.button>
        </div>

        <div class="px-7 pb-[92px]">
          <.card canvas>
            <.card_body class="overflow-hidden !p-0">
              <.table
                id="orders-table"
                rows={@orders}
                row_id={&"order-#{&1.id}"}
                row_key={& &1.id}
                row_click={&JS.push("open_order", value: %{id: &1.id})}
                variant="hoverable"
                wrapper={false}
                class="[&_:is(th,td):first-child]:w-[46px] [&_:is(th,td):first-child]:pr-3.5"
                selected={MapSet.to_list(@selected)}
                all_selected={@all?}
                on_select="toggle"
                on_select_all="toggle_all"
                select_all_label="Selecionar todos"
                select_label="Selecionar pedido"
                row_label={&"Selecionar pedido #{&1.id}"}
                sort_by={@sort_by}
                sort_dir={@sort_dir}
                on_sort="sort"
              >
                <:col
                  :let={o}
                  label="Pedido"
                  sort_key="id"
                  head_class={@idle_sort}
                  class="font-mono [--td-fs:13px] font-medium text-ink"
                >
                  #{o.id}
                </:col>
                <:col :let={o} label="Cliente" sort_key="name" head_class={@idle_sort}>
                  <div class="flex flex-nowrap items-center gap-2.5">
                    <.avatar initials={o.initials} color={o.tone} size="30" />
                    <span class="flex flex-col leading-[1.25]">
                      <span class="font-medium text-ink">{o.name}</span><small class="text-[length:smaller] text-muted">{o.city}</small>
                    </span>
                  </div>
                </:col>
                <:col :let={o} label="Data">{o.at}</:col>
                <:col :let={o} label="Canal">
                  <.badge canvas variant="outline" color={T.channel_color(o.channel)}>
                    {o.channel}
                  </.badge>
                </:col>
                <:col :let={o} label="Status"><.status_badge status={o.status} /></:col>
                <:col :let={o} label="Itens" align="right" class="font-mono [--td-fs:13px]">
                  {o.items}
                </:col>
                <:col
                  :let={o}
                  label="Total"
                  align="right"
                  sort_key="total"
                  head_class={@idle_sort}
                  class="font-mono [--td-fs:13px] font-medium text-ink"
                >
                  {T.money(o.total)}
                </:col>
                <:action :let={o}>
                  <.icon_button
                    icon="more-h"
                    label="Ações"
                    variant="ghost"
                    size="sm"
                    class="h-8! w-8!"
                    phx-click="open_order"
                    phx-value-id={o.id}
                  />
                </:action>
              </.table>
            </.card_body>
            <.card_footer class="justify-between border-t border-line px-4! py-3!">
              <span class="text-[13px] text-muted">
                Mostrando <b class="text-ink">1–{length(@orders)}</b>
                de <b class="text-ink">{T.group(total_for(@tab, @orders))}</b>
              </span>
              <.pagination
                page={1}
                total_pages={92}
                size="sm"
                class="[&>[data-part=pagination-arrow]:nth-last-child(2)]:order-first"
                page_attrs={&pager_page/1}
              />
            </.card_footer>
          </.card>
        </div>

        <.bulk_bar
          id="orders-bulk"
          variant="float"
          count={@n_sel}
          label="selecionado"
          label_plural="selecionados"
          on_clear="clear"
          clear_label="Limpar seleção"
          class="bottom-[18px]!"
        >
          <:action icon="invoice" phx-click="bulk" phx-value-id="nfe">Emitir NF-e</:action>
          <:action icon="truck" phx-click="bulk" phx-value-id="ship">Enviar para entrega</:action>
          <:action icon="download" phx-click="bulk" phx-value-id="export">Exportar</:action>
          <:action variant="danger" icon="trash" phx-click="bulk" phx-value-id="cancel">
            Cancelar
          </:action>
        </.bulk_bar>

        <:overlay>
          <.order_drawer :if={@order} order={@order} />
          <.order_modal
            :if={@new_open}
            form={@form}
            items={@items}
            subtotal={@subtotal}
            channels={@channels}
            payments={@payments}
          />
        </:overlay>
      </Shell.app>
    </Shell.frame>
    """
  end
end
