defmodule LedgerShowcaseWeb.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LedgerShowcaseWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", LedgerShowcaseWeb do
    pipe_through :browser

    live_session :shell do
      live "/", ShowcaseLive, :inicio
      live "/instalacao", ShowcaseLive, :instalacao
      live "/cores", ShowcaseLive, :cores
      live "/temas", ShowcaseLive, :temas
      live "/novidades", ShowcaseLive, :novidades
      live "/templates", ShowcaseLive, :templates
      live "/c/:id", ShowcaseLive, :component
    end

    live_session :full do
      live "/full/:id", FullscreenLive
    end

    live_session :templates do
      live "/templates/auth-login", Templates.AuthLive, :login
      live "/templates/auth-login-erro", Templates.AuthLive, :login_erro
      live "/templates/auth-cadastro", Templates.AuthLive, :cadastro
      live "/templates/auth-codigo", Templates.AuthLive, :codigo
      live "/templates/auth-senha", Templates.AuthLive, :senha
      live "/templates/dashboard", Templates.DashboardLive, :dashboard
      live "/templates/tabela", Templates.OrdersLive, :tabela
      live "/templates/tabela-gaveta", Templates.OrdersLive, :gaveta
      live "/templates/tabela-modal", Templates.OrdersLive, :modal
    end
  end
end
