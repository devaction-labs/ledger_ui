defmodule LedgerUI.Components.ScrollTarget do
  @moduledoc """
  `scroll_target/1`: scrolls smoothly to a block when the server changes `target`.

      <.scroll_target id="purchase-detail-1" target={@focus} block="nearest" />

      <section data-block="contracts">...</section>
      <section data-block="alternatives">...</section>

  Renders a hidden element; the hook `LedgerUI.ScrollTarget`
  (`priv/static/ledger_ui/hooks/scroll_target.js`) scrolls to `[data-block="<target>"]` once each
  time `target` changes (also when it mounts with one). A re-render with the same `target` does
  not scroll; `nil` or `""` does nothing. With `prefers-reduced-motion: reduce` the scroll is
  instant. A `target` with no matching element does nothing.

  `block` is where the element lands (`start`, `center`, `end`, `nearest`).

  ## Scope

  By default the block is searched in the whole document (the first `[data-block=...]`). Set
  `scope` to a CSS selector to search only inside that container, so two panels that use the
  same block names do not clash:

      <.scroll_target id="st-1" target={@focus} scope="#purchase-detail-1" />

  ## From the server

  `LedgerUI.scroll_to(socket, selector, opts)` scrolls to any selector, once, with no component
  (`block:` and `scope:` as above):

      {:noreply, LedgerUI.scroll_to(socket, ~s([data-block="contracts"]), block: "start")}
  """
  use LedgerUI.Component

  attr :id, :string, required: true, doc: "Needed by the hook."

  attr :target, :string,
    default: nil,
    doc: "Value of `data-block` to scroll to; scrolls on change."

  attr :block, :string, default: "nearest", values: ~w(start center end nearest)

  attr :scope, :string,
    default: nil,
    doc: "Selector of the container searched; the whole document when `nil`."

  attr :rest, :global

  def scroll_target(assigns) do
    ~H"""
    <span
      id={@id}
      data-part="scroll-target"
      hidden
      aria-hidden="true"
      data-lu-target={@target}
      data-lu-block={@block}
      data-lu-scope={@scope}
      phx-hook="LedgerUI.ScrollTarget"
      {@rest}
    ></span>
    """
  end
end
