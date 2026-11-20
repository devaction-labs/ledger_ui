defmodule LedgerShowcase.Templates do
  @moduledoc """
  The app templates of the showcase (`/templates/:slug`) and their mock data.

  The data is plain Elixir terms, with money in integer cents (never floats). `page/1` describes a
  template (slug, title, canvas board), `orders/0` is the orders table and `detail/1` the order
  detail of the drawer.
  """

  @pages [
    %{
      slug: "auth-login",
      title: "Entrar",
      sub: "E-mail e senha, Google e erro de credencial",
      board: "TAuthLogin",
      group: "Auth"
    },
    %{
      slug: "auth-login-erro",
      title: "Entrar com erro",
      sub: "O mesmo login com o aviso de tentativas",
      board: "TAuthLoginErro",
      group: "Auth"
    },
    %{
      slug: "auth-cadastro",
      title: "Criar conta",
      sub: "Três passos, com consulta de CNPJ",
      board: "TAuthCadastro",
      group: "Auth"
    },
    %{
      slug: "auth-codigo",
      title: "Código por e-mail",
      sub: "Seis dígitos, reenvio com contagem",
      board: "TAuthCodigo",
      group: "Auth"
    },
    %{
      slug: "auth-senha",
      title: "Recuperar a senha",
      sub: "Link por e-mail, aviso de envio",
      board: "TAuthSenha",
      group: "Auth"
    },
    %{
      slug: "dashboard",
      title: "Painel",
      sub: "Meta, KPIs, faturamento, canais e atividade",
      board: "TDashboard",
      group: "App"
    },
    %{
      slug: "tabela",
      title: "Pedidos",
      sub: "Tabela com seleção e ações em lote",
      board: "TTabela",
      group: "App"
    },
    %{
      slug: "tabela-gaveta",
      title: "Pedidos · gaveta",
      sub: "O detalhe do pedido numa gaveta",
      board: "TTabelaGaveta",
      group: "App"
    },
    %{
      slug: "tabela-modal",
      title: "Pedidos · novo pedido",
      sub: "O formulário de pedido num modal",
      board: "TTabelaModal",
      group: "App"
    }
  ]

  @doc "The nine templates, in order."
  def pages, do: @pages

  @doc "One template by slug, or `nil`."
  def page(slug), do: Enum.find(@pages, &(&1.slug == slug))

  @doc "The slugs, in order."
  def slugs, do: Enum.map(@pages, & &1.slug)

  ## Money

  @doc "Cents as the Brazilian real (`R$ 1.284,90`)."
  def money(cents) when is_integer(cents) do
    sign = if cents < 0, do: "− ", else: ""
    abs = abs(cents)

    "#{sign}R$ #{group(div(abs, 100))},#{abs |> rem(100) |> Integer.to_string() |> String.pad_leading(2, "0")}"
  end

  @doc "An integer with the thousands dot (`1.096`)."
  def group(n) when is_integer(n) do
    n
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1.")
    |> String.reverse()
  end

  ## Orders

  @orders [
    {2496, "t2", "PC", "Padaria Central", "Feira de Santana", "Hoje, 14:20", "Loja", "Pago", 14,
     128_490},
    {2495, "t1", "BP", "Mercadinho Bom Preço", "Serrinha", "Hoje, 13:05", "WhatsApp", "Separando",
     32, 312_050},
    {2494, "t3", "SB", "Restaurante Sabor da Bahia", "Alagoinhas", "Hoje, 11:48", "iFood", "Pago",
     8, 48_600},
    {2493, "t4", "LZ", "Lanchonete do Zé", "Santo Estêvão", "Hoje, 10:12", "Loja", "Atrasado", 5,
     21_240},
    {2492, "t5", "ER", "Empório Recôncavo", "Cachoeira", "Ontem, 18:30", "Site", "Pago", 21,
     204_500},
    {2491, "t2", "FB", "Supermercado Feira Boa", "Conceição do Jacuípe", "Ontem, 16:02",
     "WhatsApp", "Pago", 46, 538_075},
    {2490, "t1", "CC", "Café Cajueiro", "Feira de Santana", "Ontem, 15:40", "Loja", "Cancelado",
     3, 9_600},
    {2489, "t3", "DP", "Distribuidora Paraguaçu", "Serrinha", "Ontem, 11:22", "Site", "Pago", 58,
     791_210},
    {2488, "t4", "DL", "Mercearia Dona Lia", "Alagoinhas", "18 nov, 17:45", "Loja", "Aberto", 9,
     34_120},
    {2487, "t5", "HS", "Hortifruti Santo Antônio", "Santo Estêvão", "18 nov, 14:10", "iFood",
     "Pago", 17, 95_830},
    {2486, "t1", "BO", "Bar e Petiscaria Orla", "Cachoeira", "18 nov, 09:55", "WhatsApp",
     "Atrasado", 12, 67_400},
    {2485, "t2", "PQ", "Padaria Pão Quente", "Conceição do Jacuípe", "17 nov, 19:20", "Loja",
     "Pago", 24, 110_260}
  ]

  @doc "The orders of the table (newest first)."
  def orders do
    for {id, tone, initials, name, city, at, channel, status, items, total} <- @orders do
      %{
        id: id,
        tone: tone,
        initials: initials,
        name: name,
        city: city,
        at: at,
        channel: channel,
        status: status,
        items: items,
        total: total
      }
    end
  end

  @doc "An order by id (integer or string), or `nil`."
  def order(id) when is_binary(id) do
    case Integer.parse(id) do
      {n, ""} -> order(n)
      _ -> nil
    end
  end

  def order(id) when is_integer(id), do: Enum.find(orders(), &(&1.id == id))

  @doc "The badge of a status: `{tone, dot?}` (`tone` is a `badge` color)."
  def status_badge("Pago"), do: {"success", true}
  def status_badge("Separando"), do: {"warning", true}
  def status_badge("Atrasado"), do: {"error", true}
  def status_badge(_), do: {"neutral", false}

  @doc "The channel badge color."
  def channel_color(c) when c in ["WhatsApp", "Site"], do: "primary"
  def channel_color(_), do: "neutral"

  @doc "Statuses that count as `open` in the tabs."
  def open?(%{status: s}), do: s in ["Aberto", "Separando"]

  @doc "The tabs of the table: `{key, label, count}`."
  def tabs do
    [
      {"todos", "Todos", 1096},
      {"abertos", "Abertos", 48},
      {"pagos", "Pagos", 1012},
      {"atrasados", "Atrasados", 36},
      {"cancelados", "Cancelados", 23}
    ]
  end

  @doc "Whether an order belongs to a tab."
  def in_tab?(_, "todos"), do: true
  def in_tab?(o, "abertos"), do: open?(o)
  def in_tab?(%{status: s}, "pagos"), do: s == "Pago"
  def in_tab?(%{status: s}, "atrasados"), do: s == "Atrasado"
  def in_tab?(%{status: s}, "cancelados"), do: s == "Cancelado"
  def in_tab?(_, _), do: true

  ## Order detail

  @catalog [
    {"Café torrado 500 g", 2390},
    {"Açúcar cristal 1 kg", 499},
    {"Óleo de soja 900 ml", 790},
    {"Arroz tipo 1 5 kg", 2890}
  ]

  @doc "The catalog of the new order form: `{name, unit price in cents}`."
  def catalog, do: @catalog

  @doc """
  The detail of an order for the drawer: customer data, the lines, the totals (cents) and the
  history. Order 2495 is the one of the canvas; the others are derived from the table row.
  """
  def detail(%{id: id} = o) do
    discount = if id == 2495, do: 3250, else: 0
    qtys = if id == 2495, do: [12, 24, 6, 10], else: for(i <- 1..4, do: 2 + rem(id * i, 9))

    lines =
      for {{name, price}, q} <- Enum.zip(@catalog, qtys),
          do: %{qty: q, name: name, cents: price * q}

    shown = Enum.sum(Enum.map(lines, & &1.cents))
    shown_qty = Enum.sum(qtys)
    rest_items = if id == 2495, do: 28, else: max(o.items - shown_qty, 0)
    rest_cents = max(o.total + discount - shown, 0)

    %{
      order: o,
      cnpj: cnpj(id),
      seller: if(rem(id, 2) == 1, do: "Carlos André", else: "Marina Reis"),
      payment: if(o.channel == "iFood", do: "Cartão · à vista", else: "Pix · à vista"),
      delivery: "Hoje, 16h–18h",
      created: created(o),
      lines: lines,
      rest_items: rest_items,
      rest_cents: rest_cents,
      discount: discount,
      steps: steps(o.status),
      history: history(o)
    }
  end

  defp cnpj(2495), do: "12.345.678/0001-90"

  defp cnpj(id) do
    a = 10 + rem(id * 7, 89)
    b = 100 + rem(id * 13, 899)
    "#{a}.#{b}.#{300 + rem(id, 600)}/0001-#{10 + rem(id, 89)}"
  end

  defp created(%{at: "Hoje, " <> t}), do: "hoje às #{t}"
  defp created(%{at: "Ontem, " <> t}), do: "ontem às #{t}"
  defp created(%{at: at}), do: "em #{at}"

  @stages ["Pedido", "Pagamento", "Separação", "Entrega"]

  @doc "The four stages of an order."
  def stages, do: @stages

  # `{current index, error?}` of the stepper.
  defp steps("Aberto"), do: {0, false}
  defp steps("Pago"), do: {3, false}
  defp steps("Separando"), do: {2, false}
  defp steps("Atrasado"), do: {2, true}
  defp steps(_), do: {0, true}

  defp history(%{id: 2495}) do
    [
      %{
        tone: "success",
        icon: "check",
        title: "Pagamento confirmado",
        sub: "Pix · R$ 3.120,50",
        at: "13:08"
      },
      %{
        tone: "info",
        icon: "package",
        title: "Separação iniciada",
        sub: "Expedição · Rita",
        at: "13:20"
      },
      %{
        tone: "neutral",
        icon: "invoice",
        title: "NF-e na fila",
        sub: "Aguardando separação",
        at: "—"
      }
    ]
  end

  defp history(%{status: "Aberto"}) do
    [%{tone: "neutral", icon: "clock", title: "Aguardando pagamento", sub: "Pix gerado", at: "—"}]
  end

  defp history(%{status: "Cancelado"} = o) do
    [
      %{
        tone: "neutral",
        icon: "x",
        title: "Pedido cancelado",
        sub: "A pedido do cliente",
        at: "—"
      },
      %{tone: "success", icon: "check", title: "Pedido criado", sub: o.channel, at: "—"}
    ]
  end

  defp history(%{status: "Atrasado"}) do
    [
      %{tone: "warning", icon: "clock", title: "Entrega atrasada", sub: "Prazo vencido", at: "—"},
      %{tone: "info", icon: "package", title: "Separação iniciada", sub: "Expedição", at: "—"},
      %{tone: "success", icon: "check", title: "Pagamento confirmado", sub: "Pix", at: "—"}
    ]
  end

  defp history(o) do
    [
      %{tone: "success", icon: "invoice", title: "NF-e autorizada", sub: "SEFAZ", at: "—"},
      %{tone: "info", icon: "truck", title: "Saiu para entrega", sub: "Rota Centro", at: "—"},
      %{
        tone: "success",
        icon: "check",
        title: "Pagamento confirmado",
        sub: money(o.total),
        at: "—"
      }
    ]
  end
end
