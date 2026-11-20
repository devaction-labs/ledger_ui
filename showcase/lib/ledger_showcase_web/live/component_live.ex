defmodule LedgerShowcaseWeb.ComponentLive do
  @moduledoc """
  Temporary showcase pages: `/` lists component ids, `/c/:id` renders every section's
  preview and its HEEx source. To be replaced by a faithful copy of the vitrine layout.
  """
  use Phoenix.LiveView
  use LedgerUI

  alias LedgerShowcase.Examples

  def mount(_params, _session, socket), do: {:ok, assign(socket, ids: Examples.ids())}

  def handle_params(%{"id" => id}, _uri, socket) do
    if id in socket.assigns.ids do
      {:noreply, assign(socket, id: id, sections: Examples.sections(id))}
    else
      {:noreply, push_navigate(socket, to: "/")}
    end
  end

  def handle_params(_params, _uri, socket), do: {:noreply, assign(socket, id: nil, sections: [])}

  def render(assigns) do
    ~H"""
    <main style="max-width:960px;margin:0 auto;padding:32px 24px;font-family:Inter,sans-serif">
      <h1><a href="/">Ledger UI showcase</a></h1>
      <ul :if={@id == nil} id="component-list">
        <li :for={id <- @ids}><a href={"/c/#{id}"}>{id}</a></li>
      </ul>
      <section :if={@id} id={"component-#{@id}"}>
        <h2>{@id}</h2>
        <article :for={s <- @sections} id={"#{@id}-#{s.index}"} style="margin:24px 0">
          <h3>{s.title}</h3>
          <div class="lu-demo">{Examples.render(@id, s.index, assigns)}</div>
          <details>
            <summary>HEEx</summary>
            <pre><code>{s.source}</code></pre>
          </details>
        </article>
      </section>
    </main>
    """
  end
end
