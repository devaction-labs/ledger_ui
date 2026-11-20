defmodule LedgerShowcaseWeb.FullscreenLive do
  @moduledoc """
  `/full/:id` - the examples of one component alone, without the shell. Shown in the
  "Tela cheia" overlay (iframe) of `ShowcaseLive`; `?theme=dark|light` picks the theme.
  """
  use Phoenix.LiveView

  alias LedgerShowcase.Vitrine
  alias LedgerShowcaseWeb.Pages

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Vitrine.page(id) do
      nil -> {:ok, push_navigate(socket, to: "/")}
      page -> {:ok, assign(socket, page: page, page_title: page.name <> " · Tela cheia")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main id="main" class="d-full" phx-hook="ShowcasePage" data-page={@page.id}>
      <Pages.examples id={@page.id} sections={@page.sections} />
    </main>
    """
  end
end
