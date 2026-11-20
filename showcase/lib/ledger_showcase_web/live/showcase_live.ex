defmodule LedgerShowcaseWeb.ShowcaseLive do
  @moduledoc """
  The vitrine shell (top bar, index, command palette, fullscreen overlay) and all pages:
  `:inicio`, `:instalacao`, `:cores`, `:temas`, `:novidades`, `:templates` (`/templates`, the index of
  the app templates) and `:component` (`/c/:id`).
  Navigation between pages is a `live_patch`, so the shell stays mounted.
  """
  use Phoenix.LiveView

  alias LedgerShowcase.{ThemeGen, Vitrine}
  alias LedgerShowcaseWeb.Pages

  @titles %{
    inicio: "Ledger UI · Componentes",
    instalacao: "Instalação · Ledger UI",
    cores: "Cores · Ledger UI",
    temas: "Temas · Ledger UI",
    novidades: "Novidades · Ledger UI",
    templates: "Templates · Ledger UI"
  }

  @impl true
  def mount(_params, _session, socket),
    do: {:ok, assign(socket, page: nil, tg_acc: "base", tg_gray: "ledger", tg_mode: "light")}

  # Theme generator (`/temas`): the choice is validated against the known ids, never turned into an atom.
  @impl true
  def handle_event("tg_acc", %{"id" => id}, socket), do: {:noreply, put_tg(socket, :tg_acc, id)}
  def handle_event("tg_gray", %{"id" => id}, socket), do: {:noreply, put_tg(socket, :tg_gray, id)}

  def handle_event("tg_mode", %{"mode" => m}, socket), do: {:noreply, put_tg(socket, :tg_mode, m)}

  # Sent by the `ThemeGen` hook with the choice kept in `localStorage["lu-tg"]` (or the page theme).
  def handle_event("tg_restore", params, socket) do
    {:noreply,
     socket
     |> put_tg(:tg_acc, params["acc"])
     |> put_tg(:tg_gray, params["gray"])
     |> put_tg(:tg_mode, params["mode"])}
  end

  defp put_tg(socket, key, value) do
    if valid_tg?(key, value), do: assign(socket, key, value), else: socket
  end

  defp valid_tg?(:tg_acc, v), do: v == "base" or v in ThemeGen.accent_ids()
  defp valid_tg?(:tg_gray, v), do: v == "ledger" or v in ThemeGen.gray_ids()
  defp valid_tg?(:tg_mode, v), do: v in ~w(light dark)

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    case Vitrine.page(id) do
      nil ->
        {:noreply, push_navigate(socket, to: "/")}

      page ->
        {:noreply, assign(socket, cur: id, page: page, page_title: page.name <> " · Ledger UI")}
    end
  end

  def handle_params(_params, _uri, socket) do
    action = socket.assigns.live_action

    {:noreply,
     assign(socket,
       cur: Atom.to_string(action),
       page: nil,
       page_title: Map.fetch!(@titles, action)
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <header class="d-top">
      <div class="d-in">
        <button class="d-ib d-mbtn" id="mb" type="button" aria-label="Abrir o índice">
          <svg viewBox="0 0 24 24"><path d="M4 7h16M4 12h16M4 17h16" /></svg>
        </button>
        <.link class="d-brand" patch="/"><i>L</i>Ledger UI</.link>
        <nav>
          <.link patch="/">Componentes</.link>
          <.link patch="/novidades">Novidades</.link>
          <.link patch="/instalacao">Docs</.link>
        </nav>
        <button class="d-sbtn" id="sb" type="button">
          <svg viewBox="0 0 24 24"><circle cx="11" cy="11" r="7" /><path d="M20 20l-3.5-3.5" /></svg><span>Buscar</span><kbd>⌘K</kbd>
        </button>
        <span class="d-plw" id="plw" phx-update="ignore">
          <button
            class="d-ib d-plb"
            id="plb"
            type="button"
            aria-label="Escolher paleta"
            aria-haspopup="true"
          ></button>
          <div class="d-plm" id="plm" role="menu"></div>
        </span>
        <button class="d-ib" id="th" type="button" aria-label="Alternar tema">
          <svg viewBox="0 0 24 24"><path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z" /></svg>
        </button>
        <span class="d-me">AN</span>
      </div>
    </header>
    <div class="d-wrap">
      <aside class="d-side" id="side"><Pages.side cur={@cur} /></aside>
      <main id="main" phx-hook="ShowcasePage" data-page={@cur}>
        <Pages.intro :if={@live_action == :inicio} />
        <Pages.intro :if={@live_action == :novidades} only_new />
        <Pages.install :if={@live_action == :instalacao} />
        <Pages.cores :if={@live_action == :cores} />
        <Pages.temas
          :if={@live_action == :temas}
          tg_acc={@tg_acc}
          tg_gray={@tg_gray}
          tg_mode={@tg_mode}
        />
        <Pages.templates :if={@live_action == :templates} />
        <Pages.component :if={@live_action == :component} p={@page} />
      </main>
    </div>
    <div class="d-fs" id="fs" phx-update="ignore">
      <div class="d-bar">
        <b id="fst"></b><span style="flex:1"></span>
        <button class="d-bt" id="fsx" type="button">Fechar <span class="d-kb">Esc</span></button>
      </div>
      <iframe id="fsf" title="Prévia em tela cheia"></iframe>
    </div>
    <div class="d-pal" id="pal" phx-update="ignore">
      <div class="d-box">
        <input id="pq" placeholder="Buscar componente…" aria-label="Buscar componente" />
        <div class="d-res" id="pr"></div>
      </div>
    </div>
    """
  end
end
