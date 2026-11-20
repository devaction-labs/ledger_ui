defmodule LedgerShowcase.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: LedgerShowcase.PubSub},
      LedgerShowcaseWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: LedgerShowcase.Supervisor)
  end
end
