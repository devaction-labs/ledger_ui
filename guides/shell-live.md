# Cromo persistente: um `ShellLive` sticky

O cromo de uma página (menu, paleta de comandos, toaster, sino) costuma ser refeito a cada
navegação, porque mora no `render/1` de cada LiveView. Um LiveView aninhado e sticky monta o cromo
uma vez e o mantém entre as navegações.

Este guia mostra o desenho. O `ShellLive` de exemplo não vem pronto no kit: adapte ao seu app.

## Antes de começar: `live_session`

Um LiveView sticky só sobrevive a navegações **dentro da mesma `live_session`**. A documentação do
LiveView diz: "Redirecting between `live_session`s will always force a full page reload". Se o
roteador tem uma `live_session` por módulo ou plano, quase todo clique no menu troca de sessão: o
resultado é HTTP completo, novo join, e o sticky não sobrevive.

Alternativa: uma `live_session` só, com o requisito de cada rota num `on_mount` que leia
`socket.view` ou o `metadata:` da rota.

```elixir
live_session :app, on_mount: [{MyAppWeb.Plans, :require_plan}] do
  live "/items", ItemsLive, :index, metadata: %{plan: :basic}
  live "/reports", ReportsLive, :index, metadata: %{plan: :pro}
end
```

## 1. O layout raiz renderiza o `ShellLive`

```heex
<%!-- root.html.heex --%>
<body>
  {live_render(@conn, MyAppWeb.ShellLive, id: "shell", sticky: true)}
  {@inner_content}
</body>
```

O `ShellLive` não conhece a rota atual, e não precisa: a marcação do item ativo é do cliente.

## 2. Menu com rota ativa no cliente

`active_link` liga o hook `LedgerUI.ActiveLink`; cada item declara em `match` o caminho (prefixo)
que o torna ativo. O hook escuta `phx:page-loading-stop` e `popstate`, compara `location.pathname`
com `data-lu-match` (o prefixo mais longo vence, em fronteira de segmento) e aplica
`aria-current="page"` e as classes de ativo. O menu não recebe nada do servidor na troca de rota.

```heex
<.sidebar_nav id="menu" active_link>
  <.sidebar_nav_link navigate={~p"/items"} match="/items">Itens</.sidebar_nav_link>
  <.sidebar_nav_link navigate={~p"/reports"} match="/reports">Relatórios</.sidebar_nav_link>
</.sidebar_nav>
```

Também aceitam `match`: `rail_link`, `main_sidebar` (`active_link` no contêiner e `match` em cada
`<:item>`), `navbar_links` e `navbar_tabs` (`match:` em cada item). Dentro de um `framed_sidebar`,
embrulhe os links num `sidebar_nav` com `active_link`. Sem `match`, nada muda.

## 3. Paleta de comandos leve

Num cromo persistente a paleta fica na página o tempo todo. `defer_items` não renderiza as linhas no
servidor: manda um JSON compacto e o hook monta as linhas na primeira abertura.

```heex
<.command_palette id="palette" items={@pages} defer_items />
```

## 4. Toaster e flash de outros LiveViews

O `ShellLive` é outro processo: o `put_flash` de uma página não chega nele. Faça as páginas
publicarem por PubSub e o `ShellLive` mostrar o toast.

```elixir
defmodule MyAppWeb.ShellLive do
  use MyAppWeb, :live_view
  import LedgerUI.Components.Toast, only: [send_toast: 3]

  def mount(_params, session, socket) do
    user_id = session["user_id"]

    if connected?(socket) do
      Phoenix.PubSub.subscribe(MyApp.PubSub, "user:#{user_id}")
    end

    {:ok, assign(socket, user_id: user_id, notifications: MyApp.Inbox.recent(user_id)),
     layout: false}
  end

  def handle_info({:toast, message, opts}, socket),
    do: {:noreply, send_toast(socket, message, opts)}

  def handle_info({:notification, n}, socket),
    do: {:noreply, update(socket, :notifications, &[n | &1])}

  def render(assigns) do
    ~H"""
    <.sidebar_nav id="menu" active_link>...</.sidebar_nav>
    <.command_palette id="palette" items={MyAppWeb.Nav.pages()} defer_items />
    <.notification_center id="bell" items={@notifications} on_read="read" on_read_all="read_all" />
    <.toaster />
    """
  end
end
```

Em qualquer LiveView da aplicação:

```elixir
Phoenix.PubSub.broadcast(MyApp.PubSub, "user:#{user.id}", {:toast, "Salvo", color: "success"})
```

## 5. Sino com contador por PubSub

O `notification_center` mostra o contador pelo número de itens não lidos. Quem produz a
notificação publica `{:notification, n}` no tópico do usuário; o `ShellLive` a põe no topo da lista
e o sino se atualiza sem recarregar nada. Marcar como lido é do servidor: `on_read` e `on_read_all`
chegam ao `ShellLive`, que troca `read` nos itens. Para listas longas, `items` também aceita um
stream.

## Limites

- Navegar entre `live_session`s diferentes remonta o shell.
- O hook marca o item ativo só no cliente. Uma tela que precisa saber a rota no servidor usa
  `handle_params` na própria página.
