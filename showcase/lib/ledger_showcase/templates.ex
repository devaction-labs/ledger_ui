defmodule LedgerShowcase.Templates do
  @moduledoc """
  The app templates of the showcase (`/templates/:slug`) and their mock data.

  The data is plain Elixir terms, with money in integer cents (never floats). `page/1` describes a
  template (slug, title, canvas board), `orders/0` is the orders table and `detail/1` the order
  detail of the drawer.
  """

  # `design/vitrine/t/index.json` decides which templates exist, in which order and with which title
  # and height (`h`, px of the 1440-wide frame); the rest is ours: the blurb, the canvas board and
  # the group of the index page.
  @index_path Path.expand("../../../design/vitrine/t/index.json", __DIR__)
  @external_resource @index_path
  @index @index_path |> File.read!() |> Jason.decode!()

  @meta %{
    "auth-login" => {"E-mail e senha, Google e erro de credencial", "TAuthLogin", "Auth"},
    "auth-login-erro" => {"O mesmo login com o aviso de tentativas", "TAuthLoginErro", "Auth"},
    "auth-cadastro" => {"Três passos, com consulta de CNPJ", "TAuthCadastro", "Auth"},
    "auth-codigo" => {"Seis dígitos, reenvio com contagem", "TAuthCodigo", "Auth"},
    "auth-senha" => {"Link por e-mail, aviso de envio", "TAuthSenha", "Auth"},
    "dashboard" => {"Meta, KPIs, faturamento, canais e atividade", "TDashboard", "App"},
    "tabela" => {"Tabela com seleção e ações em lote", "TTabela", "App"},
    "tabela-gaveta" => {"O detalhe do pedido numa gaveta", "TTabelaGaveta", "App"},
    "tabela-modal" => {"O formulário de pedido num modal", "TTabelaModal", "App"},
    "tabela-app" =>
      {"A tabela inteira interativa: linha abre o detalhe, seleção, novo pedido e NF-e",
       "TTabela", "App"}
  }

  @pages Enum.map(@index, fn %{"slug" => slug, "title" => title, "h" => h} ->
           {sub, board, group} = Map.fetch!(@meta, slug)
           %{slug: slug, title: title, h: h, sub: sub, board: board, group: group}
         end)

  # The Crepúsculo palette (`data-palette="crepusculo"`): the same two pages and the palette page,
  # compared with the `TCrep*` boards. The pages take `?palette=crepusculo`.
  @palette_pages [
    %{
      slug: "auth-login",
      path: "/templates/auth-login?palette=crepusculo",
      palette: "crepusculo",
      title: "Crepúsculo · Auth · Entrar",
      sub: "O login na paleta Crepúsculo",
      board: "TCrepAuthLogin",
      group: "Crepúsculo"
    },
    %{
      slug: "dashboard",
      path: "/templates/dashboard?palette=crepusculo",
      palette: "crepusculo",
      title: "Crepúsculo · Dashboard",
      sub: "O painel na paleta Crepúsculo",
      board: "TCrepDashboard",
      group: "Crepúsculo"
    },
    %{
      slug: "paleta",
      path: "/templates/paleta",
      palette: "crepusculo",
      title: "Paleta Crepúsculo",
      sub: "Tokens, gradientes e componentes na paleta",
      board: "TCrepPaleta",
      group: "Crepúsculo"
    }
  ]

  @doc "The templates of `t/index.json`, in order."
  def pages, do: @pages

  @doc "The Crepúsculo variants (`%{slug, path, palette, title, sub, board, group}`)."
  def palette_pages, do: @palette_pages

  @doc "The palettes a template page accepts (`?palette=`)."
  def palettes, do: ~w(ledger crepusculo)

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

  # The distributor's products (unit price in cents) the order lines are made of.
  @products Map.new(
              @catalog ++
                [
                  {"Feijão carioca 1 kg", 849},
                  {"Leite integral 1 L", 529},
                  {"Farinha de trigo 1 kg", 479},
                  {"Macarrão espaguete 500 g", 359},
                  {"Refrigerante cola 2 L", 929},
                  {"Água mineral 1,5 L", 219},
                  {"Ovos brancos cartela 30", 1990},
                  {"Manteiga 200 g", 1190},
                  {"Queijo mussarela kg", 4290},
                  {"Presunto fatiado kg", 3490},
                  {"Frango congelado kg", 1290},
                  {"Cerveja lata 350 ml", 369},
                  {"Banana prata kg", 590},
                  {"Tomate kg", 690},
                  {"Batata inglesa kg", 549},
                  {"Cebola kg", 459}
                ]
            )

  @doc "The catalog of the new order form: `{name, unit price in cents}`."
  def catalog, do: @catalog

  # The detail of each order that is not a table-only row: the lines shown (`{product, qty}`), the
  # total of the remaining lines (`rest: {how many lines, cents}`, `nil` when all are shown), the
  # discount (cents) and the people/payment data. The total of the order is the row's `total`:
  # shown + rest - discount (checked by the tests). Order 2495 is the canvas board's.
  @details %{
    2496 => %{
      doc: {"CNPJ", "23.481.907/0001-55"},
      seller: "Marina Reis",
      payment: "Boleto · 28 dias",
      delivery: "Hoje, 16h–18h",
      lines: [
        {"Farinha de trigo 1 kg", 60},
        {"Açúcar cristal 1 kg", 30},
        {"Ovos brancos cartela 30", 12},
        {"Manteiga 200 g", 24}
      ],
      rest: {10, 33_840},
      discount: 1_500
    },
    2495 => %{
      doc: {"CNPJ", "12.345.678/0001-90"},
      seller: "Carlos André",
      payment: "Pix · à vista",
      delivery: "Hoje, 16h–18h",
      lines: [
        {"Café torrado 500 g", 12},
        {"Açúcar cristal 1 kg", 24},
        {"Óleo de soja 900 ml", 6},
        {"Arroz tipo 1 5 kg", 10}
      ],
      rest: {28, 241_004},
      discount: 3_250
    },
    2494 => %{
      doc: {"CNPJ", "08.772.140/0001-03"},
      seller: "Rita Souza",
      payment: "Cartão · à vista",
      delivery: "Hoje, 14h–16h",
      lines: [
        {"Frango congelado kg", 20},
        {"Óleo de soja 900 ml", 6},
        {"Arroz tipo 1 5 kg", 2},
        {"Feijão carioca 1 kg", 4}
      ],
      rest: {4, 8_884},
      discount: 0
    },
    2493 => %{
      doc: {"CNPJ", "31.906.552/0001-70"},
      seller: "Carlos André",
      payment: "Pix · à vista",
      delivery: "Hoje, 11h–12h",
      lines: [
        {"Presunto fatiado kg", 2},
        {"Queijo mussarela kg", 1},
        {"Refrigerante cola 2 L", 6},
        {"Ovos brancos cartela 30", 1}
      ],
      rest: {1, 2_406},
      discount: 0
    },
    2492 => %{
      doc: {"CNPJ", "17.250.384/0001-26"},
      seller: "Marina Reis",
      payment: "Pix · à vista",
      delivery: "Hoje, 9h–11h",
      lines: [
        {"Café torrado 500 g", 20},
        {"Queijo mussarela kg", 8},
        {"Manteiga 200 g", 30},
        {"Macarrão espaguete 500 g", 48}
      ],
      rest: {17, 71_448},
      discount: 2_000
    },
    2491 => %{
      doc: {"CNPJ", "04.618.733/0001-88"},
      seller: "Paulo Lima",
      payment: "Boleto · 14 dias",
      delivery: "Hoje, 8h–10h",
      lines: [
        {"Arroz tipo 1 5 kg", 40},
        {"Feijão carioca 1 kg", 60},
        {"Óleo de soja 900 ml", 48},
        {"Leite integral 1 L", 96}
      ],
      rest: {42, 290_831},
      discount: 8_000
    },
    2490 => %{
      doc: {"CPF", "412.883.095-27"},
      seller: "Rita Souza",
      payment: "Dinheiro",
      delivery: "Ontem, 17h–18h",
      lines: [
        {"Café torrado 500 g", 1},
        {"Feijão carioca 1 kg", 6},
        {"Leite integral 1 L", 4}
      ],
      rest: nil,
      discount: 0
    },
    2489 => %{
      doc: {"CNPJ", "10.540.226/0001-41"},
      seller: "Paulo Lima",
      payment: "Boleto · 28 dias",
      delivery: "Ontem, 14h–16h",
      lines: [
        {"Arroz tipo 1 5 kg", 100},
        {"Açúcar cristal 1 kg", 200},
        {"Óleo de soja 900 ml", 120},
        {"Farinha de trigo 1 kg", 150}
      ],
      rest: {54, 247_760},
      discount: 12_000
    },
    2488 => %{
      doc: {"CNPJ", "29.017.465/0001-09"},
      seller: "Marina Reis",
      payment: "Pix · à vista",
      delivery: "19 nov, 9h–11h",
      lines: [
        {"Açúcar cristal 1 kg", 12},
        {"Feijão carioca 1 kg", 10},
        {"Macarrão espaguete 500 g", 12},
        {"Refrigerante cola 2 L", 6}
      ],
      rest: {5, 9_760},
      discount: 0
    },
    2487 => %{
      doc: {"CNPJ", "36.284.119/0001-62"},
      seller: "Rita Souza",
      payment: "Cartão · à vista",
      delivery: "18 nov, 16h–18h",
      lines: [
        {"Banana prata kg", 20},
        {"Tomate kg", 25},
        {"Batata inglesa kg", 30},
        {"Cebola kg", 20}
      ],
      rest: {13, 41_630},
      discount: 500
    },
    2486 => %{
      doc: {"CNPJ", "14.903.571/0001-34"},
      seller: "Carlos André",
      payment: "Pix · à vista",
      delivery: "18 nov, 14h–16h",
      lines: [
        {"Cerveja lata 350 ml", 60},
        {"Refrigerante cola 2 L", 12},
        {"Frango congelado kg", 10},
        {"Água mineral 1,5 L", 24}
      ],
      rest: {8, 15_956},
      discount: 0
    },
    2485 => %{
      doc: {"CNPJ", "21.670.948/0001-17"},
      seller: "Paulo Lima",
      payment: "Boleto · 14 dias",
      delivery: "18 nov, 8h–10h",
      lines: [
        {"Farinha de trigo 1 kg", 40},
        {"Açúcar cristal 1 kg", 20},
        {"Manteiga 200 g", 12},
        {"Ovos brancos cartela 30", 4}
      ],
      rest: {20, 59_380},
      discount: 500
    }
  }

  @doc """
  The detail of an order for the drawer: customer data, the lines shown, the remaining lines (a
  lump sum), the discount, the stepper and the history. `total` is the row's total: the lines shown
  plus the rest minus the discount, in cents.
  """
  def detail(%{id: id} = o) do
    d = Map.fetch!(@details, id)

    lines =
      for {name, qty} <- d.lines,
          do: %{qty: qty, name: name, cents: Map.fetch!(@products, name) * qty}

    {rest_items, rest_cents} = d.rest || {0, 0}
    {doc_label, doc} = d.doc

    %{
      order: o,
      doc_label: doc_label,
      doc: doc,
      seller: d.seller,
      payment: d.payment,
      delivery: d.delivery,
      created: created(o),
      lines: lines,
      rest_items: rest_items,
      rest_cents: rest_cents,
      discount: d.discount,
      steps: steps(o.status),
      history: history(o, d)
    }
  end

  @doc "The total of a detail in cents: the lines shown plus the rest minus the discount."
  def detail_total(%{lines: lines, rest_cents: rest, discount: discount}),
    do: lines |> Enum.map(& &1.cents) |> Enum.sum() |> Kernel.+(rest - discount)

  defp created(%{at: "Hoje, " <> t}), do: "hoje às #{t}"
  defp created(%{at: "Ontem, " <> t}), do: "ontem às #{t}"
  defp created(%{at: at}), do: "em #{at}"

  # "HH:MM" of the row's date, `plus` minutes later.
  defp clock(%{at: at}, plus) do
    [_, h, m] = Regex.run(~r/(\d{1,2}):(\d{2})$/, at)
    t = rem(String.to_integer(h) * 60 + String.to_integer(m) + plus, 24 * 60)
    pad(div(t, 60)) <> ":" <> pad(rem(t, 60))
  end

  defp pad(n), do: n |> Integer.to_string() |> String.pad_leading(2, "0")

  @stages ["Pedido", "Pagamento", "Separação", "Entrega"]

  @doc "The four stages of an order."
  def stages, do: @stages

  # `{current index, error?}` of the stepper.
  defp steps("Aberto"), do: {1, false}
  defp steps("Separando"), do: {2, false}
  defp steps("Pago"), do: {2, false}
  # delivery overdue: the last step is flagged
  defp steps("Atrasado"), do: {3, true}
  # cancelled before the payment
  defp steps("Cancelado"), do: {1, true}

  # Newest first. Order 2495 is the canvas board's.
  defp history(%{id: 2495}, _) do
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

  defp history(%{status: "Aberto"} = o, d) do
    [
      %{
        tone: "neutral",
        icon: "clock",
        title: "Aguardando pagamento",
        sub: d.payment,
        at: clock(o, 1)
      },
      created_entry(o)
    ]
  end

  defp history(%{status: "Cancelado"} = o, _) do
    [
      %{
        tone: "neutral",
        icon: "x",
        title: "Pedido cancelado",
        sub: "A pedido do cliente",
        at: clock(o, 35)
      },
      %{
        tone: "neutral",
        icon: "clock",
        title: "Aguardando pagamento",
        sub: "Pagamento não realizado",
        at: clock(o, 1)
      },
      created_entry(o)
    ]
  end

  defp history(%{status: "Atrasado"} = o, d) do
    [
      %{
        tone: "warning",
        icon: "clock",
        title: "Entrega atrasada",
        sub: "Janela #{d.delivery} vencida",
        at: "—"
      },
      %{
        tone: "info",
        icon: "truck",
        title: "Saiu para entrega",
        sub: "Rota #{route(o)}",
        at: clock(o, 95)
      },
      %{
        tone: "info",
        icon: "package",
        title: "Separação concluída",
        sub: "Expedição",
        at: clock(o, 50)
      },
      %{
        tone: "success",
        icon: "check",
        title: "Pagamento confirmado",
        sub: "#{d.payment} · #{money(o.total)}",
        at: clock(o, 4)
      },
      created_entry(o)
    ]
  end

  # "Pago": paid, waiting for the separation.
  defp history(o, d) do
    [
      %{
        tone: "neutral",
        icon: "package",
        title: "Aguardando separação",
        sub: "Fila da expedição",
        at: "—"
      },
      %{
        tone: "success",
        icon: "check",
        title: "Pagamento confirmado",
        sub: "#{d.payment} · #{money(o.total)}",
        at: clock(o, 4)
      },
      created_entry(o)
    ]
  end

  defp created_entry(o),
    do: %{tone: "info", icon: "cart", title: "Pedido criado", sub: o.channel, at: clock(o, 0)}

  defp route(%{city: city}), do: city
end
